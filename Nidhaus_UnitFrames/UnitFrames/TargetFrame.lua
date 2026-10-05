local AddOnName, ns = ...;
local K, C, L = unpack(ns);




local function TintBorder(tex)
	if not tex then return; end
	if not (K.ApplyLortiTint and K.ApplyLortiTint(tex,
		"LortiUI_PlayerTargetFocus")) then
		tex:SetVertexColor(1, 1, 1);
	end
end

local hooksecurefunc = hooksecurefunc;
local unpack, _G = unpack, _G;
local UnitClassification, UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP = UnitClassification, UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP;

local Path;
local isInitialized = false;






local ASURI = "Interface\\AddOns\\"..AddOnName.."\\Media\\Asuri\\";

local function AsuriOn()
	return C.UnitFrameCustomTexture and C.AsuriFrames;
end



local function UpdatePath()
	if not C.UnitFrameCustomTexture then
		Path = "Interface\\TargetingFrame\\";
	elseif C.pwFrames then




		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\pw\\";
	elseif C.darkFrames then
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\";
	else
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\";
	end
	return Path;
end










local function CaptureFrameDefaults(self, keyBase)
	if self.healthbar then

		K.CaptureBarGeometry(self.healthbar, keyBase.."HealthBar");


		K.CaptureAnchors(self.healthbar, keyBase.."HealthBarAnchors");
		if self.healthbar.TextString then
			K.CaptureAnchors(self.healthbar.TextString, keyBase.."HealthText");
		end
	end
	if self.name then
		K.CaptureAnchors(self.name, keyBase.."Name");

		if not self._nufNameFont then
			self._nufNameFont = self.name:GetFontObject();
		end
	end
	if self.manabar then
		K.CaptureAnchors(self.manabar, keyBase.."ManaBarAnchors");
	end
	local bg = _G[self:GetName() .. "Background"];
	if bg and not bg._nufOrig then
		bg._nufOrig = { w = bg:GetWidth(), h = bg:GetHeight(),
			pts = { bg:GetPoint(1) } };
	end
end


