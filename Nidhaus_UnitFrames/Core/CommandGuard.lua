local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local GUARDED = {
	{ key = "ARENACALC",     module = "ArenaPointsCalc"      },
	{ key = "NUFARROWCOUNT", module = "ArrowCount",     optional = true },
	{ key = "NUFAUTOSHOT",   module = "AutoShotTimer",  optional = true },
	{ key = "HIDEACTIONBAR", module = "HideActionBarTextures"},
	{ key = "HCB",           module = "HideChatButton"       },
	{ key = "NUFPETBUFFS",   module = "HunterPetBuffs", optional = true },
	{ key = "NUFSWING",      module = "MeleeSwingTimer"      },
	{ key = "NUFMINIMAP",    module = "MinimapIconToggle"    },
	{ key = "PARTYBUFFS",    module = "PartyBuffs"           },
	{ key = "NUFPOWERBAR",   module = "PowerBar"             },
	{ key = "NUFCOMBO",      module = "ComboWatch",     optional = true },
	{ key = "GT",            module = "GargoyleTracker", optional = true },
	{ key = "NICEDAMAGE",    module = "NiceDamage"           },
	{ key = "DTSU",          module = "DTSU"                 },
	{ key = "PALADINICD",    module = "PaladinICD",     optional = true },
	{ key = "PARTYPETFRAME", module = "PartyPetFrame"        },
	{ key = "NUFSACREDSHIELD", module = "SacredShield",        optional = true },
	{ key = "NUFSSTRACKER",    module = "SacredShieldTracker", optional = true },
	{ key = "NUFSEDUCTION",    module = "SeductionAlert",      optional = true },

	{ key = "shieldwatch",   module = "ShieldWatch", optional = true },

	{ key = "NUFPALAURAS",   module = { "PaladinAuras", "TurnEvil" }, optional = true },
};

local function AnyEnabled(mod)
	if not K.IsModuleEnabled then return true; end
	if type(mod) == "table" then
		for _, id in ipairs(mod) do
			if K.IsModuleEnabled(id) then return true; end
		end
		return false;
	end
	return K.IsModuleEnabled(mod) and true or false;
end

local function ModuleLabel(mod)
	local id = (type(mod) == "table") and mod[1] or mod;
	local m = K.Modules and K.Modules[id];
	return (m and m.name) or id;
end

local wrappedFns = {};

local function GuardOne(entry)
	local handler = SlashCmdList and SlashCmdList[entry.key];
	if type(handler) ~= "function" then return false; end
	if wrappedFns[handler] then return true; end

	local wrapped = function(...)
		if not AnyEnabled(entry.module) then
			DEFAULT_CHAT_FRAME:AddMessage("|cff4FC3F7[NUF]|r " .. string.format(
				L["CMD_MODULE_OFF"]
					or "%s is turned off. Enable it in the options panel to use its commands.",
				ModuleLabel(entry.module)));
			return;
		end
		return handler(...);
	end;
	wrappedFns[wrapped] = true;

	SlashCmdList[entry.key] = wrapped;
	return true;
end

local function NotLoadedYet(mod)
	if not K.IsModuleLoaded then return false; end
	local id = (type(mod) == "table") and mod[1] or mod;
	return K.Modules and K.Modules[id] ~= nil and not K.IsModuleLoaded(id);
end

local function GuardAll()
	local ok, total, miss = 0, 0, {};
	for _, entry in ipairs(GUARDED) do
		if GuardOne(entry) then
			ok    = ok + 1;
			total = total + 1;
		elseif entry.optional or NotLoadedYet(entry.module) then

		else
			total = total + 1;
			miss[#miss + 1] = entry.key;
		end
	end

	K._cmdGuardOK    = ok;
	K._cmdGuardTotal = total;
	K._cmdGuardMiss  = miss;
end

local guardReady = false;
function K.GuardModuleCommands()
	if guardReady then GuardAll(); end
end

local guard = CreateFrame("Frame");
guard:RegisterEvent("PLAYER_LOGIN");
guard:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");
	guardReady = true;
	GuardAll();
end);
