local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local mainFrame;
local currentTab  = 1;
local tabs        = {};
local tabPanels   = {};
local checkboxes  = {};
local sliders     = {};
local checkboxCount = 0;
local sliderCount   = 0;
local showArenaBtn;
local partyMode3v3Checkbox;
local lockPosCheckbox;
local dragHintText;
local partyIndivCheckbox;

-- ── Theme-aware module-level frame refs ──────────────────
local titleBoxRef;   -- saved from CreateMainFrame for ThemeManager
local tabBarRef;     -- saved from CreateTabs for ThemeManager

local tooltips = {
	-- Tab 1 (General)
	classColor          = "TIP_classColor",
	statusbarBackdrop   = "TIP_statusbarBackdrop",
	HealthPercentage    = "TIP_HealthPercentage",
	SetPositions        = "TIP_SetPositions",
	LockPositions       = "TIP_LockPositions",
	PartyIndividualMove = "TIP_PartyIndividualMove",
	PartyMode3v3        = "TIP_PartyMode3v3",
	UnifyActionBars     = "TIP_UnifyActionBars",
};

-- ── Backdrop helper ───────────────────────────────────────
local function ApplyBackdrop(frame, inset)
	inset = inset or 4;
	frame:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile     = true,
		tileSize = 16,
		edgeSize = 16,
		insets   = {left=inset, right=inset, top=inset, bottom=inset},
	});
	frame:SetBackdropColor(0, 0, 0, 0.35);
	frame:SetBackdropBorderColor(0, 0, 0, 0.85);
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateMainFrame
-- ────────────────────────────────────────────────────────────────────────────
local function CreateMainFrame()
	mainFrame = CreateFrame("Frame", "NidhausUnitFramesConfigFrame", UIParent);
	mainFrame:SetSize(700, 580);
	mainFrame:SetPoint("CENTER");
	mainFrame:SetFrameStrata("DIALOG");
	mainFrame:EnableMouse(true);
	mainFrame:SetMovable(true);
	mainFrame:RegisterForDrag("LeftButton");
	mainFrame:SetScript("OnDragStart", mainFrame.StartMoving);
	mainFrame:SetScript("OnDragStop",  mainFrame.StopMovingOrSizing);
	mainFrame:SetClampedToScreen(true);
	mainFrame:Hide();

	mainFrame:SetScript("OnShow", function()
		if K._UpdateBagPackVisibility then K._UpdateBagPackVisibility(); end
	end);

	-- Default backdrop (will be overridden by ThemeManager on first show)
	mainFrame:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile     = true, tileSize = 32, edgeSize = 32,
		insets   = {left=11, right=12, top=12, bottom=11},
	});

	-- ── Title Box (DarkGold y ArcaneBlue usan su backdrop; Classic lo hace transparente) ──
	local titleBox = CreateFrame("Frame", nil, mainFrame);
	titleBox:SetSize(500, 32);
	titleBox:SetPoint("TOP", mainFrame, "TOP", 0, 6);
	titleBox:SetFrameLevel(mainFrame:GetFrameLevel() + 5);
	titleBox:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
		tile     = true, tileSize = 32, edgeSize = 16,
		insets   = {left=4, right=4, top=4, bottom=4},
	});
	titleBox:SetBackdropColor(0.10, 0.10, 0.10, 1.0);

	-- Título: hijo de titleBox para heredar su FrameLevel (siempre visible)
	local title = titleBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	title:SetPoint("CENTER", titleBox, "CENTER", 0, 1);
	title:SetText(L["PANEL_TITLE"]);

	-- ── Title Header Texture (Classic solamente) ──────────────
	-- Textura gris metalica nativa de Blizzard. Se muestra encima del titleBox
	-- cuando el tema es Classic (el backdrop de titleBox queda transparente).
	local titleHeaderTex = mainFrame:CreateTexture(nil, "ARTWORK");
	titleHeaderTex:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header");
	titleHeaderTex:SetWidth(500);
	titleHeaderTex:SetHeight(64);
	titleHeaderTex:SetPoint("TOP", mainFrame, "TOP", 0, 14);
	titleHeaderTex:Hide(); -- ThemeManager lo muestra solo en Classic

	-- Save references for ThemeManager
	titleBoxRef               = titleBox;
	mainFrame._titleHeaderTex = titleHeaderTex;

	-- Version label
	local version = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	version:SetPoint("TOPRIGHT", -40, -16);
	version:SetText(L["PANEL_VERSION"]);

	-- Subtitle
	local subtitle = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	subtitle:SetPoint("TOP", titleBox, "BOTTOM", 0, -4);
	subtitle:SetText("|cffAAAAAA" .. (L["PANEL_SUBTITLE"] or "") .. "|r");

	-- Close button
	local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton");
	closeButton:SetPoint("TOPRIGHT", -5, -5);
	closeButton:SetScript("OnClick", function() mainFrame:Hide(); end);

	-- Tab bar container
	local tabBar = CreateFrame("Frame", nil, mainFrame);
	tabBar:SetPoint("TOPLEFT",  18, -48);
	tabBar:SetPoint("TOPRIGHT", -18, -48);
	tabBar:SetHeight(32);
	ApplyBackdrop(tabBar, 4);
	tabBar:SetBackdropColor(0, 0, 0, 0.20);
	mainFrame.TabBar = tabBar;
	tabBarRef = tabBar;

	-- Bottom separator (sits above the two-row footer)
	local sepBottom = mainFrame:CreateTexture(nil, "ARTWORK");
	sepBottom:SetTexture(1, 1, 1, 0.08);
	sepBottom:SetPoint("BOTTOMLEFT",  mainFrame, "BOTTOMLEFT",  20, 78);
	sepBottom:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -20, 78);
	sepBottom:SetHeight(1);

	return mainFrame;
