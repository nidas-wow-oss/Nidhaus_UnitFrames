



local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);

local mainFrame;
local currentTab  = 1;



local secondaryButtons = {};
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
local resetPosBtnRef;


local titleBoxRef;
local tabBarRef;

local tooltips = {

	classColor          = "TIP_classColor",
	statusbarBackdrop   = "TIP_statusbarBackdrop",
	HealthPercentage    = "TIP_HealthPercentage",
	CastingTimers       = "TIP_CastingTimers",
	CastBarPWEnabled    = "TIP_CastBarPWEnabled",
	CastBarPWIcon       = "TIP_CastBarPWIcon",
	CastBarPWIconSize   = "TIP_CastBarPWIconSize",
	CastBarPWDark       = "TIP_CastBarPWDark",
	CastBarPWTarget     = "TIP_CastBarPWTarget",
	CastBarPWFocus      = "TIP_CastBarPWFocus",
	TabBinderEnabled    = "TIP_TabBinderEnabled",
	MiniBarHideBackground = "TIP_MiniBarHideBackground",
	TooltipArenaExp     = "TIP_TooltipArenaExp",
	TooltipTalents      = "TIP_TooltipTalents",
	TooltipQualityBorder = "TIP_TooltipQualityBorder",
	TooltipIcons        = "TIP_TooltipIcons",
	CastBarPWScale      = "TIP_CastBarPWScale",
	FocusSpellBarScale  = "TIP_FocusSpellBarScale",
	UnitFrameCustomTexture = "TIP_UnitFrameCustomTexture",
	ShowCurrentValueOnly = "TIP_ShowCurrentValueOnly",
	BigStatusText       = "TIP_BigStatusText",
	BigTextCustomSize   = "TIP_BigTextCustomSize",
	SetPositions        = "TIP_SetPositions",
	LockPositions       = "TIP_LockPositions",
	PartyIndividualMove = "TIP_PartyIndividualMove",
	PartyMode3v3        = "TIP_PartyMode3v3",
	UnifyActionBars     = "TIP_UnifyActionBars",

	AutoSellGray        = "TIP_AutoSellGray",
	AutoRepair          = "TIP_AutoRepair",
	BlockDuels          = "TIP_BlockDuels",
	ChatCopyEnabled     = "TIP_ChatCopyEnabled",
	ChatClickableURLs   = "TIP_ChatClickableURLs",
	HideKeybindText     = "TIP_HideKeybindText",
	HideMacroText       = "TIP_HideMacroText",
};


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




local function CreateMainFrame()
	mainFrame = CreateFrame("Frame", "NidhausUnitFramesConfigFrame", UIParent);



	mainFrame:SetSize(820, 620);
	mainFrame:SetPoint("CENTER");
	mainFrame:SetFrameStrata("DIALOG");
	mainFrame:EnableMouse(true);
	mainFrame:SetMovable(true);
	mainFrame:RegisterForDrag("LeftButton");
	mainFrame:SetScript("OnDragStart", mainFrame.StartMoving);
	mainFrame:SetScript("OnDragStop",  mainFrame.StopMovingOrSizing);
	mainFrame:SetClampedToScreen(true);
	mainFrame:Hide();










	mainFrame:SetResizable(true);
	mainFrame:SetMinResize(640, 420);





	local function MaxPanelSize()
		local w = math.floor((UIParent:GetWidth()  or 1024) - 20);
		local h = math.floor((UIParent:GetHeight() or 768)  - 20);
		if w < 640 then w = 640; end
		if h < 420 then h = 420; end
		return w, h;
	end


	local function ClampPanelSize()
		local maxW, maxH = MaxPanelSize();
		mainFrame:SetMaxResize(maxW, maxH);
		local w, h = mainFrame:GetWidth(), mainFrame:GetHeight();
		local nw = (w < 640) and 640 or ((w > maxW) and maxW or w);
		local nh = (h < 420) and 420 or ((h > maxH) and maxH or h);
		if nw ~= w then mainFrame:SetWidth(nw); end
		if nh ~= h then mainFrame:SetHeight(nh); end
		return nw, nh;
	end



	local function EnsureOnScreen()
		local sw, sh = UIParent:GetWidth(), UIParent:GetHeight();
		local l, r = mainFrame:GetLeft(), mainFrame:GetRight();
		local b, t = mainFrame:GetBottom(), mainFrame:GetTop();
		if not l or not r or not b or not t
			or l < 0 or b < 0 or r > sw or t > sh then
			mainFrame:ClearAllPoints();
			mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		end
	end

	mainFrame:SetMaxResize(MaxPanelSize());
	K.ResetOptionsPanelSize = function()
		mainFrame:ClearAllPoints();
		mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		mainFrame:SetWidth(820);
		mainFrame:SetHeight(620);
		if K.SaveConfig then
			K.SaveConfig("PanelWidth",  820);
			K.SaveConfig("PanelHeight", 620);
		end
	end

	local sizer = CreateFrame("Frame", nil, mainFrame);
	sizer:SetPoint("BOTTOMRIGHT", -2, 2);
	sizer:SetWidth(20);
	sizer:SetHeight(20);
	sizer:EnableMouse(true);
	sizer:SetFrameLevel(mainFrame:GetFrameLevel() + 10);

	local function Rayita(size, offset)
		local t = sizer:CreateTexture(nil, "OVERLAY");
		t:SetWidth(size);
		t:SetHeight(size);
		t:SetPoint("BOTTOMRIGHT", -offset, offset);
		t:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border");
		local x = 0.1 * size / 17;
		t:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5);
		return t;
	end
	Rayita(14, 4);
	Rayita(8, 4);








	local function StopSizing()
		if not mainFrame.nufSizing then return; end
		mainFrame.nufSizing = nil;
		sizer:SetScript("OnUpdate", nil);
		mainFrame:StopMovingOrSizing();
		mainFrame:SetClampedToScreen(true);
		ClampPanelSize();
		EnsureOnScreen();
		if K.SaveConfig then
			K.SaveConfig("PanelWidth",  math.floor(mainFrame:GetWidth()  + 0.5));
			K.SaveConfig("PanelHeight", math.floor(mainFrame:GetHeight() + 0.5));
		end
	end

	sizer:SetScript("OnMouseDown", function(self, button)
		if button and button ~= "LeftButton" then return; end
		if mainFrame.nufSizing then return; end
		mainFrame.nufSizing = true;



		mainFrame:SetClampedToScreen(false);
		mainFrame:StartSizing("BOTTOMRIGHT");


		self:SetScript("OnUpdate", function()
			if not IsMouseButtonDown("LeftButton") then StopSizing(); end
		end);
	end);
	sizer:SetScript("OnMouseUp", StopSizing);
	sizer:SetScript("OnHide",    StopSizing);

	mainFrame:SetScript("OnShow", function()


		if C and C.PanelWidth and C.PanelHeight then
			mainFrame:SetWidth(C.PanelWidth);
			mainFrame:SetHeight(C.PanelHeight);
		end


		ClampPanelSize();
		EnsureOnScreen();
		if K._UpdateBagPackVisibility then K._UpdateBagPackVisibility(); end
		if K._UpdateHideTexVisibility then K._UpdateHideTexVisibility(); end
	end);

	mainFrame:SetScript("OnHide", StopSizing);


	mainFrame:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile     = true, tileSize = 32, edgeSize = 32,
		insets   = {left=11, right=12, top=12, bottom=11},
	});


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


	local title = titleBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	title:SetPoint("CENTER", titleBox, "CENTER", 0, 1);
	title:SetText(L["PANEL_TITLE"]);




	local titleHeaderTex = mainFrame:CreateTexture(nil, "ARTWORK");
	titleHeaderTex:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header");
	titleHeaderTex:SetWidth(500);
	titleHeaderTex:SetHeight(64);
	titleHeaderTex:SetPoint("TOP", mainFrame, "TOP", 0, 14);
	titleHeaderTex:Hide();


	titleBoxRef               = titleBox;
	mainFrame._titleHeaderTex = titleHeaderTex;


	local version = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	version:SetPoint("TOPRIGHT", -40, -16);
	version:SetText(L["PANEL_VERSION"]);


	local subtitle = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	subtitle:SetPoint("TOP", titleBox, "BOTTOM", 0, -4);
	subtitle:SetText("|cffAAAAAA" .. (L["PANEL_SUBTITLE"] or "") .. "|r");


	local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton");
	closeButton:SetPoint("TOPRIGHT", -5, -5);
	closeButton:SetScript("OnClick", function() mainFrame:Hide(); end);


	local tabBar = CreateFrame("Frame", nil, mainFrame);
	tabBar:SetPoint("TOPLEFT",  18, -48);
	tabBar:SetPoint("TOPRIGHT", -18, -48);
	tabBar:SetHeight(32);
	ApplyBackdrop(tabBar, 4);
	tabBar:SetBackdropColor(0, 0, 0, 0.20);
	mainFrame.TabBar = tabBar;
	tabBarRef = tabBar;


	local sepBottom = mainFrame:CreateTexture(nil, "ARTWORK");
	sepBottom:SetTexture(1, 1, 1, 0.08);
	sepBottom:SetPoint("BOTTOMLEFT",  mainFrame, "BOTTOMLEFT",  20, 78);
	sepBottom:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -20, 78);
	sepBottom:SetHeight(1);

	return mainFrame;
end




local function SelectTab(id)
	currentTab = id;

	for i, panel in ipairs(tabPanels) do
		if i == id then panel:Show() else panel:Hide() end
	end

	local theme  = K.GetActiveTheme and K.GetActiveTheme();
	local native = theme and theme.nativeTabs;

	for i, tab in ipairs(tabs) do





		if native and tab.native then
			local fn = (i == id) and PanelTemplates_SelectTab
			                     or  PanelTemplates_DeselectTab;
			if fn then pcall(fn, tab.native); end
		end

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




















local TAB_FONT_STEPS = { 12, 11, 10, 9, 8 };

local function LayoutTabs()
	local bar = mainFrame and mainFrame.TabBar;
	if not bar then return; end

	local visible = 0;
	for _, t in ipairs(tabs) do
		if not t._nufHidden then visible = visible + 1; end
	end
	if visible == 0 then return; end

	local barW = bar:GetWidth();


	if not barW or barW <= 1 then return; end

	local tabW = barW / visible;

	for _, t in ipairs(tabs) do
		if not t._nufHidden then
			t:SetWidth(tabW);

			local lbl = t.label;
			if lbl then
				local path, _, flags = lbl:GetFont();
				local avail = tabW - 10;
				for _, size in ipairs(TAB_FONT_STEPS) do
					lbl:SetFont(path, size, flags);
					if (lbl:GetStringWidth() or 0) <= avail then break; end
				end
			end
		end
	end
end






