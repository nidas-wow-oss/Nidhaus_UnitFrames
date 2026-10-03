local AddOnName, ns = ...;
local K, C, L = unpack(ns);



local defaults = {

	classColor = false,
	statusbarBackdrop = true,
	HealthPercentage = false,
	CastingTimers = true,
	

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
	PetFrameScale = 1.0,
	

	NewPartyFrame = false,


	PartyFrameStyle = "Default",
	PartyTargetsEnabled = false,
	PartyFrameOn = true,




	PartyShowPetFrames = true,



	PartyPetArenaOnly = true,
	PartyFrameScale = 1.0,
	PartyMemberFrameSpacing = 0,
	PartyMode3v3 = false,

	Party3v3Scale1 = 1.5,
	Party3v3Scale2 = 1.5,
	Party3v3Scale3 = 1.3,
	Party3v3Scale4 = 1.3,
	BossTargetFrameSpacing = 0,
	ArenaFrameOn = true,
	ArenaFrameScale = 1.5,
	ArenaCustomTexture = true,
	ArenaFrame_Trinkets = true,


	PartyTrinketsEnabled = false,
	PartyTrinketSize = 20,
	ArenaFrame_Trinket_Voice = false,
	ArenaMirrorMode = false,
	ArenaFrameSpacing = 0,


	ArenaFrameStyle = "Custom",
	ArenaBlizzardClassColor = false,


	ArenaFlatMode = false,

	ArenaFlatWidth = 100,
	ArenaFlatHealthBarHeight = 20,
	ArenaFlatPowerBarHeight = 8,
	ArenaFlatHealthFontSize = 9,
	ArenaFlatPowerFontSize = 9,
	ArenaFlatBarTexture = "",
	ArenaFlatMirrored = false,
	ArenaFlatStatusText = true,


	ArenaPetFrameShow = false,
	ArenaFlatPetStyle = true,



	ArenaToTScale = 1.0,
	ArenaToTClassIcon = false,
	ArenaToTMirrored = false,
	ArenaToTSquare = false,


	ArenaCastBarEnable = false,
	ArenaCastBarScale = 1.0,
	ArenaCastBarWidth = 80,




	CastBarPWEnabled = false,
	CastBarPWIcon = true,
	CastBarPWIconSize = 30,
	CastBarPWDark = true,
	CastBarPWScale = 1.2,
	CastBarPWTarget = true,
	CastBarPWFocus = true,





	TooltipArenaExp = false,
	TooltipTalents = false,
	TooltipQualityBorder = false,
	TooltipIcons = false,


	AuraCastBy = false,



	AuraBordersEnabled = false,
	AuraBordersPurge = true,


	darkFrames = false,
	UnitFrameCustomTexture = false,
	AsuriFrames = false,

	ShowCurrentValueOnly = false,
	BigStatusText = false,
	BigTextCustomSize = false,
	BigTextHealthSize = 12,
	BigTextManaSize = 10,
	PartyHideHealthManaText = false,
	PartyFontSize = 0,
	PartyFontOutline = "OUTLINE",





	PCB_Enabled = false,


	ArenaCountDown = true,
	ShadowSightTimer = true,
	ArenaDR = false,
	ArenaDRSize = 22,
	ArenaDRSpacing = 2,
	ArenaDRGrow = "AUTO",
	ArenaDRBorder = true,
	ArenaDRText = true,
	ArenaDRTimer = true,
	ArenaDRClassOnly = false,
	ArenaDRHideCats = "",
	ArenaDoTWarn = false,
	ArenaDoTSize = 16,
	ArenaDoTSpacing = 2,
	ArenaDoTMax = 3,
	ArenaDoTGrow = "AUTO",
	ArenaDoTLabel = true,
	ArenaDoTBorder = true,
	AutoSellGray = true,
	AutoRepair = true,
	ErrorHideInCombat = true,
	BlockDuels = false,

	TabBinderEnabled = false,


	ArenaDalaranPipeTimer = false,
	ArenaRoVPillarTimer = false,
	ArenaEndTimer = false,


	HideKeybindText = false,
	HideMacroText = false,



	MoveGridStep = 10,


	AuraIconsPerRow   = 8,
	SideBarsHover     = false,
	MinimapSquare     = false,

	MinimapBorderStyle = "Default",
	MinimapHideZone   = false,
	MinimapHideZoneBG = false,
	MinimapHideAddonIcons = false,
	MinimapHideClock  = false,
	MinimapHideZoom   = false,
	MinimapHideCalendar = false,
	MinimapHideWorldMap = false,
	MinimapWheelZoom  = true,
	MinimapIconsOnHover = false,
	MinimapAddonIcons = "Always",




	MinimapScale      = 1.0,


	MageWaterEleTimer  = true,
	MageMirrorTimer    = true,
	MageIcyFrame       = false,
	pwFrames           = false,
	PaladinICDKeepVisible = false,
	SwingTimerBorderStyle  = "Tooltip",
	AutoShotBorderStyle    = "Tooltip",
	ClassTimersLocked  = false,
	ComboWatchLocked   = false,
	PetBuffsLocked     = false,
	EnemySpellAlertLocked = false,
	PetBuffsIconSize   = 32,
	PowerBarCombatOnly = false,
	PowerBarShowPercent = false,
	PowerBarHideText = false,
	PowerBarShowHealth = false,
	PowerBarHealthGradient = true,
	PowerBarHideWhenFull = false,
	PowerBarHealthClassColor = false,
	PowerBarShowAuras = false,
	PowerBarAuraPos = "RIGHT",


	UnitNameColorMode = "Default",
	UnitNameBorder    = "None",




	ChatCopyEnabled = true,
	ChatClickableURLs = true,


	UnifyActionBars = false,


	ActionBarButtonSpace = 6,
	MiniBarEnabled = false,

	MiniBarHideBackground = false,
	HideGryphons = false,
	ActionBarScale = 1.0,



	MiniBarExtrasScale = 1.0,
	ShowBagPackTexture = true,


	LortiUI_PlayerTargetFocus = true,
	LortiUI_Party             = true,
	LortiUI_PartyTargets      = true,
	LortiUI_PartyPet          = true,
	LortiUI_Arena             = true,
	LortiUI_ActionBars        = true,
	LortiUI_Minimap           = true,
};

