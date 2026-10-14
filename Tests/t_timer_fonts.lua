-- =========================================================
-- Timers de arena: la letra del ojo en todos y el numero del Circulo sobre el reloj
--
-- Se corre desde la raiz del repo:   Tests/run.sh
-- o a mano:                          lua5.1 Tests/t_timer_fonts.lua .
-- =========================================================
local ROOT = (arg[1] or "."):gsub("/+$", "")
-- Los modulos de arena viven en el addon a pedido.
local DIR = ROOT .. "/Nidhaus_UnitFrames_Arena/Modules2"
local created = {}
local mt = {}
mt.__index = function(t, k) if type(k) == "string" and k:match("^%u") then return function() return nil end end end
local function Obj(kind, name, parent, font)
	local o = setmetatable({ _kind = kind, _name = name, _parent = parent, _font = font, _shown = true, _scripts = {}, _ev = {}, _level = (parent and (parent._level or 0) + 1) or 1 }, mt)
	function o:GetName() return self._name end
	function o:Show() self._shown = true end
	function o:Hide() self._shown = false end
	function o:IsShown() return self._shown end
	function o:SetScript(k, f) self._scripts[k] = f end
	function o:GetScript(k) return self._scripts[k] end
	function o:RegisterEvent(e) self._ev[e] = true end
	function o:UnregisterEvent() end
	function o:UnregisterAllEvents() end
	function o:GetFrameLevel() return self._level end
	function o:SetFrameLevel(v) self._level = v end
	function o:SetTextHeight(h) self._th = h end
	function o:SetText(t) self._text = t end
	function o:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
	function o:CreateFontString(n, layer, f) local fs = Obj("FontString", n, self, f); fs._layer = layer; created[#created + 1] = fs; return fs end
	function o:CreateTexture(n, layer) local tx = Obj("Texture", n, self); tx._layer = layer; return tx end
	if name then _G[name] = o end
	created[#created + 1] = o
	return o
end
UIParent = Obj("Frame", "UIParent")
function CreateFrame(kind, name, parent) return Obj(kind, name, parent or UIParent) end
function IsAltKeyDown() return false end
function InCombatLockdown() return false end
function GetTime() return 0 end
function IsInInstance() return false, "none" end
function GetSpellInfo(id) return "S", nil, "I" end
function UnitClass() return "P", "PALADIN" end
function hooksecurefunc() end
function GetCVar() return "0" end
SlashCmdList = {}; NidhausUnitFramesDB = {}
local K = setmetatable({}, { __index = function() return nil end })
local C, L = {}, setmetatable({}, { __index = function() return nil end })
K.RegisterConfigEvent = function() end; K.RegisterScalable = function() end
K.RegisterModuleZones = function() end; K.AfterCombat = function() return false end
K.SaveConfig = function() return true end
NidhausUnitFramesNS = { K, C, L }
for _, f in ipairs({ "ArenaCountDown.lua", "ArenaDalaranPipeTimer.lua", "ArenaRoVPillarTimer.lua", "ArenaEndTimer.lua" }) do
	local ok, e = pcall(assert(loadfile(DIR .. "/" .. f)), "Nidhaus_UnitFrames", { K, C, L })
	if not ok then print("RUN FAIL " .. f .. ": " .. tostring(e)) end
end
local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. m) end end
local eye, pipe, rov = _G.NUF_ArenaCountDown, _G.NUF_DalaranPipeTimer, _G.NUF_RoVPillarTimer
-- el del ojo puede llamarse distinto: se busca el que tenga icono y texto
if not eye then for _, f in ipairs(created) do if f._name and f._name:find("ountDown") then eye = f end end end
check(pipe and pipe.text and pipe.label, "Waterfall tiene cartel y numero")
check(rov and rov.text, "Circulo del Valor tiene numero")
-- la del ojo: el unico FontString con PVPInfoTextFont antes de este cambio
local EYE_FONT = "PVPInfoTextFont"
local eyeN = 0
for _, f in ipairs(created) do if f._kind == "FontString" and f._font == EYE_FONT then eyeN = eyeN + 1 end end
check(eyeN >= 1, "el timer del ojo usa PVPInfoTextFont")
if pipe then
	check(pipe.label._font == EYE_FONT, "WATERFALL usa la letra del ojo (" .. tostring(pipe.label._font) .. ")")
	check(pipe.text._font == EYE_FONT, "el numero del Waterfall tambien (" .. tostring(pipe.text._font) .. ")")
	check(pipe.label._th == 12 and pipe.text._th == 24, "y conservan su tamano")
end
if rov then
	check(rov.text._font == EYE_FONT, "el numero del Circulo usa la letra del ojo (" .. tostring(rov.text._font) .. ")")
	check(rov.text._th == 18, "y su tamano")
	local lvlText = rov.text._parent and rov.text._parent._level or -1
	local lvlCD = rov.cooldown and rov.cooldown._level or -1
	check(lvlText > lvlCD, ("el numero va por encima del reloj (texto %d > reloj %d)"):format(lvlText, lvlCD))
end
print(("PASS %d  FAIL %d"):format(pass, fail))