local function Nidhaus_UnitFrames_Style_TargetFrame(self)
	local keyBase = (self == FocusFrame) and "Focus" or "Target";
	CaptureFrameDefaults(self, keyBase);

	if C.UnitFrameCustomTexture then
		self.highLevelTexture:ClearAllPoints();
		self.highLevelTexture:SetPoint("CENTER", self.levelText, "CENTER", 1, 0);
		self.deadText:SetPoint("CENTER", self.healthbar, "CENTER", 0, -5);
		self.nameBackground:Hide();


		K.RestoreAnchors(self.name, keyBase.."Name");
		if C.TargetNameOffset and type(C.TargetNameOffset) == "table" then
			self.name:SetPoint(K.SetOffset(self.name, unpack(C.TargetNameOffset)));
		else
			self.name:SetPoint(K.SetOffset(self.name, 0, 0));
		end


		if AsuriOn() then
			self.highLevelTexture:SetAlpha(0);
			self.nameBackground:SetAlpha(0);
			self.levelText:SetAlpha(0);
			if self.threatIndicator then self.threatIndicator:SetAlpha(0); end
			self.name:ClearAllPoints();
			self.name:SetPoint("CENTER", self, "CENTER", -50, 25);
			self.name:SetShadowOffset(1, -1);
			if self._nufNameFont then self.name:SetFontObject(self._nufNameFont); end

			self.healthbar:ClearAllPoints();
			self.healthbar:SetPoint("CENTER", self, "CENTER", -50, 7);
			self.healthbar:SetHeight(16);
			self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, 0);
			if self.deadText then
				self.deadText:ClearAllPoints();
				self.deadText:SetPoint("CENTER", self.healthbar, "CENTER", 0, 0);
			end

			self.manabar:ClearAllPoints();
			self.manabar:SetPoint("CENTER", self, "CENTER", -50, -7);
			if self.manabar.TextString then
				self.manabar.TextString:SetPoint("CENTER", self.manabar, "CENTER", 0, -1);
			end





			local bg = _G[self:GetName() .. "Background"];
			if bg then
				bg:SetWidth(119);
				bg:SetHeight(30);
				bg:ClearAllPoints();
				bg:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 7, 35);
			end

			self.healthbar.lockColor = true;
			if C.statusbarOn then
				self.healthbar:SetStatusBarTexture(C.statusbarTexture);
				self.manabar:SetStatusBarTexture(C.statusbarTexture);
			end
			return;
		end


		local bgN = _G[self:GetName() .. "Background"];
		if bgN and bgN._nufOrig then
			local o = bgN._nufOrig;
			bgN:SetWidth(o.w);
			bgN:SetHeight(o.h);
			if o.pts and o.pts[1] then
				bgN:ClearAllPoints();
				bgN:SetPoint(o.pts[1], o.pts[2] or self, o.pts[3] or o.pts[1],
					o.pts[4] or 0, o.pts[5] or 0);
			end
		end
		if self.threatIndicator then self.threatIndicator:SetAlpha(1); end
		K.RestoreAnchors(self.manabar, keyBase.."ManaBarAnchors");




		local hideLevel = (C.UnitFrameCustomTexture and C.pwFrames);
		self.levelText:SetAlpha(hideLevel and 0 or 1);
		self.highLevelTexture:SetAlpha(hideLevel and 0 or 1);

		if self._nufNameFont then
			self.name:SetFontObject(self._nufNameFont);
			self.name:SetShadowOffset(1, -1);
		end






		local big = K.BigStatusTextOn and K.BigStatusTextOn(keyBase == "Focus" and "focus" or "target");
		if big then
			self.name:ClearAllPoints();
			self.name:SetPoint("CENTER", self, "CENTER", -50, 35);
			if K.OutlineBigName then K.OutlineBigName(self.name); end
		end

		self.deadText:SetPoint("CENTER", self.healthbar, "CENTER", 0, big and 0 or -5);

		self.healthbar:SetHeight(28);






		K.RestoreAnchors(self.healthbar, keyBase.."HealthBarAnchors");
		self.healthbar:SetPoint("TOPLEFT", 5, -24);

		self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, big and 0 or -5);
	else


		K.RestoreBarGeometry(self.healthbar, keyBase.."HealthBar");
		K.RestoreAnchors(self.healthbar.TextString, keyBase.."HealthText");
		K.RestoreAnchors(self.name, keyBase.."Name");
		self.nameBackground:Show();


		if self._nufNameFont then
			self.name:SetFontObject(self._nufNameFont);
			self.name:SetShadowOffset(1, -1);
		end
		TintBorder(self.borderTexture);

		local bgD = _G[self:GetName() .. "Background"];
		if bgD and bgD._nufOrig then
			local o = bgD._nufOrig;
			bgD:SetWidth(o.w);
			bgD:SetHeight(o.h);
			if o.pts and o.pts[1] then
				bgD:ClearAllPoints();
				bgD:SetPoint(o.pts[1], o.pts[2] or self, o.pts[3] or o.pts[1],
					o.pts[4] or 0, o.pts[5] or 0);
			end
		end
		self.highLevelTexture:SetAlpha(1);
		self.nameBackground:SetAlpha(1);
		self.levelText:SetAlpha(1);
		if self.threatIndicator then self.threatIndicator:SetAlpha(1); end
		K.RestoreAnchors(self.manabar, keyBase.."ManaBarAnchors");
	end
	
	self.healthbar.lockColor = true;
	if C.statusbarOn then
		self.healthbar:SetStatusBarTexture(C.statusbarTexture);
		self.manabar:SetStatusBarTexture(C.statusbarTexture);
	end;
end;

local function Nidhaus_UnitFrames_TargetFrame_CheckClassification(self, forceNormalTexture)
	local texture;
	local classification = UnitClassification(self.unit);


	if AsuriOn() then
		self.borderTexture:SetTexture(ASURI.."AsuriFrame");
		self.borderTexture:SetVertexColor(0.25, 0.25, 0.25);
		return;
	end

	TintBorder(self.borderTexture);

	if classification == "worldboss" or classification == "elite" then
		texture = Path.."UI-TargetingFrame-Elite";
	elseif classification == "rareelite" then
		texture = Path.."UI-TargetingFrame-Rare-Elite";
	elseif classification == "rare" then
		texture = Path.."UI-TargetingFrame-Rare";
	end;
	if texture and not forceNormalTexture then
		self.borderTexture:SetTexture(texture);
	else
		self.borderTexture:SetTexture(Path.."UI-TargetingFrame");
	end;
end;

local function Nidhaus_UnitFrames_TargetFrame_CheckFaction(self)
	if self.showPVP then
		local factionGroup = UnitFactionGroup(self.unit);
		if UnitIsPVPFreeForAll(self.unit) then
			self.pvpIcon:SetTexture(Path.."UI-PVP-FFA");
			self.pvpIcon:Show();
		elseif factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(self.unit) then
			self.pvpIcon:SetTexture(Path.."UI-PVP-"..factionGroup);
			self.pvpIcon:Show();
		else
			self.pvpIcon:Hide();
		end;
	end;
end;


