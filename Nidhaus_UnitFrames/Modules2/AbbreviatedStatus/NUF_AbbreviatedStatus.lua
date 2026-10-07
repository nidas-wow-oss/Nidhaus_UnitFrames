local AddOnName, ns = ...;
local K, C, L = unpack(ns);




















local CAP1 = FIRST_NUMBER_CAP_NO_SPACE  or "k";
local CAP2 = SECOND_NUMBER_CAP_NO_SPACE or "m";
local CAP3 = THIRD_NUMBER_CAP_NO_SPACE  or "b";
local CAP4 = FOURTH_NUMBER_CAP_NO_SPACE or "t";

local DATA = {
	{ breakpoint = 10000000000000, abbr = CAP4, sig = 1000000000000, frac = 1  },
	{ breakpoint = 1000000000000,  abbr = CAP4, sig = 100000000000,  frac = 10 },
	{ breakpoint = 10000000000,    abbr = CAP3, sig = 1000000000,    frac = 1  },
	{ breakpoint = 1000000000,     abbr = CAP3, sig = 100000000,     frac = 10 },
	{ breakpoint = 10000000,       abbr = CAP2, sig = 1000000,       frac = 1  },
	{ breakpoint = 1000000,        abbr = CAP2, sig = 100000,        frac = 10 },
	{ breakpoint = 10000,          abbr = CAP1, sig = 1000,          frac = 1  },
	{ breakpoint = 1000,           abbr = CAP1, sig = 100,           frac = 10 },
};




local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	local db = NidhausUnitFramesDB.AbbrevStatus;
	if not db then
		db = { prefix = 3, remainder = 1, units = {} };
		NidhausUnitFramesDB.AbbrevStatus = db;
	end
	return db;
end






































local BIG_UNITS = { player = true, target = true, focus = true };

local function VisualTheme(unit)
	if C.UnitFrameCustomTexture ~= true then return "Blizzard"; end

	if C.AsuriFrames then return "Asuri"; end
	local big = BIG_UNITS[unit] and K.BigStatusTextOn and K.BigStatusTextOn(unit);
	if C.pwFrames    then return big and "Compact+Big" or "Compact"; end
	if C.darkFrames  then return big and "Dark+Big" or "Dark"; end
	return big and "Light+Big" or "Light";
end











local function KeyCache(prefix)
	return setmetatable({}, { __index = function(self, k)
		local v = prefix .. tostring(k);
		rawset(self, k, v);
		return v;
	end });
end
local UF_KEYS    = KeyCache("uf:");
local PARTY_KEYS = KeyCache("party:");
local ARENA_KEYS = KeyCache("arena:");

local function ThemeKey(unit)
	if unit == "party" then
		return PARTY_KEYS[(K.GetPartyFrameStyle and K.GetPartyFrameStyle())
			or C.PartyFrameStyle or "Default"];
	end
	if unit == "arena" then
		if C.ArenaFlatMode then return ARENA_KEYS["Flat"]; end
		return ARENA_KEYS[C.ArenaFrameStyle or "Default"];
	end
	return UF_KEYS[VisualTheme(unit)];
end



local function ThemeLabel(unit)
	local k = ThemeKey(unit);
	return (k:gsub("^uf:", ""):gsub("^party:", ""):gsub("^arena:", ""));
end

local POS_FIELDS = {
	"hpNumX", "hpNumY", "hpPctX", "hpPctY",
	"mpNumX", "mpNumY", "mpPctX", "mpPctY",
};










local PLAYER_LIKE = {
	hpNumX = -1, hpNumY = -6, hpPctX =  1, hpPctY = -6,
	mpNumX = -3, mpNumY =  0, mpPctX =  2, mpPctY =  0,
};



local PLAYER_BIG = {
	hpNumX = -1, hpNumY = 0, hpPctX = 1, hpPctY = 0,
	mpNumX = -3, mpNumY = 0, mpPctX = 2, mpPctY = 0,
};






local BLIZZARD_LIKE = {
	hpNumX = -1, hpNumY = 0, hpPctX = 5, hpPctY = 0,
	mpNumX =  0, mpNumY = 0, mpPctX = 5, mpPctY = 0,
};



