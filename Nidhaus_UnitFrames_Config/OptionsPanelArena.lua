



local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);

local flatSubControls = {};
local castBarSubControls = {};
local castBarBody;
local petStyleControls = {};
local arenaShowBtn;
local arenaTestRow;
local dropdownCount = 0;
local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;

local tooltips = {
	ArenaFrameOn            = "TIP_ArenaFrameOn",
	ArenaFrameScale         = "TIP_ArenaFrameScale",
	ArenaFrameSpacing       = "TIP_ArenaFrameSpacing",
	ArenaMirrorMode         = "TIP_ArenaMirrorMode",
	ArenaFrame_Trinkets     = "TIP_ArenaFrame_Trinkets",
	ArenaFrame_Trinket_Voice = "TIP_ArenaFrame_Trinket_Voice",
	ArenaFlatWidth          = "TIP_ArenaFlatWidth",
	ArenaFlatHealthBarHeight = "TIP_ArenaFlatHealthBarHeight",
	ArenaFlatPowerBarHeight = "TIP_ArenaFlatPowerBarHeight",
	ArenaFlatHealthFontSize = "TIP_ArenaFlatHealthFontSize",
	ArenaFlatPowerFontSize  = "TIP_ArenaFlatPowerFontSize",
	ArenaFlatMirrored       = "TIP_ArenaFlatMirrored",
	ArenaFlatStatusText     = "TIP_ArenaFlatStatusText",
	ArenaToTSquare          = "TIP_ArenaToTSquare",
	ArenaCastBarEnable      = "TIP_ArenaCastBarEnable",
	ArenaCastBarScale       = "TIP_ArenaCastBarScale",
	ArenaCastBarWidth       = "TIP_ArenaCastBarWidth",
	ShadowSightTimer        = "TIP_ShadowSightTimer",
	ArenaDR                 = "TIP_ArenaDR",
	ArenaDoTWarn            = "TIP_ArenaDoTWarn",
	ArenaDRSize             = "TIP_ArenaDRSize",
	ArenaDRSpacing          = "TIP_ArenaDRSpacing",
	ArenaDRBorder           = "TIP_ArenaDRBorder",
	ArenaDRText             = "TIP_ArenaDRText",
	ArenaDRTimer            = "TIP_ArenaDRTimer",
	ArenaDRClassOnly        = "TIP_ArenaDRClassOnly",
	ArenaPetFrameShow       = "TIP_ArenaPetFrameShow",
	ArenaDoTSize            = "TIP_ArenaDoTSize",
	ArenaDoTSpacing         = "TIP_ArenaDoTSpacing",
	ArenaDoTMax             = "TIP_ArenaDoTMax",
	ArenaDoTLabel           = "TIP_ArenaDoTLabel",
	ArenaDoTBorder          = "TIP_ArenaDoTBorder",
};

local function AddTooltip(frame, setting)
	local tipKey = tooltips[setting];
	if not tipKey then return; end
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(setting, 1, 1, 1);
		GameTooltip:AddLine(L[tipKey] or tipKey, nil, nil, nil, true);
		GameTooltip:Show();
	end);
	frame:SetScript("OnLeave", function() GameTooltip:Hide(); end);
end




local function CreateCheckBox(parent, label, setting, xOffset, yOffset)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate");
	cb:SetPoint("TOPLEFT", xOffset, yOffset);
	cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0);
	cb.text:SetText(label);
	cb:SetChecked(C[setting] or false);
	AddTooltip(cb, setting);

	cb:SetScript("OnClick", function(self)
		local checked = self:GetChecked() == 1 or self:GetChecked() == true;
		K.SaveConfig(setting, checked);
		if setting == "ArenaFrameOn" then


			if K._UpdateArenaOptionsVisibility then K._UpdateArenaOptionsVisibility(); end
			if arenaShowBtn then
				if checked then arenaShowBtn:Show(); else arenaShowBtn:Hide(); end
			end
			if arenaTestRow then
				if checked then arenaTestRow:Show(); else arenaTestRow:Hide(); end
			end

			if checked then
				if K.EnableArenaFrameMod then K.EnableArenaFrameMod(); end
			else
				if K.DisableArenaFrameMod then K.DisableArenaFrameMod(); end
			end
		elseif setting == "ArenaFlatMirrored" then
			if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
		elseif setting == "ArenaFlatStatusText" then
			if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
		elseif setting == "ArenaToTSquare" or setting == "ArenaToTMirrored" then
			if K.RefreshArenaToTLayout then K.RefreshArenaToTLayout(); end
		elseif setting == "ArenaCastBarEnable" then
			if K.ToggleArenaCastBar then K.ToggleArenaCastBar(checked); end



			if castBarBody then castBarBody:Refresh(); end
			if K._UpdateArenaLowerHeight then K._UpdateArenaLowerHeight(); end
			if K._RefreshArenaLayout then K._RefreshArenaLayout(); end
		elseif setting == "ArenaMirrorMode" then
			if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
			if K.RefreshArenaDRLayout then K.RefreshArenaDRLayout(); end
			if K.RefreshArenaDoTLayout then K.RefreshArenaDoTLayout(); end
		elseif setting == "ShadowSightTimer" then
			if K.ApplyShadowSightSetting then K.ApplyShadowSightSetting(); end
		elseif setting == "ArenaDR" then
			if K.ToggleArenaDR then K.ToggleArenaDR(); end
			if K._UpdateDRPreviewBtn then K._UpdateDRPreviewBtn(); end
		elseif setting == "ArenaDRBorder" or setting == "ArenaDRText" or setting == "ArenaDRTimer"
			or setting == "ArenaDRClassOnly" then
			if K.RefreshArenaDRLayout then K.RefreshArenaDRLayout(); end
		elseif setting == "ArenaDoTWarn" then
			if K.ToggleArenaDoTWarn then K.ToggleArenaDoTWarn(); end
			if K._UpdateDoTPreviewBtn then K._UpdateDoTPreviewBtn(); end
		elseif setting == "ArenaDoTLabel" or setting == "ArenaDoTBorder" then
			if K.RefreshArenaDoTLayout then K.RefreshArenaDoTLayout(); end
		elseif setting == "ArenaFrame_Trinkets" then
			if K.ToggleArenaTrinketsTracking then K.ToggleArenaTrinketsTracking(checked); end
		elseif setting == "ArenaFrame_Trinket_Voice" then

		elseif setting == "ArenaPetFrameShow" then





			if K.RefreshArenaTestPets then K.RefreshArenaTestPets(); end
		elseif setting == "ArenaFlatPetStyle" then
			if checked then
				if K.RefreshArenaTestPets then K.RefreshArenaTestPets(); end
				if K.ApplyFlatPetFrames then K.ApplyFlatPetFrames(); end
			elseif K.RemoveAllFlatPetStyles then
				K.RemoveAllFlatPetStyles();
			end
		end
	end);
	return cb;
end




local function FormatSliderValue(step, value)
	if step >= 1 then
		return string.format("%d", value);
	elseif step >= 0.1 then
		return string.format("%.1f", value);
	else
		return string.format("%.2f", value);
	end
end






