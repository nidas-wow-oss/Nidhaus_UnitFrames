local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local unlocked = false;
local overlays = {};

local PET_CLASSES = {
	HUNTER      = true,
	WARLOCK     = true,
	DEATHKNIGHT = true,
	MAGE        = true,
	PRIEST      = true,
	SHAMAN      = true,
};

local MOVABLES = {

	{ key = "Player",  group = "frames", frames = {"NidhausPlayerFrame", "PlayerFrame"}, label = "Player", scalable = true },
	{ key = "Target",  group = "frames", frames = {"TargetFrame"},  label = "Target", scalable = true },

	{ key = "Pet",     group = "frames", frames = {"PetFrame"},     label = "Pet",    scalable = true, managed = "PetFrame",
	  class = PET_CLASSES, orIfPet = true,
	  overlaySize = {120, 40} },

	{ key = "Party1", group = "frames", frames = {"PartyMemberFrame1"}, label = "Party 1", partyIndex = 1 },
	{ key = "Party2", group = "frames", frames = {"PartyMemberFrame2"}, label = "Party 2", partyIndex = 2 },
	{ key = "Party3", group = "frames", frames = {"PartyMemberFrame3"}, label = "Party 3", partyIndex = 3 },
	{ key = "Party4", group = "frames", frames = {"PartyMemberFrame4"}, label = "Party 4", partyIndex = 4 },

	{ key = "Buffs",      group = "extra", frames = {"NUF_BuffAnchor"},   label = "Buffs",   scalable = true, auraAnchor = true,
	  buttons = { prefix = "BuffButton", count = BUFF_MAX_DISPLAY or 32 },
	  overlayOffset = { 20, 0 } },
	{ key = "Debuffs",    group = "extra", frames = {"NUF_DebuffAnchor"}, label = "Debuffs", scalable = true, debuffAnchor = true,
	  buttons = { prefix = "DebuffButton", count = DEBUFF_MAX_DISPLAY or 16 },
	  overlayOffset = { 20, 0 } },

	{ key = "CastBar",    group = "extra", frames = {"CastingBarFrame"},       label = "Cast Bar", scalable = true, managed = "CastingBarFrame",
	  overlayPad = { 4, 5 } },

	{ key = "MainBar",    group = "extra", frames = {"MainMenuBar"},           label = "Action Bar 1", scalable = true, protected = true, managed = "MainMenuBar",
	  framesMiniBar = {"NUF_ActionBarHolder1"}, noClamp = true,
	  overlayOn = "NUF_ActionBar1Box" },

	{ key = "ActionBar2", group = "extra", frames = {"MultiBarBottomLeft"},   label = "Action Bar 2",
	  scalable = true, onlyIfVisible = true, setting = "MiniBarEnabled",
	  framesMiniBar = {"NUF_ActionBarHolder2"}, noClamp = true },
	{ key = "ActionBar3", group = "extra", frames = {"MultiBarBottomRight"},  label = "Action Bar 3",
	  scalable = true, onlyIfVisible = true, setting = "MiniBarEnabled",
	  framesMiniBar = {"NUF_ActionBarHolder3"}, noClamp = true },

	{ key = "PetBar",     group = "extra", frames = {"PetActionBarFrame"},     label = "Pet Bar",
	  class = PET_CLASSES, orIfPet = true,
	  framesMiniBar = {"PetActionButton1"},
	  scalable = true, protected = true, anchorTo = "MainMenuBar", managed = "PetActionBarFrame", onlyIfVisible = true,
	  buttons = { prefix = "PetActionButton", count = NUM_PET_ACTION_SLOTS or 10 } },

	{ key = "StanceBar",  group = "extra", frames = {"NUF_StanceBarHolder"},  label = "Stance Bar",
	  scalable = true, anchorTo = "MainMenuBar", onlyIfVisible = true,
	  resetFunc = "ResetStanceHolder",
	  buttons = { prefix = "ShapeshiftButton", count = NUM_SHAPESHIFT_SLOTS or 10 } },
	{ key = "TotemBar",   group = "extra", frames = {"MultiCastActionBarFrame"}, label = "Totem Bar",
	  scalable = true, protected = true, anchorTo = "MainMenuBar", managed = "MultiCastActionBarFrame", onlyIfVisible = true,
	  buttons = { prefix = "MultiCastActionButton", count = 12 },
	  class = "SHAMAN" },
	{ key = "PossessBar", group = "extra", frames = {"PossessBarFrame"},       label = "Possess Bar",
	  framesMiniBar = {"PossessButton1"},
	  scalable = true, protected = true, anchorTo = "MainMenuBar", managed = "PossessBarFrame", onlyIfVisible = true,
	  buttons = { prefix = "PossessButton", count = NUM_POSSESS_SLOTS or 2 } },
	{ key = "AutoShot",   group = "extra", frames = {"NUF_AutoShotMover"},     label = "Auto Shot", scalable = true,
	  module = "AutoShotTimer", class = "HUNTER" },
	{ key = "SwingTimer", group = "extra", frames = {"NUF_SwingMover"},        label = "Auto attack", scalable = true,
	  module = "MeleeSwingTimer" },

	{ key = "PartyPets",  group = "extra", frames = {"CustomParty1PetFrame"},  label = "Party pets", scalable = true,
	  protected = true, preview = "SetPartyPetPreview", module = "PartyPetFrame" },
	{ key = "PaladinICD", group = "extra", frames = {"PaladinICDFrame"},       label = "Paladin ICD", scalable = true,
	  preview = "SetPaladinICDPreview", module = "PaladinICD", class = "PALADIN" },
	{ key = "PalAuras",   group = "extra", frames = {"NUF_PaladinAuras"},      label = "Paladin tracker", scalable = true,
	  preview = "SetPaladinAurasPreview", module = "PaladinAuras", class = "PALADIN" },
	{ key = "TurnEvil",   group = "extra", frames = {"NUF_TurnEvilStack"},     label = "Turn Evil", scalable = true,
	  preview = "SetTurnEvilPreview", module = "TurnEvil", class = "PALADIN" },

	{ key = "SacredShield", group = "extra", frames = {"NUF_SacredShieldFrame"},   label = "Sacred Shield", scalable = true,
	  preview = "SetSacredShieldMove", module = "SacredShield", class = "PALADIN" },
	{ key = "SSTracker",    group = "extra", frames = {"NUF_SacredShieldTracker"}, label = "Sacred Shield tracker", scalable = true,
	  preview = "SetSacredShieldTrackerMove", module = "SacredShieldTracker", class = "PALADIN" },
	{ key = "Seduction",    group = "extra", frames = {"NUF_SeductionAlert"},      label = "Seduction alert", scalable = true,
	  preview = "SetSeductionAlertMove", module = "SeductionAlert" },

	{ key = "Gargoyle",   group = "extra", frames = {"GT_Blizzard", "GT_Custom"}, label = "Gargoyle",

	  preview = "SetGargoylePreview", module = "GargoyleTracker", noOverlay = true },

	{ key = "EnemyAlert", group = "extra", frames = {"NUF_EnemyAlertAnchor"},  label = "Spell Alert",
	  preview = "SetEnemyAlertPreview", module = "EnemySpellAlert", noOverlay = true },
	{ key = "ArrowCount", group = "extra", frames = {"NUF_ArrowCountFrame"},   label = "Ammo",      scalable = true,
	  module = "ArrowCount", class = "HUNTER" },
	{ key = "DungeonRoles", group = "extra", frames = {"NUF_DungeonRoles"},   label = "Dungeon roles", scalable = true,
	  module = "DungeonRoles", preview = "SetDungeonRolesPreview" },

	{ key = "PartyCast", group = "frames", frames = {"PartyMemberFrame1CastingBarFrame"},
	  label = "Party Cast Bar", setting = "PCB_Enabled",
	  preview = "SetPartyCastBarPreview", partyCast = true,

	  overlayPad = { 6, 6 } },

	{ key = "PartyTarget", group = "frames", frames = {"PartyTargetFrame1"},
	  label = "Party Target", setting = "PartyTargetsEnabled",
	  preview = "SetPartyTargetPreview", partyTarget = true },

	{ key = "Minimap",  group = "extra", frames = {"MinimapCluster"},
	  label = "Minimap", managed = "MinimapCluster", overlayOn = "Minimap" },

	{ key = "BGScore",  group = "extra", frames = {"WorldStateAlwaysUpFrame"},
	  label = "BG score", overlaySize = { 200, 60 }, overlayAnchor = "TOP" },

	{ key = "CaptureBar", group = "extra", frames = {"WorldStateCaptureBar1"},
	  label = "Capture bar", overlaySize = { 180, 40 } },

	{ key = "DalaranPipe", group = "extra", frames = {"NUF_DalaranPipeTimer"},
	  label = "Dalaran waterfall", scalable = true,
	  setting = "ArenaDalaranPipeTimer", preview = "SetArenaTimersPreview" },
	{ key = "RoVPillars",  group = "extra", frames = {"NUF_RoVPillarTimer"},
	  label = "RoV pillars", scalable = true,
	  setting = "ArenaRoVPillarTimer", preview = "SetArenaTimersPreview" },
	{ key = "ArenaEnd",    group = "extra", frames = {"NUF_ArenaEndTimer"},
	  label = "Arena time", scalable = true,
	  setting = "ArenaEndTimer", preview = "SetArenaTimersPreview" },

	{ key = "ShadowSight", group = "extra", frames = {"NUF_ShadowSightTimer"},
	  label = "Shadow Sight", scalable = true,
	  setting = "ShadowSightTimer", preview = "SetArenaTimersPreview" },

	{ key = "WaterEle",  group = "extra", frames = {"NUF_ClassTimer_WaterElemental"},
	  label = "Water Elemental", setting = "MageWaterEleTimer",
	  preview = "SetClassTimersPreview", class = "MAGE" },
	{ key = "MirrorImg", group = "extra", frames = {"NUF_ClassTimer_MirrorImage"},
	  label = "Mirror Image", setting = "MageMirrorTimer",
	  preview = "SetClassTimersPreview", class = "MAGE" },
};