local function CreateTabs()













	local tabNames = {
		L["TAB_GENERAL"], L["TAB_FRAMES"], L["TAB_ARENA"],
		L["TAB_ADDONS"] or "Addons",
		L["TAB_PROFILES"] or "Profiles",
		L["TAB_ABOUT"] or "About",
	};
	local HIDDEN_TABS = { [5] = true, [6] = true };

	mainFrame.numTabs    = #tabNames;
	mainFrame.selectedTab = 1;

	local visibleCount = 0;
	for i = 1, #tabNames do
		if not HIDDEN_TABS[i] then visibleCount = visibleCount + 1; end
	end

	local tabBarWidth = mainFrame.TabBar:GetWidth() or (mainFrame:GetWidth() - 36);
	local tabWidth    = tabBarWidth / visibleCount;
	local prevVisible;
	local prevNative;

	for i, name in ipairs(tabNames) do
		local tab = CreateFrame("Button", mainFrame:GetName().."Tab"..i, mainFrame.TabBar);
		tab:SetID(i);
		tab:SetSize(tabWidth, 28);

		if HIDDEN_TABS[i] then


			tab:SetPoint("BOTTOMLEFT", mainFrame.TabBar, "BOTTOMLEFT", 0, 2);
			tab:Hide();
			tab._nufHidden = true;
		elseif not prevVisible then
			tab:SetPoint("BOTTOMLEFT", mainFrame.TabBar, "BOTTOMLEFT", 0, 2);
			prevVisible = tab;
		else
			tab:SetPoint("LEFT", prevVisible, "RIGHT", 0, 0);
			prevVisible = tab;
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


		tab:SetBackdropColor(0.1, 0.1, 0.1, 0.6);
		tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8);
		tab.selected = false;

		tab:SetScript("OnClick", function(self) SelectTab(self:GetID()); end);
















		local nat = CreateFrame("Button", mainFrame:GetName().."NativeTab"..i,
			mainFrame.TabBar, "OptionsFrameTabButtonTemplate");
		nat:SetID(i);
		nat:SetText(name);
		if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, nat, 0); end

		if HIDDEN_TABS[i] then
			nat:SetPoint("BOTTOMLEFT", mainFrame.TabBar, "BOTTOMLEFT", 0, 0);
		elseif not prevNative then
			nat:SetPoint("BOTTOMLEFT", mainFrame.TabBar, "BOTTOMLEFT", 4, -3);
			prevNative = nat;
		else
			nat:SetPoint("LEFT", prevNative, "RIGHT", -14, 0);
			prevNative = nat;
		end

		nat:SetScript("OnClick", function(self) SelectTab(self:GetID()); end);
		nat:Hide();
		tab.native = nat;

		tabs[i] = tab;


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


	mainFrame.TabBar:SetScript("OnSizeChanged", LayoutTabs);
	LayoutTabs();


	K.SelectPanelTab = SelectTab;



	K.RefreshPanelTabs = function() SelectTab(currentTab or 1); end;
end




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




	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox(setting, check); end

	check:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked();
		local boolValue = (isChecked == 1 or isChecked == true);

		local success = K.SaveConfig(setting, boolValue);
		if not success then self:refresh(); return; end

		if setting == "UnifyActionBars" or setting == "MiniBarEnabled" then













			local other = (setting == "UnifyActionBars") and "MiniBarEnabled" or "UnifyActionBars";

			if boolValue then

				K.SaveConfig(other, false);
				C[other] = false;
				for _, cb in ipairs(checkboxes) do
					if cb.setting == other then cb:SetChecked(false); end
				end
			end













			if K.LayoutRebuild then
				K.LayoutRebuild("cambio de modo de barras");
			end

			if K._UpdateBagPackVisibility then K._UpdateBagPackVisibility(); end
			if K._UpdateHideTexVisibility then K._UpdateHideTexVisibility(); end


			if K._UpdateButtonSpaceVisibility then K._UpdateButtonSpaceVisibility(); end
			if K._UpdateMiniBgVisibility then K._UpdateMiniBgVisibility(); end
			if K.ApplyActionBarButtonSpace then K.ApplyActionBarButtonSpace(); end
		elseif setting == "HideGryphons" then
			if K.ApplyGryphons then K.ApplyGryphons(); end
		elseif setting == "ShowBagPackTexture" then
			if K.ApplyBagPackTexture then K.ApplyBagPackTexture(); end
		elseif setting == "MiniBarHideBackground" then
			if K.ApplyMiniBarBackground then K.ApplyMiniBarBackground(); end
		elseif setting == "TabBinderEnabled" then
			if K.ApplyTabBinder then K.ApplyTabBinder(); end
		elseif setting == "HealthPercentage" then
			if K.ToggleHealthPercentage then K.ToggleHealthPercentage(boolValue); end
		elseif setting == "CastingTimers" then
			if K.ToggleCastingTimers then K.ToggleCastingTimers(boolValue); end
		elseif setting == "CastBarPWEnabled" then
			if K.ApplyCastBarPW then K.ApplyCastBarPW(); end
			if K._UpdateCastBarVisibility then K._UpdateCastBarVisibility(); end



			if K.RefreshCastingTimerLayout then K.RefreshCastingTimerLayout(); end
		elseif setting == "CastBarPWIcon" or setting == "CastBarPWDark"
			or setting == "CastBarPWTarget" or setting == "CastBarPWFocus" then




			if K.ApplyCastBarPW then K.ApplyCastBarPW(); end
			if K._UpdateCastBarVisibility then K._UpdateCastBarVisibility(); end
		elseif setting == "BigStatusText" or setting == "BigTextCustomSize" then


			if K.ApplyBigStatusText then K.ApplyBigStatusText(); end
			if K._RefreshBigTextBody then K._RefreshBigTextBody(); end
		elseif setting == "ShowCurrentValueOnly" then


			if boolValue and K.IsModuleEnabled and K.IsModuleEnabled("AbbreviatedStatus") then
				if K.SetModuleEnabled then K.SetModuleEnabled("AbbreviatedStatus", false); end
				if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("AbbreviatedStatus"); end
			end
			if K._SyncStatusTextExclusive then K._SyncStatusTextExclusive(); end
			if K.ApplyHealthTextFormat then K.ApplyHealthTextFormat(); end


			if K.InvalidateAbbrevAnchors then K.InvalidateAbbrevAnchors(); end
		elseif setting == "UnitFrameCustomTexture" then


			if K.ApplyUnitFrameTheme then K.ApplyUnitFrameTheme(); end
			if K._UpdateThemeVisibility then K._UpdateThemeVisibility(); end
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




			if boolValue then
				if K.EnableArenaFrameMod then K.EnableArenaFrameMod(); end
			else
				if K.DisableArenaFrameMod then K.DisableArenaFrameMod(); end
			end
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
				if resetPosBtnRef then resetPosBtnRef:Show(); end
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
				if resetPosBtnRef then resetPosBtnRef:Hide(); end
				if K.ApplyArenaCustomPosition then K.ApplyArenaCustomPosition(false); end
			end
		elseif setting == "LockPositions" then

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
	slider._nufOwnValue = valueText;

	slider:SetScript("OnValueChanged", function(self, value)
		if not value or value < minVal or value > maxVal then return; end
		valueText:SetText(FormatSliderValue(step, value));


		if self._nufRefreshing then return; end
		K.SaveConfig(setting, value);
		if setting == "ActionBarScale" then


			if K.ClearBarOwnScales then K.ClearBarOwnScales(); end
			if K.ApplyActionBarScale then K.ApplyActionBarScale(value); end
		end
	end);

	table.insert(sliders, slider);
	return slider;
end




function K.RefreshPanelSliders(setting)
	for _, s in ipairs(sliders) do
		if s.setting and (not setting or s.setting == setting) then
			local v = C[s.setting];
			if type(v) == "number" and s:GetValue() ~= v then
				s._nufRefreshing = true;
				s:SetValue(v);
				s._nufRefreshing = nil;
			end
		end
	end
end




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







	local function TextFor(value)
		for _, opt in ipairs(options) do
			if opt.value == value then return opt.text; end
		end
		return tostring(value);
	end

	local function Initialize(self, level)
		for _, opt in ipairs(options) do
			local info = UIDropDownMenu_CreateInfo();
			info.text  = opt.text;
			info.value = opt.value;
			info.func  = function(btn)
				UIDropDownMenu_SetSelectedValue(dd, btn.value);
				UIDropDownMenu_SetText(dd, TextFor(btn.value));
				K.SaveConfig(setting, btn.value);
				if onChangeCallback then onChangeCallback(btn.value); end
			end;
			info.checked = (C[setting] == opt.value);
			UIDropDownMenu_AddButton(info, level);
		end
	end

	local current = C[setting];
	if current == nil then current = options[1].value; end
	UIDropDownMenu_Initialize(dd, Initialize);
	UIDropDownMenu_SetSelectedValue(dd, current);
	UIDropDownMenu_SetText(dd, TextFor(current));

	container.dropdown = dd;
	return container;
end






