local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ============================================================
-- SpecIcons - NUF Module v3
-- Detects enemy spec via combat log and shows spec icon on
-- Target, Focus, and Arena frames.
-- Flat mode: rectangular icon above class portrait.
-- Separate on/off for Target+Focus, Arena, and Flat mode.
-- ============================================================

local band = bit.band;
local ipairs, pairs, tinsert, wipe = ipairs, pairs, table.insert, wipe;
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER;
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE;
local UnitClass, UnitGUID, GetNumArenaOpponents = UnitClass, UnitGUID, GetNumArenaOpponents;
local GetPlayerInfoByGUID, SetPortraitToTexture = GetPlayerInfoByGUID, SetPortraitToTexture;
local IsInInstance = IsInInstance;

local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;

local metaDB;
local spellDB;

local moduleActive = false;
local duelZone = false;
local instanceType = "";
local specDB = {};
local IconFrames = {};
-- FIX PERF: Reverse lookup table (spellID → {class, spec}), built once at Enable
local reverseLookup = {};
-- FIX PERF: Reusable table for unit iteration (avoids garbage per combat event)
local reusableUnits = {};

-- ══════════════════════════════════════════════════════════════
-- SETTINGS
-- ══════════════════════════════════════════════════════════════

local defaults = {
	showOnTargetFocus = true,
	showOnArena       = true,
	showInFlatMode    = true,
};

local function GetDB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.SpecIcons then
		NidhausUnitFramesDB.SpecIcons = {};
		for k, v in pairs(defaults) do
			NidhausUnitFramesDB.SpecIcons[k] = v;
		end
	end
	return NidhausUnitFramesDB.SpecIcons;
end

local function GetSetting(key)
	local db = GetDB();
	if db[key] == nil then return defaults[key]; end
	return db[key];
end

local function SetSetting(key, value)
	local db = GetDB();
	db[key] = value;
end

-- ══════════════════════════════════════════════════════════════
-- ICON FRAME CREATION
-- ══════════════════════════════════════════════════════════════

local ICON_SIZE_UNIT  = 24;
local ICON_SIZE_ARENA = 20;
local BORDER_EXTRA    = 6;

local function CreateIconFrame(parent, unit, size)
	local f = CreateFrame("Frame", "NUF_SpecIcon_" .. unit, parent);
	f:SetFrameStrata("HIGH");
	f:SetSize(size, size);

	f.bg = f:CreateTexture(nil, "BACKGROUND");
	f.bg:SetAllPoints();

	-- Round border (DK ring) for Blizzard/Custom style
	f.roundBorder = f:CreateTexture(nil, "BORDER");
	f.roundBorder:SetPoint("CENTER", 1, -1);
	f.roundBorder:SetSize(size + BORDER_EXTRA, size + BORDER_EXTRA);
	f.roundBorder:SetTexture("Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Ring");
	f.roundBorder:SetVertexColor(0.8, 0.7, 0.2);

	-- Thin edge border for Flat style (created but hidden by default)
	f.flatBorder = f:CreateTexture(nil, "BORDER");
	f.flatBorder:SetPoint("TOPLEFT", -1, 1);
	f.flatBorder:SetPoint("BOTTOMRIGHT", 1, -1);
	f.flatBorder:SetTexture(0, 0, 0, 0.9);
	f.flatBorder:Hide();

	f._isFlat = false;
	f:Hide();
	return f;
end

local function SetIconFlat(f, isFlat, flatW, flatH)
	if not f then return; end
	f._isFlat = isFlat;
	if isFlat then
		f.roundBorder:Hide();
		f.flatBorder:Show();
		f:SetSize(flatW or 28, flatH or 12);
		f.bg:SetTexCoord(0.08, 0.92, 0.25, 0.75); -- crop for rectangular
	else
		f.roundBorder:Show();
		f.flatBorder:Hide();
		local s = f._origSize or ICON_SIZE_ARENA;
		f:SetSize(s, s);
		f.bg:SetTexCoord(0, 1, 0, 1);
	end
end

-- ══════════════════════════════════════════════════════════════
-- POSITIONING
-- ══════════════════════════════════════════════════════════════

