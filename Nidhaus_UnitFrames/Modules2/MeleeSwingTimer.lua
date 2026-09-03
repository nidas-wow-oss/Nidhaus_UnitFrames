local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local format, floor = string.format, math.floor;

-- =========================================================
-- MeleeSwingTimer.lua
-- Barra con el tiempo hasta tu proximo golpe cuerpo a cuerpo (white hit).
--
-- Como funciona: escucha el combat log propio (SWING_DAMAGE / SWING_MISSED)
-- y arranca una barra con la velocidad de tu arma principal.
-- La velocidad se relee en cada golpe, asi que respeta buffs de haste.
--
-- NOTA: en 3.3.5a el combat log no distingue mano principal de secundaria
-- en los golpes blancos, asi que la barra sigue la MANO PRINCIPAL.
--
-- Mover: /nufswing unlock -> arrastrar -> /nufswing lock
-- =========================================================

local BAR_WIDTH  = 195;
local BAR_HEIGHT = 14;

local enabled  = false;
local unlocked = false;

local playerGUID;

-- ---------------------------------------------------------
-- DB
-- ---------------------------------------------------------
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.MeleeSwingTimer then
		NidhausUnitFramesDB.MeleeSwingTimer = { x = 0, y = 222, scale = 1.0 };
	end
	return NidhausUnitFramesDB.MeleeSwingTimer;
end

-- ---------------------------------------------------------
-- Frames
-- ---------------------------------------------------------
local mover = CreateFrame("Frame", "NUF_SwingMover", UIParent);
mover:SetSize(BAR_WIDTH + 4, BAR_HEIGHT + 4);
mover:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 222);
mover:SetMovable(true);
mover:SetClampedToScreen(true);
mover:EnableMouse(false);
mover:Hide();

local bar = CreateFrame("StatusBar", "NUF_SwingBar", mover);
bar:SetSize(BAR_WIDTH, BAR_HEIGHT);
bar:SetPoint("CENTER", mover, "CENTER", 0, 0);
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
bar:SetStatusBarColor(0.85, 0.25, 0.25);
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
textLeft:SetPoint("LEFT", bar, "LEFT", 4, 0);
textLeft:SetText(L["SWING_LABEL"] or "Auto attack");

local textRight = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
textRight:SetPoint("RIGHT", bar, "RIGHT", -4, 0);

local unlockOverlay = mover:CreateTexture(nil, "OVERLAY");
unlockOverlay:SetAllPoints(mover);
unlockOverlay:SetTexture(0, 0.8, 1, 0.25);
unlockOverlay:Hide();

local unlockText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
unlockText:SetPoint("CENTER", mover, "CENTER", 0, 0);
unlockText:SetText("|cff00ccff" .. (L["DRAG_LABEL"] or "DRAG") .. "|r");
unlockText:Hide();

-- ---------------------------------------------------------
-- Posicion / escala
-- ---------------------------------------------------------
local function SavePosition()
	local db = DB();
	local _, _, _, x, y = mover:GetPoint();
	db.x = x or 0;
	db.y = y or 222;
end

local function RestorePosition()
	local db = DB();
	mover:ClearAllPoints();
	mover:SetPoint("BOTTOM", UIParent, "BOTTOM", db.x or 0, db.y or 222);
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
-- Estilo del borde
--
-- "Tooltip" es el de siempre. El otro copia el de las barras de casteo, que
-- es el mismo que usan las de arena. La textura y las proporciones NO se
-- escriben a mano: se leen en vivo de CastingBarFrame, la barra de casteo
-- del jugador, que mide 195x13 — practicamente lo mismo que esta barra. Asi
-- el borde acompaña a lo que esa barra tenga puesto y no hay medidas de
-- Blizzard adivinadas.
-- ---------------------------------------------------------
local castBorder;   -- se crea recien si el estilo lo pide

local function BorderTint(r, g, b, a)
	if castBorder and castBorder:IsShown() then
		castBorder:SetVertexColor(r, g, b, a);
	else
		border:SetBackdropBorderColor(r, g, b, a);
	end
end

local function ApplyBorderStyle()
	if C.SwingTimerCastBarSkin == true then
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
			-- texto. Se copia ese mismo corrimiento, a escala de esta barra.
			local _, sy = src:GetCenter();
			local _, ry = ref:GetCenter();
			local dy = (sy and ry) and ((sy - ry) * (BAR_HEIGHT / ref:GetHeight())) or 0;
			castBorder:SetPoint("CENTER", bar, "CENTER", 0, dy);
			castBorder:Show();
			border:Hide();
			BorderTint(1, 1, 1, 1);
			if unlocked then BorderTint(0, 0.8, 1, 1); end
			return;
		end
	end
	if castBorder then castBorder:Hide(); end
	border:Show();
	border:SetBackdropBorderColor(unlocked and 0 or 0.6, unlocked and 0.8 or 0.6,
		unlocked and 1 or 0.6, unlocked and 1 or 0.9);
end

function K.GetMeleeSwingBorderStyle()
	return (C.SwingTimerCastBarSkin == true) and "CastBar" or "Tooltip";
end

