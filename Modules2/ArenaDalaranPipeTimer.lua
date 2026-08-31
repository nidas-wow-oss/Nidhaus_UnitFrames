local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ArenaDalaranPipeTimer.lua
-- Temporizador de la cascada de la Arena de Dalaran (Warmane).
--
-- CICLO REAL (verificado contra la WeakAura de Warmane):
--   ciclo total = 70s, contado desde "The Arena battle has begun!"
--     0s  - 30s  -> fase A (30s)  : cuenta 30 -> 0
--     30s - 70s  -> fase B (40s)  : cuenta 40 -> 0
--   y vuelve a empezar. Se repite toda la arena.
--
-- Mover: Alt + click izquierdo y arrastrar.
-- =========================================================

local CYCLE_TOTAL = 70;
local PHASE_A     = 30;
local KEY         = "DalaranPipe";

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

local function IsDalaranArena()
	local zone = GetRealZoneText() or "";
	return string.find(zone, "Dalaran") ~= nil;
end

-- ---------------------------------------------------------
-- Frame
-- ---------------------------------------------------------
local frame = CreateFrame("Frame", "NUF_DalaranPipeTimer", UIParent);
-- Escala configurable desde el panel (registro central en ScaleAPI).
if K.RegisterScalable then K.RegisterScalable("ArenaDalaranPipeTimer", frame, 1.0); end
frame:SetSize(120, 42);
frame:Hide();

frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
frame.label:SetPoint("TOP", frame, "TOP", 0, 0);
frame.label:SetTextHeight(12);
frame.label:SetText("WATERFALL");

frame.text = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge");
frame.text:SetPoint("TOP", frame.label, "BOTTOM", 0, -2);
frame.text:SetTextHeight(24);

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
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 180);
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
-- Logica del ciclo
-- ---------------------------------------------------------
local startTime = nil;
local testMode  = false;
local checkAcc  = 0;

local function Stop()
	frame:Hide();
	frame:SetScript("OnUpdate", nil);
	frame.text:SetText("");
	startTime = nil;
	testMode  = false;
	checkAcc  = 0;
end

local function OnUpdate(self, elapsed)
	if not startTime then Stop(); return; end

	-- Salir si ya no estamos en arena (chequeo barato, 1x por segundo)
	checkAcc = checkAcc + elapsed;
	if checkAcc >= 1 then
		checkAcc = 0;
		if not testMode and not IsActiveBattlefieldArena() then Stop(); return; end
	end

	local cycle = math.fmod(GetTime() - startTime, CYCLE_TOTAL);
	local remaining, phaseA;

	if cycle <= PHASE_A then
		remaining = PHASE_A - cycle;
		phaseA = true;
	else
		remaining = CYCLE_TOTAL - cycle;
		phaseA = false;
	end

	self.text:SetText(string.format("%d", math.floor(remaining)));

	-- Amarillo mientras falta, rojo en los ultimos 5 segundos
	if remaining <= 5 then
		self.text:SetTextColor(1, 0.25, 0.25);
		self.label:SetTextColor(1, 0.25, 0.25);
	elseif phaseA then
		self.text:SetTextColor(1, 0.75, 0);
		self.label:SetTextColor(1, 0.75, 0);
	else
		self.text:SetTextColor(0.4, 0.8, 1);
		self.label:SetTextColor(0.4, 0.8, 1);
	end
end

local function Start(isTest)
	testMode  = isTest and true or false;
	startTime = GetTime();
	checkAcc  = 0;
	RestorePosition();
	frame:Show();
	frame:SetScript("OnUpdate", OnUpdate);
end

K.ArenaTimerTests = K.ArenaTimerTests or {};
K.ArenaTimerTests[KEY] = function()
	if frame:IsShown() and testMode then Stop(); else Start(true); end
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

	if not C.ArenaDalaranPipeTimer then return; end

	local msg = select(1, ...);
	if IsArenaStartMessage(msg) and IsDalaranArena() then
		Start(false);
	end
end);

RestorePosition();
