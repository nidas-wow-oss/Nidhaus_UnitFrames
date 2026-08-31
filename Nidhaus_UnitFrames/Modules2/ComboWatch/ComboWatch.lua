local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ComboWatch.lua  (integrado a NUF)
-- Fuente: !ComboWatch 3.3.5
--
-- QUE HACE: numero grande con los puntos de combo, coloreado segun
-- cuantos llevas (1 verde, 2 celeste, 3 amarillo, 4 naranja, 5 rojo).
-- Al llegar a 5 aparece un marco rojo que late, y se va cuando gastas
-- los puntos.
--
-- Solo tiene sentido para PICARO y DRUIDA: son las unicas dos clases
-- que generan puntos de combo. Para el resto ni se crea el frame.
--
-- CAMBIOS respecto del addon suelto:
--   * Se prende y apaga desde Interface > <tu clase>. Con el modulo
--     apagado no registra UNIT_COMBO_POINTS.
--   * Se puede MOVER (antes estaba clavado en el centro) y la posicion
--     se guarda en la DB de NUF.
--   * El PlaySoundFile del original apuntaba a Res\Alert.ogg, un archivo
--     que NO viene en el addon. Se saco: en 3.3.5a PlaySoundFile con una
--     ruta invalida no avisa, simplemente no suena, asi que era codigo
--     muerto que confundia.
-- =========================================================

local FONT = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\ComboWatch\\Res\\RESEGRG_.TTF";

local _, playerClass = UnitClass("player");
local CAN_HAVE_COMBO = (playerClass == "ROGUE" or playerClass == "DRUID");

local enabled = false;
local frame, animFrame, text;
local lastValue = 0;
local preview   = false;

-- ---------------------------------------------------------
-- DB
-- ---------------------------------------------------------
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.ComboWatch then NidhausUnitFramesDB.ComboWatch = {}; end
	return NidhausUnitFramesDB.ComboWatch;
end

local function IsLocked()
	return C.ComboWatchLocked == true;
end

-- ---------------------------------------------------------
-- Colores por cantidad de puntos
-- ---------------------------------------------------------
local function Colorize(p)
	if p == 1 then return 0, 1, 0, 1; end
	if p == 2 then return 0.4, 0.7, 1, 1; end
	if p == 3 then return 1, 1, 0, 1; end
	if p == 4 then return 1, 0.5, 0.2, 1; end
	if p == 5 then return 1, 0, 0, 1; end
	return 1, 1, 1, 1;
end

-- ---------------------------------------------------------
-- Construccion
-- ---------------------------------------------------------
local function Build()
	if frame then return; end

	frame = CreateFrame("Frame", "NUF_ComboWatch", UIParent);
	frame:SetSize(50, 50);
	frame:SetFrameStrata("HIGH");
	frame:SetMovable(true);
	-- Bloqueado = transparente al mouse, para no comerse los clicks de
	-- lo que haya detras (barras de accion, marcos, el mundo).
	frame:EnableMouse(not IsLocked());
	frame:SetClampedToScreen(true);

	text = frame:CreateFontString(nil, "OVERLAY");
	text:SetPoint("CENTER", frame, "CENTER", 0, 0);
	text:SetFont(FONT, 30, "THICKOUTLINE");
	text:SetShadowColor(0, 0, 0, 0.75);
	text:SetShadowOffset(3, -3);
	text:SetJustifyH("CENTER");
	text:SetVertexColor(1, 1, 1, 1);

	-- ── Marco animado de "5 puntos" ──
	animFrame = CreateFrame("Frame", "NUF_ComboWatchAnim", frame);
	animFrame:SetSize(50, 45);
	animFrame:SetPoint("CENTER", frame, "CENTER", 0, 3);
	animFrame:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1));

	frame.Pulse = animFrame:CreateAnimationGroup();
	local pulseAnim = frame.Pulse:CreateAnimation("SCALE");
	pulseAnim:SetScale(0.5, 1);
	pulseAnim:SetDuration(0.5);
	pulseAnim:SetSmoothing("OUT");
	frame.Pulse:SetLooping("BOUNCE");

	frame.FadeIn = animFrame:CreateAnimationGroup();
	local fadeInAnim = frame.FadeIn:CreateAnimation("ALPHA");
	fadeInAnim:SetChange(1);
	fadeInAnim:SetDuration(0.5);
	fadeInAnim:SetSmoothing("IN");
	frame.FadeIn:SetScript("OnPlay",     function() animFrame:SetAlpha(0); end);
	frame.FadeIn:SetScript("OnFinished", function()
		animFrame:SetAlpha(1);
		frame.Pulse:Play();
	end);

	frame.FadeOut = animFrame:CreateAnimationGroup();
	local fadeOutAnim = frame.FadeOut:CreateAnimation("ALPHA");
	fadeOutAnim:SetChange(-1);
	fadeOutAnim:SetDuration(0.5);
	fadeOutAnim:SetSmoothing("OUT");
	frame.FadeOut:SetScript("OnPlay", function()
		animFrame:SetAlpha(1);
		frame.Pulse:Stop();
	end);
	frame.FadeOut:SetScript("OnFinished", function() animFrame:SetAlpha(0); end);

	local bg = animFrame:CreateTexture(nil, "ARTWORK");
	bg:SetTexture("Interface\\LevelUp\\LevelUpTex");
	bg:SetTexCoord(0.56054688, 0.99609375, 0.24218750, 0.46679688);
	bg:SetVertexColor(1, 0, 0, 1);
	bg:SetPoint("BOTTOM", animFrame, "BOTTOM", 0, 0);
	bg:SetSize(300, 115);

	local top = animFrame:CreateTexture(nil, "OVERLAY");
	top:SetTexture("Interface\\LevelUp\\LevelUpTex");
	top:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313);
	top:SetVertexColor(1, 0, 0, 1);
	top:SetPoint("TOP", animFrame, "TOP", 0, 0);
	top:SetSize(418, 7);

	local bottom = animFrame:CreateTexture(nil, "OVERLAY");
	bottom:SetTexture("Interface\\LevelUp\\LevelUpTex");
	bottom:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313);
	bottom:SetVertexColor(1, 0, 0, 1);
	bottom:SetPoint("BOTTOM", animFrame, "BOTTOM", 0, -0.5);
	bottom:SetSize(418, 7);

	animFrame:SetAlpha(0);

	-- ── Arrastre ──
	frame:RegisterForDrag("LeftButton");
	frame:SetScript("OnDragStart", function(self)
		if IsLocked() then return; end
		self:StartMoving();
	end);
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing();
		local db = DB();
		local point, _, relativePoint, x, y = self:GetPoint();
		db.point, db.relativePoint, db.x, db.y = point, relativePoint, x, y;
	end);
