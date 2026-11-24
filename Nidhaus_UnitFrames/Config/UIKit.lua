local AddOnName, ns = ...;
local K, C, L = unpack(ns);

K.UI = K.UI or {};

K.UI.COLOR_HEADER = "|cffFFD100";
K.UI.COLOR_LABEL  = "|cffFFFFFF";
K.UI.COLOR_VALUE  = "|cff8EC9FF";
K.UI.COLOR_DIM    = "|cff8A8A8A";

function K.UI.Header(text) return K.UI.COLOR_HEADER .. (text or "") .. "|r"; end
function K.UI.Label(text)  return K.UI.COLOR_LABEL  .. (text or "") .. "|r"; end
function K.UI.Value(text)  return K.UI.COLOR_VALUE  .. (text or "") .. "|r"; end
function K.UI.Dim(text)    return K.UI.COLOR_DIM    .. (text or "") .. "|r"; end

function K.UI.Strip(text)
	if type(text) ~= "string" then return text; end
	text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "");
	text = string.gsub(text, "|r", "");
	return text;
end

function K.UI.SectionBox(parent, title, x, y, width, height)
	local box = CreateFrame("Frame", nil, parent);
	box:SetPoint("TOPLEFT", x, y);
	box:SetSize(width or 10, height or 10);

	if title and title ~= "" then
		local fs = box:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		fs:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -2);
		fs:SetText(K.UI.Header(K.UI.Strip(title)));
		box.title = fs;
	end

	return box;
end

function K.UI.Separator(parent, x, y, width)
	local sep = parent:CreateTexture(nil, "ARTWORK");
	sep:SetTexture(1, 1, 1, 0.10);
	sep:SetPoint("TOPLEFT", x, y);
	sep:SetSize(width or 540, 1);
	return sep;
end

function K.UI.StripeRow(parent, index)
	return nil;
end

function K.UI.SliderEnds(slider, minText, maxText)
	if not slider or not slider.GetRegions then return; end
	local low, high;
	for _, r in pairs({ slider:GetRegions() }) do
		if r.GetObjectType and r:GetObjectType() == "FontString" then
			local point = r:GetPoint();
			if point == "TOPLEFT" then
				low = r;
				r:SetText(minText or "");
				r:SetTextColor(0.6, 0.6, 0.6);
				r:Show();
			elseif point == "TOPRIGHT" then
				high = r;
				r:SetText(maxText or "");
				r:SetTextColor(0.6, 0.6, 0.6);
				r:Show();
			else
				r:SetText("");
				r:Hide();
			end
		end
	end
	return low, high;
end

local moduleScaleSliders = {};

function K.RefreshModuleScaleSliders(id)
	for _, s in ipairs(moduleScaleSliders) do
		if (not id or s._moduleId == id) and s.Refresh then s:Refresh(); end
	end
end

function K.UI.ScaleSlider(parent, moduleId, x, y, width, label)
	if not (K.IsScalable and K.IsScalable(moduleId)) then return nil; end

	local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate");
	s:SetPoint("TOPLEFT", x, y);
	s:SetWidth(width or 180);
	s:SetMinMaxValues(0.5, 2.0);
	s:SetValueStep(0.05);

	K.UI.SliderEnds(s, "0.50", "2.00");

	local title = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	title:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2);
	title:SetText(K.UI.Label(label or (L and L["SLIDER_SCALE"]) or "Scale"));

	local val = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	val:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 2);

	s._nufOwnValue = val;

	local cur = K.GetModuleScale(moduleId);
	s:SetValue(cur);
	val:SetText(string.format("%.2f", cur));
	s._last = cur;

	s:SetScript("OnValueChanged", function(self, v)
		v = math.floor(v * 20 + 0.5) / 20;
		if self._last == v then return; end
		self._last = v;
		val:SetText(string.format("%.2f", v));

		if K.SetModuleScaleFromControl then
			K.SetModuleScaleFromControl(moduleId, v);
		else
			K.SetModuleScale(moduleId, v);
		end
	end);

	s.Refresh = function(self)
		local c = K.GetModuleScale(moduleId);
		self._last = c;
		self:SetValue(c);
		val:SetText(string.format("%.2f", c));
	end

	s._moduleId = moduleId;
	table.insert(moduleScaleSliders, s);
	s:HookScript("OnShow", function(self) self:Refresh(); end);

	return s;
