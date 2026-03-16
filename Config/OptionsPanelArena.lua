local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local flatSubControls = {};
local castBarSubControls = {};
local petStyleControls = {};
local arenaShowBtn;
local dropdownCount = 0;
-- FIX: Constante para loops de test mode (consistente con ArenaMover.MOVER_ARENA_COUNT)
local MOVER_ARENA_COUNT = 3;
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
	ArenaCastBarEnable      = "TIP_ArenaCastBarEnable",
	ArenaCastBarScale       = "TIP_ArenaCastBarScale",
	ArenaCastBarWidth       = "TIP_ArenaCastBarWidth",
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

-- =========================================================
-- CreateCheckBox
-- =========================================================
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
			if arenaShowBtn then
				if checked then arenaShowBtn:Show(); else arenaShowBtn:Hide(); end
			end
			-- FIX: Activar/desactivar el mod en vivo (antes no hacía nada)
			if checked then
				if K.EnableArenaFrameMod then K.EnableArenaFrameMod(); end
			else
				if K.DisableArenaFrameMod then K.DisableArenaFrameMod(); end
			end
		elseif setting == "ArenaFlatMirrored" then
			if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
		elseif setting == "ArenaFlatStatusText" then
			if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
		elseif setting == "ArenaCastBarEnable" then
			if K.ToggleArenaCastBar then K.ToggleArenaCastBar(checked); end
			for _, ctrl in ipairs(castBarSubControls) do
				if checked then ctrl:Show(); else ctrl:Hide(); end
			end
		elseif setting == "ArenaMirrorMode" then
			if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
		elseif setting == "ArenaFrame_Trinkets" then
			if K.ToggleArenaTrinketsTracking then K.ToggleArenaTrinketsTracking(checked); end
		elseif setting == "ArenaFrame_Trinket_Voice" then
			-- voice only applies on next trinket use
		elseif setting == "ArenaPetFrameShow" then
			-- Toggle pet frames in test mode - usar nombre global
			if NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown then
				for i = 1, MOVER_ARENA_COUNT do
					local petFrame = _G["ArenaEnemyFrame"..i.."PetFrame"];
					if petFrame then
						if checked then
							-- FIX NUCLEAR: Override Hide() para bloquear el auto-hide de Blizzard
							if not petFrame._origHide then
								petFrame._origHide = petFrame.Hide;
							end
							petFrame.Hide = function() end;
							petFrame._testMode = true;
							petFrame:Show();
							if petFrame.healthbar then
								petFrame.healthbar:SetMinMaxValues(0, 100);
								petFrame.healthbar:SetValue(100);
								petFrame.healthbar:SetStatusBarColor(0, 1, 0);
							end
							if petFrame.manabar then
								petFrame.manabar:SetMinMaxValues(0, 100);
								petFrame.manabar:SetValue(100);
								petFrame.manabar:SetStatusBarColor(0, 0, 1);
							end
						else
							-- FIX: Restaurar Hide original antes de ocultar
							if petFrame._origHide then
								petFrame.Hide = petFrame._origHide;
								petFrame._origHide = nil;
							end
							petFrame._testMode = nil;
							petFrame:Hide();
						end
					end
				end
				-- Aplicar flat pet style si está activo
				if checked and K.IsFlatModeActive and K.IsFlatModeActive() and C.ArenaFlatPetStyle then
					if K.ApplyFlatPetFrames then K.ApplyFlatPetFrames(); end
				end
			end
		elseif setting == "ArenaFlatPetStyle" then
			-- Aplicar/remover flat pet style en tiempo real
			if NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown then
				if checked then
					-- Asegurar que los pet frames estén visibles
					if C.ArenaPetFrameShow then
						for i = 1, MOVER_ARENA_COUNT do
							local petFrame = _G["ArenaEnemyFrame"..i.."PetFrame"];
							if petFrame then
								-- FIX: Asegurar que Hide override está activo
								if not petFrame._origHide then
									petFrame._origHide = petFrame.Hide;
								end
								petFrame.Hide = function() end;
								petFrame._testMode = true;
								petFrame:Show();
								if petFrame.healthbar then
									petFrame.healthbar:SetMinMaxValues(0, 100);
									petFrame.healthbar:SetValue(100);
									petFrame.healthbar:SetStatusBarColor(0, 1, 0);
								end
								if petFrame.manabar then
									petFrame.manabar:SetMinMaxValues(0, 100);
									petFrame.manabar:SetValue(100);
									petFrame.manabar:SetStatusBarColor(0, 0, 1);
								end
							end
						end
					end
					if K.ApplyFlatPetFrames then K.ApplyFlatPetFrames(); end
				else
					-- Remover flat pet styles
					if K.RemoveAllFlatPetStyles then K.RemoveAllFlatPetStyles(); end
				end
			end
		end
	end);
	return cb;
