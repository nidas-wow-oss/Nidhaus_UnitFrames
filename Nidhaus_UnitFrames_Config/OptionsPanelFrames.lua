



local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);






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
		label:SetText((K.UI and K.UI.Label(labelText)) or labelText);
		label:SetFontObject("GameFontHighlightSmall");
	else
		label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		label:SetPoint("LEFT", cb, "RIGHT", 2, 0);
		label:SetText((K.UI and K.UI.Label(labelText)) or labelText);
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



local scaleSliders = {};

function K.RefreshScaleSliders()
	for _, s in ipairs(scaleSliders) do
		local value = C[s.setting];
		if type(value) == "number" then
			s._lastValue = value;
			s:SetValue(value);
			if s.ValueText and s._fmt then
				local t = s._fmt(value);
				s.ValueText:SetText((K.UI and K.UI.Value(t)) or t);
			end
		end
	end
end

local function CreateSlider(parent, label, setting, minVal, maxVal, step, xOffset, yOffset)
	local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate");
	slider:SetPoint("TOPLEFT", xOffset, yOffset);
	slider:SetWidth(210);
	slider:SetMinMaxValues(minVal, maxVal);
	slider:SetValueStep(step);
	slider:SetValue(C[setting] or minVal);
	slider.setting = setting;


	K.UI.SliderEnds(slider, FormatSliderValue(step, minVal), FormatSliderValue(step, maxVal));





	local title = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	title:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 2);
	title:SetText((K.UI and K.UI.Label(K.UI.Strip(label))) or label);

	slider.ValueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	slider.ValueText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 2);
	slider.ValueText:SetText((K.UI and K.UI.Value(FormatSliderValue(step, C[setting] or minVal)))
		or FormatSliderValue(step, C[setting] or minVal));








	slider._nufOwnValue = slider.ValueText;

	AddTooltip(slider, setting);




	slider._lastValue = C[setting] or minVal;

	slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value / step + 0.5) * step;

		if self._lastValue == value then return; end
		self._lastValue = value;
		self:SetValue(value);
		slider.ValueText:SetText((K.UI and K.UI.Value(FormatSliderValue(step, value))) or FormatSliderValue(step, value));


		C[setting] = value;






















		local aplicado = false;
		local movables = K.GetMovablesForSetting and K.GetMovablesForSetting(setting);
		if movables and K.SetGlobalFrameScale then
			for _, mk in ipairs(movables) do
				if K.SetGlobalFrameScale(mk, value) then aplicado = true; end
			end
		end

		if aplicado then

		elseif setting == "FocusScale" then
			if K.ApplyFocusFrameScale then K.ApplyFocusFrameScale(value); end
		elseif setting == "PartyFrameScale" then


			if not (K.Is3v3Active and K.Is3v3Active()) and K.ApplyPartyFrameScale then
				K.ApplyPartyFrameScale(value);
			end
		elseif setting == "FocusSpellBarScale" then
			if FocusFrameSpellBar then FocusFrameSpellBar:SetScale(value); end
		elseif setting == "PartyMemberFrameSpacing" then
			if K.ApplyPartyFrameSpacing then K.ApplyPartyFrameSpacing(); end
		elseif setting == "BossFrameScale" then


			if K.ApplyBossFrameScale then K.ApplyBossFrameScale(value); end
		elseif setting == "BossTargetFrameSpacing" then
			if K.ApplyBossFrameSpacing then K.ApplyBossFrameSpacing(); end
		end
	end);



	slider:SetScript("OnMouseUp", function(self)
		if K.SaveConfig then K.SaveConfig(setting, C[setting]); end
	end);

	slider._fmt = function(v) return FormatSliderValue(step, v); end;
	table.insert(scaleSliders, slider);

	return slider;
end








function K.BuildPartyFeatureCheckboxes(parent, x, y, onResize)












	local ROW_H, SUB_H = 28, 24;
	local BTN_X  = x + 150;
	local rows, buttons = {}, {};



	local function OpenButton(slashKey, isOn)
		local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate");
		b:SetSize(70, 20);
		b:SetText(L["BTN_OPEN"] or "Open");
		b:SetScript("OnClick", function()
			if SlashCmdList and SlashCmdList[slashKey] then
				SlashCmdList[slashKey]("");
			end
		end);
		b.Sync = function()
			if isOn() then b:Enable(); else b:Disable(); end
		end;
		b:Sync();
		buttons[#buttons + 1] = b;
		return b;
	end

	local function AddRow(cb, btn, indent, h, visible)
		rows[#rows + 1] = { cb = cb, btn = btn, indent = indent or 0, h = h or ROW_H, visible = visible };
	end

	local function Relayout()
		local cy = y;
		for _, r in ipairs(rows) do
			if not r.visible or r.visible() then
				r.cb:ClearAllPoints();
				r.cb:SetPoint("TOPLEFT", x + r.indent, cy);
				r.cb:Show();
				if r.btn then
					r.btn:ClearAllPoints();
					r.btn:SetPoint("TOPLEFT", BTN_X, cy + 2);
					r.btn:Show();
				end
				cy = cy - r.h;
			else
				r.cb:Hide();
				if r.btn then r.btn:Hide(); end
			end
		end
		if onResize then onResize(y - cy); end
	end












	local SyncPB;
	if K.Modules and K.Modules["PartyBuffs"] and K.PartyBuffs_SetShown then
		local pbCB = CreateFeatureCheckBox(parent, L["CB_PARTY_BUFFS_SHORT"] or "Party Buffs",
			x, y, L["TIP_PartyBuffs"], "PartyBuffs");
		local pbBtn = OpenButton("PARTYBUFFS", function()
			return (K.PartyBuffs_GetShown());
		end);
		local castCB = CreateFeatureCheckBox(parent, L["CB_PARTY_CASTABLE_BUFFS"] or "Castable Buffs",
			x, y, L["TIP_PartyCastableBuffs"], "PartyCastableBuffs");

		local pdCB = CreateFeatureCheckBox(parent, L["CB_PARTY_DEBUFFS_SHORT"] or "Party Debuffs",
			x, y, L["TIP_PartyDebuffs"], "PartyDebuffs");
		local pdBtn = OpenButton("PARTYBUFFS", function()
			local _, d = K.PartyBuffs_GetShown();
			return d;
		end);
		local dispCB = CreateFeatureCheckBox(parent, L["CB_PARTY_DISPEL_DEBUFFS"] or "Dispellable Debuffs",
			x, y, L["TIP_PartyDispelDebuffs"], "PartyDispelDebuffs");

		local function HasFilter(which)
			return K.PartyBuffs_HasBlizzFilter and K.PartyBuffs_HasBlizzFilter(which);
		end

		SyncPB = function()
			local bOn, dOn = K.PartyBuffs_GetShown();
			pbCB:SetChecked(bOn);
			pdCB:SetChecked(dOn);
			if K.PartyBuffs_GetBlizzFilter then
				castCB:SetChecked(K.PartyBuffs_GetBlizzFilter("buffs"));
				dispCB:SetChecked(K.PartyBuffs_GetBlizzFilter("debuffs"));
			end
			pbBtn:Sync();
			pdBtn:Sync();
		end

		AddRow(pbCB, pbBtn);
		AddRow(castCB, nil, 22, SUB_H, function() return pbCB:GetChecked() and HasFilter("buffs"); end);
		AddRow(pdCB, pdBtn);
		AddRow(dispCB, nil, 22, SUB_H, function() return pdCB:GetChecked() and HasFilter("debuffs"); end);

		pbCB:SetScript("OnClick", function(self)
			K.PartyBuffs_SetShown("buffs", self:GetChecked() and true or false);
			SyncPB();
			Relayout();
		end);
		pdCB:SetScript("OnClick", function(self)
			K.PartyBuffs_SetShown("debuffs", self:GetChecked() and true or false);
			SyncPB();
			Relayout();
		end);
		castCB:SetScript("OnClick", function(self)
			if K.PartyBuffs_SetBlizzFilter then
				K.PartyBuffs_SetBlizzFilter("buffs", self:GetChecked() and true or false);
			end
			SyncPB();
		end);
		dispCB:SetScript("OnClick", function(self)
			if K.PartyBuffs_SetBlizzFilter then
				K.PartyBuffs_SetBlizzFilter("debuffs", self:GetChecked() and true or false);
			end
			SyncPB();
		end);
	end


	local ptCB = CreateFeatureCheckBox(parent, L["CB_PARTY_TARGETS_SHORT"] or "Party Targets",
		x, y, L["TIP_PartyTargets"], "PartyTargetsEnabled");
	ptCB:SetChecked(C.PartyTargetsEnabled);
	local ptBtn = OpenButton("PARTYTARGETS", function()
		return C.PartyTargetsEnabled and true or false;
	end);
	ptCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.PartyTargetsEnabled = val;
		if K.SaveConfig then K.SaveConfig("PartyTargetsEnabled", val); end
		if K.ApplyPartyTargetsState then K.ApplyPartyTargetsState(val); end
		ptBtn:Sync();
	end);
	AddRow(ptCB, ptBtn);


	local pcbCB = CreateFeatureCheckBox(parent, L["CB_PARTY_CASTBARS_SHORT"] or "Party Castbars",
		x, y, L["TIP_PartyCastingBars"] or "", "PartyCastingBars");
	pcbCB:SetChecked(C.PCB_Enabled == true);
	local pcbBtn = OpenButton("PARTYCASTINGBARS", function()
		return C.PCB_Enabled and true or false;
	end);
	pcbCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		K.SaveConfig("PCB_Enabled", val);
		if PartyCastingBars and PartyCastingBars.EnableToggle then
			PartyCastingBars.EnableToggle(val);
		end
		pcbBtn:Sync();
	end);
	AddRow(pcbCB, pcbBtn);




	if parent.HookScript then
		parent:HookScript("OnShow", function()
			if SyncPB then SyncPB(); end
			for _, b in ipairs(buttons) do b:Sync(); end
			Relayout();
		end);
	end
	if SyncPB then SyncPB(); end
	Relayout();
