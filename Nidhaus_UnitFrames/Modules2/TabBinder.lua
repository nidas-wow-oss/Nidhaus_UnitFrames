local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local binder = CreateFrame("Frame");
local pendiente = false;
local listo = false;

local PARES = {
	TARGETNEARESTENEMY  = "TARGETNEARESTENEMYPLAYER",
	TARGETPREVIOUSENEMY = "TARGETPREVIOUSENEMYPLAYER",
};

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

	return (K.InDuel and K.InDuel()) and true or false;
end

local function Cambiar()
	Limpiar();
	local r = Registro() or {};
	r.set = r.set or GetCurrentBindingSet();
	r.keys = r.keys or {};
	for normal, jugador in pairs(PARES) do
		local teclas = { GetBindingKey(normal) };
		for _, key in ipairs(teclas) do
			if not r.keys[key] then

				r.keys[key] = normal;
				anotado = r;
				if type(NidhausUnitFramesDB) == "table" then NidhausUnitFramesDB.TabBinderSwap = r; end
				if not SetBinding(key, jugador) then r.keys[key] = nil; end
			end
		end
	end
	if not next(r.keys) then Borrar(); end
end

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

		if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
			Aplicar();
			if not HayCambios() then self:UnregisterAllEvents(); end
		end
		return;
	end

	if event == "CHAT_MSG_SYSTEM" then

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

function K.ApplyTabBinder()
	binder:UnregisterAllEvents();
	if C.TabBinderEnabled then
		for _, e in ipairs(EVENTOS) do binder:RegisterEvent(e); end
		Aplicar();
	elseif HayCambios() then

		binder:RegisterEvent("PLAYER_ENTERING_WORLD");
		binder:RegisterEvent("PLAYER_REGEN_ENABLED");
		Aplicar();
		if not HayCambios() then binder:UnregisterAllEvents(); end
	end

end

local gate = CreateFrame("Frame");
gate:RegisterEvent("PLAYER_ENTERING_WORLD");
gate:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents();
	listo = true;
	K.ApplyTabBinder();
end);

K.RegisterConfigEvent("CONFIG_LOADED", function() K.ApplyTabBinder(); end);
