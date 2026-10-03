local AddOnName, ns = ...;
local K, C, L = unpack(ns);




































local FRAMES     = 4;
local FRAME_NAME = "PartyTargetFrame";





















local SQ = {
	frame    = { w = 70, h = 75 },
	border   = { w = 64, h = 64, y = -2 },
	portrait = { size = 32, y = 9 },
	health   = { w = 30, h = 10, y = -10 },
	mana     = { w = 30, h = 10 },
	name     = { w = 84 },
};

local TEXPATH      = "Interface\\AddOns\\Nidhaus_UnitFrames\\Textures\\";
local SQUARE_TEX   = TEXPATH .. "TargetOfTargetSquare.tga";
local BAR_TEX      = TEXPATH .. "beige.tga";




















local CLASS_ATLAS  = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes";









local FRAME_COLOR  = { 1, 1, 1, 1 };

local orig = {};




local function Parts(f)
	local n = f:GetName();
	return _G[n .. "Portrait"],
	       _G[n .. "HealthBar"],
	       _G[n .. "ManaBar"],
	       _G[n .. "Name"],
	       _G[n .. "Texture"];
end


local function Snap(region)
	if not region then return nil; end
	local point, relTo, relPoint, x, y = region:GetPoint(1);
	return {
		point = point, relTo = relTo, relPoint = relPoint,
		x = x or 0, y = y or 0,
		w = region:GetWidth(), h = region:GetHeight(),
		shown = region:IsShown(),



		font = region.GetFont and { region:GetFont() } or nil,
	};
end


local function Restore(region, s, keepShown)
	if not region or not s then return; end
	region:ClearAllPoints();
	if s.point then
		region:SetPoint(s.point, s.relTo, s.relPoint, s.x, s.y);
	end
	if s.w and s.w > 0 then region:SetWidth(s.w); end
	if s.h and s.h > 0 then region:SetHeight(s.h); end
	if not keepShown then
		if s.shown then region:Show(); else region:Hide(); end
	end
	if s.font and s.font[1] and region.SetFont then
		pcall(region.SetFont, region, s.font[1], s.font[2], s.font[3]);
	end
end

local function Capture(f)
	local name = f:GetName();
	if orig[name] then return; end

	local por, hp, mp, nm, tex = Parts(f);
	orig[name] = {
		frame    = { w = f:GetWidth(), h = f:GetHeight() },
		portrait = Snap(por),
		health   = Snap(hp),
		mana     = Snap(mp),
		name     = Snap(nm),
		texture  = Snap(tex),
	};
end















local function GetBarBG(bar)
	if bar.nufSquareBG then return bar.nufSquareBG; end
	local t = bar:CreateTexture(nil, "BACKGROUND");
	t:SetTexture(0, 0, 0, 0.6);
	t:SetAllPoints(bar);
	bar.nufSquareBG = t;
	return t;
end





















local FACE_COORDS = { 0.08, 0.92, 0.08, 0.92 };


local CIRCLE_ATLAS = "Interface\\TargetingFrame\\UI-Classes-Circles";




local function WantClassIcon()
	local v = PartyTargetsDB and PartyTargetsDB.classIcon;
	if v == nil then return K.GetPartyTargetStyle() == "Square"; end
	return v and true or false;
end

local function ApplyClassPortrait(f)
	local por = _G[f:GetName() .. "Portrait"];
	if not por then return; end

	local unit = "party" .. f:GetID() .. "target";

	if UnitExists(unit) and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit);
		local coords = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class];
		if coords then
			por:SetTexture((K.GetPartyTargetStyle() == "Square") and CLASS_ATLAS or CIRCLE_ATLAS);
			por:SetTexCoord(unpack(coords));
			return;
		end
	end









	if UnitExists(unit) then
		SetPortraitTexture(por, unit);
	else
		por:SetTexture(nil);
	end
	por:SetTexCoord(unpack(FACE_COORDS));
end


local function ApplyFacePortrait(f)
	local por = _G[f:GetName() .. "Portrait"];
	if not por then return; end
	local unit = "party" .. f:GetID() .. "target";
	if UnitExists(unit) then
		SetPortraitTexture(por, unit);
	else
		por:SetTexture(nil);
	end
	por:SetTexCoord(unpack(FACE_COORDS));
end



local function UpdatePortrait(f)
	if WantClassIcon() then ApplyClassPortrait(f); else ApplyFacePortrait(f); end
end




