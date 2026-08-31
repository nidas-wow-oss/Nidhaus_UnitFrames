local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ScaleAPI.lua
-- Registro CENTRAL de escalas por modulo.
--
-- POR QUE: cada modulo guardaba (o no) su escala a su manera, con su
-- propia funcion Get/Save. Resultado: la mitad no tenia escala y el panel
-- necesitaba codigo distinto para cada uno.
--
-- Aca cada modulo solo dice "este frame es escalable":
--
--     K.RegisterScalable("DTSU", anchor, 1.0)
--
-- y con eso queda todo: la escala se guarda en la DB de NUF, se aplica al
-- cargar, y el panel puede dibujar un slider generico con
-- K.GetModuleScale(id) / K.SetModuleScale(id, v).
-- =========================================================

local registry = {};   -- id -> { frame = f, default = n }

local function ScaleDB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.ModuleScales then
		NidhausUnitFramesDB.ModuleScales = {};
	end
	return NidhausUnitFramesDB.ModuleScales;
end

-- Convierte el segundo argumento en lista de frames.
-- Acepta un frame suelto o una lista: hay modulos con mas de un marco
-- para lo mismo (la gargola tiene GT_Blizzard y GT_Custom, uno por modo)
-- y el slider tiene que escalar los dos, no solo el primero.
-- Un Frame de WoW tambien es una table, asi que se distingue por SetScale.
local function AsList(frame)
	if type(frame) ~= "table" then return nil; end
	if frame.SetScale then return { frame }; end
	local out = {};
	for _, f in ipairs(frame) do
		if type(f) == "table" and f.SetScale then out[#out + 1] = f; end
	end
	return (#out > 0) and out or nil;
end

-- Registra uno o varios frames como escalables y aplica la escala guardada.
function K.RegisterScalable(id, frame, default)
	if not id or not frame then return; end
	local list = AsList(frame);
	if not list then return; end
	registry[id] = { frames = list, frame = list[1], default = default or 1.0 };

	local saved = ScaleDB()[id];
	if type(saved) == "number" and saved > 0 then
		for _, f in ipairs(list) do pcall(f.SetScale, f, saved); end
	end
end

function K.IsScalable(id)
	return registry[id] ~= nil;
end

function K.GetModuleScale(id)
	local entry = registry[id];
	local saved = ScaleDB()[id];
	if type(saved) == "number" and saved > 0 then return saved; end
	return (entry and entry.default) or 1.0;
end

function K.SetModuleScale(id, value)
	local entry = registry[id];
	if not entry then return; end
	value = tonumber(value) or 1.0;
	if value < 0.3 then value = 0.3; end
	if value > 3.0 then value = 3.0; end
	ScaleDB()[id] = value;
	for _, f in ipairs(entry.frames or { entry.frame }) do
		pcall(f.SetScale, f, value);
	end
end

function K.ResetModuleScale(id)
	local entry = registry[id];
	if not entry then return; end
	ScaleDB()[id] = nil;
	for _, f in ipairs(entry.frames or { entry.frame }) do
		pcall(f.SetScale, f, entry.default or 1.0);
	end
end

-- Reaplica todas las escalas guardadas (por si un modulo recrea su frame)
function K.ReapplyModuleScales()
	for id, entry in pairs(registry) do
		local v = K.GetModuleScale(id);
		for _, f in ipairs(entry.frames or { entry.frame }) do
			pcall(f.SetScale, f, v);
		end
	end
end
