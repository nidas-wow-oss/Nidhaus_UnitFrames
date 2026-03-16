local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hooksecurefunc = hooksecurefunc;
local UnitFactionGroup, UnitIsPVP, UnitIsVisible, UnitPowerMax = UnitFactionGroup, UnitIsPVP, UnitIsVisible, UnitPowerMax;
local unpack = unpack;

local isInitialized = false;

local function InitializePlayerFrame()
	if isInitialized then return; end
	
	-- Crear frame de movimiento
	K.MoveFrame(PlayerFrame, "NidhausPlayerFrame", "Player", 105, 27);

	-- Aplicar escala (solo al contenedor visual)
	if C.PlayerFrameScale and type(C.PlayerFrameScale) == "number" and C.PlayerFrameScale > 0 and C.PlayerFrameScale <= 3 then
		if NidhausPlayerFrame then 
			NidhausPlayerFrame:SetScale(C.PlayerFrameScale); 
		end
	end
	
	isInitialized = true;
end

--	Player frame.
local function Nidhaus_UnitFrames_Style_PlayerFrame(self)
	if C.statusbarOn then
		self.healthbar:SetStatusBarTexture(C.statusbarTexture);
		self.manabar:SetStatusBarTexture(C.statusbarTexture);
	end;
	PlayerStatusTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\UI-Player-Status2");
	PlayerStatusTexture:ClearAllPoints();
	PlayerStatusTexture:SetPoint("CENTER", NidhausPlayerFrame, "CENTER", 16, 8);
	PlayerFrameGroupIndicatorText:ClearAllPoints();
	PlayerFrameGroupIndicatorText:SetPoint("BOTTOMLEFT", NidhausPlayerFrame, "TOP", 0, -20);
	PlayerFrameGroupIndicatorLeft:Hide();
	PlayerFrameGroupIndicatorMiddle:Hide();
	PlayerFrameGroupIndicatorRight:Hide();
	
	if C.darkFrames then
		PlayerFrameTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\UI-TargetingFrame");
		PlayerPVPIcon:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\UI-PVP-FFA");
	else
		PlayerFrameTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\UI-TargetingFrame");
		PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
	end;
end;

local function Nidhaus_UnitFrames_PlayerFrame_ToPlayerArt(self)
	-- Re-apply custom textures (Blizzard resets them when this function fires)
	Nidhaus_UnitFrames_Style_PlayerFrame(self);

	if C.PlayerNameOffset and type(C.PlayerNameOffset) == "table" then
		self.name:SetPoint(K.SetOffset(self.name, unpack(C.PlayerNameOffset)));
	else
		self.name:SetPoint(K.SetOffset(self.name, 0, 0));
	end
	
	self.healthbar:SetPoint("TOPLEFT", 106, -24);
	self.healthbar:SetHeight(28);
	self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, -5);
	RuneFrame:ClearAllPoints();
	RuneFrame:SetPoint("TOP", NidhausPlayerFrame, "BOTTOM", 52, 34);

	PlayerFrameFlash:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash");
	PlayerFrameFlash:SetTexCoord(0.9453125, 0, 0, 0.181640625);
end;

-- FIX: local para evitar colisiones con otros addons
local function playerPvpIcon()
	local factionGroup = UnitFactionGroup("player");
	if factionGroup and factionGroup ~= "Neutral" and UnitIsPVP("player") then
		if C.darkFrames then
			PlayerPVPIcon:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\UI-PVP-"..factionGroup);
		else
			PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);
		end;
	end;
end;

--	Player vehicle frame.
local function Nidhaus_UnitFrames_PlayerFrame_ToVehicleArt(self, vehicleType)
	if vehicleType == "Natural" then
		PlayerFrameFlash:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Vehicles\\UI-Vehicle-Frame-Organic-Flash");
		PlayerFrameFlash:SetTexCoord(-0.02, 1, 0.07, 0.86);
		self.healthbar:SetSize(103, 12);
	else
		PlayerFrameFlash:SetTexture("Interface\\Vehicles\\UI-Vehicle-Frame-Flash");
		PlayerFrameFlash:SetTexCoord(-0.02, 1, 0.07, 0.86);
		self.healthbar:SetSize(100, 12);
	end;
	self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, 0);
end;

-- Pet frame
local function Nidhaus_UnitFrames_PetFrame_Update(self, override)
	if (not PlayerFrame.animating) or (override) then
		if UnitIsVisible(self.unit) and not PlayerFrame.vehicleHidesPet then
			if UnitPowerMax(self.unit) == 0 then
				if C.darkFrames then
					PetFrameTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\UI-SmallTargetingFrame-NoMana");
				else
					PetFrameTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\UI-SmallTargetingFrame-NoMana");
				end;
				PetFrameManaBarText:Hide();
			else
				if C.darkFrames then
					PetFrameTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\UI-SmallTargetingFrame");
				else
					PetFrameTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\UI-SmallTargetingFrame");
				end;
			end;
		end;
	end;
end;

-- Backdrop;
local function ApplyBackdrop()
	if C.statusbarBackdrop then
		K.CreateBackdrop(PlayerFrame);
	end
end

function K.ApplyPlayerFrameScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	if NidhausPlayerFrame then
		NidhausPlayerFrame:SetScale(scale);
	end
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	-- Inicializar frame
	InitializePlayerFrame();
	
	-- Aplicar estilos
	Nidhaus_UnitFrames_Style_PlayerFrame(PlayerFrame);
	
	-- Registrar hooks
	hooksecurefunc("PlayerFrame_ToPlayerArt", Nidhaus_UnitFrames_PlayerFrame_ToPlayerArt);
	hooksecurefunc("PlayerFrame_UpdatePvPStatus", playerPvpIcon);
	hooksecurefunc("PlayerFrame_ToVehicleArt", Nidhaus_UnitFrames_PlayerFrame_ToVehicleArt);
	hooksecurefunc("PetFrame_Update", Nidhaus_UnitFrames_PetFrame_Update);
	
	-- Aplicar backdrop
	ApplyBackdrop();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if isInitialized and C.PlayerFrameScale then
		K.ApplyPlayerFrameScale(C.PlayerFrameScale);
	end
end);

-- FIX: Re-apply textures when UI scale or display mode changes
-- Blizzard resets PlayerFrameTexture/PVP icons to defaults on these events
local playerFrameEventWatcher = CreateFrame("Frame");
playerFrameEventWatcher:RegisterEvent("UI_SCALE_CHANGED");
playerFrameEventWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED");
playerFrameEventWatcher:SetScript("OnEvent", function(self)
	if not isInitialized then return; end
	-- Small delay to let Blizzard finish its own updates first
	local elapsed = 0;
	self:SetScript("OnUpdate", function(s, dt)
		elapsed = elapsed + dt;
		if elapsed >= 0.15 then
			s:SetScript("OnUpdate", nil);
			Nidhaus_UnitFrames_Style_PlayerFrame(PlayerFrame);
			Nidhaus_UnitFrames_PetFrame_Update(PetFrame, true);
			playerPvpIcon();
		end
	end);
end);