local function Nidhaus_UnitFrames_Style_ToTF(self)
	local name = self:GetName();
	local hb = _G[name.."HealthBar"];
	local mb = _G[name.."ManaBar"];
	local bg = self.background;

	K.CaptureBarGeometry(hb, name.."HB");
	K.CaptureBarGeometry(mb, name.."MB");
	K.CaptureAnchors(bg, name.."BG");

	_G[name.."TextureFrameTexture"]:SetTexture(Path.."UI-TargetofTargetFrame");
	self.deadText:ClearAllPoints();
	self.deadText:SetPoint("CENTER", name.."HealthBar", "CENTER", 1, 0);

	if C.UnitFrameCustomTexture then
		self.name:SetSize(65, 10);
		hb:ClearAllPoints();
		hb:SetPoint("TOPLEFT", 45, -15);
		hb:SetHeight(10);
		mb:ClearAllPoints();
		mb:SetPoint("TOPLEFT", 45, -25);
		mb:SetHeight(5);
		bg:SetSize(50, 14);
		bg:ClearAllPoints();
		bg:SetPoint("CENTER", self, "CENTER", 20, 0);
	else

		K.RestoreBarGeometry(hb, name.."HB");
		K.RestoreBarGeometry(mb, name.."MB");
		K.RestoreAnchors(bg, name.."BG");
	end
end;


local function Nidhaus_UnitFrames_Style_FocusFrame()
	if C.FocusScale and type(C.FocusScale) == "number" and C.FocusScale > 0 and C.FocusScale <= 3 then
		FocusFrame:SetScale(C.FocusScale);
	end
	
	if C.FocusSpellBarScale and type(C.FocusSpellBarScale) == "number" and C.FocusSpellBarScale > 0 and C.FocusSpellBarScale <= 3 then
		FocusFrameSpellBar:SetScale(C.FocusSpellBarScale);
	end
	
	if C.FocusAuraLimit then
		FocusFrame.maxDebuffs = C.Focus_maxDebuffs or 0;
		FocusFrame.maxBuffs = C.Focus_maxBuffs or 0;
	end;
end;


local function ApplyBackdrop()
	if C.statusbarBackdrop then
		K.CreateBackdrop(TargetFrame);
		K.CreateBackdrop(FocusFrame);
	end
end

local function InitializeTargetFrame()
	if isInitialized then return; end
	

	UpdatePath();
	

	if C.TargetFrameScale and type(C.TargetFrameScale) == "number" and C.TargetFrameScale > 0 and C.TargetFrameScale <= 3 then
		TargetFrame:SetScale(C.TargetFrameScale);
	end
	

	Nidhaus_UnitFrames_Style_TargetFrame(TargetFrame);
	Nidhaus_UnitFrames_Style_TargetFrame(FocusFrame);
	

	hooksecurefunc("TargetFrame_CheckClassification", Nidhaus_UnitFrames_TargetFrame_CheckClassification);
	hooksecurefunc("TargetFrame_CheckFaction", Nidhaus_UnitFrames_TargetFrame_CheckFaction);
	

	Nidhaus_UnitFrames_Style_ToTF(TargetFrameToT);
	Nidhaus_UnitFrames_Style_ToTF(FocusFrameToT);
	

	Nidhaus_UnitFrames_Style_FocusFrame();
	

	ApplyBackdrop();
	
	isInitialized = true;
end

function K.ApplyTargetFrameScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	TargetFrame:SetScale(scale);
end

function K.ApplyFocusFrameScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	FocusFrame:SetScale(scale);
end

function K.ApplyFocusSpellBarScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	if FocusFrameSpellBar then
		FocusFrameSpellBar:SetScale(scale);
	end
end






local function RefreshTargetLikeFrame(frame)
	if not frame then return; end





	Nidhaus_UnitFrames_TargetFrame_CheckClassification(frame);
	Nidhaus_UnitFrames_TargetFrame_CheckFaction(frame);
	Nidhaus_UnitFrames_Style_TargetFrame(frame);
end

function K.ApplyTargetFrameSkin()
	if not isInitialized then return; end
	UpdatePath();
	RefreshTargetLikeFrame(TargetFrame);
	RefreshTargetLikeFrame(FocusFrame);
	Nidhaus_UnitFrames_Style_ToTF(TargetFrameToT);
	Nidhaus_UnitFrames_Style_ToTF(FocusFrameToT);
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	InitializeTargetFrame();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if not isInitialized then return; end
	
	if C.TargetFrameScale then
		K.ApplyTargetFrameScale(C.TargetFrameScale);
	end
	
	if C.FocusScale then
		K.ApplyFocusFrameScale(C.FocusScale);
	end
	
	if C.FocusSpellBarScale then
		K.ApplyFocusSpellBarScale(C.FocusSpellBarScale);
	end
end);