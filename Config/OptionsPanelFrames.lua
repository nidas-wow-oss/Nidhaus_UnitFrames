local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- OptionsPanelFrames.lua
-- Tab 2: Frames — Localización Restaurada (Verde / Blanco)
-- =========================================================

local tooltips = {
	PlayerFrameScale        = "TIP_PlayerFrameScale",
	TargetFrameScale        = "TIP_TargetFrameScale",
	FocusScale              = "TIP_FocusScale",
	FocusSpellBarScale      = "TIP_FocusSpellBarScale",
	PartyFrameScale         = "TIP_PartyFrameScale",
	PartyMemberFrameSpacing = "TIP_PartyMemberFrameSpacing",
	BossFrameScale          = "TIP_BossFrameScale",
	BossTargetFrameSpacing  = "TIP_BossTargetFrameSpacing",
	NewPartyFrame           = "TIP_NewPartyFrame",
	PartyTargetsEnabled     = "TIP_PartyTargets",
};

local function AddTooltip(frame, setting)
	local tipKey = tooltips[setting];
	if not tipKey then return; end
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L[setting] or setting, 1, 1, 1);
		GameTooltip:AddLine(L[tipKey] or tipKey, nil, nil, nil, true);
		GameTooltip:Show();
	end);
	frame:SetScript("OnLeave", function() GameTooltip:Hide(); end);
end

local checkboxCount = 0;

local function CreateFeatureCheckBox(parent, labelText, xOffset, yOffset, tooltipText, setting)
	checkboxCount = checkboxCount + 1;
	local cbName = "NidhausFramesCB" .. checkboxCount;
	local cb = CreateFrame("CheckButton", cbName, parent, "UICheckButtonTemplate");
	cb:SetPoint("TOPLEFT", xOffset, yOffset);
	cb:SetHitRectInsets(0, 0, 0, 0);

	local label = _G[cbName .. "Text"];
	if label then
		label:SetText("|cff66CCFF" .. labelText .. "|r");
		label:SetFontObject("GameFontHighlightSmall"); 
	else
		label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		label:SetPoint("LEFT", cb, "RIGHT", 2, 0);
		label:SetText("|cff66CCFF" .. labelText .. "|r");
	end

	if tooltipText then
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(labelText, 1, 1, 1);
			GameTooltip:AddLine(tooltipText, nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end

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
	slider:SetWidth(155);
	slider:SetMinMaxValues(minVal, maxVal);
	slider:SetValueStep(step);
	slider:SetValue(C[setting] or minVal);
	slider.setting = setting;

	for _, region in pairs({slider:GetRegions()}) do
		if region:GetObjectType() == "FontString" then
			region:SetText(""); 
			region:Hide();
		end
	end

	local title = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	title:SetPoint("BOTTOM", slider, "TOP", 0, 3);
	title:SetText(label);

	slider.ValueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	slider.ValueText:SetPoint("TOP", slider, "BOTTOM", 0, -2);
	slider.ValueText:SetText(FormatSliderValue(step, C[setting] or minVal));

	local lowText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	lowText:SetPoint("RIGHT", slider, "LEFT", -4, 0);
	lowText:SetText(tostring(minVal));
	lowText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE");

	local highText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	highText:SetPoint("LEFT", slider, "RIGHT", 4, 0);
	highText:SetText(tostring(maxVal));
	highText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE");

	AddTooltip(slider, setting);

	-- FIX PERF: Apply visual changes immediately during drag, but only save
	-- to DB (with CONFIG_CHANGED event) on mouse release. This eliminates
	-- ~120-240 callback executions/sec while dragging sliders.
	slider._lastValue = C[setting] or minVal;

	slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value / step + 0.5) * step;
		-- FIX: Guard against double-fire (SetValue inside OnValueChanged)
		if self._lastValue == value then return; end
		self._lastValue = value;
		self:SetValue(value);
		slider.ValueText:SetText(FormatSliderValue(step, value));

		-- Apply visual effect immediately (no DB save, no CONFIG_CHANGED)
		C[setting] = value;

		if setting == "PlayerFrameScale" then
			local f = _G["NidhausPlayerFrame"] or PlayerFrame;
			if f then f:SetScale(value); end
		elseif setting == "TargetFrameScale" then
			if TargetFrame then TargetFrame:SetScale(value); end
		elseif setting == "FocusScale" then
			if FocusFrame then FocusFrame:SetScale(value); end
		elseif setting == "FocusSpellBarScale" then
			if FocusFrameSpellBar then FocusFrameSpellBar:SetScale(value); end
		elseif setting == "PartyFrameScale" then
			for i = 1, MAX_PARTY_MEMBERS do
				local pf = _G["PartyMemberFrame"..i];
				if pf then pf:SetScale(value); end
			end
		elseif setting == "PartyMemberFrameSpacing" then
			if K.ApplyPartyFrameSpacing then K.ApplyPartyFrameSpacing(); end
		elseif setting == "BossFrameScale" then
			if K.ApplyBossFrameScale then K.ApplyBossFrameScale(value); end
		elseif setting == "BossTargetFrameSpacing" then
			if K.ApplyBossFrameSpacing then K.ApplyBossFrameSpacing(); end
		end
	end);

	-- FIX PERF: Save to DB only when user releases the slider
	-- This triggers CONFIG_CHANGED exactly ONCE instead of 30+ times per drag
	slider:SetScript("OnMouseUp", function(self)
		if K.SaveConfig then K.SaveConfig(setting, C[setting]); end
	end);

	return slider;