local configLoaded = false;


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




K._settingCheckboxes = K._settingCheckboxes or {};

function K.RegisterSettingCheckbox(setting, cb)
	if not setting or not cb then return; end
	if not K._settingCheckboxes[setting] then K._settingCheckboxes[setting] = {}; end
	table.insert(K._settingCheckboxes[setting], cb);
end

function K.RefreshSettingCheckboxes(setting)
	local list = K._settingCheckboxes[setting];
	if not list then return; end
	local value = C[setting];
	if type(value) == "number" then value = (value == 1); end
	for _, cb in ipairs(list) do
		if cb.SetChecked then






			if cb.nufInverted then
				cb:SetChecked(value ~= true);
			else
				cb:SetChecked(value == true);
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


local function SafeConvertType(value, targetType)
	if targetType == "boolean" then
		if type(value) == "string" then

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


local function LoadConfigFromDB()
	if configLoaded then 
		return; 
	end
	
	if not NidhausUnitFramesDB then
		NidhausUnitFramesDB = {};
	end
	

	if not next(NidhausUnitFramesDB) then
		for key, value in pairs(defaults) do
			NidhausUnitFramesDB[key] = value;
		end
	end
	

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
	



	local DEAD = {
		UnitNameBorder   = { Mono = "None", OutMono = "None" },
		PartyFontOutline = { MONOCHROME = "OUTLINE", ["OUTLINE,MONOCHROME"] = "OUTLINE" },
	};
	for key, map in pairs(DEAD) do
		local fixed = map[C[key]];
		if fixed then
			C[key] = fixed;
			NidhausUnitFramesDB[key] = fixed;
		end
	end

	configLoaded = true;
	

	FireConfigEvent("CONFIG_LOADED");
end


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
	

	C[key] = actualValue;
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB[key] = actualValue;
	

	if K.RefreshSettingCheckboxes then K.RefreshSettingCheckboxes(key); end


	FireConfigEvent("CONFIG_CHANGED");
	
	return true;
end


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
		
		local status = match and "|cffFFD100OK|r" or "|cffFF0000ERR|r";
		
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






















local PRESERVE_ON_RESET = {
	CharProfiles = true,
	SlotProfiles = true,
	SlotBackup   = true,
};

local function ResetConfig()
	if not configLoaded then
		return;
	end

	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end


	local guardado = {};
	for key in pairs(PRESERVE_ON_RESET) do
		guardado[key] = NidhausUnitFramesDB[key];
	end


	for key in pairs(NidhausUnitFramesDB) do
		NidhausUnitFramesDB[key] = nil;
	end


	for key, value in pairs(guardado) do
		NidhausUnitFramesDB[key] = value;
	end


	for key, value in pairs(defaults) do
		C[key] = value;
		NidhausUnitFramesDB[key] = value;
	end




	if PartyBuffsDB   ~= nil then PartyBuffsDB   = {}; end
	if NiceDamageDB   ~= nil then NiceDamageDB   = {}; end
	if DTSU_DB        ~= nil then DTSU_DB        = {}; end
	if PaladinICD_DB  ~= nil then PaladinICD_DB  = {}; end

	print(L["CFG_RESET_OK"]);
	
	FireConfigEvent("CONFIG_RESET");


	FireConfigEvent("CONFIG_LOADED");
end


local function IsConfigLoaded()
	return configLoaded;
end


K.SaveConfig = SaveConfig;







function K.GetConfigDefault(key)
	return defaults[key];
end
K.ShowConfig = ShowConfig;
K.ResetConfig = ResetConfig;
K.IsConfigLoaded = IsConfigLoaded;



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


