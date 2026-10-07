local AddOnName, ns = ...;
local K, C, L = unpack(ns);
















local enabled     = false;
local forceHidden = false;
local toggleBtn;










local retryAcc, retryCount = 0, 0;
local retry = CreateFrame("Frame");
retry:Hide();




local PROTECTED = {
	["Minimap"]                = true,
	["MinimapBackdrop"]        = true,
	["MinimapCluster"]         = true,
	["MinimapBorder"]          = true,
	["MinimapBorderTop"]       = true,
	["MinimapNorthTag"]        = true,
	["MinimapCompassTexture"]  = true,
	["NUF_MinimapIconToggle"]  = true,



	["NUF_MinimapSquareBorder"] = true,






	["NUF_MinimapThinBorder"]   = true,

	["TimeManagerClockButton"]  = true,
	["TimeManagerClockTicker"]  = true,



	["NidhausUF_MinimapButton"] = true,




	["MinimapZoomIn"]        = true,
	["MinimapZoomOut"]       = true,
	["GameTimeFrame"]        = true,
	["MiniMapWorldMapButton"]= true,
	["FeedbackUIButton"]     = true,


	["MiniMapMailFrame"]           = true,
	["MiniMapMailBorder"]          = true,
	["MiniMapVoiceChatFrame"]      = true,
	["MiniMapBattlefieldFrame"]    = true,
	["MiniMapLFGFrame"]            = true,
	["MiniMapInstanceDifficulty"]  = true,
	["MinimapZoneTextButton"]      = true,



	["MiniMapTrackingFrame"]       = true,
	["MiniMapTracking"]            = true,
	["MiniMapTrackingButton"]      = true,
	["MiniMapTrackingIcon"]        = true,
	["MiniMapTrackingBorder"]      = true,
	["MiniMapTrackingButtonBorder"]= true,
	["MiniMapTrackingBackground"]  = true,
};


















local savedShown = {};




local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.MinimapIcons then
		NidhausUnitFramesDB.MinimapIcons = {};
	end
	return NidhausUnitFramesDB.MinimapIcons;
end




local function CollectTargets()
	local list = {};


	if Minimap then
		for _, child in ipairs({ Minimap:GetChildren() }) do
			local n = child.GetName and child:GetName();
			if not (n and PROTECTED[n]) and child ~= toggleBtn then
				table.insert(list, child);
			end
		end
	end


	if MinimapCluster then
		for _, child in ipairs({ MinimapCluster:GetChildren() }) do
			local n = child.GetName and child:GetName();
			if not (n and PROTECTED[n]) and child ~= Minimap and child ~= toggleBtn then
				table.insert(list, child);
			end
		end
	end

	return list;
end













local hoverOver     = false;
local hoverTargets  = nil;
local HOVER_MARGIN  = 24;



local function Mode()
	local m = C.MinimapAddonIcons;
	if m == "Never" or m == "Hover" then return m; end
	return "Always";
end

local function HoverMode()
	return Mode() == "Hover";
end




local function DesiredVisible()
	if Mode() == "Never" then return false; end
	if forceHidden then return false; end
	if HoverMode() then return hoverOver; end
	return true;
end

local function ApplyState()
	if not DesiredVisible() then



		local targets = CollectTargets();
		for _, f in ipairs(targets) do
			if f:IsShown() and savedShown[f] == nil then
				savedShown[f] = true;
				f:Hide();
			end
		end
	else


		for f in pairs(savedShown) do
			if f.Show then f:Show(); end
		end
		wipe(savedShown);
	end



	if toggleBtn then
		if forceHidden then
			toggleBtn.icon:SetTexture("Interface\\Buttons\\UI-PlusButton-Up");
		else
			toggleBtn.icon:SetTexture("Interface\\Buttons\\UI-MinusButton-Up");
		end
	end
end

local function MouseIsNearMinimap()
	if not Minimap then return false; end
	if MouseIsOver(Minimap, HOVER_MARGIN, -HOVER_MARGIN, -HOVER_MARGIN, HOVER_MARGIN) then
		return true;
	end


	if hoverTargets then
		for _, f in ipairs(hoverTargets) do
			if f.IsShown and f:IsShown() and MouseIsOver(f) then return true; end
		end
	end
	return false;
end

