local AddOnName, ns = ...;
local K, C, L = unpack(ns);
















local ROUND_MASK  = "Interface\\CharacterFrame\\TempPortraitAlphaMask";
local SQUARE_MASK = "Interface\\ChatFrame\\ChatFrameBackground";

local squareBorder;




local function GetSquareBorder()
	if squareBorder then return squareBorder; end
	if not Minimap then return nil; end

	squareBorder = CreateFrame("Frame", "NUF_MinimapSquareBorder", Minimap);
	squareBorder:SetPoint("TOPLEFT",     Minimap, "TOPLEFT",     -3,  3);
	squareBorder:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT",  3, -3);
	squareBorder:SetFrameLevel(Minimap:GetFrameLevel() + 2);


	if _G.NUF_SAFE then
		squareBorder:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 12,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		});
		squareBorder:SetBackdropBorderColor(0.55, 0.55, 0.55, 0.9);
		squareBorder:Hide();
		return squareBorder;
	end














	local THICK = 3;
	local COLOR = { 0.04, 0.04, 0.04, 1 };
	local function MakeEdge()
		local t = squareBorder:CreateTexture(nil, "BORDER");
		t:SetTexture("Interface\\Buttons\\WHITE8x8");
		t:SetVertexColor(unpack(COLOR));
		return t;
	end
	local top = MakeEdge();
	top:SetPoint("TOPLEFT", 0, 0);   top:SetPoint("TOPRIGHT", 0, 0);      top:SetHeight(THICK);
	local bottom = MakeEdge();
	bottom:SetPoint("BOTTOMLEFT", 0, 0); bottom:SetPoint("BOTTOMRIGHT", 0, 0); bottom:SetHeight(THICK);
	local left = MakeEdge();
	left:SetPoint("TOPLEFT", 0, 0);  left:SetPoint("BOTTOMLEFT", 0, 0);   left:SetWidth(THICK);
	local right = MakeEdge();
	right:SetPoint("TOPRIGHT", 0, 0); right:SetPoint("BOTTOMRIGHT", 0, 0); right:SetWidth(THICK);

	squareBorder:Hide();
	return squareBorder;
end








function GetMinimapShape()
	if _G.NUF_SAFE then return "ROUND"; end
	return (C and C.MinimapSquare) and "SQUARE" or "ROUND";
end




function K.NudgeMinimapIcons()
	if _G.NUF_SAFE then return; end
	if not LibStub then return; end
	local ok, ldb = pcall(LibStub, "LibDBIcon-1.0", true);
	if ok and ldb and ldb.objects then
		for name in pairs(ldb.objects) do
			pcall(ldb.Refresh, ldb, name);
		end
	end
end






















local blizzOrig = nil;



local function Pick(...)
	for i = 1, select("#", ...) do
		local f = _G[(select(i, ...))];
		if f and f.SetPoint and f.GetPoint then return f; end
	end
	return nil;
end



local function SquareLayout()
	return {
		{ f = Pick("MiniMapWorldMapButton"),
		  point = "CENTER", rel = "TOPRIGHT",    x = -2, y = -2 },





		{ f = Pick("GameTimeFrame"),
		  point = "CENTER", rel = "RIGHT",       x = -2, y =  38 },
		{ f = Pick("MinimapZoomIn"),
		  point = "CENTER", rel = "RIGHT",       x = -2, y =  10 },
		{ f = Pick("MinimapZoomOut"),
		  point = "CENTER", rel = "RIGHT",       x = -2, y = -18 },




		{ f = Pick("MiniMapTrackingFrame", "MiniMapTracking", "MiniMapTrackingButton"),
		  point = "CENTER", rel = "LEFT",        x =  2, y =  38 },
		{ f = Pick("MiniMapMailFrame"),
		  point = "CENTER", rel = "LEFT",        x =  2, y =  10 },
		{ f = Pick("MiniMapLFGFrame", "MiniMapMeetingStoneButton"),
		  point = "CENTER", rel = "LEFT",        x =  2, y = -18 },
		{ f = Pick("MiniMapBattlefieldFrame"),
		  point = "CENTER", rel = "BOTTOMLEFT",  x =  2, y =  2 },
	};
end

local function CaptureBlizzOrig()
	if blizzOrig then return; end
	blizzOrig = {};
	for _, e in ipairs(SquareLayout()) do
		if e.f then
			local point, relTo, relPoint, x, y = e.f:GetPoint(1);
			if point then
				blizzOrig[e.f] = {
					point = point, relTo = relTo, relPoint = relPoint,
					x = x or 0, y = y or 0,


					level = e.f.GetFrameLevel and e.f:GetFrameLevel() or nil,
				};
			end
		end
	end
