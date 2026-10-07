local AddOnName, ns = ...;
local K, C, L = unpack(ns);
























local GUARDED = {
	{ key = "ARENACALC",     module = "ArenaPointsCalc"      },
	{ key = "NUFARROWCOUNT", module = "ArrowCount"           },
	{ key = "NUFAUTOSHOT",   module = "AutoShotTimer"        },
	{ key = "HIDEACTIONBAR", module = "HideActionBarTextures"},
	{ key = "HCB",           module = "HideChatButton"       },
	{ key = "NUFPETBUFFS",   module = "HunterPetBuffs"       },
	{ key = "NUFSWING",      module = "MeleeSwingTimer"      },
	{ key = "NUFMINIMAP",    module = "MinimapIconToggle"    },
	{ key = "PARTYBUFFS",    module = "PartyBuffs"           },
	{ key = "NUFPOWERBAR",   module = "PowerBar"             },
	{ key = "NUFCOMBO",      module = "ComboWatch"           },
	{ key = "GT",            module = "GargoyleTracker"      },
	{ key = "NICEDAMAGE",    module = "NiceDamage"           },
	{ key = "DTSU",          module = "DTSU"                 },
	{ key = "PALADINICD",    module = "PaladinICD"           },
	{ key = "PARTYPETFRAME", module = "PartyPetFrame"        },




	{ key = "shieldwatch",   module = "ShieldWatch", optional = true },




	{ key = "NUFPALAURAS",   module = { "PaladinAuras", "TurnEvil" } },
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

local guard = CreateFrame("Frame");
guard:RegisterEvent("PLAYER_LOGIN");
guard:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");

	local ok, total, miss = 0, 0, {};
	for _, entry in ipairs(GUARDED) do
		if GuardOne(entry) then
			ok    = ok + 1;
			total = total + 1;
		elseif entry.optional then

		else
			total = total + 1;
			miss[#miss + 1] = entry.key;
		end
	end

	K._cmdGuardOK    = ok;
	K._cmdGuardTotal = total;
	K._cmdGuardMiss  = miss;
end);