function K.FlushConfigChanges()
	FireConfigEvent("CONFIG_CHANGED");
end






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


function K.ExportProfile()
	if not configLoaded or not NidhausUnitFramesDB then
		return nil, "Config not loaded";
	end


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





	if NidhausUnitFramesDB.globalPos then
		exportData.globalPos = NidhausUnitFramesDB.globalPos;
	end

	return "return " .. SerializeValue(exportData);
end


function K.ImportProfile(str)
	if not str or str == "" then
		return false, "Empty string";
	end

	local func, err = loadstring(str);
	if not func then
		return false, "Syntax error: " .. tostring(err);
	end


	setfenv(func, {});

	local ok, result = pcall(func);
	if not ok then
		return false, "Execution error: " .. tostring(result);
	end
	if type(result) ~= "table" then
		return false, "Invalid data (expected table)";
	end


	local knownCount = 0;
	for key in pairs(defaults) do
		if result[key] ~= nil then knownCount = knownCount + 1; end
	end
	if knownCount < 3 then
		return false, "Data doesn't look like a NUF profile (too few known keys)";
	end


	for key, defaultValue in pairs(defaults) do
		if result[key] ~= nil then
			local value = SafeConvertType(result[key], type(defaultValue));
			NidhausUnitFramesDB[key] = value;
			C[key] = value;
		end
	end


	if result.positions and type(result.positions) == "table" then
		NidhausUnitFramesDB.positions = result.positions;
	end


	if result.Modules and type(result.Modules) == "table" then
		NidhausUnitFramesDB.Modules = result.Modules;
	end


	if result.ArenaMover and type(result.ArenaMover) == "table" then
		NidhausUnitFramesDB.ArenaMover = result.ArenaMover;
	end




	if result.globalPos and type(result.globalPos) == "table" then
		NidhausUnitFramesDB.globalPos = result.globalPos;
	elseif type(NidhausUnitFramesDB.globalPos) == "table" and K.GetMovablesForSetting then
		for key in pairs(defaults) do
			local movs = (result[key] ~= nil) and K.GetMovablesForSetting(key);
			if movs then
				for _, mk in ipairs(movs) do
					for gk, pos in pairs(NidhausUnitFramesDB.globalPos) do

						local base = string.match(gk, "^([^#]+)") or gk;
						if base == mk and type(pos) == "table" then pos.scale = nil; end
					end
				end
			end
		end
	end

	return true;
end














function K.GetCharProfileKey()
	local name  = UnitName("player") or "Unknown";
	local realm = GetRealmName() or "Unknown";
	local realmType = tonumber(GetCVar("realmType")) or 0;
	local tag = "";
	if realmType == 1 then tag = " [PvP only]";
	elseif realmType == 4 then tag = " [RP]";
	elseif realmType == 6 then tag = " [RP-PvP]"; end
	return name .. " - " .. realm .. tag;
end

function K.SaveCurrentCharProfile()
	local data, err = K.ExportProfile();
	if not data then return false, err; end
	if not NidhausUnitFramesDB.CharProfiles then NidhausUnitFramesDB.CharProfiles = {}; end
	local key = K.GetCharProfileKey();
	NidhausUnitFramesDB.CharProfiles[key] = data;
	return true, key;
end

local charProfileSaver = CreateFrame("Frame");
charProfileSaver:RegisterEvent("PLAYER_LOGIN");
charProfileSaver:RegisterEvent("PLAYER_LOGOUT");
charProfileSaver:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGOUT" then
		pcall(K.SaveCurrentCharProfile);
		return;
	end
	self:UnregisterEvent("PLAYER_LOGIN");

	self:SetScript("OnUpdate", function(s)
		s:SetScript("OnUpdate", nil);
		pcall(K.SaveCurrentCharProfile);
	end);
end);


function K.DeepCopy(orig)
	if type(orig) ~= "table" then return orig; end
	local copy = {};
	for k, v in pairs(orig) do
		copy[K.DeepCopy(k)] = K.DeepCopy(v);
	end
	return copy;
end


local function SyncConfigToDB()
	if not configLoaded then return; end
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	for key in pairs(defaults) do
		if C[key] ~= nil then
			NidhausUnitFramesDB[key] = C[key];
		end
	end
end


local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("ADDON_LOADED");
initFrame:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" and addonName == AddOnName then
		self:UnregisterEvent("ADDON_LOADED");
		
		local success, err = pcall(LoadConfigFromDB);
		if not success then

			print("|cffFF0000NUF:|r Config load error: " .. tostring(err));
			for key, value in pairs(defaults) do
				C[key] = value;
			end
			configLoaded = true;


			FireConfigEvent("CONFIG_LOADED");
		end
	end
end);





local saveFrame = CreateFrame("Frame");
saveFrame:RegisterEvent("PLAYER_LOGOUT");
saveFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGOUT" and configLoaded then
		SyncConfigToDB();
	end
end);