local function PositionUnitIcon(unit)
	local f = IconFrames[unit];
	if not f then return; end
	local parent;
	if unit == "target" then parent = TargetFrame;
	elseif unit == "focus" then parent = FocusFrame;
	end
	if not parent then return; end
	f:SetParent(parent);
	f:SetFrameLevel(_G[parent:GetName() .. "TextureFrame"]:GetFrameLevel() + 1);
	f:ClearAllPoints();
	f:SetPoint("TOP", parent, "TOP", 0, -10);
	SetIconFlat(f, false);
end

local function PositionArenaIcon(index)
	local unit = "arena" .. index;
	local f = IconFrames[unit];
	if not f then return; end

	local parent = _G["ArenaEnemyFrame" .. index];
	if not parent then return; end

	f:SetParent(parent);
	f:ClearAllPoints();

	local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
	local isMirror = C.ArenaMirrorMode;

	if isFlat then
		-- Check if flat mode icons are enabled
		if not GetSetting("showInFlatMode") then
			f:Hide();
			return;
		end

		-- Get portrait container size for matching width
		local pc = parent._flatPortraitContainer;
		local portraitSize = pc and pc:GetWidth() or 28;

		-- Rectangular: same width as portrait, short height
		local flatW = portraitSize;
		local flatH = math.max(10, math.floor(portraitSize * 0.38));
		SetIconFlat(f, true, flatW, flatH);

		if pc then
			-- Anchor above the portrait container
			if isMirror then
				f:SetPoint("BOTTOMLEFT", pc, "TOPLEFT", 0, 1);
			else
				f:SetPoint("BOTTOMRIGHT", pc, "TOPRIGHT", 0, 1);
			end
		else
			-- Fallback: no portrait container yet
			if isMirror then
				f:SetPoint("TOPLEFT", parent, "TOPLEFT", -2, 2);
			else
				f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 2, 2);
			end
		end
	else
		-- Blizzard / Custom style: round icon
		SetIconFlat(f, false);

		if isMirror then
			f:SetPoint("TOPLEFT", parent, "TOPLEFT", -6, -18);
		else
			f:SetPoint("TOP", parent, "TOP", 45, -18);
		end
	end
end

function K.RepositionAllSpecIcons()
	if not moduleActive then return; end
	for i = 1, MAX_ARENA_ENEMIES do
		PositionArenaIcon(i);
	end
end

-- ══════════════════════════════════════════════════════════════
-- SPEC DETECTION & DISPLAY
-- ══════════════════════════════════════════════════════════════

local function ShowSpecIcon(unit, class, spec)
	local f = IconFrames[unit];
	if not f then return; end
	if not metaDB[class] or not metaDB[class][spec] then return; end

	-- Check per-unit-type settings
	if unit == "target" or unit == "focus" then
		if not GetSetting("showOnTargetFocus") then f:Hide(); return; end
	elseif unit:find("^arena") then
		if not GetSetting("showOnArena") then f:Hide(); return; end
		-- Additional flat mode check
		local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
		if isFlat and not GetSetting("showInFlatMode") then f:Hide(); return; end
	end

	-- FIX: Check flat mode LIVE instead of cached _isFlat flag.
	-- The flag may not be set yet if ShowSpecIcon runs before PositionArenaIcon.
	local iconPath = "Interface\\Icons\\" .. metaDB[class][spec];
	local isCurrentlyFlat = unit:find("^arena") and K.IsFlatModeActive and K.IsFlatModeActive();

	if isCurrentlyFlat then
		-- Ensure the frame is in flat shape (may not have been positioned yet)
		if not f._isFlat then
			local index = tonumber(unit:match("(%d+)$"));
			if index then PositionArenaIcon(index); end
		end
		f.bg:SetTexture(iconPath);
		f.bg:SetTexCoord(0.08, 0.92, 0.25, 0.75);
	else
		f.bg:SetTexCoord(0, 1, 0, 1);
		SetPortraitToTexture(f.bg, iconPath);
	end
	f:Show();
end

local function UpdateOnChange(unit)
	local guid = UnitGUID(unit);
	if not guid then
		if IconFrames[unit] then IconFrames[unit]:Hide(); end
		return;
	end
	local spec = specDB[guid];
	if spec then
		local _, class = UnitClass(unit);
		if class then
			ShowSpecIcon(unit, class, spec);
			return;
		end
	end
	if IconFrames[unit] then IconFrames[unit]:Hide(); end
end

local function UpdateZoneInfo()
	local localizedZoneList = {
		"Winterspring", "Berceau-de-l'Hiver", "Winterquell",
		"Cuna del Invierno",
	};
	duelZone = string.match(GetRealmName(), "Blackrock") and tContains(localizedZoneList, GetZoneText());
