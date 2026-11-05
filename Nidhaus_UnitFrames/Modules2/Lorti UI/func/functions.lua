local addon, ns = ...
local K = ns[1]
local cfg = ns.cfg
local _G = _G

local nomoreplay = function() end

local classcolor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]

local lortiEnabled = false;

local function NormalColor()
	return cfg.color.normal.r, cfg.color.normal.g, cfg.color.normal.b;
end

local function ShadowColor()
	local C = ns[2];
	local sc = cfg.background.shadowcolor;
	if K.LortiZoneColor then
		local r, g, b, a = K.LortiZoneColor("ActionBars");
		if r then return r, g, b, (a or 1) * (sc.a or 0.9); end
	end
	return sc.r, sc.g, sc.b, sc.a;
end

local shadowButtons = {};

local RANGE_RED = { 1, 0.1, 0.1, 1 };
local rangeRed = {};

local styledButtons = {};

local inHook = false;

local function UpdateLortiCache()
	lortiEnabled = K.IsModuleEnabled and K.IsModuleEnabled("LortiUI") or false;
end

if K.RegisterConfigEvent then
	K.RegisterConfigEvent("CONFIG_LOADED", UpdateLortiCache);
	K.RegisterConfigEvent("CONFIG_CHANGED", UpdateLortiCache);
end

local lortiCacheFrame = CreateFrame("Frame");
lortiCacheFrame:RegisterEvent("PLAYER_LOGIN");
lortiCacheFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");
	UpdateLortiCache();
end);

if cfg.color.classcolored then
	cfg.color.normal = classcolor
end

local bgfile, edgefile = "", ""
if cfg.background.showshadow then edgefile = cfg.textures.outer_shadow end
if cfg.background.useflatbackground and cfg.background.showbg then bgfile = cfg.textures.buttonbackflat end

local backdrop = {
	bgFile = bgfile,
	edgeFile = edgefile,
	tile = false,
	tileSize = 32,
	edgeSize = cfg.background.inset,
	insets = {
		left = cfg.background.inset,
		right = cfg.background.inset,
		top = cfg.background.inset,
		bottom = cfg.background.inset,
	},
}

local function applyBackground(bu)
	if cfg.background.showbg or cfg.background.showshadow then
		bu.bg = CreateFrame("Frame", nil, bu)
		bu.bg:SetAllPoints(bu)
		bu.bg:SetPoint("TOPLEFT", bu, "TOPLEFT", -4, 4)
		bu.bg:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", 4, -4)
		bu.bg:SetFrameLevel(bu:GetFrameLevel() - 1)

		if cfg.background.classcolored then
			cfg.background.backgroundcolor = classcolor
			cfg.background.shadowcolor = classcolor
		end

		if cfg.background.showbg and not cfg.background.useflatbackground then
			local t = bu.bg:CreateTexture(nil, "BACKGROUND", -8)
			t:SetTexture(cfg.textures.buttonback)
			t:SetAllPoints(bu)
			t:SetVertexColor(cfg.background.backgroundcolor.r, cfg.background.backgroundcolor.g, cfg.background.backgroundcolor.b, cfg.background.backgroundcolor.a)
		end

		bu.bg:SetBackdrop(backdrop)
		if cfg.background.useflatbackground then
			bu.bg:SetBackdropColor(cfg.background.backgroundcolor.r, cfg.background.backgroundcolor.g, cfg.background.backgroundcolor.b, cfg.background.backgroundcolor.a)
		end
		if cfg.background.showshadow then
			bu.bg:SetBackdropBorderColor(ShadowColor())
			shadowButtons[bu] = true
		end
	end
end

local function ntSetVertexColorFunc(nt, r, g, b, a)
	if inHook or not nt then return end
	inHook = true
	local self = nt:GetParent()
	local action = self.action
	if r == 1 and g == 1 and b == 1 and action and IsEquippedAction(action) then
		nt:SetVertexColor(cfg.color.equipped.r, cfg.color.equipped.g, cfg.color.equipped.b, 1)
	elseif r == 0.5 and g == 0.5 and b == 1 then
		local nr, ng, nb = NormalColor()
		nt:SetVertexColor(nr, ng, nb, 1)
	elseif r == 1 and g == 1 and b == 1 then
		local nr, ng, nb = NormalColor()
		nt:SetVertexColor(nr, ng, nb, 1)
	end
	inHook = false
end

