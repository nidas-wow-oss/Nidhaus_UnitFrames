local AddOnName, ns = ...;
local K, C, L = unpack(ns);




















local GARGOYLE_SPELLID       = 49206
local GARGOYLE_NAME          = "Ebon Gargoyle"
local GARGOYLE_CAST_NAME     = "Gargoyle Strike"
local GARGOYLE_DURATION      = 30
local GARGOYLE_CAST_FALLBACK = 1.5

local MODE_BLIZZARD = "blizzard"
local MODE_CUSTOM   = "custom"




local function GTDB()
  if not NidhausUnitFramesDB then NidhausUnitFramesDB = {} end
  local db = NidhausUnitFramesDB.GargoyleTracker
  if not db then
    db = { mode = MODE_BLIZZARD, inArena = true, inBG = true, inDuel = true, inWorld = true }
    NidhausUnitFramesDB.GargoyleTracker = db
  end
  if db.mode == nil then db.mode = MODE_BLIZZARD end
  if db.inArena == nil then db.inArena = true end
  if db.inBG    == nil then db.inBG    = true end
  if db.inDuel  == nil then db.inDuel  = true end
  if db.inWorld == nil then db.inWorld = true end
  return db
end































local function GTNames()
  local db = GTDB()
  if type(db.names) ~= "table" then db.names = {} end
  local loc = GetLocale() or "enUS"
  if type(db.names[loc]) ~= "table" then db.names[loc] = {} end
  return db.names[loc]
end

local function GargName()
  local n = GTNames().unit
  return (type(n) == "string" and n ~= "") and n or GARGOYLE_NAME
end

local function GargCastName()
  local n = GTNames().cast
  return (type(n) == "string" and n ~= "") and n or GARGOYLE_CAST_NAME
end

local function LearnCastName(n)
  if type(n) == "string" and n ~= "" then GTNames().cast = n end
end

local currentMode = GTDB().mode or MODE_BLIZZARD



local function ZoneAllowed()
  local db = GTDB()
  local _, itype = GetInstanceInfo()
  if itype == "arena" then return db.inArena end
  if itype == "pvp"   then return db.inBG end

  if db.inDuel and _G.DuelOutOfBoundsTimer then return true end
  return db.inWorld
end

local function GetGargoyleIcon()
  local icon = select(3, GetSpellInfo(GARGOYLE_SPELLID))
  return (icon and icon ~= "") and icon or "Interface\\Icons\\Spell_Shadow_RaiseDead"
end

local GT_DEBUG = false
local function dbg(msg)
  if GT_DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GT|r: "..tostring(msg)) end
end