for _, entry in ipairs(MOVABLES) do
	local t = L["MOVER_LBL_" .. entry.key];
	if t then entry.label = t; end
end

do
	local _, class = UnitClass("player");
	local byClass = {
		PALADIN     = L["MOVE_AURA_BAR"]     or "Aura Bar",
		DEATHKNIGHT = L["MOVE_PRESENCE_BAR"] or "Presence Bar",
		DRUID       = L["MOVE_FORM_BAR"]     or "Form Bar",
		WARRIOR     = L["MOVE_STANCE_BAR"]   or "Stance Bar",
	};
	local name = byClass[class or ""];
	if name then
		for _, entry in ipairs(MOVABLES) do
			if entry.key == "StanceBar" then entry.label = name; break; end
		end
	end
end

local currentScope = "all";

local playerClass;

local function PlayerClass()
	if not playerClass then
		playerClass = select(2, UnitClass("player"));
	end
	return playerClass;
end

local function EntryModuleActive(entry)

	local cls = PlayerClass();
	if entry.class and cls then
		if type(entry.class) == "table" then

			if not entry.class[cls] then

				if not (entry.orIfPet and UnitExists and UnitExists("pet")) then
					return false;
				end
			end
		elseif entry.class ~= cls then
			return false;
		end
	end

	if entry.setting then
		return (C and C[entry.setting]) and true or false;
	end
	if not entry.module then return true; end
	if not K.IsModuleEnabled then return true; end
	return K.IsModuleEnabled(entry.module) and true or false;
end

local EntryHasContent;

local function ScopeMatches(entry)
	if currentScope == "all" then return true; end
	if currentScope == "pet" then return entry.key == "Pet"; end
	return entry.group == currentScope;
end

local function EntryInScope(entry)
	if not EntryModuleActive(entry) then return false; end
	if not EntryHasContent(entry) then return false; end
	return ScopeMatches(entry);
end

local function ResolveFrame(entry)

	if entry.framesMiniBar and C.MiniBarEnabled == true then
		for _, name in ipairs(entry.framesMiniBar) do
			local f = _G[name];
			if f and f.SetPoint then return f; end
		end
	end

	for _, name in ipairs(entry.frames) do
		local f = _G[name];
		if f and f.SetPoint then return f; end
	end

	if entry.key == "Party"  and K.NidhausPartyFrame then return K.NidhausPartyFrame; end
	return nil;
end

function EntryHasContent(entry)
	if not entry.onlyIfVisible then return true; end

	local f = ResolveFrame(entry);
	if not f then return false; end

	if entry.key == "StanceBar" then
		local n = (GetNumShapeshiftForms and GetNumShapeshiftForms()) or 0;
		if n < 1 then return false; end

		if C.UnifyActionBars ~= true and C.MiniBarEnabled ~= true then
			return false;
		end
		return true;
	elseif entry.key == "PetBar" then
		if not (UnitExists("pet") or (PetHasActionBar and PetHasActionBar())) then
			return false;
		end
	end

	return f:IsVisible() and true or false;
end

local originals = {};
local capturedOnce = false;

local function CaptureOriginals()
	if capturedOnce then return; end
	capturedOnce = true;

	for _, entry in ipairs(MOVABLES) do
		local f = ResolveFrame(entry);
		if f and not originals[entry.key] then
			local pts = {};
			for i = 1, (f:GetNumPoints() or 0) do

				local p, rel, rp, x, y = f:GetPoint(i);
				pts[i] = { point = p, rel = rel, relPoint = rp, x = x, y = y };
			end
			originals[entry.key] = {
				frame  = f,
				points = pts,
				scale  = f:GetScale() or 1,
			};
		end
	end
end
K.CaptureMovableOriginals = CaptureOriginals;

local function RestoreOriginal(entry)
	local orig = originals[entry.key];
	local f = ResolveFrame(entry);
	if not f or not orig then return; end
	if entry.protected and InCombatLockdown() then return; end

	if orig.frame and orig.frame ~= f then
		if K.RestoreBarBaselineFrame and f.GetName and f:GetName() then
			f._nufApplying = true;
			pcall(K.RestoreBarBaselineFrame, f:GetName());
			f._nufApplying = nil;
		end
		return;
	end

	f._nufApplying = true;
	pcall(f.SetScale, f, orig.scale or 1);
	if orig.points and #orig.points > 0 then
		f:ClearAllPoints();
		for _, pt in ipairs(orig.points) do
			pcall(f.SetPoint, f, pt.point, pt.rel or f:GetParent(),
				pt.relPoint or pt.point, pt.x or 0, pt.y or 0);
		end
	end
	f._nufApplying = nil;
end

if type(K.FramePositionOwners) ~= "table" then K.FramePositionOwners = {}; end

local OwnsItsPosition;

local function SaveToOwner(entry, frame)
	if not (entry and frame) then return false; end
	local fn = K.FramePositionOwners[entry.key];
	if type(fn) == "function" then
		local ok = pcall(fn, frame);
		if ok then return true; end
	end
	local drop = frame.GetScript and frame:GetScript("OnDragStop");
	if type(drop) == "function" then
		local ok = pcall(drop, frame);
		if ok then return true; end
	end
	return false;
end

local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.globalPos then NidhausUnitFramesDB.globalPos = {}; end
	return NidhausUnitFramesDB.globalPos;
end

local function BarMode()
	if C.MiniBarEnabled  == true then return "mini";  end
	if C.UnifyActionBars == true then return "unify"; end
	return "plain";
end

local STACK_KEYS = {
	MainBar = true, ActionBar2 = true, ActionBar3 = true,
	StanceBar = true, TotemBar = true, PetBar = true, PossessBar = true,
};

local PER_MODE_KEYS = STACK_KEYS;

local function EntryKey(entry)
	local k = (type(entry) == "table") and entry.key or entry;
	if PER_MODE_KEYS[k] then return k .. "#" .. BarMode(); end
	return k;
end

local function MigrateBareKeys()
	local db = DB();
	for key in pairs(PER_MODE_KEYS) do
		local old = db[key];
		if type(old) == "table" then
			for _, m in ipairs({ "mini", "unify", "plain" }) do
				local mk = key .. "#" .. m;
				if db[mk] == nil then
					local copy = {};
					for f, v in pairs(old) do copy[f] = v; end
					db[mk] = copy;
				end
			end
			db[key] = nil;
		end
	end
end
K.MigrateBarModeKeys = MigrateBareKeys;

K.BarModeKey = EntryKey;

local function ReleaseManaged(entry, frame)
	if not entry.managed then return; end

	local target = _G[entry.managed];
	if target then target.ignoreFramePositionManager = true; end

	frame = frame or ResolveFrame(entry);
	if frame and frame ~= target then
		frame.ignoreFramePositionManager = true;
	end
end

local function ReclaimManaged(entry)
	if not entry.managed then return; end

	local function Give(frame)
		if not frame then return; end
		frame.ignoreFramePositionManager = nil;
		frame.MAPoint = nil;
		if frame.SetUserPlaced and not frame:IsProtected() then
			pcall(frame.SetUserPlaced, frame, false);
		end
	end

	local target = _G[entry.managed];
	Give(target);

	local frame = ResolveFrame(entry);
	if frame and frame ~= target then Give(frame); end
end

local function DetachPartyChain()
	if InCombatLockdown() then return; end
	local uiScale = UIParent:GetEffectiveScale();
	local uiH = UIParent:GetHeight();
	for i = 1, (MAX_PARTY_MEMBERS or 4) do
		local pf = _G["PartyMemberFrame" .. i];
		if pf and not pf:IsProtected() then
			local scale = pf:GetEffectiveScale();
			local left, top = pf:GetLeft(), pf:GetTop();
			if left and top then

				local sx, sy = left * scale, top * scale;
				pf:SetParent(UIParent);
				local ns = pf:GetEffectiveScale() or uiScale;
				if not ns or ns == 0 then ns = uiScale; end
				pf:ClearAllPoints();
				pf:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
					sx / ns, (sy - uiH * uiScale) / ns);
			end
		end
	end
end

local function PinSiblingBars(movedKey)

	local db = DB();

	for _, entry in ipairs(MOVABLES) do
		if STACK_KEYS[entry.key] and entry.key ~= movedKey then
			local dk = EntryKey(entry);
			local f  = ResolveFrame(entry);
			if f and f:IsShown() and f:GetLeft() and not (db[dk] and db[dk].point) then
				db[dk] = db[dk] or {};
				db[dk].point         = "BOTTOMLEFT";
				db[dk].relativePoint = "BOTTOMLEFT";
				db[dk].x             = f:GetLeft();
				db[dk].y             = f:GetBottom();
				db[dk].rel           = nil;
			end
		end
	end
end

local function SavePartyMemberPosition(entry, frame)
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end

	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1);
	if not point then return; end
	local relName = "UIParent";
	if relativeTo and relativeTo.GetName then relName = relativeTo:GetName() or "UIParent"; end

	NidhausUnitFramesDB.positions["PartyMemberFrame" .. entry.partyIndex] = {
		point = point, relativeTo = relName, relativePoint = relativePoint, x = x, y = y,
		scale = frame:GetScale(),
	};

	if not C.PartyIndividualMove then
		C.PartyIndividualMove = true;
		if K.SaveConfig then K.SaveConfig("PartyIndividualMove", true); end
	end
end