local function CreateSlider(parent, label, setting, minVal, maxVal, step, xOffset, yOffset)
	local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate");
	slider:SetPoint("TOPLEFT", xOffset, yOffset);
	slider:SetWidth(160);
	slider:SetMinMaxValues(minVal, maxVal);
	slider:SetValueStep(step);
	slider:SetValue(C[setting] or minVal);
	slider.setting = setting;



	K.UI.SliderEnds(slider, FormatSliderValue(step, minVal), FormatSliderValue(step, maxVal));


	local title = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	title:SetPoint("BOTTOM", slider, "TOP", 0, 3);
	title:SetText(label);


	slider.ValueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	slider.ValueText:SetPoint("TOP", slider, "BOTTOM", 0, -2);
	slider.ValueText:SetText(FormatSliderValue(step, C[setting] or minVal));



	AddTooltip(slider, setting);

	slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value / step + 0.5) * step;
		self:SetValue(value);
		slider.ValueText:SetText(FormatSliderValue(step, value));
		K.SaveConfig(setting, value);

		if setting == "ArenaFrameScale" then
			if K.ApplyArenaScale then K.ApplyArenaScale(value); end
		elseif setting == "ArenaFrameSpacing" then
			if C.ArenaFrameOn and K.ApplyArenaSpacing then K.ApplyArenaSpacing(); end
		elseif setting == "ArenaFlatWidth" or setting == "ArenaFlatHealthBarHeight"
			or setting == "ArenaFlatPowerBarHeight" or setting == "ArenaFlatHealthFontSize"
			or setting == "ArenaFlatPowerFontSize" then
			if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
		elseif setting == "ArenaCastBarScale" then
			if K.UpdateArenaCastBarScale then K.UpdateArenaCastBarScale(value); end
		elseif setting == "ArenaCastBarWidth" then
			if K.UpdateArenaCastBarWidth then K.UpdateArenaCastBarWidth(value); end
		elseif setting == "ArenaDRSize" or setting == "ArenaDRSpacing" then
			if K.RefreshArenaDRLayout then K.RefreshArenaDRLayout(); end
		elseif setting == "ArenaDoTSize" or setting == "ArenaDoTSpacing" or setting == "ArenaDoTMax" then
			if K.RefreshArenaDoTLayout then K.RefreshArenaDoTLayout(); end
		end
	end);

	return slider;
end




local function CreateDropdown(parent, labelText, setting, options, xOff, yOff, onChange)
	dropdownCount = dropdownCount + 1;
	local ddName = "NidhausArenaDD"..dropdownCount;

	local container = CreateFrame("Frame", nil, parent);
	container:SetPoint("TOPLEFT", xOff or 20, yOff);
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
			info.text = opt.text;
			info.value = opt.value;
			info.func = function(btn)
				UIDropDownMenu_SetSelectedValue(dd, btn.value);
				UIDropDownMenu_SetText(dd, btn.value);
				K.SaveConfig(setting, btn.value);
				if onChange then onChange(btn.value); end
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




local function CreateSeparator(parent, xOffset, yOffset, width)
	local sep = parent:CreateTexture(nil, "ARTWORK");
	sep:SetTexture(1, 1, 1, 0.3);
	sep:SetPoint("TOPLEFT", xOffset, yOffset);
	sep:SetSize(width or 530, 1);
	return sep;
end






