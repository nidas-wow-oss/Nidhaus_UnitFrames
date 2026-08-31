local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ArenaRoVPillarTimer.lua
-- Temporizador de los pilares de la Arena Circulo de Valor.
-- Primer ciclo: 45s desde el inicio. Luego se repite cada 25s.
-- Mover: Alt + click izquierdo y arrastrar.
-- =========================================================

local FIRST_CYCLE  = 45;
local NEXT_CYCLE   = 25;
local KEY          = "RoVPillars";

-- ---------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------
local function IsArenaStartMessage(msg)
	if not msg or msg == "" then return false; end
	return string.find(msg, "battle in the arena has begun")
		or string.find(msg, "Arena battle has begun")
		or string.find(msg, "arena has begun")
		or string.find(msg, "batalla de arena ha comenzado")
		or string.find(msg, "batalla en la arena ha comenzado")
		or string.find(msg, "combate en la arena ha comenzado");
end

local function IsRingOfValor()
	local zone = GetRealZoneText() or "";
	return string.find(zone, "Ring of Valor") ~= nil
		or string.find(zone, "Valor") ~= nil;
end

-- ---------------------------------------------------------
-- Frame
-- ---------------------------------------------------------
local frame = CreateFrame("Frame", "NUF_RoVPillarTimer", UIParent);
-- Escala configurable desde el panel (registro central en ScaleAPI).
if K.RegisterScalable then K.RegisterScalable("ArenaRoVPillarTimer", frame, 1.0); end
frame:SetSize(40, 40);
frame:Hide();

frame.texture = frame:CreateTexture(nil, "BORDER");
frame.texture:SetAllPoints();
frame.texture:SetTexture("Interface\\Icons\\Ability_Smash");
frame.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93);

frame.border = frame:CreateTexture(nil, "BACKGROUND");
frame.border:SetPoint("TOPLEFT", -1, 1);
frame.border:SetPoint("BOTTOMRIGHT", 1, -1);
frame.border:SetTexture(0, 0, 0, 1);

frame.cooldown = CreateFrame("Cooldown", "NUF_RoVPillarTimerCD", frame);
frame.cooldown:SetAllPoints();
frame.cooldown:SetDrawEdge(true);

frame.text = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge");
frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0);
frame.text:SetTextHeight(18);

-- ---------------------------------------------------------
-- Posicion guardada / arrastre
-- ---------------------------------------------------------
local function SavePosition()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.timerPos then NidhausUnitFramesDB.timerPos = {}; end
	local point, _, relativePoint, x, y = frame:GetPoint();
	-- SIN PUNTO NO SE GUARDA NADA.
	--
	-- Si el marco quedo sin anclaje (por ejemplo despues de un Reset del
	-- Move Everything, que hace ClearAllPoints), GetPoint devuelve nil y
	-- esto guardaba { point = nil, ... }, o sea UNA TABLA VACIA. Despues
	-- RestorePosition la veia y llamaba a SetPoint con un punto nil:
	-- ese era el error del timer.
	if not point then
		NidhausUnitFramesDB.timerPos[KEY] = nil;
		return;
	end
	NidhausUnitFramesDB.timerPos[KEY] = {
		point = point, relativePoint = relativePoint, x = x, y = y,
	};
end

local function RestorePosition()
	local pos = NidhausUnitFramesDB and NidhausUnitFramesDB.timerPos and NidhausUnitFramesDB.timerPos[KEY];
	frame:ClearAllPoints();
	-- Se pide el PUNTO, no la tabla: una tabla vacia tambien es "verdadera"
	-- en Lua, y con ella SetPoint reventaba.
	if pos and pos.point then
		frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y);
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", -80, 120);
	end
end

frame:SetMovable(true);
frame:EnableMouse(true);
frame:SetClampedToScreen(true);
frame:RegisterForDrag("LeftButton");
frame:SetScript("OnDragStart", function(self)
	if IsAltKeyDown() then self:StartMoving(); end
end);
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing();
	SavePosition();
end);

-- ---------------------------------------------------------
-- Logica
-- ---------------------------------------------------------
local endTime   = 0;
local checkAcc  = 0;
local testMode  = false;

local function Stop()
	frame:Hide();
	frame:SetScript("OnUpdate", nil);
	frame.text:SetText("");
	endTime  = 0;
	checkAcc = 0;
	testMode = false;
end

local function StartCycle(duration)
	endTime = GetTime() + duration;
	CooldownFrame_SetTimer(frame.cooldown, GetTime(), duration, 1);
end

local function OnUpdate(self, elapsed)
	-- Salir si ya no estamos en arena (chequeo barato, 1x por segundo)
	checkAcc = checkAcc + elapsed;
	if checkAcc >= 1 then
		checkAcc = 0;
		if not testMode and not IsActiveBattlefieldArena() then
			Stop();
			return;
		end
	end

	local remaining = endTime - GetTime();
	if remaining <= 0 then
		StartCycle(NEXT_CYCLE);
		return;
	end
	self.text:SetText(string.format("%.0f", remaining));
end

local function Start(duration, isTest)
	testMode = isTest and true or false;
	RestorePosition();
	frame:Show();
	StartCycle(duration or FIRST_CYCLE);
	checkAcc = 0;
	frame:SetScript("OnUpdate", OnUpdate);
end

K.ArenaTimerTests = K.ArenaTimerTests or {};
K.ArenaTimerTests[KEY] = function()
	if frame:IsShown() and testMode then Stop(); else Start(FIRST_CYCLE, true); end
end;

local events = CreateFrame("Frame");
events:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL");
events:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		Stop();
		return;
	end

	if not C.ArenaRoVPillarTimer then return; end

	local msg = select(1, ...);
	if IsArenaStartMessage(msg) and IsRingOfValor() then
		Start(FIRST_CYCLE, false);
	end
end);

RestorePosition();