local function SavePosition(entry, frame)
	if entry.partyIndex then
		SavePartyMemberPosition(entry, frame);
		return;
	end
	local db = DB();
	db[EntryKey(entry)] = db[EntryKey(entry)] or {};

	if entry.anchorTo and C.MiniBarEnabled ~= true then
		local parent = _G[entry.anchorTo];
		if parent and parent:GetLeft() and frame:GetLeft() then

			local fs = frame:GetEffectiveScale()  or 1;
			local ps = parent:GetEffectiveScale() or 1;
			if fs == 0 then fs = 1; end

			db[EntryKey(entry)].point         = "BOTTOMLEFT";
			db[EntryKey(entry)].relativePoint = "BOTTOMLEFT";
			db[EntryKey(entry)].x             = (frame:GetLeft()   * fs - parent:GetLeft()   * ps) / fs;
			db[EntryKey(entry)].y             = (frame:GetBottom() * fs - parent:GetBottom() * ps) / fs;
			db[EntryKey(entry)].rel           = entry.anchorTo;

			frame:ClearAllPoints();
			frame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT",
				db[EntryKey(entry)].x, db[EntryKey(entry)].y);
			ReleaseManaged(entry, frame);
			return;
		end
	end

	local point, relTo, relativePoint, x, y = frame:GetPoint();
	if not point then return; end

	if relTo and relTo ~= UIParent and frame:GetLeft() and frame:GetBottom() then
		point, relativePoint = "BOTTOMLEFT", "BOTTOMLEFT";
		x, y = frame:GetLeft(), frame:GetBottom();
		frame._nufApplying = true;
		frame:ClearAllPoints();
		frame:SetPoint(point, UIParent, relativePoint, x, y);
		frame._nufApplying = nil;
	end

	db[EntryKey(entry)].point         = point;
	db[EntryKey(entry)].relativePoint = relativePoint;
	db[EntryKey(entry)].x             = x;
	db[EntryKey(entry)].y             = y;
	db[EntryKey(entry)].rel           = nil;
	ReleaseManaged(entry, frame);

	if entry.auraAnchor then
		if K.SaveAuraAnchorPosition then K.SaveAuraAnchorPosition(); end
		if K.ReanchorAuras then K.ReanchorAuras(); end
	elseif entry.debuffAnchor then
		if K.SaveDebuffAnchorPosition then K.SaveDebuffAnchorPosition(); end
		if K.ReanchorDebuffs then K.ReanchorDebuffs(); end
	end

	if C.MiniBarEnabled == true and STACK_KEYS[entry.key] then
		PinSiblingBars(entry.key);
	end
end

local function SaveScale(entry, scale)
	local db = DB();
	db[EntryKey(entry)] = db[EntryKey(entry)] or {};
	db[EntryKey(entry)].scale = scale;
	if entry.auraAnchor and K.SaveAuraAnchorScale then
		K.SaveAuraAnchorScale(scale);
	elseif entry.debuffAnchor and K.SaveDebuffAnchorScale then
		K.SaveDebuffAnchorScale(scale);
	end
end

local function ClearSavedScale(entry)
	local db = DB();
	local k = EntryKey(entry);
	local p = db[k];
	if p and p.scale then
		p.scale = nil;
		if not p.point then db[k] = nil; end
	end
end

local MODULE_SCALE_ID = {
	Buffs        = "PlayerBuffs",
	Debuffs      = "PlayerDebuffs",
	DalaranPipe  = "ArenaDalaranPipeTimer",
	RoVPillars   = "ArenaRoVPillarTimer",
	ArenaEnd     = "ArenaEndTimer",
	ShadowSight  = "ShadowSightTimer",
	PalAuras     = "PaladinAuras",
	TurnEvil     = "TurnEvil",
	SacredShield = "SacredShield",
	SSTracker    = "SacredShieldTracker",
	PaladinICD   = "PaladinICD",
	Seduction    = "SeductionAlert",
	PartyPets    = "PartyPetFrame",
};

local OWN_SCALE = {
	AutoShot   = { get = "GetAutoShotScale",   set = "SaveAutoShotScale",
	               refresh = "RefreshAutoShotScaleSlider", default = 1.0 },
	SwingTimer = { get = "GetMeleeSwingScale", set = "SaveMeleeSwingScale",
	               refresh = "RefreshSwingScaleSlider",    default = 1.0 },
	ArrowCount = { get = "GetArrowCountScale", set = "SaveArrowCountScale",
	               default = 1.0 },
};

local function ScaleOwner(entry)
	local key = (type(entry) == "table") and entry.key or entry;
	local id = MODULE_SCALE_ID[key];
	if id and K.IsScalable and K.IsScalable(id) then
		return {
			get   = function() return K.GetModuleScale(id); end,
			set   = function(v) K.SetModuleScale(id, v); end,
			reset = function() K.ResetModuleScale(id); end,
		};
	end
	local o = OWN_SCALE[key];
	if o and type(K[o.set]) == "function" then
		local function refresh()
			local fn = o.refresh and K[o.refresh];
			if type(fn) == "function" then pcall(fn); end
		end
		return {

			get   = function()
				local g = o.get and K[o.get];
				if type(g) == "function" then
					local ok, v = pcall(g);
					if ok and type(v) == "number" and v > 0 then return v; end
				end
				return o.default or 1.0;
			end,
			set   = function(v) K[o.set](v); refresh(); end,
			reset = function() K[o.set](o.default); refresh(); end,
		};
	end
end

local function MainBarIsMaster(entry)
	local key = (type(entry) == "table") and entry.key or entry;
	return key == "MainBar" and C.MiniBarEnabled ~= true;
end

local function CurrentScale(entry, frame)
	local owner = ScaleOwner(entry);
	if owner and owner.get then
		local ok, v = pcall(owner.get);
		if ok and type(v) == "number" and v > 0 then return v; end
	end

	if MainBarIsMaster(entry) then
		local v = tonumber(C and C.ActionBarScale);
		if v and v > 0 then return v; end
	end

	local saved = K.GetGlobalScale and K.GetGlobalScale(entry);
	if type(saved) == "number" and saved > 0 then return saved; end

	return (frame and frame.GetScale and frame:GetScale()) or 1;
end
K.GetMovableScale = CurrentScale;

local function SetOverlayLabel(ov, entry, frame)
	entry = entry or ov.entry;
	frame = frame or ov.target;
	if not (ov and ov.text and entry) then return; end
	if entry.scalable then
		ov.text:SetText(entry.label .. "  " ..
			string.format("%.2f", CurrentScale(entry, frame)));
	else
		ov.text:SetText(entry.label);
	end
end

local function RefreshOverlays()
	for _, ov in ipairs(overlays) do

		if ov:IsShown() and ov.target and not ov.drag then
			SetOverlayLabel(ov);
			if ov.AnchorOverlay then pcall(ov.AnchorOverlay, ov); end
		end
	end
end

local overlayRefresher = CreateFrame("Frame");
overlayRefresher:Hide();
overlayRefresher:SetScript("OnUpdate", function(self)
	self:Hide();
	RefreshOverlays();
end);

local function RequestOverlayRefresh()

	overlayRefresher:Show();
end
K.RequestMoverRefresh = RequestOverlayRefresh;

local scaleHooked = {};
local function HookScaleSetter(name)
	if scaleHooked[name] or type(K[name]) ~= "function" then return; end
	scaleHooked[name] = true;
	hooksecurefunc(K, name, RequestOverlayRefresh);
end

local SCALE_SETTERS = {
	"ApplyActionBarScale",
	"ApplyCastBarPWScale",
	"ApplyPetFrameScale",
	"ApplyPartyFrameScale",
	"ApplyMinimapScale",
	"SetClassTimersScale",
	"SavePowerBarScale",
};
local function InstallScaleHooks()
	for _, name in ipairs(SCALE_SETTERS) do HookScaleSetter(name); end
	for _, o in pairs(OWN_SCALE) do HookScaleSetter(o.set); end
end

local SLIDER_RANGE = {
	Player  = { 0.5, 1.5 },
	Target  = { 0.5, 1.5 },
	Pet     = { 0.5, 1.5 },
	CastBar = { 0.5, 2.0 },
};
local MAINBAR_RANGE = { 0.65, 1.14 };

function K.ClearBarOwnScales()

	for _, k in ipairs({ "MainBar", "ActionBar2", "ActionBar3", "StanceBar" }) do
		ClearSavedScale(k);
	end
end

local BY_KEY = {};
for _, entry in ipairs(MOVABLES) do BY_KEY[entry.key] = entry; end

function K.SetGlobalFrameScale(key, scale)
	if type(scale) ~= "number" then return false; end
	local entry = BY_KEY[key];
	if not entry then return false; end
	if entry.protected and InCombatLockdown() then return false; end

	local f = ResolveFrame(entry);
	if f then pcall(f.SetScale, f, scale); end
	SaveScale(entry, scale);

	if K.SyncExtraBarScale then pcall(K.SyncExtraBarScale); end

	RequestOverlayRefresh();
	return true;
end

local function ApplyPoint(frame, entry, pos)

	local anchorFrame = (pos.rel and _G[pos.rel]) or UIParent;
	frame._nufApplying = true;
	frame:SetClampedToScreen(entry.noClamp ~= true);
	frame:ClearAllPoints();
	frame:SetPoint(pos.point, anchorFrame, pos.relativePoint, pos.x, pos.y);
	frame._nufApplying = nil;
end

local function OnLockedSetPoint(frame)
	if not frame.NUFPoint then return; end
	if frame._nufApplying then return; end
	if unlocked then return; end
	if frame:IsProtected() and InCombatLockdown() then return; end

	local p = frame.NUFPoint;
	frame._nufApplying = true;
	frame:ClearAllPoints();
	frame:SetPoint(unpack(p));
	frame._nufApplying = nil;
end

local function ScaleKeepingCenter(frame, newScale)
	local ok, cx, cy = pcall(frame.GetCenter, frame);
	local before = (ok and cx) and { cx * (frame:GetEffectiveScale() or 1),
	                                 cy * (frame:GetEffectiveScale() or 1) } or nil;

	pcall(frame.SetScale, frame, newScale);
	if not before then return; end

	local p, rel, rp, x, y = frame:GetPoint();
	if not p then return; end

	local es = frame:GetEffectiveScale() or 1;
	if es == 0 then return; end
	local ok2, ncx, ncy = pcall(frame.GetCenter, frame);
	if not (ok2 and ncx) then return; end

	local dx = (before[1] - ncx * es) / es;
	local dy = (before[2] - ncy * es) / es;
	if dx == 0 and dy == 0 then return; end

	frame:ClearAllPoints();
	frame:SetPoint(p, rel or UIParent, rp, (x or 0) + dx, (y or 0) + dy);
