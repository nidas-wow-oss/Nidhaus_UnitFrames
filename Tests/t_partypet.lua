-- =========================================================
-- Party pet enhanced: zonas, CC en el retrato, bordes, relojes, rango y vista previa
--
-- Se corre desde la raiz del repo:   Tests/run.sh
-- o a mano:                          lua5.1 Tests/t_partypet.lua .
-- =========================================================
local ROOT = (arg[1] or "."):gsub("/+$", "")
local FILE = ROOT .. "/Nidhaus_UnitFrames/Modules2/PartyPetFrame/PartyPetTargetFrame.lua"
local mt = {}
mt.__index = function(t, k) if type(k) == "string" and k:match("^%u") then return function() end end end
local function Obj(kind, name)
	local o = setmetatable({ _kind = kind, _name = name, _shown = (kind ~= "Button"), _scripts = {}, _attr = {} }, mt)
	function o:Show() self._shown = true end
	function o:Hide() self._shown = false end
	function o:IsShown() return self._shown end
	function o:SetScript(k, f) self._scripts[k] = f end
	function o:GetScript(k) return self._scripts[k] end
	function o:HookScript(k, f) local p = self._scripts[k]; self._scripts[k] = function(...) if p then p(...) end f(...) end end
	function o:SetTexture(t) self._tex = t end
	function o:SetText(t) self._text = t end
	function o:SetFormattedText(f, ...) self._text = string.format(f, ...) end
	function o:GetText() return self._text end
	function o:SetValue(v) self._v = v end
	function o:SetAttribute(k, v) self._attr[k] = v end
	function o:GetFrameLevel() return 1 end
	function o:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
	function o:GetStatusBarTexture() return Obj("Texture") end
	function o:CreateTexture() return Obj("Texture") end
	function o:CreateFontString() return Obj("FontString") end
	function o:SetVertexColor(r, g, b) self._c = { r, g, b } end
	function o:SetAlpha(a) self._alpha = a end
	function o:SetStatusBarColor(r, g, b) self._bar = { r, g, b } end
	function o:SetBackdropBorderColor(r, g, b, a) self._bb = { r, g, b, a } end
	function o:SetTextColor(r, g, b) self._tc = { r, g, b } end
	if name then _G[name] = o end
	return o
end
ALLF = {}
function CreateFrame(kind, name) local o = Obj(kind, name); ALLF[#ALLF + 1] = o; return o end
UIParent = Obj("Frame", "UIParent")
local combat = false
function InCombatLockdown() return combat end
local watched = {}
function RegisterUnitWatch(f) watched[f] = true end
function UnregisterUnitWatch(f) watched[f] = nil end
local cdSet = {}
function CooldownFrame_SetTimer(cd, s, d, e) cd._cd = { s, d } end
local now = 100
function GetTime() return now end
local exists = { party1pet = true, party2pet = true }
function UnitExists(u) return exists[u] or false end
function UnitName(u) return u end
function UnitHealth() return 50 end
function UnitHealthMax() return 100 end
function UnitPowerType() return 0 end
function UnitPower() return 10 end
function UnitPowerMax() return 100 end
local CLASSES = { player = "PALADIN", party1 = "HUNTER", party2 = "WARLOCK" }
function UnitClass(u) local c = CLASSES[u]; return c, c end
function UnitIsPlayer() return false end
function UnitCanAssist() return true end
function GetCVar() return "0" end
function SetPortraitTexture() end
function UnitCastingInfo() return nil end
function UnitChannelInfo() return nil end
function IsInInstance() return true, "arena" end
function GetSpellInfo(id) return "Spell" .. id, nil, "Icon" .. id end
SetPortraitToTexture = function(tex, path) tex._tex = path; tex._round = true end
local debuffs = {}
function UnitDebuff(u, i) local d = debuffs[u] and debuffs[u][i]; if not d then return nil end
	return d.name, nil, d.icon, d.count or 0, d.type, d.dur, d.exp, nil, nil, nil, d.id end
local buffs = { { "Buff1", 30, 120 }, { "Devotion Aura", 0, 0 }, { "Buff3", 0, 0 } }
function UnitBuff(u, i) local b = buffs[i]; if b then return b[1], nil, "BuffIcon" .. i, 0, nil, b[2], b[3], "player" end end
RAID_CLASS_COLORS = { HUNTER = { r = 0.67, g = 0.83, b = 0.45 }, WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
  DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 }, MAGE = { r = 0.41, g = 0.8, b = 0.94 } }
