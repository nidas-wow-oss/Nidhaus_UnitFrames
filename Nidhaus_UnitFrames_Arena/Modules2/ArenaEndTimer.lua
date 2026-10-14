local AddOnName = ...;
-- Este addon se carga a pedido (ver Core/ArenaLoader.lua del addon
-- principal), asi que el "..." de arriba NO trae el namespace de NUF: es el
-- suyo propio. El de NUF se publica como global en Core/Init.lua.
local ns = NidhausUnitFramesNS;
local K, C, L = unpack(ns);

-- =========================================================
-- ArenaEndTimer.lua
-- Tiempo restante hasta que termine la arena (empate por tiempo).
-- Mover: Alt + click izquierdo y arrastrar.
--
-- Duraciones: la mayoria de los servidores Blizzlike usan 30 min
-- (mensaje del sistema). Warmane usa 45 min (emote de boss).
-- Se toma siempre la duracion mas larga de las dos si llegan ambos.
-- =========================================================

local DURATION_SYSTEM = 1800;  -- 30 min
local DURATION_EMOTE  = 2700;  -- 45 min (Warmane)
local KEY             = "ArenaEnd";

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

local function FormatTime(seconds)
	if seconds < 0 then seconds = 0; end
	local minutes = math.floor(seconds / 60);
	local secs    = math.floor(seconds % 60);
	return string.format("%02d:%02d", minutes, secs);
end

-- ---------------------------------------------------------
-- Frame
-- ---------------------------------------------------------
local frame = CreateFrame("Frame", "NUF_ArenaEndTimer", UIParent);
-- Escala configurable desde el panel (registro central en ScaleAPI).
if K.RegisterScalable then K.RegisterScalable("ArenaEndTimer", frame, 1.0); end
frame:SetSize(90, 20);
frame:Hide();

frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0);
-- Mas chico que los textos de Blizzard de arriba: es informacion
-- secundaria y compitiendo en tamaño ensuciaba la zona.
frame.text:SetTextHeight(10);
frame.text:SetText("");

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
		-- INDEPENDIENTE de WorldStateAlwaysUpFrame.
		-- Antes se anclaba a ese frame ("TOP", ..., 0, -63) para quedar justo
		-- debajo de "Gold/Green Team: X Players Remaining". El problema es que
		-- varios addons (Capping, FriskesUI) mueven ESE frame de Blizzard, y
		-- algunos incluso le anulan SetPoint. Con el anclaje relativo, cada vez
		-- que uno de esos lo corria, el timer de NUF se iba con el — y parecia
		-- que lo movia NUF. Ahora va pegado a UIParent y se ubica solo.
		frame:SetPoint("TOP", UIParent, "TOP", 24, -72);
	end
end

-- Reset externo (boton del panel / slash)
function K.ResetArenaEndTimerPosition()
	if NidhausUnitFramesDB and NidhausUnitFramesDB.timerPos then
		NidhausUnitFramesDB.timerPos[KEY] = nil;
	end
	RestorePosition();
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
local endTime  = 0;
local updAcc   = 0;
local testMode = false;

-- DENTRO DE UNA ARENA = el tipo de instancia, no el estado de la cola.
--
-- Antes se preguntaba con IsActiveBattlefieldArena, que justo al salir de
-- la arena (en la pantalla de carga) todavia dice que si. El timer creia
-- que seguia adentro y quedaba contando en el mundo.
local function InArena()
	local inInstance, instanceType = IsInInstance();
	return inInstance and instanceType == "arena";
end

-- La partida ya termino: hay ganador y el marcador final esta en pantalla.
-- Lo que falta hasta que te sacan de la arena ya no es "tiempo de arena".
local function MatchOver()
	return GetBattlefieldWinner and GetBattlefieldWinner() ~= nil;
end

local function Stop()
	frame:Hide();
	frame:SetScript("OnUpdate", nil);
	frame.text:SetText("");
	endTime  = 0;
	updAcc   = 0;
	testMode = false;
end