end

local function LockFramePoint(frame, entry, pos)
	if not frame.NUFPointHook then
		hooksecurefunc(frame, "SetPoint", OnLockedSetPoint);
		frame.NUFPointHook = true;
	end

	local anchorFrame = (pos.rel and _G[pos.rel]) or UIParent;
	frame.NUFPoint = { pos.point, anchorFrame, pos.relativePoint, pos.x, pos.y };
end

local function UnlockFramePoint(frame)
	if frame then frame.NUFPoint = nil; end
end

local function UnlockEntryFrames(entry)
	if type(entry) ~= "table" then return; end
	for _, list in ipairs({ entry.frames, entry.framesMiniBar }) do
		if type(list) == "table" then
			for _, name in ipairs(list) do
				local f = _G[name];
				if f then UnlockFramePoint(f); end
			end
		end
	end
end

local function CenteredScaleAndSave(entry, frame, newScale)

	frame._nufApplying = true;
	ScaleKeepingCenter(frame, newScale);
	frame._nufApplying = nil;
	SaveScale(entry, newScale);

	if OwnsItsPosition and OwnsItsPosition(entry.key) then

		SaveToOwner(entry, frame);
	else
		SavePosition(entry, frame);

		if not unlocked and frame.NUFPoint then
			local saved = DB()[EntryKey(entry)];
			if saved and saved.point then LockFramePoint(frame, entry, saved); end
		end
	end
end

function K.SaveMovablePosition(key)
	local entry = BY_KEY[key];
	if not entry then return false; end
	local f = ResolveFrame(entry);
	if not f then return false; end
	if OwnsItsPosition and OwnsItsPosition(entry.key) then
		return SaveToOwner(entry, f);
	end
	SavePosition(entry, f);
	if not unlocked and f.NUFPoint then
		local saved = DB()[EntryKey(entry)];
		if saved and saved.point then LockFramePoint(f, entry, saved); end
	end
	return true;
end

local function HasSavedPoint(entry)
	local saved = DB()[EntryKey(entry)];
	return type(saved) == "table" and saved.point ~= nil;
end

function K.SetMovableScaleFromControl(key, scale)
	if type(scale) ~= "number" then return false; end
	local entry = BY_KEY[key];
	if not entry then return false; end
	if entry.protected and InCombatLockdown() then return false; end
	local f = ResolveFrame(entry);
	if not f then return false; end

	local changed = math.abs((f:GetScale() or 1) - scale) > 0.0005;
	if changed and (unlocked or HasSavedPoint(entry)) then
		CenteredScaleAndSave(entry, f, scale);
		if K.SyncExtraBarScale then pcall(K.SyncExtraBarScale); end
		RequestOverlayRefresh();
		return true;
	end
	return K.SetGlobalFrameScale(key, scale);
end

local ID_TO_KEY = {};
for key, id in pairs(MODULE_SCALE_ID) do ID_TO_KEY[id] = key; end

local function KeepAnchorPoint(entry, frame, cap)
	if not (cap and frame) then return; end
	local new = frame:GetScale() or 1;
	if new == 0 then return; end
	local r = cap.scale / new;
	if math.abs(r - 1) < 0.000001 then return; end

	frame._nufApplying = true;
	frame:ClearAllPoints();
	frame:SetPoint(cap.p, cap.rel or UIParent, cap.rp, cap.x * r, cap.y * r);
	frame._nufApplying = nil;

	if OwnsItsPosition and OwnsItsPosition(entry.key) then
		SaveToOwner(entry, frame);
	else
		SavePosition(entry, frame);
		if not unlocked and frame.NUFPoint then
			local saved = DB()[EntryKey(entry)];
			if saved and saved.point then LockFramePoint(frame, entry, saved); end
		end
	end
end

local function SetOwnedScaleFromControl(entry, frame, owner, newScale)
	local cap;
	if frame then
		local owned = OwnsItsPosition and OwnsItsPosition(entry.key);
		local keep  = (owned and unlocked) or ((not owned) and HasSavedPoint(entry));

		local isCustom = type(K.FramePositionIsCustom) == "table" and K.FramePositionIsCustom[entry.key];
		if owned and type(isCustom) == "function" then
			local ok, v = pcall(isCustom);
			keep = (ok and v) and true or false;
		end
		if keep then
			local p, rel, rp, x, y = frame:GetPoint();
			if p then
				cap = { p = p, rel = rel, rp = rp, x = x or 0, y = y or 0,
				        scale = frame:GetScale() or 1 };
			end
		end
	end
	owner.set(newScale);
	KeepAnchorPoint(entry, frame, cap);
end

function K.SetScaleFromControl(key, scale)
	if type(scale) ~= "number" then return false; end
	local entry = BY_KEY[key];
	if not entry then return false; end
	if entry.protected and InCombatLockdown() then return false; end

	local owner = ScaleOwner(entry);
	if owner then
		SetOwnedScaleFromControl(entry, ResolveFrame(entry), owner, scale);
		ClearSavedScale(entry);
		RequestOverlayRefresh();
		return true;
	end
	if MainBarIsMaster(entry) then
		K.ClearBarOwnScales();
		if K.SaveConfigSilent then K.SaveConfigSilent("ActionBarScale", scale); end
		if K.ApplyActionBarScale then pcall(K.ApplyActionBarScale, scale); end
		if K.RefreshPanelSliders then pcall(K.RefreshPanelSliders, "ActionBarScale"); end
		RequestOverlayRefresh();
		return true;
	end
	return K.SetMovableScaleFromControl(key, scale);
end

function K.SetModuleScaleFromControl(id, scale)
	local key = ID_TO_KEY[id];
	if key and BY_KEY[key] and K.SetScaleFromControl(key, scale) then return true; end
	if K.SetModuleScale then K.SetModuleScale(id, scale); end
	return true;
end

local function RestoreOne(entry)

	if entry.partyTarget then
		DB()[EntryKey(entry)] = nil;
		return;
	end

	local pos = DB()[EntryKey(entry)];
	if not pos then

		UnlockEntryFrames(entry);
		return;
	end

	if pos.scale then
		local owner = ScaleOwner(entry);
		if owner or MainBarIsMaster(entry) then
			if owner then pcall(owner.set, pos.scale); end
			pos.scale = nil;
			if not pos.point then
				DB()[EntryKey(entry)] = nil;
				return;
			end
		end
	end

	if OwnsItsPosition and OwnsItsPosition(entry.key) then
		local f = ResolveFrame(entry);
		if f and pos.scale and entry.scalable then pcall(f.SetScale, f, pos.scale); end
		if pos.point then
			pos.point, pos.relativePoint, pos.rel = nil, nil, nil;
			pos.x, pos.y = nil, nil;
			if not pos.scale then DB()[EntryKey(entry)] = nil; end
			if f then UnlockFramePoint(f); end
		end
		return;
	end

	local frame = ResolveFrame(entry);
	if not frame then return; end

	if InCombatLockdown() and (entry.protected or (frame.IsProtected and frame:IsProtected())) then
		if K.AfterCombat then
			K.AfterCombat("GU_Restore_" .. entry.key, function() pcall(RestoreOne, entry); end);
		end
		return;
	end

	if pos.scale and not entry.scalable then
		pos.scale = nil;
		if not pos.point then
			DB()[EntryKey(entry)] = nil;
			return;
		end
	end

	if pos.scale then
		pcall(frame.SetScale, frame, pos.scale);
	end

	if pos.point then
		ReleaseManaged(entry, frame);
		ApplyPoint(frame, entry, pos);
		if frame.SetUserPlaced and not frame:IsProtected() then
			pcall(frame.SetUserPlaced, frame, true);
		end

		LockFramePoint(frame, entry, pos);
	end
end

function K.GetGlobalScale(key)
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.globalPos;
	local p = db and db[EntryKey(key)];
	return p and p.scale;
end

function K.HasGlobalPos(key)
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.globalPos;

	local p = db and db[EntryKey(key)];
	return (p and p.point) and true or false;
end

function K.RestoreGlobalPosition(key)
	local entry = BY_KEY[key];
	if not entry then return false; end
	local ok = pcall(RestoreOne, entry);
	return ok and true or false;
end

function K.RestoreGlobalPositions()

	MigrateBareKeys();

	for _, entry in ipairs(MOVABLES) do
		pcall(RestoreOne, entry);
	end

	if K.MirrorPartyCastBars then pcall(K.MirrorPartyCastBars); end

	if C.MiniBarEnabled == true and K.ApplyBarHolderScales then
		pcall(K.ApplyBarHolderScales, C.ActionBarScale or 1.0);
	end
end

local function HasSavedPositions()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.globalPos;
	if not db then return false; end
	return next(db) ~= nil;
end

if type(UIParent_ManageFramePositions) == "function" then
	hooksecurefunc("UIParent_ManageFramePositions", function()
		if InCombatLockdown() then return; end
		if not HasSavedPositions() then return; end
		K.RestoreGlobalPositions();
	end);
end

local function PartyCastBar(i)
	return _G["PartyMemberFrame" .. i .. "CastingBarFrame"];
end