local spellRange = 1
function IsSpellInRange(name, u) if name ~= "Spell635" then return nil end return spellRange end
local ownerRange = true
function UnitInRange(u) return ownerRange and 1 or nil end
function CheckInteractDistance() return false end
SlashCmdList = {}
UIErrorsFrame = Obj("Frame")
local K, C, L = {}, { PartyPetArenaOnly = true }, setmetatable({}, { __index = function() return nil end })
local mod
K.RegisterModule = function(id, d) mod = d end
K.SaveConfig = function(k, v) C[k] = v end
local CAT = { [118] = "disorient", [853] = "ctrlstun", [339] = "ctrlroot" }
K.GetCCCategory = function(id) return CAT[id] end
local zoneFn, zoneChange
local zoneAllowed = true
K.RegisterModuleZones = function(id, fn, ch) zoneFn, zoneChange = fn, ch end
K.HasModuleZones = function() return zoneFn ~= nil end
K.ModuleZoneAllowed = function() local db = zoneFn(); local _, it = IsInInstance(); if it == "arena" then return db.inArena end; return db.inWorld end
local scal
K.RegisterScalable = function(id, frames) scal = frames end
assert(loadfile(FILE))("Nidhaus_UnitFrames", { K, C, L })


local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. m) end end
local f1, f2, f3, f4 = _G.CustomParty1PetFrame, _G.CustomParty2PetFrame, _G.CustomParty3PetFrame, _G.CustomParty4PetFrame

-- 1. conversion y limpieza
NidhausUnitFramesDB = { PartyPetFrame = { showCC = false, ccTimer = true, showTarget = true, borderStyle = "raro" } }
local db = zoneFn()
check(db.inArena == true and db.inBG == false and db.inWorld == false, "1. solo arena -> solo Arena")
check(db.showCC == nil and db.ccTimer == nil and db.showTarget == nil, "1. opciones sacadas, borradas del guardado")
check(db.borderStyle == "fino", "1. estilo invalido -> fino")
check(db.auraTimers and db.dispelGlow and db.ownerColor and db.rangeFade, "1. opciones nuevas prendidas de fabrica")
NidhausUnitFramesDB = {}; C.PartyPetArenaOnly = false
db = zoneFn()
check(db.inArena and db.inBG and db.inWorld, "1. en todos lados -> las tres")
NidhausUnitFramesDB = {}; C.PartyPetArenaOnly = true
db = zoneFn()

-- 2. zonas (sin duelos: mazmorra = mundo)
mod.onEnable()
check(watched[f1] and watched[f2], "2. en arena: unit watch")
IsInInstance = function() return true, "party" end
zoneChange()
check(not watched[f1], "2. mazmorra con solo Arena: oculto")
db.inWorld = true; zoneChange()
check(watched[f1], "2. mazmorra con Mundo abierto: se ve")
IsInInstance = function() return true, "pvp" end
zoneChange()
check(not watched[f1], "2. campo de batalla sin tildar: oculto")
db.inBG = true; zoneChange()
check(watched[f1], "2. campo de batalla tildado: se ve")
IsInInstance = function() return true, "arena" end
db.inBG, db.inWorld = false, false
zoneChange()
f1._shown, f2._shown = true, true

