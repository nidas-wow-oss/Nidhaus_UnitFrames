local AddOnName, ns = ...;
local K, C, L = unpack(ns);






























































local MEDIA = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\pw\\";



local TEX_BORDER = MEDIA .. "UI-CastingBar-Border-Small";
local TEX_FLASH  = MEDIA .. "UI-CastingBar-Flash-Small";
local TEX_SHIELD = MEDIA .. "UI-CastingBar-Small-Shield";
local TEX_ICONBD = MEDIA .. "Border.tga";
local FONT_PATH  = MEDIA .. "PTSans-Bold.ttf";

local TEXCOORD    = { 0.08, 0.92, 0.08, 0.92 };
local BORDER_TINT = { 0.22, 0.22, 0.22, 1 };
local ICON_TINT   = { 0.20, 0.20, 0.20, 1 };



local ICON_PLAYER = 30;
local ICON_OTHER  = 22;

local BARS = { "CastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar" };
















local function BarAllowed(barName)
	if barName == "TargetFrameSpellBar" then return C.CastBarPWTarget ~= false; end
	if barName == "FocusFrameSpellBar"  then return C.CastBarPWFocus  ~= false; end
	return true;
end

local orig    = {};
local applied = false;
local castFont;



local playerScaleBefore;




local function SnapPoints(region)
	if not region then return nil; end
	local n = region:GetNumPoints() or 0;
	if n == 0 then return nil; end
	local pts = {};
	for i = 1, n do
		pts[i] = { region:GetPoint(i) };
	end
	return pts;
end

local function RestorePoints(region, pts)
	if not region or not pts or #pts == 0 then return; end
	region:ClearAllPoints();
	for _, pt in ipairs(pts) do
		pcall(region.SetPoint, region, unpack(pt));
	end
end

local function Sub(barName, suffix)
	return _G[barName .. suffix];
end








local function CastFont()
	if castFont then return castFont; end
	local f = CreateFont("NUF_pwCastFont");
	if not f then return nil; end
	if f:SetFont(FONT_PATH, 14) == false then
		castFont = false;
		return nil;
	end
	f:SetShadowColor(0, 0, 0, 1);
	f:SetShadowOffset(1, -1);
	castFont = f;
	return f;
end




local function Capture(barName)
	if orig[barName] then return; end
	local bar = _G[barName];
	if not bar then return; end

	local border = Sub(barName, "Border");
	local flash  = Sub(barName, "Flash");
	local shield = Sub(barName, "BorderShield");
	local text   = Sub(barName, "Text");
	local icon   = Sub(barName, "Icon");

	local snap = {
		scale = bar:GetScale() or 1,
	};

	if border then
		local r, g, b, a = border:GetVertexColor();
		snap.border = {
			tex    = border:GetTexture(),
			color  = { r or 1, g or 1, b or 1, a or 1 },
			points = SnapPoints(border),
		};
	end

	if flash then
		snap.flash = { tex = flash:GetTexture(), points = SnapPoints(flash) };
	end

	if shield then
		snap.shield = { tex = shield:GetTexture() };
	end

	if text then
		snap.text = { font = text:GetFontObject(), points = SnapPoints(text) };
	end

	if icon then
		snap.icon = {
			shown  = icon:IsShown() and true or false,
			w      = icon:GetWidth(),
			h      = icon:GetHeight(),
			coord  = { icon:GetTexCoord() },
			points = SnapPoints(icon),
		};
	end

	orig[barName] = snap;
end









local function IconBorder(bar, icon)
	if bar.nufCastIconBorder then return bar.nufCastIconBorder; end
	local t = bar:CreateTexture(nil, "OVERLAY");
	t:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 3, 3);
	t:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", -3, -3);
	t:SetTexture(TEX_ICONBD);
	t:SetVertexColor(unpack(ICON_TINT));
	bar.nufCastIconBorder = t;
	return t;
end




local function StyleOne(barName)
	local bar = _G[barName];
	if not bar then return; end

	Capture(barName);

	local isPlayer = (barName == "CastingBarFrame");


	local border = Sub(barName, "Border");
	if border then
		border:SetTexture(TEX_BORDER);
		if C.CastBarPWDark == false then
			border:SetVertexColor(1, 1, 1, 1);
		else
			border:SetVertexColor(unpack(BORDER_TINT));
		end











		if NidhausFrameBorders_HidesRegion
			and NidhausFrameBorders_HidesRegion(border) then
			border:Hide();
		end
	end

	local flash = Sub(barName, "Flash");
	if flash then
		flash:SetTexture(TEX_FLASH);



		if NidhausFrameBorders_HidesRegion
			and NidhausFrameBorders_HidesRegion(flash) then
			flash:SetTexture(nil);
		end
	end

	local shield = Sub(barName, "BorderShield");
	if shield then shield:SetTexture(TEX_SHIELD); end


	local text = Sub(barName, "Text");
	if text then
		local f = CastFont();
		if f then text:SetFontObject(f); end
	end


	local icon = Sub(barName, "Icon");
	if icon then
		if C.CastBarPWIcon == false then
			icon:Hide();
			if bar.nufCastIconBorder then bar.nufCastIconBorder:Hide(); end
		else
			local base = C.CastBarPWIconSize;
			if type(base) ~= "number" then base = ICON_PLAYER; end


			local size = isPlayer and base or (base * ICON_OTHER / ICON_PLAYER);

			icon:Show();
			icon:SetWidth(size);
			icon:SetHeight(size);
			icon:SetTexCoord(unpack(TEXCOORD));

			IconBorder(bar, icon):Show();
		end
	end







	if isPlayer then
		if border then border:SetPoint("TOP", 0, 26); end
		if flash  then flash:SetPoint("TOP", 0, 26);  end
		if icon and C.CastBarPWIcon ~= false then
			icon:ClearAllPoints();
			icon:SetPoint("CENTER", bar, "TOP", 0, 24);
		end
		if text then
			text:ClearAllPoints();
			text:SetPoint("CENTER", 0, 1);
		end
	end