end

-- ────────────────────────────────────────────────────────────────────────────
-- SelectTab  (theme-aware)
-- ────────────────────────────────────────────────────────────────────────────
local function SelectTab(id)
	currentTab = id;

	for i, panel in ipairs(tabPanels) do
		if i == id then panel:Show() else panel:Hide() end
	end

	local theme = K.GetActiveTheme and K.GetActiveTheme();

	for i, tab in ipairs(tabs) do
		if i == id then
			tab.selected = true;
			if theme then
				tab:SetBackdropColor(unpack(theme.tabSelBGColor));
				tab:SetBackdropBorderColor(unpack(theme.tabSelBorderColor));
			else
				tab:SetBackdropColor(0.2, 0.2, 0.2, 0.9);
				tab:SetBackdropBorderColor(0.8, 0.7, 0.0, 0.9);
			end
			if tab.label then tab.label:SetFontObject("GameFontNormal"); end
		else
			tab.selected = false;
			if theme then
				tab:SetBackdropColor(unpack(theme.tabBGColor));
				tab:SetBackdropBorderColor(unpack(theme.tabBorderColor));
			else
				tab:SetBackdropColor(0.1, 0.1, 0.1, 0.6);
				tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8);
			end
			if tab.label then tab.label:SetFontObject("GameFontHighlightSmall"); end
		end
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateTabs
-- ────────────────────────────────────────────────────────────────────────────
local function CreateTabs()
	local tabNames = {
		L["TAB_GENERAL"], L["TAB_FRAMES"], L["TAB_ARENA"],
		L["TAB_MODULES"], L["TAB_EXTRA"],  L["TAB_ABOUT"],
	};
	mainFrame.numTabs    = #tabNames;
	mainFrame.selectedTab = 1;

	local tabBarWidth = mainFrame.TabBar:GetWidth() or (mainFrame:GetWidth() - 36);
	local numTabs     = #tabNames;
	local tabWidth    = tabBarWidth / numTabs;

	for i, name in ipairs(tabNames) do
		local tab = CreateFrame("Button", mainFrame:GetName().."Tab"..i, mainFrame.TabBar);
		tab:SetID(i);
		tab:SetSize(tabWidth, 28);

		if i == 1 then
			tab:SetPoint("BOTTOMLEFT", mainFrame.TabBar, "BOTTOMLEFT", 0, 2);
		else
			tab:SetPoint("LEFT", tabs[i-1], "RIGHT", 0, 0);
		end

		tab:SetBackdrop({
			bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile     = true, tileSize = 16, edgeSize = 12,
			insets   = {left=2, right=2, top=2, bottom=2},
		});

		local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		label:SetPoint("CENTER", 0, 0);
		label:SetText(name);
		tab.label = label;

		-- Hover scripts (theme-aware)
		tab:SetScript("OnEnter", function(self)
			if self.selected then return; end
			local theme = K.GetActiveTheme and K.GetActiveTheme();
			if theme then
				self:SetBackdropColor(unpack(theme.tabHoverBGColor));
			else
				self:SetBackdropColor(0.3, 0.3, 0.3, 0.8);
			end
		end);
		tab:SetScript("OnLeave", function(self)
			if self.selected then return; end
			local theme = K.GetActiveTheme and K.GetActiveTheme();
			if theme then
				self:SetBackdropColor(unpack(theme.tabBGColor));
				self:SetBackdropBorderColor(unpack(theme.tabBorderColor));
			else
				self:SetBackdropColor(0.1, 0.1, 0.1, 0.6);
				self:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8);
			end
		end);

		-- Default (unselected) colors
		tab:SetBackdropColor(0.1, 0.1, 0.1, 0.6);
		tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8);
		tab.selected = false;

		tab:SetScript("OnClick", function(self) SelectTab(self:GetID()); end);
		tabs[i] = tab;

		-- Content panel
		local panel = CreateFrame("Frame", "NidhausUFTabPanel"..i, mainFrame);
		panel:SetPoint("TOPLEFT",     22,  -82);
		panel:SetPoint("BOTTOMRIGHT", -22,  88);
		ApplyBackdrop(panel, 6);
		panel:SetBackdropColor(0, 0, 0, 0.18);
		panel:SetBackdropBorderColor(0, 0, 0, 0.70);
		panel:Hide();
		tabPanels[i] = panel;
	end

	SelectTab(1);
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateCheckBox
-- ────────────────────────────────────────────────────────────────────────────
local function CreateCheckBox(parent, labelText, setting, xOffset, yOffset)
	checkboxCount = checkboxCount + 1;
	local checkboxName = "NidhausUFCheckBox"..checkboxCount;
	local check = CreateFrame("CheckButton", checkboxName, parent, "InterfaceOptionsCheckButtonTemplate");
	check:SetPoint("TOPLEFT", xOffset or 20, yOffset);
	check:SetHitRectInsets(0, 0, 0, 0);

	local label = _G[checkboxName.."Text"];
	if label then
		label:SetText(labelText);
	else
		label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		label:SetPoint("LEFT", check, "RIGHT", 2, 0);
		label:SetText(labelText);
	end

	check.setting = setting;

	local tipKey = tooltips[setting];
	if tipKey and L[tipKey] then
		check:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(labelText, 1, 1, 1);
			GameTooltip:AddLine(L[tipKey], nil, nil, nil, true);
			GameTooltip:Show();
		end);
		check:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end

	check.refresh = function(self)
		local value = C[setting];
		if type(value) == "number" then value = (value == 1); end
		self:SetChecked(value == true);
	end;
	check:refresh();

	check:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked();
		local boolValue = (isChecked == 1 or isChecked == true);

		local success = K.SaveConfig(setting, boolValue);
		if not success then self:refresh(); return; end

		if setting == "UnifyActionBars" then
			if boolValue then
				K.SaveConfig("MiniBarEnabled", false);
				C.MiniBarEnabled = false;
				for _, cb in ipairs(checkboxes) do
					if cb.setting == "MiniBarEnabled" then cb:SetChecked(false); end
				end
				if K.EnableUnifyActionBars then K.EnableUnifyActionBars(); end
			else
				if K.DisableUnifyActionBars then K.DisableUnifyActionBars(); end
			end
			if K._UpdateBagPackVisibility then K._UpdateBagPackVisibility(); end
		elseif setting == "MiniBarEnabled" then
			if boolValue then
				K.SaveConfig("UnifyActionBars", false);
				C.UnifyActionBars = false;
				for _, cb in ipairs(checkboxes) do
					if cb.setting == "UnifyActionBars" then cb:SetChecked(false); end
				end
				if K._unifyActive and K.DisableUnifyActionBars then K.DisableUnifyActionBars(); end
				if K.EnableMiniBar then K.EnableMiniBar(); end
			else
				if K.DisableMiniBar then K.DisableMiniBar(); end
			end
			if K._UpdateBagPackVisibility then K._UpdateBagPackVisibility(); end
		elseif setting == "HideGryphons" then
			if K.ApplyGryphons then K.ApplyGryphons(); end
		elseif setting == "ShowBagPackTexture" then
			if K.ApplyBagPackTexture then K.ApplyBagPackTexture(); end
		elseif setting == "HealthPercentage" then
			if K.ToggleHealthPercentage then K.ToggleHealthPercentage(boolValue); end
		elseif setting == "ArenaFrameOn" then
			if showArenaBtn then
				if boolValue then showArenaBtn:Show();
				else
					showArenaBtn:Hide();
					local arenaMover = _G["NUF_ArenaMover"];
					if arenaMover and arenaMover:IsShown() then
						if K.ForceHideArenaMover then K.ForceHideArenaMover(); end
					end
				end
			end
			if K.ToggleArenaFrames then K.ToggleArenaFrames(boolValue); end
		elseif setting == "ArenaFrame_Trinkets" then
			if K.ToggleArenaTrinketsTracking then K.ToggleArenaTrinketsTracking(boolValue); end
		elseif setting == "ArenaMirrorMode" then
			if K.ToggleMirrorMode then K.ToggleMirrorMode(boolValue); end
		elseif setting == "ArenaCustomTexture" then
			if K.ToggleArenaCustomTexture then K.ToggleArenaCustomTexture(boolValue); end
		elseif setting == "SetPositions" then
			if boolValue then
				if K.InitializePartyFrames then K.InitializePartyFrames(); end
				if K.ApplyFramePositions   then K.ApplyFramePositions(); end
				if lockPosCheckbox   then lockPosCheckbox:Show(); end
				if not C.LockPositions and dragHintText then dragHintText:Show(); end
				if partyIndivCheckbox    then partyIndivCheckbox:Show(); end
				if partyMode3v3Checkbox  then partyMode3v3Checkbox:Show(); end
				local panel1 = tabPanels[1];
				if panel1 and panel1.resetPosBtn then panel1.resetPosBtn:Show(); end
				if C.PartyMode3v3 and K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
				if K.ApplyArenaCustomPosition then K.ApplyArenaCustomPosition(true); end
				if K.RegisterPartyDragger then K.RegisterPartyDragger(); end
			else
				if C.PartyMode3v3 and K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
				if K.ApplyFramePositions then K.ApplyFramePositions(); end
				if lockPosCheckbox  then lockPosCheckbox:Hide(); end
				if dragHintText     then dragHintText:Hide(); end
				if partyIndivCheckbox   then partyIndivCheckbox:Hide(); end
				if partyMode3v3Checkbox then partyMode3v3Checkbox:Hide(); end
				local panel1 = tabPanels[1];
				if panel1 and panel1.resetPosBtn then panel1.resetPosBtn:Hide(); end
				if K.ApplyArenaCustomPosition then K.ApplyArenaCustomPosition(false); end
			end
		elseif setting == "LockPositions" then
			-- dragHintText removed; hint is in the static alert box
		elseif setting == "PartyIndividualMove" then
			if boolValue then
				if K.ApplyIndividualPartyPositions then K.ApplyIndividualPartyPositions(); end
			else
				if K.RestorePartyToGroup then K.RestorePartyToGroup(); end
			end
		elseif setting == "PartyMode3v3" then
			if boolValue then
				if K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
			else
				if K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
			end
		elseif setting == "NewPartyFrame" then
			if boolValue then
				if K.EnableNewPartyFrame then K.EnableNewPartyFrame(); end
			else
				if K.DisableNewPartyFrame then K.DisableNewPartyFrame(); end
			end
		end
	end);

	table.insert(checkboxes, check);
	return check;
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateSlider
-- ────────────────────────────────────────────────────────────────────────────
local function FormatSliderValue(step, value)
	if step >= 1 then      return string.format("%d",   value);
	elseif step >= 0.1 then return string.format("%.1f", value);
	else                    return string.format("%.2f", value);
	end