local function ApplySquare(f)
	local por, hp, mp, nm, tex = Parts(f);
	if not (por and hp and mp and tex) then return; end

	f:SetSize(SQ.frame.w, SQ.frame.h);



	tex:SetTexture(SQUARE_TEX);
	tex:SetTexCoord(0, 1, 0, 1);
	tex:ClearAllPoints();
	tex:SetSize(SQ.border.w, SQ.border.h);
	tex:SetPoint("CENTER", f, "CENTER", 0, SQ.border.y);


	if not (K.ApplyLortiTint and K.ApplyLortiTint(tex, "LortiUI_PartyTargets")) then
		tex:SetVertexColor(unpack(FRAME_COLOR));
	end
	tex:Show();


	por:ClearAllPoints();
	por:SetSize(SQ.portrait.size, SQ.portrait.size);
	por:SetPoint("CENTER", tex, "CENTER", 0, SQ.portrait.y);

	hp:ClearAllPoints();
	hp:SetSize(SQ.health.w, SQ.health.h);
	hp:SetPoint("CENTER", tex, "CENTER", 0, SQ.health.y);

	mp:ClearAllPoints();
	mp:SetSize(SQ.mana.w, SQ.mana.h);
	mp:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, 0);



	hp:SetStatusBarTexture(BAR_TEX);
	mp:SetStatusBarTexture(BAR_TEX);

	GetBarBG(hp):Show();
	GetBarBG(mp):Show();




	if nm and PartyTargetsDB and PartyTargetsDB.hideName then
		nm:Hide();
	elseif nm then
		nm:Show();









		nm:ClearAllPoints();
		nm:SetWidth(SQ.name.w);
		nm:SetHeight(10);
		nm:SetPoint("BOTTOM", tex, "TOP", 0, -2);
		nm:SetJustifyH("CENTER");
		nm:SetFont("Fonts\\FRIZQT__.TTF", 9);
		nm:SetShadowColor(0, 0, 0, 1);
		nm:SetShadowOffset(1, -1);
		nm:SetTextColor(1, 0.82, 0);
	end

	UpdatePortrait(f);
end

local function ApplyClassic(f)
	local s = orig[f:GetName()];
	if not s then return; end

	local por, hp, mp, nm, tex = Parts(f);

	f:SetSize(s.frame.w, s.frame.h);
	Restore(por, s.portrait);
	Restore(hp,  s.health);
	Restore(mp,  s.mana);











	Restore(nm,  s.name, true);
	if nm then
		if PartyTargetsDB and PartyTargetsDB.hideName then nm:Hide(); else nm:Show(); end
	end
	Restore(tex, s.texture);
	if nm then nm:SetJustifyH("LEFT"); end



	if tex then
		tex:SetTexture("Interface\\TargetingFrame\\UI-TargetofTargetFrame");
		if not (K.ApplyLortiTint and K.ApplyLortiTint(tex, "LortiUI_PartyTargets")) then
			tex:SetVertexColor(1, 1, 1);
		end
	end

	if hp then hp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); end
	if mp then mp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); end


	if hp and hp.nufSquareBG then hp.nufSquareBG:Hide(); end
	if mp and mp.nufSquareBG then mp.nufSquareBG:Hide(); end




	if por then por:SetTexCoord(unpack(FACE_COORDS)); end

	if por and WantClassIcon() then ApplyClassPortrait(f); end
end




function K.GetPartyTargetStyle()
	local v = PartyTargetsDB and PartyTargetsDB.style;
	return (v == "Square") and "Square" or "Classic";
end








local stylePending = false;

function K.ApplyPartyTargetStyle()
	if InCombatLockdown() then stylePending = true; return; end
	stylePending = false;

	local square = (K.GetPartyTargetStyle() == "Square");

	for i = 1, FRAMES do
		local f = _G[FRAME_NAME .. i];
		if f then


			Capture(f);
			if square then ApplySquare(f) else ApplyClassic(f) end
		end
	end
end


function K.GetPartyTargetClassIcon()
	return WantClassIcon();
end

function K.SetPartyTargetClassIcon(on)
	if not PartyTargetsDB then PartyTargetsDB = {}; end
	PartyTargetsDB.classIcon = on and true or false;
	for i = 1, FRAMES do
		local f = _G[FRAME_NAME .. i];
		if f then UpdatePortrait(f); end
	end
end

function K.SetPartyTargetStyle(style)
	if not PartyTargetsDB then PartyTargetsDB = {}; end
	PartyTargetsDB.style = (style == "Square") and "Square" or "Classic";
	K.ApplyPartyTargetStyle();


	if K.ApplyPartyTargetScale then K.ApplyPartyTargetScale(); end
	if K.RefreshPartyTargetScaleSlider then K.RefreshPartyTargetScaleSlider(); end
end








local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:RegisterEvent("PARTY_MEMBERS_CHANGED");
events:RegisterEvent("UNIT_TARGET");
events:RegisterEvent("PLAYER_REGEN_ENABLED");
events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_ENABLED" then

		if stylePending then K.ApplyPartyTargetStyle(); end
		return;
	end


















	K.ApplyPartyTargetStyle();
end);












if type(UnitFramePortrait_Update) == "function" then
	hooksecurefunc("UnitFramePortrait_Update", function(self)


		if not self or not WantClassIcon() then return; end
		local n = self.GetName and self:GetName();
		if n and string.find(n, "^PartyTargetFrame%d") then
			ApplyClassPortrait(self);
		end
	end);
end

SLASH_NUFPTSTYLE1 = "/ptstyle";
SlashCmdList["NUFPTSTYLE"] = function(msg)
	msg = string.lower(msg or "");
	if msg == "square" then
		K.SetPartyTargetStyle("Square");
		print("|cff4FC3F7NUF:|r party targets = Square");
	elseif msg == "classic" then
		K.SetPartyTargetStyle("Classic");
		print("|cff4FC3F7NUF:|r party targets = Classic");
	else
		print("|cff4FC3F7NUF:|r /ptstyle square | classic   (ahora: "
			.. K.GetPartyTargetStyle() .. ")");
	end
end
