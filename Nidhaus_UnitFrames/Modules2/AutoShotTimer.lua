local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local format, floor = string.format, math.floor;

-- =========================================================
-- AutoShotTimer.lua  (portado de ZAutoShot a NUF)
-- Barra con el tiempo del disparo automatico del cazador.
-- Tiene en cuenta Hacerse el muerto (usa la velocidad sin modificar).
--
-- Mover: /nufshot unlock  -> arrastrar -> /nufshot lock
-- =========================================================

local BAR_WIDTH  = 195;
local BAR_HEIGHT = 14;

local AUTO_SHOT   = GetSpellInfo(75);
local FEIGN_DEATH = GetSpellInfo(5384);

local enabled  = false;
local unlocked = false;

-- ---------------------------------------------------------
-- DB
-- ---------------------------------------------------------
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.AutoShotTimer then
		NidhausUnitFramesDB.AutoShotTimer = { x = 0, y = 246, scale = 1.0 };
	end
	return NidhausUnitFramesDB.AutoShotTimer;
end

-- ---------------------------------------------------------
-- Frames
-- ---------------------------------------------------------
local mover = CreateFrame("Frame", "NUF_AutoShotMover", UIParent);
mover:SetSize(BAR_WIDTH + 4, BAR_HEIGHT + 4);
mover:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 246);
mover:SetMovable(true);
mover:SetClampedToScreen(true);
mover:EnableMouse(false);   -- bloqueado = los clicks pasan de largo
mover:Hide();

local bar = CreateFrame("StatusBar", "NUF_AutoShotBar", mover);
bar:SetSize(BAR_WIDTH, BAR_HEIGHT);
bar:SetPoint("CENTER", mover, "CENTER", 0, 0);
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
local BAR_R, BAR_G, BAR_B = 1, 0.7, 0;   -- el color propio de esta barra
bar:SetStatusBarColor(BAR_R, BAR_G, BAR_B);
bar:SetMinMaxValues(0, 1);
bar:SetValue(1);

local bg = bar:CreateTexture(nil, "BACKGROUND");
bg:SetAllPoints(bar);
bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
bg:SetVertexColor(0.1, 0.1, 0.1, 0.75);

local border = CreateFrame("Frame", nil, bar);
border:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2);
border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2);
border:SetBackdrop({
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 12,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
});
border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.9);

local spark = bar:CreateTexture(nil, "OVERLAY");
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
spark:SetSize(16, BAR_HEIGHT + 10);
spark:SetBlendMode("ADD");
spark:SetPoint("CENTER", bar, "LEFT", 0, 0);

local textLeft = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
textLeft:SetPoint("LEFT", bar, "LEFT", 4, 1);   -- +1: a la altura del texto de la barra de casteo
textLeft:SetText(AUTO_SHOT or "Auto Shot");

local textRight = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
textRight:SetPoint("RIGHT", bar, "RIGHT", -4, 1);

local unlockOverlay = mover:CreateTexture(nil, "OVERLAY");
unlockOverlay:SetAllPoints(mover);
unlockOverlay:SetTexture(0, 0.8, 1, 0.25);
unlockOverlay:Hide();

local unlockText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
unlockText:SetPoint("CENTER", mover, "CENTER", 0, 0);
unlockText:SetText("|cff00ccff" .. (L["DRAG_LABEL"] or "DRAG") .. "|r");
unlockText:Hide();

-- Tooltip oculto para leer la velocidad del arma a distancia sin modificar
local tip = CreateFrame("GameTooltip", "NUF_AutoShotTooltip", UIParent, "GameTooltipTemplate");
tip:SetOwner(UIParent, "ANCHOR_NONE");

-- ---------------------------------------------------------
-- Posicion / escala
-- ---------------------------------------------------------
local function SavePosition()
	local db = DB();
	local _, _, _, x, y = mover:GetPoint();
	db.x = x or 0;
	db.y = y or 246;
end

local function RestorePosition()
	local db = DB();
	mover:ClearAllPoints();
	mover:SetPoint("BOTTOM", UIParent, "BOTTOM", db.x or 0, db.y or 246);
	mover:SetScale(db.scale or 1.0);
end

mover:SetScript("OnMouseDown", function(self, btn)
	if btn == "LeftButton" and unlocked then self:StartMoving(); end
end);
mover:SetScript("OnMouseUp", function(self, btn)
	if btn == "LeftButton" and unlocked then
		self:StopMovingOrSizing();
		SavePosition();
	end
end);

-- ---------------------------------------------------------
-- Show / Hide / Lock
-- ---------------------------------------------------------
local function ShowBar()
	if enabled or unlocked then mover:Show(); end
end

