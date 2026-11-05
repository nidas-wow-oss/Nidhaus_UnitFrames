local AddOnName, ns = ...;
local K, C, L = unpack(ns);

K.Modules = {};
K.ModuleOrder = {};

local modulesInitialized = false;

local deferredBodies = {};

function K.RegisterModule(id, info)
	if not id or not info then
		print(L["MM_REGISTER_ERROR"]);
		return;
	end

	local existing = K.Modules[id];
	if existing then

		if existing._deferred and not existing._filled then
			existing._filled = true;
			for k, v in pairs(info) do
				if k ~= "default" then existing[k] = v; end
			end
		end
		return;
	end

	K.Modules[id] = {
		name      = info.name or id,
		desc      = info.desc or "",
		onEnable  = info.onEnable,
		onDisable = info.onDisable,
		createUI  = info.createUI or nil,
		default   = (info.default ~= false),
		hideFromModulesTab = info.hideFromModulesTab or false,

		configFunc  = info.configFunc,
		configLabel = info.configLabel,
		_deferred   = deferredBodies[id] ~= nil,
	};

	table.insert(K.ModuleOrder, id);

	if modulesInitialized then
		if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
		if not NidhausUnitFramesDB.Modules then NidhausUnitFramesDB.Modules = {}; end
		if NidhausUnitFramesDB.Modules[id] == nil then
			NidhausUnitFramesDB.Modules[id] = K.Modules[id].default;
		end
		if NidhausUnitFramesDB.Modules[id] then K.LoadModuleBody(id); end
		if NidhausUnitFramesDB.Modules[id] and K.Modules[id].onEnable then
			local ok, err = pcall(K.Modules[id].onEnable);
			if not ok then print((L["MM_ERROR_INIT"] or "") .. id .. ": " .. tostring(err)); end
		end
	end
end

function K.DeferModule(id, info, body)
	if not id or not info or type(body) ~= "function" then
		print(L["MM_REGISTER_ERROR"]);
		return;
	end
	if K.Modules[id] then return; end
	deferredBodies[id] = body;
	K.RegisterModule(id, info);
end

function K.LoadModuleBody(id)
	local body = deferredBodies[id];
	if not body then return true; end

	for other, b in pairs(deferredBodies) do
		if b == body then deferredBodies[other] = nil; end
	end
	local ok, err = pcall(body);
	if not ok then
		print((L["MM_ERROR_INIT"] or "") .. id .. ": " .. tostring(err));
		return false;
	end

	if K.GuardModuleCommands then pcall(K.GuardModuleCommands); end
	return true;
end

function K.IsModuleLoaded(id)
	return K.Modules[id] ~= nil and deferredBodies[id] == nil;
end

function K.LoadAllModuleBodies()
	for _, id in ipairs(K.ModuleOrder) do
		if deferredBodies[id] then K.LoadModuleBody(id); end
	end
end

K._moduleConfigButtons = K._moduleConfigButtons or {};

function K.RegisterModuleConfigButton(id, btn)
	if not id or not btn then return; end
	if not K._moduleConfigButtons[id] then K._moduleConfigButtons[id] = {}; end
	table.insert(K._moduleConfigButtons[id], btn);
end

function K.SetModuleConfigLabel(id, text)
	local list = K._moduleConfigButtons and K._moduleConfigButtons[id];
	if not list or not text then return; end
	for _, btn in ipairs(list) do
		if btn.SetText then btn:SetText(text); end
	end
end

K._moduleCheckboxes = K._moduleCheckboxes or {};

function K.RegisterModuleCheckbox(id, cb)
	if not id or not cb then return; end
	if not K._moduleCheckboxes[id] then K._moduleCheckboxes[id] = {}; end
	table.insert(K._moduleCheckboxes[id], cb);
end

function K.RefreshModuleCheckbox(id)
	local list = K._moduleCheckboxes and K._moduleCheckboxes[id];
	if not list then return; end
	local state = K.IsModuleEnabled(id);
	for _, cb in ipairs(list) do
		if cb.SetChecked then cb:SetChecked(state); end
	end
