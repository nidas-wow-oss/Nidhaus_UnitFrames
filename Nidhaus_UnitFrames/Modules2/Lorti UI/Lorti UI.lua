local AddOnName, ns = ...
local K = ns[1]
local L = ns[3]

local cfg = CreateFrame("Frame")
local kill = function() end
local initialized = false

local function SubOpt(key)
	local C = ns[2]
	if C[key] == nil then return true end
	return C[key]
end

local function ModuleOn()
	return not (K.IsModuleEnabled and not K.IsModuleEnabled("LortiUI"))
end

local ZONES = {
	Player       = { on = "LortiUI_Player",       color = "Player"       },
	Target       = { on = "LortiUI_Target",       color = "Target"       },
	Focus        = { on = "LortiUI_Focus",        color = "Focus"        },
	Party        = { on = "LortiUI_Party",        color = "Party"        },
	PartyTargets = { on = "LortiUI_PartyTargets", color = "PartyTargets" },
	PartyPet     = { on = "LortiUI_PartyPet",     color = "PartyPet"     },
	Arena        = { on = "LortiUI_Arena",        color = "Arena"        },
	CastBar      = { on = "LortiUI_CastBar",      color = "CastBar"      },
	ActionBars   = { on = "LortiUI_ActionBars",   color = "ActionBars"   },
	Minimap      = { on = "LortiUI_Minimap",      color = "Minimap"      },
	Buffs        = { on = "LortiUI_AuraBuffs",    color = "Buff"         },
	Debuffs      = { on = "LortiUI_AuraDebuffs",  color = "Debuff"       },
}
local ZONE_ORDER = { "Player", "Target", "Focus", "Party", "PartyTargets", "PartyPet", "Arena", "CastBar",
	"ActionBars", "Minimap", "Buffs", "Debuffs" }

local KEY_TO_ZONE = {
	LortiUI_PlayerTargetFocus = "Player",
	LortiUI_Party             = "Party",
	LortiUI_PartyTargets      = "PartyTargets",
	LortiUI_PartyPet          = "PartyPet",
	LortiUI_Arena             = "Arena",
}

local DEFAULT_COLOR = { 0.40, 0.82, 1.0 };

function K.OpenColorPickerAlpha(r, g, b, a, onPick, onCancel)
	local function Pick()
		local nr, ng, nb = ColorPickerFrame:GetColorRGB()
		local na = 1 - ((OpacitySliderFrame and OpacitySliderFrame:GetValue()) or 0)
		onPick(nr, ng, nb, na)
	end
	ColorPickerFrame.func = Pick
	ColorPickerFrame.opacityFunc = Pick
	ColorPickerFrame.cancelFunc = function() if onCancel then onCancel() end end
	ColorPickerFrame.hasOpacity = true
	ColorPickerFrame.opacity = 1 - (a or 1)
	ColorPickerFrame.previousValues = { r = r, g = g, b = b, opacity = 1 - (a or 1) }
	ColorPickerFrame:SetColorRGB(r, g, b)
	ColorPickerFrame:Hide()
	ShowUIPanel(ColorPickerFrame)
end

local function Clamp01(v, def)
	v = tonumber(v);
	if not v then return def; end
	if v < 0 then return 0; end
	if v > 1 then return 1; end
	return v;
end

function K.LortiMigrateLayout()
	local C = ns[2]
	if not C or C.LortiUI_Layout2 == true then return end
	local DB = NidhausUnitFramesDB
	local function set(k, v)
		C[k] = v
		if DB then DB[k] = v end
	end
	local ptf = (C.LortiUI_PlayerTargetFocus ~= false)
	for _, z in ipairs({ "Player", "Target", "Focus", "CastBar" }) do set("LortiUI_" .. z, ptf) end
	local auras = (C.LortiUI_Auras == true)
	set("LortiUI_AuraBuffs", auras)
	set("LortiUI_AuraDebuffs", auras)
	if C.LortiUI_CustomColor == true then
		local r = Clamp01(C.LortiUI_ColorR, DEFAULT_COLOR[1])
		local g = Clamp01(C.LortiUI_ColorG, DEFAULT_COLOR[2])
		local b = Clamp01(C.LortiUI_ColorB, DEFAULT_COLOR[3])
		for _, p in ipairs({ "Player", "Target", "Focus", "Party", "PartyTargets", "PartyPet", "Arena", "CastBar", "ActionBars" }) do
			if C["LortiUI_" .. p .. "Color"] ~= true then
				set("LortiUI_" .. p .. "Color", true)
				set("LortiUI_" .. p .. "R", r)
				set("LortiUI_" .. p .. "G", g)
				set("LortiUI_" .. p .. "B", b)
			end
		end
		set("LortiUI_CustomColor", false)
	end
	for _, z in ipairs({ "Player", "Target", "Focus", "Party", "CastBar" }) do
		if C["LortiUI_" .. z .. "Color"] == true then set(ZONES[z].on, true) end
	end
	set("LortiUI_Layout2", true)
end

function K.LortiZoneOn(zone)
	local Z = ZONES[zone]
	if not Z or not ModuleOn() then return false end
	return SubOpt(Z.on) and true or false
end

function K.LortiZoneColor(zone)
	if not K.LortiZoneOn(zone) then return nil end
	local C = ns[2]
	local p = "LortiUI_" .. ZONES[zone].color
	if C[p .. "Color"] ~= true then return nil end
	return Clamp01(C[p .. "R"], DEFAULT_COLOR[1]),
	       Clamp01(C[p .. "G"], DEFAULT_COLOR[2]),
	       Clamp01(C[p .. "B"], DEFAULT_COLOR[3]),
	       Clamp01(C[p .. "A"], 1)