function K.SetPartyCastBarPreview(on)
	for i = 1, 4 do
		local bar = PartyCastBar(i);
		if bar then
			if on then
				bar.nufPreview = true;
				bar:SetMinMaxValues(0, 1);
				bar:Show();

				local txt = _G[bar:GetName() .. "Text"];
				if txt then txt:SetText(GetSpellInfo(2050) or "Lesser Heal"); end

				local icon = _G[bar:GetName() .. "Icon"];
				if icon then
					local _, _, tex = GetSpellInfo(2050);
					if tex then icon:SetTexture(tex); icon:Show(); end
				end

				local flash = _G[bar:GetName() .. "Flash"];
				if flash then
					bar.nufFlashWasShown = flash:IsShown();
					flash:Hide();
				end

				bar.nufFill = 0;
				bar:SetScript("OnUpdate", function(self, elapsed)
					self.nufFill = (self.nufFill or 0) + (elapsed or 0) * 0.4;
					if self.nufFill > 1 then self.nufFill = 0; end
					self:SetValue(self.nufFill);
				end);

			elseif bar.nufPreview then
				bar.nufPreview = nil;
				bar.nufFill = nil;

				if C.PCB_Enabled and PartyCastingBars and PartyCastingBars.OnUpdate then
					bar:SetScript("OnUpdate", function(self)
						PartyCastingBars.OnUpdate(self);
					end);
				else
					bar:SetScript("OnUpdate", nil);
				end

				local flash = _G[bar:GetName() .. "Flash"];
				if flash and bar.nufFlashWasShown then flash:Show(); end
				bar.nufFlashWasShown = nil;

				if not (bar.casting or bar.channeling) then bar:Hide(); end
			end
		end
	end
end

function K.MirrorPartyCastBars()
	local b1, p1 = PartyCastBar(1), _G["PartyMemberFrame1"];
	if not (b1 and p1 and b1:GetLeft() and p1:GetRight()) then return; end

	local es1, ep1 = b1:GetEffectiveScale(), p1:GetEffectiveScale();
	local dx = (b1:GetLeft() * es1) - (p1:GetRight() * ep1);
	local dy = (b1:GetTop()  * es1) - (p1:GetTop()   * ep1);

	for i = 2, 4 do
		local b, p = PartyCastBar(i), _G["PartyMemberFrame" .. i];
		if b and p then
			local es = b:GetEffectiveScale();
			if not es or es == 0 then es = 1; end
			b:ClearAllPoints();
			b:SetPoint("TOPLEFT", p, "TOPRIGHT", dx / es, dy / es);
		end
	end
end

function K.ForgetPartyCastBarPosition()
	local entry = BY_KEY["PartyCast"];
	if not entry then return false; end
	DB()[EntryKey(entry)] = nil;
	UnlockFramePoint(PartyCastBar(1));
	return true;
end

function K.SyncPartyCastBarsFrom(index)
	index = tonumber(index) or 1;
	if index < 1 or index > 4 then index = 1; end

	local entry = BY_KEY["PartyCast"];
	local b1, p1 = PartyCastBar(1), _G["PartyMemberFrame1"];
	local b,  p  = PartyCastBar(index), _G["PartyMemberFrame" .. index];
	if not (entry and b1 and p1 and b and p) then return false; end
	if not (b:GetLeft() and p:GetRight() and p1:GetRight()) then return false; end

	if InCombatLockdown() and b1.IsProtected and b1:IsProtected() then return false; end

	local es, ep = b:GetEffectiveScale(), p:GetEffectiveScale();
	local dx = (b:GetLeft() * es) - (p:GetRight() * ep);
	local dy = (b:GetTop()  * es) - (p:GetTop()   * ep);

	local es1 = b1:GetEffectiveScale();
	if not es1 or es1 == 0 then es1 = 1; end

	b1._nufApplying = true;
	b1:ClearAllPoints();
	b1:SetPoint("TOPLEFT", p1, "TOPRIGHT", dx / es1, dy / es1);
	b1._nufApplying = nil;

	ReleaseManaged(entry, b1);

	local db  = DB();
	local key = EntryKey(entry);
	db[key] = db[key] or {};
	db[key].point         = "TOPLEFT";
	db[key].relativePoint = "TOPRIGHT";
	db[key].x             = dx / es1;
	db[key].y             = dy / es1;
	db[key].rel           = "PartyMemberFrame1";

	LockFramePoint(b1, entry, db[key]);
	K.MirrorPartyCastBars();
	return true;
end

local ARENA_TIMER_FRAMES = {
	"NUF_DalaranPipeTimer", "NUF_RoVPillarTimer", "NUF_ArenaEndTimer",
	"NUF_ShadowSightTimer",
};

function K.SetArenaTimersPreview(on)
	for _, name in ipairs(ARENA_TIMER_FRAMES) do
		local f = _G[name];
		if f then
			if on then
				if not f:IsShown() then
					f.nufPreviewShown = true;
					f:Show();
				end
			elseif f.nufPreviewShown then
				f.nufPreviewShown = nil;
				f:Hide();
			end
		end
	end
end

function K.SetPartyTargetPreview(on)
	if InCombatLockdown() then return; end
	for i = 1, 4 do
		local f = _G["PartyTargetFrame" .. i];
		if f then
			if on then
				if not f.nufWatchOff then
					f.nufWatchOff = true;
					pcall(UnregisterUnitWatch, f);
				end
				f:Show();
			elseif f.nufWatchOff then
				f.nufWatchOff = nil;
				pcall(RegisterUnitWatch, f);
			end
		end
	end
end

local MOVER_BACKDROP = {
	bgFile   = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 14,
	insets   = { left = 2.6, right = 2.6, top = 2.6, bottom = 2.6 },
};

local COLOR_FRAME = { 0.75, 0.40, 0.10, 0.40 };
local COLOR_EXTRA = { 0,    0.50, 0.70, 0.40 };
local COLOR_HOVER = { 0.20, 0.30, 0.40, 0.50 };

local function AuraGrid(e)
	local isDebuff = e.debuffAnchor and true or false
	local per = (K.GetAuraIconsPerRow and K.GetAuraIconsPerRow()) or tonumber(BUFFS_PER_ROW) or 8;
	if type(per) ~= "number" or per < 1 then per = 8; end
	local n = isDebuff and (tonumber(DEBUFF_MAX_DISPLAY) or 16) or (tonumber(BUFF_MAX_DISPLAY) or 32);
	local s = (K.GetModuleScale and K.GetModuleScale(isDebuff and "PlayerDebuffs" or "PlayerBuffs")) or 1;
	if type(s) ~= "number" or s <= 0 then s = 1; end

	local bf = _G["BuffFrame"];
	local base = (bf and bf.GetEffectiveScale and bf:GetEffectiveScale()) or UIParent:GetEffectiveScale() or 1;
	local ref = _G["TempEnchant1"];
	local bw = (ref and ref.GetWidth and ref:GetWidth()) or 30;
	local bh = (ref and ref.GetHeight and ref:GetHeight()) or 30;
	if type(bw) ~= "number" or bw < 8 then bw = 30; end
	if type(bh) ~= "number" or bh < 8 then bh = 30; end
	local f  = base * s;
	local sp = tonumber(BUFF_ROW_SPACING) or 0;

	return {
		per = per, n = n,
		cols = math.min(per, n), rows = math.ceil(n / per),
		w = bw * f, h = bh * f,
		gap = 5 * f, space = sp * f,
		pad = 12 * f,
	};
end

local function LayoutAuraSlots(ov, g, us)
	ov.slots = ov.slots or {};
	local w, h   = g.w / us, g.h / us;
	local dx, dy = (g.w + g.gap) / us, (g.h + g.space) / us;
	for i = 1, g.n do
		local tex = ov.slots[i];
		if not tex then
			tex = ov:CreateTexture(nil, "ARTWORK");
			tex:SetTexture(1, 1, 1, 0.14);
			ov.slots[i] = tex;
		end
		local col = (i - 1) % g.per;
		local row = math.floor((i - 1) / g.per);
		tex:ClearAllPoints();
		tex:SetWidth(w);
		tex:SetHeight(h);
		tex:SetPoint("TOPRIGHT", ov, "TOPRIGHT", -col * dx, -row * dy);
		tex:Show();
	end
	for i = g.n + 1, #ov.slots do ov.slots[i]:Hide(); end
end

local overlayLevel = 10;

