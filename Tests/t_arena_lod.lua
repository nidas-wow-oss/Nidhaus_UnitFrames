-- =========================================================
-- Los modulos de arena se cargan a pedido:
--   * no estan en el XML del addon principal
--   * el cargador los pide al entrar a una arena y con los comandos
--   * el que se anota tarde igual recibe CONFIG_LOADED
--   * un modulo registrado tarde arranca en el acto
--   * K.GetCCCategory sigue andando sin ellos (lo usa el marco de mascotas)
--
-- Se corre desde la raiz del repo:   Tests/run.sh
-- o a mano:                          lua5.1 Tests/t_arena_lod.lua .
-- =========================================================
local ROOT = (arg[1] or "."):gsub("/+$", "")
local MAIN = ROOT .. "/Nidhaus_UnitFrames/"
local ARENA = ROOT .. "/Nidhaus_UnitFrames_Arena/"

local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. m) end end
local function slurp(p) local f = io.open(p); if not f then return nil end local s = f:read("*a"); f:close(); return s end

local ARENA_FILES = {
	"Modules/ArenaFramePositionSaver.lua", "UnitFrames/Arenaflat.lua", "UnitFrames/ArenaFrame.lua",
	"Modules/ArenaFrame_Trinkets.lua", "Modules/MirrorMode.lua", "Modules/ArenaMover.lua",
	"Modules2/ArenaCountDown.lua", "Modules2/ArenaDR.lua", "Modules2/ArenaDoTMark.lua",
	"Modules2/ArenaTargetOfTarget.lua", "Modules2/ArenaDalaranPipeTimer.lua",
	"Modules2/ArenaRoVPillarTimer.lua", "Modules2/ArenaEndTimer.lua",
}

-- 1) reparto de archivos
local xml = slurp(MAIN .. "Nidhaus_UnitFrames.xml") or ""
local toc = slurp(ARENA .. "Nidhaus_UnitFrames_Arena.toc") or ""
check(toc ~= "", "existe el .toc del addon de arena")
check(toc:find("LoadOnDemand: 1", 1, true) ~= nil, "esta marcado LoadOnDemand")
check(toc:find("Dependencies: Nidhaus_UnitFrames", 1, true) ~= nil, "depende del addon principal")
local faltan, enXML = 0, 0
for _, f in ipairs(ARENA_FILES) do
	if not slurp(ARENA .. f) then faltan = faltan + 1; print("   falta " .. f) end
	if xml:find(f:gsub("/", "\\"), 1, true) then enXML = enXML + 1; print("   sigue en el XML: " .. f) end
	if not toc:find(f:gsub("/", "\\"), 1, true) then print("   no esta en el .toc: " .. f) end
end
check(faltan == 0, "los 13 archivos estan en el addon de arena")
check(enXML == 0, "y ninguno se carga desde el addon principal")
check(slurp(MAIN .. "Core/ArenaLoader.lua") ~= nil, "existe el cargador")
check(xml:find("Core\\ArenaLoader.lua", 1, true) ~= nil, "y el XML lo carga")
check(xml:find("Core\\CCCategories.lua", 1, true) ~= nil, "la tabla de CC quedo en el core")

