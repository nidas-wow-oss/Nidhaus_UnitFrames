local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local ARENA = "Nidhaus_UnitFrames_Arena";
local tried = false;

function K.AreArenaModulesLoaded()
	if IsAddOnLoaded then return IsAddOnLoaded(ARENA) and true or false; end
	return false;
end

function K.LoadArenaModules()
	if K.AreArenaModulesLoaded() then return true; end
	if not LoadAddOn then return false; end
	local loaded, reason = LoadAddOn(ARENA);
	if loaded then return true; end
	if not tried then
		tried = true;
		local why = reason and (_G["ADDON_" .. reason] or reason) or "?";
		print("|cffFF5555NUF:|r " .. (L["ARENA_LOAD_FAIL"]
			or "Couldn't load the arena modules") .. " (" .. tostring(why) .. ").");
		print("|cffFF5555NUF:|r " .. (L["ARENA_LOAD_HINT"]
			or "Check that the Nidhaus_UnitFrames_Arena folder sits next to the addon's folder and is enabled in the AddOns list."));
	end
	return false;
end

local watch = CreateFrame("Frame");
watch:RegisterEvent("PLAYER_ENTERING_WORLD");
watch:RegisterEvent("ADDON_LOADED");
watch:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then

		if arg1 == "Blizzard_ArenaUI" then K.LoadArenaModules(); end
		return;
	end

	local _, itype = IsInInstance();
	if itype == "arena" then K.LoadArenaModules(); end
end);

local function Shim(key, ...)
	local names = { ... };
	for i, cmd in ipairs(names) do
		_G["SLASH_" .. key .. i] = cmd;
	end
	local stub;
	stub = function(msg)
		if not K.LoadArenaModules() then return; end
		local real = SlashCmdList[key];
		if real and real ~= stub then real(msg); end
	end
	SlashCmdList[key] = stub;
end

Shim("NUFDR", "/nufdr");
Shim("NUFDOT", "/nufdot");
Shim("NUFARENATIMERS", "/nuftimers");