local function HideBar()
	if not unlocked then mover:Hide(); end
end

-- ---------------------------------------------------------
-- Estilo del borde: tres modos
--
--   Tooltip   el de siempre, borde gris de tooltip.
--   None      sin marco, como las barras de casteo de los marcos de
--             arena, cuyo template no dibuja borde ninguno.
--   Blizzard  el borde de la barra de casteo del jugador. La textura y
--             las medidas se leen en vivo de CastingBarFrame y se aplican
--             a escala: esta barra mide 195x14 y aquella 195x13, asi que
--             calza, y si otro modulo la retextura el timer la acompaña.
--
-- Sin marco no se pierde el modo mover: lo indica unlockOverlay, que va
-- por fuera de la barra y no depende del borde.
-- ---------------------------------------------------------
local castBorder;   -- textura del modo Blizzard, se crea recien si se pide

local function CurrentBorderStyle()
	local v = C.AutoShotBorderStyle;
	if v == "None" or v == "Blizzard" or v == "Tooltip" then return v; end
	-- Compatibilidad con la opcion booleana que hubo antes.
	if C.AutoShotBorderless == true then return "None"; end
	return "Tooltip";
end

local function BorderTint(r, g, b, a)
	if castBorder and castBorder:IsShown() then
		-- El borde prestado de la barra de casteo va a su color de fabrica
		-- mientras la barra esta bloqueada: bajarlo al gris del modo mover
		-- lo dejaba mas apagado que la barra de casteo de al lado. Solo se
		-- pinta de celeste para avisar que se la puede arrastrar.
		if unlocked then
			castBorder:SetVertexColor(r, g, b, a);
		else
			castBorder:SetVertexColor(1, 1, 1, 1);
		end
	elseif border:IsShown() then
		border:SetBackdropBorderColor(r, g, b, a);
	end
end


-- El estilo Blizzard no es solo el marco.
--
-- La barra de casteo del jugador escribe en BLANCO (GameFontHighlight) y
-- rellena con UI-CastingBar-Fill; esta barra escribia en DORADO
-- (GameFontNormalSmall) sobre UI-StatusBar. Puestas una al lado de la
-- otra, las letras eran de otro color y el relleno se veia mas apagado.
-- Se leen en vivo, igual que el borde: si otro addon retextura la barra
-- de casteo, el timer la acompaña. En los otros dos estilos vuelve a su
-- aspecto propio, que es el que tenia siempre.
-- El Auto Shot comparte el dorado de la barra de casteo, asi que en modo
-- Blizzard puede tomarle el tinte prestado tal cual.
local MATCH_BLIZZ_COLOR = true;
local DEFAULT_FILL = "Interface\\TargetingFrame\\UI-StatusBar";

local function ApplyLookForStyle(style)
	local blizz = (style == "Blizzard");

	local ref = _G.CastingBarFrameText;
	if blizz and ref then
		local f, size, flags = ref:GetFont();
		if f then
			textLeft:SetFont(f, size, flags);
			textRight:SetFont(f, size, flags);
		end
		local r, g, b = ref:GetTextColor();
		if r then
			textLeft:SetTextColor(r, g, b);
			textRight:SetTextColor(r, g, b);
		end
	else
		textLeft:SetFontObject(GameFontNormalSmall);
		textRight:SetFontObject(GameFontNormalSmall);
	end

	local cb  = _G.CastingBarFrame;
	local cbt = cb and cb.GetStatusBarTexture and cb:GetStatusBarTexture();
	local path = cbt and cbt.GetTexture and cbt:GetTexture();
	if blizz and path then
		bar:SetStatusBarTexture(path);
	else
		bar:SetStatusBarTexture(DEFAULT_FILL);
	end

	-- SetStatusBarTexture resetea el tinte: hay que reponerlo siempre.
	--
	-- Y en modo Blizzard el tinte tambien se lee en vivo, no se asume. Este
	-- relleno ya viene dorado de fabrica; multiplicarlo por un dorado propio
	-- lo apagaba, que era lo que se veia mas oscuro al lado de la barra de
	-- casteo de verdad.
	--
	-- Se lee CASTING_BAR_COLOR, la constante, y NO el color que la barra
	-- tiene puesto en este instante: Blizzard la pinta de rojo cuando un
	-- casteo se interrumpe y de verde en los canalizados, asi que preguntar
	-- en vivo podia dejar el timer rojo para siempre.
	local cc = blizz and MATCH_BLIZZ_COLOR and _G.CASTING_BAR_COLOR;
	if cc and cc.r then
		bar:SetStatusBarColor(cc.r, cc.g, cc.b);
	else
		bar:SetStatusBarColor(BAR_R, BAR_G, BAR_B);
	end

	-- El fondo va SIEMPRE oscuro. Copiar el de la barra de casteo dejaba la
	-- parte vacia blanca, que es peor que el problema que venia a resolver:
	-- lo apagado era el tinte del relleno y el del borde, no el fondo.
	bg:SetTexture(DEFAULT_FILL);
	bg:SetVertexColor(0.1, 0.1, 0.1, 0.75);
	bg:Show();

	-- El spark: el alto sale del de la barra de casteo, el ancho se queda en
	-- los 16 de siempre. Copiarle tambien el ancho lo dejaba como una mancha.
	local sh = 32;
	local sp = _G.CastingBarFrameSpark;
	if sp and (sp:GetHeight() or 0) > 0 then sh = sp:GetHeight(); end
	spark:SetWidth(16);
	spark:SetHeight(sh);
