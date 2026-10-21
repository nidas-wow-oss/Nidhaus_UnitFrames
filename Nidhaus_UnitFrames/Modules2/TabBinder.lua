local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- TabBinder.lua
--
-- La idea original es de RE/TabBinder, de Veev y AcidWeb.
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
-- COMO LO HACE: cambia la asignacion de teclas con SetBinding. Por eso hay
-- tanto cuidado alrededor:
--
--   * SetBinding NO se puede llamar en combate. Si falla, se marca el
--     intento y se reintenta al salir de combate (PLAYER_REGEN_ENABLED).
--   * Solo se tocan las teclas que YA hacen "objetivo enemigo", y cada una
--     se anota con su accion original para devolverla tal cual. Nunca se
--     inventa una tecla ni se pisa otra asignacion tuya.
--   * Al entrar en PvP NO se guarda en disco: lo guardado sigue siendo lo
--     tuyo, y un cuelgue en el medio no deja nada cambiado.
--
-- DIFERENCIA CON EL ORIGINAL: alla el archivo se corta en la primera
-- linea si la opcion esta apagada, asi que prenderla exige recargar la
-- interfaz. Aca los eventos se registran y se sueltan al vuelo, de modo
-- que el checkbox hace efecto en el acto.
-- =========================================================

local binder = CreateFrame("Frame");
local pendiente = false;   -- quedo un cambio sin aplicar por estar en combate
local listo = false;       -- asignaciones cargadas (desde PLAYER_ENTERING_WORLD)

-- Accion normal -> accion "solo jugadores".
local PARES = {
	TARGETNEARESTENEMY  = "TARGETNEARESTENEMYPLAYER",
	TARGETPREVIOUSENEMY = "TARGETPREVIOUSENEMYPLAYER",
};

-- LO QUE CAMBIAMOS, TECLA POR TECLA: { set = n, keys = { [tecla] = accion original } }.
-- Vive en la SavedVariable para sobrevivir a un /reload o un cuelgue; la
-- copia local cubre el "Reset Defaults", que vacia la DB entera.
local anotado;

local function Registro()
	local db = NidhausUnitFramesDB;
	if type(db) == "table" then
		if type(db.TabBinderSwap) == "table" then
			anotado = db.TabBinderSwap;
		elseif anotado then
			db.TabBinderSwap = anotado;
		end
	end
	return anotado;
end

local function Borrar()
	anotado = nil;
	if type(NidhausUnitFramesDB) == "table" then NidhausUnitFramesDB.TabBinderSwap = nil; end
end

local function HayCambios()
	local r = Registro();
	return (r and type(r.keys) == "table" and next(r.keys) ~= nil) and true or false;
end

-- Tras un /reload sin guardar las teclas ya volvieron solas a su accion:
-- se olvida lo anotado que no coincide con lo que hay de verdad.
local function Limpiar()
	local r = Registro();
	if not r then return; end
	if type(r.keys) ~= "table" then Borrar(); return; end
	for key, original in pairs(r.keys) do
		if not PARES[original] or GetBindingAction(key) ~= PARES[original] then
			r.keys[key] = nil;
		end
	end
	if not next(r.keys) then Borrar(); end
end

local function EnZonaPvP()
	local _, tipoInstancia = IsInInstance();
	local tipoZona = GetZonePVPInfo();
	if tipoInstancia == "arena" or tipoInstancia == "pvp" or tipoZona == "combat" then
		return true;
	end
	-- Duelo en curso (lo sigue ModuleManager, incluso el que pediste vos).
	return (K.InDuel and K.InDuel()) and true or false;
end

-- Entrar en PvP: solo las teclas que hoy hacen "objetivo enemigo" pasan a
-- "jugador enemigo". Sin SaveBindings: el disco queda con lo tuyo.
local function Cambiar()
	Limpiar();
	local r = Registro() or {};
	r.set = r.set or GetCurrentBindingSet();
	r.keys = r.keys or {};
	for normal, jugador in pairs(PARES) do
		local teclas = { GetBindingKey(normal) };
		for _, key in ipairs(teclas) do
			if not r.keys[key] then
				-- Se anota ANTES de tocarla: si algo corta a la mitad, queda registro.
				r.keys[key] = normal;
				anotado = r;
				if type(NidhausUnitFramesDB) == "table" then NidhausUnitFramesDB.TabBinderSwap = r; end
				if not SetBinding(key, jugador) then r.keys[key] = nil; end
			end
		end
	end
	if not next(r.keys) then Borrar(); end
end

-- Salir de PvP / apagar: cada tecla anotada vuelve a SU accion, y solo si
-- sigue como la dejamos (si la reasignaste vos en el medio, se respeta).
local function Devolver()
	local r = Registro();
	if not r then return; end
	local cambio = false;
	if type(r.keys) == "table" then
		for key, original in pairs(r.keys) do
			if PARES[original] and GetBindingAction(key) == PARES[original] then
				if SetBinding(key, original) then cambio = true; end
			end
		end
	end
	-- Se guarda solo si hubo que devolver algo: cubre el caso en que otro
	-- (el panel de teclas, una opcion de Blizzard) guardo con el cambio puesto.
	if cambio then SaveBindings(r.set or GetCurrentBindingSet()); end
	Borrar();
end

local function Aplicar(forzarPvP)
	if not listo then return; end
	if InCombatLockdown() then
		pendiente = true;
		return;
	end
	pendiente = false;
	if C.TabBinderEnabled and (forzarPvP or EnZonaPvP()) then
		Cambiar();
	else
		Devolver();
	end
end

local EVENTOS = {
	"ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD",
	"PLAYER_REGEN_ENABLED", "DUEL_REQUESTED", "DUEL_FINISHED",
	"CHAT_MSG_SYSTEM",
};

binder:SetScript("OnEvent", function(self, event, ...)
	if not C.TabBinderEnabled then
		-- Apagado: solo queda devolver lo que hubiera quedado cambiado.
		if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
			Aplicar();
			if not HayCambios() then self:UnregisterAllEvents(); end
		end
		return;
	end

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
function K.ApplyTabBinder()
	binder:UnregisterAllEvents();
	if C.TabBinderEnabled then
		for _, e in ipairs(EVENTOS) do binder:RegisterEvent(e); end
		Aplicar();
	elseif HayCambios() then
		-- Apagado con teclas cambiadas por nosotros: se devuelven ya, o en
		-- cuanto se pueda (fuera de combate, asignaciones cargadas).
		binder:RegisterEvent("PLAYER_ENTERING_WORLD");
		binder:RegisterEvent("PLAYER_REGEN_ENABLED");
		Aplicar();
		if not HayCambios() then binder:UnregisterAllEvents(); end
	end
	-- Apagado y sin nada anotado: no se toca ninguna tecla.
end

-- Antes de entrar al mundo las asignaciones no son confiables: hasta
-- entonces no se lee ni se escribe ninguna.
local gate = CreateFrame("Frame");
gate:RegisterEvent("PLAYER_ENTERING_WORLD");
gate:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents();
	listo = true;
	K.ApplyTabBinder();
end);

K.RegisterConfigEvent("CONFIG_LOADED", function() K.ApplyTabBinder(); end);