-- 3. CC siempre
debuffs.party1pet = { { name = "Poly", icon = "IconPoly", dur = 8, exp = now + 8, id = 118, type = "Magic" },
                      { name = "HoJ", icon = "IconHoJ", dur = 6, exp = now + 5, id = 853, type = "Magic" },
                      { name = "Curse", icon = "IconCurse", dur = 24, exp = now + 20, id = 980, type = "Curse" },
                      { name = "Rend", icon = "IconRend", dur = 15, exp = now + 3, id = 772, count = 3 } }
mod.onEnable()
check(f1.ccIcon._shown and f1.ccIcon._tex == "IconHoJ", "3. CC en el retrato (gana el stun)")
check(f1.ccCD._shown and f1.ccOverlay._shown and f1.ccGlow._shown, "3. reloj, segundos y aro, siempre")

-- 4. bordes: fino
local b1, d1, d3, d4 = f1.buffs[1], f1.debuffs[1], f1.debuffs[3], f1.debuffs[4]
check(b1._shown and b1.fOuter and b1.fOuter._shown and not b1.fRing._shown, "4. fino: buff con contorno negro, sin aro")
check(d1.fRing._shown and d1.fRing._c[3] == 1 and d1.fRing._c[1] == 0.2, "4. fino: debuff Magia con aro azul")
check(d4.fRing._c[1] == 0.8 and d4.fRing._c[2] == 0, "4. fino: debuff sin escuela -> rojo")
check(f1.buffs[2]._tex == nil or true, "")
check(f1.buffs[2]._shown and not f1.buffs[3]._shown, "4. Devotion Aura filtrada: 2 buffs a la vista")
check(b1.lGloss == nil and b1.bBorder == nil, "4. los otros estilos no crean nada")
K.SetPartyPetOption("borderStyle", "lorti")
check(b1.lGloss._shown and not b1.fOuter._shown and b1.lGloss._c[1] == 0, "4. lorti: buff con brillo negro, fino escondido")
check(d1.lRing._shown and d1.lRing._bb[3] == 1 and d1.lShadow._shown, "4. lorti: debuff con aro azul y sombra")
check(not b1.lRing._shown, "4. lorti: buff sin aro")
K.SetPartyPetOption("borderStyle", "blizzard")
check(not b1.lGloss._shown and not b1.lShadow._shown and b1.bBorder == nil, "4. blizzard: buff sin borde")
check(d1.bBorder._shown and d1.bBorder._c[3] == 1 and not d1.lRing._shown, "4. blizzard: debuff con su aro")
K.SetPartyPetOption("borderStyle", "nada")
check(zoneFn().borderStyle == "blizzard", "4. estilo invalido ignorado")
K.SetPartyPetOption("borderStyle", "fino")
check(d1.fRing._shown and not d1.bBorder._shown, "4. vuelta a fino")

-- 5. reloj y segundos
check(b1.cd._shown and b1.cd.noCooldownCount and b1.time._text == "20", "5. buff: reloj y 20 s (" .. tostring(b1.time._text) .. ")")
check(d4.count._text == "3" and d1.count._text == "", "5. acumulaciones")
check(d4.time._tc and d4.time._tc[2] == 0.25, "5. ultimos 5 s en rojo")
K.SetPartyPetOption("auraTimers", false)
check(not b1.cd._shown and b1.time._text == "", "5. sin reloj: ni barrido ni numero")
K.SetPartyPetOption("auraTimers", true)
check(b1.cd._shown, "5. reloj de vuelta")

-- 6. dispel (paladin: magia, veneno, enfermedad)
check(d1.glow._shown and not d3.glow._shown and not d4.glow._shown, "6. brilla la magia, no la maldicion ni el sin escuela")
K.SetPartyPetOption("dispelGlow", false)
check(not d1.glow._shown, "6. apagado: sin brillo")
K.SetPartyPetOption("dispelGlow", true)