end

local function CreateSlider(parent, labelText, setting, minVal, maxVal, step, xOffset, yOffset)
	sliderCount = sliderCount + 1;
	local sliderName = "NidhausUFSlider"..sliderCount;
	local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate");
	slider:SetPoint("TOPLEFT", xOffset or 20, yOffset);
	slider:SetMinMaxValues(minVal, maxVal);
	slider:SetValueStep(step);
	slider:SetWidth(200);
	slider.setting = setting;

	local initialValue = C[setting];
	if type(initialValue) ~= "number" then initialValue = minVal; end
	slider:SetValue(initialValue);

	local tipKey = tooltips[setting];
	if tipKey and L[tipKey] then
		slider:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(labelText, 1, 1, 1);
			GameTooltip:AddLine(L[tipKey], nil, nil, nil, true);
			GameTooltip:Show();
		end);
		slider:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end

	local sliderText = _G[sliderName.."Text"];
	local sliderLow  = _G[sliderName.."Low"];
	local sliderHigh = _G[sliderName.."High"];
	if sliderText then sliderText:SetText(labelText); end
	if sliderLow  then sliderLow:SetText(minVal); end
	if sliderHigh then sliderHigh:SetText(maxVal); end

	local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	valueText:SetPoint("TOP", slider, "BOTTOM", 0, -5);
	valueText:SetText(FormatSliderValue(step, slider:GetValue()));

	slider:SetScript("OnValueChanged", function(self, value)
		if not value or value < minVal or value > maxVal then return; end
		valueText:SetText(FormatSliderValue(step, value));
		K.SaveConfig(setting, value);
		if setting == "ActionBarScale" then
			if K.ApplyActionBarScale then K.ApplyActionBarScale(value); end
		end
	end);

	table.insert(sliders, slider);
	return slider;