end

function K.ApplyMinimapButtonLayout()
	if _G.NUF_SAFE or not Minimap then return; end
	CaptureBlizzOrig();

	if C.MinimapSquare then




		local lvl = (Minimap:GetFrameLevel() or 1) + 4;
		for _, e in ipairs(SquareLayout()) do
			if e.f then
				e.f:ClearAllPoints();
				e.f:SetPoint(e.point, Minimap, e.rel, e.x, e.y);
				if e.f.SetFrameLevel then pcall(e.f.SetFrameLevel, e.f, lvl); end
			end
		end
	else
		for f, o in pairs(blizzOrig) do
			f:ClearAllPoints();

			f:SetPoint(o.point, o.relTo or Minimap or UIParent, o.relPoint, o.x, o.y);
			if o.level and f.SetFrameLevel then pcall(f.SetFrameLevel, f, o.level); end
		end
	end
end


















local BORDER_DIR = "Interface\\AddOns\\Nidhaus_UnitFrames\\Media\\Minimap\\borders\\";







local STYLE_FILE = {
	Default = "Blizzard",
	Lorti   = "Blizzard",
};












local LORTI_TINT = 0.05;








local CORNER_STYLES = {
	Tooltip = true, Thin = true, Flat = true,
};


local function BorderStyle()
	local s = C.MinimapBorderStyle;
	if s == nil or s == "" then s = "Default"; end



	if s == "Blizzard" then s = "Default"; end
	return s;
end
K.GetMinimapBorderStyle = BorderStyle;

local corners;

local function GetCorners()
	if corners then return corners; end
	local parent = MinimapBackdrop or Minimap;
	if not parent or not Minimap then return nil; end

	corners = {};
	for i = 1, 4 do
		corners[i] = parent:CreateTexture("NUF_MinimapCorner" .. i, "ARTWORK");
		corners[i]:Hide();
	end


	corners[1]:SetPoint("BOTTOMRIGHT", Minimap, "CENTER"); corners[1]:SetTexCoord(0,   0.5, 0,   0.5);
	corners[2]:SetPoint("BOTTOMLEFT",  Minimap, "CENTER"); corners[2]:SetTexCoord(0.5, 1,   0,   0.5);
	corners[3]:SetPoint("TOPRIGHT",    Minimap, "CENTER"); corners[3]:SetTexCoord(0,   0.5, 0.5, 1);
	corners[4]:SetPoint("TOPLEFT",     Minimap, "CENTER"); corners[4]:SetTexCoord(0.5, 1,   0.5, 1);
	return corners;
end

















local thinBorder;

local function GetThinBorder()
	if thinBorder then return thinBorder; end
	if not Minimap then return nil; end

	thinBorder = CreateFrame("Frame", "NUF_MinimapThinBorder", Minimap);
	thinBorder:SetBackdrop({
		edgeFile = "Interface\\AddOns\\Nidhaus_UnitFrames\\Media\\Border\\Border_Light",
		edgeSize = 14,
		insets = { left = 2.5, right = 2.5, top = 2.5, bottom = 2.5 },
	});
	thinBorder:SetBackdropBorderColor(1, 1, 1, 1);
	thinBorder:Hide();
	return thinBorder;
end

function K.ApplyMinimapBorderStyle()
	local style = BorderStyle();
	local cs = GetCorners();















	local roundLight = (style == "Light") and (C.MinimapSquare ~= true);
	local lorti = (style == "Lorti");





	local tint = lorti and LORTI_TINT or 1;
	if MinimapBorder then MinimapBorder:SetVertexColor(tint, tint, tint); end
	if MinimapBorderTop then MinimapBorderTop:SetVertexColor(tint, tint, tint); end


















	local squareDefault = (style == "Default" or lorti) and (C.MinimapSquare == true);





	if cs then for _, tx in ipairs(cs) do tx:Hide(); end end

	if (CORNER_STYLES[style] or roundLight or squareDefault) and cs and Minimap then
		local tb = GetThinBorder(); if tb then tb:Hide(); end
		if squareBorder then squareBorder:Hide(); end

		if MinimapBorder then MinimapBorder:Hide(); end
		if MinimapBorderTop then MinimapBorderTop:Hide(); end

		local shape = C.MinimapSquare and "square\\" or "round\\";

		local file  = STYLE_FILE[style] or style;



		local size = (Minimap:GetWidth() / 2) * (80 / 70);
		for _, tx in ipairs(cs) do
			tx:SetTexture(BORDER_DIR .. shape .. file);
			tx:SetSize(size, size);
			tx:SetVertexColor(tint, tint, tint, 1);
			tx:Show();
		end
		return;
	end

	local b = GetThinBorder();
	if not b then return; end

	if style ~= "Light" then b:Hide(); return; end






	if not C.MinimapSquare then b:Hide(); return; end





	b:ClearAllPoints();
	b:SetPoint("TOPLEFT",     Minimap, "TOPLEFT",     -4,  4);
	b:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT",  4, -4);







	b:SetFrameLevel(math.max(0, (Minimap:GetFrameLevel() or 0)) + 1);
	b:Show();
