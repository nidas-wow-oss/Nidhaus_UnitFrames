local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);

local function ChoiceSelector(parent, px, py, labelText, opts, getFn, setFn, bw)
	bw = bw or 88;
	local bh, gap = 22, 4;
	local buttons = {};

	local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	lbl:SetPoint("TOPLEFT", px, py);
	lbl:SetText((K.UI and K.UI.Label(labelText)) or labelText);

	local box = CreateFrame("Frame", nil, parent);
	box:SetPoint("TOPLEFT", px, py - 16);
	box:SetSize((#opts * bw) + ((#opts - 1) * gap), bh);

	local function Refresh()
		local cur = getFn();
		for _, b in ipairs(buttons) do
			if b.value == cur then
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

	for i, opt in ipairs(opts) do
		local b = CreateFrame("Button", nil, box);
		b:SetSize(bw, bh);
		b:SetPoint("LEFT", box, "LEFT", (i - 1) * (bw + gap), 0);
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
			setFn(self.value);
			Refresh();
		end);
		buttons[i] = b;
	end
	Refresh();
	return box, Refresh;
end

local function BorderStyleSelector(parent, px, py, getFn, setFn)
	return ChoiceSelector(parent, px, py, L["BTN_BORDER_LABEL"] or "Border:", {
		{ value = "Tooltip",  text = L["BORDER_TOOLTIP"]  or "Tooltip" },
		{ value = "None",     text = L["BORDER_NONE"]     or "No border" },
		{ value = "Blizzard", text = L["BORDER_BLIZZARD"] or "Blizzard" },
	}, function() return getFn() or "Tooltip"; end, setFn);
end

local checkboxCount = 0;

local function Header(parent, text, x, y)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetText((K.UI and K.UI.Header(K.UI.Strip(text))) or text);
	return fs;
end

local function CollapsedDB()
	if type(NidhausUnitFramesDB) ~= "table" then NidhausUnitFramesDB = {}; end
	if type(NidhausUnitFramesDB.PanelCollapsed) ~= "table" then NidhausUnitFramesDB.PanelCollapsed = {}; end
	return NidhausUnitFramesDB.PanelCollapsed;
end

local function IsFolded(key) return key and CollapsedDB()[key] and true or false; end

local function FoldButton(parent, key, onToggle)
	local b = CreateFrame("Button", nil, parent);
	b:SetSize(16, 16);
	local function Sync()
		local folded = IsFolded(key);
		local tex = folded and "Interface\\Buttons\\UI-PlusButton-" or "Interface\\Buttons\\UI-MinusButton-";
		b:SetNormalTexture(tex .. "Up");
		b:SetPushedTexture(tex .. "Down");
		b:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD");
	end
	b.Sync = Sync;
	b:SetScript("OnClick", function()
		CollapsedDB()[key] = not IsFolded(key) or nil;
		Sync();
		if onToggle then onToggle(); end
	end);
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(IsFolded(key) and (L["FOLD_OPEN"] or "Show the options")
			or (L["FOLD_CLOSE"] or "Hide the options"), 1, 1, 1);
		GameTooltip:Show();
	end);
	b:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	Sync();
	return b;
end

local function LayoutFolds(root)
	local shift = 0;
	for _, sec in ipairs(root._nufFolds or {}) do
		sec:ClearAllPoints();
		sec:SetPoint("TOPLEFT", root, "TOPLEFT", 0, shift);
		local folded = IsFolded(sec.key);
		if folded then sec.body:Hide(); else sec.body:Show(); end
		if sec.fold then sec.fold.Sync(); end
		if folded and sec.bottom then
			shift = shift + math.max(0, (sec.top - 24) - sec.bottom);
		end
	end
end

local function FoldSection(pane, title, x, y, key)
	local root = pane._nufFoldRoot or pane;
	root._nufFolds = root._nufFolds or {};
	local prevSec = root._nufFolds[#root._nufFolds];
	if prevSec and not prevSec.bottom then prevSec.bottom = y; end

	local sec = CreateFrame("Frame", nil, root);
	sec:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0);
	sec:SetSize(1, 1);
	sec.top, sec.key = y, "class:" .. key;
	Header(sec, title, x, y);
	sec.fold = FoldButton(sec, sec.key, function() LayoutFolds(root); end);
	sec.fold:SetPoint("TOPLEFT", sec, "TOPLEFT", x + 454, y + 2);

	local body = CreateFrame("Frame", nil, sec);
	body:SetPoint("TOPLEFT", sec, "TOPLEFT", 0, 0);
	body:SetSize(1, 1);
	body._nufFoldRoot = root;
	sec.body = body;
	table.insert(root._nufFolds, sec);
	return body;
end

local function FinishFolds(root, y)
	local list = root._nufFolds;
	if not list or #list == 0 then return; end
	local last = list[#list];
	if not last.bottom then last.bottom = y; end
	LayoutFolds(root);
	root:HookScript("OnShow", function() LayoutFolds(root); end);
end

local function Note(parent, text, x, y, width)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetWidth(width or 420);
	fs:SetJustifyH("LEFT");
	fs:SetText("|cff8EAEC9" .. (text or "") .. "|r");
	return fs;
end

local function SettingCB(parent, label, setting, x, y, tip, onChange)
	checkboxCount = checkboxCount + 1;
	local cbName = "NidhausPvPCB" .. checkboxCount;
	local cb = CreateFrame("CheckButton", cbName, parent, "InterfaceOptionsCheckButtonTemplate");
	cb:SetPoint("TOPLEFT", x, y);
	cb:SetHitRectInsets(0, 0, 0, 0);

	local fs = _G[cbName .. "Text"];
	if fs then fs:SetText(label); end

	local v = C[setting];
	if type(v) == "number" then v = (v == 1); end
	cb:SetChecked(v == true);

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
		local val = (self:GetChecked() == 1 or self:GetChecked() == true);
		K.SaveConfig(setting, val);
		if onChange then onChange(val); end
	end);

	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox(setting, cb); end
	return cb;
end

local function ModuleCB(parent, label, moduleId, x, y, tip)
	if not (K.Modules and K.Modules[moduleId]) then return nil; end
	checkboxCount = checkboxCount + 1;
	local cbName = "NidhausPvPCB" .. checkboxCount;
	local cb = CreateFrame("CheckButton", cbName, parent, "InterfaceOptionsCheckButtonTemplate");
	cb:SetPoint("TOPLEFT", x, y);
	cb:SetHitRectInsets(0, 0, 0, 0);

	local fs = _G[cbName .. "Text"];
	if fs then fs:SetText(label); end

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

	local descH, descFS = 0, nil;
	if tip and tip ~= "" then
		descFS = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		descFS:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 26, -2);
		descFS:SetWidth(420);
		descFS:SetJustifyH("LEFT");
		descFS:SetText("|cff8EAEC9" .. tip .. "|r");
		descH = math.max(14, descFS:GetStringHeight() or 14) + 6;
	end

	cb:SetScript("OnClick", function(self)
		local val = (self:GetChecked() == 1 or self:GetChecked() == true);
		if K.SetModuleEnabled then K.SetModuleEnabled(moduleId, val); end
		if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox(moduleId); end
	end);
	if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox(moduleId, cb); end
	return cb, descH, descFS;
end

local BLOCK_W = 470;

local function TrackBlock(pane, blk, gap)
	blk._gap = gap;
	pane._nufBlocks = pane._nufBlocks or {};
	table.insert(pane._nufBlocks, blk);
end