end

local function ApplyBorderStyle()
	local style = CurrentBorderStyle();
	if castBorder then castBorder:Hide(); end
	border:Hide();

	if style == "Tooltip" then
		border:Show();
	elseif style == "Blizzard" then
		local src = _G.CastingBarFrameBorder;
		local ref = _G.CastingBarFrame;
		if src and ref and (ref:GetWidth() or 0) > 0 and (ref:GetHeight() or 0) > 0 then
			if not castBorder then
				castBorder = bar:CreateTexture(nil, "OVERLAY");
			end
			castBorder:SetTexture(src:GetTexture());
			castBorder:SetWidth(BAR_WIDTH   * (src:GetWidth()  / ref:GetWidth()));
			castBorder:SetHeight(BAR_HEIGHT * (src:GetHeight() / ref:GetHeight()));
			castBorder:ClearAllPoints();
			-- El borde de casteo no va centrado: deja aire arriba para el
			-- texto. Se copia ese corrimiento, a escala de esta barra.
			local _, sy = src:GetCenter();
			local _, ry = ref:GetCenter();
			local dy = (sy and ry) and ((sy - ry) * (BAR_HEIGHT / ref:GetHeight())) or 0;
			castBorder:SetPoint("CENTER", bar, "CENTER", 0, dy);
			castBorder:Show();
		else
			border:Show();   -- si la barra de casteo no existe todavia
		end
	end

	ApplyLookForStyle(style);

	if unlocked then
		BorderTint(0, 0.8, 1, 1);
	else
		BorderTint(0.6, 0.6, 0.6, 0.9);
	end
end

function K.GetAutoShotBorderStyle()
	return CurrentBorderStyle();
end

function K.SetAutoShotBorderStyle(style)
	local v = (style == "None" and "None")
		or (style == "Blizzard" and "Blizzard")
		or "Tooltip";
	K.SaveConfig("AutoShotBorderStyle", v);
	ApplyBorderStyle();
	return v;
end

function K.CycleAutoShotBorderStyle()
	local cur = CurrentBorderStyle();
	local nxt = (cur == "Tooltip" and "None")
		or (cur == "None" and "Blizzard")
		or "Tooltip";
	K.SaveConfig("AutoShotBorderStyle", nxt);
	ApplyBorderStyle();
	return nxt;
end

local function Lock()
	unlocked = false;
	mover:EnableMouse(false);
	unlockOverlay:Hide();
	unlockText:Hide();
	BorderTint(0.6, 0.6, 0.6, 0.9);
	SavePosition();
	HideBar();
end

local function Unlock()
	unlocked = true;
	mover:EnableMouse(true);
	unlockOverlay:Show();
	unlockText:Show();
	BorderTint(0, 0.8, 1, 1);
	bar:SetMinMaxValues(0, 1);
	bar:SetValue(0.6);
	textRight:SetText("--");
	mover:Show();
end

-- ---------------------------------------------------------
-- Logica
-- ---------------------------------------------------------
local function GetUnmodifiedRangedSpeed()
	tip:SetOwner(UIParent, "ANCHOR_NONE");
	tip:SetInventoryItem("player", 18);
	for i = 1, 10 do
		local line = _G["NUF_AutoShotTooltipTextRight" .. i];
		if line and line:IsVisible() then
			local spd = tonumber(string.match(line:GetText() or "", "([%d%.]+)"));
			if spd then return spd; end
		end
	end
	return nil;
end

local function OnStart(spellName)
	if unlocked then return; end
	local speed = UnitRangedDamage("player");
	if spellName == FEIGN_DEATH then
		speed = GetUnmodifiedRangedSpeed() or speed;
	end
	if not speed or speed <= 0 then return; end

	local now = GetTime();
	bar:SetMinMaxValues(now, now + speed);
	bar:SetValue(now);
	textRight:SetText(string.format("%0.1f", speed));
	ShowBar();