end
































function K.ApplyMinimapNorth()


	if C.MinimapSquare then
		if MinimapNorthTag then MinimapNorthTag:Hide(); end
		if MinimapCompassTexture then MinimapCompassTexture:Hide(); end
		return;
	end




	if type(Minimap_UpdateRotationSetting) == "function" then
		pcall(Minimap_UpdateRotationSetting);
		return;
	end




	if MinimapCompassTexture and MinimapCompassTexture:IsShown() then
		if MinimapNorthTag then MinimapNorthTag:Hide(); end
	end
end




function K.ApplyMinimapShape()
	if not Minimap then return; end

	if C.MinimapSquare then
		Minimap:SetMaskTexture(SQUARE_MASK);
		if MinimapBorder then MinimapBorder:Hide(); end
		if MinimapBorderTop then MinimapBorderTop:Hide(); end




		local b = GetSquareBorder();
		if b then b:Hide(); end
	else
		Minimap:SetMaskTexture(ROUND_MASK);
		if MinimapBorder then MinimapBorder:Show(); end
		if MinimapBorderTop then MinimapBorderTop:Show(); end
		if squareBorder then squareBorder:Hide(); end
	end



	K.ApplyMinimapNorth();

	K.ApplyMinimapBorderStyle();
	K.NudgeMinimapIcons();
	K.ApplyMinimapButtonLayout();


	if K.UpdateMinimapButtonPosition then pcall(K.UpdateMinimapButtonPosition); end
end




function K.ApplyMinimapDecorations()

	if MinimapZoneTextButton then
		if C.MinimapHideZone then MinimapZoneTextButton:Hide(); else MinimapZoneTextButton:Show(); end
	end



	if MinimapZoneText and not _G.NUF_SAFE then
		local f = select(1, MinimapZoneText:GetFont());
		MinimapZoneText:SetFont(f or "Fonts\\FRIZQT__.TTF", 13, "OUTLINE");
		MinimapZoneText:SetShadowColor(0, 0, 0, 1);
		MinimapZoneText:SetShadowOffset(1, -1);
	end
	if MinimapBorderTop and not C.MinimapSquare then
		if C.MinimapHideZone then MinimapBorderTop:Hide(); else MinimapBorderTop:Show(); end
	end





	if MinimapBorderTop and not C.MinimapHideZone then
		if C.MinimapHideZoneBG then MinimapBorderTop:Hide(); else MinimapBorderTop:Show(); end
	end
	if MinimapZoneTextButton and C.MinimapHideZoneBG then

		MinimapZoneTextButton:SetFrameStrata("MEDIUM");
	end


	if TimeManagerClockButton then
		if C.MinimapHideClock then TimeManagerClockButton:Hide(); else TimeManagerClockButton:Show(); end
	end


	if MinimapZoomIn and MinimapZoomOut then
		if C.MinimapHideZoom then
			MinimapZoomIn:Hide(); MinimapZoomOut:Hide();
		else
			MinimapZoomIn:Show(); MinimapZoomOut:Show();
		end
	end


	if GameTimeFrame then
		if C.MinimapHideCalendar then GameTimeFrame:Hide(); else GameTimeFrame:Show(); end
	end


	if MiniMapWorldMapButton then
		if C.MinimapHideWorldMap then MiniMapWorldMapButton:Hide(); else MiniMapWorldMapButton:Show(); end
	end
end












local PROTECTED = {
	["Minimap"] = true, ["MinimapBackdrop"] = true, ["MinimapCluster"] = true,
	["MinimapBorder"] = true, ["MinimapBorderTop"] = true,
	["MinimapNorthTag"] = true, ["MinimapCompassTexture"] = true,
	["MinimapZoneTextButton"] = true, ["MiniMapWorldMapButton"] = true,
	["MinimapZoomIn"] = true, ["MinimapZoomOut"] = true,
	["TimeManagerClockButton"] = true, ["GameTimeFrame"] = true,
	["NUF_MinimapIconToggle"] = true, ["NUF_MinimapSquareBorder"] = true,




	["NUF_MinimapThinBorder"] = true,

	["MiniMapTrackingFrame"] = true, ["MiniMapTracking"] = true,
	["MiniMapTrackingButton"] = true, ["MiniMapTrackingIcon"] = true,
	["MiniMapTrackingBorder"] = true, ["MiniMapTrackingButtonBorder"] = true,
	["MiniMapTrackingBackground"] = true,
};