local function MakeStatusBar(parent, level, tex, r, g, b)
  local bar = CreateFrame("StatusBar", nil, parent)
  bar:SetFrameLevel(level)
  bar:SetStatusBarTexture(tex or "Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(r, g, b, 1)
  bar:SetValue(0)
  bar.bg = bar:CreateTexture(nil, "BACKGROUND")
  bar.bg:SetAllPoints(bar)
  bar.bg:SetTexture(0, 0, 0, 0.7)
  bar.txt = bar:CreateFontString(nil, "OVERLAY")
  bar.txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  bar.txt:SetPoint("CENTER", bar, "CENTER", 0, 0)
  bar.txt:SetShadowOffset(1, -1)
  bar.txt:SetShadowColor(0, 0, 0, 1)
  return bar
end

local function MakeBorder(parent, r, g, b, a)
  r, g, b, a = r or 0.5, g or 0.4, b or 0.1, a or 1
  local edges = {
    {"TOPLEFT","TOPRIGHT",true}, {"BOTTOMLEFT","BOTTOMRIGHT",true},
    {"TOPLEFT","BOTTOMLEFT",false}, {"TOPRIGHT","BOTTOMRIGHT",false}
  }
  for _, e in ipairs(edges) do
    local t = parent:CreateTexture(nil, "OVERLAY")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetVertexColor(r, g, b, a)
    t:SetPoint(e[1], parent, e[1])
    t:SetPoint(e[2], parent, e[2])
    if e[3] then t:SetHeight(1) else t:SetWidth(1) end
  end
end

















local BFW, BFH = 256, 128

local uiBlizz = CreateFrame("Frame", "GT_Blizzard", UIParent)
uiBlizz:SetSize(BFW, BFH)
uiBlizz:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
uiBlizz:SetMovable(true)
uiBlizz:EnableMouse(true)
uiBlizz:RegisterForDrag("LeftButton")
uiBlizz:SetScript("OnDragStart", uiBlizz.StartMoving)
uiBlizz:SetScript("OnDragStop",  uiBlizz.StopMovingOrSizing)
uiBlizz:SetFrameStrata("HIGH")
uiBlizz:SetFrameLevel(2)
uiBlizz:Hide()








local bIconH = CreateFrame("Frame", nil, uiBlizz)
bIconH:SetFrameLevel(1)
bIconH:SetSize(60, 60)
bIconH:SetPoint("TOPLEFT", uiBlizz, "TOPLEFT", 45, -14)

local bIconTex = bIconH:CreateTexture(nil, "ARTWORK")
bIconTex:SetAllPoints(bIconH)
SetPortraitToTexture(bIconTex, "Interface\\Icons\\Spell_Shadow_RaiseDead")


local bIconGlow = CreateFrame("Frame", nil, uiBlizz)
bIconGlow:SetFrameLevel(5)
bIconGlow:SetSize(86, 86)
bIconGlow:SetPoint("CENTER", bIconH, "CENTER", 0, 0)
local bIconGlowTex = bIconGlow:CreateTexture(nil, "OVERLAY")
bIconGlowTex:SetAllPoints(bIconGlow)
bIconGlowTex:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
bIconGlowTex:SetBlendMode("ADD")
bIconGlowTex:SetVertexColor(0.6, 0.2, 1, 0)


local bLevelF = CreateFrame("Frame", nil, uiBlizz)
bLevelF:SetFrameLevel(5)
bLevelF:SetSize(22, 14)
bLevelF:SetPoint("BOTTOMLEFT", bIconH, "BOTTOMLEFT", -2, 2)
local bLevelTxt = bLevelF:CreateFontString(nil, "OVERLAY")
bLevelTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
bLevelTxt:SetPoint("CENTER", bLevelF, "CENTER", 0, 0)
bLevelTxt:SetTextColor(1, 0.82, 0, 1)
bLevelTxt:SetShadowOffset(1, -1)
bLevelTxt:SetShadowColor(0, 0, 0, 1)
bLevelTxt:SetText("80")






local bOvH = CreateFrame("Frame", nil, uiBlizz)
bOvH:SetAllPoints(uiBlizz)
bOvH:SetFrameLevel(3)

local bOverlay = bOvH:CreateTexture(nil, "ARTWORK")
bOverlay:SetAllPoints(bOvH)
bOverlay:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame")
bOverlay:SetTexCoord(1, 0, 0, 1)





local bNameF = CreateFrame("Frame", nil, uiBlizz)
bNameF:SetFrameLevel(2)
bNameF:SetSize(118, 14)
bNameF:SetPoint("TOPLEFT", uiBlizz, "TOPLEFT", 108, -23)

local bNameTxt = bNameF:CreateFontString(nil, "OVERLAY")
bNameTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
bNameTxt:SetPoint("LEFT", bNameF, "LEFT", 0, 0)
bNameTxt:SetTextColor(1, 0.82, 0, 1)
bNameTxt:SetShadowOffset(1, -1)
bNameTxt:SetShadowColor(0, 0, 0, 1)
bNameTxt:SetText(GargName())

local bTimeTxt = bNameF:CreateFontString(nil, "OVERLAY")
bTimeTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
bTimeTxt:SetPoint("RIGHT", bNameF, "RIGHT", 0, 0)
bTimeTxt:SetTextColor(1, 1, 1, 1)
bTimeTxt:SetShadowOffset(1, -1)
bTimeTxt:SetShadowColor(0, 0, 0, 1)
bTimeTxt:SetText("")





local bHpH = CreateFrame("Frame", nil, uiBlizz)
bHpH:SetFrameLevel(2)
bHpH:SetSize(118, 10)
bHpH:SetPoint("TOPLEFT", uiBlizz, "TOPLEFT", 108, -42)

local bHpBar = MakeStatusBar(bHpH, 2,
  "Interface\\TargetingFrame\\UI-StatusBar", 0.2, 0.9, 0.2)
bHpBar:SetAllPoints(bHpH)
bHpBar:SetMinMaxValues(0, 1)







local bDurH = CreateFrame("Frame", nil, uiBlizz)
bDurH:SetFrameLevel(2)
bDurH:SetSize(118, 10)
bDurH:SetPoint("TOPLEFT", uiBlizz, "TOPLEFT", 108, -53)

local bDurBar = MakeStatusBar(bDurH, 2,
  "Interface\\TargetingFrame\\UI-StatusBar", 1, 0.46, 0.18)
bDurBar:SetAllPoints(bDurH)
bDurBar:SetMinMaxValues(0, GARGOYLE_DURATION)







local bCastH = CreateFrame("Frame", nil, uiBlizz)
bCastH:SetFrameLevel(6)
bCastH:SetSize(150, 16)
bCastH:SetPoint("TOPLEFT", uiBlizz, "TOPLEFT", 65, -80)


local bCastBg = bCastH:CreateTexture(nil, "BACKGROUND")
bCastBg:SetAllPoints(bCastH)
bCastBg:SetTexture(0, 0, 0, 0.2)


local bCastBar = MakeStatusBar(bCastH, 5,
  "Interface\\TargetingFrame\\UI-StatusBar", 1.0, 1.0, 0.5)
bCastBar:SetPoint("TOPLEFT",     bCastH, "TOPLEFT",     2, -2)
bCastBar:SetPoint("BOTTOMRIGHT", bCastH, "BOTTOMRIGHT", -2,  2)
bCastBar:SetMinMaxValues(0, GARGOYLE_CAST_FALLBACK)

bCastBar.bg:SetTexture(0, 0, 0, 0)


local bCastBorder = bCastH:CreateTexture(nil, "OVERLAY")
bCastBorder:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border-Small")
bCastBorder:SetSize(bCastH:GetWidth() + 48, 48)
bCastBorder:SetPoint("CENTER", bCastH, "CENTER", 0, 0)


local bCastIconH = CreateFrame("Frame", nil, uiBlizz)
bCastIconH:SetFrameLevel(7)
bCastIconH:SetSize(18, 18)
bCastIconH:SetPoint("RIGHT", bCastH, "LEFT", -2, 0)

local bCastIconBg = bCastIconH:CreateTexture(nil, "BACKGROUND")
bCastIconBg:SetAllPoints(bCastIconH)
bCastIconBg:SetTexture(0, 0, 0, 1)

local bCastIconTex = bCastIconH:CreateTexture(nil, "ARTWORK")
bCastIconTex:SetPoint("TOPLEFT", bCastIconH, "TOPLEFT", 1, -1)
bCastIconTex:SetPoint("BOTTOMRIGHT", bCastIconH, "BOTTOMRIGHT", -1, 1)
bCastIconTex:SetTexCoord(0.06, 0.94, 0.06, 0.94)
bCastIconTex:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowBolt")



local bCastTxtF = CreateFrame("Frame", nil, uiBlizz)
bCastTxtF:SetFrameLevel(8)
bCastTxtF:SetAllPoints(bCastH)

bCastBar.txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")


local bCastSpellTxt = bCastTxtF:CreateFontString(nil, "OVERLAY")
bCastSpellTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
bCastSpellTxt:SetPoint("LEFT", bCastH, "LEFT", 4, 0)
bCastSpellTxt:SetTextColor(1, 1, 1, 1)
bCastSpellTxt:SetShadowOffset(1, -1)
bCastSpellTxt:SetShadowColor(0, 0, 0, 1)
bCastSpellTxt:SetText("")


local bCastTimeTxt = bCastTxtF:CreateFontString(nil, "OVERLAY")
bCastTimeTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
bCastTimeTxt:SetPoint("RIGHT", bCastH, "RIGHT", -4, 0)
bCastTimeTxt:SetTextColor(1, 1, 1, 1)
bCastTimeTxt:SetShadowOffset(1, -1)
bCastTimeTxt:SetShadowColor(0, 0, 0, 1)
bCastTimeTxt:SetText("")


bCastBar.txt = bCastTimeTxt


local bCastFlashF = CreateFrame("Frame", nil, uiBlizz)
bCastFlashF:SetFrameLevel(9)
bCastFlashF:SetSize(bCastH:GetWidth() + 30, bCastH:GetHeight() + 30)
bCastFlashF:SetPoint("CENTER", bCastH, "CENTER", 0, 0)
local bCastFlash = bCastFlashF:CreateTexture(nil, "OVERLAY")
bCastFlash:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
bCastFlash:SetAllPoints(bCastFlashF)
bCastFlash:SetBlendMode("ADD")
bCastFlash:SetVertexColor(1, 0.9, 0.5, 0)
bCastFlash:SetAlpha(0)


local bCastSpark = bCastH:CreateTexture(nil, "OVERLAY")
bCastSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
bCastSpark:SetSize(16, 32)
bCastSpark:SetBlendMode("ADD")
bCastSpark:SetPoint("CENTER", bCastBar, "RIGHT", 0, 0)


bCastBar.spellTxt = bCastSpellTxt
bCastBar.iconTex  = bCastIconTex
bCastBar.iconH    = bCastIconH
bCastBar.flash    = bCastFlash
bCastBar.flashF   = bCastFlashF
bCastBar.spark    = bCastSpark
bCastBar.holder   = bCastH
bCastBar.iconHolder = bCastIconH
bCastBar.txtHolder  = bCastTxtF


bCastH:Hide()
bCastIconH:Hide()
bCastTxtF:Hide()
bCastFlashF:Hide()




local FW     = 270
local ICON_SC= 58
local PAD    = 5
local BAR_H  = 13
local BAR_GAP= 3
local ROW_H  = 14
local FH     = PAD + ROW_H + PAD/2 + BAR_H + BAR_GAP + BAR_H + PAD
local CBAR_X = PAD + ICON_SC + PAD
local CBAR_W = FW - CBAR_X - PAD

local uiCustom = CreateFrame("Frame", "GT_Custom", UIParent)
uiCustom:SetSize(FW, FH)
uiCustom:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
uiCustom:SetMovable(true)
uiCustom:EnableMouse(true)
uiCustom:RegisterForDrag("LeftButton")
uiCustom:SetScript("OnDragStart", uiCustom.StartMoving)
uiCustom:SetScript("OnDragStop",  uiCustom.StopMovingOrSizing)
uiCustom:SetFrameStrata("MEDIUM")
uiCustom:SetFrameLevel(0)
uiCustom:SetBackdrop({
  bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 10,
  insets   = { left=2, right=2, top=2, bottom=2 },
})
uiCustom:SetBackdropColor(0.04, 0.03, 0.07, 0.95)
uiCustom:SetBackdropBorderColor(0.6, 0.5, 0.15, 1)
uiCustom:Hide()

local cIconH = CreateFrame("Frame", nil, uiCustom)
cIconH:SetFrameLevel(2)
cIconH:SetSize(ICON_SC, ICON_SC)
cIconH:SetPoint("LEFT", uiCustom, "LEFT", PAD, 0)

local cIconBg = cIconH:CreateTexture(nil, "BACKGROUND")
cIconBg:SetAllPoints(cIconH)
cIconBg:SetTexture(0, 0, 0, 1)

local cIconTex = cIconH:CreateTexture(nil, "ARTWORK")
cIconTex:SetPoint("TOPLEFT",     cIconH, "TOPLEFT",     1, -1)
cIconTex:SetPoint("BOTTOMRIGHT", cIconH, "BOTTOMRIGHT", -1,  1)
cIconTex:SetTexCoord(0.06, 0.94, 0.06, 0.94)
cIconTex:SetTexture("Interface\\Icons\\Spell_Shadow_RaiseDead")

MakeBorder(cIconH, 0.6, 0.5, 0.12, 1)

local cIconGlowF = CreateFrame("Frame", nil, uiCustom)
cIconGlowF:SetFrameLevel(4)
cIconGlowF:SetSize(ICON_SC + 18, ICON_SC + 18)
cIconGlowF:SetPoint("CENTER", cIconH, "CENTER", 0, 0)
local cIconGlowTex = cIconGlowF:CreateTexture(nil, "OVERLAY")
cIconGlowTex:SetAllPoints(cIconGlowF)
cIconGlowTex:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
cIconGlowTex:SetBlendMode("ADD")
cIconGlowTex:SetVertexColor(0.6, 0.2, 1, 0)

local cSep = uiCustom:CreateTexture(nil, "ARTWORK")
cSep:SetTexture("Interface\\Buttons\\WHITE8X8")
cSep:SetVertexColor(0.5, 0.4, 0.1, 0.5)
cSep:SetWidth(1)
cSep:SetPoint("TOPLEFT",    uiCustom, "TOPLEFT",    CBAR_X - 1, -PAD)
cSep:SetPoint("BOTTOMLEFT", uiCustom, "BOTTOMLEFT", CBAR_X - 1,  PAD)

local cNameF = CreateFrame("Frame", nil, uiCustom)
cNameF:SetFrameLevel(3)
cNameF:SetSize(CBAR_W, ROW_H)
cNameF:SetPoint("TOPLEFT", uiCustom, "TOPLEFT", CBAR_X, -PAD)

local cNameTxt = cNameF:CreateFontString(nil, "OVERLAY")
cNameTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
cNameTxt:SetPoint("LEFT", cNameF, "LEFT", 2, 0)


cNameTxt:SetWidth(CBAR_W - 52)
cNameTxt:SetJustifyH("LEFT")
if cNameTxt.SetWordWrap then cNameTxt:SetWordWrap(false) end
cNameTxt:SetTextColor(1, 0.82, 0, 1)
cNameTxt:SetShadowOffset(1, -1)
cNameTxt:SetText(GargName())




local function LearnGargName(n)
  if type(n) ~= "string" or n == "" then return end
  local t = GTNames()
  if t.unit == n then return end
  t.unit = n
  if bNameTxt then bNameTxt:SetText(n) end
  if cNameTxt then cNameTxt:SetText(n) end
  dbg("nombre aprendido: " .. n)
end

local cTimeTxt = cNameF:CreateFontString(nil, "OVERLAY")
cTimeTxt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
cTimeTxt:SetPoint("RIGHT", cNameF, "RIGHT", -2, 0)
cTimeTxt:SetTextColor(1, 1, 1, 1)
cTimeTxt:SetShadowOffset(1, -1)
cTimeTxt:SetText("")

local cDurH = CreateFrame("Frame", nil, uiCustom)
cDurH:SetFrameLevel(1)
cDurH:SetSize(CBAR_W, BAR_H)
cDurH:SetPoint("TOPLEFT", uiCustom, "TOPLEFT", CBAR_X, -(PAD + ROW_H + PAD/2))
MakeBorder(cDurH, 0.35, 0.28, 0.08, 0.7)

local cDurBar = MakeStatusBar(cDurH, 2,
  "Interface\\TargetingFrame\\UI-StatusBar", 1, 0.46, 0.18)
cDurBar:SetPoint("TOPLEFT",     cDurH, "TOPLEFT",     1, -1)
cDurBar:SetPoint("BOTTOMRIGHT", cDurH, "BOTTOMRIGHT", -1,  1)
cDurBar:SetMinMaxValues(0, GARGOYLE_DURATION)

local cDurLbl = cDurH:CreateFontString(nil, "OVERLAY")
cDurLbl:SetFont("Fonts\\FRIZQT__.TTF", 7)
cDurLbl:SetPoint("LEFT", cDurH, "LEFT", 3, 0)

cDurLbl:SetTextColor(0.7, 0.6, 0.3, 0.85)
cDurLbl:SetText(L["GT_DUR"] or "Dur")

local cHpH = CreateFrame("Frame", nil, uiCustom)
cHpH:SetFrameLevel(1)
cHpH:SetSize(CBAR_W, BAR_H)
cHpH:SetPoint("TOPLEFT", uiCustom, "TOPLEFT",
  CBAR_X, -(PAD + ROW_H + PAD/2 + BAR_H + BAR_GAP))
MakeBorder(cHpH, 0.15, 0.3, 0.1, 0.7)

local cHpBar = MakeStatusBar(cHpH, 2,
  "Interface\\TargetingFrame\\UI-StatusBar", 0.2, 0.9, 0.2)
cHpBar:SetPoint("TOPLEFT",     cHpH, "TOPLEFT",     1, -1)
cHpBar:SetPoint("BOTTOMRIGHT", cHpH, "BOTTOMRIGHT", -1,  1)
cHpBar:SetMinMaxValues(0, 1)

local cHpLbl = cHpH:CreateFontString(nil, "OVERLAY")
cHpLbl:SetFont("Fonts\\FRIZQT__.TTF", 7)
cHpLbl:SetPoint("LEFT", cHpH, "LEFT", 3, 0)

cHpLbl:SetTextColor(0.3, 0.65, 0.25, 0.85)
cHpLbl:SetText(L["GT_HP"] or "HP")

local cCastH = CreateFrame("Frame", nil, uiCustom)
cCastH:SetFrameLevel(0)
cCastH:SetSize(FW - 4, 18)
cCastH:SetPoint("TOPLEFT", uiCustom, "BOTTOMLEFT", 2, -4)
cCastH:SetBackdrop({
  bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 10,
  insets   = { left=2, right=2, top=2, bottom=2 },
})
cCastH:SetBackdropColor(0.04, 0.03, 0.08, 0.95)
cCastH:SetBackdropBorderColor(0.35, 0.3, 0.45, 0.9)

local cCastBar = MakeStatusBar(cCastH, 1,
  "Interface\\TargetingFrame\\UI-StatusBar", 0.6, 0.2, 1)
cCastBar:SetPoint("TOPLEFT",     cCastH, "TOPLEFT",     2, -2)
cCastBar:SetPoint("BOTTOMRIGHT", cCastH, "BOTTOMRIGHT", -2,  2)
cCastBar:SetMinMaxValues(0, GARGOYLE_CAST_FALLBACK)

local cCastLbl = cCastH:CreateFontString(nil, "OVERLAY")
cCastLbl:SetFont("Fonts\\FRIZQT__.TTF", 7)
cCastLbl:SetPoint("LEFT", cCastH, "LEFT", 4, 0)
cCastLbl:SetTextColor(0.75, 0.7, 0.75, 0.75)
cCastLbl:SetText(L["GT_CAST"] or "Cast")






















local bCC = CreateFrame("Cooldown", nil, uiBlizz)
bCC:SetFrameLevel(2)
bCC:SetAllPoints(bIconH)
bCC:SetReverse(true)
bCC:Hide()
local bCCTex = bCC:CreateTexture(nil, "BORDER")
bCCTex:SetAllPoints(bCC)

local cCC = CreateFrame("Cooldown", nil, uiCustom)
cCC:SetFrameLevel(3)
cCC:SetAllPoints(cIconH)
cCC:SetReverse(true)
cCC:Hide()
local cCCTex = cCC:CreateTexture(nil, "BORDER")
cCCTex:SetPoint("TOPLEFT",     cCC, "TOPLEFT",      1, -1)
cCCTex:SetPoint("BOTTOMRIGHT", cCC, "BOTTOMRIGHT", -1,  1)
cCCTex:SetTexCoord(0.06, 0.94, 0.06, 0.94)





local bIconGlowActive = bIconGlowTex
local cIconGlowActive = cIconGlowTex

local ui, iconTex, iconGlow, durBar, hpBar, castBar, nameTxt, timeTxt
local ccCD, ccTex

local function SetActiveMode(mode)
  currentMode = mode
  uiBlizz:Hide()
  uiCustom:Hide()
  bCC:Hide()
  cCC:Hide()
  if mode == MODE_BLIZZARD then
    ui       = uiBlizz
    iconTex  = bIconTex
    iconGlow = bIconGlowTex
    ccCD     = bCC
    ccTex    = bCCTex
    durBar   = bDurBar
    hpBar    = bHpBar
    castBar  = bCastBar
    nameTxt  = bNameTxt
    timeTxt  = bTimeTxt
  else
    ui       = uiCustom
    iconTex  = cIconTex
    iconGlow = cIconGlowTex
    ccCD     = cCC
    ccTex    = cCCTex
    durBar   = cDurBar
    hpBar    = cHpBar
    castBar  = cCastBar
    nameTxt  = cNameTxt
    timeTxt  = cTimeTxt
  end
  GTDB().mode = mode
end

SetActiveMode(currentMode)




local GT_CALIBRATING = false
local state = {
  active=false, tStart=0, tEnd=0,
  castActive=false, castStart=0, castEnd=0, castTarget="",
  plate=nil, plateHP=nil,
  flashAlpha=0, testMode=false,
  gargGUID=nil,
  ccName=nil, ccIcon=nil, ccStart=0, ccEnd=0,
}












































local CC_SPELLS = {

  [5782]  = { 20, 8 },
  [5484]  = {  8, 8 },
  [8122]  = {  8, 8 },
  [5246]  = {  8, 8 },
  [10326] = { 20, 10 },
  [6789]  = {  3, 3 },

  [9484]  = { 50, 0 },
  [3355]  = { 20, 0 },

  [853]   = {  6, 6 },
  [44572] = {  5, 5 },
  [12809] = {  5, 5 },
  [46968] = {  4, 4 },
  [5211]  = {  4, 4 },
  [33786] = {  6, 6 },
  [49203] = { 10, 10 },

  [122]   = {  8, 8 },
  [339]   = { 27, 0 },
  [45524] = {  8, 8 },

  [47476] = {  5, 5 },
  [15487] = {  5, 5 },
}


local CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER or 0x00000100

local function CCDuration(cc, destFlags)
  if not cc then return 0 end
  if bit and bit.band and destFlags
     and bit.band(destFlags, CONTROL_PLAYER) > 0 then
    return cc.pvp or 0
  end
  return cc.pve or 0
end

local ccByName = {}
do
  for id, pair in pairs(CC_SPELLS) do
    local name, _, icon = GetSpellInfo(id)


    if name then
      ccByName[name] = { pve = pair[1], pvp = pair[2], icon = icon }
    end
  end
end













local GARG_UNITS = { "target", "focus", "mouseover", "targettarget",
  "arenapet1", "arenapet2", "arenapet3", "arenapet4", "arenapet5" }

local function ResolveGargUnit()
  if not state.gargGUID then return nil end
  for _, u in ipairs(GARG_UNITS) do
    if UnitExists(u) and UnitGUID(u) == state.gargGUID then


      LearnGargName(UnitName(u))
      return u
    end
  end
  return nil
end

local function ClearCC()
  state.ccName, state.ccIcon = nil, nil
  state.ccStart, state.ccEnd = 0, 0
  bCC:Hide()
  cCC:Hide()
end


local function ShowCC(name, icon, start, dur)
  state.ccName  = name
  state.ccIcon  = icon
  state.ccStart = start
  state.ccEnd   = (dur and dur > 0) and (start + dur) or 0

  if not ccCD or not ccTex then return false end



  if ccCD == bCC then
    SetPortraitToTexture(ccTex, icon)
  else
    ccTex:SetTexture(icon)
  end

  ccCD:Show()
  if dur and dur > 0 then
    ccCD:SetCooldown(start, dur)
  else


    ccCD:SetCooldown(0, 0)
  end
  return true
end




local function RefreshCCFromUnit()
  local u = ResolveGargUnit()
  if not u then return false end

  local best, bestExp
  for i = 1, 40 do
    local name, _, icon, _, _, duration, expirationTime = UnitDebuff(u, i)
    if not name then break end
    if ccByName[name] and expirationTime and expirationTime > 0 then
      if not bestExp or expirationTime > bestExp then
        best    = { name = name, icon = icon, dur = duration, exp = expirationTime }
        bestExp = expirationTime
      end
    end
  end

  if not best then

    if state.ccName then ClearCC() end
    return true
  end

  if state.ccName ~= best.name or math.abs((state.ccEnd or 0) - best.exp) > 0.25 then
    ShowCC(best.name, best.icon, best.exp - (best.dur or 0), best.dur)
  end
  return true
end

local function IsHostile(flags)
  return bit.band(flags or 0, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
end

local function StopCast()
  state.castActive = false
  state.castTarget = ""
  bIconGlowTex:SetVertexColor(0.6, 0.2, 1, 0)
  cIconGlowTex:SetVertexColor(0.6, 0.2, 1, 0)
end


local WakeGTDriver

local function StopAll()
  state.active     = false
  state.castActive = false
  state.flashAlpha = 0
  state.testMode   = false
  state.gargGUID   = nil
  GT_CALIBRATING   = false
  ClearCC()
  bIconGlowTex:SetVertexColor(0.6, 0.2, 1, 0)
  cIconGlowTex:SetVertexColor(0.6, 0.2, 1, 0)
  bCastH:Hide(); bCastIconH:Hide(); bCastTxtF:Hide(); bCastFlashF:Hide()
  ui:Hide()
end

local function StartCast(duration, targetName)
  state.castActive = true
  state.castStart  = GetTime()
  state.castEnd    = state.castStart + duration
  state.castTarget = targetName or ""
  castBar:SetMinMaxValues(0, duration)
  castBar:SetValue(0)
end

local function StartGargoyle(sourceName, isTest, gargGUID)


  if not isTest and not ZoneAllowed() then return end



  state.gargGUID   = gargGUID
  ClearCC()
  state.active     = true
  if WakeGTDriver then WakeGTDriver() end
  state.tStart     = GetTime()
  state.tEnd       = state.tStart + GARGOYLE_DURATION
  state.castActive = false
  state.castTarget = ""
  state.plate      = nil
  state.plateHP    = nil

  local icon = GetGargoyleIcon()
  SetPortraitToTexture(bIconTex, icon)
  cIconTex:SetTexture(icon)

  durBar:SetMinMaxValues(0, GARGOYLE_DURATION)


  durBar:SetValue(GARGOYLE_DURATION)
  durBar:SetStatusBarColor(1, 0.46, 0.18, 1)
  durBar.txt:SetText("")
  hpBar:SetValue(0)
  hpBar.txt:SetText("")
  castBar:SetValue(0)
  castBar.txt:SetText("")
  bIconGlowTex:SetVertexColor(0.6, 0.2, 1, 0)
  cIconGlowTex:SetVertexColor(0.6, 0.2, 1, 0)
  timeTxt:SetText(string.format("%.1fs", GARGOYLE_DURATION))
  timeTxt:SetTextColor(1, 1, 1, 1)

  ui:Show()
  dbg("START: "..tostring(sourceName or "?"))
end




local function FindGargoyleNameplate()
  for _, plate in ipairs({ WorldFrame:GetChildren() }) do
    if plate and plate.GetRegions and plate:IsShown() then
      local found = false
      for _, reg in ipairs({ plate:GetRegions() }) do
        if reg and reg.GetObjectType
           and reg:GetObjectType() == "FontString"
           and reg:GetText() == GargName() then
          found = true; break
        end
      end
      if found then
        for _, child in ipairs({ plate:GetChildren() }) do
          if child and child.GetObjectType
             and child:GetObjectType() == "StatusBar" then
            local _, mx = child:GetMinMaxValues()
            if mx and mx > 0 then return plate, child end
          end
        end
        return plate, nil
      end
    end
  end
  return nil, nil
end




local glowAlpha, glowDir = 0, 1
local f = CreateFrame("Frame")








f:Hide()
WakeGTDriver = function() f:Show() end

f:SetScript("OnUpdate", function(self, elapsed)
  if GT_CALIBRATING then return end
  if not state.active then self:Hide() return end

  local now = GetTime()
  local rem = state.tEnd - now
  if rem <= 0 then StopAll() return end



  durBar:SetValue(rem)
  if rem > 10 then
    durBar:SetStatusBarColor(1, 0.46, 0.18, 1)
    timeTxt:SetTextColor(1, 1, 1, 1)
  elseif rem > 5 then
    durBar:SetStatusBarColor(1, 0.85, 0.0, 1)
    timeTxt:SetTextColor(1, 0.85, 0, 1)
  else
    durBar:SetStatusBarColor(1, 0.15, 0.15, 1)
    timeTxt:SetTextColor(1, 0.3, 0.3, 1)
  end
  timeTxt:SetText(string.format("%.1fs", rem))










  local ccHandled = false
  if not state.testMode then
    ccHandled = RefreshCCFromUnit()
  end
  if not ccHandled then
    if state.ccName and state.ccEnd > 0 and now >= state.ccEnd then
      ClearCC()
    end
  end

  if not state.testMode then
    if not state.plate then
      local p, hp = FindGargoyleNameplate()
      if p then state.plate = p; state.plateHP = hp end
    end

    if state.plateHP and state.plateHP:IsShown() then
      local v = state.plateHP:GetValue()
      local _, mx = state.plateHP:GetMinMaxValues()
      if mx and mx > 0 then
        local pct = math.max(0, math.min(1, v / mx))
        hpBar:SetValue(pct)
        hpBar.txt:SetText(string.format("%d / %d", math.floor(v + 0.5), math.floor(mx + 0.5)))
        if pct > 0.5 then
          hpBar:SetStatusBarColor(0.2, 0.9, 0.2, 1)
        elseif pct > 0.25 then
          hpBar:SetStatusBarColor(1, 0.85, 0, 1)
        else
          hpBar:SetStatusBarColor(0.9, 0.15, 0.15, 1)
        end
      end
    else
      hpBar:SetValue(0)
      hpBar.txt:SetText("")
    end
  end

  if state.castActive then

    if castBar.holder and not castBar.holder:IsShown() then
      castBar.holder:Show()
      if castBar.iconHolder then castBar.iconHolder:Show() end
      if castBar.txtHolder then castBar.txtHolder:Show() end
      if castBar.flashF then castBar.flashF:Show() end
    end
    local crem = state.castEnd - now
    if crem <= 0 then
      StopCast()
      castBar:SetValue(0)
      castBar.txt:SetText("")
      if castBar.spellTxt then castBar.spellTxt:SetText("") end
      if castBar.spark then castBar.spark:SetAlpha(0) end

      if castBar.flash then
        castBar.flash:SetAlpha(1)
        state.flashAlpha = 1
      end
    else
      local progress = (now - state.castStart) / (state.castEnd - state.castStart)
      castBar:SetValue(now - state.castStart)
      castBar.txt:SetText(string.format("%.1fs", crem))
      if castBar.spellTxt then
        castBar.spellTxt:SetText(GargCastName())
      end

      if castBar.spark then
        local barW = castBar:GetWidth() or 150
        castBar.spark:ClearAllPoints()
        castBar.spark:SetPoint("CENTER", castBar, "LEFT", barW * progress, 0)
        castBar.spark:SetAlpha(1)
      end
      glowAlpha = glowAlpha + elapsed * 2.5 * glowDir
      if glowAlpha >= 0.8 then glowAlpha = 0.8; glowDir = -1
      elseif glowAlpha <= 0 then glowAlpha = 0; glowDir = 1 end
      iconGlow:SetVertexColor(0.6, 0.2, 1, glowAlpha)
    end
  else
    castBar:SetValue(0)
    castBar.txt:SetText("")
    if castBar.spellTxt then castBar.spellTxt:SetText("") end
    if castBar.spark then castBar.spark:SetAlpha(0) end
    iconGlow:SetVertexColor(0.6, 0.2, 1, 0)

    if (not state.flashAlpha or state.flashAlpha <= 0) then
      if castBar.holder and castBar.holder:IsShown() then
        castBar.holder:Hide()
        if castBar.iconHolder then castBar.iconHolder:Hide() end
        if castBar.txtHolder then castBar.txtHolder:Hide() end
        if castBar.flashF then castBar.flashF:Hide() end
      end
    end
  end


  if state.flashAlpha and state.flashAlpha > 0 then
    state.flashAlpha = state.flashAlpha - elapsed * 2.5
    if state.flashAlpha <= 0 then
      state.flashAlpha = 0

      if castBar.holder then castBar.holder:Hide() end
      if castBar.iconHolder then castBar.iconHolder:Hide() end
      if castBar.txtHolder then castBar.txtHolder:Hide() end
      if castBar.flashF then castBar.flashF:Hide() end
    end
    if castBar.flash then
      castBar.flash:SetAlpha(state.flashAlpha)
    end
  end
end)




local loginF = CreateFrame("Frame")
loginF:RegisterEvent("PLAYER_LOGIN")
loginF:SetScript("OnEvent", function(self)
  local icon = GetGargoyleIcon()
  SetPortraitToTexture(bIconTex, icon)
  cIconTex:SetTexture(icon)
  self:UnregisterAllEvents()
end)






f:SetScript("OnEvent", function(self, event, ...)
  if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then





    if not state.active then return end
    if event == "UPDATE_BATTLEFIELD_STATUS" then


      if GetBattlefieldWinner and GetBattlefieldWinner() then StopAll() end
    else

      StopAll()
    end
    return
  end
  local timestamp, subEvent,
        sourceGUID, sourceName, sourceFlags,
        destGUID, destName, destFlags,
        spellId, spellName, spellSchool = ...

  if (subEvent == "SPELL_SUMMON" or subEvent == "SPELL_CAST_SUCCESS")
     and tonumber(spellId) == GARGOYLE_SPELLID
     and IsHostile(sourceFlags) then






    if subEvent == "SPELL_SUMMON" then LearnGargName(destName) end
    StartGargoyle(sourceName, false,
      (subEvent == "SPELL_SUMMON") and destGUID or nil)
    return
  end
  if not state.active then return end



  if subEvent == "UNIT_DIED" or subEvent == "UNIT_DESTROYED" or subEvent == "PARTY_KILL" then
    local dead = (state.gargGUID and destGUID == state.gargGUID)
                 or ((not state.gargGUID) and destName == GargName())
    if dead then StopAll() end
    return
  end






  local isGarg = (state.gargGUID and destGUID == state.gargGUID)
                 or ((not state.gargGUID) and destName == GargName())
  if isGarg then
    if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then
      local cc = spellName and ccByName[spellName]
      if cc then





        local dur  = CCDuration(cc, destFlags)
        local left = state.tEnd - GetTime()
        if dur > left then dur = left end
        if dur < 0 then dur = 0 end
        ShowCC(spellName, cc.icon, GetTime(), dur)

        RefreshCCFromUnit()
      end
      return
    end
    if subEvent == "SPELL_AURA_REMOVED" or subEvent == "SPELL_AURA_BROKEN"
       or subEvent == "SPELL_AURA_BROKEN_SPELL" then
      if spellName and state.ccName == spellName then ClearCC() end
      return
    end
  end
  if subEvent == "SPELL_CAST_START"
     and sourceName == GargName() and IsHostile(sourceFlags) then
    LearnCastName(spellName)
    StartCast(GARGOYLE_CAST_FALLBACK, destName)
    return
  end
  if (subEvent == "SPELL_CAST_SUCCESS" or subEvent == "SPELL_INTERRUPT"
   or subEvent == "SPELL_CAST_FAILED")
     and sourceName == GargName() and IsHostile(sourceFlags) then
    StopCast()
    return
  end
end)




SLASH_GT1 = "/gt"
SlashCmdList.GT = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")

  if msg == "mode" then
    local wasShown = ui:IsShown()
    local oldPoint = { ui:GetPoint(1) }
    if currentMode == MODE_BLIZZARD then
      SetActiveMode(MODE_CUSTOM)
    else
      SetActiveMode(MODE_BLIZZARD)
    end
    if wasShown and #oldPoint > 0 then
      ui:ClearAllPoints()
      ui:SetPoint(oldPoint[1], oldPoint[2], oldPoint[3], oldPoint[4], oldPoint[5])
      ui:Show()
    end

  elseif msg == "debug" then
    GT_DEBUG = not GT_DEBUG
    print("GT debug = "..tostring(GT_DEBUG))

  elseif msg:match("^icon") then
    local x, y = msg:match("^icon%s+(-?%d+)%s+(-?%d+)")
    if x and y then
      x, y = tonumber(x), tonumber(y)
      bIconH:ClearAllPoints()
      bIconH:SetPoint("TOPLEFT", uiBlizz, "TOPLEFT", x, y)
      print("GT: icon movido a TOPLEFT("..x..", "..y..") 60x60")
    else
      local p1, rel, p2, cx, cy = bIconH:GetPoint(1)
      print("GT: icon actual -> TOPLEFT("..tostring(math.floor(cx+0.5))..", "..tostring(math.floor(cy+0.5))..") 60x60")
      print("GT: uso: /gt icon X Y  (ej: /gt icon 189 -8)")
    end

  elseif msg == "center" then
    ui:ClearAllPoints()
    ui:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    print("GT: centrado")


  elseif msg:match("^bars") then
    local x, w, y = msg:match("^bars%s+(-?%d+)%s+(%d+)%s*(-?%d*)")
    if x and w then
      x, w = tonumber(x), tonumber(w)
      y = tonumber(y) or -23
      bNameF:ClearAllPoints(); bNameF:SetSize(w, 14)
      bNameF:SetPoint("TOPLEFT", uiBlizz, "TOPLEFT", x, y)
      bHpH:ClearAllPoints(); bHpH:SetSize(w, 10)
      bHpH:SetPoint("TOPLEFT", uiBlizz, "TOPLEFT", x, y - 17)
      bDurH:ClearAllPoints(); bDurH:SetSize(w, 10)
      bDurH:SetPoint("TOPLEFT", uiBlizz, "TOPLEFT", x, y - 30)
      print("GT: barras -> x="..x.." w="..w.." y="..y.." (HP y="..(y-17)..", Dur y="..(y-30)..")")
    else
      print("GT: uso: /gt bars X W Y  (ej: /gt bars 107 118 -14)")
    end

  elseif msg:match("^cast") then
    local x, y = msg:match("^cast%s+(-?%d+)%s+(-?%d+)")
    if x and y then
      x, y = tonumber(x), tonumber(y)
      bCastH:ClearAllPoints()
      bCastH:SetPoint("TOPLEFT", uiBlizz, "TOPLEFT", x, y)
      bCastH:Show(); bCastIconH:Show(); bCastTxtF:Show(); bCastFlashF:Show()
      print("GT: castbar -> TOPLEFT("..x..", "..y..")")
    else
      print("GT: uso: /gt cast X Y  (ej: /gt cast 65 -80)")
    end

  elseif msg == "test" then
    StartGargoyle("TestDK", true)
    state.testMode = true

    hpBar:SetMinMaxValues(0, 1)
    hpBar:SetValue(1)
    hpBar:SetStatusBarColor(0.2, 0.9, 0.2, 1)
    hpBar.txt:SetText("24692 / 24692")
    print("GT: simulando 30s con casteos consecutivos")

    local te, castCount = 0, 0
    local tf = CreateFrame("Frame")
    tf:SetScript("OnUpdate", function(self, dt)
      if not state.active then self:SetScript("OnUpdate", nil) return end
      te = te + dt
      if not state.castActive and te >= 1.5 then
        te = 0
        castCount = castCount + 1
        StartCast(1.5, "Jugador")

        local newPct = math.max(0.1, 1 - castCount * 0.08)
        hpBar:SetValue(newPct)
        local hp = math.floor(24692 * newPct + 0.5)
        hpBar.txt:SetText(hp.." / 24692")
        if newPct > 0.5 then
          hpBar:SetStatusBarColor(0.2, 0.9, 0.2, 1)
        elseif newPct > 0.25 then
          hpBar:SetStatusBarColor(1, 0.85, 0, 1)
        else
          hpBar:SetStatusBarColor(0.9, 0.15, 0.15, 1)
        end
      end
    end)

  elseif msg == "cal" then
    if GT_CALIBRATING then
      GT_CALIBRATING = false
      ui:Hide()
      bCastH:Hide(); bCastIconH:Hide(); bCastTxtF:Hide(); bCastFlashF:Hide()
      print("GT CAL: cerrado.")
      return
    end

    GT_CALIBRATING = true
    SetActiveMode(MODE_BLIZZARD)
    ui:ClearAllPoints()
    ui:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    durBar:SetMinMaxValues(0, 100)
    durBar:SetValue(60)
    durBar:SetStatusBarColor(1, 0.46, 0.18, 1)
    durBar.txt:SetText("")
    hpBar:SetMinMaxValues(0, 1)
    hpBar:SetValue(0.6)
    hpBar:SetStatusBarColor(0.2, 0.9, 0.2, 1)
    hpBar.txt:SetText("14815 / 24692")
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0.6)
    castBar.txt:SetText("0.6s")
    if castBar.spellTxt then castBar.spellTxt:SetText(GargCastName()) end
    if castBar.holder then castBar.holder:Show() end
    if castBar.iconHolder then castBar.iconHolder:Show() end
    if castBar.txtHolder then castBar.txtHolder:Show() end
    if castBar.flashF then castBar.flashF:Show() end
    nameTxt:SetText(GargName())
    timeTxt:SetText("18.0s")
    timeTxt:SetTextColor(1, 1, 1, 1)
    ui:Show()
    print("GT CAL: modo calibracion (Blizzard). /gt cal para cerrar.")
    print("GT CAL: /gt icon X Y  /gt bars X W  para ajuste en vivo")

  elseif ui:IsShown() then
    ui:Hide(); print("GT: oculto")

  else
    ui:Show()
    print("GT: visible | /gt test  /gt mode  /gt debug")
  end
end




local gtEnabled = false


function K.ToggleGargoyleTest()
  if state.active and state.testMode then
    StopAll()
    return false
  end
  StartGargoyle("TestDK", true)
  state.testMode = true
  hpBar:SetMinMaxValues(0, 1)
  hpBar:SetValue(1)
  hpBar:SetStatusBarColor(0.2, 0.9, 0.2, 1)
  if hpBar.txt then hpBar.txt:SetText("24692 / 24692") end
  return true
end

function K.IsGargoyleTestActive()
  return state.active and state.testMode
end







function K.SetGargoylePreview(on)
  local active = K.IsGargoyleTestActive()
  if on and not active then
    K.ToggleGargoyleTest()
  elseif not on and active then
    K.ToggleGargoyleTest()
  end
end


function K.SetGargoyleMode(mode)
  if mode ~= MODE_BLIZZARD and mode ~= MODE_CUSTOM then return end
  local wasShown = ui and ui:IsShown()
  SetActiveMode(mode)
  if wasShown and ui then ui:Show() end
end

function K.GetGargoyleMode()
  return currentMode
end


function K.GetGargoyleZoneOption(key)
  return GTDB()[key] and true or false
end

function K.SetGargoyleZoneOption(key, value)
  GTDB()[key] = value and true or false
end

function K.ResetGargoylePosition()
  if uiBlizz then
    uiBlizz:ClearAllPoints()
    uiBlizz:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
  end
  if uiCustom then
    uiCustom:ClearAllPoints()
    uiCustom:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
  end
end










if K.RegisterScalable then
  K.RegisterScalable("GargoyleTracker", { uiBlizz, uiCustom }, 1.0)
end

local function GT_SetEnabled(on)
  gtEnabled = on
  if on then
    SetActiveMode(GTDB().mode or MODE_BLIZZARD)
    f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    f:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  else


    f:UnregisterAllEvents()
    StopAll()
    if uiBlizz then uiBlizz:Hide() end
    if uiCustom then uiCustom:Hide() end
  end
end

K.RegisterModule("GargoyleTracker", {
  name    = L["MOD_GARGOYLE"] or "Gargoyle Tracker",
  desc    = L["MOD_GARGOYLE_DESC"]
    or "Timer, cast bar and health of the enemy Ebon Gargoyle (Death Knight).",
  default = false,
  hideFromModulesTab = true,
  onEnable  = function() GT_SetEnabled(true) end,
  onDisable = function() GT_SetEnabled(false) end,
});