end

local function StepDecimals(slider)
	local step = slider:GetValueStep() or 1;
	if step >= 1 then return 0; end
	if step >= 0.1 then return 1; end
	return 2;
end

local function FormatValue(slider, v)

	if slider._nufFormat then
		local ok, s = pcall(slider._nufFormat, v);
		if ok and s then return s; end
	end
	local d = StepDecimals(slider);
	if d == 0 then return tostring(math.floor(v + 0.5)); end
	return string.format("%." .. d .. "f", v);
end

local function StripTrailingValue(text)
	if type(text) ~= "string" then return text; end
	return (string.gsub(text, "%s*:%s*%-?%d+%.?%d*%s*$", ""));
end

function K.UI.AttachSliderValue(slider)
	if not slider or slider._nufValueBox then return; end
	if not slider.GetValueStep or not slider.GetMinMaxValues then return; end

	if slider.GetOrientation and slider:GetOrientation() == "VERTICAL" then return; end
	local sname = slider:GetName();
	if sname and string.find(sname, "ScrollBar") then return; end
	local parent = slider:GetParent();
	if parent and parent.GetObjectType and parent:GetObjectType() == "ScrollFrame" then
		return;
	end

	local name = slider:GetName();
	local titleFS = name and _G[name .. "Text"];
	if not titleFS then
		for _, r in ipairs({ slider:GetRegions() }) do
			if r.GetObjectType and r:GetObjectType() == "FontString" then
				local pt = r:GetPoint(1);
				if pt == "BOTTOM" then titleFS = r; break; end
			end
		end
	end

	if slider.ValueText then
		pcall(slider.ValueText.Hide, slider.ValueText);
	end

	if slider._nufOwnValue then
		pcall(slider._nufOwnValue.Hide, slider._nufOwnValue);
	else
		for _, r in ipairs({ slider:GetRegions() }) do
			if r.GetObjectType and r:GetObjectType() == "FontString" and r ~= titleFS then
				local pt, rel, rp = r:GetPoint(1);
				if pt == "TOP" and rp == "BOTTOM" then pcall(r.Hide, r); end
			end
		end
	end

	local box = CreateFrame("EditBox", nil, slider);
	box:SetAutoFocus(false);
	box:SetFontObject("GameFontHighlightSmall");
	box:SetJustifyH("CENTER");
	box:SetWidth(58);
	box:SetHeight(16);
	box:SetPoint("TOP", slider, "BOTTOM", 0, -1);
	box:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 10,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	box:SetBackdropColor(0, 0, 0, 0.55);
	box:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8);
	box:SetTextInsets(4, 4, 0, 0);

	slider._nufValueBox = box;

	local function Sync()
		if box:HasFocus() then return; end
		box:SetText(FormatValue(slider, slider:GetValue() or 0));
		box:SetCursorPosition(0);
	end
	slider._nufSyncValue = Sync;

	box:SetScript("OnEnterPressed", function(self)

		local v;
		if slider._nufParse then
			local ok, r = pcall(slider._nufParse, self:GetText() or "");
			if ok then v = r; end
		else
			v = tonumber(self:GetText());
		end
		if v then
			local lo, hi = slider:GetMinMaxValues();
			if v < lo then v = lo; elseif v > hi then v = hi; end
			slider:SetValue(v);
		end
		self:ClearFocus();
		Sync();
	end);
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); Sync(); end);
	box:SetScript("OnEditFocusLost", Sync);

	slider:HookScript("OnValueChanged", function(self)

		if titleFS then titleFS:SetText(StripTrailingValue(titleFS:GetText())); end
		Sync();
	end);

	if titleFS then titleFS:SetText(StripTrailingValue(titleFS:GetText())); end
	Sync();
	return box;
end