local function ModuleBlock(pane, prev, moduleId, label, desc, tip)
	local blk = CreateFrame("Frame", nil, pane);
	blk:SetWidth(BLOCK_W);
	if prev then
		blk:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -10);
	else
		blk:SetPoint("TOPLEFT", 16, -14);
	end
	TrackBlock(pane, blk, prev and 10 or 14);

	local sep = blk:CreateTexture(nil, "ARTWORK");
	sep:SetTexture(1, 1, 1, 0.13);
	sep:SetPoint("TOPLEFT", 0, 0);
	sep:SetPoint("TOPRIGHT", 0, 0);
	sep:SetHeight(1);

	local headH = 26;

	local cb = ModuleCB(blk, label, moduleId, 0, -10, tip);
	if not cb then

		blk:SetHeight(1);
		blk.Refresh = function() end;
		blk.SetBodyHeight = function() end;
		return blk, blk;
	end

	local descFS;
	if desc and desc ~= "" then
		descFS = blk:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		descFS:SetPoint("TOPLEFT", 26, -34);
		descFS:SetWidth(BLOCK_W - 40);
		descFS:SetJustifyH("LEFT");
		descFS:SetText("|cff8EAEC9" .. desc .. "|r");
		headH = 34 + math.max(14, descFS:GetStringHeight() or 14) + 6;
	end

	local body = CreateFrame("Frame", nil, blk);
	body:SetPoint("TOPLEFT", 0, -headH);
	body:SetWidth(BLOCK_W);
	body:SetHeight(1);

	blk._headH = headH;
	blk._bodyH = 0;

	function blk:SetBodyHeight(h)
		self._bodyH = h or 0;
		body:SetHeight(math.max(1, self._bodyH));
	end

	local foldKey = "mod:" .. moduleId;
	local fold = FoldButton(blk, foldKey, function() blk:Refresh(); end);
	fold:SetPoint("TOPLEFT", BLOCK_W - 16, -14);

	function blk:Refresh()
		local on = K.IsModuleEnabled and K.IsModuleEnabled(moduleId);
		if on and not IsFolded(foldKey) then
			body:Show();
			self:SetHeight(self._headH + self._bodyH + 4);
		else
			body:Hide();
			self:SetHeight(self._headH);
		end
		if on then fold:Show(); else fold:Hide(); end
		fold.Sync();
	end

	cb:HookScript("OnClick", function() blk:Refresh(); end);
	pane:HookScript("OnShow", function() blk:Refresh(); end);

	blk.checkbox = cb;
	return blk, body;
end

local function HeaderBlock(pane, prev, title, note)
	local blk = CreateFrame("Frame", nil, pane);
	blk:SetWidth(BLOCK_W);
	if prev then
		blk:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -14);
	else
		blk:SetPoint("TOPLEFT", 16, -14);
	end
	TrackBlock(pane, blk, 14);

	local h = 0;
	local fs = blk:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	fs:SetPoint("TOPLEFT", 0, 0);
	fs:SetText((K.UI and K.UI.Header(K.UI.Strip(title))) or title);
	h = 20;

	if note and note ~= "" then
		local n = blk:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		n:SetPoint("TOPLEFT", 2, -h);
		n:SetWidth(BLOCK_W - 20);
		n:SetJustifyH("LEFT");
		n:SetText("|cff8EAEC9" .. note .. "|r");
		h = h + math.max(14, n:GetStringHeight() or 14) + 4;
	end

	blk:SetHeight(h);
	return blk;
end

local CLASS_COLORS = {
	MAGE        = "|cff69CCF0", HUNTER = "|cffABD473", ROGUE   = "|cffFFF569",
	WARRIOR     = "|cffC79C6E", PRIEST = "|cffFFFFFF", WARLOCK = "|cff9482C9",
	PALADIN     = "|cffF58CBA", SHAMAN = "|cff0070DE", DRUID   = "|cffFF7D0A",
	DEATHKNIGHT = "|cffC41F3B",
};

	local function ComboSection(pane, x, y)
		local pane = FoldSection(pane, L["PVP_COMBO"] or "Combo Points", x, y, "Combo");
		y = y - 24;

		local _, cwH = ModuleCB(pane, L["MOD_COMBOWATCH"] or "Combo Points", "ComboWatch",
			x, y, L["MOD_COMBOWATCH_DESC"]);
		y = y - 26 - (cwH or 0);

		SettingCB(pane, L["CB_LOCK_COMBO"] or "Lock it in place", "ComboWatchLocked",
			x + 22, y, L["TIP_ComboWatchLocked"]
			or "While locked it ignores the mouse: you can click through it.",
			function() if K.ApplyComboWatchLock then K.ApplyComboWatchLock(); end end);
		y = y - 52;

		local showBtn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
		showBtn:SetPoint("TOPLEFT", x + 2, y);
		showBtn:SetSize(150, 22);
		showBtn:SetText(L["BTN_SHOW_BARS"] or "Show to position");
		showBtn:SetScript("OnClick", function(self)
			local on = not (K.IsComboWatchPreview and K.IsComboWatchPreview());
			if K.SetComboWatchPreview then K.SetComboWatchPreview(on); end
			self:SetText(on and (L["BTN_HIDE_BARS"] or "Hide")
				or (L["BTN_SHOW_BARS"] or "Show to position"));
		end);

		local resetBtn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
		resetBtn:SetPoint("LEFT", showBtn, "RIGHT", 8, 0);
		resetBtn:SetSize(100, 22);
		resetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
		resetBtn:SetScript("OnClick", function()
			if K.ResetComboWatchPosition then K.ResetComboWatchPosition(); end
		end);

		return y - 44;
	end

