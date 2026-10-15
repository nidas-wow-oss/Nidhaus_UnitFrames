local AddOnName = ...;
-- Este addon se carga a pedido (ver Core/ArenaLoader.lua del addon
-- principal), asi que el "..." de arriba NO trae el namespace de NUF: es el
-- suyo propio. El de NUF se publica como global en Core/Init.lua.
local ns = NidhausUnitFramesNS;
local K, C, L = unpack(ns);

-- =========================================================
-- ArenaRoVPillarTimer.lua
-- Temporizador de los pilares de la Arena Circulo de Valor.
-- Los pilares cambian cada 25s, desde que arranca la partida.
-- Mover: Alt + click izquierdo y arrastrar.
-- =========================================================

-- EL PRIMERO A LOS 50 SEGUNDOS, DESPUES CADA 25.
--
-- Esto cambio dos veces y conviene dejar escrito por que.
--
-- Empezo en 45 s (el valor del codigo de TrinityCore) y despues 25. Como
-- en el servidor los ciclos que se repiten son de 25, se bajo el primero
-- a 25 tambien -- y ahi quedo corrido al reves: el primer pilar sale a
-- los 50 s de que se abren las puertas, no a los 25. Medido en el
-- servidor, que es lo unico que vale: el codigo de TrinityCore no coincide.
--
-- Asi que son dos numeros distintos y no uno solo.
local FIRST_CYCLE  = 50;   -- desde que empieza la arena hasta el 1er pilar
local NEXT_CYCLE   = 25;   -- y de ahi en adelante
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

-- Mismo criterio que el timer de fin de arena: tipo de instancia (no el
-- estado de la cola, que al salir sigue diciendo "activa" un momento) y
-- partida sin ganador.
local function InArena()
	local inInstance, instanceType = IsInInstance();
	return inInstance and instanceType == "arena";
end

local function MatchOver()
	return GetBattlefieldWinner and GetBattlefieldWinner() ~= nil;
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
-- El numero lo pone frame.text. Sin esto OmniCC le dibujaba OTRO numero
-- encima del mismo reloj y se veian dos tiempos, uno debajo del otro.
frame.cooldown.noCooldownCount = true;   -- OmniCC respeta esta bandera
frame.cooldown.noOCC = true;             -- (versiones viejas de OmniCC)

-- EL NUMERO, ENCIMA DEL RELOJ Y CON LA LETRA DEL OJO.
--
-- Dos cosas estaban mal:
--   * la tipografia era NumberFontNormalHuge y la del ojo (Vista de las
--     Sombras) es PVPInfoTextFont: se pidio que fueran iguales;
--   * el numero vivia en el OVERLAY del marco, pero el reloj es un FRAME
--     HIJO, y todo lo que dibuja un hijo va POR ENCIMA de las capas del
--     padre. O sea que el barrido oscuro del reloj le pasaba por arriba
--     al numero y se veia apagado.
--
-- La solucion es la de siempre: un frame propio, un nivel por encima del
-- reloj, y el texto adentro.
frame.textLayer = CreateFrame("Frame", nil, frame);
frame.textLayer:SetAllPoints();
frame.textLayer:SetFrameLevel((frame.cooldown:GetFrameLevel() or 0) + 1);

frame.text = frame.textLayer:CreateFontString(nil, "OVERLAY", "PVPInfoTextFont");
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
	-- Fijado desde el panel: no se mueve ni con Alt.
	if K.ArenaTimersLocked then return; end
	if IsAltKeyDown() or K.ArenaTimersUnlocked then self:StartMoving(); end
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
		if not testMode and (not InArena() or MatchOver()) then
			Stop();
			return;
		end
	end

	local remaining = endTime - GetTime();
	if remaining <= 0 then
		-- En la prueba no hay otro ciclo: al llegar a 0 se esconden todos
		-- los timers juntos Y se sale del modo mover. Antes esto llamaba a
		-- StopArenaTimerTests, que con "Mover" encendido los volvia a
		-- arrancar: no se iban nunca.
		if testMode then
			if K.ExitArenaTimersMoving then K.ExitArenaTimersMoving(); else Stop(); end
			return;
		end
		StartCycle(NEXT_CYCLE);
		return;
	end
	self.text:SetFormattedText("%.0f", remaining);   -- sin basura
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
-- La PRUEBA usa el ciclo corto, no el primero: sirve para acomodar el
-- marco, y esperar 50 s para eso no tiene sentido. Ademas ArenaEndTimer
-- corta la prueba a los 25 s, asi que con FIRST_CYCLE nunca se veia
-- llegar a 0.
K.ArenaTimerTests[KEY] = function()
	if frame:IsShown() and testMode then Stop(); else Start(NEXT_CYCLE, true); end
end;

-- /nuftimers: arrancar / cortar la prueba SIN tocar un timer de verdad
-- (si estas en una arena y ya esta corriendo, se queda como esta).
K.ArenaTimerTestStart = K.ArenaTimerTestStart or {};
K.ArenaTimerTestStop  = K.ArenaTimerTestStop  or {};
K.ArenaTimerTestStart[KEY] = function()
	if not frame:IsShown() then Start(NEXT_CYCLE, true); end
end;
K.ArenaTimerTestStop[KEY] = function()
	if testMode then Stop(); end
end;

-- Lo consulta la cascada de Dalaran: ella solo cierra el ciclo de prueba
-- si ESTE no esta corriendo (los pilares pueden estar apagados en las
-- opciones, o la arena puede no ser el Circulo del Valor). El de pilares
-- manda porque su ciclo es mas corto.
function K.IsArenaRoVTestRunning()
	return (frame:IsShown() and testMode) and true or false;
end

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
	if IsArenaStartMessage(msg) and InArena() and IsRingOfValor() then
		Start(FIRST_CYCLE, false);
	end
end);

RestorePosition();