local function OnUpdate(self, elapsed)
	updAcc = updAcc + elapsed;
	if updAcc < 0.2 then return; end
	updAcc = 0;

	-- SE APAGA SOLO CUANDO LA ARENA TERMINA.
	--
	-- Antes solo se cortaba al llegar a cero o al cargar una zona (y ahi
	-- con la pregunta de arriba, que fallaba). Terminabas la arena y el
	-- "Arena: 28:07" seguia en pantalla en Elwynn. Ahora se revisa en cada
	-- pasada, que es barato: fuera de la arena, partida con ganador u
	-- opcion apagada, y se va. El modo de prueba (/nuftimers) no se toca.
	if not testMode and (not C.ArenaEndTimer or not InArena() or MatchOver()) then
		Stop();
		return;
	end

	local remaining = endTime - GetTime();
	if remaining <= 0 then
		Stop();
		return;
	end

	-- Un solo SetFormattedText: el texto se arma en C y no deja strings de
	-- Lua sueltos (antes eran cuatro por vuelta, cinco veces por segundo).
	local label = (L["ARENA_END_PREFIX"] or "Arena: ");
	local secs = math.max(remaining, 0);
	local mm, ss = math.floor(secs / 60), math.floor(secs % 60);
	if remaining <= 60 then
		self.text:SetFormattedText("|cffFF4444%s%02d:%02d|r", label, mm, ss);
	elseif remaining <= 300 then
		self.text:SetFormattedText("|cffFFAA00%s%02d:%02d|r", label, mm, ss);
	else
		self.text:SetFormattedText("%s%02d:%02d", label, mm, ss);
	end
end

local function Start(duration, isTest)
	local newEnd = GetTime() + duration;
	-- Si ya corre, quedarse con la duracion mas larga
	if frame:IsShown() and newEnd <= endTime then return; end
	endTime = newEnd;
	testMode = isTest and true or false;
	RestorePosition();
	frame:Show();
	updAcc = 1;
	frame:SetScript("OnUpdate", OnUpdate);
end

K.ArenaTimerTests = K.ArenaTimerTests or {};
K.ArenaTimerTests[KEY] = function()
	if frame:IsShown() then Stop(); else Start(DURATION_EMOTE, true); end
end;

-- /nuftimers: arrancar / cortar la prueba SIN tocar un timer de verdad
-- (si estas en una arena y ya esta corriendo, se queda como esta).
K.ArenaTimerTestStart = K.ArenaTimerTestStart or {};
K.ArenaTimerTestStop  = K.ArenaTimerTestStop  or {};
K.ArenaTimerTestStart[KEY] = function()
	if not frame:IsShown() then Start(DURATION_EMOTE, true); end
end;
K.ArenaTimerTestStop[KEY] = function()
	if testMode then Stop(); end
end;

local events = CreateFrame("Frame");
events:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL");
events:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:RegisterEvent("ZONE_CHANGED_NEW_AREA");
events:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");
events:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		-- Al cargar fuera de una arena se apaga todo, prueba incluida.
		if not InArena() then Stop(); end
		return;
	end
	if event == "ZONE_CHANGED_NEW_AREA" or event == "UPDATE_BATTLEFIELD_STATUS" then
		-- Salir de la arena o que la partida tenga ganador lo apaga en el
		-- acto, sin esperar a la proxima pasada.
		if frame:IsShown() and not testMode and (not InArena() or MatchOver()) then
			Stop();
		end
		return;
	end

	if not C.ArenaEndTimer then return; end
	-- Solo dentro de una arena, y con la partida todavia en juego.
	if not InArena() or MatchOver() then return; end

	local msg = select(1, ...);
	if not IsArenaStartMessage(msg) then return; end

	if event == "CHAT_MSG_RAID_BOSS_EMOTE" then
		Start(DURATION_EMOTE);
	else
		Start(DURATION_SYSTEM);
	end
end);

RestorePosition();