end

-- ══════════════════════════════════════════════════════════════
-- VISIBILITY
-- ══════════════════════════════════════════════════════════════

local function RefreshAllVisibility()
	if GetSetting("showOnTargetFocus") then
		UpdateOnChange("target");
		UpdateOnChange("focus");
	else
		if IconFrames["target"] then IconFrames["target"]:Hide(); end
		if IconFrames["focus"] then IconFrames["focus"]:Hide(); end
	end

	for i = 1, MAX_ARENA_ENEMIES do
		local unit = "arena" .. i;
		if GetSetting("showOnArena") then
			PositionArenaIcon(i); -- re-position handles flat check
			UpdateOnChange(unit);
		else
			if IconFrames[unit] then IconFrames[unit]:Hide(); end
		end
	end
end

-- ══════════════════════════════════════════════════════════════
-- ENSURE FRAMES
-- ══════════════════════════════════════════════════════════════

local function EnsureUnitFrames()
	for _, data in ipairs({ {TargetFrame, "target"}, {FocusFrame, "focus"} }) do
		local parent, unit = data[1], data[2];
		if parent and not IconFrames[unit] then
			IconFrames[unit] = CreateIconFrame(parent, unit, ICON_SIZE_UNIT);
			IconFrames[unit]._origSize = ICON_SIZE_UNIT;
			PositionUnitIcon(unit);
		end
	end
end

local function EnsureArenaFrames()
	for i = 1, MAX_ARENA_ENEMIES do
		local unit = "arena" .. i;
		local parent = _G["ArenaEnemyFrame" .. i];
		if parent and not IconFrames[unit] then
			IconFrames[unit] = CreateIconFrame(parent, unit, ICON_SIZE_ARENA);
			IconFrames[unit]._origSize = ICON_SIZE_ARENA;
			PositionArenaIcon(i);
		end
		if IconFrames[unit] then IconFrames[unit]:Hide(); end
	end
end

-- ══════════════════════════════════════════════════════════════
-- EVENT HANDLER
-- ══════════════════════════════════════════════════════════════

local eventFrame = CreateFrame("Frame");