end














K._3v3Checkboxes = K._3v3Checkboxes or {};

function K.Register3v3Checkbox(cb)
	if not cb then return; end
	table.insert(K._3v3Checkboxes, cb);
	if K.Update3v3Enabled then K.Update3v3Enabled(); end
end

function K.Update3v3Enabled()
	local ok = (C.SetPositions == true);
	for _, cb in ipairs(K._3v3Checkboxes) do
		if cb.Enable then
			if ok then cb:Enable(); else cb:Disable(); end
			cb:SetAlpha(ok and 1 or 0.4);
			if cb.text then cb.text:SetAlpha(ok and 1 or 0.4); end
		end
	end
end






function K.CreateCustomPosCheckbox(parent, x, y)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate");
	cb:SetPoint("TOPLEFT", x, y);
	cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0);
	cb.text:SetText(L["CB_CUSTOM_POS"] or "Use Custom Positions");
	cb:SetChecked(C.SetPositions and true or false);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("SetPositions", cb); end

	cb:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CB_CUSTOM_POS"] or "Use Custom Positions", 1, 1, 1);
		GameTooltip:AddLine(L["TIP_SetPositions"] or "", nil, nil, nil, true);
		GameTooltip:Show();
	end);
	cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	cb:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SaveConfig then K.SaveConfig("SetPositions", v); end

		if K.Update3v3Enabled then K.Update3v3Enabled(); end

		if v then


			local gp = NidhausUnitFramesDB and NidhausUnitFramesDB.globalPos;


			if gp then
				gp.Player, gp.Target = nil, nil;
				for i = 1, 4 do gp["Party" .. i] = nil; end
			end
			if K.InitializePartyFrames then K.InitializePartyFrames(); end
			if K.ApplyFramePositions then K.ApplyFramePositions(); end
			if C.PartyMode3v3 and K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
			if K.ApplyArenaCustomPosition then K.ApplyArenaCustomPosition(true); end
		else
			if C.PartyMode3v3 and K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
			if K.ApplyFramePositions then K.ApplyFramePositions(); end
			if K.ApplyArenaCustomPosition then K.ApplyArenaCustomPosition(false); end
		end

		if K.PartyBuffs_OnFramesMoved then pcall(K.PartyBuffs_OnFramesMoved); end
	end);

	return cb;
end













K._3v3Sliders = K._3v3Sliders or { {}, {}, {}, {} };

local function Sync3v3Siblings(i, value, from)
	local list = K._3v3Sliders[i];
	if not list then return; end
	for _, other in ipairs(list) do
		if other ~= from and other._last ~= value then
			other._last = value;
			other:SetValue(value);
			local txt = string.format("%.2f", value);
			if other.ValueText then
				other.ValueText:SetText((K.UI and K.UI.Value(txt)) or txt);
			end
		end
	end
end




function K.Refresh3v3Sliders()
	for i = 1, 4 do
		local v = C["Party3v3Scale" .. i] or (K.Get3v3Scale and K.Get3v3Scale(i)) or 1.0;
		for _, sl in ipairs(K._3v3Sliders[i] or {}) do


			sl._last = v;
			sl:SetValue(v);
			local txt = string.format("%.2f", v);
			if sl.ValueText then sl.ValueText:SetText((K.UI and K.UI.Value(txt)) or txt); end
		end
	end
end