function K.ToggleMeleeSwingBorderStyle()
	local v = not (C.SwingTimerCastBarSkin == true);
	K.SaveConfig("SwingTimerCastBarSkin", v);
	ApplyBorderStyle();
	return v;
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
	-- Si "Mover todo" ya esta activo, el frame lo maneja ESE modo: tener los
	-- dos a la vez ponia dos capas de arrastre encima y el frame quedaba
	-- pegado / imposible de soltar.
	if K.IsGlobalUnlocked and K.IsGlobalUnlocked() then
		print("|cff4FC3F7NUF:|r " .. (L["SWING_USE_GLOBAL"]
			or "Move Everything is on: drag the blue box from there."));
		return;
	end
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
local function StartSwing()
	if unlocked then return; end

	local mainSpeed = UnitAttackSpeed("player");
	if not mainSpeed or mainSpeed <= 0 then return; end

	local now = GetTime();
	bar:SetMinMaxValues(now, now + mainSpeed);
	bar:SetValue(now);
	textRight:SetText(string.format("%0.1f", mainSpeed));
	ShowBar();
end

bar:SetScript("OnUpdate", function(self)
	if unlocked then return; end

	local lo, hi = self:GetMinMaxValues();
	if hi <= lo then return; end

	local now = GetTime();

	-- FIX: la barra se quedaba clavada en 0.0. Al terminar el swing se
	-- resetea y se oculta; el proximo golpe la vuelve a arrancar.
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
events:SetScript("OnEvent", function(self, event, ...)
	if not enabled then return; end

	if event == "PLAYER_ENTERING_WORLD" then
		playerGUID = UnitGUID("player");
		RestorePosition();
		ApplyBorderStyle();
		HideBar();
		return;
	end

	if event == "PLAYER_REGEN_ENABLED" then
		-- Fuera de combate: dejar que la barra termine y se oculte sola
		return;
	end

	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, subEvent, sourceGUID = ...;
		if sourceGUID ~= playerGUID then return; end
		if subEvent == "SWING_DAMAGE" or subEvent == "SWING_MISSED" then
			StartSwing();
		end
	end
end);

-- ---------------------------------------------------------
-- Comandos
-- ---------------------------------------------------------
SLASH_NUFSWING1 = "/nufswing";
SlashCmdList["NUFSWING"] = function(msg)
	msg = string.lower(msg or "");
	local cmd, val = string.match(msg, "^(%a*)%s*(.*)$");

	if cmd == "unlock" or cmd == "move" then
		Unlock();
		print("|cff4FC3F7NUF:|r Swing Timer - arrastrá la barra. /nufswing lock para fijarla.");
	elseif cmd == "lock" then
		Lock();
		print("|cff4FC3F7NUF:|r Swing Timer - barra fijada.");
	elseif cmd == "scale" then
		local s = tonumber(val);
		if s and s >= 0.5 and s <= 2.5 then
			DB().scale = s;
			mover:SetScale(s);
			print("|cff4FC3F7NUF:|r Swing Timer - escala: " .. string.format("%.1f", s));
		else
			print("|cff4FC3F7NUF:|r Uso: /nufswing scale <0.5 - 2.5>");
		end
	elseif cmd == "reset" then
		local db = DB();
		db.x, db.y, db.scale = 0, 222, 1.0;
		RestorePosition();
		Lock();
		print("|cff4FC3F7NUF:|r Swing Timer - posición y escala reiniciadas.");
	else
		print("|cff4FC3F7NUF:|r /nufswing unlock | lock | scale <n> | reset");
	end
end


-- Reset externo (boton del panel)
function K.ResetMeleeSwingTimerPosition()
	local db = DB();
	db.x, db.y, db.scale = 0, 222, 1.0;
	RestorePosition();
	Lock();
end

-- ---------------------------------------------------------
-- API para el panel de opciones (boton mover + slider de escala)
-- ---------------------------------------------------------
function K.ToggleMeleeSwingUnlock()
	if unlocked then Lock(); else Unlock(); end
	return unlocked;
end

function K.IsMeleeSwingUnlocked()
	return unlocked;
end

function K.GetMeleeSwingScale()
	return DB().scale or 1.0;
end

function K.SaveMeleeSwingScale(s)
	s = tonumber(s) or 1.0;
	DB().scale = s;
	mover:SetScale(s);
end

-- ---------------------------------------------------------
-- Registro del modulo
-- ---------------------------------------------------------
K.RegisterModule("MeleeSwingTimer", {
	name    = L["MOD_SWINGTIMER"] or "Melee Swing Timer",
	desc    = L["MOD_SWINGTIMER_DESC"] or "Bar showing the time until your next melee white hit. /nufswing unlock to move it.",
	default = false,
	configLabel = L["BTN_MODULE_MOVE"] or "Move",
	configFunc = function()
		if unlocked then Lock(); else Unlock(); end
	end,
	onEnable = function()
		enabled = true;
		playerGUID = UnitGUID("player");
		RestorePosition();
		events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		events:RegisterEvent("PLAYER_REGEN_ENABLED");
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		unlocked = false;
		mover:Hide();
	end,
});
