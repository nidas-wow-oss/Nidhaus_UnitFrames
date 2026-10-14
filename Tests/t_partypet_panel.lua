-- =========================================================
-- Panel: la hoja "Mascotas" (zonas, bordes, casillas, vista previa)
--
-- Se corre desde la raiz del repo:   Tests/run.sh
-- o a mano:                          lua5.1 Tests/t_partypet_panel.lua .
-- =========================================================
local ROOT = (arg[1] or "."):gsub("/+$", "")
local FILE = arg[1] or "/mnt/user-data/outputs/nufarena/Nidhaus_UnitFrames_Config/OptionsPanel.lua"
local magic_mt = {}
local function Magic(name) return setmetatable({ _name = name or "?" }, magic_mt) end
local numeric = { GetStringHeight = 12, GetStringWidth = 40, GetWidth = 100, GetHeight = 20, GetFrameLevel = 1,
  GetNumPoints = 0, GetValue = 1, GetScale = 1, GetEffectiveScale = 1, GetLeft = 0, GetTop = 0, GetRight = 100, GetBottom = 0 }
magic_mt.__index = function(t, k)
  if numeric[k] ~= nil then local v = numeric[k]; return function() return v end end
  if k == "IsShown" or k == "IsVisible" then return function() return true end end
  if type(k) == "string" and not k:match("^%u") then return nil end
  local f = function(self, ...) return Magic(k) end
  rawset(t, k, f)
  return f
end
magic_mt.__call = function() return Magic("call") end