local function Build3v3MemberSliders(parent, cols, namePrefix)
	local box = CreateFrame("Frame", nil, parent);
	local rows = math.ceil(4 / cols);
	box:SetSize(cols * 115, rows * 50 + 8);

	for i = 1, 4 do
		local col = (i - 1) % cols;
		local row = math.floor((i - 1) / cols);
		local s = CreateFrame("Slider", namePrefix .. i, box, "OptionsSliderTemplate");
		s:SetPoint("TOPLEFT", col * 115, -18 - row * 50);
		s:SetWidth(96);
		s:SetMinMaxValues(0.5, 2.0);
		s:SetValueStep(0.05);
		s.setting = "Party3v3Scale" .. i;
		s:SetValue(C["Party3v3Scale" .. i] or K.Get3v3Scale and K.Get3v3Scale(i) or 1.0);
		K.UI.SliderEnds(s, "", "");

		local t = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		t:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2);
		local lbl = (L["LABEL_PARTY_MEMBER"] or "Party") .. " " .. i;
		t:SetText((K.UI and K.UI.Label(lbl)) or lbl);

		local v0 = C["Party3v3Scale" .. i] or (K.Get3v3Scale and K.Get3v3Scale(i)) or 1.0;
		s.ValueText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		s.ValueText:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 2);
		s.ValueText:SetText((K.UI and K.UI.Value(string.format("%.2f", v0))) or string.format("%.2f", v0));

		s._last = v0;
		s:SetScript("OnValueChanged", function(self, value)
			value = math.floor(value / 0.05 + 0.5) * 0.05;
			if self._last == value then return; end
			self._last = value;
			self:SetValue(value);
			local txt = string.format("%.2f", value);
			self.ValueText:SetText((K.UI and K.UI.Value(txt)) or txt);
			C[self.setting] = value;
			if K.Apply3v3MemberScale then K.Apply3v3MemberScale(i); end
			Sync3v3Siblings(i, value, self);
		end);
		s:SetScript("OnMouseUp", function(self)
			if K.SaveConfig then K.SaveConfig(self.setting, C[self.setting]); end
		end);

		table.insert(K._3v3Sliders[i], s);
	end
	return box;
end





local function Build3v3Checkbox(parent, globalName, onChange)
	local cb = CreateFrame("CheckButton", globalName, parent, "UICheckButtonTemplate");
	cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0);
	cb.text:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3");
	cb:SetChecked(C.PartyMode3v3 and true or false);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyMode3v3", cb); end
	if K.Register3v3Checkbox then K.Register3v3Checkbox(cb); end

	cb:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3", 1, 1, 1);
		GameTooltip:AddLine(L["TIP_PartyMode3v3"] or "", nil, nil, nil, true);
		GameTooltip:Show();
	end);
	cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	cb:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SaveConfig then K.SaveConfig("PartyMode3v3", v); end
		if v then
			if K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
		else
			if K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
		end

		if K.Update3v3SlidersVisibility then K.Update3v3SlidersVisibility(); end
		if onChange then onChange(); end
		if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
		if K.ScheduleGlobalPositionReapply then K.ScheduleGlobalPositionReapply(); end
	end);
	return cb;
end








local function FHeader(parent, text, x, y)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetText((K.UI and K.UI.Header(K.UI.Strip(text))) or text);
	return fs;
end

local function FNote(parent, text, x, y, width)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetWidth(width or 430);
	fs:SetJustifyH("LEFT");
	fs:SetText("|cff8EAEC9" .. (text or "") .. "|r");
	return fs;
end