local function CreateOverlay(entry)
	local frame = ResolveFrame(entry);
	if not frame then return nil; end

	local overlay = CreateFrame("Frame", "NUF_Move_" .. entry.key, UIParent);
	overlay:SetFrameStrata("FULLSCREEN_DIALOG");

	overlayLevel = overlayLevel + 2;
	overlay:SetFrameLevel(overlayLevel);

	local function AnchorOverlay(self)
		self:ClearAllPoints();
		local e = self.entry;

		if e.overlayOn and string.find(e.overlayOn, "^NUF_ActionBar")
		   and K.UpdateActionBarsBox then
			pcall(K.UpdateActionBarsBox);
		elseif e.overlayOn == "NUF_StanceBarBox" and K.UpdateStanceBarBox then
			pcall(K.UpdateStanceBarBox);
		end

		local useOwn = e.framesMiniBar and C.MiniBarEnabled == true;
		local box  = ((not useOwn) and e.overlayOn and _G[e.overlayOn]) or self.target;
		local offX = (e.overlayOffset and e.overlayOffset[1]) or 0;
		local offY = (e.overlayOffset and e.overlayOffset[2]) or 0;

		if e.auraAnchor or e.debuffAnchor then
			local tgt = self.target;
			local right, top = tgt and tgt:GetRight(), tgt and tgt:GetTop();
			if right and top then
				local g  = AuraGrid(e);
				local ts = tgt:GetEffectiveScale() or 1;
				local us = self:GetEffectiveScale() or 1;
				if us == 0 then us = 1; end
				local wpx = g.cols * g.w + (g.cols - 1) * g.gap;
				local hpx = g.rows * g.h + (g.rows - 1) * g.space + g.pad;
				self:SetSize(wpx / us, hpx / us);
				self:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", right * ts / us, top * ts / us);
				LayoutAuraSlots(self, g, us);
				return;
			end
		end

		if e.buttons then
			local l, r, bt, tp, bscale;
			for i = 1, (e.buttons.count or 0) do
				local f = _G[e.buttons.prefix .. i];
				if f and f:IsVisible() and f:GetLeft() then
					local fs = f:GetEffectiveScale() or 1;
					local fl, fr = f:GetLeft() * fs, f:GetRight() * fs;
					local fb, ft = f:GetBottom() * fs, f:GetTop() * fs;
					l  = math.min(l  or fl, fl);
					r  = math.max(r  or fr, fr);
					bt = math.min(bt or fb, fb);
					tp = math.max(tp or ft, ft);
					bscale = fs;
				end
			end
			if l and bscale and (r - l) > 4 then
				local us = self:GetEffectiveScale() or 1;
				if us > 0 then
					self:SetSize((r - l) / us, math.max((tp - bt) / us, 10));

					self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l / us, bt / us);
					return;
				end
			end

		end

		local w = box:GetWidth()  or 0;
		local h = box:GetHeight() or 0;

		local minW = (e.overlaySize and e.overlaySize[1]) or 0;
		local minH = (e.overlaySize and e.overlaySize[2]) or 0;
		local padX = (e.overlayPad  and e.overlayPad[1])  or 0;
		local padY = (e.overlayPad  and e.overlayPad[2])  or 0;

		if w < 8 or h < 8 then
			self:SetSize(math.max(minW, 200), math.max(minH, 60));
			local anchor = e.overlayAnchor or "TOPLEFT";
			self:SetPoint(anchor, box, anchor, offX, offY);
			return;
		end

		if minW == 0 and minH == 0 and padX == 0 and padY == 0
			and offX == 0 and offY == 0 then
			self:SetAllPoints(box);
			return;
		end

		local ts = box:GetEffectiveScale() or 1;
		local os = self:GetEffectiveScale() or 1;
		if ts == 0 then ts = 1; end
		if os == 0 then os = 1; end
		local k = ts / os;

		self:SetSize(math.max(w * k + padX * 2, minW),
		             math.max(h * k + padY * 2, minH));
		self:SetPoint("CENTER", box, "CENTER", offX, offY);
	end
	overlay.AnchorOverlay = AnchorOverlay;
	overlay:EnableMouse(true);
	overlay:SetMovable(true);
	overlay:RegisterForDrag("LeftButton");
	overlay:Hide();

	local col = (entry.group == "frames") and COLOR_FRAME or COLOR_EXTRA;
	overlay.bg = overlay:CreateTexture(nil, "BACKGROUND");
	overlay.bg:SetAllPoints(overlay);
	overlay.bg:SetTexture(col[1], col[2], col[3], col[4]);

	overlay.hl = overlay:CreateTexture(nil, "BORDER");
	overlay.hl:SetAllPoints(overlay);
	overlay.hl:SetTexture(COLOR_HOVER[1], COLOR_HOVER[2], COLOR_HOVER[3], COLOR_HOVER[4]);
	overlay.hl:SetBlendMode("ADD");
	overlay.hl:Hide();
	overlay:HookScript("OnEnter", function(self) self.hl:Show(); end);
	overlay:HookScript("OnLeave", function(self)
		if not self.drag then self.hl:Hide(); end
	end);

	overlay.text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	overlay.text:SetPoint("CENTER", overlay, "CENTER", 0, 0);
	overlay.text:SetTextColor(1, 0.82, 0);

	SetOverlayLabel(overlay, entry, frame);

	overlay.target = frame;
	overlay.entry  = entry;

local function GridStep()
	local v = C and C.MoveGridStep;

	if v == 0 then return 1; end
	if type(v) ~= "number" or v < 1 then return 10; end
	return v;
end

local function BeginDrag(overlay)
	local f = overlay.target;
	if not f then return; end

	f._nufDragging = true;
	if overlay.hl then overlay.hl:Show(); end

	if overlay.entry and overlay.entry.managed then
		f.ignoreFramePositionManager = true;
	end

	local point, relTo, relPoint, ox, oy = f:GetPoint(1);
	if not point then

		f:ClearAllPoints();
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		point, relTo, relPoint, ox, oy = f:GetPoint(1);
		if not point then return; end
	end

	local cx, cy = GetCursorPosition();
	overlay.drag = {
		point = point, relTo = relTo, relPoint = relPoint,
		ox = ox or 0, oy = oy or 0, cx = cx, cy = cy,
	};

	overlay:SetScript("OnUpdate", function(self)
		local d = self.drag;
		if not d or not self.target then return; end
		local f = self.target;

		local es = f:GetEffectiveScale();
		if not es or es == 0 then es = 1; end

		local nx, ny = GetCursorPosition();
		local ox = d.ox + (nx - d.cx) / es;
		local oy = d.oy + (ny - d.cy) / es;
		f:ClearAllPoints();
		f:SetPoint(d.point, d.relTo, d.relPoint, ox, oy);

		local left, bottom = f:GetLeft(), f:GetBottom();
		if left and bottom then
			local grid = GridStep();
			local sl, sb = left * es, bottom * es;
			local tl = math.floor(sl / grid + 0.5) * grid;
			local tb = math.floor(sb / grid + 0.5) * grid;

			f:ClearAllPoints();
			f:SetPoint(d.point, d.relTo, d.relPoint,
				ox + (tl - sl) / es,
				oy + (tb - sb) / es);
		end

		self:AnchorOverlay();
	end);
end

local function EndDrag(overlay)
	overlay:SetScript("OnUpdate", nil);
	overlay.drag = nil;
	if overlay.target then overlay.target._nufDragging = nil; end

	if overlay.hl and not (MouseIsOver and MouseIsOver(overlay)) then overlay.hl:Hide(); end
end

	overlay:SetScript("OnDragStart", function(self)
		if self.entry.protected and InCombatLockdown() then
			print("|cffFF5555NUF:|r " .. (L["MOVE_COMBAT_BLOCK"]
				or "Action bars cannot be moved during combat."));
			return;
		end

		ReleaseManaged(self.entry, self.target);
		UnlockFramePoint(self.target);

		if self.entry.partyIndex and not InCombatLockdown() then

			DetachPartyChain();
			self.target:SetParent(UIParent);
		end
		self.target:SetMovable(true);
		if self.entry.auraAnchor or self.entry.debuffAnchor then self.target:EnableMouse(false); end

		self.target:SetClampedToScreen(self.entry.noClamp ~= true);
		BeginDrag(self);
		self.isMoving = true;
	end);

	overlay:SetScript("OnDragStop", function(self)
		if not self.isMoving then return; end
		self.isMoving = false;
		EndDrag(self);
		if self.target.SetUserPlaced and not self.target:IsProtected() then
			pcall(self.target.SetUserPlaced, self.target, true);
		end

		local moduleOwned = self.entry.partyIndex or self.entry.partyTarget
			or self.entry.partyCast;

		if (not moduleOwned) and OwnsItsPosition and OwnsItsPosition(self.entry.key) then
			if SaveToOwner(self.entry, self.target) then
				UnlockFramePoint(self.target);
				local pos = DB()[EntryKey(self.entry)];
				if pos then
					pos.point, pos.relativePoint, pos.rel = nil, nil, nil;
					pos.x, pos.y = nil, nil;
					if not pos.scale then DB()[EntryKey(self.entry)] = nil; end
				end
				moduleOwned = true;
			end

		end

		if not moduleOwned then
			SavePosition(self.entry, self.target);
			local pos = DB()[EntryKey(self.entry)];
			if pos and pos.point then LockFramePoint(self.target, self.entry, pos); end
		elseif self.entry.partyIndex then

			SavePosition(self.entry, self.target);

			if C.PartyMode3v3 and K.Apply3v3PartyMode then
				pcall(K.Apply3v3PartyMode);
			elseif K.ApplyIndividualPartyPositions then
				pcall(K.ApplyIndividualPartyPositions);
			end
		end

		if self.entry.auraAnchor and K.ReanchorAuras then K.ReanchorAuras(); end
		if self.entry.debuffAnchor and K.ReanchorDebuffs then K.ReanchorDebuffs(); end

		if self.entry.partyCast and K.SyncPartyCastBarsFrom then
			pcall(K.SyncPartyCastBarsFrom, 1);
		end
		if self.entry.partyTarget and PartyTargets_AnchorFromFrame then

			pcall(PartyTargets_AnchorFromFrame, self.target);
		end

		if self.entry.key == "Minimap" and K.RefreshAuraAnchorDefault then
			pcall(K.RefreshAuraAnchorDefault);
		end
		self:AnchorOverlay();
	end);

	if entry.scalable then
		overlay:EnableMouseWheel(true);
		overlay:SetScript("OnMouseWheel", function(self, delta)
			if not IsControlKeyDown() then return; end
			if self.entry.protected and InCombatLockdown() then return; end

			local current = CurrentScale(self.entry, self.target);
			local newScale = current + (delta > 0 and 0.05 or -0.05);
			local key = self.entry.key;
			local range = (MainBarIsMaster(self.entry) and MAINBAR_RANGE)
				or SLIDER_RANGE[key] or { 0.5, 2.0 };
			if newScale < range[1] then newScale = range[1]; end
			if newScale > range[2] then newScale = range[2]; end

			local owner = ScaleOwner(self.entry);
			if owner then

				SetOwnedScaleFromControl(self.entry, self.target, owner, newScale);
				ClearSavedScale(self.entry);
			elseif MainBarIsMaster(self.entry) then

				K.ClearBarOwnScales();
				if K.SaveConfigSilent then K.SaveConfigSilent("ActionBarScale", newScale); end
				if K.ApplyActionBarScale then pcall(K.ApplyActionBarScale, newScale); end
				if K.RefreshPanelSliders then pcall(K.RefreshPanelSliders, "ActionBarScale"); end
			else

				CenteredScaleAndSave(self.entry, self.target, newScale);

				local perBar = (C.MiniBarEnabled == true) and STACK_KEYS[self.entry.key];
				if K.SyncFrameScaleSetting and not perBar then
					K.SyncFrameScaleSetting(self.entry.key, newScale);
				end

				if perBar and K.ApplyBarHolderScales then
					pcall(K.ApplyBarHolderScales, C.ActionBarScale or 1.0);
				end

				if key == "CastBar" and K.ApplyCastBarPWScale then
					pcall(K.ApplyCastBarPWScale, newScale);
				end
			end

			if K.SyncExtraBarScale then pcall(K.SyncExtraBarScale); end

			SetOverlayLabel(self);
			self:AnchorOverlay();
		end);
	end

	overlay.target = frame;
	overlay.entry  = entry;
	AnchorOverlay(overlay);

	return overlay;