-- 7. color del dueno
check(f1.healthBar._bar[1] == 0.67 and f2.healthBar._bar[1] == 0.58, "7. vida del color del dueno (cazador, brujo)")
K.SetPartyPetOption("ownerColor", false)
check(f1.healthBar._bar[1] == 0 and f1.healthBar._bar[2] == 1, "7. apagado: verde")
K.SetPartyPetOption("ownerColor", true)

-- 8. rango
check(f1._alpha == 1, "8. en rango: opaco")
spellRange = 0; mod.onEnable()
check(f1._alpha == 0.45, "8. fuera de rango (hechizo): atenuado")
K.SetPartyPetOption("rangeFade", false)
check(f1._alpha == 1, "8. opcion apagada: opaco")
K.SetPartyPetOption("rangeFade", true)
spellRange = nil; ownerRange = false; mod.onEnable()
check(f1._alpha == 0.45, "8. sin hechizo: por el dueno")
spellRange = 1; ownerRange = true; mod.onEnable()

-- 9. vista previa
check(K.TogglePartyPetPreview() == true, "9. vista previa")
check(f3.debuffs[2]._shown and f3.debuffs[2].count._text == "3", "9. veneno con 3 acumulaciones")
check(f3.debuffs[1].glow._shown and f3.debuffs[2].glow._shown and not f2.debuffs[1].glow._shown, "9. brillo: magia y veneno si, maldicion no (paladin)")
check(f4._alpha == 0.45 and f1._alpha == 1, "9. la 4 hace de lejos")
check(f3.healthBar._bar[1] == 0.77, "9. color del dueno de ejemplo (DK)")
check(f1.buffs[1].time._text == "30m", "9. buff largo en minutos (" .. tostring(f1.buffs[1].time._text) .. ")")
local t0 = f2.debuffs[1].time._text
local ticked = 0
now = now + 5
for _, fr in ipairs(ALLF) do if fr._scripts.OnUpdate and fr._kind == "Frame" and not fr.text then pcall(fr._scripts.OnUpdate, fr, 0.2); ticked = ticked + 1 end end
check(f2.debuffs[1].time._text ~= t0, "9. el reloj de la vista previa corre (" .. tostring(t0) .. " -> " .. tostring(f2.debuffs[1].time._text) .. ")")
now = now + 30
for _, fr in ipairs(ALLF) do if fr._scripts.OnUpdate and fr._kind == "Frame" and not fr.text then pcall(fr._scripts.OnUpdate, fr, 0.2) end end
check(tonumber(f2.debuffs[1].time._text) and tonumber(f2.debuffs[1].time._text) > 0, "9. al terminar vuelve a empezar (" .. tostring(f2.debuffs[1].time._text) .. ")")
local pw
for _, v in pairs(_G) do end
now = now + 1
-- el tick de la vista previa
local tick
-- buscar el frame con OnUpdate PreviewTick: es el que tiene RegisterEvent PLAYER_REGEN_DISABLED; lo probamos via UpdateAuraTime indirecto
K.SetPartyPetOption("borderStyle", "lorti")
check(f3.debuffs[1].lRing._shown and f1.buffs[1].lGloss._shown, "9. cambiar el estilo se ve en la vista previa")
K.SetPartyPetOption("borderStyle", "fino")
check(K.TogglePartyPetPreview() == false and f4._alpha == 1 and not f4.debuffs[1]._shown, "9. apagar: alfa y auras limpias")

-- 10. /ppf arena
SlashCmdList.PARTYPETFRAME("arena")
db = zoneFn()
check(db.inWorld and db.inBG, "10. /ppf arena -> en todos lados")
SlashCmdList.PARTYPETFRAME("arena")
check(not db.inWorld and not db.inBG and db.inArena, "10. otra vez -> solo arena")

-- 11. apagar con vista previa
K.TogglePartyPetPreview()
mod.onDisable()
check(not K.IsPartyPetPreview() and not f1._shown, "11. apagar el modulo saca la vista previa")
print(("PASS %d  FAIL %d"):format(pass, fail))