local function rActionButtonStyler_AB_style(self)
	if not lortiEnabled then return end

	if not self.rABS_Styled and self:GetParent() and self:GetParent():GetName() ~= "MultiCastActionBarFrame" and self:GetParent():GetName() ~= "MultiCastActionPage1" and self:GetParent():GetName() ~= "MultiCastActionPage2" and self:GetParent():GetName() ~= "MultiCastActionPage3" then

		local action = self.action
		local name = self:GetName()
		local bu  = _G[name]
		local ic  = _G[name.."Icon"]
		local co  = _G[name.."Count"]
		local bo  = _G[name.."Border"]
		local ho  = _G[name.."HotKey"]
		local cd  = _G[name.."Cooldown"]
		local na  = _G[name.."Name"]
		local fl  = _G[name.."Flash"]
		local nt  = _G[name.."NormalTexture"]

		bo:Hide()
		bo.Show = nomoreplay

		local fam = NidhausFrameBorders_ButtonFont
			and NidhausFrameBorders_ButtonFont() or nil;

		if cfg.hotkeys.show then
			ho:SetFont(fam or cfg.font, cfg.hotkeys.fontsize, "OUTLINE")
			ho:ClearAllPoints()
			ho:SetPoint(cfg.hotkeys.pos1.a1, bu, cfg.hotkeys.pos1.x, cfg.hotkeys.pos1.y)
			ho:SetPoint(cfg.hotkeys.pos2.a1, bu, cfg.hotkeys.pos2.x, cfg.hotkeys.pos2.y)
		else
			ho:Hide()
			ho.Show = nomoreplay
		end

		if cfg.macroname.show then
			na:SetFont(fam or cfg.font, cfg.macroname.fontsize, "OUTLINE")
			na:ClearAllPoints()
			na:SetPoint(cfg.macroname.pos1.a1, bu, cfg.macroname.pos1.x, cfg.macroname.pos1.y)
			na:SetPoint(cfg.macroname.pos2.a1, bu, cfg.macroname.pos2.x, cfg.macroname.pos2.y)
		else
			na:Hide()
		end

		if cfg.itemcount.show then
			co:SetFont(fam or cfg.font, cfg.itemcount.fontsize, "OUTLINE")
			co:ClearAllPoints()
			co:SetPoint(cfg.itemcount.pos1.a1, bu, cfg.itemcount.pos1.x, cfg.itemcount.pos1.y)
		else
			co:Hide()
		end

		fl:SetTexture(cfg.textures.flash)
		bu:SetHighlightTexture(cfg.textures.hover)
		bu:SetPushedTexture(cfg.textures.pushed)
		bu:SetCheckedTexture(cfg.textures.checked)
		bu:SetNormalTexture(cfg.textures.normal)

		ic:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		ic:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
		ic:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)

		cd:SetPoint("TOPLEFT", bu, "TOPLEFT", cfg.cooldown.spacing, -cfg.cooldown.spacing)
		cd:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -cfg.cooldown.spacing, cfg.cooldown.spacing)

		if IsEquippedAction(action) then
			bu:SetNormalTexture(cfg.textures.equipped)
			nt:SetVertexColor(cfg.color.equipped.r, cfg.color.equipped.g, cfg.color.equipped.b, 1)
		else
			bu:SetNormalTexture(cfg.textures.normal)
			local nr, ng, nb = NormalColor()
			nt:SetVertexColor(nr, ng, nb, 1)
		end

		nt:SetAllPoints(bu)

		fl.SetTexture = nomoreplay
		bu.SetHighlightTexture = nomoreplay
		bu.SetPushedTexture = nomoreplay
		bu.SetCheckedTexture = nomoreplay
		bu.SetNormalTexture = nomoreplay

		hooksecurefunc(nt, "SetVertexColor", ntSetVertexColorFunc)

		if not bu.bg then applyBackground(bu) end

		styledButtons[bu] = true
		self.rABS_Styled = true
	end
end

local function rActionButtonStyler_AB_stylepet()
	if not lortiEnabled then return end

	for i = 1, NUM_PET_ACTION_SLOTS do
		local name = "PetActionButton"..i
		local bu  = _G[name]
		local ic  = _G[name.."Icon"]
		local fl  = _G[name.."Flash"]

		if not bu.rABS_Styled then
			fl:SetTexture(cfg.textures.flash)
			bu:SetHighlightTexture(cfg.textures.hover)
			bu:SetPushedTexture(cfg.textures.pushed)
			bu:SetCheckedTexture(cfg.textures.checked)

			ic:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			ic:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
			ic:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)

			if not bu.bg then applyBackground(bu) end

			bu.rABS_Styled = true
		end

		local nt2 = _G[name.."NormalTexture2"]
		if nt2 then
			nt2:SetTexture(cfg.textures.normal)
			nt2:SetAllPoints(bu)
			local nr, ng, nb = NormalColor()
			nt2:SetVertexColor(nr, ng, nb, 1)
		end
	end