end

local SCALE_SETTING = {
	Player = "PlayerFrameScale",
	Target = "TargetFrameScale",

	Pet    = "PetFrameScale",

	MainBar = "ActionBarScale",
	CastBar = "CastBarPWScale",
};

local SETTING_MOVABLES = {};
for key, setting in pairs(SCALE_SETTING) do
	SETTING_MOVABLES[setting] = SETTING_MOVABLES[setting] or {};
	table.insert(SETTING_MOVABLES[setting], key);
end
for _, list in pairs(SETTING_MOVABLES) do table.sort(list); end

function K.GetMovablesForSetting(setting)
	return SETTING_MOVABLES[setting];
end

function K.SyncFrameScaleSetting(key, scale)
	local setting = SCALE_SETTING[key];
	if not setting then return; end
	if K.SaveConfigSilent then
		K.SaveConfigSilent(setting, scale);
	elseif K.SaveConfig then
		K.SaveConfig(setting, scale);
	end
	if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
	if K.RefreshCastBarScaleSlider then K.RefreshCastBarScaleSlider(); end

	if K.RefreshPanelSliders then pcall(K.RefreshPanelSliders, setting); end
end

local builtFor = {};

local function BuildOverlays()
	InstallScaleHooks();

	if K.MiniBarDetachStack then pcall(K.MiniBarDetachStack); end

	if K.UpdateActionBarsBox then pcall(K.UpdateActionBarsBox); end
	if K.UpdateStanceBarBox then pcall(K.UpdateStanceBarBox); end

	for _, entry in ipairs(MOVABLES) do

		if entry.noOverlay then

		elseif not builtFor[entry.key] then
			local ov = CreateOverlay(entry);
			if ov then
				builtFor[entry.key] = ov;
				table.insert(overlays, ov);
			end
		else

			local f = ResolveFrame(entry);
			local ov = builtFor[entry.key];
			if f and ov.target ~= f then
				ov.target = f;
			end
			if ov.target and ov.AnchorOverlay then ov:AnchorOverlay(); end

			SetOverlayLabel(ov);
		end
	end
end

local console;

local function BuildConsole()
	if console then return console; end

	console = CreateFrame("Frame", "NUF_MoverConsole", UIParent);
	console:SetSize(320, 124);

	console:SetFrameStrata("TOOLTIP");
	console:SetToplevel(true);
	console:SetBackdrop(MOVER_BACKDROP);
	console:SetBackdropColor(0, 0, 0, 0.75);
	console:SetBackdropBorderColor(1, 0.71, 0, 0.45);
	console:Hide();

	local saved = NidhausUnitFramesDB and NidhausUnitFramesDB.moverConsolePos;
	if saved and saved.point then
		console:SetPoint(saved.point, UIParent, saved.relPoint or saved.point,
			saved.x or 0, saved.y or 0);
	else

		console:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -40, -60);
	end

	console:EnableMouse(true);
	console:SetMovable(true);
	console:SetClampedToScreen(true);
	console:RegisterForDrag("LeftButton");
	console:SetScript("OnDragStart", function(self) self:StartMoving(); end);
	console:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing();
		local point, _, relPoint, x, y = self:GetPoint(1);
		if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
		NidhausUnitFramesDB.moverConsolePos = {
			point = point, relPoint = relPoint, x = x, y = y,
		};
	end);

	console.title = console:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	console.title:SetPoint("TOP", console, "TOP", 0, -8);
	console.title:SetTextColor(1, 0.8, 0);
	console.title:SetText(L["MOVER_CONSOLE"] or "Move Everything");

	console.hint = console:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	console.hint:SetPoint("TOP", console, "TOP", 0, -22);
	console.hint:SetText("|cff8EAEC9" .. (L["MOVER_HINT_SCALE"]
		or "Ctrl + mouse wheel over a box to scale it") .. "|r");

	console.gridLbl = console:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	console.gridLbl:SetPoint("TOPLEFT", console, "TOPLEFT", 14, -52);
	console.gridLbl:SetText(L["LBL_MOVE_GRID"] or "Grid");

	console.gridBtns = {};
	local function RefreshGrid()
		local cur = (C and C.MoveGridStep) or 10;
		for step, b in pairs(console.gridBtns) do
			if step == cur then b:LockHighlight(); else b:UnlockHighlight(); end
		end
	end
	console.RefreshGrid = RefreshGrid;

	K.RefreshMoveConsoleGrid = RefreshGrid;

	local gx = 56;
	for _, step in ipairs({ 0, 2, 5, 10 }) do
		local b = CreateFrame("Button", nil, console, "UIPanelButtonTemplate");
		b:SetPoint("TOPLEFT", console, "TOPLEFT", gx, -48);
		b:SetSize((step == 0) and 44 or 50, 22);
		b:SetText((step == 0) and (L["BTN_GRID_OFF"] or "Off") or ("x" .. step));
		b:SetScript("OnClick", function()

			local cur  = (C and C.MoveGridStep) or 10;

			local want = (step == 0 or cur == step) and 0 or step;
			if K.SaveConfig then K.SaveConfig("MoveGridStep", want); end
			RefreshGrid();

			if K._RefreshMoveGridButtons then pcall(K._RefreshMoveGridButtons); end
		end);
		console.gridBtns[step] = b;
		gx = gx + ((step == 0) and 48 or 54);
	end

	local lockBtn = CreateFrame("Button", nil, console, "UIPanelButtonTemplate");
	lockBtn:SetPoint("BOTTOMRIGHT", console, "BOTTOMRIGHT", -14, 12);
	lockBtn:SetSize(120, 24);
	lockBtn:SetText(L["BTN_LOCK_IT"] or "Lock it");
	lockBtn:SetScript("OnClick", function()
		if K.SetGlobalUnlock then K.SetGlobalUnlock(false, currentScope); end
	end);

	local resetBtn = CreateFrame("Button", nil, console, "UIPanelButtonTemplate");
	resetBtn:SetPoint("BOTTOMLEFT", console, "BOTTOMLEFT", 14, 12);
	resetBtn:SetSize(120, 24);
	resetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
	resetBtn:SetScript("OnClick", function()

		if K.ResetEverything then K.ResetEverything();
		elseif K.ResetGlobalPositions then K.ResetGlobalPositions(); end
	end);

	RefreshGrid();
	return console;
end

function K.RefreshGlobalUnlockOverlays()
	if not unlocked then return; end

	BuildOverlays();

	for _, entry in ipairs(MOVABLES) do
		if entry.preview and K[entry.preview] then
			pcall(K[entry.preview], EntryModuleActive(entry) and true or false);
		end
	end

	for _, ov in ipairs(overlays) do
		if EntryInScope(ov.entry) then
			if ov.AnchorOverlay then ov:AnchorOverlay(); end
			ov:Show();
		else
			ov:Hide();
		end
	end
end

function K.SetGlobalUnlock(state, scope)

	if state and K.LoadArenaModules then pcall(K.LoadArenaModules); end
	unlocked = state and true or false;

	if not unlocked and K.ExitArenaTimersMoving then
		pcall(K.ExitArenaTimersMoving);
	end

	if unlocked then
		if K.IsMeleeSwingUnlocked and K.IsMeleeSwingUnlocked() then
			pcall(K.ToggleMeleeSwingUnlock);
		end
	end

	if not unlocked then
		for _, ov in ipairs(overlays) do
			if ov.isMoving then
				local stop = ov:GetScript("OnDragStop");
				if stop then pcall(stop, ov); end
			end
		end
	end

	currentScope = scope or "all";

	for _, entry in ipairs(MOVABLES) do

		if entry.preview and K[entry.preview] and EntryModuleActive(entry) then
			pcall(K[entry.preview], unlocked and ScopeMatches(entry));
		end
	end
	BuildOverlays();

	for _, ov in ipairs(overlays) do
		if unlocked and EntryInScope(ov.entry) then
			if ov.AnchorOverlay then ov:AnchorOverlay(); end
			ov:Show();
		else
			ov:Hide();
		end
	end

	if K.SetPartyTestMode then
		pcall(K.SetPartyTestMode, unlocked and currentScope ~= "pet");
	end

	if K.ToggleArenaFramesMover and not InCombatLockdown() then
		local db = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover;
		local shown = (db and db.IsShown) and true or false;

		local want = unlocked and currentScope ~= "pet";
		if want then
			if not shown then pcall(K.ToggleArenaFramesMover); end
		else
			if shown then pcall(K.ToggleArenaFramesMover); end
		end
	end

	if unlocked and currentScope == "pet" then

		if console then console:Hide(); end
	elseif unlocked then
		local c = BuildConsole();
		if c then
			if c.RefreshGrid then c:RefreshGrid(); end
			c:Show();
		end
	elseif console then
		console:Hide();

		if C.MiniBarEnabled == true and K.RefreshMiniBarLayout then
			pcall(K.RefreshMiniBarLayout);
		end
	end

end

function K.IsGlobalUnlocked()
	return unlocked;
end

function K.GetGlobalUnlockScope()
	return currentScope;
end

function K.ToggleGlobalUnlock(scope)
	K.SetGlobalUnlock(not unlocked, scope);
end

function K.ResetTimerBarPositions()
	if K.ResetAutoShotTimerPosition then pcall(K.ResetAutoShotTimerPosition); end
	if K.ResetMeleeSwingTimerPosition then pcall(K.ResetMeleeSwingTimerPosition); end
	if K.ResetArrowCountPosition then pcall(K.ResetArrowCountPosition); end
end

local POS_FIELDS = { "point", "rel", "relPoint", "relativePoint",
                     "relativeTo", "x", "y" };

