local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ConfigManager

local defaults = {
	-- GENERAL
	classColor = true,
	statusbarBackdrop = true,
	HealthPercentage = true,
	
	-- FRAMES
	SetPositions = false,
	LockPositions = true,
	PartyIndividualMove = false,
	PlayerFrameScale = 1.0,
	TargetFrameScale = 1.0,
	FocusScale = 1.0,
	FocusSpellBarScale = 1.2,
	FocusAuraLimit = false,
	Focus_maxDebuffs = 0,
	Focus_maxBuffs = 0,
	BossFrameScale = 0.65,
	
	-- PARTY/ARENA
	NewPartyFrame = false,
	PartyTargetsEnabled = true,
	PartyFrameOn = true,
	PartyFrameScale = 1.0,
	PartyMemberFrameSpacing = 0,
	PartyMode3v3 = true,
	BossTargetFrameSpacing = 0,
	ArenaFrameOn = true,
	ArenaFrameScale = 1.5,
	ArenaCustomTexture = true,
	ArenaFrame_Trinkets = true,
	ArenaFrame_Trinket_Voice = false,
	ArenaMirrorMode = false,
	ArenaFrameSpacing = 0,

	-- ARENA STYLE: "Default", "Custom", "Flat"
	ArenaFrameStyle = "Custom",

	-- FLAT STYLE OPTIONS
	ArenaFlatMode = false,
	ArenaFlatWidth = 120,
	ArenaFlatHealthBarHeight = 20,
	ArenaFlatPowerBarHeight = 8,
	ArenaFlatHealthFontSize = 9,
	ArenaFlatPowerFontSize = 9,
	ArenaFlatBarTexture = "",
	ArenaFlatMirrored = false,
	ArenaFlatStatusText = true,

	-- ARENA PET FRAME
	ArenaPetFrameShow = false,
	ArenaFlatPetStyle = true,

	-- CAST BAR OPTIONS
	ArenaCastBarEnable = false,
	ArenaCastBarScale = 1.0,
	ArenaCastBarWidth = 80,

	-- VISUAL THEME
	darkFrames = false,

	-- PARTY CASTING BARS
	PCB_Enabled = false,

	-- EXTRA OPTIONS
	ArenaCountDown = true,
	AutoSellGray = true,
	AutoRepair = true,
	ErrorHideInCombat = true,

	-- ACTION BARS
	UnifyActionBars = true,
	MiniBarEnabled = false,
	HideGryphons = false,
	ActionBarScale = 1.0,
	ShowBagPackTexture = true,

	-- LORTI UI SUB-OPTIONS
	LortiUI_PlayerTargetFocus = true,  -- Player, Target, Focus frame textures
	LortiUI_Party             = true,  -- Party frame textures
	LortiUI_Arena             = true,  -- Arena frame textures
	LortiUI_ActionBars        = true,  -- Action bar textures
	LortiUI_Minimap           = true,  -- Minimap textures & scroll
};

local configLoaded = false;

-- FireConfigEvent
local eventCallbacks = {};

local function FireConfigEvent(eventName)
	if eventCallbacks[eventName] then
		for _, callback in ipairs(eventCallbacks[eventName]) do
			local success, err = pcall(callback);
			if not success then
				print("|cffFF0000NUF:|r Error in " .. eventName .. ": " .. tostring(err));
			end
		end
	end
end

function K.RegisterConfigEvent(eventName, callback)
	if not eventCallbacks[eventName] then
		eventCallbacks[eventName] = {};
	end
	table.insert(eventCallbacks[eventName], callback);
end

-- SafeConvertType
local function SafeConvertType(value, targetType)
	if targetType == "boolean" then
		if type(value) == "string" then
			-- FIX: "false"/"0" deben convertirse a false, no a true
			return value == "true" or value == "1";
		end
		if type(value) == "number" then
			return value ~= 0;
		end
		return not not value;
	elseif targetType == "number" then
		local num = tonumber(value);
		if not num then
			return 0;
		end
		return num;
	elseif targetType == "string" then
		return tostring(value);
	end
	return value;
end

-- LoadConfigFromDB
local function LoadConfigFromDB()
	if configLoaded then 
		return; 
	end
	
	if not NidhausUnitFramesDB then
		NidhausUnitFramesDB = {};
	end
	
	-- Si la DB está vacía, copiar defaults
	if not next(NidhausUnitFramesDB) then
		for key, value in pairs(defaults) do
			NidhausUnitFramesDB[key] = value;
		end
	end
	
	-- Cargar cada valor desde DB o usar default
	for key, defaultValue in pairs(defaults) do
		local savedValue = NidhausUnitFramesDB[key];
		
		if savedValue ~= nil then
			local value = SafeConvertType(savedValue, type(defaultValue));
			C[key] = value;
			
			if type(value) ~= type(savedValue) then
				NidhausUnitFramesDB[key] = value;
			end
		else
			C[key] = defaultValue;
			NidhausUnitFramesDB[key] = defaultValue;
		end
	end
	
	configLoaded = true;
	
	-- DISPARAR EVENTO: Config lista
	FireConfigEvent("CONFIG_LOADED");