end

local function rActionButtonStyler_AB_styleshapeshift()
	if not lortiEnabled then return end

	for i = 1, NUM_SHAPESHIFT_SLOTS do
		local name = "ShapeshiftButton"..i
		local bu  = _G[name]
		local ic  = _G[name.."Icon"]
		local fl  = _G[name.."Flash"]

		if not bu.rABS_Styled then
			fl:SetTexture(cfg.textures.flash)
			bu:SetHighlightTexture(cfg.textures.hover)
			bu:SetPushedTexture(cfg.textures.pushed)
			bu:SetCheckedTexture(cfg.textures.checked)

			ic:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			ic:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
			ic:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)

			if not bu.bg then applyBackground(bu) end

			bu.rABS_Styled = true
		end

		local nt = _G[name.."NormalTexture"]
		if nt then
			nt:SetTexture(cfg.textures.normal)
			nt:SetAllPoints(bu)
			local nr, ng, nb = NormalColor()
			nt:SetVertexColor(nr, ng, nb, 1)
		end
	end
end

local function ColorNEBButtons()
	if not lortiEnabled then return end
	local sr, sg, sb, sa = ShadowColor()
	for _, side in ipairs({ "Left", "Right" }) do
		for i = 1, 12 do
			local bu = _G["NEB_Bar" .. side .. "Button" .. i]
			local bg = bu and bu._nebLortiBG
			if bg and bg.SetBackdropBorderColor then
				bg:SetBackdropBorderColor(sr, sg, sb, sa)
			end
		end
	end
end
K.LortiColorNEB = ColorNEBButtons

do
	local nebWait = CreateFrame("Frame")
	local t = 0
	nebWait:Hide()
	nebWait:SetScript("OnUpdate", function(self, dt)
		t = t + dt
		if t > 0 and not self.first then self.first = true; ColorNEBButtons() end
		if t >= 1 then self:Hide(); ColorNEBButtons() end
	end)
	nebWait:RegisterEvent("PLAYER_ENTERING_WORLD")
	nebWait:SetScript("OnEvent", function(self)
		t = 0; self.first = nil; self:Show()
	end)
end

function K.ApplyLortiButtonColor()
	if not lortiEnabled then return end
	local sr, sg, sb, sa = ShadowColor()
	for bu in pairs(shadowButtons) do

		if not rangeRed[bu] and bu.bg and bu.bg.SetBackdropBorderColor then
			bu.bg:SetBackdropBorderColor(sr, sg, sb, sa)
		end
	end
	local nr, ng, nb = NormalColor()
	for bu in pairs(styledButtons) do
		local name = bu:GetName()
		local nt = name and _G[name.."NormalTexture"]
		if nt and not (bu.action and IsEquippedAction(bu.action)) then
			inHook = true
			nt:SetVertexColor(nr, ng, nb, 1)
			inHook = false
		end
	end
	rActionButtonStyler_AB_styleshapeshift()
	rActionButtonStyler_AB_stylepet()
	ColorNEBButtons()
end

function K.LortiRangeBorder(bu, out)
	if not bu then return false end
	if out then
		local bg = bu.bg
		if not (lortiEnabled and bg and shadowButtons[bu]) then return false end
		if not rangeRed[bu] then
			rangeRed[bu] = true
			bg:SetBackdropBorderColor(RANGE_RED[1], RANGE_RED[2], RANGE_RED[3], RANGE_RED[4])
		end
		return true
	end
	if rangeRed[bu] then
		rangeRed[bu] = nil
		if bu.bg then bu.bg:SetBackdropBorderColor(ShadowColor()) end
	end
	return false
end

function K.LortiRangeBorderReset()
	for bu in pairs(rangeRed) do
		rangeRed[bu] = nil
		if bu.bg then bu.bg:SetBackdropBorderColor(ShadowColor()) end
	end
end

hooksecurefunc("ActionButton_Update",       rActionButtonStyler_AB_style)
hooksecurefunc("ShapeshiftBar_Update",      rActionButtonStyler_AB_styleshapeshift)
hooksecurefunc("ShapeshiftBar_UpdateState", rActionButtonStyler_AB_styleshapeshift)
hooksecurefunc("PetActionBar_Update",       rActionButtonStyler_AB_stylepet)
