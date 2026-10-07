local AddOnName, ns = ...;
local K = ns[1];
local L = ns[3];







local function CreateOptionsPanel()
	local f = CreateFrame("Frame", "PartyTargetsOptions", UIParent)

	if K and K.UI and K.UI.AutoRestyle then K.UI.AutoRestyle(f); end


	f:SetWidth(300)
	f:SetHeight(362)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 100)








	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetToplevel(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:Hide()












	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = false, edgeSize = 24,
		insets = { left = 6, right = 6, top = 6, bottom = 6 },
	})
	f:SetBackdropColor(0.05, 0.06, 0.09, 1)


	local title = f:CreateTexture(nil, "ARTWORK")
	title:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	title:SetWidth(200)
	title:SetHeight(44)
	title:SetPoint("TOP", 0, 10)

	local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titleText:SetPoint("TOP", 0, 2)
	titleText:SetText(L["PT_TITLE"] or "Party Targets")

	local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", -4, -4)


	local function IsChecked(cb)
		local v = cb:GetChecked()
		return v == 1 or v == true
	end







	local styleLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	styleLbl:SetPoint("TOPLEFT", 18, -40)
	styleLbl:SetText(L["PT_STYLE"] or "Frame style:")

	local styleDD = CreateFrame("Frame", "PTOptionsStyleDD", f, "UIDropDownMenuTemplate")
	styleDD:SetPoint("TOPLEFT", styleLbl, "TOPRIGHT", -8, 6)
	UIDropDownMenu_SetWidth(styleDD, 120)

	local STYLES = {
		{ value = "Classic", text = L["PT_STYLE_CLASSIC"] or "Classic (wide)" },
		{ value = "Square",  text = L["PT_STYLE_SQUARE"]  or "Square (compact)" },
	}

	local function StyleText(v)
		for _, o in ipairs(STYLES) do
			if o.value == v then return o.text end
		end
		return STYLES[1].text
	end

	UIDropDownMenu_Initialize(styleDD, function()
		for _, o in ipairs(STYLES) do
			local info = UIDropDownMenu_CreateInfo()
			info.text  = o.text
			info.value = o.value
			info.func  = function(btn)
				UIDropDownMenu_SetSelectedValue(styleDD, btn.value)
				UIDropDownMenu_SetText(styleDD, StyleText(btn.value))
				if K and K.SetPartyTargetStyle then K.SetPartyTargetStyle(btn.value) end
			end
			info.checked = (o.value == (K and K.GetPartyTargetStyle and K.GetPartyTargetStyle() or "Classic"))
			UIDropDownMenu_AddButton(info)
		end
	end)

	do
		local cur = (K and K.GetPartyTargetStyle and K.GetPartyTargetStyle()) or "Classic"
		UIDropDownMenu_SetSelectedValue(styleDD, cur)
		UIDropDownMenu_SetText(styleDD, StyleText(cur))
	end




	local mirrorCB = CreateFrame("CheckButton", "PTOptionsMirror", f, "UICheckButtonTemplate")
	mirrorCB:SetPoint("TOPLEFT", 16, -74)
	mirrorCB:SetWidth(24)
	mirrorCB:SetHeight(24)
	_G[mirrorCB:GetName().."Text"]:SetText(L["PT_MIRROR"] or "Mirror Party Frames")
	_G[mirrorCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	mirrorCB:SetScript("OnClick", function(self)
		PartyTargetsDB.mirror = IsChecked(self)
		if PartyTargets_ApplyMirrorSetting then
			PartyTargets_ApplyMirrorSetting()
		end
	end)




	local anchorCB = CreateFrame("CheckButton", "PTOptionsAnchor", f, "UICheckButtonTemplate")
	anchorCB:SetPoint("TOPLEFT", 16, -102)
	anchorCB:SetWidth(24)
	anchorCB:SetHeight(24)
	_G[anchorCB:GetName().."Text"]:SetText(L["PT_ANCHOR"] or "Anchor to Party Frames")
	_G[anchorCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	anchorCB:SetScript("OnClick", function(self)
		PartyTargetsDB.anchor = IsChecked(self)
		if PartyTargets_ApplyAnchorSetting then
			PartyTargets_ApplyAnchorSetting()
		end
	end)

	local anchorHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	anchorHint:SetPoint("TOPLEFT", 44, -122)
	anchorHint:SetText(L["PT_ANCHOR_HINT"] or "ON: drag one moves all | OFF: move each")




	local lockCB = CreateFrame("CheckButton", "PTOptionsLock", f, "UICheckButtonTemplate")
	lockCB:SetPoint("TOPLEFT", 16, -142)
	lockCB:SetWidth(24)
	lockCB:SetHeight(24)
	_G[lockCB:GetName().."Text"]:SetText(L["PT_LOCK"] or "Lock Frames")
	_G[lockCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	lockCB:SetScript("OnClick", function(self)
		PartyTargetsDB.locked = IsChecked(self)
	end)

	local lockHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	lockHint:SetPoint("TOPLEFT", 44, -162)
	lockHint:SetText(L["PT_LOCK_HINT"] or "Shift+Alt+drag always overrides lock")




	local nameCB = CreateFrame("CheckButton", "PTOptionsHideName", f, "UICheckButtonTemplate")
	nameCB:SetPoint("TOPLEFT", 16, -182)
	nameCB:SetWidth(24)
	nameCB:SetHeight(24)
	_G[nameCB:GetName().."Text"]:SetText(L["PT_HIDE_NAME"] or "Hide target name")
	_G[nameCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	nameCB:SetChecked(PartyTargetsDB.hideName and true or false)
	nameCB:SetScript("OnClick", function(self)
		PartyTargetsDB.hideName = IsChecked(self)
		if PartyTargets_ApplyNameVisibility then
			PartyTargets_ApplyNameVisibility()
		end
	end)




	local classCB = CreateFrame("CheckButton", "PTOptionsClassIcon", f, "UICheckButtonTemplate")
	classCB:SetPoint("TOPLEFT", 16, -208)
	classCB:SetWidth(24)
	classCB:SetHeight(24)
	_G[classCB:GetName().."Text"]:SetText(L["PT_CLASS_ICON"] or "Class icon in portrait")
	_G[classCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	classCB:SetChecked(K and K.GetPartyTargetClassIcon and K.GetPartyTargetClassIcon() or false)
	classCB:SetScript("OnClick", function(self)
		if K and K.SetPartyTargetClassIcon then K.SetPartyTargetClassIcon(IsChecked(self)) end
	end)
	classCB:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["PT_CLASS_ICON"] or "Class icon in portrait", 1, 1, 1)
		GameTooltip:AddLine(L["PT_CLASS_ICON_TIP"]
			or "Shows the class icon instead of the face (players only; NPCs keep their face).", nil, nil, nil, true)
		GameTooltip:Show()
	end)
	classCB:SetScript("OnLeave", function() GameTooltip:Hide() end)




	local sliderLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sliderLabel:SetPoint("TOPLEFT", 18, -242)
	sliderLabel:SetText((K and K.UI and K.UI.Label(L["PT_SCALE"] or "Scale:"))
		or (L["PT_SCALE"] or "Scale:"))

	local slider = CreateFrame("Slider", "PTOptionsScale", f, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", 22, -262)
	slider:SetWidth(250)
	slider:SetHeight(16)
	slider:SetMinMaxValues(0.5, 2.0)
	slider:SetValueStep(0.05)
	_G[slider:GetName().."Low"]:SetText("0.5")
	_G[slider:GetName().."High"]:SetText("2.0")
	_G[slider:GetName().."Text"]:SetText("")

	slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value * 20 + 0.5) / 20

		if K and K.SavePartyTargetScale then K.SavePartyTargetScale(value) end
		for i = 1, MAX_PARTY_MEMBERS do
			local frame = _G["PartyTargetFrame"..i]
			if frame then frame:SetScale(value) end
		end
	end)



	function K.RefreshPartyTargetScaleSlider()
		if not f:IsShown() then return end
		slider:SetValue((K.GetPartyTargetScale and K.GetPartyTargetScale()) or 1.0)
	end














	if K and K.UI and K.UI.AttachSliderValue then
		K.UI.AttachSliderValue(slider);
	end




	local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	saveBtn:SetWidth(110)
	saveBtn:SetHeight(22)
	saveBtn:SetPoint("BOTTOMLEFT", 22, 16)
	saveBtn:SetText(L["BTN_SAVE"] or "Save")
	saveBtn:SetScript("OnClick", function()

		f:Hide()
	end)




	local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	resetBtn:SetWidth(110)
	resetBtn:SetHeight(22)
	resetBtn:SetPoint("BOTTOMRIGHT", -22, 16)
	resetBtn:SetText(L["BTN_RESET_SHORT"] or "Reset")
	resetBtn:SetScript("OnClick", function()
		StaticPopup_Show("PARTYTARGETS_RESET_CONFIRM")
	end)

	StaticPopupDialogs["PARTYTARGETS_RESET_CONFIRM"] = {
		text = L["PT_RESET_CONFIRM"] or "Reset all PartyTargets settings to defaults?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			PartyTargetsDB = {}
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}




	f:SetScript("OnShow", function(self)
		PartyTargets_configOpen = true

		mirrorCB:SetChecked(PartyTargetsDB.mirror and true or false)
		anchorCB:SetChecked(PartyTargetsDB.anchor and true or false)
		lockCB:SetChecked(PartyTargetsDB.locked and true or false)
		classCB:SetChecked(K and K.GetPartyTargetClassIcon and K.GetPartyTargetClassIcon() or false)
		slider:SetValue((K and K.GetPartyTargetScale and K.GetPartyTargetScale()) or 1.0)



		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00PartyTargets:|r " .. (L["PT_CONFIG_OPEN"] or "Config open - drag target frames to reposition."))
	end)




	f:SetScript("OnHide", function(self)
		PartyTargets_configOpen = false
	end)

	tinsert(UISpecialFrames, "PartyTargetsOptions")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event)
	CreateOptionsPanel()
	self:UnregisterAllEvents()
end)