end

function K.IsModuleEnabled(id)
	if not NidhausUnitFramesDB or not NidhausUnitFramesDB.Modules then return false; end
	local val = NidhausUnitFramesDB.Modules[id];
	if val == nil then
		return K.Modules[id] and K.Modules[id].default or false;
	end
	return val == true;
end

function K.SetModuleEnabled(id, enabled)
	if not K.Modules[id] then return false; end

	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.Modules then NidhausUnitFramesDB.Modules = {}; end

	NidhausUnitFramesDB.Modules[id] = enabled;

	if enabled then K.LoadModuleBody(id); end

	local mod = K.Modules[id];
	if enabled and mod.onEnable then
		local ok, err = pcall(mod.onEnable);
		if not ok then print(L["MM_ERROR_ENABLING"]..id..": "..tostring(err)); end
	elseif not enabled and mod.onDisable then
		local ok, err = pcall(mod.onDisable);
		if not ok then print(L["MM_ERROR_DISABLING"]..id..": "..tostring(err)); end
	end

	if K.RefreshGlobalUnlockOverlays then
		pcall(K.RefreshGlobalUnlockOverlays);
	end

	return true;
end

local FORCE_OFF_ONCE = {
	"AbbreviatedStatus", "DTSU", "PaladinICD", "EnemySpellAlert",
	"PowerBar", "ShieldWatch",

	"PartyBuffs",
};

local FORCE_OFF_SETTINGS_ONCE = {
	"PartyTargetsEnabled",
	"HealthPercentage",
};

local FORCE_OFF_FLAG = "_forcedOff_v39";

function K.InitializeModules()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.Modules then NidhausUnitFramesDB.Modules = {}; end

	if not NidhausUnitFramesDB[FORCE_OFF_FLAG] then
		NidhausUnitFramesDB[FORCE_OFF_FLAG] = true;
		for _, id in ipairs(FORCE_OFF_ONCE) do
			NidhausUnitFramesDB.Modules[id] = false;
		end
		for _, key in ipairs(FORCE_OFF_SETTINGS_ONCE) do
			NidhausUnitFramesDB[key] = false;
			if C then C[key] = false; end
		end
	end

	modulesInitialized = true;

	for _, id in ipairs(K.ModuleOrder) do
		local mod = K.Modules[id];

		if NidhausUnitFramesDB.Modules[id] == nil then
			NidhausUnitFramesDB.Modules[id] = mod.default;
		end

		local enabled = NidhausUnitFramesDB.Modules[id];

		if enabled then K.LoadModuleBody(id); end

		if enabled and mod.onEnable then
			local ok, err = pcall(mod.onEnable);
			if not ok then
				print(L["MM_ERROR_INIT"]..id..": "..tostring(err));
			end
		end
	end
end

local DISPLAY_PRIORITY = {
	"LortiUI", "NiceDamage", "ClassIcons", "SpecIcons", "PartyBuffs",
};

function K.GetModuleDisplayOrder()
	local out, seen = {}, {};

	for _, id in ipairs(DISPLAY_PRIORITY) do
		if K.Modules[id] then
			table.insert(out, id);
			seen[id] = true;
		end
	end

	for _, id in ipairs(K.ModuleOrder) do
		if not seen[id] then table.insert(out, id); end
	end

	return out;
end

local ADDON_ORDER = {
	"LortiUI", "NiceDamage", "ClassIcons", "SpecIcons",
	"ShieldWatch", "HideChatButton", "MinimapIconToggle",
};

local ADDON_ELSEWHERE = {
	ArrowCount            = true,
	AutoShotTimer         = true,
	ComboWatch            = true,
	HunterPetBuffs        = true,
	PowerBar              = true,
	MeleeSwingTimer       = true,
	ArenaTimes            = true,
	ArenaToT              = true,
	ArenaPointsCalc       = true,
	ButtonRange           = true,
	HideActionBarTextures = true,
	PartyBuffs            = true,
	PartyFramesImproved   = true,
	AbbreviatedStatus     = true,
	PaladinICD            = true,
	EnemySpellAlert       = true,
	PaladinAuras          = true,
	TurnEvil              = true,
};