function K.PopulateFramesTab(panel)
	local side = K.CreateSideList(panel, {
		{ name = L["SIDE_PTF"]    or "Player, Target and Focus" },
		{ name = L["SIDE_PARTY"]  or "Party" },
		{ name = L["SIDE_AURAS"]  or "Buffs and Debuffs" },
		{ name = L["SIDE_BOSS"]   or "Boss" },
		{ name = L["SIDE_PET"]    or "Pet" },
	});
	panel.sideList = side;

	local paneMain, paneParty, paneAuras, paneBoss, panePet =
		side[1], side[2], side[3], side[4], side[5];

	local x        = 20;
	local sliderH  = 46;
















	local xR = 300;
	local y  = -14;
	local ry = -14;


	FHeader(paneMain, L["HEADER_SCALES"] or "Scale", x, y);

	y = y - 30;
	CreateSlider(paneMain, L["SLIDER_PLAYER_SCALE"], "PlayerFrameScale", 0.5, 1.5, 0.05, x, y);
	y = y - sliderH;
	CreateSlider(paneMain, L["SLIDER_TARGET_SCALE"], "TargetFrameScale", 0.5, 1.5, 0.05, x, y);
	y = y - sliderH;
	CreateSlider(paneMain, L["SLIDER_FOCUS_SCALE"], "FocusScale", 0.5, 1.5, 0.05, x, y);



	y = y - sliderH + 6;
	FNote(paneMain, L["NOTE_FOCUS_SPELLBAR"]
		or "Focus cast bar scale lives in Interface > Cast Bar.", x, y, 220);
	y = y - 26;






	FHeader(paneMain, L["HEADER_3V3_SCALE"] or "Party 3v3 Scale", xR, ry);

	ry = ry - 26;
	local genMini;
	local function UpdateGen3v3()
		if not genMini then return; end
		if C.PartyMode3v3 then genMini:Show(); else genMini:Hide(); end
	end
	local gen3v3 = Build3v3Checkbox(paneMain, "NidhausFramesGen3v3CB", UpdateGen3v3);
	gen3v3:SetPoint("TOPLEFT", xR, ry);


	ry = ry - 32;
	genMini = Build3v3MemberSliders(paneMain, 2, "NidhausGen3v3Slider");
	genMini:SetPoint("TOPLEFT", xR + 4, ry);
	UpdateGen3v3();
	if K.RegisterConfigEvent then K.RegisterConfigEvent("CONFIG_CHANGED", UpdateGen3v3); end
	ry = ry - 108;


	local sy = math.min(y, ry) - 12;
	if K.UI and K.UI.Separator then K.UI.Separator(paneMain, x, sy, 540); end


	sy = sy - 14;
	FHeader(paneMain, L["HEADER_MOVE_FRAMES"] or "Move Unit Frames", x, sy);

	sy = sy - 22;
	local moveDesc = FNote(paneMain, L["DESC_MOVE_FRAMES"] or "", x + 2, sy, 520);



	local unlockBtn = CreateFrame("Button", nil, paneMain, "UIPanelButtonTemplate");
	unlockBtn:SetPoint("TOPLEFT", moveDesc, "BOTTOMLEFT", -2, -10);
	unlockBtn:SetSize(210, 24);




	local function FramesMoveNow()
		return K.IsGlobalUnlocked and K.IsGlobalUnlocked()
			and (not K.GetGlobalUnlockScope or K.GetGlobalUnlockScope() == "frames");
	end
	local function UnlockLabel()
		if FramesMoveNow() then
			unlockBtn:SetText(L["BTN_MOVE_ALL_DONE"] or "Lock All Frames");
		else
			unlockBtn:SetText(L["BTN_MOVE_FRAMES"] or "Unlock Unit Frames");
		end
	end
	UnlockLabel();
	unlockBtn:SetScript("OnClick", function()
		if K.SetGlobalUnlock then
			K.SetGlobalUnlock(not FramesMoveNow(), "frames");
		elseif K.ToggleGlobalUnlock then
			K.ToggleGlobalUnlock("frames");
		end
		UnlockLabel();
	end);
	unlockBtn:SetScript("OnShow", UnlockLabel);




	local resetScalesBtn = CreateFrame("Button", nil, paneMain, "UIPanelButtonTemplate");
	resetScalesBtn:SetPoint("TOPLEFT", unlockBtn, "TOPLEFT", xR - x, 0);
	resetScalesBtn:SetSize(210, 24);
	resetScalesBtn:SetText(L["BTN_RESET_FRAMES"] or "Reset Scales & Positions");
	resetScalesBtn:SetScript("OnClick", function()


		if K.ResetUnitFrames then
			K.ResetUnitFrames();
		elseif K.ResetPositionsAndScale then
			K.ResetPositionsAndScale();
		end
	end);


	local customPosCB = K.CreateCustomPosCheckbox(paneMain, x, sy);
	if customPosCB then
		customPosCB:ClearAllPoints();
		customPosCB:SetPoint("TOPLEFT", unlockBtn, "BOTTOMLEFT", 0, -6);
	end


	side.SetContentHeight(1, sy - 130);




	local py = -14;








	local testBtn = CreateFrame("Button", nil, paneParty);
	testBtn:SetPoint("TOPLEFT", x, py);
	testBtn:SetSize(200, 24);
	testBtn:SetFrameLevel(paneParty:GetFrameLevel() + 3);
	testBtn:EnableMouse(true);

	local tbBg = testBtn:CreateTexture(nil, "ARTWORK");
	tbBg:SetTexture("Interface\\Buttons\\WHITE8X8");
	tbBg:SetAllPoints(testBtn);
	tbBg:SetVertexColor(0.03, 0.08, 0.20, 0.95);

	local TB_BW = 1;
	local function TBEdge()
		local t = testBtn:CreateTexture(nil, "OVERLAY");
		t:SetTexture("Interface\\Buttons\\WHITE8X8");
		return t;
	end
	local tbTop = TBEdge();
	tbTop:SetPoint("TOPLEFT", testBtn, "TOPLEFT", 0, 0);
	tbTop:SetPoint("TOPRIGHT", testBtn, "TOPRIGHT", 0, 0);
	tbTop:SetHeight(TB_BW);
	local tbBot = TBEdge();
	tbBot:SetPoint("BOTTOMLEFT", testBtn, "BOTTOMLEFT", 0, 0);
	tbBot:SetPoint("BOTTOMRIGHT", testBtn, "BOTTOMRIGHT", 0, 0);
	tbBot:SetHeight(TB_BW);
	local tbLeft = TBEdge();
	tbLeft:SetPoint("TOPLEFT", testBtn, "TOPLEFT", 0, 0);
	tbLeft:SetPoint("BOTTOMLEFT", testBtn, "BOTTOMLEFT", 0, 0);
	tbLeft:SetWidth(TB_BW);
	local tbRight = TBEdge();
	tbRight:SetPoint("TOPRIGHT", testBtn, "TOPRIGHT", 0, 0);
	tbRight:SetPoint("BOTTOMRIGHT", testBtn, "BOTTOMRIGHT", 0, 0);
	tbRight:SetWidth(TB_BW);

	local tbLabel = testBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	tbLabel:SetPoint("CENTER", testBtn, "CENTER", 0, 0);
	tbLabel:SetText("|cff4fc3f7" .. (L["BTN_PARTY_TEST"] or "Test mode (4 fake members)") .. "|r");

	local function TestBtnRest()
		tbBg:SetVertexColor(0.03, 0.08, 0.20, 0.95);
		tbTop:SetVertexColor(0.30, 0.65, 1.00, 1.00);
		tbBot:SetVertexColor(0.25, 0.55, 0.90, 0.80);
		tbLeft:SetVertexColor(0.25, 0.55, 0.90, 0.80);
		tbRight:SetVertexColor(0.25, 0.55, 0.90, 0.80);
	end
	TestBtnRest();

	testBtn:SetScript("OnEnter", function()
		tbTop:SetVertexColor(0.60, 0.85, 1.00, 1.00);
		tbBot:SetVertexColor(0.60, 0.85, 1.00, 1.00);
		tbLeft:SetVertexColor(0.60, 0.85, 1.00, 1.00);
		tbRight:SetVertexColor(0.60, 0.85, 1.00, 1.00);
	end);
	testBtn:SetScript("OnLeave", TestBtnRest);
	testBtn:SetScript("OnClick", function()
		if K.TogglePartyTestMode then K.TogglePartyTestMode(); end
	end);
	py = py - 34;


	FHeader(paneParty, L["HEADER_PARTY_STYLE"] or "Frame Style", x, py);
	py = py - 20;
	FNote(paneParty, L["NOTE_PARTY_STYLE"]
		or "Pick one. The two custom styles retexture the same frames, so they cannot be on at the same time.",
		x + 2, py, 430);

	py = py - 30;
	do
		local styles = {
			{ value = "Default",  text = L["PARTY_STYLE_DEFAULT"]  or "Blizzard" },


			{ value = "PW",       text = L["PARTY_STYLE_PW"]       or "Big Blizzard" },
			{ value = "New",      text = L["PARTY_STYLE_NEW"]      or "New Party" },
			{ value = "Improved", text = L["PARTY_STYLE_IMPROVED"] or "Improved" },
			{ value = "PW2",      text = L["PARTY_STYLE_PW2"]      or "Compact 2" },
		};

		local btnW, btnH, gap = 66, 22, 4;
		local styleButtons = {};

		local container = CreateFrame("Frame", nil, paneParty);
		container:SetPoint("TOPLEFT", x + 2, py);
		container:SetSize((#styles * btnW) + ((#styles - 1) * gap), btnH);

		local function RefreshStyle()
			local current = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or "Default";
			for _, b in ipairs(styleButtons) do
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

		K.RefreshPartyStyleSelector = RefreshStyle;

		for i, opt in ipairs(styles) do
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
				if K.SetPartyFrameStyle then K.SetPartyFrameStyle(self.value); end
				RefreshStyle();

				if K._UpdatePartyFontVisibility then K._UpdatePartyFontVisibility(); end
			end);
			b:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(opt.text, 1, 1, 1);
				GameTooltip:AddLine(L["TIP_PartyStyle_" .. opt.value] or "", nil, nil, nil, true);
				GameTooltip:Show();
			end);
			b:SetScript("OnLeave", function() GameTooltip:Hide(); end);

			table.insert(styleButtons, b);
		end
		RefreshStyle();
	end









	py = py - 44;




	local fontBody = K.UI.Collapsible(paneParty, x, py, 440, 104, function()
		local style = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or "Default";
		return style ~= "Default";
	end);

	FHeader(fontBody, L["HEADER_PARTY_FONT"] or "Text Outline", 0, 0);

	do
		local outlines = {
			{ value = "",                  text = L["OUTLINE_NONE"]      or "None" },
			{ value = "OUTLINE",           text = L["OUTLINE_NORMAL"]    or "Outline" },
			{ value = "THICKOUTLINE",      text = L["OUTLINE_THICK"]     or "Thick outline" },
			{ value = "Blizz",             text = L["OUTLINE_BLIZZ"]     or "Like health / mana text" },
		};
		local function OutText(v)
			for _, o in ipairs(outlines) do if o.value == v then return o.text; end end
			return outlines[1].text;
		end

		local lbl = fontBody:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		lbl:SetPoint("TOPLEFT", 2, -30);
		lbl:SetText((K.UI and K.UI.Label(L["LBL_PARTY_FONT"] or "Font outline"))
			or (L["LBL_PARTY_FONT"] or "Font outline"));

		local dd = CreateFrame("Frame", "NidhausPartyOutlineDD", fontBody, "UIDropDownMenuTemplate");
		dd:SetPoint("LEFT", lbl, "RIGHT", 4, -2);
		UIDropDownMenu_SetWidth(dd, 150);
		UIDropDownMenu_Initialize(dd, function(self, level)
			for _, opt in ipairs(outlines) do
				local info = UIDropDownMenu_CreateInfo();
				info.text  = opt.text;
				info.value = opt.value;
				info.func  = function(btn)
					UIDropDownMenu_SetSelectedValue(dd, btn.value);
					UIDropDownMenu_SetText(dd, OutText(btn.value));
					if K.SaveConfig then K.SaveConfig("PartyFontOutline", btn.value); end
					if K.RestylePartyFrames then K.RestylePartyFrames(); end
					if K.PFI_Restyle then K.PFI_Restyle(); end
				end;
				info.checked = (opt.value == (C.PartyFontOutline or "OUTLINE"));
				UIDropDownMenu_AddButton(info, level);
			end
		end);
		UIDropDownMenu_SetSelectedValue(dd, C.PartyFontOutline or "OUTLINE");
		UIDropDownMenu_SetText(dd, OutText(C.PartyFontOutline or "OUTLINE"));

	end


	do
		local fsSlider = CreateFrame("Slider", "NidhausPartyFontSizeSlider", fontBody,
			"OptionsSliderTemplate");
		fsSlider:SetPoint("TOPLEFT", 8, -66);
		fsSlider:SetWidth(200);

		fsSlider:SetMinMaxValues(0, 20);
		fsSlider:SetValueStep(1);
		local start = tonumber(C.PartyFontSize) or 0;
		fsSlider:SetValue(start);
		_G[fsSlider:GetName() .. "Low"]:SetText(L["PARTY_FONT_AUTO"] or "Auto");
		_G[fsSlider:GetName() .. "High"]:SetText("20");
		_G[fsSlider:GetName() .. "Text"]:SetText(L["SLIDER_PARTY_FONT_SIZE"] or "Text size");
		fsSlider:SetScript("OnValueChanged", function(self, v)
			v = math.floor(v + 0.5);
			if v > 0 and v < 6 then v = 6; end
			if K.SaveConfig then K.SaveConfig("PartyFontSize", v); end
			if K.RestylePartyFrames then K.RestylePartyFrames(); end
			if K.PFI_Restyle then K.PFI_Restyle(); end
		end);
		fsSlider:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["SLIDER_PARTY_FONT_SIZE"] or "Text size", 1, 1, 1);
			GameTooltip:AddLine(L["TIP_PartyFontSize"] or "", nil, nil, nil, true);
			GameTooltip:Show();
		end);
		fsSlider:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	end


	local function UpdatePartyFontVisibility()
		fontBody:Refresh();
	end
	K._UpdatePartyFontVisibility = UpdatePartyFontVisibility;






	local cbHide;
	do
		cbHide = CreateFrame("CheckButton", "NidhausPartyHideTextCB", paneParty,
			"InterfaceOptionsCheckButtonTemplate");





		cbHide:SetPoint("TOPLEFT", fontBody, "TOPLEFT", 250, -62);
		cbHide:SetHitRectInsets(0, 0, 0, 0);
		local fs = _G["NidhausPartyHideTextCBText"];
		if fs then fs:SetText(L["CB_PARTY_HIDE_TEXT"] or "Hide health / mana numbers"); end
		cbHide:SetChecked(C.PartyHideHealthManaText and true or false);
		if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyHideHealthManaText", cbHide); end
		cbHide:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["CB_PARTY_HIDE_TEXT"] or "Hide health / mana numbers", 1, 1, 1);
			GameTooltip:AddLine(L["TIP_PartyHideHealthManaText"] or "", nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cbHide:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		cbHide:SetScript("OnClick", function(self)
			local v = (self:GetChecked() == 1 or self:GetChecked() == true);
			if K.SaveConfig then K.SaveConfig("PartyHideHealthManaText", v); end
			if K.ApplyHealthTextFormat then K.ApplyHealthTextFormat(); end
		end);
	end








	local petSep = K.UI.Separator(paneParty, 0, 0, 440);
	petSep:ClearAllPoints();


	petSep:SetPoint("TOPLEFT", fontBody, "BOTTOMLEFT", -4, -10);

	local petHeader = FHeader(paneParty, L["HEADER_PARTY_PETS"] or "Pets", 0, 0);
	petHeader:ClearAllPoints();
	petHeader:SetPoint("TOPLEFT", petSep, "BOTTOMLEFT", 4, -10);

	local cbPPF;
	do
		cbPPF = CreateFrame("CheckButton", "NidhausParty1PetCB", paneParty, "UICheckButtonTemplate");
		cbPPF:SetPoint("TOPLEFT", petHeader, "BOTTOMLEFT", 0, -10);
		cbPPF.text = cbPPF:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		cbPPF.text:SetPoint("LEFT", cbPPF, "RIGHT", 4, 0);
		cbPPF.text:SetText(L["MOD_PARTYPETFRAME"] or "Party pet enhanced");
		cbPPF:SetChecked(K.IsModuleEnabled and K.IsModuleEnabled("PartyPetFrame") or false);
		if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox("PartyPetFrame", cbPPF); end
		cbPPF:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MOD_PARTYPETFRAME"] or "Party pet enhanced", 1, 1, 1);
			GameTooltip:AddLine(L["MOD_PARTYPETFRAME_DESC"] or "", nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cbPPF:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		cbPPF:SetScript("OnClick", function(self)
			local v = (self:GetChecked() == 1 or self:GetChecked() == true);
			if K.SetModuleEnabled then K.SetModuleEnabled("PartyPetFrame", v); end
			if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("PartyPetFrame"); end
		end);
	end


	local cbPet;
	do
		cbPet = CreateFrame("CheckButton", "NidhausPartyPetCB", paneParty, "UICheckButtonTemplate");


		cbPet:SetPoint("LEFT", cbPPF, "LEFT", 230, 0);
		cbPet.text = cbPet:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		cbPet.text:SetPoint("LEFT", cbPet, "RIGHT", 4, 0);









		cbPet.text:SetText(L["CB_PARTY_PETS_HIDE"] or "Hide party pet frames");
		cbPet.nufInverted = true;
		cbPet:SetChecked(C.PartyShowPetFrames == false);
		if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyShowPetFrames", cbPet); end
		cbPet:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["CB_PARTY_PETS_HIDE"] or "Hide party pet frames", 1, 1, 1);
			GameTooltip:AddLine(L["TIP_PartyPets"]
				or "The small frames of your party members' pets (hunter, warlock, DK...). Hiding them cleans up the screen in arena.",
				nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cbPet:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		cbPet:SetScript("OnClick", function(self)

			local hide = (self:GetChecked() == 1 or self:GetChecked() == true);
			if K.SaveConfig then K.SaveConfig("PartyShowPetFrames", not hide); end
			if K.ApplyPartyPetFrames then K.ApplyPartyPetFrames(); end
		end);
	end

	local modeSep = K.UI.Separator(paneParty, 0, 0, 440);
	modeSep:ClearAllPoints();


	modeSep:SetPoint("TOPLEFT", cbPPF, "BOTTOMLEFT", -4, -14);

	local modeHeader = FHeader(paneParty, L["HEADER_PARTY_MODE"] or "Mode", 0, 0);
	modeHeader:ClearAllPoints();
	modeHeader:SetPoint("TOPLEFT", modeSep, "BOTTOMLEFT", 4, -10);

	local cb3v3 = CreateFrame("CheckButton", "NidhausFrames3v3CB", paneParty, "UICheckButtonTemplate");
	cb3v3:SetPoint("TOPLEFT", modeHeader, "BOTTOMLEFT", 0, -10);
	cb3v3.text = cb3v3:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb3v3.text:SetPoint("LEFT", cb3v3, "RIGHT", 4, 0);
	cb3v3.text:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3");
	cb3v3:SetChecked(C.PartyMode3v3 and true or false);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyMode3v3", cb3v3); end
	cb3v3:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3", 1, 1, 1);
		GameTooltip:AddLine(L["TIP_PartyMode3v3"] or "", nil, nil, nil, true);
		GameTooltip:Show();
	end);
	cb3v3:SetScript("OnLeave", function() GameTooltip:Hide(); end);


	local mini = CreateFrame("Frame", nil, paneParty);
	mini:SetPoint("TOPLEFT", cb3v3, "BOTTOMLEFT", 0, -12);
	mini:SetSize(460, 58);

	for i = 1, 4 do
		local s = CreateFrame("Slider", "NidhausMini3v3Slider"..i, mini, "OptionsSliderTemplate");
		s:SetPoint("TOPLEFT", (i - 1) * 115, -18);
		s:SetWidth(96);
		s:SetMinMaxValues(0.5, 2.0);
		s:SetValueStep(0.05);
		s.setting = "Party3v3Scale"..i;
		s:SetValue(C["Party3v3Scale"..i] or 1.0);



		K.UI.SliderEnds(s, "", "");

		local t = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		t:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2);
		t:SetText((K.UI and K.UI.Label((L["LABEL_PARTY_MEMBER"] or "Party") .. " " .. i))
			or ((L["LABEL_PARTY_MEMBER"] or "Party") .. " " .. i));

		s.ValueText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		s.ValueText:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 2);
		s.ValueText:SetText((K.UI and K.UI.Value(string.format("%.2f", C["Party3v3Scale"..i] or 1.0)))
			or string.format("%.2f", C["Party3v3Scale"..i] or 1.0));

		s._last = C["Party3v3Scale"..i] or 1.0;

		table.insert(K._3v3Sliders[i], s);
		s:SetScript("OnValueChanged", function(self, value)
			value = math.floor(value / 0.05 + 0.5) * 0.05;
			if self._last == value then return; end
			self._last = value;
			self:SetValue(value);
			local txt = string.format("%.2f", value);
			self.ValueText:SetText((K.UI and K.UI.Value(txt)) or txt);
			C[self.setting] = value;
			if K.Apply3v3MemberScale then K.Apply3v3MemberScale(i); end

			Sync3v3Siblings(i, value, self);
		end);
		s:SetScript("OnMouseUp", function(self)
			if K.SaveConfig then K.SaveConfig(self.setting, C[self.setting]); end
		end);
	end








	local scaleGroup = CreateFrame("Frame", nil, paneParty);
	scaleGroup:SetPoint("TOPLEFT", mini, "BOTTOMLEFT", 0, -10);
	scaleGroup:SetWidth(440);
	scaleGroup:SetHeight(sliderH * 2 + 40);

	FHeader(scaleGroup, L["HEADER_SCALES"] or "Scale", 0, 0);
	CreateSlider(scaleGroup, L["SLIDER_PARTY_SCALE"], "PartyFrameScale", 0.5, 1.5, 0.05, 0, -30);
	CreateSlider(scaleGroup, L["SLIDER_PARTY_SPACING"], "PartyMemberFrameSpacing", 0, 80, 2, 0, -30 - sliderH);

	local MINI_H  = 58;
	local SCALE_H = sliderH * 2 + 40;



	local function Update3v3Visibility()
		if C.PartyMode3v3 then
			mini:Show();       mini:SetHeight(MINI_H);
			scaleGroup:Hide(); scaleGroup:SetHeight(1);
		else
			mini:Hide();       mini:SetHeight(1);
			scaleGroup:Show(); scaleGroup:SetHeight(SCALE_H);
		end
	end
	Update3v3Visibility();
	K.Update3v3SlidersVisibility = Update3v3Visibility;
	if K.RegisterConfigEvent then
		K.RegisterConfigEvent("CONFIG_CHANGED", Update3v3Visibility);
	end

	cb3v3:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SaveConfig then K.SaveConfig("PartyMode3v3", v); end
		if v then
			if K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
		else
			if K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
		end
		Update3v3Visibility();
		if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
		if K.ScheduleGlobalPositionReapply then K.ScheduleGlobalPositionReapply(); end
	end);



	local featBox = CreateFrame("Frame", nil, paneParty);
	featBox:SetPoint("TOPLEFT", scaleGroup, "BOTTOMLEFT", 0, -20);
	featBox:SetWidth(460);



	featBox:SetHeight(144);

	FHeader(featBox, L["HEADER_PARTY_FEATURES"] or "Party Features", 0, 0);



	local partyTailPy;
	local function UpdatePartyHeight()
		if not partyTailPy then return; end

		side.SetContentHeight(2, -810 - (featBox:GetHeight() - 116) + partyTailPy - 30);
	end
	K.BuildPartyFeatureCheckboxes(featBox, 0, -26, function(rowsH)
		featBox:SetHeight(26 + rowsH + 6);
		UpdatePartyHeight();
	end);
	py = py - 74 - SCALE_H - 138;






	local tailBox = CreateFrame("Frame", nil, paneParty);
	tailBox:SetPoint("TOPLEFT", featBox, "BOTTOMLEFT", 0, -10);
	tailBox:SetWidth(460);
	tailBox:SetHeight(300);
	py = 0;






	FNote(tailBox, L["NOTE_PARTY_SUBADDONS"]
		or "Commands: /pbuffs, /ptarget, /pcb",
		2, py, 430);
	py = py - 26;




	K.UI.Separator(tailBox, -4, py + 14, 440);
	FHeader(tailBox, L["HEADER_PARTY_TRINKET"] or "Party Trinkets", 0, py);
	py = py - 20;
	FNote(tailBox, L["NOTE_PARTY_TRINKET"]
		or "PvP trinket cooldown next to each party member. The position is shared by all four.",
		2, py, 430);

	py = py - 32;
	local ptCB = CreateFeatureCheckBox(tailBox, L["CB_PARTY_TRINKETS"] or "Show party trinkets",
		0, py, L["TIP_PartyTrinkets"], "PartyTrinketsEnabled");
	ptCB:SetChecked(C.PartyTrinketsEnabled);
	ptCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.PartyTrinketsEnabled = val;
		if K.SaveConfig then K.SaveConfig("PartyTrinketsEnabled", val); end
		if K.ApplyPartyTrinketSettings then K.ApplyPartyTrinketSettings(); end
	end);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyTrinketsEnabled", ptCB); end




	py = py - 30;
	local ptBody = K.UI.Collapsible(tailBox, 0, py, 440, 96, function()
		return C.PartyTrinketsEnabled == true;
	end);

	local ptMoveBtn = CreateFrame("Button", nil, ptBody, "UIPanelButtonTemplate");
	ptMoveBtn:SetPoint("TOPLEFT", 0, 0);
	ptMoveBtn:SetSize(150, 22);
	ptMoveBtn:SetText(L["BTN_MOVE_TRINKETS"] or "Move them");
	ptMoveBtn:SetScript("OnClick", function(self)
		local on = not (K.IsPartyTrinketMoveMode and K.IsPartyTrinketMoveMode());
		if K.SetPartyTrinketMoveMode then K.SetPartyTrinketMoveMode(on); end
		self:SetText(on and (L["BTN_LOCK_TRINKETS"] or "Done")
			or (L["BTN_MOVE_TRINKETS"] or "Move them"));
	end);

	local ptResetBtn = CreateFrame("Button", nil, ptBody, "UIPanelButtonTemplate");
	ptResetBtn:SetPoint("LEFT", ptMoveBtn, "RIGHT", 8, 0);
	ptResetBtn:SetSize(100, 22);
	ptResetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
	ptResetBtn:SetScript("OnClick", function()
		if K.ResetPartyTrinketPosition then K.ResetPartyTrinketPosition(); end
	end);

	local ptSize = CreateSlider(ptBody, L["SLIDER_PARTY_TRINKET_SIZE"] or "Trinket Size",
		"PartyTrinketSize", 12, 40, 1, 0, -46);
	ptSize:SetWidth(210);
	ptSize:HookScript("OnValueChanged", function()
		if K.ApplyPartyTrinketSettings then K.ApplyPartyTrinketSettings(); end
	end);



	ptCB:HookScript("OnClick", function(self)
		if not self:GetChecked() then
			if K.SetPartyTrinketMoveMode then K.SetPartyTrinketMoveMode(false); end
			ptMoveBtn:SetText(L["BTN_MOVE_TRINKETS"] or "Move them");
		end
		ptBody:Refresh();
	end);

	py = py - 110;






	partyTailPy = py;
	UpdatePartyHeight();




	local ay = -14;
	FHeader(paneAuras, L["HEADER_AURAS"] or "Player Buffs and Debuffs", x, ay);

	ay = ay - 22;
	FNote(paneAuras, L["DESC_AURAS"]
		or "Unlock to drag the buff and debuff blocks anywhere on the screen.",
		x + 2, ay, 215);

	ay = ay - 48;
	local auraBtn = CreateFrame("Button", nil, paneAuras, "UIPanelButtonTemplate");
	auraBtn:SetPoint("TOPLEFT", x, ay);
	auraBtn:SetSize(145, 24);
	auraBtn:SetText(L["BTN_MOVE_AURAS"] or "Unlock buffs / debuffs");
	auraBtn:SetScript("OnClick", function()
		if K.ToggleGlobalUnlock then K.ToggleGlobalUnlock("extra"); end
	end);

	local auraReset = CreateFrame("Button", nil, paneAuras, "UIPanelButtonTemplate");
	auraReset:SetPoint("LEFT", auraBtn, "RIGHT", 8, 0);
	auraReset:SetSize(75, 24);
	auraReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
	auraReset:SetScript("OnClick", function()



		if K.ResetAuras then K.ResetAuras();
		elseif K.ResetAuraAnchor then K.ResetAuraAnchor(); end
	end);


	ay = ay - 62;
	do
		local s = CreateFrame("Slider", nil, paneAuras, "OptionsSliderTemplate");
		s:SetPoint("TOPLEFT", x + 4, ay);
		s:SetWidth(215);
		s:SetMinMaxValues(4, 16);
		s:SetValueStep(1);
		K.UI.SliderEnds(s, "4", "16");
		local title = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		title:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2);
		title:SetText((K.UI and K.UI.Label(L["SLIDER_ICONS_PER_ROW"] or "Icons per row"))
			or (L["SLIDER_ICONS_PER_ROW"] or "Icons per row"));
		local val = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		val:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 2);

		local cur = (K.GetAuraIconsPerRow and K.GetAuraIconsPerRow()) or 8;
		s:SetValue(cur);
		val:SetText(tostring(cur));
		s._last = cur;
		s:SetScript("OnValueChanged", function(self, v)
			v = math.floor(v + 0.5);
			if self._last == v then return; end
			self._last = v;
			val:SetText(tostring(v));
			if K.SaveConfig then K.SaveConfig("AuraIconsPerRow", v); end
			if K.ApplyAuraIconsPerRow then K.ApplyAuraIconsPerRow(); end
		end);

		FNote(paneAuras, L["NOTE_ICONS_PER_ROW"]
			or "How many buff icons fit in one row before wrapping to the next.",
			x + 4, ay - 34, 215);
	end









	ay = ay - 84;
	if K.UI and K.UI.ScaleSlider then
		K.UI.ScaleSlider(paneAuras, "PlayerBuffs",   x + 4, ay, 215,
			L["SLIDER_BUFF_SCALE"] or "Buff scale");
		ay = ay - 56;
		K.UI.ScaleSlider(paneAuras, "PlayerDebuffs", x + 4, ay, 215,
			L["SLIDER_DEBUFF_SCALE"] or "Debuff scale");
	end

	ay = ay - 60;








	local ry = -14;
	FHeader(paneAuras, L["HEADER_AURA_BORDERS"] or "Target and Focus Auras", xR, ry);

	ry = ry - 24;
	local abCB = CreateFeatureCheckBox(paneAuras, L["CB_AURA_BORDERS"] or "Custom aura borders",
		xR, ry, L["TIP_AuraBordersEnabled"], "AuraBordersEnabled");
	abCB:SetChecked(C.AuraBordersEnabled and true or false);

	ry = ry - 24;
	FNote(paneAuras, L["NOTE_AURA_BORDERS"] or "", xR + 24, ry, 210);

	ry = ry - 56;
	local abPurgeCB = CreateFeatureCheckBox(paneAuras, L["CB_AURA_PURGE"] or "Highlight purgeable buffs",
		xR + 16, ry, L["TIP_AuraBordersPurge"], "AuraBordersPurge");
	abPurgeCB:SetChecked(C.AuraBordersPurge ~= false);


	local function SyncAuraBorderRow()
		local on = C.AuraBordersEnabled and true or false;
		if on then abPurgeCB:Enable(); else abPurgeCB:Disable(); end
		abPurgeCB:SetAlpha(on and 1 or 0.4);
	end
	SyncAuraBorderRow();

	abCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.AuraBordersEnabled = val;
		if K.SaveConfig then K.SaveConfig("AuraBordersEnabled", val); end
		if K.ApplyAuraBorders then K.ApplyAuraBorders(); end
		SyncAuraBorderRow();
	end);

	abPurgeCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.AuraBordersPurge = val;
		if K.SaveConfig then K.SaveConfig("AuraBordersPurge", val); end
		if K.ApplyAuraBorders then K.ApplyAuraBorders(); end
	end);




	ry = ry - 46;
	K.UI.Separator(paneAuras, xR, ry + 12, 215);

	ry = ry - 16;
	local castByCB = CreateFeatureCheckBox(paneAuras,
		L["CB_AURA_CAST_BY"] or "Show who cast the aura",
		xR, ry, L["TIP_AuraCastBy"], "AuraCastBy");
	castByCB:SetChecked(C.AuraCastBy and true or false);

	ry = ry - 24;
	FNote(paneAuras, L["NOTE_AURA_CAST_BY"] or "", xR + 24, ry, 210);

	castByCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.AuraCastBy = val;
		if K.SaveConfig then K.SaveConfig("AuraCastBy", val); end
	end);

	ry = ry - 40;


	side.SetContentHeight(3, math.min(ay, ry) - 30);




	local vy = -14;
	FHeader(paneBoss, L["HEADER_BOSS"] or "Boss Frames (PvE)", x, vy);

	local showBossBtn = CreateFrame("Button", nil, paneBoss, "UIPanelButtonTemplate");
	showBossBtn:SetPoint("TOPLEFT", x + 190, vy - 3);
	showBossBtn:SetSize(140, 20);
	showBossBtn:SetText(L["BTN_SHOW_BOSS"] or "Show Boss Frame");
	showBossBtn:SetScript("OnClick", function()
		if SlashCmdList and SlashCmdList["NUF"] then SlashCmdList["NUF"]("boss"); end
	end);

	vy = vy - 36;
	CreateSlider(paneBoss, L["SLIDER_BOSS_SCALE"], "BossFrameScale", 0.3, 1.5, 0.05, x, vy);
	vy = vy - sliderH;
	CreateSlider(paneBoss, L["SLIDER_BOSS_SPACING"], "BossTargetFrameSpacing", -50, 100, 5, x, vy);
	vy = vy - sliderH;

	side.SetContentHeight(4, vy - 40);




	local pv = -14;
	FHeader(panePet, L["HEADER_PET"] or "Pet Frame", x, pv);

	pv = pv - 24;
	FNote(panePet, L["NOTE_PET"]
		or "Scale of your pet frame (hunter, warlock, mage water elemental, death knight ghoul).",
		x + 2, pv, 430);

	pv = pv - 36;
	CreateSlider(panePet, L["SLIDER_PET_SCALE"] or "Pet Frame Scale", "PetFrameScale",
		0.5, 1.5, 0.05, x, pv);
	pv = pv - sliderH - 6;

	local petResetBtn = CreateFrame("Button", nil, panePet, "UIPanelButtonTemplate");
	petResetBtn:SetPoint("TOPLEFT", x, pv);
	petResetBtn:SetSize(140, 22);
	petResetBtn:SetText(L["BTN_RESET"] or "Reset");
	petResetBtn:SetScript("OnClick", function()











		if InCombatLockdown() then
			if UIErrorsFrame and ERR_NOT_IN_COMBAT then
				UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1, 0.1, 0.1);
			end
			return;
		end





		if K.ResetGlobalPositions then K.ResetGlobalPositions({ Pet = true }); end
		local def = (K.GetConfigDefault and K.GetConfigDefault("PetFrameScale")) or 1.0;
		C.PetFrameScale = def;
		if K.SaveConfigSilent then K.SaveConfigSilent("PetFrameScale", def); end
		if K.ApplyPetFrameScale then K.ApplyPetFrameScale(def); end
		if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
	end);




	local petMoveBtn = CreateFrame("Button", nil, panePet, "UIPanelButtonTemplate");
	petMoveBtn:SetPoint("LEFT", petResetBtn, "RIGHT", 10, 0);
	petMoveBtn:SetSize(140, 22);
	local function PetMovesNow()
		return K.IsGlobalUnlocked and K.IsGlobalUnlocked()
			and K.GetGlobalUnlockScope and K.GetGlobalUnlockScope() == "pet";
	end
	local function PetMoveLabel()
		if PetMovesNow() then
			petMoveBtn:SetText(L["BTN_MODULE_LOCK"] or "Lock");
		else
			petMoveBtn:SetText(L["BTN_MODULE_MOVE"] or "Move");
		end
	end
	PetMoveLabel();
	petMoveBtn:SetScript("OnClick", function()
		if not K.SetGlobalUnlock then return; end


		K.SetGlobalUnlock(not PetMovesNow(), "pet");
		PetMoveLabel();
	end);


	petMoveBtn:SetScript("OnShow", PetMoveLabel);

	pv = pv - 40;






	FHeader(panePet, L["MOD_PETBUFFS"] or "Pet Buffs", x, pv);
	pv = pv - 26;
	local petBuffsCB = CreateFeatureCheckBox(panePet,
		L["MOD_PETBUFFS"] or "Pet Buffs", x, pv, L["MOD_PETBUFFS_DESC"]);
	petBuffsCB:SetChecked(K.IsModuleEnabled and K.IsModuleEnabled("HunterPetBuffs") and true or false);
	if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox("HunterPetBuffs", petBuffsCB); end
	petBuffsCB:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SetModuleEnabled then K.SetModuleEnabled("HunterPetBuffs", v); end
		if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("HunterPetBuffs"); end
	end);
	pv = pv - 40;

	side.SetContentHeight(5, pv - 30);



	panel.positionsPane   = paneMain;
	panel.positionsStartY = 0;
	panel.framesSubTabs   = nil;
end