end

-- =========================================================
-- FormatSliderValue
-- =========================================================
local function FormatSliderValue(step, value)
	if step >= 1 then
		return string.format("%d", value);
	elseif step >= 0.1 then
		return string.format("%.1f", value);
	else
		return string.format("%.2f", value);
	end
end

-- =========================================================
-- CreateSlider (sArena style - matching reference image)
-- Yellow title on top, white value centered below,
-- small min/max on left/right sides
-- =========================================================
local function CreateSlider(parent, label, setting, minVal, maxVal, step, xOffset, yOffset)
	local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate");
	slider:SetPoint("TOPLEFT", xOffset, yOffset);
	slider:SetWidth(160);
	slider:SetMinMaxValues(minVal, maxVal);
	slider:SetValueStep(step);
	slider:SetValue(C[setting] or minVal);
	slider.setting = setting;

	-- HIDE all template-created FontStrings to prevent overlap
	for _, region in pairs({slider:GetRegions()}) do
		if region:GetObjectType() == "FontString" then
			region:SetText("");
			region:Hide();
		end
	end

	-- Title (yellow GameFontNormal, centered above slider)
	local title = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	title:SetPoint("BOTTOM", slider, "TOP", 0, 3);
	title:SetText(label);

	-- Current value (white, centered below slider)
	slider.ValueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	slider.ValueText:SetPoint("TOP", slider, "BOTTOM", 0, -2);
	slider.ValueText:SetText(FormatSliderValue(step, C[setting] or minVal));

	-- Min value (small, left of slider)
	local lowText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	lowText:SetPoint("RIGHT", slider, "LEFT", -4, 0);
	lowText:SetText(tostring(minVal));
	lowText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE");

	-- Max value (small, right of slider)
	local highText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	highText:SetPoint("LEFT", slider, "RIGHT", 4, 0);
	highText:SetText(tostring(maxVal));
	highText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE");

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
		end
	end);

	return slider;
end

-- =========================================================
-- CreateDropdown
-- =========================================================
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

-- =========================================================
-- CreateSeparator (white horizontal line)
-- =========================================================
local function CreateSeparator(parent, xOffset, yOffset, width)
	local sep = parent:CreateTexture(nil, "ARTWORK");
	sep:SetTexture(1, 1, 1, 0.3);
	sep:SetPoint("TOPLEFT", xOffset, yOffset);
	sep:SetSize(width or 530, 1);
	return sep;
end