function K.GetAddonTabIds()
	local ids, placed = {}, {};

	for _, id in ipairs(ADDON_ORDER) do
		if K.Modules[id] then
			table.insert(ids, id);
			placed[id] = true;
		end
	end

	for _, id in ipairs(K.ModuleOrder) do
		local mod = K.Modules[id];
		if not placed[id] and not ADDON_ELSEWHERE[id]
			and mod and not mod.hideFromModulesTab then
			table.insert(ids, id);
		end
	end

	return ids;
end

function K.ListModules()
	print(L["MM_LIST_HEADER"]);
	if #K.ModuleOrder == 0 then
		print(L["MM_LIST_EMPTY"]);
		print(L["MM_LIST_HINT"]);
	else
		for _, id in ipairs(K.ModuleOrder) do
			local mod = K.Modules[id];
			local enabled = K.IsModuleEnabled(id);
			local status = enabled and "|cff00FF00ON|r" or "|cffFF0000OFF|r";
			print("  ["..status.."] |cffFFFFFF"..mod.name.."|r - "..mod.desc);
		end
	end
	print("");
end

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN");
		K.InitializeModules();
	end
end);

local ZONE_KEYS = { "inArena", "inBG", "inDuel", "inWorld" };
local zoneOwners = {};
local inDuel = false;

function K.InDuel() return inDuel; end

local function ZoneDB(id)
	local o = zoneOwners[id];
	local db = o and o.db and o.db();
	if type(db) ~= "table" then return nil; end
	for _, k in ipairs(ZONE_KEYS) do
		if db[k] == nil then db[k] = true; end
	end
	return db;
end

function K.RegisterModuleZones(id, dbFn, onChange)
	if not id or type(dbFn) ~= "function" then return; end
	zoneOwners[id] = { db = dbFn, onChange = onChange };
end

function K.HasModuleZones(id) return zoneOwners[id] ~= nil; end

function K.GetModuleZone(id, key)
	local db = ZoneDB(id);
	if not db then return true; end
	return db[key] and true or false;
end

function K.SetModuleZone(id, key, v)
	local db = ZoneDB(id);
	if not db then return; end
	db[key] = v and true or false;
	local o = zoneOwners[id];
	if o and o.onChange then pcall(o.onChange); end
end

function K.ModuleZoneAllowed(id)
	local db = ZoneDB(id);
	if not db then return true; end
	local _, itype = GetInstanceInfo();
	if itype == "arena" then return db.inArena and true or false; end
	if itype == "pvp"   then return db.inBG and true or false; end
	if inDuel then return db.inDuel and true or false; end
	return db.inWorld and true or false;
end

local function ZonesChanged()
	for _, o in pairs(zoneOwners) do
		if o.onChange then pcall(o.onChange); end
	end
end

local zoneWatch = CreateFrame("Frame");
zoneWatch:RegisterEvent("PLAYER_ENTERING_WORLD");
zoneWatch:RegisterEvent("ZONE_CHANGED_NEW_AREA");
zoneWatch:RegisterEvent("DUEL_REQUESTED");
zoneWatch:RegisterEvent("DUEL_INBOUNDS");
zoneWatch:RegisterEvent("DUEL_OUTOFBOUNDS");
zoneWatch:RegisterEvent("DUEL_FINISHED");
zoneWatch:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_ENTERING_WORLD" or event == "DUEL_FINISHED" then

		inDuel = false;
	elseif event ~= "ZONE_CHANGED_NEW_AREA" then
		inDuel = true;
	end
	ZonesChanged();
end);
if type(StartDuel) == "function" then
	hooksecurefunc("StartDuel", function()
		inDuel = true;
		ZonesChanged();
	end);
end