end

local TC_DEFAULT = { 0.3, 0.3, 0.3, 1.0 }

function K.TextureColorOn()
	return (K.IsModuleEnabled and K.IsModuleEnabled("TextureColor")) and true or false
end

function K.TextureColorTint()
	if not K.TextureColorOn() then return nil end
	local C = ns[2]
	return Clamp01(C.TextureColorR, TC_DEFAULT[1]),
	       Clamp01(C.TextureColorG, TC_DEFAULT[2]),
	       Clamp01(C.TextureColorB, TC_DEFAULT[3]),
	       Clamp01(C.TextureColorA, TC_DEFAULT[4])
end

function K.LortiZoneTint(zone, dark, mult)
	if K.LortiZoneOn(zone) then
		local r, g, b, a = K.LortiZoneColor(zone)
		mult = mult or 1
		if r then return r * mult, g * mult, b * mult, a end
		dark = dark or 0.05
		return dark, dark, dark, 1
	end

	return K.TextureColorTint()
end

function K.LortiTint(key, part)
	local zone = part or KEY_TO_ZONE[key] or "Player"
	return K.LortiZoneTint(zone, (zone == "Arena") and 0.1 or 0.05, 1)
end

function K.ApplyLortiTint(tex, key, part)
	if not tex then return false; end
	local r, g, b, a = K.LortiTint(key, part);
	if not r then
		tex:SetVertexColor(1, 1, 1, 1);
		return false;
	end
	tex:SetVertexColor(r, g, b, a or 1);
	return true;
end

function K.LortiMinimapTint()
	local r, g, b, a = K.LortiZoneColor("Minimap")
	if r then return r, g, b, a end
	return 0.05, 0.05, 0.05, 1
end

function K.LortiCastBarColor()
	return K.LortiZoneColor("CastBar")
end

local tinted = {}

local function TintOne(tex, zone, dark, mult, rr, rg, rb)
	if not tex then return end
	local r, g, b, a = K.LortiZoneTint(zone, dark, mult)
	if r then
		tex:SetVertexColor(r, g, b, a or 1)
		tinted[tex] = true
	elseif tinted[tex] then
		tinted[tex] = nil
		tex:SetVertexColor(rr or 1, rg or 1, rb or 1, 1)
	end
end

local FRAME_TEXTURES = {

	{ "PlayerFrameTexture",                "Player", true },
	{ "PetFrameTexture",                   "Player" },
	{ "TargetFrameTextureFrameTexture",    "Target", true },
	{ "TargetFrameToTTextureFrameTexture", "Target" },
	{ "FocusFrameTextureFrameTexture",     "Focus",  true },
	{ "FocusFrameToTTextureFrameTexture",  "Focus" },
}

local function TintUnitFrames()

	local skipPlayer = K.IcyPlayerFrameOn and K.IcyPlayerFrameOn();
	for _, e in ipairs(FRAME_TEXTURES) do
		if not (skipPlayer and e[1] == "PlayerFrameTexture") then

			TintOne(_G[e[1]], e[2], 0.05, 1, 1, 1, 1)
		end
	end
end

local PARTY_SUFFIX = { "Texture", "PetFrameTexture", "VehicleTexture" }
local function TintPartyFrames()
	for i = 1, 4 do
		for _, suf in ipairs(PARTY_SUFFIX) do
			TintOne(_G["PartyMemberFrame" .. i .. suf], "Party", 0.05)
		end
	end
end

local CASTBAR_BORDERS = { "CastingBarFrameBorder", "TargetFrameSpellBarBorder", "FocusFrameSpellBarBorder" }
local castTouched = false

local function ApplyCastBarBorders()
	local r, g, b, a = K.LortiZoneTint("CastBar", 0.05)
	if not r and not castTouched then return end
	for _, n in ipairs(CASTBAR_BORDERS) do
		local tex = _G[n]
		if tex then
			if r then tex:SetVertexColor(r, g, b, a or 1) else tex:SetVertexColor(1, 1, 1, 1) end
		end
	end
	local was = castTouched
	castTouched = (r ~= nil)

	if was and not r then
		local C = ns[2]
		if C.CastBarPWEnabled and K.ApplyCastBarPW then K.ApplyCastBarPW() end
	end
end

local clockTinted = false
local function ApplyClock()
	local r, g, b, a = K.LortiZoneTint("Minimap", 0.05)
	if not r and not clockTinted then return end
	clockTinted = (r ~= nil)
	if not r then r, g, b, a = 1, 1, 1, 1 end
	for _, f in ipairs({ TimeManagerClockButton or false, GameTimeFrame or false }) do
		if f then
			local region = select(1, f:GetRegions())
			if region then region:SetVertexColor(r, g, b, a or 1) end
		end
	end
end

local function ApplyDarkArenaTextures()
	for i = 1, 5 do
		TintOne(_G["ArenaEnemyFrame" .. i .. "Texture"], "Arena", 0.1)
		TintOne(_G["ArenaEnemyFrame" .. i .. "PetFrameTexture"], "Arena", 0.1)
	end
end

