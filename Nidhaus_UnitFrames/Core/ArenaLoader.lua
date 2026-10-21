local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- LOS MODULOS DE ARENA SE CARGAN CUANDO HACEN FALTA
--
-- Los marcos de arena, el mover, el espejo, los trinkets, el DR, los
-- DoTs, el objetivo-del-objetivo y los cuatro timers son 400 KB de Lua
-- compilado -- el 16% del addon -- que el cliente leia en CADA login,
-- juegues arena ese dia o no.
--
-- Ahora viven en Nidhaus_UnitFrames_Arena, un addon aparte marcado como
-- LoadOnDemand, igual que el panel de opciones. Este archivo es lo unico
-- que queda en el addon principal: unas pocas lineas que lo piden cuando
-- de verdad se necesita.
--
-- CUANDO SE CARGA
--   * al entrar a una arena (PLAYER_ENTERING_WORLD con tipo "arena");
--   * cuando el cliente carga Blizzard_ArenaUI (el modo de prueba de
--     arena pasa por ahi);
--   * al abrir el panel de opciones (tiene una pestaña entera de arena);
--   * al abrir "Mover todo" (para poder acomodar los timers);
--   * con /nufdr, /nufdot o /nuftimers.
--
-- QUE HACE FALTA PARA QUE ESTO FUNCIONE
--   * K.RegisterConfigEvent repite CONFIG_LOADED al que se anota tarde
--     (ConfigManager.lua);
--   * K.RegisterModule prende el modulo en el acto si los modulos ya se
--     inicializaron (ModuleManager.lua);
--   * la tabla de categorias de CC quedo en el core (CCCategories.lua),
--     porque la usa el marco de mascotas, que no es de arena.
-- =========================================================

local ARENA = "Nidhaus_UnitFrames_Arena";
local tried = false;

function K.AreArenaModulesLoaded()
	if IsAddOnLoaded then return IsAddOnLoaded(ARENA) and true or false; end
	return false;
end

-- Devuelve true si quedaron cargados. Avisa UNA sola vez si no se pudo.
function K.LoadArenaModules()
	if K.AreArenaModulesLoaded() then return true; end
	if not LoadAddOn then return false; end
	local loaded, reason = LoadAddOn(ARENA);
	if loaded then return true; end
	if not tried then
		tried = true;
		local why = reason and (_G["ADDON_" .. reason] or reason) or "?";
		print("|cffFF5555NUF:|r " .. (L["ARENA_LOAD_FAIL"]
			or "Couldn't load the arena modules") .. " (" .. tostring(why) .. ").");
		print("|cffFF5555NUF:|r " .. (L["ARENA_LOAD_HINT"]
			or "Check that the Nidhaus_UnitFrames_Arena folder sits next to the addon's folder and is enabled in the AddOns list."));
	end
	return false;
end

-- ---------------------------------------------------------
-- Disparadores
-- ---------------------------------------------------------
local watch = CreateFrame("Frame");
watch:RegisterEvent("PLAYER_ENTERING_WORLD");
watch:RegisterEvent("ADDON_LOADED");
watch:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		-- El modo de prueba de arena carga Blizzard_ArenaUI: si aparece,
		-- es que alguien quiere ver los marcos de arena.
		if arg1 == "Blizzard_ArenaUI" then K.LoadArenaModules(); end
		return;
	end
	-- PLAYER_ENTERING_WORLD: adentro de una arena, y nada mas.
	local _, itype = IsInInstance();
	if itype == "arena" then K.LoadArenaModules(); end
end);

-- ---------------------------------------------------------
-- SUPLENTES DE LOS COMANDOS
--
-- /nufdr, /nufdot y /nuftimers viven en el addon de arena. Mientras no
-- este cargado atienden estos: lo cargan y le pasan la pelota al de
-- verdad, que para entonces ya los reemplazo. La comparacion con 'stub'
-- es la que corta la recursion si la carga fallara.
-- ---------------------------------------------------------
local function Shim(key, ...)
	local names = { ... };
	for i, cmd in ipairs(names) do
		_G["SLASH_" .. key .. i] = cmd;
	end
	local stub;
	stub = function(msg)
		if not K.LoadArenaModules() then return; end
		local real = SlashCmdList[key];
		if real and real ~= stub then real(msg); end
	end
	SlashCmdList[key] = stub;
end

Shim("NUFDR", "/nufdr");
Shim("NUFDOT", "/nufdot");
Shim("NUFARENATIMERS", "/nuftimers");