end




local function RestoreOne(barName)
	local snap = orig[barName];
	if not snap then return; end
	local bar = _G[barName];
	if not bar then return; end

	local border = Sub(barName, "Border");
	if border and snap.border then
		if snap.border.tex then border:SetTexture(snap.border.tex); end
		border:SetVertexColor(unpack(snap.border.color));
		RestorePoints(border, snap.border.points);
	end

	local flash = Sub(barName, "Flash");
	if flash and snap.flash then
		if snap.flash.tex then flash:SetTexture(snap.flash.tex); end
		RestorePoints(flash, snap.flash.points);
	end

	local shield = Sub(barName, "BorderShield");
	if shield and snap.shield and snap.shield.tex then
		shield:SetTexture(snap.shield.tex);
	end

	local text = Sub(barName, "Text");
	if text and snap.text then
		if snap.text.font then text:SetFontObject(snap.text.font); end
		RestorePoints(text, snap.text.points);
	end

	local icon = Sub(barName, "Icon");
	if icon and snap.icon then
		icon:SetWidth(snap.icon.w or 16);
		icon:SetHeight(snap.icon.h or 16);
		if snap.icon.coord and #snap.icon.coord >= 4 then
			pcall(icon.SetTexCoord, icon, unpack(snap.icon.coord));
		end
		RestorePoints(icon, snap.icon.points);


		if snap.icon.shown then icon:Show(); else icon:Hide(); end
	end

	if bar.nufCastIconBorder then bar.nufCastIconBorder:Hide(); end




	if barName == "TargetFrameSpellBar" then
		pcall(bar.SetScale, bar, snap.scale or 1);
	end
end


























local function CapturePlayerScale(target)
	if playerScaleBefore ~= nil then return; end
	local v;
	if K.GetGlobalScale then v = K.GetGlobalScale("CastBar"); end
	if type(v) ~= "number" then
		local bar = _G["CastingBarFrame"];
		v = (bar and bar:GetScale()) or 1;
	end
	if type(target) == "number" and math.abs(v - target) < 0.001 then
		v = 1;
	end
	playerScaleBefore = v;
end

local function ReleasePlayerScale()
	local v = playerScaleBefore;
	playerScaleBefore = nil;
	if type(v) ~= "number" then return; end
	if K.SetGlobalFrameScale and K.SetGlobalFrameScale("CastBar", v) then
		return;
	end
	local bar = _G["CastingBarFrame"];
	if bar then pcall(bar.SetScale, bar, v); end
end












local function ReapplyPlayerPosition()
	if K.RestoreGlobalPosition then
		pcall(K.RestoreGlobalPosition, "CastBar");
	end
end

function K.ApplyCastBarPWScale(value)
	if type(value) ~= "number" then value = C.CastBarPWScale; end
	if type(value) ~= "number" then return; end




	local player = _G["CastingBarFrame"];
	if K.SetGlobalFrameScale then
		K.SetGlobalFrameScale("CastBar", value);
	elseif player then
		pcall(player.SetScale, player, value);
	end




	if not applied then return; end


	if not BarAllowed("TargetFrameSpellBar") then return; end
	local target = _G["TargetFrameSpellBar"];
	if target then
		pcall(target.SetScale, target, value);
	end
end




function K.EnableCastBarPW()
	applied = true;




	for _, name in ipairs(BARS) do
		if BarAllowed(name) then StyleOne(name); else RestoreOne(name); end
	end


	CapturePlayerScale(C.CastBarPWScale);
	K.ApplyCastBarPWScale(C.CastBarPWScale);
	ReapplyPlayerPosition();



	if C.CastingTimers and K.ToggleCastingTimers then
		K.ToggleCastingTimers(true);
	end
end

function K.DisableCastBarPW()
	if not applied then return; end
	applied = false;
	for _, name in ipairs(BARS) do RestoreOne(name); end

	ReleasePlayerScale();
	ReapplyPlayerPosition();

	if C.CastingTimers and K.ToggleCastingTimers then
		K.ToggleCastingTimers(true);
	end
end

function K.IsCastBarPWActive()
	return applied;
end

function K.ApplyCastBarPW()
	if C.CastBarPWEnabled then
		K.EnableCastBarPW();
	else
		K.DisableCastBarPW();
	end
end










local function HookBars()
	for _, name in ipairs(BARS) do
		local bar = _G[name];
		if bar and not bar.nufCastPWHooked then
			bar.nufCastPWHooked = true;
			bar:HookScript("OnShow", function(self)
				if not applied or not BarAllowed(name) then return; end
				StyleOne(name);
			end);
		end
	end
end




















if K.LayoutRegisterStore then
	K.LayoutRegisterStore("CastBarPW", function()
		K.ApplyCastBarPW();
	end);
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	HookBars();
	K.ApplyCastBarPW();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	HookBars();
	K.ApplyCastBarPW();
end);