local function RestoreTrackingButton()
	for _, n in ipairs({ "MiniMapTrackingFrame", "MiniMapTracking", "MiniMapTrackingButton" }) do
		local f = _G[n];
		if f and f.Show and not f:IsShown() then pcall(f.Show, f); end
	end
end
K.RestoreMinimapTracking = RestoreTrackingButton;










local iconRetry = CreateFrame("Frame");
local retryAcc, retryCount = 0, 0;
iconRetry:Hide();
iconRetry:SetScript("OnUpdate", function(self, elapsed)
	retryAcc = retryAcc + elapsed;
	if retryAcc < 1 then return; end
	retryAcc = 0;
	retryCount = retryCount + 1;
	if K.ApplyMinimapIconState then K.ApplyMinimapIconState(); end
	if retryCount >= 5 then self:Hide(); end
end);




local wheelHooked = false;

function K.ApplyMinimapWheelZoom()
	if not Minimap then return; end
	if C.MinimapWheelZoom then
		Minimap:EnableMouseWheel(true);
		if not wheelHooked then
			wheelHooked = true;
			Minimap:SetScript("OnMouseWheel", function(self, delta)
				if not C.MinimapWheelZoom then return; end
				if delta > 0 then
					Minimap_ZoomIn();
				else
					Minimap_ZoomOut();
				end
			end);
		end
	else
		Minimap:EnableMouseWheel(false);
	end
end




local ScaleRelayout;

function K.ApplyMinimapScale()
	local scale = C.MinimapScale or 1.0;
	if MinimapCluster then MinimapCluster:SetScale(scale); end



	if K.RefreshAuraAnchorDefault then K.RefreshAuraAnchorDefault(); end



	ScaleRelayout();
end


local scaleRelay = CreateFrame("Frame");
scaleRelay:Hide();
scaleRelay:SetScript("OnUpdate", function(self)
	self:Hide();
	if K.RefreshAuraAnchorDefault then K.RefreshAuraAnchorDefault(); end
end);
ScaleRelayout = function()
	scaleRelay:Show();
end
















function K.SyncLortiMinimap()
	local style = BorderStyle();
	local lortiMod = K.IsModuleEnabled and K.IsModuleEnabled("LortiUI");
	if lortiMod and C.LortiUI_Minimap ~= false and style == "Default" then
		style = "Lorti";
		C.MinimapBorderStyle = "Lorti";
		if K.SaveConfigSilent then K.SaveConfigSilent("MinimapBorderStyle", "Lorti"); end
	end
	local want = (style == "Lorti");
	if (C.LortiUI_Minimap ~= false) ~= want then
		C.LortiUI_Minimap = want;
		if K.SaveConfigSilent then K.SaveConfigSilent("LortiUI_Minimap", want); end
	end

	if K.RefreshLortiSubOptions then pcall(K.RefreshLortiSubOptions); end
	if K.RefreshMinimapBorderDropdown then pcall(K.RefreshMinimapBorderDropdown); end
end

function K.ApplyMinimapSettings()
	K.SyncLortiMinimap();
	K.ApplyMinimapShape();
	K.ApplyMinimapDecorations();
	if K.ApplyMinimapIconState then K.ApplyMinimapIconState(); end
	K.ApplyMinimapWheelZoom();
	K.ApplyMinimapScale();
	RestoreTrackingButton();
	retryAcc, retryCount = 0, 0;
	iconRetry:Show();
end

local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:SetScript("OnEvent", function()
	K.ApplyMinimapSettings();
end);








if type(Minimap_UpdateRotationSetting) == "function" then
	hooksecurefunc("Minimap_UpdateRotationSetting", function()
		if C.MinimapSquare and K.ApplyMinimapNorth then
			K.ApplyMinimapNorth();
		end
	end);
end


if type(Minimap_SetPing) == "function" then

end

SLASH_NUFMINIMAPSTYLE1 = "/nufmap";
SlashCmdList["NUFMINIMAPSTYLE"] = function(msg)
	msg = string.lower(msg or "");
	if msg == "square" or msg == "cuadrado" then
		K.SaveConfig("MinimapSquare", true);
		K.ApplyMinimapSettings();
	elseif msg == "round" or msg == "redondo" then
		K.SaveConfig("MinimapSquare", false);
		K.ApplyMinimapSettings();
	else
		print("|cff4FC3F7NUF:|r /nufmap square | round");
	end
end