end

function K.PopulateFramesTab(panel)
	-- ── HEADER ─────────────────────────────
	local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	header:SetPoint("TOPLEFT", 16, -12);
	-- TÍTULO: Usamos L["HEADER_FRAMES"] (Verde)
	-- Si el sistema está en ES, L["HEADER_FRAMES"] devolverá "Configuración de Frames"
	header:SetText("|cff00ff00" .. (L["HEADER_FRAMES"] or "Frames Configuration") .. "|r");

	-- SUBTÍTULO: Usamos L["HEADER_SCALES_NEW"] (Blanco)
	-- Si el sistema está en ES, L["HEADER_SCALES_NEW"] devolverá "Ajusta espacio y escala..."
	local subHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
	subHeader:SetPoint("LEFT", header, "RIGHT", 10, 0);
	subHeader:SetText("|cffffffff" .. (L["HEADER_SCALES_NEW"] or "Adjust spacing and scale") .. "|r");

	-- SECCIÓN 1: PARTY FEATURES BOX (ARRIBA)
	local featureBox = CreateFrame("Frame", nil, panel);
	featureBox:SetPoint("TOPLEFT", 12, -45); 
	featureBox:SetPoint("TOPRIGHT", -12, -45);
	featureBox:SetHeight(75); 
	featureBox:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 14,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	});
	featureBox:SetBackdropColor(0.05, 0.15, 0.3, 0.4);
	featureBox:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8);

	-- Título de la sección de party
	local boxTitle = featureBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	boxTitle:SetPoint("BOTTOMLEFT", featureBox, "TOPLEFT", 5, 2);
	boxTitle:SetText(L["HEADER_PARTY_FEATURES"] or "Party Features");

	local col1X = 6;
	local col2X = 135; 
	local cbY1 = -6;
	
	local npfCB = CreateFeatureCheckBox(featureBox, L["CB_NEW_PARTY_FRAME_SHORT"] or "New Party", col1X, cbY1, L["TIP_NewPartyFrame"], "NewPartyFrame");
	npfCB:SetChecked(C.NewPartyFrame);
	npfCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.NewPartyFrame = val;
		if K.SaveConfig then K.SaveConfig("NewPartyFrame", val); end
		if val then if K.EnableNewPartyFrame then K.EnableNewPartyFrame(); end
		else if K.DisableNewPartyFrame then K.DisableNewPartyFrame(); end end
	end);

	if K.Modules and K.Modules["PartyBuffs"] then
		local pbCB = CreateFeatureCheckBox(featureBox, L["CB_PARTY_BUFFS_SHORT"] or "Party Buffs", col2X, cbY1, L["TIP_PartyBuffs"], "PartyBuffs");
		pbCB:SetChecked(K.IsModuleEnabled("PartyBuffs"));
		pbCB:SetScript("OnClick", function(self)
			local val = self:GetChecked() and true or false;
			K.SetModuleEnabled("PartyBuffs", val);
		end);
	end

	local cbY2 = -35; 
	local ptCB = CreateFeatureCheckBox(featureBox, L["CB_PARTY_TARGETS_SHORT"] or "Party Targets", col1X, cbY2, L["TIP_PartyTargets"], "PartyTargetsEnabled");
	ptCB:SetChecked(C.PartyTargetsEnabled);
	ptCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.PartyTargetsEnabled = val;
		if K.SaveConfig then K.SaveConfig("PartyTargetsEnabled", val); end
		if K.ApplyPartyTargetsState then K.ApplyPartyTargetsState(val); end
	end);

	local pcbCB = CreateFeatureCheckBox(featureBox, L["CB_PARTY_CASTBARS_SHORT"] or "Party Castbars", col2X, cbY2, L["TIP_PartyCastingBars"] or "Enable party casting bars next to party unit frames.", "PartyCastingBars");
	-- Leer estado inicial desde C[] (ConfigManager ya lo cargó correctamente desde DB)
	local pcbEnabled = (C.PCB_Enabled == true);
	pcbCB:SetChecked(pcbEnabled);
	pcbCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		-- BUG FIX: K.SaveConfig actualiza TANTO C.PCB_Enabled COMO NidhausUnitFramesDB.PCB_Enabled.
		-- Sin esta llamada, SyncConfigToDB (que lee C[]) sobrescribia el DB con el valor viejo al salir.
		K.SaveConfig("PCB_Enabled", val);
		-- EnableToggle aplica el efecto funcional inmediato en las barras
		if PartyCastingBars and PartyCastingBars.EnableToggle then
			PartyCastingBars.EnableToggle(val);
		end
	end);

	-- ── LÍNEA DIVISORIA ──
	local sep = panel:CreateTexture(nil, "ARTWORK");
	sep:SetTexture(1, 1, 1, 0.1);
	sep:SetPoint("TOPLEFT", featureBox, "BOTTOMLEFT", 10, -6);
	sep:SetPoint("TOPRIGHT", featureBox, "BOTTOMRIGHT", -10, -6);
	sep:SetHeight(1);

	-- SECCIÓN 2: SLIDERS (ABAJO)
	local xLeft  = 35;
	local xRight = 350;
	local sliderH = 60;  
	local topY = -145;   

	-- ── COLUMNA IZQUIERDA (Player, Target, Focus)
	local yL = topY;
	CreateSlider(panel, L["SLIDER_PLAYER_SCALE"], "PlayerFrameScale", 0.5, 1.5, 0.05, xLeft, yL);
	yL = yL - sliderH;
	CreateSlider(panel, L["SLIDER_TARGET_SCALE"], "TargetFrameScale", 0.5, 1.5, 0.05, xLeft, yL);
	
	yL = yL - sliderH + 4; 
	local focusHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
	focusHeader:SetPoint("TOPLEFT", xLeft - 15, yL);
	focusHeader:SetText(L["HEADER_FOCUS"] or "|cffffd100Focus Settings|r");
	
	yL = yL - 20; 
	CreateSlider(panel, L["SLIDER_FOCUS_SCALE"], "FocusScale", 0.5, 1.5, 0.05, xLeft, yL);
	yL = yL - sliderH;
	CreateSlider(panel, L["SLIDER_FOCUS_SPELLBAR"], "FocusSpellBarScale", 0.5, 1.5, 0.05, xLeft, yL);

	-- ── COLUMNA DERECHA (Party, Boss)
	local yR = topY;
	local partyHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
	partyHeader:SetPoint("TOPLEFT", xRight - 15, yR + 15);
	partyHeader:SetText(L["HEADER_PARTY"] or "|cffffd100Party Settings|r");
	
	yR = yR - 12;
	CreateSlider(panel, L["SLIDER_PARTY_SCALE"], "PartyFrameScale", 0.5, 1.5, 0.05, xRight, yR);
	yR = yR - sliderH;
	CreateSlider(panel, L["SLIDER_PARTY_SPACING"], "PartyMemberFrameSpacing", 0, 80, 2, xRight, yR);

	yR = yR - sliderH + 8; 
	local bossHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
	bossHeader:SetPoint("TOPLEFT", xRight - 15, yR);
	bossHeader:SetText(L["HEADER_BOSS"] or "|cffffd100Boss Frames|r");

	local showBossBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate");
	showBossBtn:SetPoint("LEFT", bossHeader, "RIGHT", 8, 0); 
	showBossBtn:SetSize(90, 18);
	showBossBtn:SetText(L["BTN_SHOW_BOSS"] or "Show Boss");
	showBossBtn:SetScript("OnClick", function()
		if SlashCmdList and SlashCmdList["NUF"] then SlashCmdList["NUF"]("boss"); end
	end);

	yR = yR - 25;
	CreateSlider(panel, L["SLIDER_BOSS_SCALE"], "BossFrameScale", 0.3, 1.5, 0.05, xRight, yR);
	yR = yR - sliderH;
	CreateSlider(panel, L["SLIDER_BOSS_SPACING"], "BossTargetFrameSpacing", -50, 100, 5, xRight, yR);

end