local function CreateThemeSwitcher()
	if not K.GetPanelThemes then return {}; end
	local THEMES, THEME_ORDER = K.GetPanelThemes();
	if not THEMES or not THEME_ORDER then return {}; end

	local themeButtons = {};
	local btnW, btnH = 98, 24;
	local gap  = 6;
	local totalW = (#THEME_ORDER * btnW) + ((#THEME_ORDER - 1) * gap);







	local container = CreateFrame("Frame", nil, mainFrame);
	container:SetSize(totalW + 14, btnH + 10);
	container:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -20, 50);


	local label = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	label:SetPoint("RIGHT", container, "LEFT", -6, 0);
	label:SetText("|cff888888" .. (L["PANEL_STYLE"] or "Style") .. "|r");

	for i, id in ipairs(THEME_ORDER) do
		local t = THEMES[id];
		local btn = CreateFrame("Button", nil, container);
		btn:SetSize(btnW, btnH);


		btn:SetPoint("LEFT", container, "LEFT", (i-1) * (btnW + gap), 0);


		btn:SetBackdrop({
			bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile     = true, tileSize = 16, edgeSize = 12,
			insets   = {left=3, right=3, top=3, bottom=3},
		});
		btn:SetBackdropColor(0.07, 0.07, 0.07, 0.65);
		btn:SetBackdropBorderColor(
			t.accent[1]*0.38, t.accent[2]*0.38, t.accent[3]*0.38, 0.55);


		local dot = btn:CreateTexture(nil, "ARTWORK");
		dot:SetSize(8, 8);
		dot:SetPoint("LEFT", btn, "LEFT", 7, 0);
		dot:SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Coin-Down");
		dot:SetVertexColor(
			t.accent[1]*0.48, t.accent[2]*0.48, t.accent[3]*0.48, 0.65);
		btn.dot = dot;


		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		fs:SetPoint("LEFT", dot, "RIGHT", 5, 0);
		fs:SetText(t.label);
		fs:SetTextColor(0.48, 0.48, 0.48);
		btn.labelFS = fs;


		btn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP");
			GameTooltip:SetText(t.label, t.accent[1], t.accent[2], t.accent[3]);
			GameTooltip:AddLine(L["TIP_PANEL_THEME"] or "Switch panel theme", 0.7, 0.7, 0.7);
			GameTooltip:Show();

			if NidhausUnitFramesDB and NidhausUnitFramesDB.PanelTheme ~= id then
				self:SetBackdropBorderColor(
					t.accent[1]*0.65, t.accent[2]*0.65, t.accent[3]*0.65, 0.75);
			end
		end);
		btn:SetScript("OnLeave", function(self)
			GameTooltip:Hide();

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







local function CreateModuleCB(parent, label, moduleId, x, y, tip)
	if not (K.Modules and K.Modules[moduleId]) then return nil; end
	checkboxCount = checkboxCount + 1;
	local cbName = "NidhausUFCheckBox" .. checkboxCount;
	local cb = CreateFrame("CheckButton", cbName, parent, "InterfaceOptionsCheckButtonTemplate");
	cb:SetPoint("TOPLEFT", x, y);
	cb:SetHitRectInsets(0, 0, 0, 0);

	local labelFS = _G[cbName .. "Text"];
	if labelFS then labelFS:SetText(label); end

	cb:SetChecked(K.IsModuleEnabled and K.IsModuleEnabled(moduleId) or false);
	if tip then
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(label, 1, 1, 1);
			GameTooltip:AddLine(tip, nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end
	cb:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SetModuleEnabled then K.SetModuleEnabled(moduleId, v); end
		if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox(moduleId); end
	end);
	if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox(moduleId, cb); end
	return cb;
end


local function SectionHeader(parent, text, x, y)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetText((K.UI and K.UI.Header(K.UI.Strip(text))) or text);
	return fs;
end


local function SectionNote(parent, text, x, y, width)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetWidth(width or 430);
	fs:SetJustifyH("LEFT");
	fs:SetText("|cff8EAEC9" .. (text or "") .. "|r");
	return fs;
end




local function PopulateTabs()






	local panel1 = tabPanels[1];



	local className = (K.GetClassSectionName and K.GetClassSectionName())
		or (L["SIDE_CLASSOPT"] or "Class Options");

	local sideUI = K.CreateSideList(panel1, {
		{ name = L["SIDE_GENERAL"]    or "General Settings" },
		{ name = L["SIDE_ACTIONBARS"] or "Action Bars" },
		{ name = L["SIDE_MINIMAP"]    or "Minimap" },
		{ name = L["SIDE_CHAT"]       or "Chat" },
		{ name = L["SIDE_CASTBAR"]    or "Cast Bar" },
		{ name = L["SIDE_TOOLTIP"]    or "Tooltip" },

		{ separator = true },
		{ name = L["TAB_PVP"] or "PvP" },
		{ name = className },







		{ name = L["SIDE_MOVEALL"] or "Move Everything", hidden = true },
	});
	panel1.sideList = sideUI;



	local paneGen, paneBars, paneMap, paneChat, paneCast, paneTip, panePvP, paneClass, paneMove =
		sideUI[1], sideUI[2], sideUI[3], sideUI[4], sideUI[5], sideUI[6], sideUI[7],
		sideUI[8], sideUI[9];

	local xL = 16;






	local xR = 300;
	local gY = -14;
	local rY = -14;

	SectionHeader(paneGen, L["HEADER_APPEARANCE"] or "Appearance", xL, gY);

	gY = gY - 24;
	CreateCheckBox(paneGen, L["CB_UNITFRAME_CUSTOM_TEX"], "UnitFrameCustomTexture", xL, gY);


	gY = gY - 30;
	local themeLabel = paneGen:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	themeLabel:SetPoint("TOPLEFT", xL + 22, gY - 5);
	themeLabel:SetText((K.UI and K.UI.Header(K.UI.Strip(L["HEADER_THEME"]))) or L["HEADER_THEME"]);

	local themeOptions = {
		{text = L["THEME_OPT_LIGHT"] or "Light", value = "Light"},
		{text = L["THEME_OPT_DARK"]  or "Dark",  value = "Dark"},
		{text = L["THEME_OPT_ASURI"] or "Asuri", value = "Asuri"},
		{text = L["THEME_OPT_PW"]    or "Compact", value = "Compact"},
	};




	local currentTheme = C.AsuriFrames and "Asuri"
		or (C.pwFrames and "Compact")
		or (C.darkFrames and "Dark")
		or "Light";

	dropdownCount = dropdownCount + 1;
	local themeDD = CreateFrame("Frame", "NidhausUFDropdown"..dropdownCount, paneGen, "UIDropDownMenuTemplate");
	themeDD:SetPoint("LEFT", themeLabel, "RIGHT", -8, -2);
	UIDropDownMenu_SetWidth(themeDD, 100);

	UIDropDownMenu_Initialize(themeDD, function(self, level)
		for _, opt in ipairs(themeOptions) do
			local info = UIDropDownMenu_CreateInfo();
			info.text  = opt.text;
			info.value = opt.value;
			info.func  = function(btn)
				UIDropDownMenu_SetSelectedValue(themeDD, btn.value);
				UIDropDownMenu_SetText(themeDD, btn.value);
				currentTheme = btn.value;



				K.SaveConfig("darkFrames",  btn.value == "Dark");
				K.SaveConfig("AsuriFrames", btn.value == "Asuri");
				K.SaveConfig("pwFrames",    btn.value == "Compact");
				if K._UpdateThemeVisibility then K._UpdateThemeVisibility(); end




				if K.ApplyUnitFrameTheme then
					K.ApplyUnitFrameTheme();
				else
					if K.ApplyPlayerFrameSkin then K.ApplyPlayerFrameSkin(); end
					if K.ApplyTargetFrameSkin then K.ApplyTargetFrameSkin(); end
				end

			end;
			info.checked = (opt.value == currentTheme);
			UIDropDownMenu_AddButton(info, level);
		end
	end);
	UIDropDownMenu_SetSelectedValue(themeDD, currentTheme);
	UIDropDownMenu_SetText(themeDD, currentTheme);

	local function UpdateThemeVisibility()
		local on = C.UnitFrameCustomTexture and true or false;
		if on then
			UIDropDownMenu_EnableDropDown(themeDD);
			themeLabel:SetAlpha(1);
		else
			UIDropDownMenu_DisableDropDown(themeDD);
			themeLabel:SetAlpha(0.4);
		end
	end
	K._UpdateThemeVisibility = UpdateThemeVisibility;
	UpdateThemeVisibility();

	gY = gY - 34;
	CreateCheckBox(paneGen, L["CB_CLASS_COLOR"],    "classColor",        xL, gY); gY = gY - 27;
	CreateCheckBox(paneGen, L["CB_BACKDROP"],       "statusbarBackdrop", xL, gY); gY = gY - 27;
	CreateCheckBox(paneGen, L["CB_HEALTH_PCT"],     "HealthPercentage",  xL, gY); gY = gY - 27;


	CreateCheckBox(paneGen, L["CB_ERROR_HIDE"] or "Hide Errors in Combat",
		"ErrorHideInCombat", xL, gY);


	gY = gY - 40;
	SectionHeader(paneGen, L["HEADER_NAME_COLOR"] or "Name Color", xL, gY);

	gY = gY - 24;
	do
		local modes = {
			{ value = "Default", text = L["NAME_COLOR_DEFAULT"] or "Default" },
			{ value = "White",   text = L["NAME_COLOR_WHITE"]   or "White"   },
			{ value = "Class",   text = L["NAME_COLOR_CLASS"]   or "Class"   },
		};
		local btnW, btnH, gap = 76, 22, 4;
		local nameButtons = {};

		local container = CreateFrame("Frame", nil, paneGen);
		container:SetPoint("TOPLEFT", xL + 2, gY);
		container:SetSize((#modes * btnW) + ((#modes - 1) * gap), btnH);

		local function RefreshNameButtons()
			local current = C.UnitNameColorMode or "Default";
			for _, b in ipairs(nameButtons) do
				if b.value == current then
					b:SetBackdropColor(0.10, 0.35, 0.60, 0.90);
					b:SetBackdropBorderColor(0.35, 0.70, 1.00, 0.95);
					b.labelFS:SetTextColor(1, 1, 1);
				else
					b:SetBackdropColor(0.07, 0.07, 0.07, 0.65);
					b:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.60);
					b.labelFS:SetTextColor(0.55, 0.55, 0.55);
				end
			end
		end

		for i, opt in ipairs(modes) do
			local b = CreateFrame("Button", nil, container);
			b:SetSize(btnW, btnH);
			b:SetPoint("LEFT", container, "LEFT", (i - 1) * (btnW + gap), 0);
			b:SetBackdrop({
				bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile     = true, tileSize = 16, edgeSize = 12,
				insets   = { left = 3, right = 3, top = 3, bottom = 3 },
			});
			local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
			fs:SetPoint("CENTER", b, "CENTER", 0, 0);
			fs:SetText(opt.text);
			b.labelFS = fs;
			b.value   = opt.value;

			b:SetScript("OnClick", function(self)
				K.SaveConfig("UnitNameColorMode", self.value);
				RefreshNameButtons();
				if K.ApplyUnitNameColorNow then K.ApplyUnitNameColorNow(); end
			end);
			b:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(opt.text, 1, 1, 1);
				GameTooltip:AddLine(L["TIP_UnitNameColorMode"] or "", nil, nil, nil, true);
				GameTooltip:Show();
			end);
			b:SetScript("OnLeave", function() GameTooltip:Hide(); end);

			table.insert(nameButtons, b);
		end
		RefreshNameButtons();
	end


	do
		local borderOpts = {
			{ value = "None",    text = L["NAME_BORDER_NONE"]    or "None" },
			{ value = "Outline", text = L["NAME_BORDER_OUTLINE"] or "Outline" },
			{ value = "Thick",   text = L["NAME_BORDER_THICK"]   or "Thick Outline" },
			{ value = "Shadow",  text = L["NAME_BORDER_SHADOW"]  or "Like health / mana text" },
		};
		local function OptText(v)
			for _, o in ipairs(borderOpts) do if o.value == v then return o.text; end end
			return v;
		end

		gY = gY - 34;
		local borderLabel = paneGen:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		borderLabel:SetPoint("TOPLEFT", xL + 2, gY - 4);
		borderLabel:SetText((K.UI and K.UI.Label(L["NAME_BORDER"] or "Name border"))
			or (L["NAME_BORDER"] or "Name border"));

		dropdownCount = dropdownCount + 1;
		local borderDD = CreateFrame("Frame", "NidhausUFDropdown" .. dropdownCount, paneGen, "UIDropDownMenuTemplate");
		borderDD:SetPoint("LEFT", borderLabel, "RIGHT", 4, -2);
		UIDropDownMenu_SetWidth(borderDD, 150);
		UIDropDownMenu_Initialize(borderDD, function(self, level)
			for _, opt in ipairs(borderOpts) do
				local info = UIDropDownMenu_CreateInfo();
				info.text  = opt.text;
				info.value = opt.value;
				info.func  = function(btn)
					UIDropDownMenu_SetSelectedValue(borderDD, btn.value);
					UIDropDownMenu_SetText(borderDD, OptText(btn.value));
					if K.SaveConfig then K.SaveConfig("UnitNameBorder", btn.value); end
					if K.ApplyUnitNameColorNow then K.ApplyUnitNameColorNow(); end
				end;
				info.checked = (opt.value == (C.UnitNameBorder or "None"));
				UIDropDownMenu_AddButton(info, level);
			end
		end);
		UIDropDownMenu_SetSelectedValue(borderDD, C.UnitNameBorder or "None");
		UIDropDownMenu_SetText(borderDD, OptText(C.UnitNameBorder or "None"));
	end







	local coBody;
	if K.Modules and K.Modules["ClassOutline"] then
		gY = gY - 44;
		SectionHeader(paneGen, L["HEADER_CLASS_INDICATORS"] or "Class Colored Indicators", xL, gY);

		gY = gY - 26;
		checkboxCount = checkboxCount + 1;
		local coName = "NidhausUFCheckBox" .. checkboxCount;
		local coCB = CreateFrame("CheckButton", coName, paneGen, "InterfaceOptionsCheckButtonTemplate");
		coCB:SetPoint("TOPLEFT", xL, gY);
		coCB:SetHitRectInsets(0, 0, 0, 0);
		local coFS = _G[coName .. "Text"];
		if coFS then coFS:SetText(L["MOD_CLASSOUTLINE"] or "Class Colored Outlines"); end
		coCB:SetChecked(K.IsModuleEnabled and K.IsModuleEnabled("ClassOutline") or false);
		coCB:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MOD_CLASSOUTLINE"] or "Class Colored Outlines", 1, 1, 1);
			GameTooltip:AddLine(L["MOD_CLASSOUTLINE_DESC"] or "", nil, nil, nil, true);
			GameTooltip:Show();
		end);
		coCB:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		coCB:SetScript("OnClick", function(self)
			local v = (self:GetChecked() == 1 or self:GetChecked() == true);
			if K.SetModuleEnabled then K.SetModuleEnabled("ClassOutline", v); end
			if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("ClassOutline"); end
		end);
		if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox("ClassOutline", coCB); end




		gY = gY - 30;
		coBody = K.UI.Collapsible(paneGen, xL + 8, gY, 210, 46, function()
			return K.IsModuleEnabled and K.IsModuleEnabled("ClassOutline");
		end);

		local coSlider = CreateFrame("Slider", "NidhausClassOutlineSizeSlider", coBody,
			"OptionsSliderTemplate");
		coSlider:SetPoint("TOPLEFT", 0, 0);
		coSlider:SetWidth(190);
		coSlider:SetMinMaxValues(40, 90);
		coSlider:SetValueStep(1);
		local coStart = (K.GetClassOutlineSize and K.GetClassOutlineSize()) or 62;
		coSlider:SetValue(coStart);
		_G[coSlider:GetName() .. "Low"]:SetText("40");
		_G[coSlider:GetName() .. "High"]:SetText("90");
		_G[coSlider:GetName() .. "Text"]:SetText(L["SLIDER_OUTLINE_SIZE"] or "Ring size");
		coSlider:SetScript("OnValueChanged", function(self, v)
			v = math.floor(v + 0.5);
			if K.SetClassOutlineSize then K.SetClassOutlineSize(v); end
		end);

		coCB:HookScript("OnClick", function() coBody:Refresh(); end);
	end




	local utilHdr = paneGen:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	if coBody then
		utilHdr:SetPoint("TOPLEFT", coBody, "BOTTOMLEFT", -8, -26);
	else
		gY = gY - 44;
		utilHdr:SetPoint("TOPLEFT", xL, gY);
	end
	utilHdr:SetText((K.UI and K.UI.Header(K.UI.Strip(L["HEADER_UTILITY"] or "Utility")))
		or (L["HEADER_UTILITY"] or "Utility"));

	local utilBox = CreateFrame("Frame", nil, paneGen);
	utilBox:SetPoint("TOPLEFT", utilHdr, "BOTTOMLEFT", 0, -6);
	utilBox:SetWidth(240);
	utilBox:SetHeight(106);

	CreateCheckBox(utilBox, L["CB_AUTO_SELL"] or "Auto Sell Gray Items", "AutoSellGray", 0, 0);
	CreateCheckBox(utilBox, L["CB_AUTO_REPAIR"] or "Auto Repair", "AutoRepair", 0, -26);
	CreateCheckBox(utilBox, L["CB_BLOCK_DUELS"] or "Decline Duels", "BlockDuels", 0, -52);
	CreateCheckBox(utilBox, L["CB_TAB_BINDER"] or "Tab targets enemy players in PvP",
		"TabBinderEnabled", 0, -78);
	gY = gY - 140;




	SectionHeader(paneGen, L["HEADER_FRAMES_MIRROR"] or "Unit Frames", xR, rY);



	rY = rY - 28;
	if K.CreateCustomPosCheckbox then
		K.CreateCustomPosCheckbox(paneGen, xR, rY);
	end

	rY = rY - 30;
	local cb3v3Gen = CreateFrame("CheckButton", "NidhausGeneralMirror3v3CB", paneGen, "UICheckButtonTemplate");
	cb3v3Gen:SetPoint("TOPLEFT", xR, rY);
	cb3v3Gen.text = cb3v3Gen:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb3v3Gen.text:SetPoint("LEFT", cb3v3Gen, "RIGHT", 4, 0);
	cb3v3Gen.text:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3");
	cb3v3Gen:SetChecked(C.PartyMode3v3 and true or false);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyMode3v3", cb3v3Gen); end
	if K.Register3v3Checkbox then K.Register3v3Checkbox(cb3v3Gen); end
	cb3v3Gen:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3", 1, 1, 1);
		GameTooltip:AddLine(L["TIP_PartyMode3v3"] or "", nil, nil, nil, true);
		GameTooltip:Show();
	end);
	cb3v3Gen:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	cb3v3Gen:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SaveConfig then K.SaveConfig("PartyMode3v3", v); end
		if v then
			if K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
		else
			if K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
		end
		if K.Update3v3SlidersVisibility then K.Update3v3SlidersVisibility(); end
		if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
		if K.ScheduleGlobalPositionReapply then K.ScheduleGlobalPositionReapply(); end
	end);




	rY = rY - 44;
	SectionHeader(paneGen, L["HEADER_STATUS_TEXT"] or "Status Text", xR, rY);
	rY = rY - 26;


	local fullValueCB = CreateCheckBox(paneGen, L["CB_FULL_VALUE"] or "Current value only (no /max)",
		"ShowCurrentValueOnly", xR, rY);
	K._FullValueCB = fullValueCB;

	rY = rY - 28;
	local abbrevCB = CreateModuleCB(paneGen, L["CB_ABBREV_STATUS"] or "Abbreviated health / mana text",
		"AbbreviatedStatus", xR, rY, L["TIP_ABBREV_STATUS"]);
	local abbrevBody;
	if abbrevCB then






		abbrevBody = K.UI.Collapsible(paneGen, xR + 26, rY - 22, 200, 24, function()
			return (K.IsModuleEnabled and K.IsModuleEnabled("AbbreviatedStatus")) or false;
		end);

		local abbrevBtn = CreateFrame("Button", nil, abbrevBody, "UIPanelButtonTemplate");
		abbrevBtn:SetSize(80, 20);
		abbrevBtn:SetPoint("TOPLEFT", 0, 0);
		abbrevBtn:SetText(L["BTN_MODULE_OPEN"] or "Open");
		abbrevBtn:SetScript("OnClick", function()



			if not (K.IsModuleEnabled and K.IsModuleEnabled("AbbreviatedStatus")) then return; end
			if K.OpenAbbreviatedStatusMenu then K.OpenAbbreviatedStatusMenu(); end
		end);
		rY = rY - 28;
	end
	K._AbbrevCB = abbrevCB;




	local function SyncStatusTextExclusive()
		local full   = C.ShowCurrentValueOnly and true or false;
		local abbrev = (K.IsModuleEnabled and K.IsModuleEnabled("AbbreviatedStatus")) or false;
		local fv, ab = K._FullValueCB, K._AbbrevCB;
		if fv then










			fv:SetChecked(full);
			if abbrev then fv:Disable(); else fv:Enable(); end
			fv:SetAlpha(abbrev and 0.4 or 1);
		end
		if ab then
			ab:SetChecked(abbrev);
			if full then ab:Disable(); else ab:Enable(); end
			ab:SetAlpha(full and 0.4 or 1);
		end




		if abbrevBody then abbrevBody:Refresh(); end
	end
	K._SyncStatusTextExclusive = SyncStatusTextExclusive;
	paneGen:HookScript("OnShow", SyncStatusTextExclusive);
	if abbrevCB then abbrevCB:HookScript("OnClick", SyncStatusTextExclusive); end
	SyncStatusTextExclusive();
	rY = rY - 6;










	local function BigThemeOK()
		return C.UnitFrameCustomTexture == true and not C.AsuriFrames;
	end
	local bigWrap = K.UI.Collapsible(paneGen, xR, rY, 300, 156, BigThemeOK);
	CreateCheckBox(bigWrap, L["CB_BIG_TEXT"] or "Big text (name above the frame)", "BigStatusText", 0, 0);

	local bigSizeBody = K.UI.Collapsible(bigWrap, 22, -28, 278, 128, function()
		return C.BigStatusText and true or false;
	end);
	CreateCheckBox(bigSizeBody, L["CB_BIG_TEXT_SIZE"] or "Custom text size", "BigTextCustomSize", 0, 0);

	local bigSliderBody = K.UI.Collapsible(bigSizeBody, 0, -46, 278, 82, function()
		return C.BigTextCustomSize and true or false;
	end);
	local bigHP = CreateSlider(bigSliderBody, L["SLIDER_BIG_TEXT_HP"] or "Health text",
		"BigTextHealthSize", 8, 16, 1, 4, 0);
	local bigMP = CreateSlider(bigSliderBody, L["SLIDER_BIG_TEXT_MP"] or "Mana text",
		"BigTextManaSize", 8, 16, 1, 146, 0);
	for _, s in ipairs({ bigHP, bigMP }) do
		s:SetWidth(122);

		s:HookScript("OnValueChanged", function()
			if K.RefreshBigStatusFonts then K.RefreshBigStatusFonts(); end
		end);
	end

	local function RefreshBigTextBody()
		bigWrap:Refresh();
		bigSizeBody:Refresh();
		bigSliderBody:Refresh();
	end
	K._RefreshBigTextBody = RefreshBigTextBody;



	local prevThemeVis = K._UpdateThemeVisibility;
	K._UpdateThemeVisibility = function(...)
		if prevThemeVis then prevThemeVis(...); end
		RefreshBigTextBody();
	end
	RefreshBigTextBody();
	rY = rY - 156;


	sideUI.SetContentHeight(1, math.min(gY, rY) - 40);


	local bY = -14;
	SectionHeader(paneBars, L["HEADER_BAR_STYLE"] or "Bar Style", xL, bY);

	bY = bY - 24;
	CreateCheckBox(paneBars, L["CB_UNIFY_ACTIONBARS"], "UnifyActionBars", xL, bY); bY = bY - 26;
	CreateCheckBox(paneBars, L["CB_MINIBAR"] or "MiniBar", "MiniBarEnabled", xL, bY); bY = bY - 26;
	CreateCheckBox(paneBars, L["CB_MINIBAR_NO_BG"] or "Hide bar background",
		"MiniBarHideBackground", xL + 16, bY);
	local miniBgCB = checkboxes[#checkboxes]; bY = bY - 26;
	local function UpdateMiniBgVisibility()
		if not miniBgCB then return; end
		if C.MiniBarEnabled == true then miniBgCB:Show(); else miniBgCB:Hide(); end
	end
	K._UpdateMiniBgVisibility = UpdateMiniBgVisibility;
	UpdateMiniBgVisibility();
	CreateCheckBox(paneBars, L["CB_HIDE_GRYPHONS"] or "Hide Gryphons", "HideGryphons", xL, bY); bY = bY - 26;
	CreateCheckBox(paneBars, L["CB_BAGPACK"] or "BagPack Background", "ShowBagPackTexture", xL, bY);
	local bagpackCheckbox = checkboxes[#checkboxes];

	local function UpdateBagPackCheckboxVisibility()
		local anyBarActive = K.IsAnyBarModeActive and K.IsAnyBarModeActive()
			or (C.UnifyActionBars == true) or (C.MiniBarEnabled == true);
		if anyBarActive then bagpackCheckbox:Show(); else bagpackCheckbox:Hide(); end
	end
	K._UpdateBagPackVisibility = UpdateBagPackCheckboxVisibility;
	UpdateBagPackCheckboxVisibility();

	bY = bY - 26;
	local hideTexCB = CreateModuleCB(paneBars, L["CB_HIDE_BAR_TEXTURES"] or "Hide Action Bar Textures",
		"HideActionBarTextures", xL, bY, L["TIP_HideBarTextures"]);


	local function UpdateHideTexVisibility()
		if not hideTexCB then return; end
		local anyBarActive = (C.UnifyActionBars == true) or (C.MiniBarEnabled == true);
		if anyBarActive then hideTexCB:Hide(); else hideTexCB:Show(); end
	end
	K._UpdateHideTexVisibility = UpdateHideTexVisibility;
	UpdateHideTexVisibility();




	bY = bY - 46;
	local btnSpaceSlider = CreateSlider(paneBars, L["SLIDER_BUTTON_SPACE"] or "Buttons space",
		"ActionBarButtonSpace", 0, 20, 1, xL + 4, bY);
	btnSpaceSlider:HookScript("OnValueChanged", function()
		if K.ApplyActionBarButtonSpace then K.ApplyActionBarButtonSpace(); end
	end);

	local function UpdateButtonSpaceVisibility()
		local anyBarActive = (C.UnifyActionBars == true) or (C.MiniBarEnabled == true);
		if anyBarActive then btnSpaceSlider:Show(); else btnSpaceSlider:Hide(); end
	end
	K._UpdateButtonSpaceVisibility = UpdateButtonSpaceVisibility;
	UpdateButtonSpaceVisibility();





	local xBarR = 300;
	local bT = -14;
	SectionHeader(paneBars, L["HEADER_BAR_TEXT"] or "Text and Feedback", xBarR, bT);

	bT = bT - 24;
	CreateModuleCB(paneBars, L["CB_BUTTON_RANGE"] or "Button Range", "ButtonRange",
		xBarR, bT, L["TIP_ButtonRange"]);
	bT = bT - 26;
	CreateCheckBox(paneBars, L["CB_HIDE_KEYBIND"] or "Hide Keybind Text", "HideKeybindText", xBarR, bT);
	bT = bT - 26;
	CreateCheckBox(paneBars, L["CB_HIDE_MACRO"] or "Hide Macro Names", "HideMacroText", xBarR, bT);


	bT = bT - 26;
	do
		CreateCheckBox(paneBars, L["CB_SIDEBARS_HOVER"] or "Show side bars on mouseover",
			"SideBarsHover", xBarR, bT);
		local cb = checkboxes[#checkboxes];
		cb:HookScript("OnClick", function()
			if K.ApplySideBarHover then K.ApplySideBarHover(); end
		end);
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["CB_SIDEBARS_HOVER"] or "Show side bars on mouseover", 1, 1, 1);
			GameTooltip:AddLine(L["TIP_SideBarsHover"]
				or "The right side bars stay hidden and only appear when the mouse is over them. They still work while hidden.",
				nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end


	bY = bY - 46;
	SectionHeader(paneBars, L["HEADER_BAR_SIZE"] or "Size", xL, bY);
	bY = bY - 34;
	local abScaleSlider = CreateSlider(paneBars,
		L["SLIDER_ACTIONBAR_SCALE"] or "Action Bar Scale",
		"ActionBarScale", 0.65, 1.14, 0.01, xL, bY);
	abScaleSlider:SetWidth(210);




	bY = bY - 60;
	SectionHeader(paneBars, L["HEADER_BAR_MOVE"] or "Position", xL, bY);
	bY = bY - 20;

	SectionNote(paneBars, L["NOTE_BAR_MOVE"]
		or "Turns on move mode: drag the blue box to place the action bars. Click again to lock and save.",
		xL + 2, bY, 262);

	bY = bY - 34;
	local barMoveBtn = CreateFrame("Button", nil, paneBars, "UIPanelButtonTemplate");
	barMoveBtn:SetPoint("TOPLEFT", xL + 2, bY);
	barMoveBtn:SetSize(170, 22);
	barMoveBtn:SetText(L["BTN_MOVE_BARS"] or "Move action bars");
	barMoveBtn:SetScript("OnClick", function(self)
		if not K.ToggleGlobalUnlock then return; end
		K.ToggleGlobalUnlock("extra");
		local on = K.IsGlobalUnlocked and K.IsGlobalUnlocked();
		self:SetText(on and (L["BTN_LOCK_BARS"] or "Lock bars")
			or (L["BTN_MOVE_BARS"] or "Move action bars"));
	end);

	local barResetBtn = CreateFrame("Button", nil, paneBars, "UIPanelButtonTemplate");
	barResetBtn:SetPoint("LEFT", barMoveBtn, "RIGHT", 8, 0);
	barResetBtn:SetSize(100, 22);
	barResetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
	barResetBtn:SetScript("OnClick", function()









		if K.ResetActionBars then K.ResetActionBars(); end
	end);



	sideUI.SetContentHeight(2, math.min(bY, bT) - 60);


	local mmY = -14;
	SectionHeader(paneMap, L["HEADER_MINIMAP_SHAPE"] or "Shape", xL, mmY);

	mmY = mmY - 24;
	do
		local shapes = {
			{ value = false, text = L["MINIMAP_ROUND"]  or "Round" },
			{ value = true,  text = L["MINIMAP_SQUARE"] or "Square" },
		};
		local btnW, btnH, gap = 86, 22, 4;
		local shapeButtons = {};

		local container = CreateFrame("Frame", nil, paneMap);
		container:SetPoint("TOPLEFT", xL + 2, mmY);
		container:SetSize((#shapes * btnW) + ((#shapes - 1) * gap), btnH);

		local function RefreshShape()
			local current = C.MinimapSquare and true or false;
			for _, b in ipairs(shapeButtons) do
				if b.value == current then
					b:SetBackdropColor(0.10, 0.35, 0.60, 0.90);
					b:SetBackdropBorderColor(0.35, 0.70, 1.00, 0.95);
					b.labelFS:SetTextColor(1, 1, 1);
				else
					b:SetBackdropColor(0.07, 0.07, 0.07, 0.65);
					b:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.60);
					b.labelFS:SetTextColor(0.55, 0.55, 0.55);
				end
			end
		end

		for i, opt in ipairs(shapes) do
			local b = CreateFrame("Button", nil, container);
			b:SetSize(btnW, btnH);
			b:SetPoint("LEFT", container, "LEFT", (i - 1) * (btnW + gap), 0);
			b:SetBackdrop({
				bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile     = true, tileSize = 16, edgeSize = 12,
				insets   = { left = 3, right = 3, top = 3, bottom = 3 },
			});
			local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
			fs:SetPoint("CENTER", b, "CENTER", 0, 0);
			fs:SetText(opt.text);
			b.labelFS = fs;
			b.value   = opt.value;
			b:SetScript("OnClick", function(self)
				K.SaveConfig("MinimapSquare", self.value);
				RefreshShape();
				if K.ApplyMinimapSettings then K.ApplyMinimapSettings(); end


				if K._UpdateBorderNote then K._UpdateBorderNote(); end
			end);
			table.insert(shapeButtons, b);
		end
		RefreshShape();
	end


	local function MinimapCB(label, setting, y, tip)
		CreateCheckBox(paneMap, label, setting, xL, y, tip);
		local cb = checkboxes[#checkboxes];
		cb:HookScript("OnClick", function()
			if K.ApplyMinimapSettings then K.ApplyMinimapSettings(); end
		end);
		return cb;
	end






	mmY = mmY - 40;
	SectionHeader(paneMap, L["HEADER_MINIMAP_BORDER"] or "Border", xL, mmY);

	mmY = mmY - 30;
	do
		local opts = {
			{ text = L["MINIMAP_BORDER_DEFAULT"]  or "Default",  value = "Default"  },
			{ text = L["MINIMAP_BORDER_LIGHT"]    or "Light",    value = "Light"    },
			{ text = L["MINIMAP_BORDER_TOOLTIP"]  or "Tooltip",  value = "Tooltip"  },
			{ text = L["MINIMAP_BORDER_THIN"]     or "Thin",     value = "Thin"     },
			{ text = L["MINIMAP_BORDER_FLAT"]     or "Flat",     value = "Flat"     },






			{ text = L["MINIMAP_BORDER_LORTI"] or "Lorti UI", value = "Lorti" },
		};







		if K.SyncLortiMinimap then pcall(K.SyncLortiMinimap); end

		local borderDD = CreateDropdown(paneMap, L["DD_MINIMAP_BORDER"] or "Border style",
			"MinimapBorderStyle", opts, xL, mmY, function(value)






				local wantLorti = (value == "Lorti");
				if (C.LortiUI_Minimap == true) ~= wantLorti then
					C.LortiUI_Minimap = wantLorti;
					if K.SaveConfig then K.SaveConfig("LortiUI_Minimap", wantLorti); end
					if K.RefreshLortiSubOptions then pcall(K.RefreshLortiSubOptions); end
				end

				if K.ApplyMinimapSettings then K.ApplyMinimapSettings(); end
				if K._UpdateBorderNote then K._UpdateBorderNote(); end
			end);



		mmY = mmY - 46;
		local note = SectionNote(paneMap, "", xL + 2, mmY, 260);
		local function UpdateBorderNote()
			if not note then return; end
			local style = C.MinimapBorderStyle or "Default";
			if style == "Light" and C.MinimapSquare ~= true then
				note:SetText("|cffFFD100" .. (L["NOTE_MINIMAP_BORDER_SQUARE"]
					or "Light only works with the square shape.") .. "|r");
			else
				note:SetText("|cff8EAEC9" .. (L["NOTE_MINIMAP_BORDER"]
					or "Tooltip, Thin, Flat and Blizzard work with both shapes.") .. "|r");
			end
		end
		K._UpdateBorderNote = UpdateBorderNote;
		UpdateBorderNote();



		K.RefreshMinimapBorderDropdown = function()
			local dd = borderDD and borderDD.dropdown;
			if not dd then return; end
			local v = (K.GetMinimapBorderStyle and K.GetMinimapBorderStyle())
				or C.MinimapBorderStyle or "Default";
			local text = v;
			for _, o in ipairs(opts) do if o.value == v then text = o.text; end end
			UIDropDownMenu_SetSelectedValue(dd, v);
			UIDropDownMenu_SetText(dd, text);
			UpdateBorderNote();
		end
	end

	mmY = mmY - 44;
	SectionHeader(paneMap, L["HEADER_MINIMAP_DECOR"] or "Decorations", xL, mmY);

	mmY = mmY - 24;
	MinimapCB(L["CB_MINIMAP_HIDE_ZONE"]    or "Hide Zone Name",      "MinimapHideZone",   mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_HIDE_ZONEBG"]  or "Hide Zone Name Background", "MinimapHideZoneBG", mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_HIDE_CLOCK"]    or "Hide Clock",          "MinimapHideClock",    mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_HIDE_ZOOM"]     or "Hide Zoom Buttons",   "MinimapHideZoom",     mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_HIDE_CALENDAR"] or "Hide Calendar",       "MinimapHideCalendar", mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_HIDE_WORLDMAP"] or "Hide World Map",      "MinimapHideWorldMap", mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_WHEEL"]         or "Mouse Wheel Zoom",    "MinimapWheelZoom",    mmY);







	local mmR = -14;
	SectionHeader(paneMap, L["HEADER_MINIMAP_ICONS"] or "Addon Icons", xR, mmR);

	mmR = mmR - 26;
	do













		if C.MinimapAddonIcons == nil or C.MinimapAddonIcons == "" then
			local v = "Always";
			if C.MinimapIconsOnHover == true then v = "Hover";
			elseif C.MinimapHideAddonIcons == true then v = "Never"; end
			C.MinimapAddonIcons = v;
			if K.SaveConfig then K.SaveConfig("MinimapAddonIcons", v); end
		end

		local iconBoxes = {};
		local function RefreshIconBoxes()
			local cur = C.MinimapAddonIcons or "Always";
			for _, b in ipairs(iconBoxes) do b:SetChecked(b.value == cur); end
		end

		local function IconModeCB(label, value, y)
			checkboxCount = checkboxCount + 1;
			local name = "NidhausUFCheckBox" .. checkboxCount;
			local cb = CreateFrame("CheckButton", name, paneMap, "InterfaceOptionsCheckButtonTemplate");
			cb:SetPoint("TOPLEFT", xR, y);
			cb:SetHitRectInsets(0, 0, 0, 0);
			local fs = _G[name .. "Text"];
			if fs then fs:SetText(label); end
			cb.value = value;
			cb:SetScript("OnClick", function(self)


				if K.SaveConfig then K.SaveConfig("MinimapAddonIcons", self.value); end
				C.MinimapAddonIcons = self.value;
				RefreshIconBoxes();
				if K.ApplyMinimapIconState then K.ApplyMinimapIconState(); end
			end);
			iconBoxes[#iconBoxes + 1] = cb;
		end

		IconModeCB(L["MINIMAP_ICONS_ALWAYS"] or "Always",       "Always", mmR); mmR = mmR - 24;
		IconModeCB(L["MINIMAP_ICONS_HOVER"]  or "On mouseover", "Hover",  mmR); mmR = mmR - 24;
		IconModeCB(L["MINIMAP_ICONS_NEVER"]  or "Never",        "Never",  mmR);
		RefreshIconBoxes();
	end




	mmR = mmR - 36;
	CreateModuleCB(paneMap, L["MOD_MINIMAP_TOGGLE"] or "Minimap Icon Toggle",
		"MinimapIconToggle", xR, mmR, L["MOD_MINIMAP_TOGGLE_DESC"]);

	mmR = mmR - 30;
	SectionNote(paneMap, L["NOTE_MINIMAP_ICONS"]
		or "A small button on the minimap corner to hide the icons on the fly. It only hides, so with Never it has nothing to do.",
		xR + 2, mmR, 230);
	mmR = mmR - 22;

	mmR = mmR - 52;
	SectionHeader(paneMap, L["HEADER_MINIMAP_SIZE"] or "Size", xR, mmR);
	mmR = mmR - 30;
	local mapScale = CreateSlider(paneMap, L["SLIDER_MINIMAP_SCALE"] or "Minimap Scale",
		"MinimapScale", 0.6, 1.6, 0.05, xR, mmR);
	mapScale:SetWidth(210);
	mapScale:HookScript("OnMouseUp", function()
		if K.ApplyMinimapScale then K.ApplyMinimapScale(); end
	end);
	mapScale:HookScript("OnValueChanged", function()
		if K.ApplyMinimapScale then K.ApplyMinimapScale(); end
	end);


	sideUI.SetContentHeight(3, math.min(mmY, mmR) - 60);


	local cY = -14;
	SectionHeader(paneChat, L["HEADER_CHAT"] or "Chat", xL, cY);

	cY = cY - 24;
	CreateCheckBox(paneChat, L["CB_CHAT_COPY"] or "Copy Chat Text", "ChatCopyEnabled",
		xL, cY, L["TIP_ChatCopyEnabled"]);
	cY = cY - 26;
	CreateCheckBox(paneChat, L["CB_CHAT_URLS"] or "Clickable Links", "ChatClickableURLs",
		xL, cY, L["TIP_ChatClickableURLs"]);
	cY = cY - 26;
	CreateModuleCB(paneChat, L["CB_HIDE_CHAT_BUTTON"] or "Hide Chat Buttons",
		"HideChatButton", xL, cY, L["TIP_HideChatButton"]);
	cY = cY - 26;
	CreateModuleCB(paneChat, L["MOD_SYSTEM_SPAM"] or "Hide system spam",
		"SystemSpamFilter", xL, cY, L["MOD_SYSTEM_SPAM_DESC"]
			or "Removes system chat spam: other people's duel results, drunk messages and 'you have learned' lines.");

	sideUI.SetContentHeight(4, cY - 40);




	local kY = -14;
	SectionHeader(paneCast, L["HEADER_CASTBAR"] or "Cast Bar", xL, kY);

	kY = kY - 24;
	CreateCheckBox(paneCast, L["CB_CASTING_TIMERS"], "CastingTimers", xL, kY);

	kY = kY - 34;
	K.UI.Separator(paneCast, xL, kY, 440);


	kY = kY - 18;
	local castPWCB = CreateCheckBox(paneCast, L["CB_CASTBAR_PW"] or "Custom Cast Bar",
		"CastBarPWEnabled", xL, kY);

	kY = kY - 26;
	SectionNote(paneCast, L["NOTE_CASTBAR_PW"] or "", xL + 24, kY, 400);

	kY = kY - 44;
	local castIconCB = CreateCheckBox(paneCast, L["CB_CASTBAR_PW_ICON"] or "Show spell icon",
		"CastBarPWIcon", xL + 16, kY);

	kY = kY - 26;
	local castDarkCB = CreateCheckBox(paneCast, L["CB_CASTBAR_PW_DARK"] or "Dark border",
		"CastBarPWDark", xL + 16, kY);



	kY = kY - 26;
	local castTargetCB = CreateCheckBox(paneCast, L["CB_CASTBAR_PW_TARGET"] or "Apply to target",
		"CastBarPWTarget", xL + 16, kY);

	kY = kY - 26;
	local castFocusCB = CreateCheckBox(paneCast, L["CB_CASTBAR_PW_FOCUS"] or "Apply to focus",
		"CastBarPWFocus", xL + 16, kY);

	kY = kY - 42;
	local castIconSlider = CreateSlider(paneCast, L["SLIDER_CASTBAR_PW_SIZE"] or "Icon Size",
		"CastBarPWIconSize", 18, 48, 1, xL + 20, kY);
	castIconSlider:HookScript("OnValueChanged", function()
		if K.ApplyCastBarPW then K.ApplyCastBarPW(); end
	end);







	kY = kY - 56;
	local focusBarSlider = CreateSlider(paneCast, L["SLIDER_FOCUS_SPELLBAR"] or "Focus Cast Bar Scale",
		"FocusSpellBarScale", 0.5, 1.5, 0.05, xL + 20, kY);
	focusBarSlider:HookScript("OnValueChanged", function(self, value)
		if K.ApplyFocusSpellBarScale then K.ApplyFocusSpellBarScale(value); end
	end);

	kY = kY - 56;
	local castScaleSlider = CreateSlider(paneCast, L["SLIDER_CASTBAR_PW_SCALE"] or "Cast Bar Scale",
		"CastBarPWScale", 0.5, 2.0, 0.05, xL + 20, kY);
	castScaleSlider:HookScript("OnValueChanged", function(self, value)




		if K.ApplyCastBarPWScale then K.ApplyCastBarPWScale(value); end
	end);



	function K.RefreshCastBarScaleSlider()
		local v = C.CastBarPWScale;
		if type(v) ~= "number" then return; end
		if castScaleSlider:GetValue() ~= v then
			castScaleSlider:SetValue(v);
		end
	end



	local function UpdateCastBarVisibility()
		local on = C.CastBarPWEnabled and true or false;
		for _, obj in ipairs({ castIconCB, castDarkCB, castTargetCB, castFocusCB,
			castIconSlider, castScaleSlider }) do
			if on then obj:Enable(); else obj:Disable(); end
			obj:SetAlpha(on and 1 or 0.4);
		end

		if on and C.CastBarPWIcon == false then
			castIconSlider:Disable();
			castIconSlider:SetAlpha(0.4);
		end
	end
	K._UpdateCastBarVisibility = UpdateCastBarVisibility;
	UpdateCastBarVisibility();



	castPWCB:HookScript("OnClick", UpdateCastBarVisibility);

	sideUI.SetContentHeight(5, kY - 70);




	local tY = -14;
	SectionHeader(paneTip, L["HEADER_TOOLTIP"] or "Tooltip", xL, tY);

	tY = tY - 26;
	CreateCheckBox(paneTip, L["CB_TOOLTIP_ARENA_EXP"] or "Arena experience",
		"TooltipArenaExp", xL, tY);

	tY = tY - 24;
	SectionNote(paneTip, L["NOTE_TOOLTIP_ARENA_EXP"] or "", xL + 24, tY, 420);

	tY = tY - 46;
	CreateCheckBox(paneTip, L["CB_TOOLTIP_TALENTS"] or "Show talents",
		"TooltipTalents", xL, tY);

	tY = tY - 24;
	SectionNote(paneTip, L["NOTE_TOOLTIP_TALENTS"] or "", xL + 24, tY, 420);

	tY = tY - 46;
	CreateCheckBox(paneTip, L["CB_TOOLTIP_QUALITY"] or "Item quality border",
		"TooltipQualityBorder", xL, tY);

	tY = tY - 24;
	SectionNote(paneTip, L["NOTE_TOOLTIP_QUALITY"] or "", xL + 24, tY, 420);

	tY = tY - 34;
	CreateCheckBox(paneTip, L["CB_TOOLTIP_ICONS"] or "Show tooltip icons",
		"TooltipIcons", xL, tY, L["TIP_TooltipIcons"]);
	tY = tY - 24;
	SectionNote(paneTip, L["NOTE_TOOLTIP_ICONS"] or "", xL + 24, tY, 420);

	sideUI.SetContentHeight(6, tY - 60);


	local vY = -14;
	SectionHeader(paneMove, L["HEADER_MOVE_ALL"] or "Move Everything", xL, vY);

	vY = vY - 22;
	SectionNote(paneMove, L["DESC_MOVE_ALL"] or "", xL + 2, vY, 430);

	vY = vY - 48;
	local unlockAllBtn = CreateFrame("Button", nil, paneMove, "UIPanelButtonTemplate");
	unlockAllBtn:SetPoint("TOPLEFT", xL + 2, vY);
	unlockAllBtn:SetSize(200, 24);
	unlockAllBtn:SetText(L["BTN_MOVE_ALL"] or "Unlock Everything");
	unlockAllBtn:SetScript("OnClick", function(self)
		if not K.ToggleGlobalUnlock then return; end
		K.ToggleGlobalUnlock("all");
		if K.IsGlobalUnlocked and K.IsGlobalUnlocked() then
			self:SetText(L["BTN_MOVE_ALL_DONE"] or "Lock All Frames");
		else
			self:SetText(L["BTN_MOVE_ALL"] or "Unlock Everything");
		end
	end);

	local unlockAllReset = CreateFrame("Button", nil, paneMove, "UIPanelButtonTemplate");
	unlockAllReset:SetPoint("LEFT", unlockAllBtn, "RIGHT", 8, 0);
	unlockAllReset:SetSize(120, 24);
	unlockAllReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
	unlockAllReset:SetScript("OnClick", function()


		if K.ResetEverything then K.ResetEverything();
		elseif K.ResetGlobalPositions then K.ResetGlobalPositions(); end
	end);




	vY = vY - 34;
	local gridLbl = paneMove:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	gridLbl:SetPoint("TOPLEFT", xL + 2, vY);
	gridLbl:SetText(L["LBL_MOVE_GRID"] or "Grid");

	local gridNote = paneMove:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	gridNote:SetPoint("TOPLEFT", xL + 2, vY - 42);
	gridNote:SetWidth(430);
	gridNote:SetJustifyH("LEFT");
	gridNote:SetText("|cff8EAEC9" .. (L["DESC_MOVE_GRID"]
		or "Frames snap to a grid while you drag them, so lining two of them up is easy. Smaller steps move more freely.") .. "|r");

	local gridBtns = {};
	local function RefreshGridButtons()
		local cur = (C and C.MoveGridStep) or 10;
		for step, b in pairs(gridBtns) do

			if step == cur then b:LockHighlight(); else b:UnlockHighlight(); end
		end
	end

	local gx = xL + 50;
	for _, step in ipairs({ 2, 5, 10 }) do
		local b = CreateFrame("Button", nil, paneMove, "UIPanelButtonTemplate");
		b:SetPoint("TOPLEFT", gx, vY + 4);
		b:SetSize(52, 22);
		b:SetText("x" .. step);
		b:SetScript("OnClick", function()



			local cur  = (C and C.MoveGridStep) or 10;
			local want = (cur == step) and 0 or step;
			if K.SaveConfig then K.SaveConfig("MoveGridStep", want); end
			RefreshGridButtons();
			if K.RefreshMoveConsoleGrid then pcall(K.RefreshMoveConsoleGrid); end
		end);
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("x" .. step, 1, 1, 1);
			GameTooltip:AddLine(string.format(L["TIP_MOVE_GRID"]
				or "Cells of %d pixels a side.", step), nil, nil, nil, true);
			GameTooltip:Show();
		end);
		b:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		gridBtns[step] = b;
		gx = gx + 58;
	end
	RefreshGridButtons();
	K._RefreshMoveGridButtons = RefreshGridButtons;


	vY = vY - 92;
	K.UI.Separator(paneMove, xL, vY + 12, 440);






	vY = vY - 8;
	if K.CreateCustomPosCheckbox then
		K.CreateCustomPosCheckbox(paneMove, xL, vY);
	end

	vY = vY - 30;
	local cb3v3General = CreateFrame("CheckButton", "NidhausGeneral3v3CB", paneMove, "UICheckButtonTemplate");
	cb3v3General:SetPoint("TOPLEFT", xL, vY);
	cb3v3General.text = cb3v3General:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb3v3General.text:SetPoint("LEFT", cb3v3General, "RIGHT", 4, 0);
	cb3v3General.text:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3");
	cb3v3General:SetChecked(C.PartyMode3v3 and true or false);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyMode3v3", cb3v3General); end
	if K.Register3v3Checkbox then K.Register3v3Checkbox(cb3v3General); end
	cb3v3General:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3", 1, 1, 1);
		GameTooltip:AddLine(L["TIP_PartyMode3v3"] or "", nil, nil, nil, true);
		GameTooltip:Show();
	end);
	cb3v3General:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	cb3v3General:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SaveConfig then K.SaveConfig("PartyMode3v3", v); end
		if v then
			if K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
		else
			if K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
		end
		if K.Update3v3SlidersVisibility then K.Update3v3SlidersVisibility(); end
		if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
		if K.ScheduleGlobalPositionReapply then K.ScheduleGlobalPositionReapply(); end
	end);


	sideUI.SetContentHeight(9, vY - 50);


	if K.BuildPvPSection then
		sideUI.SetContentHeight(7, K.BuildPvPSection(panePvP) - 30);
	end


	if K.BuildClassSection then
		sideUI.SetContentHeight(8, K.BuildClassSection(paneClass) - 30);
	end




	if K.PopulateFramesTab then K.PopulateFramesTab(tabPanels[2]); end




	if K.PopulateArenaTab then
		showArenaBtn = K.PopulateArenaTab(tabPanels[3]);
	end






	local panel4 = tabPanels[4];



	local allIds = (K.GetAddonTabIds and K.GetAddonTabIds()) or {};

	local addonScroll = CreateFrame("ScrollFrame", "NidhausAddonsScroll", panel4, "UIPanelScrollFrameTemplate");
	addonScroll:SetPoint("TOPLEFT", 6, -6);
	addonScroll:SetPoint("BOTTOMRIGHT", -28, 6);

	local addonPane = CreateFrame("Frame", "NidhausAddonsScrollChild", addonScroll);
	addonPane:SetWidth(560);
	addonPane:SetHeight(1);
	addonScroll:SetScrollChild(addonPane);

	local moduleCount = 0;
	K._moduleContainers = {};

	local function UpdateModulesScrollHeight()
		local total = 10;
		for _, id in ipairs(allIds) do
			local ct = K._moduleContainers[id];
			if ct then total = total + ct:GetHeight(); end
		end
		addonPane:SetHeight(total + 40);
	end
	K.UpdateModulesScrollHeight = UpdateModulesScrollHeight;

	do
		local pane = addonPane;
		local prevContainer = nil;

		for _, id in ipairs(allIds) do
			local mod = K.Modules[id];
			if mod and not mod.hideFromModulesTab then
				moduleCount   = moduleCount + 1;
				checkboxCount = checkboxCount + 1;

				local container = CreateFrame("Frame", "NidhausModuleContainer_"..id, pane);
				container:SetWidth(548);






				if prevContainer then
					local sep = container:CreateTexture(nil, "ARTWORK");
					sep:SetTexture(1, 1, 1, 0.07);
					sep:SetPoint("TOPLEFT", container, "TOPLEFT", 6, 2);
					sep:SetPoint("TOPRIGHT", container, "TOPRIGHT", -6, 2);
					sep:SetHeight(1);
				end
				if prevContainer then
					container:SetPoint("TOPLEFT", prevContainer, "BOTTOMLEFT", 0, 0);
				else
					container:SetPoint("TOPLEFT", 6, -8);
				end

				local cbName = "NidhausUFModuleCB"..moduleCount;
				local check  = CreateFrame("CheckButton", cbName, container,
					"InterfaceOptionsCheckButtonTemplate");
				check:SetPoint("TOPLEFT", 6, 0);
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
					if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox(id); end
				end);
				if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox(id, check); end

				if mod.configFunc then
					local cfgBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate");






					cfgBtn:SetSize(90, 20);
					cfgBtn:SetPoint("TOPRIGHT", container, "TOPRIGHT", -10, -1);
					cfgBtn:SetText(mod.configLabel or (L["BTN_MODULE_CONFIG"] or "Configure"));


					if K.RegisterModuleConfigButton then K.RegisterModuleConfigButton(id, cfgBtn); end
					cfgBtn:SetScript("OnClick", function()
						local ok, err = pcall(mod.configFunc);
						if not ok then print("|cffFF0000NUF:|r " .. tostring(err)); end
					end);
					local function RefreshCfgBtn()
						if K.IsModuleEnabled(id) then
							cfgBtn:Enable(); cfgBtn:SetAlpha(1);
						else
							cfgBtn:Disable(); cfgBtn:SetAlpha(0.4);
						end
					end
					RefreshCfgBtn();
					check:HookScript("OnClick", RefreshCfgBtn);
				end

				local baseHeight = 0;
				if mod.desc and mod.desc ~= "" then
					local descText = container:CreateFontString(nil, "ARTWORK",
						"GameFontHighlightSmall");
					descText:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 26, 2);
					descText:SetText("|cff888888"..mod.desc.."|r");

					descText:SetWidth(mod.configFunc and 400 or 500);
					descText:SetJustifyH("LEFT");











					local h = descText:GetStringHeight() or 12;
					baseHeight = 26 + h + 6;
					if baseHeight < 40 then baseHeight = 40; end
				else
					baseHeight = 28;
				end

				local subUIHeight = 0;
				container._collapsed = false;








				local autoScaleH = 0;
				if K.IsScalable and K.IsScalable(id) and K.UI and K.UI.ScaleSlider then
					local sc = K.UI.ScaleSlider(container, id, 30, -baseHeight - 14, 180);
					if sc then
						container._autoScale = sc;
						autoScaleH = 52;
					end
				end

				if mod.createUI then
					local beforeChildren = {};
					for _, child in pairs({container:GetChildren()}) do
						beforeChildren[child] = true;
					end
					local beforeRegions = {};
					for _, region in pairs({container:GetRegions()}) do
						beforeRegions[region] = true;
					end

					subUIHeight = mod.createUI(container, -baseHeight - autoScaleH, check) or 0;

					container._subUIAll = {};
					for _, child in pairs({container:GetChildren()}) do
						if not beforeChildren[child] then
							table.insert(container._subUIAll, child);
						end
					end
					for _, region in pairs({container:GetRegions()}) do
						if not beforeRegions[region] then
							table.insert(container._subUIAll, region);
						end
					end

					if type(subUIHeight) ~= "number" or subUIHeight < 0 then
						subUIHeight = 0;
					end

					if subUIHeight > 100 then
						local subUIElements = container._subUIAll;

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

				local function UpdateContainerState()
					local on = K.IsModuleEnabled(id);
					if container._subUIAll then
						for _, elem in ipairs(container._subUIAll) do
							if on and not container._collapsed then
								if elem.Show then elem:Show(); end
							else
								if elem.Hide then elem:Hide(); end
							end
						end
					end



					local scaleH = 0;
					if container._autoScale then
						if on and not container._collapsed then
							container._autoScale:Show();
							scaleH = autoScaleH;
						else
							container._autoScale:Hide();
						end
					end

					local h = baseHeight + scaleH;
					if not (container._collapsed or not on or subUIHeight <= 0) then
						h = h + subUIHeight;
					end
					container:SetHeight(h);
					if K.UpdateModulesScrollHeight then K.UpdateModulesScrollHeight(); end
				end
				container._UpdateState = UpdateContainerState;
				check:HookScript("OnClick", UpdateContainerState);
				UpdateContainerState();

				K._moduleContainers[id] = container;
				prevContainer = container;
			end
		end

		if not prevContainer then
			local empty = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
			empty:SetPoint("TOPLEFT", 10, -10);
			empty:SetText("|cff888888" .. (L["MODULES_NONE"] or "No addons in this group yet.") .. "|r");
		end
	end

	UpdateModulesScrollHeight();




	if K.PopulateExtraTab then K.PopulateExtraTab(tabPanels[5]); end


	if K.PopulateAboutTab then K.PopulateAboutTab(tabPanels[6]); end