local function OnEvent(self, event, ...)
	if not moduleActive then return; end

	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, eventType, srcGUID, _, srcFlags, _, _, _, spellId = ...;

		if (instanceType == "pvp" or instanceType == "arena") and specDB[srcGUID] then return; end

		local isHostile = band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0;
		if (not duelZone and instanceType ~= "arena") and not isHostile then return; end

		local isPlayer = band(srcFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0;
		if not isPlayer then return; end

		if eventType == "SPELL_CAST_START" or eventType == "SPELL_CAST_SUCCESS" or
		   eventType == "SPELL_CAST_FAILED" or eventType == "SPELL_AURA_APPLIED" or
		   eventType == "SPELL_AURA_REFRESH" or eventType == "SPELL_AURA_REMOVED" then

			-- FIX PERF: O(1) reverse lookup instead of O(specs × spells) linear scan
			local match = reverseLookup[spellId];
			if not match then return; end

			local _, class = GetPlayerInfoByGUID(srcGUID);
			if not class or class ~= match.class then return; end

			specDB[srcGUID] = match.spec;

			-- FIX PERF: Reuse table instead of creating new one per event
			wipe(reusableUnits);
			reusableUnits[1] = "target";
			reusableUnits[2] = "focus";
			local n = 2;
			if instanceType == "arena" then
				for a = 1, GetNumArenaOpponents() do
					n = n + 1;
					reusableUnits[n] = "arena" .. a;
				end
			end
			for u = 1, n do
				if UnitGUID(reusableUnits[u]) == srcGUID then
					ShowSpecIcon(reusableUnits[u], class, match.spec);
				end
			end
			return;
		end

	elseif event == "PLAYER_TARGET_CHANGED" then
		UpdateOnChange("target");

	elseif event == "PLAYER_FOCUS_CHANGED" then
		UpdateOnChange("focus");

	elseif event == "PLAYER_ENTERING_WORLD" then
		instanceType = select(2, IsInInstance());
		if instanceType == "pvp" or instanceType == "arena" then wipe(specDB); end
		if instanceType == "arena" then EnsureArenaFrames(); end
		UpdateZoneInfo();
		UpdateOnChange("target");
		UpdateOnChange("focus");

	elseif event == "ZONE_CHANGED_NEW_AREA" then
		UpdateZoneInfo();

	elseif event == "ARENA_OPPONENT_UPDATE" then
		for i = 1, MAX_ARENA_ENEMIES do
			UpdateOnChange("arena" .. i);
		end
	end
end

-- ══════════════════════════════════════════════════════════════
-- createUI: Checkboxes in Modules tab
-- ══════════════════════════════════════════════════════════════

local function SpecIcons_CreateUI(parent, yOffset, mainCheck)
	local cbCount = 0;

	local function MakeCB(labelText, settingKey, xOff, yOff)
		cbCount = cbCount + 1;
		local cbName = "NUF_SpecIconsCB" .. cbCount;
		local cb = CreateFrame("CheckButton", cbName, parent, "UICheckButtonTemplate");
		cb:SetPoint("TOPLEFT", xOff, yOff);
		cb:SetHitRectInsets(0, 0, 0, 0);
		local lbl = _G[cbName .. "Text"];
		if lbl then lbl:SetText(labelText); end
		cb:SetChecked(GetSetting(settingKey));
		cb:SetScript("OnClick", function(self)
			local checked = (self:GetChecked() == 1 or self:GetChecked() == true);
			SetSetting(settingKey, checked);
			RefreshAllVisibility();
		end);
		return cb;
	end

	local y = yOffset - 4;
	MakeCB("Show on Target & Focus", "showOnTargetFocus", 36, y);
	y = y - 24;
	MakeCB("Show on Arena Enemies", "showOnArena", 36, y);
	y = y - 24;
	MakeCB("Show in Flat Mode", "showInFlatMode", 36, y);

	-- Separator + info text
	y = y - 28;
	local sep = parent:CreateTexture(nil, "ARTWORK");
	sep:SetTexture(1, 1, 1, 0.12);
	sep:SetPoint("TOPLEFT", 36, y);
	sep:SetSize(280, 1);

	y = y - 14;
	local hint = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	hint:SetPoint("TOPLEFT", 38, y);
	hint:SetText("|cffAAAAAARound icon on Blizzard/Custom, rectangular on Flat style.|r");
	hint:SetWidth(280);
	hint:SetJustifyH("LEFT");

	-- Return height > 100 so OptionsPanel.lua creates a [+]/[-] collapse button
	return 110;
end

-- ══════════════════════════════════════════════════════════════
-- ENABLE / DISABLE
-- ══════════════════════════════════════════════════════════════

local function Enable()
	metaDB  = ns.SpecMetaDB;
	spellDB = ns.SpecSpellDB;
	if not metaDB or not spellDB then
		print("|cffFF0000NUF:|r SpecIcons: SpecDB not loaded!");
		return;
	end

	-- FIX PERF: Build reverse lookup table (spellID → {class, spec})
	-- ~600 spells → ~15KB memory, but turns O(60) scan into O(1) per event
	wipe(reverseLookup);
	for class, specs in pairs(spellDB) do
		for spec, spells in pairs(specs) do
			for _, id in ipairs(spells) do
				reverseLookup[id] = { class = class, spec = spec };
			end
		end
	end

	moduleActive = true;
	EnsureUnitFrames();

	eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
	eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED");
	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE");
	eventFrame:SetScript("OnEvent", OnEvent);

	local _, iType = IsInInstance();
	if iType == "arena" then
		instanceType = "arena";
		EnsureArenaFrames();
	end
end

local function Disable()
	moduleActive = false;
	eventFrame:UnregisterAllEvents();
	eventFrame:SetScript("OnEvent", nil);
	for _, f in pairs(IconFrames) do f:Hide(); end
	wipe(reverseLookup);
end

-- ══════════════════════════════════════════════════════════════
-- REPOSITION ON STYLE CHANGE
-- ══════════════════════════════════════════════════════════════

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if moduleActive then K.RepositionAllSpecIcons(); end
end);

-- ══════════════════════════════════════════════════════════════
-- REGISTER MODULE
-- ══════════════════════════════════════════════════════════════

K.RegisterModule("SpecIcons", {
	name      = "Spec Icons",
	desc      = "Detects enemy spec via combat log. Shows spec icon on Target, Focus and Arena frames.",
	default   = true,
	onEnable  = Enable,
	onDisable = Disable,
	createUI  = SpecIcons_CreateUI,
});