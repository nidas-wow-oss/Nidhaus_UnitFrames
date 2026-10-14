-- =========================================================
-- Barras de casteo del grupo: el estilo guardado se aplica al entrar
--
-- Se corre desde la raiz del repo:   Tests/run.sh
-- o a mano:                          lua5.1 Tests/t_partycast_style.lua .
-- =========================================================
local ROOT = (arg[1] or "."):gsub("/+$", "")
local FILE = ROOT .. "/Nidhaus_UnitFrames/Modules2/PartyCastingBars/PartyCastingBars.lua"
local mt = {}
mt.__index = function(t, k) if type(k) == "string" and k:match("^%u") then return function() end end end
local function Obj(kind, name, parent)
	local o = setmetatable({ _kind = kind, _name = name, _shown = true, _scripts = {}, _ev = {}, _w = 10, _h = 10, _parent = parent }, mt)
	function o:Show() self._shown = true end
	function o:Hide() self._shown = false end
	function o:IsShown() return self._shown end
	function o:IsVisible() return self._shown end
	function o:SetScript(k, f) self._scripts[k] = f end
	function o:RegisterEvent(e) self._ev[e] = true end
	function o:UnregisterEvent(e) self._ev[e] = nil end
	function o:GetName() return self._name end
	function o:GetParent() return self._parent end
	function o:SetWidth(w) self._w = w end
	function o:SetHeight(h) self._h = h end
	function o:GetWidth() return self._w end
	function o:GetHeight() return self._h end
	function o:SetTexture(t) self._tex = t end
	function o:GetTexture() return self._tex end
	function o:GetNumPoints() return 1 end
	function o:GetPoint() return "TOP", nil, "TOP", 0, 28 end
	function o:SetFontObject(f) self._font = f end
	function o:GetFontObject() return self._font end
	function o:GetAttribute() return nil end
	function o:SetScale(s) self._scale = s end
	if name then _G[name] = o end
	return o
end
local frames = {}
function CreateFrame(kind, name, parent) local o = Obj(kind, name, parent); frames[#frames + 1] = o; return o end
UIParent = Obj("Frame", "UIParent")
function IsLoggedIn() return LOGGED end
function UnitExists() return false end
local cfgEv = {}
local K, C, L = {}, { PCB_Enabled = true, ArenaCastBarWidth = 80 }, {}
K.RegisterConfigEvent = function(e, f) cfgEv[e] = cfgEv[e] or {}; table.insert(cfgEv[e], f) end
SlashCmdList = {}
tinsert = table.insert; strfind = string.find; format = string.format
function GetTime() return 0 end
function UnitInRaid() return nil end
function UnitCanAttack() return false end
assert(loadfile(FILE))("Nidhaus_UnitFrames", { K, C, L })
-- Las cuatro barras (lo que hace el XML): Border 256x64 del template, Text 185 GameFontHighlight
for i = 1, 4 do
	local pf = Obj("Frame", "PartyMemberFrame" .. i); pf.unit = "party" .. i
	local n = "PartyMemberFrame" .. i .. "CastingBarFrame"
	local bar = Obj("StatusBar", n, pf); bar._w, bar._h = 195, 13
	local b = Obj("Texture", n .. "Border"); b._tex = "Interface\\CastingBar\\UI-CastingBar-Border"; b._w, b._h = 256, 64
	local f = Obj("Texture", n .. "Flash"); f._tex = "Interface\\CastingBar\\UI-CastingBar-Flash"; f._w, f._h = 256, 64
	local t = Obj("FontString", n .. "Text"); t._font = "GameFontHighlight"; t._w, t._h = 185, 16
	Obj("Texture", n .. "Icon"); Obj("Texture", n .. "Spark"); Obj("FontString", n .. "Time")
	PartyCastingBars.OnLoad(bar)
end
-- La SavedVariable llega despues de los .lua, con el estilo Arena guardado
PartyCastingBarsDB = { barStyle = "Arena", scaleByStyle = { Arena = 0.8 } }
for _, f in ipairs(cfgEv.CONFIG_LOADED) do f() end
if not LOGGED then
	for _, fr in ipairs(frames) do if fr._ev.PLAYER_LOGIN and fr._scripts.OnEvent then fr._scripts.OnEvent(fr, "PLAYER_LOGIN") end end
end
local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. m) end end
local bar = PartyMemberFrame2CastingBarFrame
check(PartyCastingBars.GetBarStyle() == "Arena", "el menu dice Arena")
check(PartyMemberFrame2CastingBarFrameBorder._shown == false, "Arena: sin marco (el de la captura)")
check(bar._w == 80 and bar._h == 13, "Arena: tamano de las barras de arena (" .. bar._w .. "x" .. bar._h .. ")")
check(bar._scale == 0.8, "Arena: su escala guardada")
check(PartyMemberFrame2CastingBarFrameText._font == "GameFontHighlightSmall" and PartyMemberFrame2CastingBarFrameText._w == 76, "Arena: texto chico y del ancho de la barra")
check(PartyMemberFrame2CastingBarFrameFlash._tex == nil, "Arena: sin flash fantasma")
-- Cambiar a Blizzard y volver
PartyCastingBars.SetBarStyle("Blizzard")
check(PartyMemberFrame2CastingBarFrameBorder._shown and PartyMemberFrame2CastingBarFrameBorder._tex:match("CastingBar%-Border") and bar._w == 195, "Blizzard: marco y tamano del template")
check(PartyMemberFrame2CastingBarFrameText._font == "GameFontHighlight" and PartyMemberFrame2CastingBarFrameText._w == 185, "Blizzard: texto como venia")
PartyCastingBars.SetBarStyle("Arcane")
check(PartyMemberFrame2CastingBarFrameBorder._tex:match("UI%-StatusBar%-Border") and PartyMemberFrame2CastingBarFrameFlash._tex:match("ArcaneBarFlash"), "Arcane: borde de tooltip y su flash")
check(PartyCastingBarsDB.barStyle == "Arcane", "Arcane guardado")
-- Cambia el ancho de las barras de arena en NUF
PartyCastingBars.SetBarStyle("Arena")
C.ArenaCastBarWidth = 120
for _, f in ipairs(cfgEv.CONFIG_CHANGED) do f() end
check(bar._w == 120, "ancho de arena cambiado en NUF -> las del grupo tambien (" .. bar._w .. ")")
-- Restablecer todo con el personaje adentro: CONFIG_LOADED otra vez
IsLoggedIn = function() return true end
PartyCastingBarsDB.barStyle = "Blizzard"
for _, f in ipairs(cfgEv.CONFIG_LOADED) do f() end
check(PartyMemberFrame2CastingBarFrameBorder._shown and bar._w == 195, "CONFIG_LOADED ya adentro: se aplica en el acto")
print(("PASS %d  FAIL %d"):format(pass, fail))