-- 2) el cargador, con un WoW de mentira
local frames = {}
local mt = {}
mt.__index = function(t, k) if type(k) == "string" and k:match("^%u") then return function() return nil end end end
local function Obj(kind, name)
	local o = setmetatable({ _kind = kind, _scripts = {}, _ev = {} }, mt)
	function o:SetScript(k, f) self._scripts[k] = f end
	function o:RegisterEvent(e) self._ev[e] = true end
	function o:UnregisterEvent(e) self._ev[e] = nil end
	if name then _G[name] = o end
	frames[#frames + 1] = o
	return o
end
function CreateFrame(kind, name) return Obj(kind, name) end
local loadedAddons, loadCalls = {}, 0
function IsAddOnLoaded(n) return loadedAddons[n] and true or false end
function LoadAddOn(n) loadCalls = loadCalls + 1; loadedAddons[n] = true; return true end
local itype = "none"
function IsInInstance() return itype ~= "none", itype end
SlashCmdList = {}
local K = setmetatable({}, { __index = function(t, k) if type(k) == "string" and k:match("^_") then return nil end return nil end })
local C, L = {}, setmetatable({}, { __index = function() return nil end })
assert(loadfile(MAIN .. "Core/ArenaLoader.lua"))("Nidhaus_UnitFrames", { K, C, L })

check(type(K.LoadArenaModules) == "function", "K.LoadArenaModules existe")
check(loadCalls == 0, "al cargar el addon NO se piden los modulos de arena")
-- entrar al mundo normal: nada
local w
for _, f in ipairs(frames) do if f._ev.PLAYER_ENTERING_WORLD then w = f end end
check(w ~= nil, "el cargador escucha PLAYER_ENTERING_WORLD")
w._scripts.OnEvent(w, "PLAYER_ENTERING_WORLD")
check(loadCalls == 0, "entrar a una ciudad no los carga")
-- entrar a una arena: si
itype = "arena"
w._scripts.OnEvent(w, "PLAYER_ENTERING_WORLD")
check(loadCalls == 1, "entrar a una arena los carga (" .. loadCalls .. ")")
check(K.AreArenaModulesLoaded(), "y quedan cargados")
w._scripts.OnEvent(w, "PLAYER_ENTERING_WORLD")
check(loadCalls == 1, "la segunda vez no se vuelve a pedir")
-- Blizzard_ArenaUI
loadedAddons, loadCalls = {}, 0
w._scripts.OnEvent(w, "ADDON_LOADED", "OtraCosa")
check(loadCalls == 0, "otro addon cualquiera no los carga")
w._scripts.OnEvent(w, "ADDON_LOADED", "Blizzard_ArenaUI")
check(loadCalls == 1, "Blizzard_ArenaUI si (es el modo de prueba)")
-- los comandos
loadedAddons, loadCalls = {}, 0
local llamado = false
check(SLASH_NUFDR1 == "/nufdr" and SLASH_NUFDOT1 == "/nufdot" and SLASH_NUFARENATIMERS1 == "/nuftimers",
	"los tres comandos quedan registrados sin cargar nada")
local stub = SlashCmdList["NUFDR"]
LoadAddOn = function(n) loadCalls = loadCalls + 1; loadedAddons[n] = true
	SlashCmdList["NUFDR"] = function(msg) llamado = msg or true end   -- lo que haria el archivo de verdad
	return true end
SlashCmdList["NUFDR"]("hola")
check(loadCalls == 1 and llamado == "hola", "/nufdr carga el addon y le pasa la pelota al de verdad")

-- 3) CONFIG_LOADED para el que llega tarde
for k in pairs(_G) do if k:match("^SLASH_NUF") then _G[k] = nil end end
local K2 = setmetatable({}, { __index = function(t, k) if type(k) == "string" and k:match("^_") then return nil end return nil end })
local C2 = {}
local L2 = setmetatable({}, { __index = function() return nil end })
NidhausUnitFramesDB = {}
_G.GetLocale = function() return "enUS" end
_G.UnitClass = function() return "P", "PALADIN" end
_G.print = print
local okc = pcall(function()
	assert(loadfile(MAIN .. "Config/ConfigManager.lua"))("Nidhaus_UnitFrames", { K2, C2, L2 })
end)
check(okc, "ConfigManager carga")
if okc then
	-- el ADDON_LOADED del propio addon es lo que dispara CONFIG_LOADED
	local cm
	for _, f in ipairs(frames) do if f._ev.ADDON_LOADED and f._scripts.OnEvent then cm = f end end
	local tardeCorrio = false
	-- antes de CONFIG_LOADED: se anota y NO corre
	K2.RegisterConfigEvent("CONFIG_LOADED", function() tardeCorrio = "temprano" end)
	check(tardeCorrio == false, "antes de cargar la config no se llama a nadie")
	if cm then pcall(cm._scripts.OnEvent, cm, "ADDON_LOADED", "Nidhaus_UnitFrames") end
	-- ahora, uno que llega tarde
	local tarde = false
	K2.RegisterConfigEvent("CONFIG_LOADED", function() tarde = true end)
	check(tarde == true, "el que se anota DESPUES recibe CONFIG_LOADED igual")
end

-- 4) un modulo que se registra tarde (los de arena) arranca en el acto
do
	local frames2 = {}
	local mt2 = {}; mt2.__index = function(t, k) if type(k) == "string" and k:match("^%u") then return function() end end end
	local oldCreate = CreateFrame
	CreateFrame = function(kind, name)
		local o = setmetatable({ _scripts = {}, _ev = {} }, mt2)
		function o:SetScript(k, f) self._scripts[k] = f end
		function o:RegisterEvent(e) self._ev[e] = true end
		function o:UnregisterEvent(e) self._ev[e] = nil end
		frames2[#frames2 + 1] = o; if name then _G[name] = o end; return o
	end
	NidhausUnitFramesDB = { Modules = { Tarde = true, Apagado = false } }
	local K3 = setmetatable({}, { __index = function(t, k) if type(k) == "string" and k:match("^_") then return nil end return nil end })
	local C3, L3 = {}, setmetatable({}, { __index = function() return nil end })
	assert(loadfile(MAIN .. "Core/ModuleManager.lua"))("Nidhaus_UnitFrames", { K3, C3, L3 })
	local onA = 0
	K3.RegisterModule("Temprano", { name = "t", onEnable = function() onA = onA + 1 end, default = true })
	NidhausUnitFramesDB.Modules.Temprano = true
	check(onA == 0, "antes de PLAYER_LOGIN no se prende nada")
	local init
	for _, f in ipairs(frames2) do if f._ev.PLAYER_LOGIN then init = f end end
	init._scripts.OnEvent(init, "PLAYER_LOGIN")
	check(onA == 1, "en PLAYER_LOGIN se prende lo tildado (" .. onA .. ")")
	local onB, onC = 0, 0
	K3.RegisterModule("Tarde", { name = "t", onEnable = function() onB = onB + 1 end, default = false })
	check(onB == 1, "un modulo tildado registrado TARDE arranca en el acto (" .. onB .. ")")
	K3.RegisterModule("Apagado", { name = "t", onEnable = function() onC = onC + 1 end, default = true })
	check(onC == 0, "y uno destildado no")
	CreateFrame = oldCreate
end


-- 5) las texturas y los sonidos siguen saliendo de la carpeta principal
do
	local malas = 0
	for _, f in ipairs(ARENA_FILES) do
		local src = slurp(ARENA .. f) or ""
		for linea in src:gmatch("[^\n]+") do
			if linea:find("AddOns?\\\\\"%s*%.%.%s*AddOnName") or linea:find('AddOns\\\\"%.%.AddOnName') then
				malas = malas + 1; print("   ruta al addon de arena: " .. f)
			end
		end
	end
	check(malas == 0, "ninguna ruta de media apunta al addon de arena")
end

print(("PASS %d  FAIL %d"):format(pass, fail))