local CLASS_MODULES = {

	ROGUE = function(pane, x, y)
		y = ComboSection(pane, x, y);

		return y;
	end,

	DRUID = function(pane, x, y)
		y = ComboSection(pane, x, y);

		return y;
	end,

	MAGE = function(pane, x, y)
		local pane = FoldSection(pane, L["PVP_TIMERS"] or "Timers", x, y, "MageTimers");
		y = y - 24;

		SettingCB(pane, L["BAR_WATER_ELE"] or "Water Elemental", "MageWaterEleTimer",
			x, y, L["TIP_MageWaterEle"]
			or "Duration bar for the Water Elemental. Hidden automatically if you have the Glyph of Eternal Water, since the pet is permanent.");
		y = y - 26;

		SettingCB(pane, L["BAR_MIRROR"] or "Mirror Image", "MageMirrorTimer",
			x, y, L["TIP_MageMirror"] or "30 second duration bar for Mirror Image.");
		y = y - 34;

		SettingCB(pane, L["CB_LOCK_CLASS_BARS"] or "Lock the bars", "ClassTimersLocked",
			x, y, L["TIP_ClassTimersLocked"]
			or "While locked the bars ignore the mouse: you can click through them.",
			function() if K.ApplyClassTimersLock then K.ApplyClassTimersLock(); end end);
		y = y - 48;

		do
			local cs = CreateFrame("Slider", nil, pane, "OptionsSliderTemplate");
			cs:SetPoint("TOPLEFT", x + 2, y);
			cs:SetWidth(200);
			cs:SetMinMaxValues(0.5, 2.0);
			cs:SetValueStep(0.05);
			K.UI.SliderEnds(cs, "0.50", "2.00");
			local ct = cs:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
			ct:SetPoint("BOTTOMLEFT", cs, "TOPLEFT", 0, 2);
			ct:SetText((K.UI and K.UI.Label(L["SLIDER_SCALE"] or "Scale")) or "Scale");
			local cv = cs:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
			cv:SetPoint("BOTTOMRIGHT", cs, "TOPRIGHT", 0, 2);
			local cur = (K.GetClassTimersScale and K.GetClassTimersScale()) or 1.0;
			cs:SetValue(cur); cv:SetText(string.format("%.2f", cur)); cs._last = cur;
			cs:SetScript("OnValueChanged", function(self, v)
				v = math.floor(v * 20 + 0.5) / 20;
				if self._last == v then return; end
				self._last = v;
				cv:SetText(string.format("%.2f", v));
				if K.SetClassTimersScale then K.SetClassTimersScale(v); end
			end);
		end
		y = y - 34;

		local showBtn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
		showBtn:SetPoint("TOPLEFT", x + 2, y);
		showBtn:SetSize(150, 22);
		showBtn:SetText(L["BTN_SHOW_BARS"] or "Show to position");
		showBtn:SetScript("OnClick", function(self)
			local on = not (K.IsClassTimersPreview and K.IsClassTimersPreview());
			if K.SetClassTimersPreview then K.SetClassTimersPreview(on); end
			self:SetText(on and (L["BTN_HIDE_BARS"] or "Hide")
				or (L["BTN_SHOW_BARS"] or "Show to position"));
		end);

		local resetBtn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
		resetBtn:SetPoint("LEFT", showBtn, "RIGHT", 8, 0);
		resetBtn:SetSize(100, 22);
		resetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
		resetBtn:SetScript("OnClick", function()
			if K.ResetClassTimerPositions then K.ResetClassTimerPositions(); end
		end);
		y = y - 44;

		local pane = FoldSection(pane, L["PVP_MAGE_APPEARANCE"] or "Appearance", x, y, "MageLook");
		y = y - 24;

		SettingCB(pane, L["CB_MAGE_ICY"] or "Icy player frame", "MageIcyFrame",
			x, y, L["TIP_MageIcy"]
			or "Frost / ice skin for your player frame. Works on its own, no other option needed.",
			function() if K.ApplyPlayerFrameSkin then K.ApplyPlayerFrameSkin(); end end);
		y = y - 34;

		return y;
	end,

	HUNTER = function(pane, x, y)
		local pane = FoldSection(pane, L["PVP_SHOOTING"] or "Shooting", x, y, "HunterShooting");
		y = y - 24;

		local asCB, asH = ModuleCB(pane, L["MOD_AUTOSHOT"] or "Auto Shot Timer", "AutoShotTimer",
			x, y, L["MOD_AUTOSHOT_DESC"]);
		y = y - 26 - (asH or 0);

		local asBody = K.UI.Collapsible(pane, x, y, 440, 44, function()
			return K.IsModuleEnabled and K.IsModuleEnabled("AutoShotTimer");
		end);
		if asCB then asCB:HookScript("OnClick", function() asBody:Refresh(); end); end

		BorderStyleSelector(asBody, 22, 0,
			function() return (K.GetAutoShotBorderStyle and K.GetAutoShotBorderStyle()) or "Tooltip"; end,
			function(v) if K.SetAutoShotBorderStyle then K.SetAutoShotBorderStyle(v); end end);

		y = y - 48;

		local acCB, acH = ModuleCB(pane, L["MOD_ARROWCOUNT"] or "Arrow / Bullet Count", "ArrowCount",
			x, y, L["MOD_ARROWCOUNT_DESC"]);
		if acCB then
			acCB:ClearAllPoints();
			acCB:SetPoint("TOPLEFT", asBody, "BOTTOMLEFT", 0, -4);
		end
		y = y - 42 - (acH or 0);

		local pane = FoldSection(pane, L["PVP_HUNTER_PETSECTION"] or "Pet", x, y, "HunterPet");
		y = y - 24;

		local pbCB, pbH = ModuleCB(pane, L["MOD_PETBUFFS"] or "Pet Buffs", "HunterPetBuffs",
			x, y, L["MOD_PETBUFFS_DESC"]);
		y = y - 26 - (pbH or 0);

		local pbBody = K.UI.Collapsible(pane, x, y, 440, 130, function()
			return K.IsModuleEnabled and K.IsModuleEnabled("HunterPetBuffs");
		end);
		if pbCB then pbCB:HookScript("OnClick", function() pbBody:Refresh(); end); end

		SettingCB(pbBody, L["CB_LOCK_PETBUFFS"] or "Lock them in place", "PetBuffsLocked",
			22, 0, L["TIP_PetBuffsLocked"]
			or "While locked they ignore the mouse: you can click through them.");

		local pbShow = CreateFrame("Button", nil, pbBody, "UIPanelButtonTemplate");
		pbShow:SetPoint("TOPLEFT", 2, -32);
		pbShow:SetSize(150, 22);
		pbShow:SetText(L["BTN_SHOW_BARS"] or "Show to position");
		pbShow:SetScript("OnClick", function(self)
			local on = not (K.IsPetBuffsPreview and K.IsPetBuffsPreview());
			if K.SetPetBuffsPreview then K.SetPetBuffsPreview(on); end
			self:SetText(on and (L["BTN_HIDE_BARS"] or "Hide")
				or (L["BTN_SHOW_BARS"] or "Show to position"));
		end);

		local pbReset = CreateFrame("Button", nil, pbBody, "UIPanelButtonTemplate");
		pbReset:SetPoint("LEFT", pbShow, "RIGHT", 8, 0);
		pbReset:SetSize(100, 22);
		pbReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		pbReset:SetScript("OnClick", function()
			if K.ResetPetBuffsPosition then K.ResetPetBuffsPosition(); end
		end);

		local pbSize = CreateFrame("Slider", nil, pbBody, "OptionsSliderTemplate");
		pbSize:SetPoint("TOPLEFT", 0, -84);
		pbSize:SetWidth(210);
		pbSize:SetMinMaxValues(16, 48);
		pbSize:SetValueStep(1);
		pbSize:SetValue(C.PetBuffsIconSize or 32);
		K.UI.SliderEnds(pbSize, "16", "48");
		local pbSizeTitle = pbSize:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		pbSizeTitle:SetPoint("BOTTOMLEFT", pbSize, "TOPLEFT", 0, 2);
		pbSizeTitle:SetText((K.UI and K.UI.Label(L["SLIDER_PETBUFF_SIZE"] or "Icon Size"))
			or (L["SLIDER_PETBUFF_SIZE"] or "Icon Size"));
		pbSize.ValueText = pbSize:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		pbSize.ValueText:SetPoint("BOTTOMRIGHT", pbSize, "TOPRIGHT", 0, 2);
		pbSize.ValueText:SetText(tostring(C.PetBuffsIconSize or 32));
		pbSize._last = C.PetBuffsIconSize or 32;
		pbSize:SetScript("OnValueChanged", function(self, value)
			value = math.floor(value + 0.5);
			if self._last == value then return; end
			self._last = value;
			self:SetValue(value);
			self.ValueText:SetText(tostring(value));
			C.PetBuffsIconSize = value;
			if K.ApplyPetBuffsLayout then K.ApplyPetBuffsLayout(); end
		end);
		pbSize:SetScript("OnMouseUp", function(self)
			if K.SaveConfig then K.SaveConfig("PetBuffsIconSize", C.PetBuffsIconSize); end
		end);

		return y - 130;
	end,

	PALADIN = function(pane, x, y)

		local blocks = {};
		local cards  = {};
		local bar, RefreshBar;

		local function UpdateHeight()
			local h = math.abs(y) + (bar and bar:GetHeight() or 0);
			for _, b in ipairs(blocks) do
				h = h + b.gap + (b.frame:GetHeight() or 0);
			end

			pane:SetHeight(h + 70);
			return h;
		end

		local function Enabled(id) return K.IsModuleEnabled and K.IsModuleEnabled(id); end
		local function Checked(cb) local c = cb:GetChecked(); return c == 1 or c == true; end

		local function Tooltip(widget, title, text)
			if not text then return; end
			widget:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(title, 1, 1, 1);
				GameTooltip:AddLine(text, nil, nil, nil, true);
				GameTooltip:Show();
			end);
			widget:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		end

		local function ZoneGrid(parent, id, px, py)
			local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
			lbl:SetPoint("TOPLEFT", px, py);
			lbl:SetText((K.UI and K.UI.Label(L["GARG_WHERE"] or "Show it in:"))
				or (L["GARG_WHERE"] or "Show it in:"));
			local zones = {
				{ key = "inArena", text = L["GARG_ARENA"] or "Arena",         col = 0, row = 0 },
				{ key = "inBG",    text = L["GARG_BG"]    or "Battlegrounds", col = 1, row = 0 },
				{ key = "inDuel",  text = L["GARG_DUEL"]  or "Duels",         col = 0, row = 1 },
				{ key = "inWorld", text = L["GARG_WORLD"] or "Open world",    col = 1, row = 1 },
			};
			for _, z in ipairs(zones) do
				checkboxCount = checkboxCount + 1;
				local cbName = "NidhausPalZoneCB" .. checkboxCount;
				local cb = CreateFrame("CheckButton", cbName, parent, "InterfaceOptionsCheckButtonTemplate");
				cb:SetPoint("TOPLEFT", px - 2 + z.col * 104, py - 14 - z.row * 26);
				cb:SetHitRectInsets(0, 0, 0, 0);
				local fs = _G[cbName .. "Text"];
				if fs then fs:SetText(z.text); end
				local function Sync() cb:SetChecked(K.GetModuleZone and K.GetModuleZone(id, z.key)); end
				Sync();
				cb:SetScript("OnClick", function(self)
					if K.SetModuleZone then K.SetModuleZone(id, z.key, Checked(self)); end
				end);
				parent:HookScript("OnShow", Sync);
			end
		end

		local MOVE_W, RESET_W = 92, 76;
		local function Card(prev, spec)
			local blk, body = ModuleBlock(pane, prev, spec.id, spec.label, spec.desc);
			blocks[#blocks + 1] = { frame = blk, gap = 10 };
			if not blk.checkbox then return blk; end

			local moveBtn = CreateFrame("Button", nil, blk, "UIPanelButtonTemplate");
			moveBtn:SetSize(MOVE_W, 22);

			moveBtn:SetPoint("TOPLEFT", BLOCK_W - MOVE_W - RESET_W - 6 - 22, -12);
			local resetBtn = CreateFrame("Button", nil, blk, "UIPanelButtonTemplate");
			resetBtn:SetSize(RESET_W, 22);
			resetBtn:SetPoint("LEFT", moveBtn, "RIGHT", 6, 0);
			resetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");

			local card = { id = spec.id, isMoving = spec.isMoving, setMove = spec.setMove };
			function card.RefreshMove()
				local on = card.isMoving and card.isMoving();
				moveBtn:SetText(on and (L["BTN_LOCK_IT"] or "Lock it")
					or (L["BTN_MOVE_IT"] or "Move it"));
			end

			function card.Reset()
				if spec.reset then spec.reset(); end
				if K.ResetModuleScale then K.ResetModuleScale(spec.id); end
			end
			moveBtn:SetScript("OnClick", function()
				if card.setMove then card.setMove(not (card.isMoving and card.isMoving())); end
				card.RefreshMove();
				if RefreshBar then RefreshBar(); end
			end);
			resetBtn:SetScript("OnClick", function() card.Reset(); end);
			cards[#cards + 1] = card;

			local by = -4;
			if spec.options then by = spec.options(body, by); end
			if K.HasModuleZones and K.HasModuleZones(spec.id) then
				ZoneGrid(body, spec.id, 24, by);
			end
			if K.UI and K.UI.ScaleSlider then
				K.UI.ScaleSlider(body, spec.id, 292, by - 16, 160);
			end
			by = by - 70;
			blk:SetBodyHeight(-by);

			local baseRefresh = blk.Refresh;
			blk.Refresh = function(self)
				baseRefresh(self);
				if Enabled(spec.id) then
					moveBtn:Show(); resetBtn:Show();
				else
					moveBtn:Hide(); resetBtn:Hide();
					if card.setMove and card.isMoving and card.isMoving() then
						card.setMove(false);
						if RefreshBar then RefreshBar(); end
					end
				end
				card.RefreshMove();
				UpdateHeight();
			end
			blk:Refresh();
			return blk;
		end

		local function Group(prev, title)
			local blk = HeaderBlock(pane, prev, title);
			blocks[#blocks + 1] = { frame = blk, gap = 14 };
			return blk;
		end

		bar = CreateFrame("Frame", nil, pane);
		bar:SetPoint("TOPLEFT", x, y);
		bar:SetSize(BLOCK_W, 24);

		local moveAll = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate");
		moveAll:SetPoint("TOPLEFT", 0, 0);
		moveAll:SetSize(130, 22);
		local resetAll = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate");
		resetAll:SetPoint("LEFT", moveAll, "RIGHT", 8, 0);
		resetAll:SetSize(130, 22);
		resetAll:SetText(L["PAL_RESET_ALL"] or "Reset all");
		Tooltip(moveAll, L["PAL_MOVE_ALL"] or "Move all", L["TIP_PAL_MOVE_ALL"]
			or "Shows every paladin frame you have turned on so you can drag them all at once. Click again to lock them.");
		Tooltip(resetAll, L["PAL_RESET_ALL"] or "Reset all", L["TIP_PAL_RESET_ALL"]
			or "Puts every paladin frame back in its default place and size. Your other settings are kept.");

		local function AnyMoving()
			for _, c in ipairs(cards) do
				if c.isMoving and c.isMoving() then return true; end
			end
			return false;
		end
		RefreshBar = function()
			moveAll:SetText(AnyMoving() and (L["PAL_LOCK_ALL"] or "Lock all")
				or (L["PAL_MOVE_ALL"] or "Move all"));
		end
		moveAll:SetScript("OnClick", function()

			local fix = AnyMoving();
			for _, c in ipairs(cards) do
				if c.setMove then
					if fix then
						c.setMove(false);
					elseif Enabled(c.id) then
						c.setMove(true);
					end
				end
				c.RefreshMove();
			end
			RefreshBar();
		end);
		resetAll:SetScript("OnClick", function()
			for _, c in ipairs(cards) do c.Reset(); end
		end);

		local prev = Group(bar, L["PVP_PALADIN_DEF"] or "Defensives");
		prev = Card(prev, {
			id = "PaladinICD",
			label = L["MOD_PALADIN_ICD"] or "Paladin ICD",
			desc = L["MOD_PALADIN_ICD_DESC"],
			isMoving = function() return K.IsPaladinICDMoving and K.IsPaladinICDMoving(); end,
			setMove  = function(v) if K.SetPaladinICDMove then K.SetPaladinICDMove(v); end end,
			reset    = function() if K.ResetPaladinICDPosition then K.ResetPaladinICDPosition(); end end,
			options  = function(body, by)
				SettingCB(body, L["CB_PALADIN_ICD_KEEP"] or "Keep it on screen when ready",
					"PaladinICDKeepVisible", 22, by, L["TIP_PaladinICDKeep"]
					or "Leaves the icon visible in color once the cooldown is over, so you can see at a glance that it is up. Otherwise it hides until you use it again.",
					function() if K.ApplyPaladinICDVisibility then K.ApplyPaladinICDVisibility(); end end);
				return by - 28;
			end,
		});

		prev = Group(prev, L["PVP_PAL_PROCS"] or "Procs & debuffs");
		prev = Card(prev, {
			id = "PaladinAuras",
			label = L["MOD_PALADIN_AURAS"] or "Paladin tracker",
			desc = L["MOD_PALADIN_AURAS_DESC"],
			isMoving = function() return K.IsPaladinAurasPreview and K.IsPaladinAurasPreview(); end,
			setMove  = function(v) if K.SetPaladinAurasPreview then K.SetPaladinAurasPreview(v); end end,
			reset    = function() if K.ResetPaladinAurasPosition then K.ResetPaladinAurasPosition(); end end,

			options  = function(body, by)
				local cx = 22;
				local icons = {
					{ key = "showWar",  text = L["PAL_SHOW_WAR"]  or "The Art of War",
					  tip = L["TIP_PAL_SHOW_WAR"] or "Icon while The Art of War is up: your next Exorcism or Flash of Light is instant." },
					{ key = "showHoly", text = L["PAL_SHOW_HOLY"] or "Holy Strength",
					  tip = L["TIP_PAL_SHOW_HOLY"] or "Icon while the Holy Strength proc (Crusader enchant) is up." },
					{ key = "showHeal", text = L["PAL_SHOW_HEAL"] or "Healing reduction",
					  tip = L["TIP_PAL_SHOW_HEAL"] or "Icon when anyone in your group has a healing reduction (Mortal Strike, Aimed Shot, Wound Poison...), with their name." },
				};
				for _, o in ipairs(icons) do
					checkboxCount = checkboxCount + 1;
					local cbName = "NidhausPalShowCB" .. checkboxCount;
					local cb = CreateFrame("CheckButton", cbName, body, "InterfaceOptionsCheckButtonTemplate");
					cb:SetPoint("TOPLEFT", cx, by);
					cb:SetHitRectInsets(0, 0, 0, 0);
					local fs = _G[cbName .. "Text"];
					if fs then fs:SetText(o.text); end
					local function Sync() cb:SetChecked(K.GetPaladinAurasShow and K.GetPaladinAurasShow(o.key)); end
					Sync();
					body:HookScript("OnShow", Sync);
					Tooltip(cb, o.text, o.tip);
					cb:SetScript("OnClick", function(self)
						if K.SetPaladinAurasShow then K.SetPaladinAurasShow(o.key, Checked(self)); end
					end);
					local w = fs and fs.GetStringWidth and fs:GetStringWidth();
					if type(w) ~= "number" or w <= 0 then w = 100; end
					cx = cx + 26 + w + 18;
				end
				return by - 28;
			end,
		});

		prev = Group(prev, L["PVP_PAL_CONTROL"] or "Crowd control");
		prev = Card(prev, {
			id = "TurnEvil",
			label = L["MOD_TURN_EVIL"] or "Turn Evil tracker",
			desc = L["MOD_TURN_EVIL_DESC"],
			isMoving = function() return K.IsTurnEvilPreview and K.IsTurnEvilPreview(); end,
			setMove  = function(v) if K.SetTurnEvilPreview then K.SetTurnEvilPreview(v); end end,
			reset    = function() if K.ResetTurnEvilPosition then K.ResetTurnEvilPosition(); end end,
		});

		prev = Group(prev, L["PVP_PAL_SS"] or "Sacred Shield");
		prev = Card(prev, {
			id = "SacredShield",
			label = L["MOD_SACREDSHIELD"] or "Sacred Shield (target)",
			desc = L["MOD_SACREDSHIELD_DESC"],
			isMoving = function() return K.IsSacredShieldMoving and K.IsSacredShieldMoving(); end,
			setMove  = function(v) if K.SetSacredShieldMove then K.SetSacredShieldMove(v); end end,
			reset    = function() if K.ResetSacredShieldPosition then K.ResetSacredShieldPosition(); end end,
		});
		prev = Card(prev, {
			id = "SacredShieldTracker",
			label = L["MOD_SS_TRACKER"] or "Sacred Shield tracker (group)",
			desc = L["MOD_SS_TRACKER_DESC"],
			isMoving = function() return K.IsSacredShieldTrackerMoving and K.IsSacredShieldTrackerMoving(); end,
			setMove  = function(v) if K.SetSacredShieldTrackerMove then K.SetSacredShieldTrackerMove(v); end end,
			reset    = function() if K.ResetSacredShieldTrackerPosition then K.ResetSacredShieldTrackerPosition(); end end,
		});

		pane:HookScript("OnShow", function()
			for _, c in ipairs(cards) do c.RefreshMove(); end
			RefreshBar();
			UpdateHeight();
		end);
		RefreshBar();

		return -UpdateHeight();
	end,

	WARRIOR = function(pane, x, y)

		return y;
	end,
};

local OWN_TOP_BAR = { PALADIN = true };

function K.GetClassSectionName()
	local class = (K.GetPlayerClass and K.GetPlayerClass()) or select(2, UnitClass("player"));
	local localized = UnitClass("player");
	return localized or class or (L["SIDE_CLASSOPT"] or "Class Options"), class;
end

function K.BuildPvPSection(pane)
	local prev = nil;

	local movers = {};
	local RefreshMoveAll;
	local function AddMover(id, isMoving, setMove, reset, btn, onText, offText)
		local m = { id = id, isMoving = isMoving, setMove = setMove, reset = reset };
		function m.Sync()
			if btn then
				btn:SetText((isMoving() and onText or offText));
			end
		end
		movers[#movers + 1] = m;
		if btn then
			btn:HookScript("OnClick", function() if RefreshMoveAll then RefreshMoveAll(); end end);
		end
		return m;
	end
	local LOCK = L["BTN_LOCK_IT"] or "Lock it";
	local MOVE = L["BTN_MOVE_IT"] or "Move it";

	local bar = CreateFrame("Frame", nil, pane);
	bar:SetPoint("TOPLEFT", 16, -14);
	bar:SetSize(BLOCK_W, 24);
	TrackBlock(pane, bar, 14);

	local moveAll = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate");
	moveAll:SetPoint("TOPLEFT", 0, 0);
	moveAll:SetSize(130, 22);
	local resetAll = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate");
	resetAll:SetPoint("LEFT", moveAll, "RIGHT", 8, 0);
	resetAll:SetSize(130, 22);
	resetAll:SetText(L["PAL_RESET_ALL"] or "Reset all");

	local function BarTip(widget, title, text)
		widget:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(title, 1, 1, 1);
			GameTooltip:AddLine(text, nil, nil, nil, true);
			GameTooltip:Show();
		end);
		widget:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end
	BarTip(moveAll, L["PAL_MOVE_ALL"] or "Move all", L["TIP_PVP_MOVE_ALL"]
		or "Shows every PvP frame you have turned on so you can drag them all at once. Click again to lock them.");
	BarTip(resetAll, L["PAL_RESET_ALL"] or "Reset all", L["TIP_PVP_RESET_ALL"]
		or "Puts every PvP frame back in its default place and size. Your other settings are kept.");

	local function On(id) return K.IsModuleEnabled and K.IsModuleEnabled(id); end
	local function AnyMoving()
		for _, m in ipairs(movers) do
			if m.isMoving() then return true; end
		end
		return false;
	end
	RefreshMoveAll = function()
		moveAll:SetText(AnyMoving() and (L["PAL_LOCK_ALL"] or "Lock all")
			or (L["PAL_MOVE_ALL"] or "Move all"));
		for _, m in ipairs(movers) do m.Sync(); end
	end
	moveAll:SetScript("OnClick", function()

		local fix = AnyMoving();
		for _, m in ipairs(movers) do
			if fix then
				if m.isMoving() then m.setMove(false); end
			elseif On(m.id) then
				m.setMove(true);
			end
		end
		RefreshMoveAll();
	end);
	resetAll:SetScript("OnClick", function()
		for _, m in ipairs(movers) do
			if m.reset then m.reset(); end
			if K.ResetModuleScale then K.ResetModuleScale(m.id); end
		end
		RefreshMoveAll();
	end);
	pane:HookScript("OnShow", function() RefreshMoveAll(); end);
	prev = bar;

	prev = HeaderBlock(pane, prev, L["PVP_HUD"] or "Combat HUD",
		L["PVP_HUD_NOTE"]
		or "Bars that sit next to your character so you do not have to look at the unit frames.");

	local pbBlk, pbBody = ModuleBlock(pane, prev, "PowerBar",
		L["MOD_POWERBAR"] or "Power Bar", L["MOD_POWERBAR_DESC"]);
	prev = pbBlk;
	do
		local by = 0;

		local COL_L, COL_R = 22, 250;

		local pbRow = 0;
		local function PBCheck(label, setting, tip, onChange)
			local x = (pbRow % 2 == 0) and COL_L or COL_R;
			local y = by - math.floor(pbRow / 2) * 26;
			pbRow = pbRow + 1;
			SettingCB(pbBody, label, setting, x, y, tip, onChange);
		end

		local function UpdBar()  if K.UpdatePowerBar then K.UpdatePowerBar(); end end
		local function UpdHP()   if K.ApplyPowerBarHealth then K.ApplyPowerBarHealth(); end end

		PBCheck(L["CB_POWERBAR_COMBAT"] or "Only in combat", "PowerBarCombatOnly",
			L["TIP_PowerBarCombatOnly"]
			or "Hides the power bar out of combat so it does not clutter the screen.", UpdBar);
		PBCheck(L["CB_POWERBAR_HIDEFULL"] or "Hide it when full", "PowerBarHideWhenFull",
			L["TIP_PowerBarHideFull"]
			or "Hides the bar while you are at full health and resource outside combat.", UpdHP);

		PBCheck(L["CB_POWERBAR_PCT"] or "Percentage, not numbers", "PowerBarShowPercent",
			L["TIP_PowerBarPct"]
			or "Shows 73% instead of 7300 / 10000 on both bars.", UpdBar);
		PBCheck(L["CB_POWERBAR_HIDETEXT"] or "Hide the numbers", "PowerBarHideText",
			L["TIP_PowerBarHideText"]
			or "Turns the numbers off entirely. The bar alone already tells you how much is left.", UpdBar);

		PBCheck(L["CB_POWERBAR_HEALTH"] or "Also a health bar", "PowerBarShowHealth",
			L["TIP_PowerBarHealth"]
			or "Adds a health bar above the resource bar, so the Power Bar works like a mini player frame.", UpdHP);
		PBCheck(L["CB_POWERBAR_GRADIENT"] or "Color by health left", "PowerBarHealthGradient",
			L["TIP_PowerBarGradient"]
			or "The health bar goes green > yellow > red as you lose health.", UpdBar);

		PBCheck(L["CB_POWERBAR_CLASSCOLOR"] or "Health in class color", "PowerBarHealthClassColor",
			L["TIP_PowerBarClassColor"]
			or "Paints the health bar with your class color instead of green. It wins over the gradient above.", UpdBar);
		PBCheck(L["CB_POWERBAR_AURAS"] or "Buffs and debuffs", "PowerBarShowAuras",
			L["TIP_PowerBarAuras"]
			or "Two rows of small icons: buffs on top, debuffs below. Unlike the Blizzard frame it shows all of them, not a chosen few.",
			function() if K.ApplyPowerBarAuraToggle then K.ApplyPowerBarAuraToggle(); end end);

		by = by - math.ceil(pbRow / 2) * 26;

		local function PBSlider(label, sx, sy, minV, maxV, step, getFn, setFn)
			local s = CreateFrame("Slider", nil, pbBody, "OptionsSliderTemplate");
			s:SetPoint("TOPLEFT", sx, sy);
			s:SetWidth(180);
			s:SetMinMaxValues(minV, maxV);
			s:SetValueStep(step);
			K.UI.SliderEnds(s, tostring(minV), tostring(maxV));
			local title = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
			title:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2);
			title:SetText(label);
			local val = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
			val:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 2);
			local function Fmt(v) return (step >= 1) and tostring(v) or string.format("%.2f", v); end
			s:SetValue(getFn());
			val:SetText(Fmt(getFn()));
			s._last = getFn();
			s:SetScript("OnValueChanged", function(self, v)
				if step >= 1 then v = math.floor(v + 0.5); end
				if self._last == v then return; end
				self._last = v;
				self:SetValue(v);
				val:SetText(Fmt(v));
				setFn(v);
			end);
			return s;
		end

		by = by - 46;
		PBSlider(L["SLIDER_POWERBAR_SCALE"] or "Scale", 26, by, 0.5, 2.0, 0.05,
			function() return (K.GetPowerBarScale and K.GetPowerBarScale()) or 1; end,
			function(v) if K.SavePowerBarScale then K.SavePowerBarScale(v); end end);
		PBSlider(L["SLIDER_POWERBAR_WIDTH"] or "Width", 260, by, 80, 320, 5,
			function() return (K.GetPowerBarWidth and K.GetPowerBarWidth()) or 160; end,
			function(v) if K.SavePowerBarWidth then K.SavePowerBarWidth(v); end end);
		by = by - 52;
		PBSlider(L["SLIDER_POWERBAR_HEIGHT"] or "Bar height", 26, by, 8, 40, 1,
			function() return (K.GetPowerBarBarHeight and K.GetPowerBarBarHeight()) or 14; end,
			function(v) if K.SavePowerBarBarHeight then K.SavePowerBarBarHeight(v); end end);
		PBSlider(L["SLIDER_POWERBAR_AURASIZE"] or "Aura icon size", 260, by, 10, 32, 1,
			function() return (K.GetPowerBarAuraSize and K.GetPowerBarAuraSize()) or 16; end,
			function(v) if K.SavePowerBarAuraSize then K.SavePowerBarAuraSize(v); end end);
		by = by - 52;
		PBSlider(L["SLIDER_POWERBAR_AURAROW"] or "Auras per row", 26, by, 2, 16, 1,
			function() return (K.GetPowerBarAuraPerRow and K.GetPowerBarAuraPerRow()) or 8; end,
			function(v) if K.SavePowerBarAuraPerRow then K.SavePowerBarAuraPerRow(v); end end);

		by = by - 42;
		ChoiceSelector(pbBody, 26, by, L["BTN_AURAPOS_LABEL"] or "Auras:", {
			{ value = "RIGHT",  text = L["AURAPOS_RIGHT"]  or "Right" },
			{ value = "BOTTOM", text = L["AURAPOS_BOTTOM"] or "Below" },
			{ value = "TOP",    text = L["AURAPOS_TOP"]    or "Above" },
		},
			function() return (K.GetPowerBarAuraPos and K.GetPowerBarAuraPos()) or "RIGHT"; end,
			function(v) if K.SetPowerBarAuraPos then K.SetPowerBarAuraPos(v); end end,
			74);

		pbBlk:SetBodyHeight(math.abs(by) + 62);
		pbBlk:Refresh();

		AddMover("PowerBar",
			function() return K.IsPowerBarMoving and K.IsPowerBarMoving(); end,
			function(v) if K.SetPowerBarMove then K.SetPowerBarMove(v); end end,
			function() if K.ResetPowerBarPosition then K.ResetPowerBarPosition(); end end);
	end

	local swBlk, swBody = ModuleBlock(pane, prev, "MeleeSwingTimer",
		L["MOD_MELEESWING"] or "Melee Swing Timer", L["MOD_MELEESWING_DESC"]);
	prev = swBlk;
	do
		local swMove = CreateFrame("Button", nil, swBody, "UIPanelButtonTemplate");
		swMove:SetPoint("TOPLEFT", 24, 0);
		swMove:SetSize(150, 22);
		swMove:SetText((K.IsMeleeSwingUnlocked and K.IsMeleeSwingUnlocked())
			and (L["BTN_LOCK_IT"] or "Lock it") or (L["BTN_MOVE_IT"] or "Move it"));
		swMove:SetScript("OnClick", function(self)
			if not K.ToggleMeleeSwingUnlock then return; end
			local on = K.ToggleMeleeSwingUnlock();
			self:SetText(on and (L["BTN_LOCK_IT"] or "Lock it")
				or (L["BTN_MOVE_IT"] or "Move it"));
		end);

		local swReset = CreateFrame("Button", nil, swBody, "UIPanelButtonTemplate");
		swReset:SetPoint("LEFT", swMove, "RIGHT", 8, 0);
		swReset:SetSize(100, 22);
		swReset:SetText(L["BTN_MOVE_RESET"] or "Reset");

		local swScale = CreateFrame("Slider", nil, swBody, "OptionsSliderTemplate");
		swScale:SetPoint("TOPLEFT", 24, -48);
		swScale:SetWidth(200);
		swScale:SetMinMaxValues(0.5, 2.5);
		swScale:SetValueStep(0.05);
		K.UI.SliderEnds(swScale, "0.50", "2.50");
		local swTitle = swScale:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		swTitle:SetPoint("BOTTOMLEFT", swScale, "TOPLEFT", 0, 2);
		swTitle:SetText((K.UI and K.UI.Label(L["SLIDER_SWING_SCALE"] or "Scale"))
			or (L["SLIDER_SWING_SCALE"] or "Scale"));
		local swVal = swScale:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		swVal:SetPoint("BOTTOMRIGHT", swScale, "TOPRIGHT", 0, 2);

		local function RefreshSwingScale()
			local v = (K.GetMeleeSwingScale and K.GetMeleeSwingScale()) or 1.0;
			swScale._last = v;
			swScale:SetValue(v);
			swVal:SetText(string.format("%.2f", v));
		end
		K.RefreshSwingScaleSlider = RefreshSwingScale;
		RefreshSwingScale();

		swScale:SetScript("OnValueChanged", function(self, v)
			v = math.floor(v * 20 + 0.5) / 20;
			if self._last == v then return; end
			self._last = v;
			swVal:SetText(string.format("%.2f", v));

			if not (K.SetScaleFromControl and K.SetScaleFromControl("SwingTimer", v))
			   and K.SaveMeleeSwingScale then
				K.SaveMeleeSwingScale(v);
			end
		end);

		swReset:SetScript("OnClick", function()
			if K.ResetMeleeSwingTimerPosition then K.ResetMeleeSwingTimerPosition(); end
			swMove:SetText(L["BTN_MOVE_IT"] or "Move it");
			RefreshSwingScale();
		end);

		BorderStyleSelector(swBody, 24, -84,
			function() return (K.GetMeleeSwingBorderStyle and K.GetMeleeSwingBorderStyle()) or "Tooltip"; end,
			function(v) if K.SetMeleeSwingBorderStyle then K.SetMeleeSwingBorderStyle(v); end end);

		swBlk:SetBodyHeight(136);
		swBlk:Refresh();

		AddMover("MeleeSwingTimer",
			function() return K.IsMeleeSwingUnlocked and K.IsMeleeSwingUnlocked(); end,
			function(v)
				local cur = K.IsMeleeSwingUnlocked and K.IsMeleeSwingUnlocked();
				if K.ToggleMeleeSwingUnlock and (v and true or false) ~= (cur and true or false) then
					K.ToggleMeleeSwingUnlock();
				end
			end,
			function()
				if K.ResetMeleeSwingTimerPosition then K.ResetMeleeSwingTimerPosition(); end
				RefreshSwingScale();
			end,
			swMove, LOCK, MOVE);
	end

	prev = HeaderBlock(pane, prev, L["PVP_ENEMY_HEADER"] or "Enemy awareness");

	local eaBlk, eaBody = ModuleBlock(pane, prev, "EnemySpellAlert",
		L["MOD_ENEMYALERT"] or "Enemy Spell Alert",
		L["PVP_ENEMYALERT_NOTE"] or L["MOD_ENEMYALERT_DESC"]);
	prev = eaBlk;
	do
		SettingCB(eaBody, L["CB_LOCK_ENEMYALERT"] or "Lock it in place", "EnemySpellAlertLocked",
			22, 0, L["TIP_EnemyAlertLocked"]
			or "While locked it ignores the mouse: you can click through it.",
			function() if K.ApplyEnemyAlertLock then K.ApplyEnemyAlertLock(); end end);

		local eaShow = CreateFrame("Button", nil, eaBody, "UIPanelButtonTemplate");
		eaShow:SetPoint("TOPLEFT", 24, -32);
		eaShow:SetSize(150, 22);
		eaShow:SetText(L["BTN_SHOW_BARS"] or "Show to position");
		eaShow:SetScript("OnClick", function(self)
			local on = not (K.IsEnemyAlertPreview and K.IsEnemyAlertPreview());
			if K.SetEnemyAlertPreview then K.SetEnemyAlertPreview(on); end
			self:SetText(on and (L["BTN_HIDE_BARS"] or "Hide")
				or (L["BTN_SHOW_BARS"] or "Show to position"));
		end);

		local eaReset = CreateFrame("Button", nil, eaBody, "UIPanelButtonTemplate");
		eaReset:SetPoint("LEFT", eaShow, "RIGHT", 8, 0);
		eaReset:SetSize(100, 22);
		eaReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		eaReset:SetScript("OnClick", function()
			if K.ResetEnemyAlertPosition then K.ResetEnemyAlertPosition(); end
		end);

		local eaList = CreateFrame("Button", nil, eaBody, "UIPanelButtonTemplate");
		eaList:SetPoint("LEFT", eaReset, "RIGHT", 8, 0);
		eaList:SetSize(110, 22);
		eaList:SetText(L["BTN_SPELL_LIST"] or "Spell list");
		eaList:SetScript("OnClick", function()
			if K.OpenEnemyAlertMenu then K.OpenEnemyAlertMenu(); end
		end);

		local eaWhere = eaBody:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		eaWhere:SetPoint("TOPLEFT", 24, -62);
		eaWhere:SetText((K.UI and K.UI.Label(L["GARG_WHERE"] or "Show it in:"))
			or (L["GARG_WHERE"] or "Show it in:"));

		local eaZones = {
			{ key = "inArena", text = L["GARG_ARENA"] or "Arena",         x = 26,  y = -80 },
			{ key = "inBG",    text = L["GARG_BG"]    or "Battlegrounds", x = 150, y = -80 },
			{ key = "inDuel",  text = L["GARG_DUEL"]  or "Duels",         x = 300, y = -80 },
			{ key = "inWorld", text = L["GARG_WORLD"] or "Open world",    x = 26,  y = -106 },
		};
		for _, z in ipairs(eaZones) do
			checkboxCount = checkboxCount + 1;
			local cbName = "NidhausEAZoneCB" .. checkboxCount;
			local cb = CreateFrame("CheckButton", cbName, eaBody, "InterfaceOptionsCheckButtonTemplate");
			cb:SetPoint("TOPLEFT", z.x, z.y);
			cb:SetHitRectInsets(0, 0, 0, 0);
			local fs = _G[cbName .. "Text"];
			if fs then fs:SetText(z.text); end
			cb:SetChecked(K.GetEnemyAlertZone and K.GetEnemyAlertZone(z.key));
			cb:SetScript("OnClick", function(self)
				local v = (self:GetChecked() == 1 or self:GetChecked() == true);
				if K.SetEnemyAlertZone then K.SetEnemyAlertZone(z.key, v); end
			end);
		end

		if K.UI and K.UI.ScaleSlider then
			K.UI.ScaleSlider(eaBody, "EnemySpellAlert", 26, -142, 200,
				L["SLIDER_SCALE"] or "Scale");
		end

		eaBlk:SetBodyHeight(180);
		eaBlk:Refresh();

		AddMover("EnemySpellAlert",
			function() return K.IsEnemyAlertPreview and K.IsEnemyAlertPreview(); end,
			function(v) if K.SetEnemyAlertPreview then K.SetEnemyAlertPreview(v); end end,
			function() if K.ResetEnemyAlertPosition then K.ResetEnemyAlertPosition(); end end,
			eaShow, L["BTN_HIDE_BARS"] or "Hide", L["BTN_SHOW_BARS"] or "Show to position");
	end

	local sdBlk, sdBody = ModuleBlock(pane, prev, "SeductionAlert",
		L["MOD_SEDUCTION"] or "Seduction on you (arena)", L["MOD_SEDUCTION_DESC"]);
	prev = sdBlk;
	do
		local sdMove = CreateFrame("Button", nil, sdBody, "UIPanelButtonTemplate");
		sdMove:SetPoint("TOPLEFT", 24, -4);
		sdMove:SetSize(150, 22);
		sdMove:SetText(L["BTN_MOVE_IT"] or "Move it");
		sdMove:SetScript("OnClick", function(self)
			if not K.SetSeductionAlertMove then return; end
			local on = K.SetSeductionAlertMove(not (K.IsSeductionAlertMoving and K.IsSeductionAlertMoving()));
			self:SetText(on and (L["BTN_LOCK_IT"] or "Lock it")
				or (L["BTN_MOVE_IT"] or "Move it"));
		end);

		local sdReset = CreateFrame("Button", nil, sdBody, "UIPanelButtonTemplate");
		sdReset:SetPoint("LEFT", sdMove, "RIGHT", 8, 0);
		sdReset:SetSize(100, 22);
		sdReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		sdReset:SetScript("OnClick", function()
			if K.ResetSeductionAlertPosition then K.ResetSeductionAlertPosition(); end
		end);

		if K.UI and K.UI.ScaleSlider then
			K.UI.ScaleSlider(sdBody, "SeductionAlert", 26, -40, 200,
				L["SLIDER_SCALE"] or "Scale");
		end

		sdBlk:SetBodyHeight(80);
		sdBlk:Refresh();

		AddMover("SeductionAlert",
			function() return K.IsSeductionAlertMoving and K.IsSeductionAlertMoving(); end,
			function(v) if K.SetSeductionAlertMove then K.SetSeductionAlertMove(v); end end,
			function() if K.ResetSeductionAlertPosition then K.ResetSeductionAlertPosition(); end end,
			sdMove, LOCK, MOVE);
	end

	local gtBlk, gtBody = ModuleBlock(pane, prev, "GargoyleTracker",
		L["MOD_GARGOYLE"] or "Gargoyle Tracker", L["MOD_GARGOYLE_DESC"]);
	prev = gtBlk;
	do

		local styleLbl = gtBody:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		styleLbl:SetPoint("TOPLEFT", 24, -8);
		styleLbl:SetText((K.UI and K.UI.Label(L["GARG_MODE"] or "Style"))
			or (L["GARG_MODE"] or "Style"));

		local modes = {
			{ value = "blizzard", text = L["GARG_MODE_BLIZZ"]  or "Blizzard" },
			{ value = "custom",   text = L["GARG_MODE_CUSTOM"] or "Custom" },
		};
		local function ModeText(v)
			for _, m in ipairs(modes) do if m.value == v then return m.text; end end
			return tostring(v);
		end
		local styleDD = CreateFrame("Frame", "NidhausGargStyleDD", gtBody, "UIDropDownMenuTemplate");
		styleDD:SetPoint("TOPLEFT", 60, 0);
		UIDropDownMenu_SetWidth(styleDD, 110);
		local function RefreshStyle()
			local cur = (K.GetGargoyleMode and K.GetGargoyleMode()) or "blizzard";
			UIDropDownMenu_SetSelectedValue(styleDD, cur);
			UIDropDownMenu_SetText(styleDD, ModeText(cur));
		end
		UIDropDownMenu_Initialize(styleDD, function(self, level)
			for _, m in ipairs(modes) do
				local info = UIDropDownMenu_CreateInfo();
				info.text, info.value = m.text, m.value;
				info.checked = ((K.GetGargoyleMode and K.GetGargoyleMode()) == m.value);
				info.func = function(btn)
					if K.SetGargoyleMode then K.SetGargoyleMode(btn.value); end
					RefreshStyle();
				end;
				UIDropDownMenu_AddButton(info, level);
			end
		end);
		RefreshStyle();
		gtBody:HookScript("OnShow", RefreshStyle);

		checkboxCount = checkboxCount + 1;
		local mirName = "NidhausGargMirrorCB" .. checkboxCount;
		local mirCB = CreateFrame("CheckButton", mirName, gtBody, "InterfaceOptionsCheckButtonTemplate");
		mirCB:SetPoint("TOPLEFT", 236, -2);
		mirCB:SetHitRectInsets(0, -60, 0, 0);
		if _G[mirName .. "Text"] then _G[mirName .. "Text"]:SetText(L["GARG_MIRROR"] or "Mirror"); end
		local function SyncMirror() mirCB:SetChecked(K.GetGargoyleMirror and K.GetGargoyleMirror()); end
		SyncMirror();
		gtBody:HookScript("OnShow", SyncMirror);
		mirCB:SetScript("OnClick", function(self)
			local v = (self:GetChecked() == 1 or self:GetChecked() == true);
			if K.SetGargoyleMirror then K.SetGargoyleMirror(v); end
		end);
		mirCB:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["GARG_MIRROR"] or "Mirror", 1, 1, 1);
			GameTooltip:AddLine(L["TIP_GARG_MIRROR"] or "Flips the frame: the icon goes to the other side and the bars too. Works with both styles.", nil, nil, nil, true);
			GameTooltip:Show();
		end);
		mirCB:SetScript("OnLeave", function() GameTooltip:Hide(); end);

		local whereLbl = gtBody:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		whereLbl:SetPoint("TOPLEFT", 24, -34);
		whereLbl:SetText((K.UI and K.UI.Label(L["GARG_WHERE"] or "Show it in:"))
			or (L["GARG_WHERE"] or "Show it in:"));

		local zones = {
			{ key = "inArena", text = L["GARG_ARENA"] or "Arena",         x = 26,  y = -52 },
			{ key = "inBG",    text = L["GARG_BG"]    or "Battlegrounds", x = 150, y = -52 },
			{ key = "inDuel",  text = L["GARG_DUEL"]  or "Duels",         x = 300, y = -52 },
			{ key = "inWorld", text = L["GARG_WORLD"] or "Open world",    x = 26,  y = -78 },
		};
		for _, z in ipairs(zones) do
			checkboxCount = checkboxCount + 1;
			local cbName = "NidhausGargCB" .. checkboxCount;
			local cb = CreateFrame("CheckButton", cbName, gtBody, "InterfaceOptionsCheckButtonTemplate");
			cb:SetPoint("TOPLEFT", z.x, z.y);
			cb:SetHitRectInsets(0, 0, 0, 0);
			local fs = _G[cbName .. "Text"];
			if fs then fs:SetText(z.text); end
			cb:SetChecked(K.GetGargoyleZoneOption and K.GetGargoyleZoneOption(z.key));
			cb:SetScript("OnClick", function(self)
				local v = (self:GetChecked() == 1 or self:GetChecked() == true);
				if K.SetGargoyleZoneOption then K.SetGargoyleZoneOption(z.key, v); end
			end);
		end

		local gtTest = CreateFrame("Button", nil, gtBody, "UIPanelButtonTemplate");
		gtTest:SetPoint("TOPLEFT", 26, -106);
		gtTest:SetSize(150, 22);
		gtTest:SetText(L["BTN_TEST_MODE"] or "Test mode");
		gtTest:SetScript("OnClick", function(self)
			if not K.ToggleGargoyleTest then return; end
			local on = K.ToggleGargoyleTest();
			self:SetText(on and (L["BTN_HIDE_BARS"] or "Hide")
				or (L["BTN_TEST_MODE"] or "Test mode"));
		end);

		local gtReset = CreateFrame("Button", nil, gtBody, "UIPanelButtonTemplate");
		gtReset:SetPoint("LEFT", gtTest, "RIGHT", 8, 0);
		gtReset:SetSize(100, 22);
		gtReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		gtReset:SetScript("OnClick", function()
			if K.ResetGargoylePosition then K.ResetGargoylePosition(); end
		end);

		if K.UI and K.UI.ScaleSlider then
			K.UI.ScaleSlider(gtBody, "GargoyleTracker", 26, -140, 200);
		end

		gtBlk:SetBodyHeight(180);
		gtBlk:Refresh();

		AddMover("GargoyleTracker",
			function() return K.IsGargoyleTestActive and K.IsGargoyleTestActive(); end,
			function(v) if K.SetGargoylePreview then K.SetGargoylePreview(v); end end,
			function() if K.ResetGargoylePosition then K.ResetGargoylePosition(); end end,
			gtTest, L["BTN_HIDE_BARS"] or "Hide", L["BTN_TEST_MODE"] or "Test mode");
	end

	local total = 0;
	for _, blk in ipairs(pane._nufBlocks or {}) do
		local h = blk._headH and (blk._headH + (blk._bodyH or 0) + 4) or (blk:GetHeight() or 0);
		total = total + (blk._gap or 0) + h;
	end
	return -math.max(1000, total + 20);