end

local function RestorePosition()
	if not frame then return; end
	local db = DB();
	frame:ClearAllPoints();
	if db.point then
		frame:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 1, -185);
	end
	frame:SetScale(db.scale or 1);
end

function K.ResetComboWatchPosition()
	local db = DB();
	db.point, db.relativePoint, db.x, db.y = nil, nil, nil, nil;
	RestorePosition();
end

-- ---------------------------------------------------------
-- Actualizacion
-- ---------------------------------------------------------
local function Update()
	if not frame or not enabled then return; end
	if preview then return; end

	local value = GetComboPoints("player") or 0;

	if value > 0 then
		text:SetText(value);
	else
		text:SetText(nil);
	end
	text:SetVertexColor(Colorize(value));

	if value == 5 and lastValue ~= 5 then
		frame.FadeIn:Play();
	elseif lastValue == 5 and value ~= 5 then
		frame.FadeOut:Play();
	end

	lastValue = value;
end

-- ---------------------------------------------------------
-- Modo "mostrar para acomodar"
-- ---------------------------------------------------------
function K.SetComboWatchPreview(state)
	if not CAN_HAVE_COMBO then return; end
	Build();
	preview = state and true or false;
	frame:EnableMouse(preview or not IsLocked());
	if preview then
		RestorePosition();
		text:SetText("5");
		text:SetVertexColor(Colorize(5));
		animFrame:SetAlpha(1);
		frame:Show();
	else
		animFrame:SetAlpha(0);
		lastValue = 0;
		Update();
	end
end

-- La llama el checkbox de "Fijarlo en su lugar" del panel
function K.ApplyComboWatchLock()
	if not frame then return; end
	frame:EnableMouse(preview or not IsLocked());
end

function K.IsComboWatchPreview()
	return preview;
end

-- ---------------------------------------------------------
-- Eventos (solo con el modulo activo)
-- ---------------------------------------------------------
local events = CreateFrame("Frame");
events:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_ENTERING_WORLD" then
		RestorePosition();
		Update();
		return;
	end
	if event == "UNIT_COMBO_POINTS" and unit ~= "player" then return; end
	Update();
end);

-- ---------------------------------------------------------
-- Registro del modulo
-- ---------------------------------------------------------
if CAN_HAVE_COMBO then
	K.RegisterModule("ComboWatch", {
		name    = L["MOD_COMBOWATCH"] or "Combo Points",
		desc    = L["MOD_COMBOWATCH_DESC"]
			or "Big combo point counter, colored by amount, with a pulsing frame at 5 points.",
		default = false,
		onEnable = function()
			enabled = true;
			Build();
			RestorePosition();
			events:RegisterEvent("PLAYER_ENTERING_WORLD");
			events:RegisterEvent("PLAYER_TARGET_CHANGED");
			events:RegisterEvent("UNIT_COMBO_POINTS");
			lastValue = 0;
			frame:Show();
			Update();
		end,
		onDisable = function()
			enabled = false;
			preview = false;
			events:UnregisterAllEvents();
			if frame then
				frame:Hide();
				animFrame:SetAlpha(0);
			end
		end,
	});
end

SLASH_NUFCOMBO1 = "/nufcombo";
SlashCmdList["NUFCOMBO"] = function(msg)
	if not CAN_HAVE_COMBO then
		print("|cff4FC3F7NUF:|r " .. (L["COMBOWATCH_WRONG_CLASS"]
			or "Only rogues and druids generate combo points."));
		return;
	end
	msg = string.lower(msg or "");
	if msg == "show" or msg == "move" then
		K.SetComboWatchPreview(true);
	elseif msg == "hide" then
		K.SetComboWatchPreview(false);
	elseif msg == "reset" then
		K.ResetComboWatchPosition();
	else
		print("|cff4FC3F7NUF:|r /nufcombo show | hide | reset");
	end
end