function K.UI.AutoRestyle(frame)
	if not frame or frame._nufAutoRestyle then return; end
	frame._nufAutoRestyle = true;
	frame:HookScript("OnShow", function(self)
		if self._nufSlidersDone then return; end
		self._nufSlidersDone = true;
		pcall(K.UI.RestyleSliders, self);
	end);
	if frame:IsShown() then pcall(K.UI.RestyleSliders, frame); end
end

function K.UI.RestyleSliders(root, depth)
	if not root or (depth or 0) > 8 then return; end
	local kids = { root:GetChildren() };
	for _, child in ipairs(kids) do
		if child.GetObjectType and child:GetObjectType() == "Slider" then
			pcall(K.UI.AttachSliderValue, child);
		end
		K.UI.RestyleSliders(child, (depth or 0) + 1);
	end
end

function K.UI.Collapsible(parent, x, y, width, height, isOpen)
	local body = CreateFrame("Frame", nil, parent);
	body:SetPoint("TOPLEFT", x, y);
	body:SetWidth(width or 440);
	body:SetHeight(height or 1);

	body._fullHeight = height or 1;

	function body:SetFullHeight(h)
		self._fullHeight = h or 1;
		self:Refresh();
	end

	function body:Refresh()
		local open = true;
		if isOpen then
			local ok, v = pcall(isOpen);
			open = ok and v and true or false;
		end
		if open then
			self:Show();
			self:SetHeight(self._fullHeight);
		else
			self:Hide();
			self:SetHeight(1);
		end
		return open;
	end

	parent:HookScript("OnShow", function() body:Refresh(); end);
	body:Refresh();
	return body;
end

local SOUND_DIR = "Interface\\AddOns\\Nidhaus_UnitFrames\\Media\\Sound\\";
K.SOUNDS = {
	{ key = "raid",        text = "Raid Warning" },
	{ key = "AlarmShort",  file = "AlarmShort.ogg" },
	{ key = "AlarmMid",    file = "AlarmMid.ogg" },
	{ key = "AlarmLong",   file = "AlarmLong.ogg" },
	{ key = "BeepHigh",    file = "BeepHigh.mp3" },
	{ key = "BeepLow",     file = "BeepLow.mp3" },
	{ key = "ChainLink",   file = "ChainLink.ogg" },
	{ key = "ChurchBell",  file = "ChurchBell.ogg" },
	{ key = "Duck",        file = "Duck.ogg" },
	{ key = "ElectroZap1", file = "ElectroZap1.mp3" },
	{ key = "ElectroZap2", file = "ElectroZap2.mp3" },
	{ key = "Heartbeat",   file = "Heartbeat.ogg" },
	{ key = "Message1",    file = "Message1.ogg" },
	{ key = "Message2",    file = "Message2.ogg" },
	{ key = "Ringtone1",   file = "Ringtone1.mp3" },
	{ key = "Ringtone2",   file = "Ringtone2.mp3" },
	{ key = "Sparkle",     file = "Sparkle.mp3" },
	{ key = "Squish",      file = "Squish.ogg" },
	{ key = "WindChime",   file = "WindChime.ogg" },
	{ key = "Xylophone",   file = "Xylophone.ogg" },
};

local function SoundIndex(key)
	for i, s in ipairs(K.SOUNDS) do
		if s.key == key then return i; end
	end
	return 1;
end

function K.SoundName(key)
	local s = K.SOUNDS[SoundIndex(key)];
	return s.text or s.key;
end

function K.PlayNUFSound(key)
	local s = K.SOUNDS[SoundIndex(key)];
	if s.file then
		PlaySoundFile(SOUND_DIR .. s.file);
	else
		PlaySound("RaidWarning");
	end
end

