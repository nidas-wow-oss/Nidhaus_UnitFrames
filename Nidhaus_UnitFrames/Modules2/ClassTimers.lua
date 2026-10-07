local AddOnName, ns = ...;
local K, C, L = unpack(ns);























local FRAME_W, FRAME_H = 120, 30;
local ICON_SIZE        = 15;
local BAR_W,  BAR_H    = 105, 15;
local FONT_SIZE        = 10;

local _, playerClass = UnitClass("player");

function K.GetPlayerClass()
	return playerClass;
end




local function DB(key)
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.ClassTimers then NidhausUnitFramesDB.ClassTimers = {}; end
	if not NidhausUnitFramesDB.ClassTimers[key] then
		NidhausUnitFramesDB.ClassTimers[key] = {};
	end
	return NidhausUnitFramesDB.ClassTimers[key];
end

local bars    = {};
local preview = false;

local function IsLocked()
	return C.ClassTimersLocked == true;
end


















local function ApplySavedScale(f)
	pcall(f.SetScale, f, K.GetClassTimersScale());
end

local function BuildBar(key, label, iconPath, defaultY, maxDuration)
	local f = CreateFrame("Frame", "NUF_ClassTimer_" .. key, UIParent);
	f:SetSize(FRAME_W, FRAME_H);
	f:SetMovable(true);



	f:EnableMouse(not IsLocked());
	f:SetClampedToScreen(true);
	f:Hide();


	f.icon = f:CreateTexture(nil, "BACKGROUND");
	f.icon:SetSize(ICON_SIZE, ICON_SIZE);
	f.icon:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0);
	f.icon:SetTexture(iconPath);


	local bar = CreateFrame("StatusBar", "NUF_ClassTimerBar_" .. key, f);
	bar:SetSize(BAR_W, BAR_H);
	bar:SetPoint("LEFT", f.icon, "LEFT", ICON_SIZE, 0);
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	bar:SetStatusBarColor(0, 0, 1);
	bar:SetMinMaxValues(0, maxDuration);
	bar:SetValue(0);
	f.bar = bar;


	f.title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	f.title:SetPoint("TOP", f, "TOP", 0, -3);
	f.title:SetFont("Fonts\\FRIZQT__.TTF", FONT_SIZE);
	f.title:SetText(label);






	f.timeText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	f.timeText:SetPoint("CENTER", bar, "CENTER", 0, 0);
	f.timeText:SetFont("Fonts\\FRIZQT__.TTF", FONT_SIZE, "OUTLINE");
	f.timeText:SetTextColor(1, 1, 1);


	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", function(self)
		if IsLocked() then return; end
		self:StartMoving();
		self.isMoving = true;
	end);
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing();
		self.isMoving = false;
		local db = DB(key);
		local point, _, relativePoint, x, y = self:GetPoint();
		db.point, db.relativePoint, db.x, db.y = point, relativePoint, x, y;
	end);

	f.endTime     = 0;
	f.maxDuration = maxDuration;
	f._key        = key;
	f._defaultY   = defaultY;

	bars[key] = f;
	ApplySavedScale(f);
	return f;
end

local function RestorePosition(f)
	local db = DB(f._key);
	f:ClearAllPoints();
	if db.point then
		f:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 0, f._defaultY);
	end
end



function K.GetClassTimersScale()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.ClassTimersScale;
	return (type(db) == "number" and db > 0) and db or 1.0;
end

function K.SetClassTimersScale(v)
	v = tonumber(v) or 1.0;
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB.ClassTimersScale = v;
	for _, f in pairs(bars) do
		pcall(f.SetScale, f, v);
	end
end

function K.ResetClassTimerPositions()
	for key, f in pairs(bars) do
		local db = DB(key);
		db.point, db.relativePoint, db.x, db.y = nil, nil, nil, nil;
		RestorePosition(f);
	end
end








local UpdateTickerState;

local function StartBar(f, duration)
	if not f then return; end
	f.endTime     = GetTime() + duration;
	f.maxDuration = duration;
	f.bar:SetMinMaxValues(0, duration);
	f.bar:SetValue(duration);
	f.timeText:SetText(string.format("%d", duration));
	f:SetAlpha(1);
	f:Show();
	UpdateTickerState();
end





local ticker = CreateFrame("Frame");
local acc = 0;
ticker:Hide();