local created = {}
function CreateFrame(kind, name, parent, template)
  local f = Magic("frame:" .. tostring(kind))
  f._kind, f._parent, f._template, f._scripts, f._shown = kind, parent, template, {}, true
  f._fname = name
  f.GetName = function(self) return self._fname end
  f.GetParent = function(self) return self._parent end
  f.SetScript = function(self, k, fn) self._scripts[k] = fn end
  f.GetScript = function(self, k) return self._scripts[k] end
  f.HookScript = function(self, k, fn) local o = self._scripts[k]; self._scripts[k] = function(...) if o then o(...) end fn(...) end end
  f.SetText = function(self, t) self._text = t end
  f.GetText = function(self) return self._text end
  f.SetChecked = function(self, v) self._checked = v end
  f.GetChecked = function(self) return self._checked end
  f.Enable = function(self) self._enabled = true end
  f.Disable = function(self) self._enabled = false end
  f.IsShown = function(self) return self._shown end
  f.Show = function(self) local was = self._shown; self._shown = true; if not was and self._scripts.OnShow then self._scripts.OnShow(self) end end
  f.Hide = function(self) self._shown = false end
  f.SetPoint = function(self, ...) self._pt = { ... } end
  f.SetHeight = function(self, h) self._h = h end
  f.SetWidth = function(self, w) self._w = w end
  f.GetHeight = function(self) return self._h or 20 end
  f.SetMinMaxValues = function(self, a, b) self._min, self._max = a, b end
  f.SetValue = function(self, v) self._value = v; if self._scripts.OnValueChanged then self._scripts.OnValueChanged(self, v) end end
  f.GetValue = function(self) return self._value or 0 end
  f.CreateFontString = function(self) local fs = Magic("fs"); fs._parent = self; fs.SetText = function(s, t) s._text = t end
    fs.GetText = function(s) return s._text end; fs.GetStringHeight = function() return 12 end; created[#created + 1] = fs; return fs end
  created[#created + 1] = f
  if name then _G[name] = f
    if kind == "Slider" then for _, suf in ipairs({ "Low", "High", "Text" }) do _G[name .. suf] = f:CreateFontString() end end
    if kind == "CheckButton" then _G[name .. "Text"] = f:CreateFontString() end
  end
  return f
end
UIParent = CreateFrame("Frame", "UIParent")
GameTooltip = Magic("GameTooltip")
StaticPopupDialogs = {}
UISpecialFrames = {}
SlashCmdList = {}
function IsLoggedIn() return true end
function InCombatLockdown() return false end
function hooksecurefunc() end
function GetCVar() return "0" end
function GetCVarBool() return false end
function UnitClass() return "Hunter", "HUNTER" end
for _, n in ipairs({ "UIDropDownMenu_SetWidth", "UIDropDownMenu_Initialize", "UIDropDownMenu_SetSelectedValue", "UIDropDownMenu_SetText",
  "UIDropDownMenu_AddButton", "UIDropDownMenu_EnableDropDown", "UIDropDownMenu_DisableDropDown", "UIDropDownMenu_JustifyText", "PlaySound" }) do
  _G[n] = function() end
end
UIDropDownMenu_CreateInfo = function() return {} end
local themeInit
UIDropDownMenu_Initialize = function(dd, fn) dd._init = fn end

local K = setmetatable({}, { __index = function(t, k) return function() return Magic("K." .. k) end end })
local C = { UnitFrameCustomTexture = false, BigStatusText = false, BigTextCustomSize = false, BigTextHealthSize = 12, BigTextManaSize = 10 }
local L = { TAB_GENERAL = "Interface", TAB_FRAMES = "Frames", TAB_ARENA = "Arena", CB_UNITFRAME_CUSTOM_TEX = "Custom Skin", HEADER_THEME = "Visual Theme" }
local saved = {}
K.SaveConfig = function(k, v) saved[k] = v; C[k] = v; return true end
K.IsModuleEnabled = function() return false end
local heights = {}
K.CreateSideList = function(panel, sections)
  local r = {}
  local n = 0
  _G.SIDE_NAMES = {}
  for _, s in ipairs(sections) do if not s.separator then n = n + 1; r[n] = CreateFrame("Frame", nil, panel); _G.SIDE_NAMES[n] = s.name end end
  r.SetContentHeight = function(i, v) heights[i] = v end
  r.Select = function() end
  return r
end
K.UI = setmetatable({}, { __index = function(t, k) return function() return Magic("UI." .. k) end end })
K.UI.Header = function(s) return s end
K.UI.Strip = function(s) return s end
-- Collapsible: el de UIKit tal cual
K.UI.Collapsible = function(parent, x, y, width, height, isOpen)
  local body = CreateFrame("Frame", nil, parent)
  body:SetPoint("TOPLEFT", x, y); body:SetWidth(width or 440); body:SetHeight(height or 1)
  body._fullHeight = height or 1
  function body:Refresh()
    local open = true
    if isOpen then local ok, v = pcall(isOpen); open = ok and v and true or false end
    if open then self:Show(); self:SetHeight(self._fullHeight) else self:Hide(); self:SetHeight(1) end
    return open
  end
  parent:HookScript("OnShow", function() body:Refresh() end)
  body:Refresh()
  return body
end
local FRAMES = ROOT .. "/Nidhaus_UnitFrames_Config/OptionsPanelFrames.lua"
setmetatable(K, { __index = function(t, k) if type(k) == "string" and k:match("^_") then return nil end return function() return Magic("K." .. k) end end })
local enabled = { PartyPetFrame = false }
K.IsModuleEnabled = function(id) return enabled[id] or false end
K.SetModuleEnabled = function(id, v) enabled[id] = v end
K.RefreshModuleCheckbox = function() end
local zoneCalls, optCalls, opts = {}, {}, { showBuffs = true, showDebuffs = true, showCast = true, clickable = true, auraTimers = true, dispelGlow = true, ownerColor = true, rangeFade = true, borderStyle = "fino" }
local canDispel = true
K.PartyPetCanDispel = function() return canDispel end
K.GetModuleZone = function(id, k) return k == "inArena" end
K.SetModuleZone = function(id, k, v) zoneCalls[#zoneCalls + 1] = id .. ":" .. k .. "=" .. tostring(v) end
K.GetPartyPetOption = function(k) return opts[k] end
K.SetPartyPetOption = function(k, v) opts[k] = v; optCalls[#optCalls + 1] = k end
local preview = false
K.IsPartyPetPreview = function() return preview end
K.TogglePartyPetPreview = function() preview = not preview; return preview end
K.IsScalable = function() return false end
K.Get3v3Scale = function() return 1 end
K.Modules = { PartyPetFrame = {}, HunterPetBuffs = {} }
UIErrorsFrame = Magic("UIErrorsFrame")
_G.NidhausUnitFramesNS = { K, C, L }
assert(loadfile(FRAMES))()
local panel = CreateFrame("Frame", "PanelX")
local ok, err = pcall(K.PopulateFramesTab, panel)
print("Populate:", ok, err)
local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. m) end end
local zcb = {}
for k, v in pairs(_G) do if type(k) == "string" and k:match("^NidhausPPFZoneCB") and not k:match("Text$") then zcb[#zcb + 1] = v end end
check(#zcb == 3, "zonas: 3 casillas, sin Duelos (" .. #zcb .. ")")
check(heights[3] ~= nil, "la hoja Party pet tiene alto propio")

local body = zcb[1] and zcb[1]._parent
check(body and body._shown == false and body._h == 1, "modulo apagado: opciones plegadas")
check(SIDE_NAMES and SIDE_NAMES[3] == "Party pet", "la hoja 3 es Party pet (" .. tostring(SIDE_NAMES and SIDE_NAMES[3]) .. ")")
check(SIDE_NAMES and SIDE_NAMES[2] == "Party", "y sigue a Party")
check(SIDE_NAMES and #SIDE_NAMES == 6, "6 hojas (" .. tostring(SIDE_NAMES and #SIDE_NAMES) .. ")")
local cbPPF = _G.NidhausParty1PetCB
enabled.PartyPetFrame = true
cbPPF._checked = 1; cbPPF._scripts.OnClick(cbPPF)
check(body._shown and body._h == 226, "prender: se despliegan (226)")
check(heights[2] ~= nil, "alto del scroll recalculado")
-- zona
local inBG
for _, c in ipairs(zcb) do for _, fs in ipairs(created) do if fs._parent == c then end end end
zcb[1]._checked = 1; zcb[1]._scripts.OnClick(zcb[1])
check(#zoneCalls == 1 and zoneCalls[1]:match("^PartyPetFrame:in"), "zona: guarda en PartyPetFrame (" .. tostring(zoneCalls[1]) .. ")")
-- opciones: buscar casillas hijas del cuerpo con OnClick que llamen SetPartyPetOption
local optCount = 0
for _, f in ipairs(created) do
	if f._parent == body and f._kind == "CheckButton" and not (f._fname or ""):match("PPFZone") then
		optCount = optCount + 1
		f._checked = nil; f._scripts.OnClick(f)
	end
end
check(optCount == 11 and #optCalls == 11, "8 casillas + 3 bordes, cada una guarda (" .. optCount .. "/" .. #optCalls .. ")")
local keys = {}
for _, k in ipairs(optCalls) do keys[k] = true end
check(keys.auraTimers and keys.dispelGlow and keys.ownerColor and keys.rangeFade and keys.borderStyle, "opciones nuevas en el panel")
check(not keys.showCC and not keys.ccTimer and not keys.showTarget, "CC / segundos / objetivo sacados del panel")
check(opts.borderStyle == "blizzard", "el ultimo boton de bordes elegido: blizzard (" .. tostring(opts.borderStyle) .. ")")
-- texto de las zonas
local zt = {}
for _, c in ipairs(zcb) do local fs = _G[c._fname .. "Text"]; zt[#zt + 1] = fs and fs._text end
table.sort(zt)
check(table.concat(zt, ",") == "Arena,Battlegrounds,Open world", "zonas: " .. table.concat(zt, ","))
-- botones
local prevBtn
for _, f in ipairs(created) do if f._parent == body and f._kind == "Button" and f._text and f._text:match("Preview") then prevBtn = f end end
check(prevBtn, "boton Vista previa")
if prevBtn then prevBtn._scripts.OnClick(prevBtn); check(preview and prevBtn._text:match("Stop"), "vista previa: prende y cambia el texto") end
-- dispel: deshabilitado sin debuffs o en una clase que no saca nada
local dcb
for _, f in ipairs(created) do if f._parent == body and f._kind == "CheckButton" and f._scripts.OnClick then
	local before = #optCalls; f._scripts.OnClick(f); if optCalls[#optCalls] == "dispelGlow" then dcb = f end end end
opts.showDebuffs = true; canDispel = true; body._scripts.OnShow(body)
check(dcb and dcb._enabled ~= false, "dispel habilitado (paladin, con debuffs)")
canDispel = false; body._scripts.OnShow(body)
check(dcb and dcb._enabled == false, "dispel gris en una clase que no saca nada")
canDispel = true; opts.showDebuffs = false; body._scripts.OnShow(body)
check(dcb and dcb._enabled == false, "dispel gris sin debuffs")
print(("PASS %d  FAIL %d"):format(pass, fail))