local BAR_TEXTURES = {
	"BonusActionBarTexture0", "BonusActionBarTexture1",
	"MainMenuBarTexture0", "MainMenuBarTexture1", "MainMenuBarTexture2", "MainMenuBarTexture3",
	"MainMenuMaxLevelBar0", "MainMenuMaxLevelBar1", "MainMenuMaxLevelBar2", "MainMenuMaxLevelBar3",
	"MainMenuXPBarTextureLeftCap", "MainMenuXPBarTextureRightCap", "MainMenuXPBarTextureMid",
	"MainMenuXPBarTexture0", "MainMenuXPBarTexture1", "MainMenuXPBarTexture2", "MainMenuXPBarTexture3",
	"ReputationWatchBarTexture0", "ReputationWatchBarTexture1", "ReputationWatchBarTexture2", "ReputationWatchBarTexture3",
	"ReputationXPBarTexture0", "ReputationXPBarTexture1", "ReputationXPBarTexture2", "ReputationXPBarTexture3",
}
local function ApplyActionBarTextures()
	for _, n in ipairs(BAR_TEXTURES) do TintOne(_G[n], "ActionBars", 0.2, 0.6) end
	TintOne(MainMenuBarLeftEndCap, "ActionBars", 0.35, 0.8)
	TintOne(MainMenuBarRightEndCap, "ActionBars", 0.35, 0.8)
end