end




local function CreateBottomButtons()








	local function FooterAlpha()
		local t = K.GetActiveTheme and K.GetActiveTheme();
		return (t and t.footerAlpha) or 0.75;
	end

	local function MakeSecondary(btn)
		btn:SetAlpha(FooterAlpha());
		btn:HookScript("OnEnter", function(self) self:SetAlpha(1); end);
		btn:HookScript("OnLeave", function(self) self:SetAlpha(FooterAlpha()); end);
		secondaryButtons[#secondaryButtons + 1] = btn;
	end

	local reloadButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	reloadButton:SetPoint("BOTTOMLEFT", 20, 18);
	reloadButton:SetSize(104, 22);
	reloadButton:SetText(L["BTN_RELOAD"]);
	reloadButton:SetScript("OnClick", function() ReloadUI(); end);
	MakeSecondary(reloadButton);

	local resetButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	resetButton:SetPoint("LEFT", reloadButton, "RIGHT", 8, 0);
	resetButton:SetSize(114, 22);
	resetButton:SetText(L["BTN_RESET"]);
	resetButton:SetScript("OnClick", function()
		StaticPopup_Show("NIDHAUS_RESET_CONFIRM");
	end);
	MakeSecondary(resetButton);











	local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	closeButton:SetPoint("BOTTOMRIGHT", -20, 18);
	closeButton:SetSize(120, 25);
	closeButton:SetText(L["BTN_CLOSE"]);
	closeButton:SetScript("OnClick", function() mainFrame:Hide(); end);









	local profilesButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	profilesButton:SetPoint("LEFT", resetButton, "RIGHT", 8, 0);
	profilesButton:SetText(L["TAB_PROFILES"] or "Profiles");



	do
		local fs = profilesButton:GetFontString();
		local w  = (fs and fs:GetStringWidth() or 0) + 26;
		if w < 100 then w = 100; end
		profilesButton:SetSize(w, 22);
	end
	MakeSecondary(profilesButton);
	profilesButton:SetScript("OnClick", function()
		if K.SelectPanelTab then K.SelectPanelTab(5); end
	end);







	local aboutButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	aboutButton:SetPoint("LEFT", profilesButton, "RIGHT", 8, 0);
	aboutButton:SetSize(100, 22);
	aboutButton:SetText(L["TAB_ABOUT"] or "About");
	MakeSecondary(aboutButton);
	aboutButton:SetScript("OnClick", function()
		if K.SelectPanelTab then K.SelectPanelTab(6); end
	end);











	local moveBox = CreateFrame("Button", "NUF_MoveEverythingBox", mainFrame);
	moveBox:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 20, 50);
	moveBox:SetSize(158, 24);
	moveBox:SetFrameLevel(mainFrame:GetFrameLevel() + 3);
	moveBox:EnableMouse(true);

	local mbBg = moveBox:CreateTexture(nil, "ARTWORK");
	mbBg:SetTexture("Interface\\Buttons\\WHITE8X8");
	mbBg:SetAllPoints(moveBox);
	mbBg:SetVertexColor(0.03, 0.08, 0.20, 0.95);

	local MB_BW = 1;
	local function MBEdge()
		local t = moveBox:CreateTexture(nil, "OVERLAY");
		t:SetTexture("Interface\\Buttons\\WHITE8X8");
		return t;
	end
	local mbTop   = MBEdge();
	mbTop:SetPoint("TOPLEFT", moveBox, "TOPLEFT", 0, 0);
	mbTop:SetPoint("TOPRIGHT", moveBox, "TOPRIGHT", 0, 0);
	mbTop:SetHeight(MB_BW);
	local mbBot   = MBEdge();
	mbBot:SetPoint("BOTTOMLEFT", moveBox, "BOTTOMLEFT", 0, 0);
	mbBot:SetPoint("BOTTOMRIGHT", moveBox, "BOTTOMRIGHT", 0, 0);
	mbBot:SetHeight(MB_BW);
	local mbLeft  = MBEdge();
	mbLeft:SetPoint("TOPLEFT", moveBox, "TOPLEFT", 0, 0);
	mbLeft:SetPoint("BOTTOMLEFT", moveBox, "BOTTOMLEFT", 0, 0);
	mbLeft:SetWidth(MB_BW);
	local mbRight = MBEdge();
	mbRight:SetPoint("TOPRIGHT", moveBox, "TOPRIGHT", 0, 0);
	mbRight:SetPoint("BOTTOMRIGHT", moveBox, "BOTTOMRIGHT", 0, 0);
	mbRight:SetWidth(MB_BW);

	local mbLabel = moveBox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	mbLabel:SetPoint("CENTER", moveBox, "CENTER", 0, 0);
	mbLabel:SetText("|cff4fc3f7" .. (L["SIDE_MOVEALL"] or "Move Everything") .. "|r");

	local function MoveBoxRest()
		mbBg:SetVertexColor(0.03, 0.08, 0.20, 0.95);
		mbTop:SetVertexColor(0.30, 0.65, 1.00, 1.00);
		mbBot:SetVertexColor(0.25, 0.55, 0.90, 0.80);
		mbLeft:SetVertexColor(0.25, 0.55, 0.90, 0.80);
		mbRight:SetVertexColor(0.25, 0.55, 0.90, 0.80);
	end
	MoveBoxRest();

	moveBox:SetScript("OnEnter", function()
		mbTop:SetVertexColor(0.60, 0.85, 1.00, 1.00);
		mbBot:SetVertexColor(0.60, 0.85, 1.00, 1.00);
		mbLeft:SetVertexColor(0.60, 0.85, 1.00, 1.00);
		mbRight:SetVertexColor(0.60, 0.85, 1.00, 1.00);
	end);
	moveBox:SetScript("OnLeave", MoveBoxRest);
	moveBox:SetScript("OnClick", function()
		mainFrame:Hide();
		if K.ToggleGlobalUnlock then K.ToggleGlobalUnlock(); end
	end);


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