-- =========================================================
-- /nuftimers  -> muestra/oculta todos los timers de arena
-- para poder reposicionarlos con Alt + arrastrar.
--
-- DURA 25 SEGUNDOS: un ciclo de los pilares del Circulo del Valor. Cuando
-- esa cuenta llega a 0 se esconden TODOS juntos, ya acomodados. Antes cada
-- uno seguia por su lado (el de pilares arrancaba otro ciclo, el de la
-- arena seguia 45 minutos) y habia que volver a escribir /nuftimers.
-- Escribirlo de nuevo antes de tiempo los esconde en el acto.
-- =========================================================
local TEST_SECONDS = 25;   -- un ciclo de pilares
local testLeft = 0;
local testTimer = CreateFrame("Frame");
testTimer:Hide();
testTimer:SetScript("OnUpdate", function(self, elapsed)
	testLeft = testLeft - elapsed;
	if testLeft <= 0 then K.StopArenaTimerTests(); end
end);

local function RunAll(list)
	for _, fn in pairs(list or {}) do
		local ok, err = pcall(fn);
		if not ok then print("|cffFF0000NUF:|r " .. tostring(err)); end
	end
end

-- Corta la prueba de todos los timers (lo llama tambien el de pilares al
-- llegar a 0). Un timer de verdad, de una arena en curso, no se toca.
-- =========================================================
-- MOVER LOS TIMERS (boton "Mover" de Arena > Timers)
--
-- Lo mismo que /nuftimers, pero:
--   * sin los 25 segundos: quedan a la vista hasta que apretas "Fijar";
--   * se arrastran SIN Alt (K.ArenaTimersUnlocked lo miran los cuatro).
-- Cuando el de pilares llega a 0 llama a StopArenaTimerTests: en este
-- modo eso no los esconde, los vuelve a arrancar.
-- =========================================================
local moveMode = false;

function K.IsArenaTimersMoving() return moveMode; end

-- ---------------------------------------------------------
-- FIJADO
--
-- Apretar "Fijar" tiene que dejarlos quietos de verdad: ni con Alt. Se
-- guarda, asi sigue fijado despues de reloguear. De fabrica NO esta
-- fijado, para no romperle el Alt + arrastrar a quien nunca toco el boton.
-- ---------------------------------------------------------
local function LockedDB(v)
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if v ~= nil then NidhausUnitFramesDB.ArenaTimersLocked = v and true or false; end
	return NidhausUnitFramesDB.ArenaTimersLocked and true or false;
end

function K.AreArenaTimersLocked() return K.ArenaTimersLocked and true or false; end

-- La SavedVariable recien existe en ADDON_LOADED: de ahi se repone.
local lockLoad = CreateFrame("Frame");
lockLoad:RegisterEvent("ADDON_LOADED");
lockLoad:SetScript("OnEvent", function(self, _, addon)
	if addon ~= AddOnName then return; end
	self:UnregisterEvent("ADDON_LOADED");
	K.ArenaTimersLocked = LockedDB();
end);

function K.StopArenaTimerTests()
	testTimer:Hide();
	RunAll(K.ArenaTimerTestStop);
	if moveMode then RunAll(K.ArenaTimerTestStart); end
end

function K.SetArenaTimersMoving(on)
	on = on and true or false;
	if on == moveMode then return moveMode; end
	moveMode = on;
	K.ArenaTimersUnlocked = on;
	-- Mover = desbloquear; Fijar = bloquear (y se guarda).
	K.ArenaTimersLocked = not on;
	LockedDB(not on);
	testTimer:Hide();
	if on then
		RunAll(K.ArenaTimerTestStart);
	else
		RunAll(K.ArenaTimerTestStop);
	end
	-- El boton del panel (si esta abierto) cambia de texto.
	if K._OnArenaTimersMoving then pcall(K._OnArenaTimersMoving, on); end
	return moveMode;
end

SLASH_NUFARENATIMERS1 = "/nuftimers";
SlashCmdList["NUFARENATIMERS"] = function()
	if moveMode then
		K.SetArenaTimersMoving(false);
		return;
	end
	if testTimer:IsShown() then
		K.StopArenaTimerTests();
		return;
	end
	RunAll(K.ArenaTimerTestStart);
	testLeft = TEST_SECONDS;
	testTimer:Show();
	print("|cff4FC3F7NUF:|r " .. (L["TIMERS_TEST_HINT"] or "Arena timers test mode toggled. Alt + drag to move them."));
end