end

-- ────────────────────────────────────────────────────────────────────────────
-- DROPDOWN HELPER
-- ────────────────────────────────────────────────────────────────────────────
local dropdownCount = 0;

local function CreateDropdown(parent, labelText, setting, options, xOffset, yOffset, onChangeCallback)
	dropdownCount = dropdownCount + 1;
	local ddName = "NidhausUFDropdown"..dropdownCount;

	local container = CreateFrame("Frame", nil, parent);
	container:SetPoint("TOPLEFT", xOffset or 20, yOffset);
	container:SetSize(200, 50);

	local label = container:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	label:SetPoint("TOPLEFT", 0, 0);
	label:SetText(labelText);

	local dd = CreateFrame("Frame", ddName, container, "UIDropDownMenuTemplate");
	dd:SetPoint("TOPLEFT", -16, -16);
	UIDropDownMenu_SetWidth(dd, 140);

	local function Initialize(self, level)
		for _, opt in ipairs(options) do
			local info = UIDropDownMenu_CreateInfo();
			info.text  = opt.text;
			info.value = opt.value;
			info.func  = function(btn)
				UIDropDownMenu_SetSelectedValue(dd, btn.value);
				UIDropDownMenu_SetText(dd, btn.value);
				K.SaveConfig(setting, btn.value);
				if onChangeCallback then onChangeCallback(btn.value); end
			end;
			info.checked = (C[setting] == opt.value);
			UIDropDownMenu_AddButton(info, level);
		end
	end

	UIDropDownMenu_Initialize(dd, Initialize);
	UIDropDownMenu_SetSelectedValue(dd, C[setting] or options[1].value);
	UIDropDownMenu_SetText(dd, C[setting] or options[1].value);

	container.dropdown = dd;
	return container;
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateThemeSwitcher
-- Builds the 3 pill-buttons that sit in the footer of the panel.
-- Returns a table of {id -> button} for ThemeManager registration.
-- ────────────────────────────────────────────────────────────────────────────
local function CreateThemeSwitcher()
	if not K.GetPanelThemes then return {}; end
	local THEMES, THEME_ORDER = K.GetPanelThemes();
	if not THEMES or not THEME_ORDER then return {}; end

	local themeButtons = {};
	local btnW, btnH = 98, 24;
	local gap  = 6;
	local totalW = (#THEME_ORDER * btnW) + ((#THEME_ORDER - 1) * gap);

	-- Container in the UPPER footer row (above the action buttons)
	local container = CreateFrame("Frame", nil, mainFrame);
	container:SetSize(totalW + 14, btnH + 10);
	container:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 50);

	-- Optional: dim label to the left
	local label = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	label:SetPoint("RIGHT", container, "LEFT", -6, 0);
	label:SetText("|cff888888Style|r");

	for i, id in ipairs(THEME_ORDER) do
		local t = THEMES[id];
		local btn = CreateFrame("Button", nil, container);
		btn:SetSize(btnW, btnH);

		-- Position relative to container left edge
		btn:SetPoint("LEFT", container, "LEFT", (i-1) * (btnW + gap), 0);

		-- Backdrop for pill shape
		btn:SetBackdrop({
			bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile     = true, tileSize = 16, edgeSize = 12,
			insets   = {left=3, right=3, top=3, bottom=3},
		});
		btn:SetBackdropColor(0.07, 0.07, 0.07, 0.65);
		btn:SetBackdropBorderColor(
			t.accent[1]*0.38, t.accent[2]*0.38, t.accent[3]*0.38, 0.55);

		-- Colored dot (small circle indicator)
		local dot = btn:CreateTexture(nil, "ARTWORK");
		dot:SetSize(8, 8);
		dot:SetPoint("LEFT", btn, "LEFT", 7, 0);
		dot:SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Coin-Down");
		dot:SetVertexColor(
			t.accent[1]*0.48, t.accent[2]*0.48, t.accent[3]*0.48, 0.65);
		btn.dot = dot;

		-- Label text
		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		fs:SetPoint("LEFT", dot, "RIGHT", 5, 0);
		fs:SetText(t.label);
		fs:SetTextColor(0.48, 0.48, 0.48);
		btn.labelFS = fs;

		-- Hover
		btn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP");
			GameTooltip:SetText(t.label, t.accent[1], t.accent[2], t.accent[3]);
			GameTooltip:AddLine("Switch panel theme", 0.7, 0.7, 0.7);
			GameTooltip:Show();
			-- Brighten border slightly on hover
			if NidhausUnitFramesDB and NidhausUnitFramesDB.PanelTheme ~= id then
				self:SetBackdropBorderColor(
					t.accent[1]*0.65, t.accent[2]*0.65, t.accent[3]*0.65, 0.75);
			end
		end);
		btn:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
			-- Restore dim (ThemeManager will set the correct state)
			if NidhausUnitFramesDB and NidhausUnitFramesDB.PanelTheme ~= id then
				self:SetBackdropBorderColor(
					t.accent[1]*0.38, t.accent[2]*0.38, t.accent[3]*0.38, 0.55);
			end
		end);

		btn:SetScript("OnClick", function()
			K.ApplyPanelTheme(id);
		end);

		themeButtons[id] = btn;
	end

	return themeButtons;