end

-- SaveConfig
local function SaveConfig(key, value)
	if not configLoaded then
		return false;
	end
	
	if defaults[key] == nil then 
		return false; 
	end
	
	if value == nil then
		return false;
	end
	
	local actualValue = SafeConvertType(value, type(defaults[key]));
	
	if type(actualValue) ~= type(defaults[key]) then
		return false;
	end
	
	-- Guardar en ambos lugares
	C[key] = actualValue;
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB[key] = actualValue;
	
	-- DISPARAR EVENTO: Config cambiada
	FireConfigEvent("CONFIG_CHANGED");
	
	return true;
end

-- ShowConfig
local function ShowConfig()
	print(L["CFG_HEADER"]);
	
	if not configLoaded then
		print(L["CFG_NOT_LOADED"]);
		return;
	end
	
	print(L["CFG_FORMAT"]);
	print("");
	
	local allMatch = true;
	local keys = {};
	
	for key in pairs(defaults) do
		table.insert(keys, key);
	end
	table.sort(keys);
	
	for _, key in ipairs(keys) do
		local dbValue = NidhausUnitFramesDB[key];
		local cValue = C[key];
		local match = (dbValue == cValue) and (type(dbValue) == type(cValue));
		
		if not match then allMatch = false; end
		
		local status = match and "|cff00FF00OK|r" or "|cffFF0000ERR|r";
		
		print(string.format("%s %-30s DB: %-8s (%s) | C: %-8s (%s)", 
			status,
			key,
			tostring(dbValue),
			type(dbValue),
			tostring(cValue),
			type(cValue)
		));
	end
	

	print("");
	if NidhausUnitFramesDB.positions then
		print(L["CFG_SAVED_POS"]);
		for key, pos in pairs(NidhausUnitFramesDB.positions) do
			if type(pos) == "table" then
				-- FIX: Soportar formato con nombres (FrameDragger) y con índices (legacy)
				local anchor = pos.point or pos[1] or "?";
				local xVal = pos.x or pos[4] or 0;
				local yVal = pos.y or pos[5] or 0;
				print(string.format("  %s: %s at (%.1f, %.1f)", 
					key, tostring(anchor), tonumber(xVal) or 0, tonumber(yVal) or 0));
			else
				print(string.format("  %s: %s", key, tostring(pos)));
			end
		end
	else
		print(L["CFG_NO_SAVED_POS"]);
	end
	
	print("");
	if allMatch then
		print(L["CFG_ALL_SYNC"]);
	else
		print(L["CFG_OUT_OF_SYNC"]);
	end
	print("");
end

-- ResetConfig
local function ResetConfig()
	if not configLoaded then
		return;
	end
	
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	
	for key, value in pairs(defaults) do
		C[key] = value;
		NidhausUnitFramesDB[key] = value;
	end
	
	if NidhausUnitFramesDB.positions then
		NidhausUnitFramesDB.positions = {};
	end
	
	if NidhausUnitFramesDB.ArenaMover then
		NidhausUnitFramesDB.ArenaMover = {
			IsShown = false
		};
	end
	
	print(L["CFG_RESET_OK"]);
	
	FireConfigEvent("CONFIG_RESET");
	-- FIX: También disparar CONFIG_LOADED para que los módulos se re-inicialicen
	-- (la mayoría solo escucha CONFIG_LOADED y CONFIG_CHANGED, no CONFIG_RESET)
	FireConfigEvent("CONFIG_LOADED");
end

-- IsConfigLoaded
local function IsConfigLoaded()
	return configLoaded;
end

-- Exports
K.SaveConfig = SaveConfig;
K.ShowConfig = ShowConfig;
K.ResetConfig = ResetConfig;
K.IsConfigLoaded = IsConfigLoaded;

-- FIX: SaveConfigSilent — guarda sin disparar CONFIG_CHANGED (para batch saves)
-- Usar con FlushConfigChanges al final del batch
function K.SaveConfigSilent(key, value)
	if not configLoaded then return false; end
	if defaults[key] == nil then return false; end
	if value == nil then return false; end
	local actualValue = SafeConvertType(value, type(defaults[key]));
	if type(actualValue) ~= type(defaults[key]) then return false; end
	C[key] = actualValue;
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB[key] = actualValue;
	return true;
end

-- FIX: FlushConfigChanges — dispara CONFIG_CHANGED una sola vez después de batch save
function K.FlushConfigChanges()
	FireConfigEvent("CONFIG_CHANGED");
end

-- =========================================================
-- PROFILE SERIALIZER (Export / Import)
-- =========================================================