local OWN_STORES = {
	PalAuras     = "PaladinAuras",
	TurnEvil     = "TurnEvil",
	EnemyAlert   = "EnemySpellAlert",
	ArrowCount   = "ArrowCount",
	DungeonRoles = "DungeonRoles",
	AutoShot     = "AutoShotTimer",
	SwingTimer   = "MeleeSwingTimer",
	Gargoyle     = "GargoyleTracker",

	WaterEle     = "ClassTimers",
	MirrorImg    = "ClassTimers",
	DalaranPipe  = "timerPos",
	RoVPillars   = "timerPos",
	ArenaEnd     = "timerPos",
	ShadowSight  = "timerPos",
};

local OWN_GLOBALS = {
	PaladinICD   = "PaladinICD_DB",
	SacredShield = "SacredShieldDB",
	SSTracker    = "SacredShieldTrackerDB",
	Seduction    = "SeductionAlertDB",
};

function OwnsItsPosition(key)
	if not key then return false; end
	if K.FramePositionOwners[key] then return true; end
	return (OWN_STORES[key] or OWN_GLOBALS[key]) and true or false;
end

local function WipePos(tbl)
	if type(tbl) ~= "table" then return false; end

	for _, f in ipairs(POS_FIELDS) do tbl[f] = nil; end

	for k, v in pairs(tbl) do
		if type(v) == "table" then
			local vacia = true;
			for _, f in ipairs(POS_FIELDS) do v[f] = nil; end
			for _ in pairs(v) do vacia = false; break; end
			if vacia then tbl[k] = nil; end
		end
	end

	for _ in pairs(tbl) do return false; end
	return true;
end

local function ClearOwnStore(key)
	local name = OWN_STORES[key];
	if name and NidhausUnitFramesDB then
		if WipePos(NidhausUnitFramesDB[name]) then
			NidhausUnitFramesDB[name] = nil;
		end
	end
	local gname = OWN_GLOBALS[key];
	if gname and _G[gname] then
		if WipePos(_G[gname]) then _G[gname] = nil; end
	end
end

local function DropLegacyFocusPos()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.globalPos;
	if db and db.Focus then db.Focus = nil; end
end

function K.ResetGlobalPositions(only)

	if K.AfterCombat and K.AfterCombat("ResetGlobalPositions", function() K.ResetGlobalPositions(only); end) then
		print("|cff4FC3F7NUF:|r " .. (L["RESET_AFTER_COMBAT"]
			or "You're in combat: the reset will apply when combat ends."));
		return;
	end
	CaptureOriginals();

	local function Wanted(key) return (not only) or only[key]; end

	if NidhausUnitFramesDB then
		if only then
			local db = NidhausUnitFramesDB.globalPos;
			if db then
				for key in pairs(only) do

					db[EntryKey(key)] = nil;
					db[key]           = nil;

					if PER_MODE_KEYS[key] then
						db[key .. "#mini"]  = nil;
						db[key .. "#unify"] = nil;
						db[key .. "#plain"] = nil;
					end
				end
			end
		else
			NidhausUnitFramesDB.globalPos = nil;
		end
	end

	if not only and NidhausUnitFramesDB and NidhausUnitFramesDB.positions then
		for i = 1, (MAX_PARTY_MEMBERS or 4) do
			NidhausUnitFramesDB.positions["PartyMemberFrame" .. i] = nil;
		end
	end
	if not only and C.PartyIndividualMove then
		C.PartyIndividualMove = false;
		if K.SaveConfig then K.SaveConfig("PartyIndividualMove", false); end
	end

	for _, entry in ipairs(MOVABLES) do
		if Wanted(entry.key) then
			local f = ResolveFrame(entry);
			if f then
				UnlockFramePoint(f);
				f.NUFPoint = nil;
			end
			ReclaimManaged(entry);
			pcall(RestoreOriginal, entry);

			if entry.resetFunc and K[entry.resetFunc] then
				pcall(K[entry.resetFunc]);
			end

			pcall(ClearOwnStore, entry.key);
		end
	end

	if Wanted("PartyCast") then
		if PartyCastingBars and PartyCastingBars.ResetBarLocations then
			pcall(PartyCastingBars.ResetBarLocations);
		elseif K.MirrorPartyCastBars then
			pcall(K.MirrorPartyCastBars);
		end
	end

	if not only then
		if C.PartyMode3v3 and K.Apply3v3PartyMode then
			pcall(K.Apply3v3PartyMode);
		elseif K.RestorePartyToGroup then
			pcall(K.RestorePartyToGroup);
		end

		K.ResetTimerBarPositions();
	end
	if Wanted("Buffs") or Wanted("Debuffs") then
		if K.ResetAuraAnchor then K.ResetAuraAnchor(); end
	end

	if not InCombatLockdown() and type(UIParent_ManageFramePositions) == "function" then
		pcall(UIParent_ManageFramePositions);
	end

	for _, ov in ipairs(overlays) do
		if ov.AnchorOverlay then pcall(ov.AnchorOverlay, ov); end
	end

	local settle = CreateFrame("Frame");
	settle:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil);

		if K.RefreshAuraAnchorDefault then pcall(K.RefreshAuraAnchorDefault); end
		if Wanted("Buffs") or Wanted("Debuffs") then
			if K.ResetAuraAnchor then pcall(K.ResetAuraAnchor); end
		end
		for _, ov in ipairs(overlays) do
			if ov.AnchorOverlay then pcall(ov.AnchorOverlay, ov); end
		end
	end);

	for _, entry in ipairs(MOVABLES) do
		local owner = entry.scalable and Wanted(entry.key) and ScaleOwner(entry);
		if owner then

			pcall(owner.reset);
		elseif entry.scalable and Wanted(entry.key) and MainBarIsMaster(entry) then
			local def = (K.GetConfigDefault and K.GetConfigDefault("ActionBarScale")) or 1.0;
			if K.SaveConfigSilent then pcall(K.SaveConfigSilent, "ActionBarScale", def); end
			if K.ApplyActionBarScale then pcall(K.ApplyActionBarScale, def); end
			if K.RefreshPanelSliders then pcall(K.RefreshPanelSliders, "ActionBarScale"); end
		elseif entry.scalable and Wanted(entry.key) then

			local setting = SCALE_SETTING[entry.key];
			local def = (setting and K.GetConfigDefault and K.GetConfigDefault(setting)) or 1.0;
			local f = ResolveFrame(entry);
			if f and f.SetScale then
				pcall(f.SetScale, f, def);
			end

			if entry.auraAnchor and K.SaveAuraAnchorScale then
				pcall(K.SaveAuraAnchorScale, 1.0);
			elseif entry.debuffAnchor and K.SaveDebuffAnchorScale then
				pcall(K.SaveDebuffAnchorScale, 1.0);
			end
			if K.SyncFrameScaleSetting then
				pcall(K.SyncFrameScaleSetting, entry.key, def);
			end
		end
	end

	if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
	if K.RefreshPanelSliders then pcall(K.RefreshPanelSliders); end
	if K.RefreshModuleScaleSliders then pcall(K.RefreshModuleScaleSliders); end

	if C.MiniBarEnabled == true and K.ResetMiniBarLayout then
		pcall(K.ResetMiniBarLayout);
	end
	if K.UpdateActionBarsBox then pcall(K.UpdateActionBarsBox); end

end

local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:SetScript("OnEvent", function(self)
	DropLegacyFocusPos();

	CaptureOriginals();

	local acc, tries = 0, 0;
	self:SetScript("OnUpdate", function(s, elapsed)
		acc = acc + elapsed;
		if acc < 0.5 then return; end
		acc = 0;
		tries = tries + 1;
		CaptureOriginals();
		K.RestoreGlobalPositions();
		if tries >= 3 then s:SetScript("OnUpdate", nil); end
	end);
end);

local reapply = CreateFrame("Frame");
local reapplyAcc = 0;
reapply:Hide();
reapply:SetScript("OnUpdate", function(self, elapsed)
	reapplyAcc = reapplyAcc + elapsed;
	if reapplyAcc < 0.3 then return; end
	self:Hide();
	if not InCombatLockdown() and HasSavedPositions() then
		K.RestoreGlobalPositions();
	end
end);

function K.ScheduleGlobalPositionReapply()
	if not HasSavedPositions() then return; end
	reapplyAcc = 0;
	reapply:Show();
end

local combatGuard = CreateFrame("Frame");
combatGuard:RegisterEvent("PLAYER_REGEN_DISABLED");
combatGuard:SetScript("OnEvent", function()
	if unlocked then K.SetGlobalUnlock(false); end
end);

SLASH_NUFMOVE1 = "/nufmove";
SLASH_NUFMOVE2 = "/move";
SLASH_NUFMOVE3 = "/nufunlock";

SlashCmdList["NUFMOVE"] = function(msg)
	msg = string.lower(msg or "");
	msg = string.gsub(msg, "^%s+", "");
	msg = string.gsub(msg, "%s+$", "");

	if msg == "reset" then

		if K.ResetEverything then K.ResetEverything();
		else K.ResetGlobalPositions(); end
		print("|cff4FC3F7NUF:|r " .. (L["MOVE_RESET_DONE"]
			or "Every frame is back to its default position."));
		return;
	end

	if msg == "lock" then
		K.SetGlobalUnlock(false, currentScope);
		return;
	end

	if msg == "help" or msg == "?" then
		print("|cff4FC3F7NUF - " .. (L["MOVER_CONSOLE"] or "Move Everything") .. "|r");
		print("   /move          " .. (L["MOVE_HELP_ALL"]    or "unlock everything"));
		print("   /move frames   " .. (L["MOVE_HELP_FRAMES"] or "only the unit frames"));
		print("   /move lock     " .. (L["MOVE_HELP_LOCK"]   or "lock it back"));
		print("   /move reset    " .. (L["MOVE_HELP_RESET"]  or "back to default positions"));
		return;
	end

	K.ToggleGlobalUnlock(msg == "frames" and "frames" or "all");
end