local function AnyBarRunning()
	for _, f in pairs(bars) do
		if f:IsShown() then return true; end
	end
	return false;
end

function UpdateTickerState()
	if preview then ticker:Hide(); return; end
	if AnyBarRunning() then
		acc = 0;
		ticker:Show();
	else
		ticker:Hide();
	end
end

ticker:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < 0.1 then return; end
	acc = 0;

	local anyRunning = false;
	for _, f in pairs(bars) do
		if f:IsShown() then
			local remaining = f.endTime - GetTime();
			if remaining <= 0 then
				f:Hide();
			else
				f.bar:SetValue(remaining);
				f.timeText:SetText(string.format("%d", math.ceil(remaining)));
				anyRunning = true;
			end
		end
	end


	if not anyRunning then self:Hide(); end
end);




function K.SetClassTimersPreview(state)
	preview = state and true or false;
	for _, f in pairs(bars) do
		f:EnableMouse(preview or not IsLocked());
		if preview then
			RestorePosition(f);
			f.bar:SetMinMaxValues(0, f.maxDuration);
			f.bar:SetValue(f.maxDuration * 0.65);
			f.timeText:SetText("--");
			f:SetAlpha(0.85);







			if not f._nufStrata then
				f._nufStrata = f:GetFrameStrata();
			end
			f:SetFrameStrata("FULLSCREEN_DIALOG");
			f:Show();
		else
			if f._nufStrata then
				f:SetFrameStrata(f._nufStrata);
				f._nufStrata = nil;
			end
			f:Hide();
		end
	end
	UpdateTickerState();
end


function K.ApplyClassTimersLock()
	local locked = IsLocked();
	for _, f in pairs(bars) do
		f:EnableMouse(not locked);
	end
end

function K.IsClassTimersPreview()
	return preview;
end

function K.HasClassTimers()
	return next(bars) ~= nil;
end




if playerClass == "MAGE" then
	local WE = BuildBar("WaterElemental",
		L["BAR_WATER_ELE"] or "Water Elemental",
		"Interface\\Icons\\Spell_Frost_SummonWaterElemental_2", 250, 45);

	local MI = BuildBar("MirrorImage",
		L["BAR_MIRROR"] or "Mirror Image",
		"Interface\\Icons\\spell_magic_lesserinvisibilty", 214, 30);


	local function HasEternalWaterGlyph()
		for k = 1, 6 do
			local enabled, _, glyphSpellID = GetGlyphSocketInfo(k);
			if enabled == 1 and glyphSpellID == 70937 then
				return true;
			end
		end
		return false;
	end


	local function WaterEleDuration()
		local _, _, _, _, currRank = GetTalentInfo(3, 26);
		return 45 + 5 * (currRank or 0);
	end

	local events = CreateFrame("Frame");
	events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	events:RegisterEvent("PLAYER_ENTERING_WORLD");
	events:SetScript("OnEvent", function(self, event, unit, spellName, _, _, spellID)
		if event == "PLAYER_ENTERING_WORLD" then
			RestorePosition(WE);
			RestorePosition(MI);
			return;
		end
		if unit ~= "player" then return; end
		if preview then return; end


		local isWE = (spellID == 31687) or (spellName == GetSpellInfo(31687));
		local isMI = (spellID == 55342) or (spellName == GetSpellInfo(55342));

		if isWE and C.MageWaterEleTimer then
			if not HasEternalWaterGlyph() then
				StartBar(WE, WaterEleDuration());
			end
		elseif isMI and C.MageMirrorTimer then
			StartBar(MI, 30);
		end
	end);
end




SLASH_NUFCLASS1 = "/nufclass";
SlashCmdList["NUFCLASS"] = function(msg)
	msg = string.lower(msg or "");
	if msg == "show" or msg == "move" then
		K.SetClassTimersPreview(true);
		print("|cff4FC3F7NUF:|r " .. (L["CLASSTIMERS_PREVIEW_ON"]
			or "Class bars shown. Drag them, then /nufclass hide."));
	elseif msg == "hide" then
		K.SetClassTimersPreview(false);
	elseif msg == "reset" then
		K.ResetClassTimerPositions();
		print("|cff4FC3F7NUF:|r " .. (L["CLASSTIMERS_RESET"] or "Class bar positions reset."));
	else
		print("|cff4FC3F7NUF:|r /nufclass show | hide | reset");
	end
end