local EXTRA_TEXTURES = {
	{ "ShapeshiftBarLeft", "ActionBars" }, { "ShapeshiftBarMiddle", "ActionBars" },
	{ "ShapeshiftBarRight", "ActionBars" }, { "PossessBackground1", "ActionBars" },
	{ "PossessBackground2", "ActionBars" }, { "SlidingActionBarTexture0", "ActionBars" },
	{ "SlidingActionBarTexture1", "ActionBars" },
	{ "MiniMapTrackingButtonBorder", "Minimap" }, { "MiniMapLFGFrameBorder", "Minimap" },
	{ "MiniMapBattlefieldBorder", "Minimap" }, { "MiniMapMailBorder", "Minimap" },
	{ "MiniMapWorldBorder", "Minimap" },
	{ "PlayerFrameVehicleTexture", "Player" }, { "PlayerFrameAlternateManaBarBorder", "Player" },
	{ "PetCastingBarFrameBorder", "CastBar" },
	{ "TargetFrameSpellBarBorderShield", "CastBar" }, { "FocusFrameSpellBarBorderShield", "CastBar" },
}
for i = 1, 5 do
	EXTRA_TEXTURES[#EXTRA_TEXTURES + 1] = { "Boss" .. i .. "TargetFrameTextureFrameTexture", "Target" }
	EXTRA_TEXTURES[#EXTRA_TEXTURES + 1] = { "Boss" .. i .. "TargetFrameSpellBarBorder", "Target" }
end
for i = 1, 6 do
	EXTRA_TEXTURES[#EXTRA_TEXTURES + 1] = { "RuneButtonIndividual" .. i .. "BorderTexture", "Player" }
end
local extraTinted = {}

local function TintExtra(tex, zone)
	if not tex or not tex.SetVertexColor then return end
	local r, g, b, a
	if not K.LortiZoneOn(zone) then r, g, b, a = K.TextureColorTint() end
	if r then
		tex:SetVertexColor(r, g, b, a)
		extraTinted[tex] = true
	elseif extraTinted[tex] then
		extraTinted[tex] = nil
		tex:SetVertexColor(1, 1, 1, 1)
	end
end

local function ApplyTextureExtras()
	for _, e in ipairs(EXTRA_TEXTURES) do TintExtra(_G[e[1]], e[2]) end

	for i = 1, 5 do
		local cp = _G["ComboPoint" .. i]
		if cp then TintExtra((select(1, cp:GetRegions())), "Target") end
	end

	if not K.LortiZoneOn("Minimap") then
		TintExtra(MinimapBorder, "Minimap")
		TintExtra(MinimapBorderTop, "Minimap")
	end
end

local function InitMinimap()
	if not SubOpt("LortiUI_Minimap") then return end
	local ok, err = pcall(function()

		if MiniMapTracking then
			MiniMapTracking:Show()
			MiniMapTracking.Show = kill
			MiniMapTracking:UnregisterAllEvents()
		end
		if Minimap then
			Minimap:EnableMouseWheel(true)
			Minimap:SetScript("OnMouseWheel", function(self, z)
				local c = Minimap:GetZoom()
				if z > 0 and c < 5 then Minimap:SetZoom(c + 1)
				elseif z < 0 and c > 0 then Minimap:SetZoom(c - 1) end
			end)
			Minimap:SetScript("OnMouseUp", function(self, btn)
				if btn == "RightButton" then
					if _G.GameTimeFrame then _G.GameTimeFrame:Click() end
				elseif btn == "MiddleButton" then
					_G.ToggleDropDownMenu(1, nil, _G.MiniMapTrackingDropDown, self)
				else
					_G.Minimap_OnClick(self)
				end
			end)
		end
	end)
	if not ok then
		print("|cffFF0000NUF Lorti:|r " .. (L["LORTI_MINIMAP_ERR"] or "Minimap init error:") .. " " .. tostring(err))
	end
end

local buffsOn, debuffsOn = false, false
local auraStyled = {}
local auraOrig = {}
local TEMP_COLOR = { 0.6, 0.2, 0.9 }

local function SnapPoints(region)
	if not region then return nil end
	local n = region:GetNumPoints() or 0
	if n == 0 then return nil end
	local pts = {}
	for i = 1, n do pts[i] = { region:GetPoint(i) } end
	return pts
end

local function AuraShadowColor(kind)
	local r, g, b = K.LortiZoneColor((kind == "Debuff") and "Debuffs" or "Buffs")
	if r then return r, g, b, 1 end
	local sc = cfg.background.shadowcolor
	return sc.r, sc.g, sc.b, sc.a
end

local function AuraGlossColor(bu, kind)
	if kind == "Debuff" then

		local bo = _G[bu:GetName() .. "Border"]
		if bo and bo.GetVertexColor then
			local r, g, b = bo:GetVertexColor()
			if r then return r, g, b end
		end
		return 0.8, 0, 0
	elseif kind == "Temp" then
		return TEMP_COLOR[1], TEMP_COLOR[2], TEMP_COLOR[3]
	end
	local n = cfg.color.normal
	return n.r, n.g, n.b
end

local function StyleAura(bu, kind)
	local name = bu and bu.GetName and bu:GetName()
	if not name then return end
	local icon = _G[name .. "Icon"]
	if not auraOrig[bu] then
		auraOrig[bu] = { pts = SnapPoints(icon), coord = icon and { icon:GetTexCoord() } or nil }
	end
	if not bu.nufLortiGloss then

		local gl = bu:CreateTexture(nil, "OVERLAY")
		if gl.SetDrawLayer then pcall(gl.SetDrawLayer, gl, "OVERLAY", -1) end
		gl:SetTexture(cfg.textures.normal)
		gl:SetAllPoints(bu)
		bu.nufLortiGloss = gl
		local sh = CreateFrame("Frame", nil, bu)
		sh:SetFrameLevel(math.max(0, (bu:GetFrameLevel() or 1) - 1))
		bu.nufLortiShadow = sh
	end
	auraStyled[bu] = kind

	local big = (bu:GetWidth() or 30) >= 26
	local inset = big and 2 or 1
	if icon then
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", bu, "TOPLEFT", inset, -inset)
		icon:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -inset, inset)
		icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	end
	local sh = bu.nufLortiShadow
	local off = big and 4 or 3
	if sh.nufOff ~= off then
		sh.nufOff = off
		sh:ClearAllPoints()
		sh:SetPoint("TOPLEFT", bu, "TOPLEFT", -off, off)
		sh:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", off, -off)
		sh:SetBackdrop({
			edgeFile = cfg.textures.outer_shadow, edgeSize = off + 1,
			insets = { left = off + 1, right = off + 1, top = off + 1, bottom = off + 1 },
		})
	end
	sh:SetBackdropBorderColor(AuraShadowColor(kind))
	sh:Show()
	bu.nufLortiGloss:SetVertexColor(AuraGlossColor(bu, kind))
	bu.nufLortiGloss:Show()

	local bo = _G[name .. "Border"]
	if bo then bo:Hide() end
end

local function RestoreAura(bu)
	if not auraStyled[bu] then return end
	auraStyled[bu] = nil
	if bu.nufLortiGloss then bu.nufLortiGloss:Hide() end
	if bu.nufLortiShadow then bu.nufLortiShadow:Hide() end
	local name = bu:GetName()
	local icon = name and _G[name .. "Icon"]
	local o = auraOrig[bu]
	if icon and o then
		icon:ClearAllPoints()
		if o.pts then
			for _, pt in ipairs(o.pts) do pcall(icon.SetPoint, icon, unpack(pt)) end
		else

			icon:SetAllPoints(bu)
		end
		if o.coord and #o.coord >= 4 then pcall(icon.SetTexCoord, icon, unpack(o.coord)) end
	end
	local bo = name and _G[name .. "Border"]
	if bo then bo:Show() end
end

if type(AuraButton_Update) == "function" then
	hooksecurefunc("AuraButton_Update", function(buttonName, index)
		local isDebuff = (buttonName == "DebuffButton")
		if isDebuff then
			if not debuffsOn then return end
		elseif not buffsOn then
			return
		end
		local bu = _G[buttonName .. index]
		if not bu or not bu:IsShown() then return end
		StyleAura(bu, isDebuff and "Debuff" or "Buff")
	end)
end

function K.ApplyLortiAuras()
	buffsOn = K.LortiZoneOn("Buffs")
	debuffsOn = K.LortiZoneOn("Debuffs")
	for bu, kind in pairs(auraStyled) do
		local want = buffsOn
		if kind == "Debuff" then want = debuffsOn end
		if not want then RestoreAura(bu) end
	end
	if buffsOn then
		for i = 1, (BUFF_MAX_DISPLAY or 32) do
			local bu = _G["BuffButton" .. i]
			if bu and bu:IsShown() then StyleAura(bu, "Buff") end
		end

		for i = 1, 3 do
			local bu = _G["TempEnchant" .. i]
			if bu then StyleAura(bu, "Temp") end
		end
	end
	if debuffsOn then
		for i = 1, (DEBUFF_MAX_DISPLAY or 16) do
			local bu = _G["DebuffButton" .. i]
			if bu and bu:IsShown() then StyleAura(bu, "Debuff") end
		end
	end
end

local function ApplyAll()
	TintUnitFrames()
	TintPartyFrames()
	ApplyCastBarBorders()
	ApplyClock()
	if IsAddOnLoaded("Blizzard_ArenaUI") then ApplyDarkArenaTextures() end
	ApplyActionBarTextures()
	ApplyTextureExtras()

	if K.ApplyLortiButtonColor then K.ApplyLortiButtonColor() end
	K.ApplyLortiAuras()
end

local painterReady = false

function K.ApplyLortiColor()
	if not painterReady then return end
	ApplyAll()

	if ModuleOn() and SubOpt("LortiUI_Minimap") and K.ApplyMinimapSettings then K.ApplyMinimapSettings() end
end

local function WhenLoaded(addon, fn)
	if IsAddOnLoaded(addon) then fn(); return end
	local f = CreateFrame("Frame")
	f:RegisterEvent("ADDON_LOADED")
	f:SetScript("OnEvent", function(self, event, name)
		if name == addon then
			self:UnregisterEvent("ADDON_LOADED")
			self:SetScript("OnEvent", nil)
			fn()
		end
	end)
end

local function StartPainter()
	if painterReady then ApplyAll(); return end
	painterReady = true
	ApplyAll()

	WhenLoaded("Blizzard_TimeManager", ApplyClock)
	WhenLoaded("Blizzard_ArenaUI", ApplyDarkArenaTextures)

	if K.RegisterConfigEvent then
		K.RegisterConfigEvent("CONFIG_LOADED", function()
			if ModuleOn() or K.TextureColorOn() then ApplyAll() end
		end)
	end
end

local function Init()
	if initialized then return end
	initialized = true
	if K.LortiMigrateLayout then K.LortiMigrateLayout() end

	InitMinimap()
	StartPainter()
end

cfg.textures = {
	normal         = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\gloss",
	flash          = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\flash",
	hover          = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\hover",
	pushed         = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\pushed",
	checked        = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\checked",
	equipped       = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\gloss_grey",
	buttonback     = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\button_background",
	buttonbackflat = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\button_background_flat",
	outer_shadow   = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\outer_shadow",
}
cfg.background = {
	showbg = true, showshadow = true, useflatbackground = false,
	backgroundcolor = { r=0.3, g=0.3, b=0.3, a=0.7 },
	shadowcolor     = { r=0,   g=0,   b=0,   a=0.9 },
	classcolored = false, inset = 5,
}
cfg.color = {
	normal   = { r=0,   g=0,    b=0,   a=0.9 },
	equipped = { r=0.3, g=0.55, b=0.1 },
	classcolored = false,
}
cfg.hotkeys   = { show=true, fontsize=12, pos1={a1="TOPRIGHT",x=0,y=0}, pos2={a1="TOPLEFT",x=0,y=0} }
cfg.macroname = { show=true, fontsize=11, pos1={a1="BOTTOMLEFT",x=-4,y=0}, pos2={a1="BOTTOMRIGHT",x=4,y=0} }
cfg.itemcount = { show=true, fontsize=12, pos1={a1="BOTTOMRIGHT",x=0,y=0} }
cfg.cooldown  = { spacing=0 }
cfg.font      = "Fonts\\FRIZQT__.TTF"
ns.cfg = cfg

local ZONE_INFO = {

	Player       = { "Player", "Your frame and your pet's frame, in any style (Default, Light, Dark, Compact or Asuri). The mage's Icy frame keeps its own colors." },
	Target       = { "Target", "The target frame and its target of target, in any style." },
	Focus        = { "Focus", "The focus frame and its target, in any style." },
	Party        = { "Party", "The 4 party frames, their pets and their vehicle frame, in any party style (Default, New, Improved or Compact)." },
	PartyTargets = { "Party targets", "The target-of-party frames.", true },
	PartyPet     = { "Party pets", "The enhanced party pet frames and their cast bar border.", true },
	Arena        = { "Arena", "The enemy arena frames and their pets.", true },
	CastBar      = { "Cast bars", "The border of the cast bars: yours, target and focus." },
	ActionBars   = { "Action bars", "The action bar art (also the XP and reputation bars) and the glow around the action buttons." },
	Minimap      = { "Minimap", "The Lorti UI border of the minimap, and the clock. Same option as Interface > Minimap > Border style: Lorti UI.\nAlso: right-click the minimap to open the calendar." },
	Buffs        = { "Your buffs", "Your buffs (top right) and your weapon enchants: cut icon, Lorti border and glow. The target and focus auras stay normal." },
	Debuffs      = { "Your debuffs", "Your debuffs: cut icon and glow. The border keeps the school color (Magic, Curse, Poison, Disease)." },
}
local LEFT_ZONES  = { "Player", "Target", "Focus", "Party", "PartyTargets", "PartyPet", "Arena", "CastBar" }
local RIGHT_ZONES = { "ActionBars", "Minimap", "Buffs", "Debuffs" }

local function CreateLortiSubUI(container, yOffset, parentCheckbox)
	local C = ns[2]
	if K.LortiMigrateLayout then K.LortiMigrateLayout() end

	local wrapper = CreateFrame("Frame", nil, container)
	wrapper:SetPoint("TOPLEFT", 0, yOffset)
	local W = container:GetWidth() or 540
	if not W or W < 400 then W = 540 end
	wrapper:SetWidth(W)

	local sep = wrapper:CreateTexture(nil, "ARTWORK")
	sep:SetHeight(1)
	sep:SetPoint("TOPLEFT", 36, 4)
	sep:SetPoint("TOPRIGHT", -10, 4)
	sep:SetTexture(1, 1, 1, 0.07)

	local CB_S  = 0.85
	local X1    = 46
	local GAP   = 30
	local COL_W = math.max(220, math.min(270, math.floor((W - X1 - GAP - 20) / 2)))
	local X2    = X1 + COL_W + GAP
	local ROW_H = 22
	local TOP   = -8
	local FIRST = TOP - 16

	local function SaveKey(key, v)
		local save = K.SaveConfigSilent or K.SaveConfig
		save(key, v)
	end
	local function ColorOf(p)
		return Clamp01(C[p .. "R"], DEFAULT_COLOR[1]),
		       Clamp01(C[p .. "G"], DEFAULT_COLOR[2]),
		       Clamp01(C[p .. "B"], DEFAULT_COLOR[3]),
		       Clamp01(C[p .. "A"], 1)
	end
	local function MakeCB(name, x, y)
		local cb = CreateFrame("CheckButton", name, wrapper, "InterfaceOptionsCheckButtonTemplate")
		cb:SetScale(CB_S)
		cb:SetPoint("TOPLEFT", wrapper, "TOPLEFT", x / CB_S, y / CB_S)
		local t = _G[name .. "Text"]
		if t then t:SetText("") end
		return cb
	end
	local function Text(text, point, x, y, font)
		local fs = wrapper:CreateFontString(nil, "ARTWORK", font or "GameFontDisableSmall")
		fs:SetPoint(point, wrapper, "TOPLEFT", x, y)
		fs:SetText(text)
		return fs
	end

	local function Cols(x)
		local lx = x + COL_W - 74
		return lx, lx + 28, lx + 54
	end
	local function Tip(owner, title, line, warn)
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:SetText(title, 1, 1, 1)
		if line then GameTooltip:AddLine(line, nil, nil, nil, true) end
		if warn then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(warn, 1, 0.67, 0, true)
		end
		GameTooltip:Show()
	end
	local function HideTip() GameTooltip:Hide() end

	local function OpenPicker(r, g, b, a, onPick, onCancel)
		K.OpenColorPickerAlpha(r, g, b, a, onPick, onCancel)
	end
	local function MakeSwatch(x, y)
		local sw = CreateFrame("Button", nil, wrapper)
		sw:SetSize(18, 18)
		sw:SetPoint("TOPLEFT", wrapper, "TOPLEFT", x, y - 2)
		local bd = sw:CreateTexture(nil, "BACKGROUND")
		bd:SetPoint("TOPLEFT", -1, 1)
		bd:SetPoint("BOTTOMRIGHT", 1, -1)
		bd:SetTexture(0.6, 0.6, 0.6, 1)
		local tx = sw:CreateTexture(nil, "ARTWORK")
		tx:SetAllPoints()
		tx:SetTexture(1, 1, 1, 1)
		sw.tex = tx
		sw:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		return sw
	end

	local function Header(x, text)
		local lx, cx = Cols(x)
		Text(text, "TOPLEFT", x, TOP, "GameFontNormalSmall")
		Text(L["LORTI_COL_LORTI"] or "Lorti", "TOP", lx + 11, TOP)
		Text(L["LORTI_COL_COLOR"] or "Color", "TOP", cx + 20, TOP)
	end
	Header(X1, L["LORTI_GROUP_FRAMES"] or "Frames")
	Header(X2, L["LORTI_GROUP_UI"] or "Interface")

	local rows = {}
	local RefreshAll
	local function Apply()
		if K.ApplyLortiColor then K.ApplyLortiColor() end
	end

	local function MakeRow(zone, x, y)
		local Z, info = ZONES[zone], ZONE_INFO[zone]
		local p = "LortiUI_" .. Z.color
		local label = L["LORTI_Z_" .. zone] or info[1]
		local tip = L["LORTI_ZTIP_" .. zone] or info[2]
		local reload = info[3]
		local lx, cx, sx = Cols(x)

		local name = wrapper:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		name:SetPoint("LEFT", wrapper, "TOPLEFT", x, y - 11)
		name:SetText(label .. (reload and " |cff888888*|r" or ""))

		local lorti = MakeCB("NidhausLortiZone_" .. zone, lx, y)

		lorti:SetHitRectInsets(-(lx - x) / CB_S, 0, 0, 0)
		local color = MakeCB("NidhausLortiColor_" .. zone, cx, y)

		color:SetHitRectInsets(0, 0, 0, 0)
		local sw = MakeSwatch(sx, y)

		sw:SetFrameLevel((color:GetFrameLevel() or 1) + 2)

		local row = { zone = zone }
		function row.Avail()
			if C[Z.on] == false then return false end
			if zone == "Minimap" then

				local style = (K.GetMinimapBorderStyle and K.GetMinimapBorderStyle()) or C.MinimapBorderStyle
				return style == "Lorti"
			end
			return true
		end
		function row.Refresh()
			local on = (C[Z.on] ~= false)
			lorti:SetChecked(on)
			local v = on and 1 or 0.55
			name:SetTextColor(v, v, v)
			local avail = row.Avail()
			local colOn = (C[p .. "Color"] == true)
			color:SetChecked(colOn)
			if avail then color:Enable() else color:Disable() end
			sw.tex:SetVertexColor(ColorOf(p))
			if avail and colOn then
				sw:Enable(); sw:SetAlpha(1)
			else
				sw:Disable(); sw:SetAlpha(0.3)
			end
		end

		lorti:SetScript("OnEnter", function(self)
			Tip(self, label, tip, reload and ("\226\154\160 " .. (L["LORTI_REQ_RELOAD"] or "Requires /reload")) or nil)
		end)
		lorti:SetScript("OnLeave", HideTip)
		lorti:SetScript("OnClick", function(self)
			local checked = self:GetChecked() == 1 or self:GetChecked() == true
			K.SaveConfig(Z.on, checked)

			if zone == "Minimap" then
				local cur = (K.GetMinimapBorderStyle and K.GetMinimapBorderStyle()) or C.MinimapBorderStyle
				if checked then
					K.SaveConfig("MinimapBorderStyle", "Lorti")
				elseif cur == "Lorti" then
					K.SaveConfig("MinimapBorderStyle", "Default")
				end
				if K.ApplyMinimapSettings then K.ApplyMinimapSettings() end
			end
			Apply()
			RefreshAll()
		end)

		color:SetScript("OnEnter", function(self)
			Tip(self, (L["LORTI_COL_COLOR"] or "Color") .. ": " .. label,
				L["LORTI_COLOR_TIP"] or "Your own color instead of black. Click the square to choose it; right-click it for the default color.",
				(not row.Avail()) and (L["LORTI_COLOR_OFF"] or "Tick 'Lorti' on this row first.") or nil)
		end)
		color:SetScript("OnLeave", HideTip)
		color:SetScript("OnClick", function(self)
			local checked = self:GetChecked() == 1 or self:GetChecked() == true
			K.SaveConfig(p .. "Color", checked)
			row.Refresh()
			Apply()
		end)

		sw:SetScript("OnEnter", function(self)
			Tip(self, (L["LORTI_COL_COLOR"] or "Color") .. ": " .. label,
				L["LORTI_SWATCH_TIP"] or "Click: choose the color (applies instantly).\nRight-click: back to the default color.")
		end)
		sw:SetScript("OnLeave", HideTip)
		sw:SetScript("OnClick", function(self, button)
			local function Save(r, g, b, a)
				SaveKey(p .. "R", r); SaveKey(p .. "G", g); SaveKey(p .. "B", b); SaveKey(p .. "A", a or 1)
				sw.tex:SetVertexColor(r, g, b, a or 1)
				Apply()
			end
			if button == "RightButton" then
				Save(DEFAULT_COLOR[1], DEFAULT_COLOR[2], DEFAULT_COLOR[3], 1)
				return
			end
			local r, g, b, a = ColorOf(p)
			OpenPicker(r, g, b, a, Save, function() Save(r, g, b, a) end)
		end)

		row.Refresh()
		rows[#rows + 1] = row
	end

	for i, zone in ipairs(LEFT_ZONES) do MakeRow(zone, X1, FIRST - (i - 1) * ROW_H) end
	for i, zone in ipairs(RIGHT_ZONES) do MakeRow(zone, X2, FIRST - (i - 1) * ROW_H) end

	local yR = FIRST - #RIGHT_ZONES * ROW_H - 6
	local line = wrapper:CreateTexture(nil, "ARTWORK")
	line:SetHeight(1)
	line:SetWidth(COL_W - 2)
	line:SetPoint("TOPLEFT", wrapper, "TOPLEFT", X2, yR)
	line:SetTexture(1, 1, 1, 0.08)
	yR = yR - 6

	local allLbl = wrapper:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	allLbl:SetPoint("LEFT", wrapper, "TOPLEFT", X2, yR - 11)
	allLbl:SetText(L["LORTI_ALL_COLOR"] or "Same color for all")
	local _, _, sxAll = Cols(X2)
	local allSw = MakeSwatch(sxAll, yR)
	allSw:SetScript("OnEnter", function(self)
		Tip(self, L["LORTI_ALL_COLOR"] or "Same color for all",
			L["LORTI_ALL_COLOR_TIP"] or "Paints every row that has 'Lorti' ticked with this color, and ticks its 'Color'. Cancel in the picker leaves everything as it was.")
	end)
	allSw:SetScript("OnLeave", HideTip)
	allSw:SetScript("OnClick", function()
		local snap = {}
		for _, z in ipairs(ZONE_ORDER) do
			local p = "LortiUI_" .. ZONES[z].color
			snap[z] = { C[p .. "Color"] == true, ColorOf(p) }
		end
		local r0, g0, b0, a0 = ColorOf("LortiUI_All")
		local function PaintAll(nr, ng, nb, na)
			SaveKey("LortiUI_AllR", nr); SaveKey("LortiUI_AllG", ng); SaveKey("LortiUI_AllB", nb); SaveKey("LortiUI_AllA", na)
			allSw.tex:SetVertexColor(nr, ng, nb, na)
			for _, z in ipairs(ZONE_ORDER) do
				if C[ZONES[z].on] ~= false then
					local p = "LortiUI_" .. ZONES[z].color
					SaveKey(p .. "Color", true)
					SaveKey(p .. "R", nr); SaveKey(p .. "G", ng); SaveKey(p .. "B", nb); SaveKey(p .. "A", na)
				end
			end
			Apply()
			RefreshAll()
		end
		OpenPicker(r0, g0, b0, a0, PaintAll, function()
			for z, s in pairs(snap) do
				local p = "LortiUI_" .. ZONES[z].color
				SaveKey(p .. "Color", s[1])
				SaveKey(p .. "R", s[2]); SaveKey(p .. "G", s[3]); SaveKey(p .. "B", s[4]); SaveKey(p .. "A", s[5])
			end
			SaveKey("LortiUI_AllR", r0); SaveKey("LortiUI_AllG", g0); SaveKey("LortiUI_AllB", b0); SaveKey("LortiUI_AllA", a0)
			Apply()
			RefreshAll()
		end)
	end)
	yR = yR - 26

	local defBtn = CreateFrame("Button", nil, wrapper, "UIPanelButtonTemplate")
	defBtn:SetSize(150, 20)
	defBtn:SetPoint("TOPLEFT", wrapper, "TOPLEFT", X2, yR)
	defBtn:SetText(L["LORTI_DEFAULT_COLORS"] or "Default colors")
	defBtn:SetScript("OnEnter", function(self)
		Tip(self, L["LORTI_DEFAULT_COLORS"] or "Default colors",
			L["LORTI_DEFAULT_COLORS_TIP"] or "Every row back to the black of Lorti UI: unticks 'Color' and resets the colors to the default light blue.")
	end)
	defBtn:SetScript("OnLeave", HideTip)
	defBtn:SetScript("OnClick", function()
		for _, z in ipairs(ZONE_ORDER) do
			local p = "LortiUI_" .. ZONES[z].color
			SaveKey(p .. "Color", false)
			SaveKey(p .. "R", DEFAULT_COLOR[1]); SaveKey(p .. "G", DEFAULT_COLOR[2]); SaveKey(p .. "B", DEFAULT_COLOR[3])
			SaveKey(p .. "A", 1)
		end
		Apply()
		RefreshAll()
	end)
	yR = yR - 28

	Text("* " .. (L["LORTI_RELOAD_NOTE"] or "needs /reload"), "TOPLEFT", X2, yR)
	yR = yR - 14

	RefreshAll = function()
		for _, r in ipairs(rows) do r.Refresh() end
		allSw.tex:SetVertexColor(ColorOf("LortiUI_All"))
	end
	RefreshAll()

	wrapper:SetScript("OnShow", RefreshAll)

	local leftBottom = FIRST - #LEFT_ZONES * ROW_H
	local subUIHeight = math.abs(math.min(leftBottom, yR)) + 8
	wrapper:SetHeight(subUIHeight)

	K.RefreshLortiSubOptions = RefreshAll

	local function SetSubsVisible(show)
		if show then wrapper:Show() else wrapper:Hide() end

		local ct = K._moduleContainers and K._moduleContainers["LortiUI"]
		if ct then
			if show then
				ct:SetHeight(ct._baseHeight + subUIHeight)
			else
				ct:SetHeight(ct._baseHeight)
			end
			if K.UpdateModulesScrollHeight then K.UpdateModulesScrollHeight() end
		end
	end

	if parentCheckbox then
		local origClick = parentCheckbox:GetScript("OnClick")
		parentCheckbox:SetScript("OnClick", function(self)
			if origClick then origClick(self) end
			local enabled = self:GetChecked() == 1 or self:GetChecked() == true
			SetSubsVisible(enabled)
		end)
	end

	if K.IsModuleEnabled("LortiUI") then
		wrapper:Show()
	else
		wrapper:Hide()
	end

	return subUIHeight
end

K.RegisterModule("LortiUI", {
	name     = "Lorti UI",
	desc     = L["MOD_LORTI_DESC"] or "Lorti UI look: dark (or your color) frames, action buttons, minimap and your buffs. Turning the module on or off needs /reload.",
	default  = false,
	onEnable = Init,
	createUI = CreateLortiSubUI,
})

local function CreateTextureColorUI(container, yOffset, parentCheckbox)
	local C = ns[2]
	local wrapper = CreateFrame("Frame", nil, container)
	wrapper:SetPoint("TOPLEFT", 0, yOffset)
	wrapper:SetWidth(container:GetWidth() or 540)

	local lbl = wrapper:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lbl:SetPoint("TOPLEFT", 46, -6)
	lbl:SetText(L["TEXCOLOR_COLOR"] or "Color and transparency")

	local sw = CreateFrame("Button", nil, wrapper)
	sw:SetSize(18, 18)
	sw:SetPoint("LEFT", lbl, "RIGHT", 10, 0)
	local bd = sw:CreateTexture(nil, "BACKGROUND")
	bd:SetPoint("TOPLEFT", -1, 1)
	bd:SetPoint("BOTTOMRIGHT", 1, -1)
	bd:SetTexture(0.6, 0.6, 0.6, 1)
	local tx = sw:CreateTexture(nil, "ARTWORK")
	tx:SetAllPoints()
	tx:SetTexture(1, 1, 1, 1)

	local function Cur()
		return Clamp01(C.TextureColorR, TC_DEFAULT[1]), Clamp01(C.TextureColorG, TC_DEFAULT[2]),
		       Clamp01(C.TextureColorB, TC_DEFAULT[3]), Clamp01(C.TextureColorA, TC_DEFAULT[4])
	end
	local function Save(r, g, b, a)
		local save = K.SaveConfigSilent or K.SaveConfig
		save("TextureColorR", r); save("TextureColorG", g)
		save("TextureColorB", b); save("TextureColorA", a or 1)
		tx:SetVertexColor(r, g, b, a or 1)
		if K.ApplyLortiColor then K.ApplyLortiColor() end
	end
	tx:SetVertexColor(Cur())

	sw:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	sw:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			Save(TC_DEFAULT[1], TC_DEFAULT[2], TC_DEFAULT[3], TC_DEFAULT[4])
			return
		end
		local r, g, b, a = Cur()
		K.OpenColorPickerAlpha(r, g, b, a, Save, function() Save(r, g, b, a) end)
	end)
	sw:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["TEXCOLOR_COLOR"] or "Color and transparency", 1, 1, 1)
		GameTooltip:AddLine(L["LORTI_SWATCH_TIP"] or "Click: choose the color (applies instantly).\nRight-click: back to the default color.", nil, nil, nil, true)
		GameTooltip:Show()
	end)
	sw:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local note = wrapper:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	note:SetPoint("TOPLEFT", 46, -28)
	note:SetWidth(440)
	note:SetJustifyH("LEFT")
	note:SetText(L["TEXCOLOR_NOTE"] or "Rows ticked in Lorti UI keep the Lorti color; this color goes everywhere else.")

	local h = 46
	wrapper:SetHeight(h)

	local function SetSubsVisible(show)
		if show then wrapper:Show() else wrapper:Hide() end
		local ct = K._moduleContainers and K._moduleContainers["TextureColor"]
		if ct then
			ct:SetHeight(ct._baseHeight + (show and h or 0))
			if K.UpdateModulesScrollHeight then K.UpdateModulesScrollHeight() end
		end
	end
	if parentCheckbox then
		local origClick = parentCheckbox:GetScript("OnClick")
		parentCheckbox:SetScript("OnClick", function(self)
			if origClick then origClick(self) end
			SetSubsVisible(self:GetChecked() == 1 or self:GetChecked() == true)
		end)
	end
	if K.TextureColorOn() then wrapper:Show() else wrapper:Hide() end
	return h
end

K.RegisterModule("TextureColor", {
	name     = L["MOD_TEXCOLOR"] or "Texture color",
	desc     = L["MOD_TEXCOLOR_DESC"] or "Paints the art of the frames, bars and minimap with one color and transparency (the FriskesUI option). Works with or without Lorti UI.",
	default  = false,
	onEnable = StartPainter,

	onDisable = function() if painterReady then ApplyAll() end end,
	createUI = CreateTextureColorUI,
})