local function InitializePanel()
	CreateMainFrame();
	CreateTabs();





	local built = false;
	mainFrame:HookScript("OnShow", function()
		if built then return; end
		built = true;
		local ok, err = pcall(PopulateTabs);
		if not ok then
			print("|cffFF0000NUF:|r error armando el panel: " .. tostring(err));
		end



		if K.UI and K.UI.RestyleSliders then
			pcall(K.UI.RestyleSliders, mainFrame);
		end
		if K.LoadSavedTheme then pcall(K.LoadSavedTheme); end
	end);

	CreateBottomButtons();


	local themeButtons = CreateThemeSwitcher();

	if K.RegisterThemeFrames then
		K.RegisterThemeFrames({
			mainFrame    = mainFrame,
			titleBox     = titleBoxRef,
			tabBar       = tabBarRef,
			tabs         = tabs,
			tabPanels    = tabPanels,
			themeButtons = themeButtons,
			secondaryButtons = secondaryButtons,
		});
	end


	if K.LoadSavedTheme then
		K.LoadSavedTheme();
	end
end













if IsLoggedIn and IsLoggedIn() then
	InitializePanel();
else
	local initFrame = CreateFrame("Frame");
	initFrame:RegisterEvent("PLAYER_LOGIN");
	initFrame:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_LOGIN" then
			self:UnregisterEvent("PLAYER_LOGIN");
			InitializePanel();
		end
	end);
end

SLASH_NUFCONFIG1 = "/nufconfig";
SLASH_NUFCONFIG2 = "/nufoptions";

SlashCmdList["NUFCONFIG"] = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "");
	if msg == "db" or msg == "database" then
		K.ShowConfig();
	elseif msg == "reset" or msg == "size" then

		if K.ResetOptionsPanelSize then
			K.ResetOptionsPanelSize();
			print("|cff4FC3F7NUF:|r " .. (L["PANEL_SIZE_RESET"]
				or "Ventana de opciones restaurada a 820x620 y centrada."));
			if mainFrame and not mainFrame:IsShown() then mainFrame:Show(); end
		end
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