-- =========================================================
-- PopulateArenaTab - Main layout con ScrollFrame
-- ORDEN: Header > Modules > Scale/Spacing > Style(+Flat collapsible) > CastBar
-- =========================================================
function K.PopulateArenaTab(panel)

	local scrollFrame = CreateFrame("ScrollFrame", "NidhausArenaScrollFrame", panel, "UIPanelScrollFrameTemplate");
	scrollFrame:SetPoint("TOPLEFT", 4, -4);
	scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4);

	local scrollChild = CreateFrame("Frame", "NidhausArenaScrollChild", scrollFrame);
	scrollChild:SetWidth(scrollFrame:GetWidth() or 530);
	scrollChild:SetHeight(1);
	scrollFrame:SetScrollChild(scrollChild);

	local content = scrollChild;
	local fCol1 = 30;
	local fCol2 = 285;

	-- HEADER
	local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	header:SetPoint("TOPLEFT", 14, -10);
	header:SetText(L["HEADER_ARENA"]);

	local desc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4);
	desc:SetText(L["DESC_ARENA"]);

	-- Hint text (sArena style): "† Shift+Alt+Click to move various elements"
	local moveHint = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	moveHint:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -4);
	moveHint:SetText(L["ARENA_MOVE_HINT"] or "|cffFFAA00\226\128\160Shift+Alt+Click to move various elements|r");

	-- TOP ROW: Enable + Show Arena button
	local yPos = -54;
	CreateCheckBox(content, L["CB_ARENA_ON"], "ArenaFrameOn", 20, yPos);

	arenaShowBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate");
	arenaShowBtn:SetPoint("TOPLEFT", 280, yPos);
	arenaShowBtn:SetSize(180, 25);
	arenaShowBtn:SetText(L["BTN_SHOW_ARENA"]);
	arenaShowBtn:SetScript("OnClick", function()
		if IsActiveBattlefieldArena and IsActiveBattlefieldArena() then return; end
		if K.ToggleArenaFramesMover then K.ToggleArenaFramesMover(); end
	end);

	local function UpdateArenaShowButtonState()
		if not arenaShowBtn then return; end
		if IsActiveBattlefieldArena and IsActiveBattlefieldArena() then
			arenaShowBtn:Disable(); arenaShowBtn:SetAlpha(0.5);
		else
			arenaShowBtn:Enable(); arenaShowBtn:SetAlpha(1.0);
		end
	end
	arenaShowBtn:SetScript("OnShow", function() UpdateArenaShowButtonState(); end);
	local btnEvt = CreateFrame("Frame");
	btnEvt:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	btnEvt:RegisterEvent("PLAYER_ENTERING_WORLD");
	btnEvt:SetScript("OnEvent", function() UpdateArenaShowButtonState(); end);
	UpdateArenaShowButtonState();
	if not C.ArenaFrameOn then arenaShowBtn:Hide(); end

	local arenaHint = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	arenaHint:SetPoint("TOP", arenaShowBtn, "BOTTOM", 0, -2);
	arenaHint:SetText(L["ARENA_HINT"]);
	arenaHint:SetJustifyH("CENTER");

	-- SECTION 1: ARENA MODULES
	yPos = yPos - 40;
	CreateSeparator(content, 14, yPos, 540);
	yPos = yPos - 8;

	local modH = content:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	modH:SetPoint("TOPLEFT", 20, yPos);
	modH:SetText(L["HEADER_ARENA_MODULES"]);

	yPos = yPos - 22;
	CreateCheckBox(content, L["CB_MIRROR_MODE"],    "ArenaMirrorMode",          20, yPos);
	CreateCheckBox(content, L["CB_TRINKET_TRACK"],  "ArenaFrame_Trinkets",     280, yPos);
	yPos = yPos - 25;
	CreateCheckBox(content, L["CB_TRINKET_VOICE"],  "ArenaFrame_Trinket_Voice", 20, yPos);
	CreateCheckBox(content, L["CB_PET_FRAME_SHOW"] or "Show Pet Frame (Test Mode)",
		"ArenaPetFrameShow", 280, yPos);

	-- SECTION 2: SCALE & SPACING
	yPos = yPos - 35;
	CreateSeparator(content, 14, yPos, 540);
	yPos = yPos - 22;

	local scaleS = CreateSlider(content, L["SLIDER_ARENA_SCALE"],
		"ArenaFrameScale", 0.5, 2.0, 0.1, fCol1, yPos);
	scaleS:SetWidth(200);

	local spaceS = CreateSlider(content, L["SLIDER_ARENA_SPACING"],
		"ArenaFrameSpacing", 0, 100, 5, fCol2, yPos);
	spaceS:SetWidth(200);

	-- SECTION 3: ARENA STYLE + FLAT (collapsible)
	yPos = yPos - 60;
	CreateSeparator(content, 14, yPos, 540);
	yPos = yPos - 8;

	local styleStartY = yPos;

	local styleOptions = {
		{text = "Blizzard", value = "Blizzard"},
		{text = "Custom",   value = "Custom"},
		{text = "Flat",     value = "Flat"},
	};

	-- FLAT WRAPPER (60px below dropdown to avoid overlap)
	local flatAnchorY = styleStartY - 60;

	local flatWrapper = CreateFrame("Frame", "NidhausArenaFlatWrapper", content);
	flatWrapper:SetPoint("TOPLEFT", 0, flatAnchorY);
	flatWrapper:SetWidth(540);

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

	local petCB = CreateCheckBox(flatWrapper, L["CB_FLAT_PET_STYLE"] or "Flat Pet Style",
		"ArenaFlatPetStyle", fCol2, fY);
	table.insert(flatSubControls, petCB);

	fY = fY - 30;
	local statusTextCB = CreateCheckBox(flatWrapper, L["CB_FLAT_STATUS_TEXT"] or "Force Status Text",
		"ArenaFlatStatusText", fCol1, fY);
	table.insert(flatSubControls, statusTextCB);

	fY = fY - 30;
	local flatWrapperHeight = math.abs(fY);
	flatWrapper:SetHeight(flatWrapperHeight);

	-- CAST BAR SECTION (dynamic position)
	local castBarSection = CreateFrame("Frame", "NidhausArenaCastBarSection", content);
	castBarSection:SetWidth(540);

	local cY = 0;
	CreateSeparator(castBarSection, 14, cY, 540);
	cY = cY - 8;

	local cbH = castBarSection:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	cbH:SetPoint("TOPLEFT", 20, cY);
	cbH:SetText(L["HEADER_CASTBAR"]);

	cY = cY - 22;
	CreateCheckBox(castBarSection, L["CB_CASTBAR_ENABLE"], "ArenaCastBarEnable", 20, cY);

	cY = cY - 42;
	local cbS = CreateSlider(castBarSection, L["SLIDER_CASTBAR_SCALE"],
		"ArenaCastBarScale", 0.1, 5.0, 0.1, fCol1, cY);
	cbS:SetWidth(130); cbS.setting = "ArenaCastBarScale";
	table.insert(castBarSubControls, cbS);

	local cbW = CreateSlider(castBarSection, L["SLIDER_CASTBAR_WIDTH"],
		"ArenaCastBarWidth", 10, 400, 5, fCol2, cY);
	cbW:SetWidth(130); cbW.setting = "ArenaCastBarWidth";
	table.insert(castBarSubControls, cbW);

	local cbResetBtn = CreateFrame("Button", nil, castBarSection, "UIPanelButtonTemplate");
	cbResetBtn:SetPoint("TOPLEFT", fCol2 + 170, cY + 2);
	cbResetBtn:SetSize(60, 22);
	cbResetBtn:SetText(L["BTN_RESET_CASTBAR"] or "Reset");
	cbResetBtn:SetScript("OnClick", function()
		local defs = { ArenaCastBarScale = 1.0, ArenaCastBarWidth = 80 };
		for k, v in pairs(defs) do K.SaveConfig(k, v); C[k] = v; end
		for _, ctrl in ipairs(castBarSubControls) do
			if ctrl.SetValue and ctrl.setting and defs[ctrl.setting] ~= nil then
				ctrl:SetValue(defs[ctrl.setting]);
				if ctrl.ValueText then
					ctrl.ValueText:SetText(FormatSliderValue(ctrl:GetValueStep() or 1, defs[ctrl.setting]));
				end
			end
		end
		for i = 1, (MAX_ARENA_ENEMIES or 5) do
			local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
			if castBar then castBar:SetScale(1.0); castBar:SetWidth(80); end
		end
		if NidhausUnitFramesDB then NidhausUnitFramesDB.CastBarPositions = nil; end
	end);
	table.insert(castBarSubControls, cbResetBtn);

	local castBarSectionHeight = math.abs(cY) + 40;
	castBarSection:SetHeight(castBarSectionHeight);

	if not C.ArenaCastBarEnable then
		for _, ctrl in ipairs(castBarSubControls) do ctrl:Hide(); end
	end

	-- DYNAMIC LAYOUT
	local function UpdateLayout(flatVisible)
		local castBarY;
		if flatVisible then
			castBarY = flatAnchorY - flatWrapperHeight - 10;
		else
			castBarY = flatAnchorY - 5;
		end
		castBarSection:ClearAllPoints();
		castBarSection:SetPoint("TOPLEFT", 0, castBarY);
		scrollChild:SetHeight(math.abs(castBarY) + castBarSectionHeight + 20);
	end

	local function SetFlatVisible(show)
		if show then flatWrapper:Show(); else flatWrapper:Hide(); end
		UpdateLayout(show);
	end

	-- STYLE CHANGE (logica ORIGINAL sin tocar - funcionaba antes)
	local function OnStyleChange(value)
		local isFlat = (value == "Flat");

		if isFlat and C.ArenaMirrorMode then
			if K.ResetMirrorCastBars then K.ResetMirrorCastBars(); end
		end

		if K.RemoveAllFlatStyles then K.RemoveAllFlatStyles(); end
		if K.RemoveAllFlatPetStyles then K.RemoveAllFlatPetStyles(); end

		if value == "Custom" then
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

		-- Re-style SOLO si mover visible (test mode)
		if NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown then
			if K.StyleSingleArenaFrame then
				for i = 1, MOVER_ARENA_COUNT do
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
	end

	CreateDropdown(content, L["LABEL_ARENA_STYLE"] or "Arena Style", "ArenaFrameStyle",
		styleOptions, 20, styleStartY, OnStyleChange);

	local isCurrentlyFlat = (C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true);
	SetFlatVisible(isCurrentlyFlat);

	return arenaShowBtn;
end