local soundMenu;
local function BuildSoundMenu()
	local m = CreateFrame("Frame", "NUF_SoundMenu", UIParent);
	m:SetFrameStrata("FULLSCREEN_DIALOG");
	m:SetClampedToScreen(true);
	m:EnableMouse(true);
	m:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 14,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	});
	m:SetBackdropColor(0.05, 0.05, 0.05, 0.97);
	m:SetBackdropBorderColor(0.5, 0.5, 0.5, 1);
	m.rows = {};
	local ROW_H = 16;
	for i, s in ipairs(K.SOUNDS) do
		local r = CreateFrame("Button", nil, m);
		r:SetHeight(ROW_H);
		r:SetPoint("TOPLEFT", 6, -6 - (i - 1) * ROW_H);
		r:SetPoint("RIGHT", m, "RIGHT", -6, 0);
		r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD");
		r.check = r:CreateTexture(nil, "OVERLAY");
		r.check:SetSize(14, 14);
		r.check:SetPoint("LEFT", 2, 0);
		r.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
		r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		r.text:SetPoint("LEFT", 20, 0);
		r.text:SetText(s.text or s.key);
		r.key = s.key;
		r:SetScript("OnClick", function(self)
			K.PlayNUFSound(self.key);
			if m.onPick then m.onPick(self.key); end
			m:Hide();
		end);
		m.rows[i] = r;
	end
	m:SetHeight(12 + #K.SOUNDS * ROW_H);

	m:SetScript("OnUpdate", function(self)

		if self.owner and not self.owner:IsVisible() then self:Hide(); return; end
		if (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton"))
		   and not self:IsMouseOver() and not (self.owner and self.owner:IsMouseOver()) then
			self:Hide();
		end
	end);
	m:Hide();
	return m;
end

function K.UI.OpenSoundMenu(owner, current, onPick)
	soundMenu = soundMenu or BuildSoundMenu();
	if soundMenu:IsShown() and soundMenu.owner == owner then
		soundMenu:Hide();
		return;
	end
	soundMenu.owner, soundMenu.onPick = owner, onPick;
	for _, r in ipairs(soundMenu.rows) do
		if r.key == (K.SOUNDS[SoundIndex(current)].key) then r.check:Show(); else r.check:Hide(); end
	end
	soundMenu:SetWidth(math.max(150, owner:GetWidth()));
	soundMenu:ClearAllPoints();
	soundMenu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2);
	soundMenu:Show();
end

function K.UI.SoundPicker(parent, x, y, labelText, getFn, setFn, width)
	width = width or 170;
	local f = CreateFrame("Frame", nil, parent);
	f:SetPoint("TOPLEFT", x, y);
	f:SetSize(width + 26, 38);

	local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	lbl:SetPoint("TOPLEFT", 0, 0);
	lbl:SetText(K.UI.Label(labelText or (L["SOUND_PICK"] or "Sound:")));

	local box = CreateFrame("Frame", nil, f);
	box:SetPoint("TOPLEFT", 0, -15);
	box:SetSize(width, 22);
	box:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	box:SetBackdropColor(0.07, 0.07, 0.07, 0.75);
	box:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.8);

	local name = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	name:SetPoint("LEFT", 8, 0);
	name:SetPoint("RIGHT", -22, 0);
	name:SetJustifyH("LEFT");

	local function Refresh()
		name:SetText(K.SoundName(getFn()));
	end

	local open = CreateFrame("Button", nil, box);
	open:SetAllPoints(box);
	open:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD");
	local arrow = box:CreateTexture(nil, "OVERLAY");
	arrow:SetSize(20, 20);
	arrow:SetPoint("RIGHT", -1, 0);
	arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up");
	open:SetScript("OnClick", function()
		K.UI.OpenSoundMenu(box, getFn(), function(key)
			setFn(key);
			Refresh();
		end);
	end);

	local play = CreateFrame("Button", nil, f);
	play:SetSize(22, 22);
	play:SetPoint("LEFT", box, "RIGHT", 4, 0);
	play:SetNormalTexture("Interface\\Common\\VoiceChat-Speaker");
	play:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD");
	play:SetScript("OnClick", function() K.PlayNUFSound(getFn()); end);
	play:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SOUND_PLAY"] or "Play", 1, 1, 1);
		GameTooltip:Show();
	end);
	play:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	parent:HookScript("OnShow", Refresh);
	Refresh();
	f.Refresh = Refresh;
	return f, Refresh;
end