local POS_DEFAULTS = {
	["uf:Blizzard"] = {
		player = BLIZZARD_LIKE, target = BLIZZARD_LIKE, focus = BLIZZARD_LIKE,
	},
	["uf:Compact+Big"] = {
		player = PLAYER_BIG, target = PLAYER_BIG, focus = PLAYER_BIG,
	},
	["uf:Light+Big"] = {
		player = PLAYER_BIG, target = PLAYER_BIG, focus = PLAYER_BIG,
	},
	["uf:Dark+Big"] = {
		player = PLAYER_BIG, target = PLAYER_BIG, focus = PLAYER_BIG,
	},
	["uf:Asuri"] = {
		player = PLAYER_LIKE, target = PLAYER_LIKE, focus = PLAYER_LIKE,
	},
	["uf:Compact"] = {
		player = PLAYER_LIKE, target = PLAYER_LIKE, focus = PLAYER_LIKE,
	},
	["uf:Light"] = {
		player = PLAYER_LIKE, target = PLAYER_LIKE, focus = PLAYER_LIKE,
	},
	["uf:Dark"] = {
		player = PLAYER_LIKE, target = PLAYER_LIKE, focus = PLAYER_LIKE,
	},
};



local function UnitCfg(unit)
	local db = DB();
	if not db.units[unit] then
		db.units[unit] = {
			on = true,
			hpNum = true, hpPct = true, mpNum = true, mpPct = true,
		};
	end

	if db.units[unit].on == nil then db.units[unit].on = true; end
	return db.units[unit];
end





local function UnitPos(unit)
	local cfg = UnitCfg(unit);
	if not cfg.pos then cfg.pos = {}; end






	if not cfg._posMigrated then
		local old, any = {}, false;
		for _, f in ipairs(POS_FIELDS) do
			if type(cfg[f]) == "number" and cfg[f] ~= 0 then old[f] = cfg[f]; any = true; end
			cfg[f] = nil;
		end
		if any then cfg.pos[ThemeKey(unit)] = old; end
		cfg._posMigrated = true;
	end

	local key = ThemeKey(unit);
	local slot = cfg.pos[key];










	if slot then
		local empty = true;
		for _ in pairs(slot) do empty = false; break; end
		if empty then slot = nil; end
	end

	if not slot then
		local d = POS_DEFAULTS[key] and POS_DEFAULTS[key][unit];
		slot = {};
		if d then for _, f in ipairs(POS_FIELDS) do slot[f] = d[f] or 0; end end
		cfg.pos[key] = slot;
	end
	return slot;
end

local VALID = {
	player = true, target = true, focus = true,
	pet = true, party = true, arena = true,
};