function K.PopulateArenaTab(panel)








	local sub = K.CreateSideList(panel, {
		{ name = L["SUBTAB_ARENA_FRAMES"]  or "Frames" },
		{ name = L["SUBTAB_ARENA_OPTIONS"] or "Options" },
		{ name = L["SUBTAB_ARENA_DR"]      or "DR" },
		{ name = L["SUBTAB_ARENA_DOT"]     or "DoT" },
		{ name = L["SUBTAB_ARENA_POINTS"]  or "Arena Calculator" },
	});

	local paneFrames  = sub[1];

	local paneModules = sub[2];
	local paneTimers  = sub[2];

	local paneDR      = sub[3];
	local paneDoT     = sub[4];
	local panePoints  = sub[5];

	local fCol1 = 30;
	local fCol2 = 285;


	local function CreateModuleCheckBox(parent, label, moduleId, xOffset, yOffset, tipText)
		local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate");
		cb:SetPoint("TOPLEFT", xOffset, yOffset);
		cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0);
		cb.text:SetText(label);
		cb:SetChecked(K.IsModuleEnabled and K.IsModuleEnabled(moduleId) or false);

		if tipText then
			cb:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(label, 1, 1, 1);
				GameTooltip:AddLine(tipText, nil, nil, nil, true);
				GameTooltip:Show();
			end);
			cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		end

		cb:SetScript("OnClick", function(self)
			local checked = self:GetChecked() == 1 or self:GetChecked() == true;
			if K.SetModuleEnabled then K.SetModuleEnabled(moduleId, checked); end
			if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox(moduleId); end











			if moduleId == "ArenaPointsCalc" and K._RefreshArenaPointsBlock then
				K._RefreshArenaPointsBlock();
			end
		end);

		if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox(moduleId, cb); end
		return cb;
	end








	local content = paneFrames;

	local moveHint = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	moveHint:SetPoint("TOPLEFT", 20, -100);
	moveHint:SetText(L["ARENA_MOVE_HINT"] or "|cffFFAA00\226\128\160Shift+Alt+Click to move various elements|r");

	local yPos = -12;
	CreateCheckBox(content, L["CB_ARENA_ON"], "ArenaFrameOn", 20, yPos);








	arenaTestRow = CreateFrame("Frame", nil, content);
	arenaTestRow:SetPoint("TOPLEFT", 20, yPos - 34);
	arenaTestRow:SetSize(420, 24);


	arenaShowBtn = arenaTestRow;

	local testLbl = arenaTestRow:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	testLbl:SetPoint("LEFT", 2, 0);
	testLbl:SetText(L["ARENA_TEST_LABEL"] or "Preview:");

	local function TestShownCount()
		local db = NidhausUnitFramesDB;
		if db and db.ArenaMover and db.ArenaMover.IsShown then
			return (K.GetArenaTestCount and K.GetArenaTestCount()) or 3;
		end
		return nil;
	end

	local countBtns = {};
	local hideTestBtn;

	local function RefreshTestButtons()
		local live = IsActiveBattlefieldArena and IsActiveBattlefieldArena();
		local shown = TestShownCount();
		for n, btn in pairs(countBtns) do
			if live then
				btn:Disable(); btn:SetAlpha(0.5);
			else
				btn:Enable(); btn:SetAlpha(1.0);
			end
			if shown == n and not live then
				btn:LockHighlight();
				btn:SetNormalFontObject("GameFontHighlight");
			else
				btn:UnlockHighlight();
				btn:SetNormalFontObject("GameFontNormal");
			end
		end
		if hideTestBtn then
			if shown and not live then
				hideTestBtn:Enable(); hideTestBtn:SetAlpha(1.0);
			else
				hideTestBtn:Disable(); hideTestBtn:SetAlpha(0.5);
			end
		end
	end

	local bx = 104;
	for _, n in ipairs({ 2, 3, 5 }) do
		local btn = CreateFrame("Button", nil, arenaTestRow, "UIPanelButtonTemplate");
		btn:SetPoint("LEFT", bx, 0);
		btn:SetSize(56, 22);
		btn:SetText(n .. "v" .. n);
		btn:SetScript("OnClick", function()
			if TestShownCount() == n then
				if K.ClearArenaTestFrames then K.ClearArenaTestFrames(); end
			elseif K.SetArenaTestCount then
				K.SetArenaTestCount(n);
			end
			RefreshTestButtons();
		end);
		btn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(n .. "v" .. n, 1, 1, 1);
			GameTooltip:AddLine(string.format(L["ARENA_TEST_TIP"]
				or "Shows %d test frames. Click it again to hide them.", n), nil, nil, nil, true);
			GameTooltip:Show();
		end);
		btn:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		countBtns[n] = btn;
		bx = bx + 60;
	end

	hideTestBtn = CreateFrame("Button", nil, arenaTestRow, "UIPanelButtonTemplate");
	hideTestBtn:SetPoint("LEFT", bx + 10, 0);
	hideTestBtn:SetSize(80, 22);
	hideTestBtn:SetText(L["BTN_ARENA_TEST_CLEAR"] or "Hide");
	hideTestBtn:SetScript("OnClick", function()
		if K.ClearArenaTestFrames then K.ClearArenaTestFrames(); end
		RefreshTestButtons();
	end);




	if type(K.SetTrinketMouseState) == "function" then
		hooksecurefunc(K, "SetTrinketMouseState", function() RefreshTestButtons(); end);
	end
	arenaTestRow:SetScript("OnShow", RefreshTestButtons);
	local btnEvt = CreateFrame("Frame");
	btnEvt:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	btnEvt:RegisterEvent("PLAYER_ENTERING_WORLD");
	btnEvt:SetScript("OnEvent", function() RefreshTestButtons(); end);
	RefreshTestButtons();
	if not C.ArenaFrameOn then arenaTestRow:Hide(); end




	local petShowCB = CreateCheckBox(content, L["CB_PET_FRAME_SHOW"] or "Show pets in Test mode",
		"ArenaPetFrameShow", 20, yPos - 62);



	local arenaHint = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	arenaHint:SetPoint("TOPLEFT", 280, yPos - 2);
	arenaHint:SetWidth(270);
	arenaHint:SetJustifyH("LEFT");
	arenaHint:SetText(L["ARENA_HINT_INLINE"]
		or "|cff00FFFF/nuf arena|r does the same from chat, and inside an arena it lets you move the frames.");


	local styleSep = CreateSeparator(content, 14, -118, 540);
	local styleHead = content:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	styleHead:SetPoint("TOPLEFT", 20, -126);
	styleHead:SetText("|cffFFD100" .. (L["HEADER_ARENA_STYLE_SIZE"] or "Style and size") .. "|r");
	local styleStartY = -148;

	local styleOptions = {
		{text = "Blizzard", value = "Blizzard"},
		{text = "Custom",   value = "Custom"},





		{text = L["ARENA_STYLE_COMPACT"] or "Borderless", value = "Compact"},


		{text = L["ARENA_STYLE_COMPACT2"] or "Compact", value = "Compact2"},
		{text = "Flat",     value = "Flat"},
	};



	local scaleS = CreateSlider(content, L["SLIDER_ARENA_SCALE"],
		"ArenaFrameScale", 0.5, 2.0, 0.1, fCol1, styleStartY - 76);
	scaleS:SetWidth(200);

	local spaceS = CreateSlider(content, L["SLIDER_ARENA_SPACING"],
		"ArenaFrameSpacing", 0, 100, 5, fCol2, styleStartY - 76);
	spaceS:SetWidth(200);


	local flatAnchorY = styleStartY - 118;

	local flatWrapper = CreateFrame("Frame", "NidhausArenaFlatWrapper", content);
	flatWrapper:SetPoint("TOPLEFT", 14, flatAnchorY);
	flatWrapper:SetWidth(530);

	local fY = 0;

	local flatSep = flatWrapper:CreateTexture(nil, "ARTWORK");
	flatSep:SetTexture(1, 1, 1, 0.15);
	flatSep:SetPoint("TOPLEFT", 20, fY);
	flatSep:SetSize(500, 1);
	fY = fY - 10;

	local flatW = CreateSlider(flatWrapper, L["SLIDER_FLAT_WIDTH_FULL"] or L["SLIDER_FLAT_WIDTH"],
		"ArenaFlatWidth", 40, 400, 10, fCol1, fY);
	flatW:SetWidth(200); flatW.setting = "ArenaFlatWidth";
	table.insert(flatSubControls, flatW);

	local resetBtn = CreateFrame("Button", nil, flatWrapper, "UIPanelButtonTemplate");
	resetBtn:SetPoint("TOPLEFT", fCol1 + 250, fY + 2);
	resetBtn:SetSize(60, 22);
	resetBtn:SetText(L["BTN_RESET_FLAT"] or "Reset");
	resetBtn:SetScript("OnClick", function()
		local defs = {
			ArenaFlatWidth = 120, ArenaFlatHealthBarHeight = 20,
			ArenaFlatPowerBarHeight = 8, ArenaFlatHealthFontSize = 9,
			ArenaFlatPowerFontSize = 9, ArenaFlatMirrored = false,
			ArenaFlatStatusText = true,
		};
		for k, v in pairs(defs) do K.SaveConfig(k, v); C[k] = v; end
		for _, ctrl in ipairs(flatSubControls) do
			if ctrl.SetValue and ctrl.setting and C[ctrl.setting] ~= nil then
				ctrl:SetValue(C[ctrl.setting]);
				if ctrl.ValueText then
					ctrl.ValueText:SetText(FormatSliderValue(ctrl:GetValueStep() or 1, C[ctrl.setting]));
				end
			end
			if ctrl.SetChecked then ctrl:SetChecked(false); end
		end
		if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
	end);
	table.insert(flatSubControls, resetBtn);

	fY = fY - 55;
	local flatHB = CreateSlider(flatWrapper, L["SLIDER_FLAT_HB_HEIGHT_FULL"] or L["SLIDER_FLAT_HB_HEIGHT"],
		"ArenaFlatHealthBarHeight", 1, 50, 1, fCol1, fY);
	flatHB:SetWidth(130); flatHB.setting = "ArenaFlatHealthBarHeight";
	table.insert(flatSubControls, flatHB);

	local flatPB = CreateSlider(flatWrapper, L["SLIDER_FLAT_PB_HEIGHT_FULL"] or L["SLIDER_FLAT_PB_HEIGHT"],
		"ArenaFlatPowerBarHeight", 1, 50, 1, fCol2, fY);
	flatPB:SetWidth(130); flatPB.setting = "ArenaFlatPowerBarHeight";
	table.insert(flatSubControls, flatPB);

	fY = fY - 55;
	local flatHF = CreateSlider(flatWrapper, L["SLIDER_FLAT_HB_FONT_FULL"] or L["SLIDER_FLAT_HB_FONT"],
		"ArenaFlatHealthFontSize", 0, 50, 1, fCol1, fY);
	flatHF:SetWidth(130); flatHF.setting = "ArenaFlatHealthFontSize";
	table.insert(flatSubControls, flatHF);

	local flatPF = CreateSlider(flatWrapper, L["SLIDER_FLAT_PB_FONT_FULL"] or L["SLIDER_FLAT_PB_FONT"],
		"ArenaFlatPowerFontSize", 0, 50, 1, fCol2, fY);
	flatPF:SetWidth(130); flatPF.setting = "ArenaFlatPowerFontSize";
	table.insert(flatSubControls, flatPF);

	fY = fY - 35;
	local mirCB = CreateCheckBox(flatWrapper, L["CB_FLAT_MIRRORED_FULL"] or L["CB_FLAT_MIRRORED"],
		"ArenaFlatMirrored", fCol1, fY);
	table.insert(flatSubControls, mirCB);

	fY = fY - 30;
	local statusTextCB = CreateCheckBox(flatWrapper, L["CB_FLAT_STATUS_TEXT"] or "Force Status Text",
		"ArenaFlatStatusText", fCol1, fY);
	table.insert(flatSubControls, statusTextCB);

	fY = fY - 30;
	local flatWrapperHeight = math.abs(fY);
	flatWrapper:SetHeight(flatWrapperHeight);



	local lowerSection = CreateFrame("Frame", "NidhausArenaLowerSection", content);
	lowerSection:SetWidth(540);

	local lY = 0;
	CreateSeparator(lowerSection, 14, lY, 540);
	lY = lY - 8;


	local modH = lowerSection:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	modH:SetPoint("TOPLEFT", 20, lY);
	modH:SetText(L["HEADER_ARENA_MODULES"]);
	lY = lY - 24;
	CreateCheckBox(lowerSection, L["CB_MIRROR_MODE"],   "ArenaMirrorMode",      20, lY);
	CreateCheckBox(lowerSection, L["CB_TRINKET_TRACK"], "ArenaFrame_Trinkets", 285, lY);
	lY = lY - 28;
	CreateCheckBox(lowerSection, L["CB_TRINKET_VOICE"], "ArenaFrame_Trinket_Voice", 20, lY);
	lY = lY - 40;

	CreateSeparator(lowerSection, 14, lY, 540);
	lY = lY - 8;

	local cbH = lowerSection:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	cbH:SetPoint("TOPLEFT", 20, lY);
	cbH:SetText(L["HEADER_CASTBAR"]);

	lY = lY - 22;
	CreateCheckBox(lowerSection, L["CB_CASTBAR_ENABLE"], "ArenaCastBarEnable", 20, lY);







	lY = lY - 52;
	local cbBody = K.UI.Collapsible(lowerSection, 0, lY, 540, 58, function()
		return C.ArenaCastBarEnable and true or false;
	end);
	castBarBody = cbBody;

	local cbS = CreateSlider(cbBody, L["SLIDER_CASTBAR_SCALE"],
		"ArenaCastBarScale", 0.1, 5.0, 0.1, fCol1, 0);
	cbS:SetWidth(130); cbS.setting = "ArenaCastBarScale";
	table.insert(castBarSubControls, cbS);

	local cbW = CreateSlider(cbBody, L["SLIDER_CASTBAR_WIDTH"],
		"ArenaCastBarWidth", 10, 400, 5, fCol2, 0);
	cbW:SetWidth(130); cbW.setting = "ArenaCastBarWidth";
	table.insert(castBarSubControls, cbW);

	local cbResetBtn = CreateFrame("Button", nil, cbBody, "UIPanelButtonTemplate");
	cbResetBtn:SetPoint("TOPLEFT", fCol2 + 170, 2);
	cbResetBtn:SetSize(60, 22);
	cbResetBtn:SetText(L["BTN_RESET_CASTBAR"] or "Reset");
	cbResetBtn:SetScript("OnClick", function()





		if K.ResetCastBarPositions then K.ResetCastBarPositions(); end


		local defs = { ArenaCastBarScale = 1.0, ArenaCastBarWidth = 80 };
		for _, ctrl in ipairs(castBarSubControls) do
			if ctrl.SetValue and ctrl.setting and defs[ctrl.setting] ~= nil then
				ctrl:SetValue(defs[ctrl.setting]);
				if ctrl.ValueText then
					ctrl.ValueText:SetText(FormatSliderValue(ctrl:GetValueStep() or 1, defs[ctrl.setting]));
				end
			end
		end
	end);
	table.insert(castBarSubControls, cbResetBtn);



	local lowerSectionHeight = math.abs(lY);



	local function UpdateLayout(flatVisible)
		local lowerY;
		if flatVisible then
			lowerY = flatAnchorY - flatWrapperHeight - 10;
		else
			lowerY = flatAnchorY - 5;
		end
		lowerSection:ClearAllPoints();
		lowerSection:SetPoint("TOPLEFT", 0, lowerY);
		sub.SetContentHeight(1, math.abs(lowerY) + lowerSectionHeight);
	end

	K._RefreshArenaLayout = function()
		UpdateLayout((C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true));
	end

	local function SetFlatVisible(show)
		if show then flatWrapper:Show(); else flatWrapper:Hide(); end
		UpdateLayout(show);
	end


	local function OnStyleChange(value)
		local isFlat = (value == "Flat");




		if K._UpdateArenaBlizzClassColorBox then K._UpdateArenaBlizzClassColorBox(); end
		if K.ToggleClassColors then K.ToggleClassColors(); end

		if isFlat and C.ArenaMirrorMode then
			if K.ResetMirrorCastBars then K.ResetMirrorCastBars(); end
		end

		if K.RemoveAllFlatStyles then K.RemoveAllFlatStyles(); end
		if K.RemoveAllFlatPetStyles then K.RemoveAllFlatPetStyles(); end








		if value == "Custom" or value == "Compact" or value == "Compact2" then
			K.SaveConfig("ArenaCustomTexture", true);
			K.SaveConfig("ArenaFlatMode", false);
			if K.ToggleArenaCustomTexture then K.ToggleArenaCustomTexture(true); end
		elseif isFlat then
			K.SaveConfig("ArenaCustomTexture", false);
			K.SaveConfig("ArenaFlatMode", true);
			if K.ToggleArenaFlatMode then K.ToggleArenaFlatMode(true); end
		else
			K.SaveConfig("ArenaCustomTexture", false);
			K.SaveConfig("ArenaFlatMode", false);
			if K.ToggleArenaCustomTexture then K.ToggleArenaCustomTexture(false); end
		end

		SetFlatVisible(isFlat);

		if NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown then
			if K.StyleSingleArenaFrame then
				for i = 1, MAX_ARENA_ENEMIES do
					local af = _G["ArenaEnemyFrame"..i];
					if af and af:IsShown() then K.StyleSingleArenaFrame(af, i); end
				end
			end
			local mover = _G["NUF_ArenaMover"];
			if mover and mover.bg then
				if isFlat then
					mover.bg:Hide();
				elseif not IsActiveBattlefieldArena or not IsActiveBattlefieldArena() then
					mover.bg:Show();
				end
			end
		end

		if K.RepositionAllSpecIcons then K.RepositionAllSpecIcons(); end
		if K.ApplyMirrorMode then K.ApplyMirrorMode(); end









		if K._UpdateArenaOptionsVisibility then K._UpdateArenaOptionsVisibility(); end
	end

	local styleDDContainer = CreateDropdown(content, L["LABEL_ARENA_STYLE"] or "Arena Style", "ArenaFrameStyle",
		styleOptions, 20, styleStartY, OnStyleChange);










	local blizzCCBox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate");


	blizzCCBox:SetPoint("TOPLEFT", 182, styleStartY - 12);
	blizzCCBox:SetWidth(24); blizzCCBox:SetHeight(24);
	blizzCCBox.text = blizzCCBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	blizzCCBox.text:SetPoint("LEFT", blizzCCBox, "RIGHT", 2, 0);
	blizzCCBox.text:SetText(L["CB_ARENA_BLIZZ_CLASSCOLOR"] or "Class color");
	blizzCCBox:SetScript("OnClick", function(self)
		local checked = self:GetChecked() == 1 or self:GetChecked() == true;
		K.SaveConfig("ArenaBlizzardClassColor", checked);
		if K.ToggleClassColors then K.ToggleClassColors(checked); end
	end);

	local function UpdateBlizzClassColorBox()








		if C.ArenaFrameOn ~= true then
			blizzCCBox:Hide();
			return;
		end

		if (C.ArenaFrameStyle or "Custom") == "Blizzard" then
			blizzCCBox:SetChecked(C.ArenaBlizzardClassColor or false);
			blizzCCBox:Show();
		else
			blizzCCBox:Hide();
		end
	end
	UpdateBlizzClassColorBox();

	K._UpdateArenaBlizzClassColorBox = UpdateBlizzClassColorBox;





	local tail = CreateFrame("Frame", nil, lowerSection);
	tail:SetPoint("TOPLEFT", cbBody, "BOTTOMLEFT", 0, -16);
	tail:SetWidth(540);
	tail:SetHeight(96);

	CreateSeparator(tail, 14, 0, 540);

	local petH = tail:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	petH:SetPoint("TOPLEFT", 20, -12);
	petH:SetText("|cffFFD100" .. (L["HEADER_ARENA_PETS"] or "Pets") .. "|r");



	local petNote = tail:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	petNote:SetPoint("TOPLEFT", 22, -42);
	petNote:SetWidth(245);
	petNote:SetJustifyH("LEFT");
	petNote:SetText("|cff8EAEC9" .. (L["PET_STYLE_FLAT_ONLY"]
		or "The pet style only applies with the Flat arena style.") .. "|r");

	local petContainerRef;
	do
		dropdownCount = dropdownCount + 1;
		local petDDName = "NidhausArenaDD"..dropdownCount;

		local petContainer = CreateFrame("Frame", nil, tail);
		petContainer:SetPoint("TOPLEFT", 20, -32);
		petContainer:SetSize(240, 50);
		petContainerRef = petContainer;

		local petLabel = petContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		petLabel:SetPoint("TOPLEFT", 0, 0);
		petLabel:SetText("|cffffd100" .. (L["ARENA_PET_STYLE"] or "Pet Style") .. "|r");

		local petDD = CreateFrame("Frame", petDDName, petContainer, "UIDropDownMenuTemplate");
		petDD:SetPoint("TOPLEFT", -16, -16);
		UIDropDownMenu_SetWidth(petDD, 110);

		local petOpts = {
			{text = "Default", flat = false},
			{text = "Flat",    flat = true},
		};
		local function PetDDInit(self, level)
			for _, opt in ipairs(petOpts) do
				local info = UIDropDownMenu_CreateInfo();
				info.text = opt.text;
				info.value = opt.text;
				info.func = function(btn)
					UIDropDownMenu_SetSelectedValue(petDD, btn.value);
					UIDropDownMenu_SetText(petDD, btn.value);
					local isFlat = (btn.value == "Flat");
					K.SaveConfig("ArenaFlatPetStyle", isFlat);
					if isFlat and C.ArenaPetFrameShow then
						if K.ApplyFlatPetFrames then K.ApplyFlatPetFrames(); end
						if K.RestorePetFramePositions then K.RestorePetFramePositions(); end
					elseif not isFlat then
						if K.RemoveAllFlatPetStyles then K.RemoveAllFlatPetStyles(); end
					end
				end;
				info.checked = (opt.flat == C.ArenaFlatPetStyle);
				UIDropDownMenu_AddButton(info, level);
			end
		end
		UIDropDownMenu_Initialize(petDD, PetDDInit);
		local initText = C.ArenaFlatPetStyle and "Flat" or "Default";
		UIDropDownMenu_SetSelectedValue(petDD, initText);
		UIDropDownMenu_SetText(petDD, initText);
	end



	local resetPetBtn = CreateFrame("Button", nil, tail, "UIPanelButtonTemplate");
	resetPetBtn:SetPoint("TOPLEFT", 285, -50);
	resetPetBtn:SetSize(170, 24);
	resetPetBtn:SetText(L["BTN_RESET_PET_POS"] or "Reset position");
	resetPetBtn:SetScript("OnClick", function()
		if NidhausUnitFramesDB then
			NidhausUnitFramesDB.PetFramePositions = nil;
		end
		local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
		if isFlat and C.ArenaFlatPetStyle then
			if K.ApplyFlatPetFrames then K.ApplyFlatPetFrames(); end
		else
			for i = 1, MAX_ARENA_ENEMIES do
				local pf = _G["ArenaEnemyFrame"..i.."PetFrame"];
				if pf and pf._blizzDefaultPoints then
					pf:ClearAllPoints();
					for _, pt in ipairs(pf._blizzDefaultPoints) do
						pf:SetPoint(unpack(pt));
					end
				end
			end
		end
	end);


	local function UpdateLowerHeight()
		local open = C.ArenaCastBarEnable and true or false;
		lowerSectionHeight = math.abs(lY) + (open and 58 or 0) + 122;
		lowerSection:SetHeight(lowerSectionHeight);
	end
	K._UpdateArenaLowerHeight = UpdateLowerHeight;
	UpdateLowerHeight();




	local function UpdateArenaOptionsVisibility()
		local on = (C.ArenaFrameOn == true);
		local isFlat = (C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true);

		if styleSep then if on then styleSep:Show(); else styleSep:Hide(); end end
		if K._UpdateArenaBoxes then K._UpdateArenaBoxes(); end
		if styleDDContainer then if on then styleDDContainer:Show(); else styleDDContainer:Hide(); end end

		for _, w in ipairs({ styleHead, scaleS, spaceS, petShowCB }) do
			if on then w:Show(); else w:Hide(); end
		end








		if petContainerRef then
			if on and isFlat then petContainerRef:Show(); else petContainerRef:Hide(); end
		end
		if petNote then
			if on and not isFlat then petNote:Show(); else petNote:Hide(); end
		end
		if lowerSection then if on then lowerSection:Show(); else lowerSection:Hide(); end end
		if flatWrapper then
			if on and isFlat then flatWrapper:Show(); else flatWrapper:Hide(); end
		end
		if arenaHint then if on then arenaHint:Show(); else arenaHint:Hide(); end end
		if moveHint then if on then moveHint:Show(); else moveHint:Hide(); end end




		if K._UpdateArenaBlizzClassColorBox then
			K._UpdateArenaBlizzClassColorBox();
		end

		if on then
			UpdateLayout(isFlat);
		else
			sub.SetContentHeight(1, 120);
		end
	end
	K._UpdateArenaOptionsVisibility = UpdateArenaOptionsVisibility;


	local arenaBoxes = {};
	if K.UI and K.UI.SectionBox then

		table.insert(arenaBoxes, K.UI.SectionBox(content, nil, 8, -4, 580, 112));


		local b = K.UI.SectionBox(content, nil,
			8, styleStartY + 30, 580, 130);
		table.insert(arenaBoxes, b);
	end

	local function UpdateArenaBoxes()
		local on = (C.ArenaFrameOn == true);
		for _, b in ipairs(arenaBoxes) do
			if on then b:Show(); else b:Hide(); end
		end
	end

	local isCurrentlyFlat = (C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true);
	SetFlatVisible(isCurrentlyFlat);
	UpdateArenaOptionsVisibility();
	UpdateArenaBoxes();
	K._UpdateArenaBoxes = UpdateArenaBoxes;




	local tY = -12;

	local timH = paneTimers:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	timH:SetPoint("TOPLEFT", 20, tY);
	timH:SetText(L["HEADER_ARENA_TIMERS"] or "|cffFFD100Arena Timers|r");

	tY = tY - 20;
	local timHint = paneTimers:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	timHint:SetPoint("TOPLEFT", 22, tY);
	timHint:SetWidth(430);
	timHint:SetJustifyH("LEFT");
	timHint:SetText("|cff8EAEC9" .. (L["TIMERS_MOVE_NOTE"]
		or "/nuftimers to show them, Alt + drag to move") .. "|r");

	tY = tY - 30;
	CreateCheckBox(paneTimers, L["CB_ARENA_COUNTDOWN"] or "Arena Countdown",
		"ArenaCountDown", 20, tY);
	tY = tY - 28;
	CreateCheckBox(paneTimers, L["CB_SHADOW_SIGHT"] or "Shadow Sight timer (eye icon)",
		"ShadowSightTimer", 20, tY);
	tY = tY - 28;
	CreateCheckBox(paneTimers, L["CB_ARENA_END"] or "Arena Time Remaining",
		"ArenaEndTimer", 20, tY);
	tY = tY - 28;
	CreateCheckBox(paneTimers, L["CB_DALARAN_PIPE"] or "Dalaran Waterfall Timer",
		"ArenaDalaranPipeTimer", 20, tY);
	tY = tY - 28;
	CreateCheckBox(paneTimers, L["CB_ROV_PILLARS"] or "Ring of Valor Pillar Timer",
		"ArenaRoVPillarTimer", 20, tY);

	tY = tY - 28;
	if K.Modules and K.Modules["ArenaTimes"] then
		CreateModuleCheckBox(paneTimers, L["CB_ARENA_TIMES"] or "Queue timer + invite popup timer",
			"ArenaTimes", 20, tY,
			L["TIP_ArenaTimes"] or "Shows a countdown on the arena invite popup and the queue time next to the minimap.");
	end








	tY = tY - 46;
	CreateSeparator(paneTimers, 14, tY + 14, 440);
	local scH = paneTimers:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	scH:SetPoint("TOPLEFT", 20, tY);
	scH:SetText((K.UI and K.UI.Header(L["HEADER_TIMER_SCALES"] or "Timer size"))
		or "|cffFFD100Timer size|r");
	tY = tY - 34;

	if K.UI and K.UI.ScaleSlider then
		local sc1 = K.UI.ScaleSlider(paneTimers, "ArenaEndTimer", 24, tY, 150,
			L["CB_ARENA_END"] or "Arena Time");
		local sc2 = K.UI.ScaleSlider(paneTimers, "ArenaCountDown", 260, tY, 150,
			L["SCALE_COUNTDOWN"] or "Countdown");
		if sc1 or sc2 then tY = tY - 54; end

		local sc3 = K.UI.ScaleSlider(paneTimers, "ArenaDalaranPipeTimer", 24, tY, 150,
			L["SCALE_DALARAN"] or "Dalaran");
		local sc4 = K.UI.ScaleSlider(paneTimers, "ArenaRoVPillarTimer", 260, tY, 150,
			L["SCALE_ROV"] or "Ring of Valor");
		if sc3 or sc4 then tY = tY - 54; end
	end

	tY = tY - 20;





	CreateSeparator(paneTimers, 14, tY + 12, 440);

	local mPane = paneModules;
	local mY = tY;

	local totH = mPane:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	totH:SetPoint("TOPLEFT", 20, mY);
	totH:SetText("|cffFFD100" .. (L["ARENA_TOT"] or "Target of Target") .. "|r");

	mY = mY - 26;
	local totToggle;
	if K.Modules and K.Modules["ArenaToT"] then
		totToggle = CreateModuleCheckBox(mPane, L["CB_ARENA_TOT"] or "Enable Target of Target",
			"ArenaToT", 20, mY,
			L["TIP_ArenaToT"] or "Shows the target of each arena enemy.");
	end










	mY = mY - 34;
	local totSection = CreateFrame("Frame", "NidhausArenaToTSection", mPane);
	totSection:SetPoint("TOPLEFT", 0, mY);
	totSection:SetWidth(540);
	totSection:SetHeight(86);

	local totScaleSlider = CreateSlider(totSection, L["SLIDER_ARENA_TOT_SCALE"] or "Target of Target Scale",
		"ArenaToTScale", 0.5, 2.0, 0.1, fCol1, -16);
	totScaleSlider:SetWidth(130); totScaleSlider.setting = "ArenaToTScale";


	CreateCheckBox(totSection, L["CB_ARENA_TOT_CLASSICON"] or "Class Icon",
		"ArenaToTClassIcon", fCol2, -12);
	CreateCheckBox(totSection, L["CB_ARENA_TOT_MIRROR"] or "Mirror Frame",
		"ArenaToTMirrored",  fCol2 + 130, -12);




	CreateCheckBox(totSection, L["CB_ARENA_TOT_SQUARE"] or "Square Style",
		"ArenaToTSquare", fCol1, -44);

	local totResetBtn = CreateFrame("Button", nil, totSection, "UIPanelButtonTemplate");
	totResetBtn:SetPoint("TOPLEFT", fCol2, -44);
	totResetBtn:SetSize(80, 20);
	totResetBtn:SetText(L["BTN_RESET_SHORT"] or "Reset");
	totResetBtn:SetScript("OnClick", function()
		K.SaveConfig("ArenaToTScale", 1.0);
		totScaleSlider:SetValue(1.0);
		if K.ResetArenaToTPositions then K.ResetArenaToTPositions(); end
		if K.ApplyArenaToTScale then K.ApplyArenaToTScale(1.0); end
	end);

	local function RefreshToTSection()
		local on = K.IsModuleEnabled and K.IsModuleEnabled("ArenaToT");
		if on then totSection:Show(); else totSection:Hide(); end
	end
	RefreshToTSection();

	if totToggle then
		local oldOnClick = totToggle:GetScript("OnClick");
		totToggle:SetScript("OnClick", function(self)
			if oldOnClick then oldOnClick(self); end
			RefreshToTSection();
		end);
	end

	mY = mY - 90;









	local function BuildTrackerPane(pane, o)
		o.pane = pane;
		local y = -12;
		local head = pane:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		head:SetPoint("TOPLEFT", 20, y);
		head:SetText("|cffFFD100" .. o.header .. "|r");

		y = y - 20;
		local intro = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		intro:SetPoint("TOPLEFT", 22, y);
		intro:SetWidth(430);
		intro:SetJustifyH("LEFT");
		intro:SetText("|cff8EAEC9" .. o.intro .. "|r");
		y = y - math.max(28, math.ceil(intro:GetStringHeight() or 0) + 12);

		CreateCheckBox(pane, o.enableLabel, o.enableSetting, 20, y);
		y = y - 44;



		local bodyTop = y;
		local body = CreateFrame("Frame", nil, pane);
		body:SetPoint("TOPLEFT", 0, bodyTop);
		body:SetSize(540, 10);
		pane = body;
		y = 0;


		CreateSeparator(pane, 14, y + 12, 440);
		local posH = pane:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		posH:SetPoint("TOPLEFT", 20, y);
		posH:SetText("|cffFFD100" .. (L["HEADER_DR_POS"] or "Position and preview") .. "|r");

		y = y - 20;
		local hint = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		hint:SetPoint("TOPLEFT", 22, y);
		hint:SetWidth(430);
		hint:SetJustifyH("LEFT");
		hint:SetText("|cffFFAA00" .. (L["DR_MOVE_HINT"] or "Preview: Shift+Alt+drag the icons to move them.") .. "|r");
		y = y - math.max(18, math.ceil(hint:GetStringHeight() or 0) + 10);

		local previewBtn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
		previewBtn:SetPoint("TOPLEFT", 20, y);
		previewBtn:SetSize(170, 24);

		local function UpdateBtn()
			local on = o.isPreviewOn and o.isPreviewOn();
			previewBtn:SetText(on and (L["BTN_DR_PREVIEW_OFF"] or "Hide preview")
				or (L["BTN_DR_PREVIEW"] or "Preview"));
			local live = IsActiveBattlefieldArena and IsActiveBattlefieldArena();
			if C[o.enableSetting] and C.ArenaFrameOn and not live then
				previewBtn:Enable();
			else
				previewBtn:Disable();
			end
		end

		previewBtn:SetScript("OnClick", function()
			if o.togglePreview then o.togglePreview(); end
			UpdateBtn();
		end);
		previewBtn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["BTN_DR_PREVIEW"] or "Preview", 1, 1, 1);
			if not C.ArenaFrameOn then
				GameTooltip:AddLine(L["DR_PREVIEW_NEEDS_ARENA"] or "Needs the arena frames mod.", 1, 0.3, 0.3, true);
			elseif not C[o.enableSetting] then
				GameTooltip:AddLine(o.needEnable or "Turn it on first.", 1, 0.3, 0.3, true);
			else
				GameTooltip:AddLine(L["DR_MOVE_HINT"] or "Shift+Alt+drag to move.", nil, nil, nil, true);
			end
			GameTooltip:Show();
		end);
		previewBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

		local resetBtn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
		resetBtn:SetPoint("LEFT", previewBtn, "RIGHT", 10, 0);
		resetBtn:SetSize(170, 24);
		resetBtn:SetText(L["BTN_DR_RESET"] or "Reset position");
		resetBtn:SetScript("OnClick", function()
			if o.resetPos then o.resetPos(); end
		end);

		y = y - 40;


		local growOpts = {
			{ value = "AUTO",  text = L["DR_GROW_AUTO"]  or "Auto (outward)" },
			{ value = "LEFT",  text = L["DR_GROW_LEFT"]  or "Left" },
			{ value = "RIGHT", text = L["DR_GROW_RIGHT"] or "Right" },
			{ value = "UP",    text = L["DR_GROW_UP"]    or "Up" },
			{ value = "DOWN",  text = L["DR_GROW_DOWN"]  or "Down" },
		};
		local function GrowText(v)
			for _, g in ipairs(growOpts) do
				if g.value == v then return g.text; end
			end
			return growOpts[1].text;
		end

		local growBox = CreateFrame("Frame", nil, pane);
		growBox:SetPoint("TOPLEFT", 20, y);
		growBox:SetSize(220, 50);
		local growLbl = growBox:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		growLbl:SetPoint("TOPLEFT", 0, 0);
		growLbl:SetText(L["DD_DR_GROW"] or "Grow direction");

		local growDD = CreateFrame("Frame", o.ddName, growBox, "UIDropDownMenuTemplate");
		growDD:SetPoint("TOPLEFT", -16, -16);
		UIDropDownMenu_SetWidth(growDD, 160);
		UIDropDownMenu_Initialize(growDD, function(self, level)
			for _, g in ipairs(growOpts) do
				local info = UIDropDownMenu_CreateInfo();
				info.text = g.text;
				info.value = g.value;
				info.checked = ((C[o.growSetting] or "AUTO") == g.value);
				info.func = function(btn)
					UIDropDownMenu_SetSelectedValue(growDD, btn.value);
					UIDropDownMenu_SetText(growDD, GrowText(btn.value));
					K.SaveConfig(o.growSetting, btn.value);
					if o.refresh then o.refresh(); end
				end;
				UIDropDownMenu_AddButton(info, level);
			end
		end);
		UIDropDownMenu_SetSelectedValue(growDD, C[o.growSetting] or "AUTO");
		UIDropDownMenu_SetText(growDD, GrowText(C[o.growSetting] or "AUTO"));

		y = y - 66;


		CreateSeparator(pane, 14, y + 12, 440);
		local lookH = pane:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		lookH:SetPoint("TOPLEFT", 20, y);
		lookH:SetText("|cffFFD100" .. (L["HEADER_DR_LOOK"] or "Look") .. "|r");


		y = y - 40;
		for i, s in ipairs(o.sliders) do
			local col = (i % 2 == 1) and 24 or 260;
			CreateSlider(pane, s[1], s[2], s[3], s[4], s[5], col, y);
			if i % 2 == 0 and i < #o.sliders then y = y - 56; end
		end

		y = y - 48;
		for _, c in ipairs(o.checks) do
			CreateCheckBox(pane, c[1], c[2], 20, y);
			y = y - 28;
		end

		if o.extra then y = o.extra(pane, y, o); end
		y = y - 16;

		local fullH = math.abs(bodyTop) + math.abs(y);
		local shortH = math.abs(bodyTop) + 6;
		local function UpdateAll()
			UpdateBtn();
			if o.sync then o.sync(); end
			local on = C[o.enableSetting] and true or false;
			if on then body:Show(); else body:Hide(); end
			sub.SetContentHeight(o.index, on and fullH or shortH);
		end

		o.pane:HookScript("OnShow", UpdateAll);
		UpdateAll();
		return UpdateAll;
	end









	local function BuildDRCategories(pane, y, o)
		y = y - 8;
		CreateSeparator(pane, 14, y + 12, 440);
		local head = pane:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		head:SetPoint("TOPLEFT", 20, y);
		head:SetText("|cffFFD100" .. (L["HEADER_DR_CATS"] or "Categories to show") .. "|r");

		y = y - 20;
		local note = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		note:SetPoint("TOPLEFT", 22, y);
		note:SetWidth(430);
		note:SetJustifyH("LEFT");
		note:SetText("|cff8EAEC9" .. (L["DR_CATS_NOTE"] or "DR is shared per category. Hover one to see its spells.") .. "|r");
		y = y - math.max(18, math.ceil(note:GetStringHeight() or 0) + 10);

		local boxes = {};
		local function Sync()
			if not K.IsArenaDRCategoryShown then return; end
			for _, cb in ipairs(boxes) do
				cb:SetChecked(K.IsArenaDRCategoryShown(cb.cat) and true or false);
			end
		end
		o.sync = Sync;


		local presets = {
			{ "all",   L["BTN_DR_CATS_ALL"]   or "All" },
			{ "class", L["BTN_DR_CATS_CLASS"] or "My class" },
			{ "none",  L["BTN_DR_CATS_NONE"]  or "None" },
		};
		local x = 20;
		for _, pr in ipairs(presets) do
			local which = pr[1];
			local btn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
			btn:SetPoint("TOPLEFT", x, y);
			btn:SetSize(110, 22);
			btn:SetText(pr[2]);
			btn:SetScript("OnClick", function()
				if K.SetArenaDRCategoryPreset then K.SetArenaDRCategoryPreset(which); end
				Sync();
			end);
			x = x + 118;
		end
		y = y - 32;

		local cats = K.GetArenaDRCategories and K.GetArenaDRCategories() or {};
		local rows = math.ceil(#cats / 2);
		for i, info in ipairs(cats) do
			local col = (i <= rows) and 0 or 1;
			local row = (col == 0) and (i - 1) or (i - 1 - rows);

			local cb = CreateFrame("CheckButton", nil, pane, "UICheckButtonTemplate");
			cb:SetSize(22, 22);
			cb:SetPoint("TOPLEFT", 20 + col * 220, y - row * 24);
			cb.cat = info.key;
			cb.mine = info.mine;

			local ic = cb:CreateTexture(nil, "ARTWORK");
			ic:SetSize(16, 16);
			ic:SetPoint("LEFT", cb, "RIGHT", 2, 0);
			ic:SetTexture(info.icon);
			ic:SetTexCoord(0.07, 0.93, 0.07, 0.93);

			local label = L["DR_CAT_" .. info.key] or info.key;
			local t = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
			t:SetPoint("LEFT", ic, "RIGHT", 4, 0);
			t:SetWidth(172);
			t:SetJustifyH("LEFT");
			t:SetText(label);


			if not info.mine then t:SetTextColor(0.62, 0.62, 0.62); end
			cb.label = label;

			cb:SetChecked(K.IsArenaDRCategoryShown and K.IsArenaDRCategoryShown(info.key) and true or false);
			cb:SetScript("OnClick", function(self)
				local on = self:GetChecked() and true or false;
				if K.SetArenaDRCategoryShown then K.SetArenaDRCategoryShown(self.cat, on); end
			end);
			cb:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(self.label, 1, 1, 1);
				if self.mine then
					GameTooltip:AddLine(L["DR_CATS_TIP_MINE"] or "Your class applies it.", 0.3, 1, 0.3, true);
				else
					GameTooltip:AddLine(L["DR_CATS_TIP_OTHER"] or "Your class doesn't apply it; your teammates can.", 0.7, 0.7, 0.7, true);
				end
				local spells = K.GetArenaDRCategorySpells and K.GetArenaDRCategorySpells(self.cat) or {};
				if #spells > 0 then
					GameTooltip:AddLine(" ");
					GameTooltip:AddLine(L["DR_CATS_TIP_SPELLS"] or "Share this DR:", 1, 0.82, 0);
					GameTooltip:AddLine(table.concat(spells, ", "), 1, 1, 1, true);
				end
				GameTooltip:Show();
			end);
			cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
			boxes[#boxes + 1] = cb;
		end
		y = y - rows * 24 - 6;
		return y;
	end


	K._UpdateDRPreviewBtn = BuildTrackerPane(paneDR, {
		index         = 3,
		header        = L["HEADER_ARENA_DR"] or "Diminishing Returns",
		intro         = L["DR_INTRO"] or "One icon per DR category on each arena enemy: 1/2, 1/4, X = immune.",
		enableLabel   = L["CB_ARENA_DR"] or "Diminishing Returns icons (your class spells)",
		enableSetting = "ArenaDR",
		needEnable    = L["DR_NEED_ENABLE"],
		isPreviewOn   = function() return K.IsArenaDRPreviewOn and K.IsArenaDRPreviewOn(); end,
		togglePreview = function() if K.ToggleArenaDRPreview then K.ToggleArenaDRPreview(); end end,
		resetPos      = function() if K.ResetArenaDRPosition then K.ResetArenaDRPosition(); end end,
		refresh       = function() if K.RefreshArenaDRLayout then K.RefreshArenaDRLayout(); end end,
		growSetting   = "ArenaDRGrow",
		ddName        = "NidhausArenaDRGrowDD",
		sliders = {
			{ L["SLIDER_DR_SIZE"] or "Icon size", "ArenaDRSize", 12, 48, 1 },
			{ L["SLIDER_DR_SPACING"] or "Spacing", "ArenaDRSpacing", 0, 20, 1 },
		},
		checks = {
			{ L["CB_DR_BORDER"] or "Colored border (DR level)", "ArenaDRBorder" },
			{ L["CB_DR_TEXT"] or "Show 1/2 - 1/4 - X", "ArenaDRText" },
			{ L["CB_DR_TIMER"] or "Show time left", "ArenaDRTimer" },
		},
		extra = BuildDRCategories,
	});


	K._UpdateDoTPreviewBtn = BuildTrackerPane(paneDoT, {
		index         = 4,
		header        = L["HEADER_ARENA_DOT"] or "DoT warning",
		intro         = L["DOT_INTRO"] or "Marks every arena enemy that has a damage-over-time effect.",
		enableLabel   = L["CB_ARENA_DOTWARN"] or "Show DoTs on arena enemies",
		enableSetting = "ArenaDoTWarn",
		needEnable    = L["DOT_NEED_ENABLE"],
		isPreviewOn   = function() return K.IsArenaDoTPreviewOn and K.IsArenaDoTPreviewOn(); end,
		togglePreview = function() if K.ToggleArenaDoTPreview then K.ToggleArenaDoTPreview(); end end,
		resetPos      = function() if K.ResetArenaDoTPosition then K.ResetArenaDoTPosition(); end end,
		refresh       = function() if K.RefreshArenaDoTLayout then K.RefreshArenaDoTLayout(); end end,
		growSetting   = "ArenaDoTGrow",
		ddName        = "NidhausArenaDoTGrowDD",
		sliders = {
			{ L["SLIDER_DR_SIZE"] or "Icon size", "ArenaDoTSize", 10, 40, 1 },
			{ L["SLIDER_DR_SPACING"] or "Spacing", "ArenaDoTSpacing", 0, 20, 1 },
			{ L["SLIDER_DOT_MAX"] or "Max icons", "ArenaDoTMax", 1, 6, 1 },
		},
		checks = {
			{ L["CB_DOT_LABEL"] or 'Show the "DoT" text', "ArenaDoTLabel" },
			{ L["CB_DOT_BORDER"] or "Red border", "ArenaDoTBorder" },
		},
	});









	local apcBlock, apcHost;
	if K.Modules and K.Modules["ArenaPointsCalc"] then


		apcBlock = CreateFrame("Frame", "NidhausArenaPointsBlock", panePoints);
		apcBlock:SetPoint("TOPLEFT", 0, -14);
		apcBlock:SetWidth(540);
		apcBlock:SetHeight(96);

		local ptsH = apcBlock:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		ptsH:SetPoint("TOPLEFT", 20, 0);
		ptsH:SetText("|cffFFD100" .. (L["HEADER_ARENA_CALC"] or "Arena Calculator") .. "|r");

		CreateModuleCheckBox(apcBlock, L["MOD_APC"] or "Arena Points Calculator",
			"ArenaPointsCalc", 20, -40,
			L["MOD_APC_DESC"] or "Calculates the arena points you will get each week. /apc to open it.");










		apcHost = CreateFrame("Frame", "NidhausArenaCalcHost", apcBlock);
		apcHost:SetPoint("TOPLEFT", 24, -70);
		apcHost:SetSize(300, 248);




		panePoints:HookScript("OnShow", function()
			if K.IsModuleEnabled and K.IsModuleEnabled("ArenaPointsCalc") then
				if K.APC_Dock then K.APC_Dock(apcHost); end
			end
		end);
		panePoints:HookScript("OnHide", function()
			if K.APC_Undock then K.APC_Undock(); end
		end);
	end



	local function RefreshAPCBlock()
		local on = K.IsModuleEnabled and K.IsModuleEnabled("ArenaPointsCalc");















		if apcBlock then apcBlock:Show(); end
		if apcHost then
			if on then apcHost:Show(); else apcHost:Hide(); end
		end


		if apcHost and panePoints and panePoints:IsShown() then
			if on then
				if K.APC_Dock then K.APC_Dock(apcHost); end
			elseif K.APC_Undock then
				K.APC_Undock();
			end
		end



		sub.SetContentHeight(2, math.abs(mY));



		sub.SetContentHeight(5, on and 340 or 90);
	end
	K._RefreshArenaPointsBlock = RefreshAPCBlock;
	RefreshAPCBlock();




	paneTimers:HookScript("OnShow", RefreshAPCBlock);
	panePoints:HookScript("OnShow", RefreshAPCBlock);


	panel:HookScript("OnShow", function()
		UpdateArenaOptionsVisibility();
		local isFlat = (C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true);
		if C.ArenaFrameOn then UpdateLayout(isFlat); end
		RefreshToTSection();
		RefreshAPCBlock();
		if totToggle and K.IsModuleEnabled then
			totToggle:SetChecked(K.IsModuleEnabled("ArenaToT"));
		end
	end);

	return arenaShowBtn;
end
