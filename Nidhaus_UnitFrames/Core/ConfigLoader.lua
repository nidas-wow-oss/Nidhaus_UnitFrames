local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local LOD = "Nidhaus_UnitFrames_Config";

local function LoadPanel()
	if IsAddOnLoaded and IsAddOnLoaded(LOD) then return true; end
	if not LoadAddOn then return false; end

	if K.LoadArenaModules then pcall(K.LoadArenaModules); end

	if K.LoadAllModuleBodies then pcall(K.LoadAllModuleBodies); end

	local loaded, reason = LoadAddOn(LOD);
	if loaded then return true; end

	local why = reason and (_G["ADDON_" .. reason] or reason) or "?";
	print("|cffFF5555NUF:|r " .. (L["PANEL_LOAD_FAIL"]
		or "Could not load the options panel") .. " (" .. tostring(why) .. ").");
	print("|cffFF5555NUF:|r " .. (L["PANEL_LOAD_HINT"]
		or "Check that the Nidhaus_UnitFrames_Config folder sits next to the addon folder and is enabled in the addon list."));
	return false;
end

K.LoadConfigPanel = LoadPanel;

local shim;
shim = function()
	if not LoadPanel() then return; end
	if K.ToggleOptionsPanel and K.ToggleOptionsPanel ~= shim then
		K.ToggleOptionsPanel();
	end
end
K.ToggleOptionsPanel = shim;

local slashShim;
slashShim = function(msg)
	if not LoadPanel() then return; end
	local real = SlashCmdList["NUFCONFIG"];
	if real and real ~= slashShim then real(msg); end
end

SLASH_NUFCONFIG1 = "/nufconfig";
SLASH_NUFCONFIG2 = "/nufoptions";
SlashCmdList["NUFCONFIG"] = slashShim;