local function Abbrev(value, remainder, prefix)
	remainder = remainder or 1;
	prefix    = prefix or 3;
	local index = (prefix >= 3) and (prefix - 3) or 0;
	for _, d in ipairs(DATA) do
		if value >= d.breakpoint then
			local finalValue = string.format("%." .. remainder .. "f", (value / d.sig) / d.frac);
			local cur = DATA[#DATA - index].breakpoint;
			if prefix > 1 and cur <= d.breakpoint then
				return finalValue .. d.abbr;
			else
				return finalValue;
			end
		end
	end
	return tostring(value);
end


local function AbbrevThreshold(value)
	for _, d in ipairs(DATA) do
		if value >= d.breakpoint then
			return (math.floor(value / d.sig) / d.frac) .. d.abbr;
		end
	end
	return tostring(value);
end

local function IsOn()
	return K.IsModuleEnabled and K.IsModuleEnabled("AbbreviatedStatus");
end







local function CaptureOrigPoints(self, fs)





	if self._nufMoved then return; end
	local pts = {};
	for i = 1, (fs:GetNumPoints() or 0) do
		local p, rel, rp, x, y = fs:GetPoint(i);
		if p then pts[#pts + 1] = { p, rel, rp, x, y }; end
	end
	if #pts > 0 then self._nufOrigPts = pts; end
end












local function SetWithOffset(self, fs, dx, dy)
	fs:ClearAllPoints();
	fs:SetPoint("CENTER", self, "CENTER", dx, dy);
end


local function RestoreOrigPoints(self, fs)
	local pts = self._nufOrigPts;













	if not pts or #pts == 0 then
		fs:ClearAllPoints();
		fs:SetPoint("CENTER", self, "CENTER", 0, 0);
		return;
	end

	fs:ClearAllPoints();
	for _, pt in ipairs(pts) do
		pcall(fs.SetPoint, fs, pt[1], pt[2] or self, pt[3] or pt[1], pt[4] or 0, pt[5] or 0);
	end
end

































local function CreatePct(bar, statusText)
	local textParent = statusText:GetParent() or bar;
	local box = CreateFrame("Frame", nil, bar);
	box:SetAllPoints(bar);
	local lvl = bar:GetFrameLevel() or 0;
	local tl = textParent.GetFrameLevel and textParent:GetFrameLevel() or 0;
	if tl > lvl then lvl = tl; end
	box:SetFrameLevel(lvl + 1);
	local ok, layer = pcall(statusText.GetDrawLayer, statusText);
	if not ok or not layer then layer = "OVERLAY"; end
	local fs = box:CreateFontString(nil, layer, "TextStatusBarText");
	local okS, sx, sy = pcall(statusText.GetShadowOffset, statusText);
	if okS and sx then fs:SetShadowOffset(sx, sy); end
	local okC, r, g, b, a = pcall(statusText.GetShadowColor, statusText);
	if okC and r then fs:SetShadowColor(r, g, b, a); end
	bar._nufPct = fs;
	return fs;
end







local function MirrorPct(statusText, pctFS)
	local face, size, flags = statusText:GetFont();
	if face and (pctFS._nufFace ~= face or pctFS._nufSize ~= size or pctFS._nufFlags ~= flags) then
		if pcall(pctFS.SetFont, pctFS, face, size, flags) then
			pctFS._nufFace, pctFS._nufSize, pctFS._nufFlags = face, size, flags;
		end
	end
	pctFS:SetTextColor(statusText:GetTextColor());
	pctFS:SetAlpha(statusText:GetAlpha());
end




function K.MirrorAbbrevPct(bar)
	if bar and bar._nufPct and bar.TextString then
		pcall(MirrorPct, bar.TextString, bar._nufPct);
	end
end

local function ApplyBar(self)
	local statusText = self.TextString;
	if not statusText then return; end

	CaptureOrigPoints(self, statusText);



	if not IsOn() then
		if self._nufPct then self._nufPct:Hide(); end
		if self._nufMoved then
			RestoreOrigPoints(self, statusText);
			self._nufMoved = false;
		end
		return;
	end

	local unit = self.unit;
	if not unit then return; end







	local ukey = self._nufUKey;
	if ukey == nil or self._nufUKeyFor ~= unit then
		ukey = string.gsub(unit, "%d", "");
		self._nufUKey = ukey;
		self._nufUKeyFor = unit;
	end
	if not VALID[ukey] then return; end


	local ucfg = UnitCfg(ukey);
	if not ucfg.on then
		if self._nufPct then self._nufPct:Hide(); end
		if self._nufMoved then
			RestoreOrigPoints(self, statusText);
			self._nufMoved = false;
		end
		return;
	end


	local isHealth = self._nufIsHealth;
	if isHealth == nil then
		local n = self:GetName();
		isHealth = (n and string.find(n, "HealthBar")) and true or false;
		self._nufIsHealth = isHealth;
	end

	local cfg = UnitCfg(ukey);
	local wantNum = isHealth and cfg.hpNum or cfg.mpNum;
	local wantPct = isHealth and cfg.hpPct or cfg.mpPct;

	local db = DB();
	local value = self:GetValue() or 0;
	local _, vmax = self:GetMinMaxValues();





	if not vmax or vmax <= 0 then
		if self._nufPct then self._nufPct:Hide(); end
		return;
	end


	local pctFS = self._nufPct;
	if wantPct and not pctFS then
		pctFS = CreatePct(self, statusText);
	end
	if pctFS then MirrorPct(statusText, pctFS); end


	if wantNum then
		if value > 0 then
			statusText:SetText(Abbrev(value, db.remainder, db.prefix));
		elseif not self.zeroText then



			statusText:SetText("0");
		end
		statusText:Show();
	else
		statusText:Hide();
	end


	local pctShown = false;
	if wantPct and pctFS then
		if vmax and vmax > 0 and value > 0 then
			pctFS:SetText(string.format("%d%%", value / vmax * 100 + 0.5));
			pctFS:Show();
			pctShown = true;
		else
			pctFS:Hide();
		end
	elseif pctFS then
		pctFS:Hide();
	end


	local numX, numY, pctX, pctY;
	local pos = UnitPos(ukey);
	if isHealth then
		numX, numY = pos.hpNumX or 0, pos.hpNumY or 0;
		pctX, pctY = pos.hpPctX or 0, pos.hpPctY or 0;
	else
		numX, numY = pos.mpNumX or 0, pos.mpNumY or 0;
		pctX, pctY = pos.mpPctX or 0, pos.mpPctY or 0;
	end



	if wantNum and pctShown then
		statusText:ClearAllPoints();
		statusText:SetPoint("RIGHT", self, "RIGHT", numX, numY);
		pctFS:ClearAllPoints();
		pctFS:SetPoint("LEFT", self, "LEFT", pctX, pctY);
		self._nufMoved = true;
	else


		SetWithOffset(self, statusText, numX, numY);
		if pctFS then
			SetWithOffset(self, pctFS, pctX, pctY);
		end








		self._nufMoved = true;
	end
end






hooksecurefunc("TextStatusBar_UpdateTextString", function(self)
	pcall(ApplyBar, self);
end);




local UNIT_BARS = {
	"PlayerFrameHealthBar", "PlayerFrameManaBar",
	"PetFrameHealthBar",    "PetFrameManaBar",
	"TargetFrameHealthBar", "TargetFrameManaBar",
	"FocusFrameHealthBar",  "FocusFrameManaBar",
};
for i = 1, 4 do
	table.insert(UNIT_BARS, "PartyMemberFrame" .. i .. "HealthBar");
	table.insert(UNIT_BARS, "PartyMemberFrame" .. i .. "ManaBar");
end
for i = 1, 5 do
	table.insert(UNIT_BARS, "ArenaEnemyFrame" .. i .. "HealthBar");
	table.insert(UNIT_BARS, "ArenaEnemyFrame" .. i .. "ManaBar");
end











local refreshPending = false;

local function RefreshAllBars()
	if not TextStatusBar_UpdateTextString then return; end
	if InCombatLockdown() then refreshPending = true; return; end
	refreshPending = false;
	for _, name in ipairs(UNIT_BARS) do
		local bar = _G[name];
		if bar then pcall(TextStatusBar_UpdateTextString, bar); end
	end
end
K.RefreshAbbreviatedStatusBars = RefreshAllBars;

local refreshWatcher = CreateFrame("Frame");
refreshWatcher:RegisterEvent("PLAYER_REGEN_ENABLED");
refreshWatcher:SetScript("OnEvent", function()
	if refreshPending then RefreshAllBars(); end
end);




local function ReleaseBar(bar)




	if bar._nufMoved and bar.TextString then
		pcall(RestoreOrigPoints, bar, bar.TextString);
	end
	bar._nufOrigPts = nil;
	bar._nufMoved   = false;
end










function K.ReleaseAbbrevAnchors(prefix)
	for _, name in ipairs(UNIT_BARS) do
		if not prefix or string.find(name, prefix, 1, true) == 1 then
			local bar = _G[name];
			if bar then ReleaseBar(bar); end
		end
	end
end

function K.InvalidateAbbrevAnchors()
	K.ReleaseAbbrevAnchors();
	RefreshAllBars();
end






local win;

local UNITS = {
	{ key = "player", label = PLAYER or "Player" },
	{ key = "target", label = TARGET or "Target" },
	{ key = "focus",  label = FOCUS  or "Focus"  },
	{ key = "pet",    label = PET    or "Pet"    },
	{ key = "party",  label = PARTY  or "Party"  },
	{ key = "arena",  label = ARENA  or "Arena"  },
};


local COLS = {
	{ field = "hpNum", head = "HP #" },
	{ field = "hpPct", head = "HP %" },
	{ field = "mpNum", head = "MP #" },
	{ field = "mpPct", head = "MP %" },
};
local COL_X = { 165, 230, 300, 365 };


local OFF_LAYOUT = {
	{ col = 1, row = 1, field = "hpNumX", label = "HP #  X" },
	{ col = 1, row = 2, field = "hpNumY", label = "HP #  Y" },
	{ col = 1, row = 3, field = "hpPctX", label = "HP %  X" },
	{ col = 1, row = 4, field = "hpPctY", label = "HP %  Y" },
	{ col = 2, row = 1, field = "mpNumX", label = "MP #  X" },
	{ col = 2, row = 2, field = "mpNumY", label = "MP #  Y" },
	{ col = 2, row = 3, field = "mpPctX", label = "MP %  X" },
	{ col = 2, row = 4, field = "mpPctY", label = "MP %  Y" },
};
local OFF_COLX = { [1] = 425, [2] = 555 };
local OFF_ROWY = { [1] = -128, [2] = -176, [3] = -224, [4] = -272 };

local function RefreshWindow()
	if not win then return; end
	win._syncing = true;
	local db = DB();
	win.remSlider:SetValue(db.remainder or 1);
	win.preSlider:SetValue(db.prefix or 3);
	if _G["NUF_AbbrevPreSliderText"] then
		_G["NUF_AbbrevPreSliderText"]:SetText(
			(L["ABBREV_FROM"] or "Abbreviate from") .. ": " .. AbbrevThreshold(
				DATA[#DATA - ((db.prefix >= 3) and (db.prefix - 3) or 0)].breakpoint));
	end
	for _, cb in ipairs(win.cells) do
		local cfg = UnitCfg(cb._unit);
		cb:SetChecked(cfg[cb._field] and true or false);

		if cb._refreshRow then cb._refreshRow(); end
	end


	if win.offSliders then
		local cfg = UnitPos(win.selUnit or "player");
		for i, s in ipairs(win.offSliders) do
			local v = cfg[s._field] or 0;
			s:SetValue(v);
			if _G["NUF_AbbrevOff" .. i .. "Text"] then
				_G["NUF_AbbrevOff" .. i .. "Text"]:SetText(s._label .. "  " .. v);
			end
		end
		if win.unitDD then UIDropDownMenu_SetSelectedValue(win.unitDD, win.selUnit or "player"); end
	end

	if win.themeFS then
		local u = win.selUnit or "player";
		win._themeKey = ThemeKey(u);
		win.themeFS:SetText("|cff8EAEC9" .. (L["ABBREV_POS_THEME"] or "Theme")
			.. ":|r |cffFFD100" .. ThemeLabel(u) .. "|r");
	end

	win._syncing = false;
end

local function BuildWindow()
	win = CreateFrame("Frame", "NUF_AbbrevStatusWindow", UIParent);

	if K.UI and K.UI.AutoRestyle then K.UI.AutoRestyle(win); end

	win:SetSize(690, 430);
	win:SetPoint("CENTER");
	win:SetFrameStrata("FULLSCREEN_DIALOG");
	win:EnableMouse(true);
	win:SetMovable(true);
	win:RegisterForDrag("LeftButton");
	win:SetScript("OnDragStart", win.StartMoving);
	win:SetScript("OnDragStop",  win.StopMovingOrSizing);
	win:SetClampedToScreen(true);
	win:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	});

	local titleBox = CreateFrame("Frame", nil, win);
	titleBox:SetSize(260, 30);
	titleBox:SetPoint("TOP", win, "TOP", 0, 6);
	titleBox:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
		tile = true, tileSize = 32, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	});
	titleBox:SetBackdropColor(0.10, 0.10, 0.10, 1.0);
	local title = titleBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	title:SetPoint("CENTER", titleBox, "CENTER", 0, 1);
	title:SetText(L["MOD_ABBREV_STATUS"] or "Abbreviated Status");

	local close = CreateFrame("Button", nil, win, "UIPanelCloseButton");
	close:SetPoint("TOPRIGHT", -4, -4);
	close:SetScript("OnClick", function() win:Hide(); end);


	local fmtH = win:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	fmtH:SetPoint("TOPLEFT", 20, -40);
	fmtH:SetText((K.UI and K.UI.Header("Format")) or "|cffFFD100Format|r");

	local rem = CreateFrame("Slider", "NUF_AbbrevRemSlider", win, "OptionsSliderTemplate");
	rem:SetPoint("TOPLEFT", 30, -78);
	rem:SetWidth(150);
	rem:SetMinMaxValues(0, 2);
	rem:SetValueStep(1);
	_G["NUF_AbbrevRemSliderLow"]:SetText("0");
	_G["NUF_AbbrevRemSliderHigh"]:SetText("2");
	_G["NUF_AbbrevRemSliderText"]:SetText(L["ABBREV_DECIMALS"] or "Decimals");
	rem:SetScript("OnValueChanged", function(self, v)
		v = math.floor(v + 0.5);
		if win._syncing then return; end
		DB().remainder = v;
		RefreshAllBars();
	end);
	win.remSlider = rem;

	local pre = CreateFrame("Slider", "NUF_AbbrevPreSlider", win, "OptionsSliderTemplate");
	pre:SetPoint("TOPLEFT", 240, -78);
	pre:SetWidth(150);
	pre:SetMinMaxValues(3, 8);
	pre:SetValueStep(1);
	_G["NUF_AbbrevPreSliderLow"]:SetText("");
	_G["NUF_AbbrevPreSliderHigh"]:SetText("");
	pre:SetScript("OnValueChanged", function(self, v)
		v = math.floor(v + 0.5);
		local idx = (v >= 3) and (v - 3) or 0;
		_G["NUF_AbbrevPreSliderText"]:SetText(
			(L["ABBREV_FROM"] or "Abbreviate from") .. ": " .. AbbrevThreshold(DATA[#DATA - idx].breakpoint));
		if win._syncing then return; end
		DB().prefix = v;
		RefreshAllBars();
	end);
	win.preSlider = pre;

	if K.UI and K.UI.Separator then K.UI.Separator(win, 16, -118, 408); end


	local onHead = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	onHead:SetPoint("CENTER", win, "TOPLEFT", 30, -134);
	onHead:SetText("|cffFFD100" .. (L["ABBREV_ON"] or "On") .. "|r");

	for i, c in ipairs(COLS) do
		local h = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		h:SetPoint("CENTER", win, "TOPLEFT", COL_X[i] + 12, -134);
		h:SetText("|cffFFD100" .. c.head .. "|r");
	end

	win.cells = {};
	local rowY = -152;
	for _, u in ipairs(UNITS) do


		local master = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate");
		master:SetSize(24, 24);
		master:SetPoint("TOPLEFT", 18, rowY);
		master._unit, master._field = u.key, "on";
		table.insert(win.cells, master);

		local ulabel = win:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		ulabel:SetPoint("TOPLEFT", 46, rowY - 4);
		ulabel:SetText(u.label);

		local rowCells = {};
		for i, c in ipairs(COLS) do
			local cb = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate");
			cb:SetSize(24, 24);
			cb:SetPoint("TOPLEFT", COL_X[i], rowY);
			cb._unit, cb._field = u.key, c.field;
			cb:SetScript("OnClick", function(self)
				if win._syncing then return; end
				local v = self:GetChecked() == 1 or self:GetChecked() == true;
				UnitCfg(u.key)[c.field] = v;
				RefreshAllBars();
			end);
			table.insert(win.cells, cb);
			table.insert(rowCells, cb);
		end


		local function RefreshRow()
			local on = UnitCfg(u.key).on;
			for _, cb in ipairs(rowCells) do
				if on then cb:Enable(); cb:SetAlpha(1);
				else cb:Disable(); cb:SetAlpha(0.35); end
			end
			ulabel:SetAlpha(on and 1 or 0.45);
		end
		master._refreshRow = RefreshRow;

		master:SetScript("OnClick", function(self)
			if win._syncing then return; end
			local v = self:GetChecked() == 1 or self:GetChecked() == true;
			UnitCfg(u.key).on = v;
			RefreshRow();
			RefreshAllBars();
		end);

		rowY = rowY - 32;
	end


	win.selUnit = win.selUnit or "player";

	local posH = win:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	posH:SetPoint("TOPLEFT", 410, -40);
	posH:SetText((K.UI and K.UI.Header("Position")) or "|cffFFD100Position|r");

	local posNote = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	posNote:SetPoint("TOPLEFT", 412, -60);
	posNote:SetWidth(250);
	posNote:SetJustifyH("LEFT");
	posNote:SetText("|cff8EAEC9" .. (L["ABBREV_POS_NOTE"]
		or "Move the health/mana texts of the selected unit.") .. "|r");






	local themeFS = win:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
	themeFS:SetPoint("TOPLEFT", 412, -92);
	win.themeFS = themeFS;


	local unitDD = CreateFrame("Frame", "NUF_AbbrevUnitDD", win, "UIDropDownMenuTemplate");
	unitDD:SetPoint("TOPLEFT", 400, -74);
	UIDropDownMenu_SetWidth(unitDD, 130);
	UIDropDownMenu_Initialize(unitDD, function(self, level)
		for _, u in ipairs(UNITS) do
			local info = UIDropDownMenu_CreateInfo();
			info.text  = u.label;
			info.value = u.key;
			info.func  = function(btn)
				win.selUnit = btn.value;
				UIDropDownMenu_SetSelectedValue(unitDD, btn.value);
				RefreshWindow();
			end;
			info.checked = (u.key == win.selUnit);
			UIDropDownMenu_AddButton(info, level);
		end
	end);
	UIDropDownMenu_SetSelectedValue(unitDD, win.selUnit);
	win.unitDD = unitDD;


	win.offSliders = {};
	for i, o in ipairs(OFF_LAYOUT) do
		local sName = "NUF_AbbrevOff" .. i;
		local s = CreateFrame("Slider", sName, win, "OptionsSliderTemplate");
		s:SetPoint("TOPLEFT", OFF_COLX[o.col], OFF_ROWY[o.row]);
		s:SetWidth(110);
		s:SetMinMaxValues(-30, 30);
		s:SetValueStep(1);
		_G[sName .. "Low"]:SetText("");
		_G[sName .. "High"]:SetText("");
		_G[sName .. "Text"]:SetText(o.label);
		s._field = o.field;
		s._label = o.label;
		s:SetScript("OnValueChanged", function(self, v)
			v = math.floor(v + 0.5);
			_G[sName .. "Text"]:SetText(o.label .. "  " .. v);
			if win._syncing then return; end
			UnitPos(win.selUnit)[o.field] = v;
			RefreshAllBars();
		end);
		win.offSliders[i] = s;
	end

	local reset = CreateFrame("Button", nil, win, "UIPanelButtonTemplate");
	reset:SetSize(150, 22);
	reset:SetPoint("BOTTOM", win, "BOTTOM", 0, 18);
	reset:SetText(L["ABBREV_RESET"] or "Restore defaults");
	reset:SetScript("OnClick", function()
		NidhausUnitFramesDB.AbbrevStatus = { prefix = 3, remainder = 1, units = {} };
		RefreshAllBars();
		RefreshWindow();
	end);






	win:SetScript("OnUpdate", function(self, elapsed)
		self._t = (self._t or 0) + elapsed;
		if self._t < 0.25 then return; end
		self._t = 0;
		if self._themeKey ~= ThemeKey(self.selUnit or "player") then
			RefreshWindow();
		end
	end);

	tinsert(UISpecialFrames, "NUF_AbbrevStatusWindow");
end

function K.OpenAbbreviatedStatusMenu()
	if not win then BuildWindow(); end
	if win:IsShown() then
		win:Hide();
	else
		RefreshWindow();
		win:Show();
	end
end




K.RegisterModule("AbbreviatedStatus", {
	name    = L["MOD_ABBREV_STATUS"] or "Abbreviated Status Text",
	desc    = L["MOD_ABBREV_STATUS_DESC"]
		or "Shortens the health/mana numbers on unit frames (12.3k instead of 12345).",
	default = false,
	hideFromModulesTab = true,
	configLabel = L["BTN_MODULE_OPEN"] or "Open",
	configFunc  = function() K.OpenAbbreviatedStatusMenu(); end,
	onEnable = function()



		if C.ShowCurrentValueOnly then
			if K.SaveConfig then K.SaveConfig("ShowCurrentValueOnly", false); end
			C.ShowCurrentValueOnly = false;
			if K.ApplyHealthTextFormat then K.ApplyHealthTextFormat(); end
		end
		if K._SyncStatusTextExclusive then K._SyncStatusTextExclusive(); end
		RefreshAllBars();
	end,
	onDisable = function()
		RefreshAllBars();



		if K.ApplyPlayerFrameSkin then pcall(K.ApplyPlayerFrameSkin); end
		if K.ApplyTargetFrameSkin then pcall(K.ApplyTargetFrameSkin); end


		if K.ApplyHealthTextFormat then K.ApplyHealthTextFormat(); end
		if K._SyncStatusTextExclusive then K._SyncStatusTextExclusive(); end
	end,
});
