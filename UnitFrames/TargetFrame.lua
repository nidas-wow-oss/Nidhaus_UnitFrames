local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hooksecurefunc = hooksecurefunc;
local unpack, _G = unpack, _G;
local UnitClassification, UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP = UnitClassification, UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP;

local Path;
local isInitialized = false;

--	Target frame
local function Nidhaus_UnitFrames_Style_TargetFrame(self)
	self.highLevelTexture:ClearAllPoints();
	self.highLevelTexture:SetPoint("CENTER", self.levelText, "CENTER", 1, 0);
	self.deadText:SetPoint("CENTER", self.healthbar, "CENTER", 0, -5);
	self.nameBackground:Hide();
	if C.TargetNameOffset and type(C.TargetNameOffset) == "table" then
		self.name:SetPoint(K.SetOffset(self.name, unpack(C.TargetNameOffset)));
	else
		self.name:SetPoint(K.SetOffset(self.name, 0, 0));
	end
	
	self.healthbar:SetHeight(28);
	self.healthbar:SetPoint("TOPLEFT", 5, -24);
	self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, -5);
	
	self.healthbar.lockColor = true;
	if C.statusbarOn then
		self.healthbar:SetStatusBarTexture(C.statusbarTexture);
		self.manabar:SetStatusBarTexture(C.statusbarTexture);
	end;
end;

local function Nidhaus_UnitFrames_TargetFrame_CheckClassification(self, forceNormalTexture)
	local texture;
	local classification = UnitClassification(self.unit);
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

--	ToT & ToF
local function Nidhaus_UnitFrames_Style_ToTF(self)
	_G[self:GetName().."TextureFrameTexture"]:SetTexture(Path.."UI-TargetofTargetFrame");
	self.deadText:ClearAllPoints();
	self.deadText:SetPoint("CENTER", self:GetName().."HealthBar", "CENTER", 1, 0);
	self.name:SetSize(65, 10);
	self.healthbar:ClearAllPoints();
	self.healthbar:SetPoint("TOPLEFT", 45, -15);
	self.healthbar:SetHeight(10);
	self.manabar:ClearAllPoints();
	self.manabar:SetPoint("TOPLEFT", 45, -25);
	self.manabar:SetHeight(5);
	self.background:SetSize(50, 14);
	self.background:ClearAllPoints();
	self.background:SetPoint("CENTER", self, "CENTER", 20, 0);
end;

-- Focus frame
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

--	Create Backdrop
local function ApplyBackdrop()
	if C.statusbarBackdrop then
		K.CreateBackdrop(TargetFrame);
		K.CreateBackdrop(FocusFrame);
	end
end

local function InitializeTargetFrame()
	if isInitialized then return; end
	
	-- Determinar path de texturas
	if C.darkFrames then
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\";
	else
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\";
	end
	
	-- Aplicar escala del Target Frame
	if C.TargetFrameScale and type(C.TargetFrameScale) == "number" and C.TargetFrameScale > 0 and C.TargetFrameScale <= 3 then
		TargetFrame:SetScale(C.TargetFrameScale);
	end
	
	-- Aplicar estilos
	Nidhaus_UnitFrames_Style_TargetFrame(TargetFrame);
	Nidhaus_UnitFrames_Style_TargetFrame(FocusFrame);
	
	-- Registrar hooks
	hooksecurefunc("TargetFrame_CheckClassification", Nidhaus_UnitFrames_TargetFrame_CheckClassification);
	hooksecurefunc("TargetFrame_CheckFaction", Nidhaus_UnitFrames_TargetFrame_CheckFaction);
	
	-- Aplicar estilos a ToT y ToF
	Nidhaus_UnitFrames_Style_ToTF(TargetFrameToT);
	Nidhaus_UnitFrames_Style_ToTF(FocusFrameToT);
	
	-- Aplicar estilos a Focus
	Nidhaus_UnitFrames_Style_FocusFrame();
	
	-- Aplicar backdrop
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