local hoverDriver = CreateFrame("Frame");
local hoverAcc = 0;
hoverDriver:Hide();
hoverDriver:SetScript("OnUpdate", function(self, elapsed)
	hoverAcc = hoverAcc + elapsed;
	if hoverAcc < 0.2 then return; end
	hoverAcc = 0;

	local over = MouseIsNearMinimap();
	if over ~= hoverOver then
		hoverOver = over;
		if over then hoverTargets = CollectTargets(); end
		ApplyState();
	end
end);



function K.ApplyMinimapIconState()
	if HoverMode() then
		hoverTargets = CollectTargets();
		hoverOver = MouseIsNearMinimap();
		hoverDriver:Show();
	else
		hoverDriver:Hide();
		hoverOver = false;
	end
	ApplyState();
end



K.ApplyMinimapAddonIcons  = function() K.ApplyMinimapIconState(); end
K.ApplyMinimapIconsOnHover = function() K.ApplyMinimapIconState(); end


local bootstrap = CreateFrame("Frame");
bootstrap:RegisterEvent("PLAYER_ENTERING_WORLD");
bootstrap:SetScript("OnEvent", function()
	forceHidden = DB().hidden and true or false;
	K.ApplyMinimapIconState();
	retryAcc, retryCount = 0, 0;
	retry:Show();
end);

local function SetHidden(state)
	forceHidden = state and true or false;
	DB().hidden = forceHidden;
	ApplyState();
end




local function CreateToggleButton()
	if toggleBtn then return toggleBtn; end
	if not Minimap then return nil; end

	toggleBtn = CreateFrame("Button", "NUF_MinimapIconToggle", Minimap);
	toggleBtn:SetSize(16, 16);











	toggleBtn:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -4, 4);
	toggleBtn:SetFrameStrata("MEDIUM");
	toggleBtn:SetFrameLevel(Minimap:GetFrameLevel() + 10);

	toggleBtn.bg = toggleBtn:CreateTexture(nil, "BACKGROUND");
	toggleBtn.bg:SetAllPoints();
	toggleBtn.bg:SetTexture(0, 0, 0, 0.55);

	toggleBtn.icon = toggleBtn:CreateTexture(nil, "ARTWORK");
	toggleBtn.icon:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0);
	toggleBtn.icon:SetSize(14, 14);
	toggleBtn.icon:SetTexture("Interface\\Buttons\\UI-MinusButton-Up");

	toggleBtn:SetScript("OnClick", function()
		SetHidden(not forceHidden);
	end);

	toggleBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(L["MINIMAP_TOGGLE_TITLE"] or "Minimap Icons", 1, 1, 1);
		GameTooltip:AddLine(L["MINIMAP_TOGGLE_TIP"]
			or "Click to hide or show every minimap icon (zoom, clock, addons).",
			nil, nil, nil, true);
		GameTooltip:Show();
	end);
	toggleBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	return toggleBtn;
end




retry:SetScript("OnUpdate", function(self, elapsed)
	retryAcc = retryAcc + elapsed;
	if retryAcc < 1 then return; end
	retryAcc = 0;
	retryCount = retryCount + 1;


	ApplyState();
	if retryCount >= 5 then self:Hide(); end
end);

local events = CreateFrame("Frame");
events:SetScript("OnEvent", function()
	if not enabled then return; end
	CreateToggleButton();
	if toggleBtn then toggleBtn:Show(); end
end);

SLASH_NUFMINIMAP1 = "/nufminimap";
SlashCmdList["NUFMINIMAP"] = function()
	if not enabled then
		print("|cff4FC3F7NUF:|r " .. (L["MINIMAP_TOGGLE_DISABLED"]
			or "Enable the Minimap Icon Toggle module first."));
		return;
	end
	SetHidden(not forceHidden);
end




K.RegisterModule("MinimapIconToggle", {
	name    = L["MOD_MINIMAP_TOGGLE"] or "Minimap Icon Toggle",
	desc    = L["MOD_MINIMAP_TOGGLE_DESC"] or "Button on the minimap corner that hides or shows every minimap icon.",
	default = false,






	hideFromModulesTab = true,
	configLabel = L["BTN_MODULE_TOGGLE"] or "Toggle",
	configFunc = function() SetHidden(not forceHidden); end,


	onEnable = function()
		enabled = true;
		CreateToggleButton();
		if toggleBtn then toggleBtn:Show(); end
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		if toggleBtn then toggleBtn:Hide(); end


		if forceHidden then SetHidden(false); end
	end,
});