-- Serialize a Lua value to a portable string
local function SerializeValue(val)
	local t = type(val);
	if t == "string" then
		return string.format("%q", val);
	elseif t == "number" then
		return tostring(val);
	elseif t == "boolean" then
		return val and "true" or "false";
	elseif t == "table" then
		local parts = {};
		for k, v in pairs(val) do
			local key;
			if type(k) == "string" then
				key = "[" .. string.format("%q", k) .. "]";
			else
				key = "[" .. tostring(k) .. "]";
			end
			table.insert(parts, key .. "=" .. SerializeValue(v));
		end
		return "{" .. table.concat(parts, ",") .. "}";
	else
		return "nil";
	end
end

-- Serialize the full config DB to a copyable string
function K.ExportProfile()
	if not configLoaded or not NidhausUnitFramesDB then
		return nil, "Config not loaded";
	end

	-- Build export table: all defaults keys + positions + modules + ArenaMover
	local exportData = {};

	for key in pairs(defaults) do
		if NidhausUnitFramesDB[key] ~= nil then
			exportData[key] = NidhausUnitFramesDB[key];
		end
	end

	if NidhausUnitFramesDB.positions then
		exportData.positions = NidhausUnitFramesDB.positions;
	end
	if NidhausUnitFramesDB.Modules then
		exportData.Modules = NidhausUnitFramesDB.Modules;
	end
	if NidhausUnitFramesDB.ArenaMover then
		exportData.ArenaMover = NidhausUnitFramesDB.ArenaMover;
	end

	return "return " .. SerializeValue(exportData);
end

-- Deserialize a string back to a table (sandboxed)
function K.ImportProfile(str)
	if not str or str == "" then
		return false, "Empty string";
	end

	local func, err = loadstring(str);
	if not func then
		return false, "Syntax error: " .. tostring(err);
	end

	-- Sandbox: block access to all globals
	setfenv(func, {});

	local ok, result = pcall(func);
	if not ok then
		return false, "Execution error: " .. tostring(result);
	end
	if type(result) ~= "table" then
		return false, "Invalid data (expected table)";
	end

	-- Validate: at least some known keys exist
	local knownCount = 0;
	for key in pairs(defaults) do
		if result[key] ~= nil then knownCount = knownCount + 1; end
	end
	if knownCount < 3 then
		return false, "Data doesn't look like a NUF profile (too few known keys)";
	end

	-- Apply: overwrite settings
	for key, defaultValue in pairs(defaults) do
		if result[key] ~= nil then
			local value = SafeConvertType(result[key], type(defaultValue));
			NidhausUnitFramesDB[key] = value;
			C[key] = value;
		end
	end

	-- Overwrite positions if present
	if result.positions and type(result.positions) == "table" then
		NidhausUnitFramesDB.positions = result.positions;
	end

	-- Overwrite modules if present
	if result.Modules and type(result.Modules) == "table" then
		NidhausUnitFramesDB.Modules = result.Modules;
	end

	-- Overwrite ArenaMover if present
	if result.ArenaMover and type(result.ArenaMover) == "table" then
		NidhausUnitFramesDB.ArenaMover = result.ArenaMover;
	end

	return true;
end

-- Deep copy helper (for future profile copy features)
function K.DeepCopy(orig)
	if type(orig) ~= "table" then return orig; end
	local copy = {};
	for k, v in pairs(orig) do
		copy[K.DeepCopy(k)] = K.DeepCopy(v);
	end
	return copy;
end

-- SyncConfigToDB
local function SyncConfigToDB()
	if not configLoaded then return; end
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	for key in pairs(defaults) do
		if C[key] ~= nil then
			NidhausUnitFramesDB[key] = C[key];
		end
	end
end

-- ADDON_LOADED
local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("ADDON_LOADED");
initFrame:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" and addonName == AddOnName then
		self:UnregisterEvent("ADDON_LOADED");
		
		local success, err = pcall(LoadConfigFromDB);
		if not success then
			-- FIX: Imprimir el error para que el usuario sepa que su config no cargó
			print("|cffFF0000NUF:|r Config load error: " .. tostring(err));
			for key, value in pairs(defaults) do
				C[key] = value;
			end
			configLoaded = true;
			-- FIX: Disparar CONFIG_LOADED incluso si pcall falló.
			-- Sin esto, NINGÚN sistema se inicializa (ArenaFrame, NewPartyFrame, etc.)
			FireConfigEvent("CONFIG_LOADED");
		end
	end
end);

-- FIX PERF: Only sync on PLAYER_LOGOUT (safety net).
-- SaveConfig() already writes to both C[] and NidhausUnitFramesDB in real-time.
-- PLAYER_LEAVING_WORLD fires on EVERY loading screen (instance, BG, zone change),
-- running a full iteration of ~45 keys each time for no benefit.
local saveFrame = CreateFrame("Frame");
saveFrame:RegisterEvent("PLAYER_LOGOUT");
saveFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGOUT" and configLoaded then
		SyncConfigToDB();
	end
end);