end

function K.BuildClassSection(pane)
	local x = 16;
	local y = -14;

	local class = (K.GetPlayerClass and K.GetPlayerClass()) or select(2, UnitClass("player"));
	local className = UnitClass("player") or class or "?";
	local color = CLASS_COLORS[class] or "|cffFFFFFF";

	if OWN_TOP_BAR[class] and CLASS_MODULES[class] then
		return CLASS_MODULES[class](pane, x, y);
	end

	local banner = CreateFrame("Frame", nil, pane);
	banner:SetPoint("TOPLEFT", x - 4, y);
	banner:SetSize(440, 40);
	banner:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile     = true, tileSize = 16, edgeSize = 12,
		insets   = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	banner:SetBackdropColor(0.07, 0.06, 0.04, 0.85);
	banner:SetBackdropBorderColor(0.35, 0.32, 0.24, 0.8);

	local bannerText = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	bannerText:SetPoint("TOPLEFT", banner, "TOPLEFT", 12, -8);
	bannerText:SetText((L["PVP_DETECTED"] or "Detected class:") .. " " .. color .. className .. "|r");

	local bannerSub = banner:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
	bannerSub:SetPoint("TOPLEFT", bannerText, "BOTTOMLEFT", 0, -2);
	bannerSub:SetText(L["PVP_DETECTED_SUB"]
		or "Only the modules your class can actually use are shown here.");

	y = y - 54;

	local builder = CLASS_MODULES[class];
	if builder then
		y = builder(pane, x, y);
		FinishFolds(pane, y);
	else
		Note(pane, L["PVP_NO_CLASS_MODULES"]
			or "There are no class specific modules for this class yet. The list grows as they get added.",
			x + 2, y, 430);
		y = y - 60;
	end

	return y;
end
