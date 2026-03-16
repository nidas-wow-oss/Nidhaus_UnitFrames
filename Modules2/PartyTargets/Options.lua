----------------------------------------------------
-- PartyTargets - Options Panel
-- /ptarget to open
-- All checkboxes apply in real-time
----------------------------------------------------

local function CreateOptionsPanel()
	local f = CreateFrame("Frame", "PartyTargetsOptions", UIParent)
	f:SetWidth(240)
	f:SetHeight(240)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
	f:SetFrameStrata("DIALOG")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:Hide()

	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 24,
		insets = { left = 6, right = 6, top = 6, bottom = 6 },
	})
	f:SetBackdropColor(0, 0, 0, 0.85)

	-- Title
	local title = f:CreateTexture(nil, "ARTWORK")
	title:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	title:SetWidth(200)
	title:SetHeight(44)
	title:SetPoint("TOP", 0, 10)

	local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titleText:SetPoint("TOP", 0, 2)
	titleText:SetText("Party Targets")

	local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", -4, -4)

	-- Helper to check a CheckButton state (3.3.5 compat)
	local function IsChecked(cb)
		local v = cb:GetChecked()
		return v == 1 or v == true
	end

	-- ========================
	-- Mirror Checkbox (real-time)
	-- ========================
	local mirrorCB = CreateFrame("CheckButton", "PTOptionsMirror", f, "UICheckButtonTemplate")
	mirrorCB:SetPoint("TOPLEFT", 16, -34)
	mirrorCB:SetWidth(24)
	mirrorCB:SetHeight(24)
	_G[mirrorCB:GetName().."Text"]:SetText("Mirror Party Frames")
	_G[mirrorCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	mirrorCB:SetScript("OnClick", function(self)
		PartyTargetsDB.mirror = IsChecked(self)
		if PartyTargets_ApplyMirrorSetting then
			PartyTargets_ApplyMirrorSetting()
		end
	end)

	-- ========================
	-- Anchor Checkbox (real-time)
	-- ========================
	local anchorCB = CreateFrame("CheckButton", "PTOptionsAnchor", f, "UICheckButtonTemplate")
	anchorCB:SetPoint("TOPLEFT", 16, -58)
	anchorCB:SetWidth(24)
	anchorCB:SetHeight(24)
	_G[anchorCB:GetName().."Text"]:SetText("Anchor to Party Frames")
	_G[anchorCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	anchorCB:SetScript("OnClick", function(self)
		PartyTargetsDB.anchor = IsChecked(self)
		if PartyTargets_ApplyAnchorSetting then
			PartyTargets_ApplyAnchorSetting()
		end
	end)

	local anchorHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	anchorHint:SetPoint("TOPLEFT", 42, -75)
	anchorHint:SetText("ON: drag one moves all | OFF: move each")

	-- ========================
	-- Lock Checkbox (real-time)
	-- ========================
	local lockCB = CreateFrame("CheckButton", "PTOptionsLock", f, "UICheckButtonTemplate")
	lockCB:SetPoint("TOPLEFT", 16, -90)
	lockCB:SetWidth(24)
	lockCB:SetHeight(24)
	_G[lockCB:GetName().."Text"]:SetText("Lock Frames")
	_G[lockCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	lockCB:SetScript("OnClick", function(self)
		PartyTargetsDB.locked = IsChecked(self)
	end)

	local lockHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	lockHint:SetPoint("TOPLEFT", 42, -107)
	lockHint:SetText("Shift+Alt+drag always overrides lock")

	-- ========================
	-- Scale Slider (live preview)
	-- ========================
	local sliderLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sliderLabel:SetPoint("TOPLEFT", 18, -130)
	sliderLabel:SetText("Scale:")

	local slider = CreateFrame("Slider", "PTOptionsScale", f, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", 54, -128)
	slider:SetWidth(140)
	slider:SetHeight(16)
	slider:SetMinMaxValues(0.5, 2.0)
	slider:SetValueStep(0.05)
	_G[slider:GetName().."Low"]:SetText("0.5")
	_G[slider:GetName().."High"]:SetText("2.0")
	_G[slider:GetName().."Text"]:SetText("")

	local scaleValue = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	scaleValue:SetPoint("LEFT", slider, "RIGHT", 8, 0)
	scaleValue:SetText("1.00")

	slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value * 20 + 0.5) / 20
		scaleValue:SetText(string.format("%.2f", value))
		-- Live preview
		PartyTargetsDB.scale = value
		for i = 1, MAX_PARTY_MEMBERS do
			local frame = _G["PartyTargetFrame"..i]
			if frame then frame:SetScale(value) end
		end
	end)

	-- ========================
	-- Save Button
	-- ========================
	local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	saveBtn:SetWidth(90)
	saveBtn:SetHeight(22)
	saveBtn:SetPoint("BOTTOMLEFT", 16, 14)
	saveBtn:SetText("Save")
	saveBtn:SetScript("OnClick", function()
		-- Values already saved in real-time, just confirm and close
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00PartyTargets:|r Settings saved!")
		f:Hide()
	end)

	-- ========================
	-- Reset Button
	-- ========================
	local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	resetBtn:SetWidth(90)
	resetBtn:SetHeight(22)
	resetBtn:SetPoint("BOTTOMRIGHT", -16, 14)
	resetBtn:SetText("Reset")
	resetBtn:SetScript("OnClick", function()
		StaticPopup_Show("PARTYTARGETS_RESET_CONFIRM")
	end)

	StaticPopupDialogs["PARTYTARGETS_RESET_CONFIRM"] = {
		text = "Reset all PartyTargets settings to defaults?",
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

	-- ========================
	-- OnShow: enable config drag, load values
	-- ========================
	f:SetScript("OnShow", function(self)
		PartyTargets_configOpen = true

		mirrorCB:SetChecked(PartyTargetsDB.mirror and true or false)
		anchorCB:SetChecked(PartyTargetsDB.anchor and true or false)
		lockCB:SetChecked(PartyTargetsDB.locked and true or false)
		slider:SetValue(PartyTargetsDB.scale or 1.0)
		scaleValue:SetText(string.format("%.2f", PartyTargetsDB.scale or 1.0))

		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00PartyTargets:|r Config open - drag target frames to reposition.")
	end)

	-- ========================
	-- OnHide: disable config drag
	-- ========================
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