-- =========================================================
-- Turn Evil: el borde verde gira igual en vivo que en el modo mover
--
-- Se corre desde la raiz del repo:   Tests/run.sh
-- o a mano:                          lua5.1 Tests/t_turnevil_glow.lua .
-- =========================================================
local ROOT = (arg[1] or "."):gsub("/+$", "")
local FILE = ROOT .. "/Nidhaus_UnitFrames/Modules2/PaladinAuras.lua"
local mt = {}
mt.__index = function(t, k) if type(k) == "string" and k:match("^%u") then return function() return nil end end end
local all = {}
local function Obj(kind, name, parent)
	local o = setmetatable({ _kind = kind, _name = name, _parent = parent, _shown = true, _scripts = {}, _ev = {}, _w = 36, _h = 36 }, mt)
	function o:GetName() return self._name end
	function o:Show() self._shown = true end
	function o:Hide() self._shown = false end
	function o:IsShown() return self._shown end
	function o:IsVisible() return self._shown end
	function o:SetScript(k, f) self._scripts[k] = f end
	function o:GetScript(k) return self._scripts[k] end
	function o:HookScript(k, f) local p = self._scripts[k]; self._scripts[k] = function(...) if p then p(...) end f(...) end end
	function o:RegisterEvent(e) self._ev[e] = true end
	function o:UnregisterEvent(e) self._ev[e] = nil end
	function o:UnregisterAllEvents() self._ev = {} end
	function o:GetWidth() return self._w end
	function o:GetHeight() return self._h end
	function o:GetFrameLevel() return 1 end
	function o:SetTexCoord(a, b, c, d) self._tc = { a, b, c, d } end
	function o:GetTexture() return self._tex end
	function o:SetTexture(t) self._tex = t end
	function o:SetText(t) self._text = t end
	function o:SetAlpha(a) self._alpha = a end
	function o:GetAlpha() return self._alpha or 1 end
	function o:CreateTexture(n) return Obj("Texture", n, self) end
	function o:CreateFontString(n) return Obj("FontString", n, self) end
	function o:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
	if name then _G[name] = o end
	all[#all + 1] = o
	return o
end
UIParent = Obj("Frame", "UIParent")
function CreateFrame(kind, name, parent) return Obj(kind, name, parent) end
function UnitClass() return "Paladin", "PALADIN" end
function InCombatLockdown() return false end
local now = 1000
function GetTime() return now end
function UnitExists(u) return u == "arenapet1" end
function UnitGUID(u) return "GUID-" .. tostring(u) end
function UnitName(u) return "Felhunter" end
local TURN_EVIL = "Turn Evil"
function UnitAura(u, i) if i == 1 then return TURN_EVIL, nil, "IconTE", nil, nil, 20, now + 15 end end
function GetSpellInfo(id) return TURN_EVIL, nil, "IconTE" end
function hooksecurefunc() end
function GetCVar() return "0" end
function IsInInstance() return true, "arena" end
SlashCmdList = {}; NidhausUnitFramesDB = {}
local K = setmetatable({}, { __index = function(t, k) if type(k) == "string" and k:match("^_") then return nil end return nil end })
local C = {}
local L = setmetatable({}, { __index = function() return nil end })
K.RegisterConfigEvent = function() end
K.RegisterScalable = function() end
K.RegisterModuleZones = function() end
K.GetModuleScale = function() return 1.2 end
K.ModuleZoneAllowed = function() return true end
K.AfterCombat = function() return false end
K.SaveConfig = function(k, v) C[k] = v; return true end
local mods = {}
K.RegisterModule = function(id, d) mods[id] = d end
assert(loadfile(FILE))("Nidhaus_UnitFrames", { K, C, L })
local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. m) end end
check(mods.TurnEvil ~= nil, "modulo TurnEvil registrado")
mods.TurnEvil.onEnable()
-- el ticker (lo que corre en vivo): el frame con OnUpdate que no es un glow
local ticker
for _, f in ipairs(all) do if f._scripts.OnUpdate and not f.ants then ticker = ticker or f end end
-- buscar el glow del primer icono
local glow
for _, f in ipairs(all) do if f.ants and f._shown then glow = glow or f end end
check(glow ~= nil, "el borde verde aparece en vivo")
if glow then
	-- correr 2 segundos de juego: el ticker refresca cada 0.1s
	local frames = 0
	for i = 1, 120 do           -- 120 cuadros de ~1/60 s
		now = now + 1 / 60
		if ticker and ticker._scripts.OnUpdate then ticker._scripts.OnUpdate(ticker, 1 / 60) end
		if glow._scripts.OnUpdate then glow._scripts.OnUpdate(glow, 1 / 60) end
	end
	-- en 2 s, a 0.05 s por cuadro, tendria que haber dado ~40 pasos = 1.8 vueltas
	check(glow.antI ~= nil, "las hormigas tienen cuadro")
	check(glow.t > 1.5, ("el latido avanza (t = %.2f, deberia ser ~2)"):format(glow.t or -1))
	-- el cuadro de las hormigas no puede estar clavado en los primeros
	local seen = {}
	for i = 1, 60 do
		now = now + 1 / 60
		if ticker and ticker._scripts.OnUpdate then ticker._scripts.OnUpdate(ticker, 1 / 60) end
		glow._scripts.OnUpdate(glow, 1 / 60)
		seen[glow.antI] = true
	end
	local n = 0; for _ in pairs(seen) do n = n + 1 end
	check(n >= 8, ("recorre toda la vuelta: %d cuadros distintos en 1 s (sin el arreglo son 2 o 3)"):format(n))
end
print(("PASS %d  FAIL %d"):format(pass, fail))