end

-- ────────────────────────────────────────────────────────────────────────────
-- PopulateTabs
-- ────────────────────────────────────────────────────────────────────────────
local function PopulateTabs()
	-- ── TAB 1: GENERAL ───────────────────────────────────────
	local panel1 = tabPanels[1];

	local header1 = panel1:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	header1:SetPoint("TOPLEFT", 14, -14);
	header1:SetText(L["HEADER_GENERAL"]);

	local desc1 = panel1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	desc1:SetPoint("TOPLEFT", header1, "BOTTOMLEFT", 0, -6);
	desc1:SetText(L["DESC_GENERAL"]);

	local yPos = -50;
	CreateCheckBox(panel1, L["CB_CLASS_COLOR"],  "classColor",        20, yPos); yPos = yPos - 30;
	CreateCheckBox(panel1, L["CB_BACKDROP"],     "statusbarBackdrop", 20, yPos); yPos = yPos - 30;
	CreateCheckBox(panel1, L["CB_HEALTH_PCT"],   "HealthPercentage",  20, yPos);

	yPos = yPos - 40;
	local posHeader = panel1:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	posHeader:SetPoint("TOPLEFT", 20, yPos);
	posHeader:SetText(L["HEADER_POSITIONS"]);

	-- ── Hint lines: how to move frames (plain text, no box) ──
	yPos = yPos - 22;
	local hintLine1 = panel1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	hintLine1:SetPoint("TOPLEFT", 20, yPos);
	hintLine1:SetWidth(260);
	hintLine1:SetJustifyH("LEFT");
	hintLine1:SetText(L["POS_HINT_ENABLE"]);

	yPos = yPos - 34;
	local hintLine2 = panel1:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	hintLine2:SetPoint("TOPLEFT", 20, yPos);
	hintLine2:SetWidth(260);
	hintLine2:SetJustifyH("LEFT");
	hintLine2:SetText(L["POS_HINT_DRAG"]);

	yPos = yPos - 55;
	CreateCheckBox(panel1, L["CB_CUSTOM_POS"], "SetPositions", 20, yPos);

	yPos = yPos - 28;
	lockPosCheckbox = CreateCheckBox(panel1, L["CB_LOCK_POS"], "LockPositions", 40, yPos);
	if not C.SetPositions then lockPosCheckbox:Hide(); end

	-- dragHintText kept as hidden reference for internal compatibility
	dragHintText = panel1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	dragHintText:SetPoint("TOPLEFT", 44, yPos - 14);
	dragHintText:Hide();

	yPos = yPos - 28;
	partyIndivCheckbox = CreateCheckBox(panel1, L["CB_PARTY_INDIVIDUAL"], "PartyIndividualMove", 40, yPos);
	if not C.SetPositions then partyIndivCheckbox:Hide(); end

	yPos = yPos - 28;
	partyMode3v3Checkbox = CreateCheckBox(panel1, L["CB_PARTY_3V3"], "PartyMode3v3", 40, yPos);
	if not C.SetPositions then partyMode3v3Checkbox:Hide(); end

	yPos = yPos - 30;
	local resetPosBtn = CreateFrame("Button", nil, panel1, "UIPanelButtonTemplate");
	resetPosBtn:SetPoint("TOPLEFT", 40, yPos);
	resetPosBtn:SetSize(200, 22);
	resetPosBtn:SetText(L["BTN_RESET_POS"]);
	resetPosBtn:SetScript("OnClick", function()
		StaticPopup_Show("NIDHAUS_RESET_POS_CONFIRM");
	end);
	if not C.SetPositions then resetPosBtn:Hide(); end
	panel1.resetPosBtn = resetPosBtn;

	-- ── RIGHT COLUMN: Visual Theme (Dark/Light legacy dropdown) ──
	local themeHeader = panel1:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	themeHeader:SetPoint("TOPLEFT", 310, -14);
	themeHeader:SetText(L["HEADER_THEME"]);

	local themeOptions = {
		{text = L["THEME_OPT_LIGHT"] or "Light", value = "Light"},
		{text = L["THEME_OPT_DARK"]  or "Dark",  value = "Dark"},
	};
	local currentTheme = C.darkFrames and "Dark" or "Light";

	local themeContainer = CreateFrame("Frame", nil, panel1);
	themeContainer:SetPoint("TOPLEFT", 310, -42);
	themeContainer:SetSize(200, 50);

	local themeLabel = themeContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	themeLabel:SetPoint("TOPLEFT", 0, 0);
	themeLabel:SetText(L["LABEL_THEME"] or "Dark Frames");

	dropdownCount = dropdownCount + 1;
	local themeDDName = "NidhausUFDropdown"..dropdownCount;
	local themeDD = CreateFrame("Frame", themeDDName, themeContainer, "UIDropDownMenuTemplate");
	themeDD:SetPoint("TOPLEFT", -16, -16);
	UIDropDownMenu_SetWidth(themeDD, 120);

	local function ThemeInitialize(self, level)
		for _, opt in ipairs(themeOptions) do
			local info = UIDropDownMenu_CreateInfo();
			info.text  = opt.text;
			info.value = opt.value;
			info.func  = function(btn)
				UIDropDownMenu_SetSelectedValue(themeDD, btn.value);
				UIDropDownMenu_SetText(themeDD, btn.value);
				local isDark = (btn.value == "Dark");
				K.SaveConfig("darkFrames", isDark);
				print(L["THEME_CHANGED"] or "|cff00FF00NUF:|r Theme changed. /reload to apply.");
			end;
			info.checked = (opt.value == currentTheme);
			UIDropDownMenu_AddButton(info, level);
		end
	end
	UIDropDownMenu_Initialize(themeDD, ThemeInitialize);
	UIDropDownMenu_SetSelectedValue(themeDD, currentTheme);
	UIDropDownMenu_SetText(themeDD, currentTheme);

	local themeHint = panel1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	themeHint:SetPoint("TOPLEFT", themeContainer, "BOTTOMLEFT", 4, -4);
	themeHint:SetText("|cffFFAA00/reload to apply dark frame change|r");

	-- ── Action Bars ──────────────────────────────────────────
	local uabHeader = panel1:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	uabHeader:SetPoint("TOPLEFT", themeHint, "BOTTOMLEFT", -4, -18);
	uabHeader:SetText(L["HEADER_ACTIONBARS"] or "|cff00FF00Action Bars|r");

	CreateCheckBox(panel1, L["CB_UNIFY_ACTIONBARS"], "UnifyActionBars", 310, -170);
	local uabCheckbox = checkboxes[#checkboxes];
	uabCheckbox:ClearAllPoints();
	uabCheckbox:SetPoint("TOPLEFT", uabHeader, "BOTTOMLEFT", 0, -8);

	CreateCheckBox(panel1, L["CB_MINIBAR"] or "MiniBar", "MiniBarEnabled", 310, -170);
	local mbCheckbox = checkboxes[#checkboxes];
	mbCheckbox:ClearAllPoints();
	mbCheckbox:SetPoint("TOPLEFT", uabCheckbox, "BOTTOMLEFT", 0, 4);

	CreateCheckBox(panel1, L["CB_HIDE_GRYPHONS"] or "Hide Gryphons", "HideGryphons", 310, -170);
	local gryphonCheckbox = checkboxes[#checkboxes];
	gryphonCheckbox:ClearAllPoints();
	gryphonCheckbox:SetPoint("TOPLEFT", mbCheckbox, "BOTTOMLEFT", 0, -12);

	CreateCheckBox(panel1, L["CB_BAGPACK"] or "BagPack Background", "ShowBagPackTexture", 310, -170);
	local bagpackCheckbox = checkboxes[#checkboxes];
	bagpackCheckbox:ClearAllPoints();
	bagpackCheckbox:SetPoint("TOPLEFT", gryphonCheckbox, "BOTTOMLEFT", 0, 4);

	local function UpdateBagPackCheckboxVisibility()
		local anyBarActive = K.IsAnyBarModeActive and K.IsAnyBarModeActive()
			or (C.UnifyActionBars == true) or (C.MiniBarEnabled == true);
		if anyBarActive then bagpackCheckbox:Show();
		else                 bagpackCheckbox:Hide(); end
	end
	K._UpdateBagPackVisibility = UpdateBagPackCheckboxVisibility;
	UpdateBagPackCheckboxVisibility();

	local abScaleSlider = CreateSlider(panel1,
		L["SLIDER_ACTIONBAR_SCALE"] or "Action Bar Scale",
		"ActionBarScale", 0.65, 1.14, 0.01, 310, -170);
	abScaleSlider:SetWidth(165);
	abScaleSlider:ClearAllPoints();
	abScaleSlider:SetPoint("TOPLEFT", bagpackCheckbox, "BOTTOMLEFT", 10, -16);

	-- ── TAB 2: FRAMES ─────────────────────────────────────────
	local panel2 = tabPanels[2];
	if K.PopulateFramesTab then K.PopulateFramesTab(panel2); end

	-- ── TAB 3: ARENA ──────────────────────────────────────────
	local panel3 = tabPanels[3];
	if K.PopulateArenaTab then
		showArenaBtn = K.PopulateArenaTab(panel3);
	end

	-- ── TAB 4: MODULES ────────────────────────────────────────
	local panel4 = tabPanels[4];

	local header4 = panel4:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	header4:SetPoint("TOPLEFT", 14, -14);
	header4:SetText(L["HEADER_MODULES"]);

	local desc4 = panel4:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	desc4:SetPoint("TOPLEFT", header4, "BOTTOMLEFT", 0, -6);
	desc4:SetText(L["DESC_MODULES"]);

	local scrollFrame = CreateFrame("ScrollFrame", "NidhausModulesScrollFrame",
		panel4, "UIPanelScrollFrameTemplate");
	scrollFrame:SetPoint("TOPLEFT",     10,  -50);
	scrollFrame:SetPoint("BOTTOMRIGHT", -30,  10);

	local scrollChild = CreateFrame("Frame", "NidhausModulesScrollChild", scrollFrame);
	scrollChild:SetWidth(540);
	scrollChild:SetHeight(1);
	scrollFrame:SetScrollChild(scrollChild);

	local moduleCount = 0;
	K._moduleContainers = {};
	local prevContainer = nil;

	local function UpdateModulesScrollHeight()
		local totalH = 5;
		for _, id in ipairs(K.ModuleOrder) do
			local ct = K._moduleContainers[id];
			if ct then totalH = totalH + ct:GetHeight(); end
		end
		scrollChild:SetHeight(totalH + 60);
	end
	K.UpdateModulesScrollHeight = UpdateModulesScrollHeight;

	if K.ModuleOrder and #K.ModuleOrder > 0 then
		for _, id in ipairs(K.ModuleOrder) do
			local mod = K.Modules[id];
			if mod and not mod.hideFromModulesTab then
				moduleCount = moduleCount + 1;
				checkboxCount = checkboxCount + 1;

				local container = CreateFrame("Frame", "NidhausModuleContainer_"..id, scrollChild);
				container:SetWidth(540);
				if prevContainer then
					container:SetPoint("TOPLEFT", prevContainer, "BOTTOMLEFT", 0, 0);
				else
					container:SetPoint("TOPLEFT", 0, -5);
				end

				local cbName = "NidhausUFModuleCB"..moduleCount;
				local check  = CreateFrame("CheckButton", cbName, container,
					"InterfaceOptionsCheckButtonTemplate");
				check:SetPoint("TOPLEFT", 10, 0);
				check:SetHitRectInsets(0, 0, 0, 0);

				local mlabel = _G[cbName.."Text"];
				if mlabel then
					mlabel:SetText(mod.name);
					mlabel:SetFontObject("GameFontNormal");
				end

				if mod.desc and mod.desc ~= "" then
					check:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetText(mod.name, 1, 1, 1);
						GameTooltip:AddLine(mod.desc, nil, nil, nil, true);
						GameTooltip:AddLine(" ");
						if K.IsModuleEnabled(id) then
							GameTooltip:AddLine(L["MODULES_ENABLED"]);
						else
							GameTooltip:AddLine(L["MODULES_DISABLED"]);
						end
						GameTooltip:Show();
					end);
					check:SetScript("OnLeave", function() GameTooltip:Hide(); end);
				end

				check:SetChecked(K.IsModuleEnabled(id));
				check.moduleId = id;
				check:SetScript("OnClick", function(self)
					local isChecked = self:GetChecked();
					K.SetModuleEnabled(id, isChecked == 1 or isChecked == true);
				end);

				local baseHeight = 0;
				if mod.desc and mod.desc ~= "" then
					local descText = container:CreateFontString(nil, "ARTWORK",
						"GameFontHighlightSmall");
					descText:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 26, 2);
					descText:SetText("|cff888888"..mod.desc.."|r");
					descText:SetWidth(480);
					descText:SetJustifyH("LEFT");
					baseHeight = 40;
				else
					baseHeight = 28;
				end

				local subUIHeight = 0;
				container._collapsed = false;

				if mod.createUI then
					local beforeChildren = {};
					for _, child in pairs({container:GetChildren()}) do
						beforeChildren[child] = true;
					end
					local beforeRegions = {};
					for _, region in pairs({container:GetRegions()}) do
						beforeRegions[region] = true;
					end

					subUIHeight = mod.createUI(container, -baseHeight, check) or 0;

					if subUIHeight > 100 then
						local subUIElements = {};
						for _, child in pairs({container:GetChildren()}) do
							if not beforeChildren[child] then
								table.insert(subUIElements, child);
							end
						end
						for _, region in pairs({container:GetRegions()}) do
							if not beforeRegions[region] then
								table.insert(subUIElements, region);
							end
						end

						local collapseBtn = CreateFrame("Button", nil, container);
						collapseBtn:SetSize(20, 16);
						collapseBtn:SetPoint("LEFT", _G[cbName.."Text"] or check, "RIGHT", 6, 0);
						collapseBtn:SetNormalFontObject("GameFontNormalSmall");

						local collapsed = true;

						local function UpdateCollapseVisual()
							if collapsed then
								collapseBtn:SetText("|cffAAAAAA[+]|r");
								for _, elem in ipairs(subUIElements) do
									if elem.Hide then elem:Hide(); end
								end
								container:SetHeight(baseHeight);
							else
								collapseBtn:SetText("|cffAAAAAA[-]|r");
								if K.IsModuleEnabled(id) then
									for _, elem in ipairs(subUIElements) do
										if elem.Show then elem:Show(); end
									end
									container:SetHeight(baseHeight + subUIHeight);
								else
									container:SetHeight(baseHeight);
								end
							end
							container._collapsed = collapsed;
							UpdateModulesScrollHeight();
						end

						collapseBtn:SetScript("OnClick", function()
							collapsed = not collapsed;
							UpdateCollapseVisual();
						end);
						collapseBtn:SetScript("OnEnter", function(self)
							GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
							GameTooltip:SetText(collapsed
								and (L["MODULE_EXPAND"]   or "Click to expand")
								or  (L["MODULE_COLLAPSE"] or "Click to collapse"),
								0.8, 0.8, 0.8);
							GameTooltip:Show();
						end);
						collapseBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

						UpdateCollapseVisual();
					end
				end

				container._baseHeight  = baseHeight;
				container._subUIHeight = subUIHeight;
				container._moduleId    = id;

				if container._collapsed then
					container:SetHeight(baseHeight);
				elseif K.IsModuleEnabled(id) and subUIHeight > 0 then
					container:SetHeight(baseHeight + subUIHeight);
				else
					container:SetHeight(baseHeight);
				end

				K._moduleContainers[id] = container;
				prevContainer = container;
			end
		end
	end

	if moduleCount == 0 then
		local noModules = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		noModules:SetPoint("TOPLEFT", 10, -5);
		noModules:SetText(L["MODULES_NONE"]);

		local helpText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		helpText:SetPoint("TOPLEFT", 10, -35);
		helpText:SetWidth(480);
		helpText:SetJustifyH("LEFT");
		helpText:SetText(L["MODULES_HOWTO"]);
	end

	UpdateModulesScrollHeight();

	-- ── TAB 5: EXTRA ──────────────────────────────────────────
	local panel5 = tabPanels[5];
	if K.PopulateExtraTab then K.PopulateExtraTab(panel5); end

	-- ── TAB 6: ABOUT ──────────────────────────────────────────
	local panel6 = tabPanels[6];
	if K.PopulateAboutTab then K.PopulateAboutTab(panel6); end
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateBottomButtons
-- ────────────────────────────────────────────────────────────────────────────
local function CreateBottomButtons()
	-- Left buttons
	local reloadButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	reloadButton:SetPoint("BOTTOMLEFT", 20, 18);
	reloadButton:SetSize(120, 25);
	reloadButton:SetText(L["BTN_RELOAD"]);
	reloadButton:SetScript("OnClick", function() ReloadUI(); end);

	local resetButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	resetButton:SetPoint("LEFT", reloadButton, "RIGHT", 10, 0);
	resetButton:SetSize(120, 25);
	resetButton:SetText(L["BTN_RESET"]);
	resetButton:SetScript("OnClick", function()
		StaticPopup_Show("NIDHAUS_RESET_CONFIRM");
	end);

	-- Right buttons
	local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	closeButton:SetPoint("BOTTOMRIGHT", -20, 18);
	closeButton:SetSize(120, 25);
	closeButton:SetText(L["BTN_CLOSE"]);
	closeButton:SetScript("OnClick", function() mainFrame:Hide(); end);

	local infoButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	infoButton:SetPoint("RIGHT", closeButton, "LEFT", -10, 0);
	infoButton:SetSize(120, 25);
	infoButton:SetText(L["BTN_SHOW_CONFIG"]);
	infoButton:SetScript("OnClick", function() K.ShowConfig(); end);

	-- ── Popup dialogs ─────────────────────────────────────────
	StaticPopupDialogs["NIDHAUS_RESET_CONFIRM"] = {
		text           = L["RESET_CONFIRM"],
		button1        = L["RESET_BTN_YES"],
		button2        = L["RESET_BTN_NO"],
		OnAccept       = function() K.ResetConfig(); ReloadUI(); end,
		timeout        = 0,
		whileDead      = true,
		hideOnEscape   = true,
		preferredIndex = 3,
	};

	StaticPopupDialogs["NIDHAUS_RESET_POS_CONFIRM"] = {
		text           = L["RESET_POS_CONFIRM"],
		button1        = L["RESET_POS_BTN_YES"],
		button2        = L["RESET_POS_BTN_NO"],
		OnAccept       = function()
			if K.ResetPositionsAndScale then K.ResetPositionsAndScale(); end
			for _, slider in pairs(sliders) do
				if slider.setting and C[slider.setting] then
					slider:SetValue(C[slider.setting]);
				end
			end
		end,
		timeout        = 0,
		whileDead      = true,
		hideOnEscape   = true,
		preferredIndex = 3,
	};
end

-- ────────────────────────────────────────────────────────────────────────────
-- InitializePanel
-- ────────────────────────────────────────────────────────────────────────────
local function InitializePanel()
	CreateMainFrame();
	CreateTabs();
	PopulateTabs();
	CreateBottomButtons();

	-- ── Build theme switcher and register frames with ThemeManager ──
	local themeButtons = CreateThemeSwitcher();

	if K.RegisterThemeFrames then
		K.RegisterThemeFrames({
			mainFrame    = mainFrame,
			titleBox     = titleBoxRef,
			tabBar       = tabBarRef,
			tabs         = tabs,
			tabPanels    = tabPanels,
			themeButtons = themeButtons,
		});
	end

	-- ── Apply the saved (or default) panel theme ─────────────
	if K.LoadSavedTheme then
		K.LoadSavedTheme();
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- Initialization trigger
-- ────────────────────────────────────────────────────────────────────────────
local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN");
		InitializePanel();
	end
end);

SLASH_NUFCONFIG1 = "/nufconfig";
SLASH_NUFCONFIG2 = "/nufoptions";

SlashCmdList["NUFCONFIG"] = function(msg)
	if msg == "db" or msg == "database" then
		K.ShowConfig();
	else
		if not mainFrame then return; end
		if mainFrame:IsShown() then mainFrame:Hide(); else mainFrame:Show(); end
	end
end;

function K.ToggleOptionsPanel()
	if mainFrame then
		if mainFrame:IsShown() then mainFrame:Hide(); else mainFrame:Show(); end
	end
end