local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- TabBinder.lua
--
-- Portado de el UI de origen (RE/TabBinder), que a su vez
-- viene de RE/TabBinder, de Veev y AcidWeb.
--
-- QUE HACE: en zonas de PvP — arena, campo de batalla, zona en disputa —
-- y mientras tenes un duelo pedido, la tecla de seleccionar objetivo pasa
-- de "el enemigo mas cercano" a "el JUGADOR enemigo mas cercano". Al
-- salir, vuelve sola.
--
-- POR QUE IMPORTA: con la asignacion normal, el Tab te agarra mascotas,
-- totems, guardianes y bichos del escenario. En arena eso es la
-- diferencia entre tabear al sanador o a un totem de piedra.
--
-- COMO LO HACE: reescribe la asignacion de teclas de verdad, con
-- SetBinding + SaveBindings. Por eso hay tanto cuidado alrededor:
--
--   * SetBinding NO se puede llamar en combate. Si falla, se marca el
--     intento y se reintenta al salir de combate (PLAYER_REGEN_ENABLED).
--   * Se respeta la tecla que YA tengas asignada. Solo si no hay
--     ninguna se asume Tab y Shift+Tab.
--   * Se guarda en el set de asignaciones activo (cuenta o personaje),
--     el que tengas puesto.
--
-- DIFERENCIA CON EL ORIGINAL: alla el archivo se corta en la primera
-- linea si la opcion esta apagada, asi que prenderla exige recargar la
-- interfaz. Aca los eventos se registran y se sueltan al vuelo, de modo
-- que el checkbox hace efecto en el acto.
-- =========================================================

local binder = CreateFrame("Frame");
local pendiente = false;   -- quedo un cambio sin aplicar por estar en combate

local function EnZonaPvP()
	local _, tipoInstancia = IsInInstance();
	local tipoZona = GetZonePVPInfo();
	return tipoInstancia == "arena" or tipoInstancia == "pvp"
		or tipoZona == "combat";
end

-- Devuelve la tecla asignada a la accion "normal" o a la "solo jugadores",
-- porque segun como haya quedado la ultima vez puede estar en cualquiera
-- de las dos.
local function TeclaDe(accionNormal, accionJugador, porDefecto)
	return GetBindingKey(accionJugador) or GetBindingKey(accionNormal) or porDefecto;
end

local function Aplicar(forzarPvP)
	if InCombatLockdown() then
		pendiente = true;
		return;
	end

	local set = GetCurrentBindingSet();
	local teclaSig = TeclaDe("TARGETNEARESTENEMY", "TARGETNEARESTENEMYPLAYER", "TAB");
	local teclaAnt = TeclaDe("TARGETPREVIOUSENEMY", "TARGETPREVIOUSENEMYPLAYER", "SHIFT-TAB");

	local quiero = (forzarPvP or EnZonaPvP()) and "TARGETNEARESTENEMYPLAYER"
		or "TARGETNEARESTENEMY";
	local quieroAnt = (forzarPvP or EnZonaPvP()) and "TARGETPREVIOUSENEMYPLAYER"
		or "TARGETPREVIOUSENEMY";

	-- Si ya esta como corresponde, no se toca nada: reescribir las
	-- asignaciones en cada cambio de zona ensucia el archivo de teclas.
	if teclaSig and GetBindingAction(teclaSig) == quiero then
		pendiente = false;
		return;
	end

	local ok = true;
	if teclaSig then ok = SetBinding(teclaSig, quiero); end
	if teclaAnt then SetBinding(teclaAnt, quieroAnt); end

	if ok then
		SaveBindings(set);
		pendiente = false;
	else
		pendiente = true;
	end
end

binder:SetScript("OnEvent", function(self, event, ...)
	if not C.TabBinderEnabled then return; end

	if event == "CHAT_MSG_SYSTEM" then
		-- El aviso de duelo pedido llega como mensaje de sistema en
		-- 3.3.5; se traduce al mismo caso que DUEL_REQUESTED.
		local msg = ...;
		if msg == ERR_DUEL_REQUESTED then Aplicar(true); end
		return;
	end

	if event == "DUEL_REQUESTED" then
		Aplicar(true);
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pendiente then Aplicar(); end
	else
		Aplicar();
	end
end);

-- ---------------------------------------------------------
-- Encender / apagar en caliente
-- ---------------------------------------------------------
local EVENTOS = {
	"ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD",
	"PLAYER_REGEN_ENABLED", "DUEL_REQUESTED", "DUEL_FINISHED",
	"CHAT_MSG_SYSTEM",
};

function K.ApplyTabBinder()
	if C.TabBinderEnabled then
		for _, e in ipairs(EVENTOS) do binder:RegisterEvent(e); end
		Aplicar();
	else
		binder:UnregisterAllEvents();
		-- Al apagarlo se devuelve la tecla al objetivo normal, para no
		-- dejarte con la asignacion de PvP puesta sin saberlo.
		if not InCombatLockdown() then
			local set = GetCurrentBindingSet();
			local teclaSig = GetBindingKey("TARGETNEARESTENEMYPLAYER");
			local teclaAnt = GetBindingKey("TARGETPREVIOUSENEMYPLAYER");
			local cambio = false;
			if teclaSig then SetBinding(teclaSig, "TARGETNEARESTENEMY"); cambio = true; end
			if teclaAnt then SetBinding(teclaAnt, "TARGETPREVIOUSENEMY"); cambio = true; end
			if cambio then SaveBindings(set); end
		end
	end
end

K.RegisterConfigEvent("CONFIG_LOADED", function() K.ApplyTabBinder(); end);