end

bar:SetScript("OnUpdate", function(self)
	if unlocked then return; end
	local lo, hi = self:GetMinMaxValues();
	if hi <= lo then return; end

	local now = GetTime();

	-- FIX: si el disparo no sale (fuera de rango, sin objetivo, etc.) la barra
	-- se quedaba llena para siempre. Al terminar el ciclo se oculta y se
	-- resetea; el proximo disparo real la vuelve a arrancar.
	if now >= hi then
		self:SetMinMaxValues(0, 1);
		self:SetValue(0);
		textRight:SetText("");
		spark:ClearAllPoints();
		spark:SetPoint("CENTER", self, "LEFT", 0, 0);
		HideBar();
		return;
	end

	self:SetValue(now);

	local pct = (now - lo) / (hi - lo);
	spark:ClearAllPoints();
	spark:SetPoint("CENTER", self, "LEFT", pct * BAR_WIDTH, 0);

	-- El texto solo muestra un decimal, asi que cambia 10 veces por segundo
	-- como mucho. Antes se llamaba a format() y SetText() en CADA fotograma:
	-- 60 cadenas nuevas por segundo, 50 de ellas identicas a la anterior.
	-- En 3.3.5 esa basura se paga en tirones del recolector.
	local decimas = floor((hi - now) * 10);
	if decimas ~= self.lastDecimas then
		self.lastDecimas = decimas;
		textRight:SetText(format("%0.1f", hi - now));
	end
end);

-- ---------------------------------------------------------
-- Eventos
-- ---------------------------------------------------------
local events = CreateFrame("Frame");
events:SetScript("OnEvent", function(self, event, arg1, arg2)
	if not enabled then return; end

	if event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
		if arg2 == AUTO_SHOT or arg2 == FEIGN_DEATH then
			OnStart(arg2);
		end
	elseif event == "START_AUTOREPEAT_SPELL" then
		ShowBar();
	elseif event == "STOP_AUTOREPEAT_SPELL" or event == "PLAYER_ENTERING_WORLD" then
		HideBar();
	end
end);

-- ---------------------------------------------------------
-- Comandos
-- ---------------------------------------------------------
SLASH_NUFAUTOSHOT1 = "/nufshot";
SlashCmdList["NUFAUTOSHOT"] = function(msg)
	msg = string.lower(msg or "");
	local cmd, val = string.match(msg, "^(%a*)%s*(.*)$");

	if cmd == "unlock" or cmd == "move" then
		Unlock();
		print("|cff4FC3F7NUF:|r Auto Shot - arrastrá la barra. /nufshot lock para fijarla.");
	elseif cmd == "lock" then
		Lock();
		print("|cff4FC3F7NUF:|r Auto Shot - barra fijada.");
	elseif cmd == "scale" then
		local s = tonumber(val);
		if s and s >= 0.5 and s <= 2.5 then
			DB().scale = s;
			mover:SetScale(s);
			print("|cff4FC3F7NUF:|r Auto Shot - escala: " .. string.format("%.1f", s));
		else
			print("|cff4FC3F7NUF:|r Uso: /nufshot scale <0.5 - 2.5>");
		end
	elseif cmd == "reset" then
		local db = DB();
		db.x, db.y, db.scale = 0, 246, 1.0;
		RestorePosition();
		Lock();
		print("|cff4FC3F7NUF:|r Auto Shot - posición y escala reiniciadas.");
	else
		print("|cff4FC3F7NUF:|r /nufshot unlock | lock | scale <n> | reset");
	end
end


-- Reset externo (boton del panel)
function K.ResetAutoShotTimerPosition()
	local db = DB();
	db.x, db.y, db.scale = 0, 246, 1.0;
	RestorePosition();
	Lock();
end

-- ---------------------------------------------------------
-- Registro del modulo
-- ---------------------------------------------------------
K.RegisterModule("AutoShotTimer", {
	name    = L["MOD_AUTOSHOT"] or "Auto Shot Timer",
	desc    = L["MOD_AUTOSHOT_DESC"] or "Hunter auto shot timing bar. /nufshot unlock to move it.",
	default = false,
	configLabel = L["BTN_MODULE_MOVE"] or "Move",
	configFunc = function()
		if unlocked then Lock(); else Unlock(); end
	end,
	onEnable = function()
		enabled = true;
		RestorePosition();
		ApplyBorderStyle();
		events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
		events:RegisterEvent("START_AUTOREPEAT_SPELL");
		events:RegisterEvent("STOP_AUTOREPEAT_SPELL");
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		unlocked = false;
		mover:Hide();
	end,
});
