local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hooksecurefunc = hooksecurefunc;
local UnitFactionGroup, UnitIsPVP, UnitIsVisible, UnitPowerMax = UnitFactionGroup, UnitIsPVP, UnitIsVisible, UnitPowerMax;
local unpack = unpack;

local isInitialized = false;





local ASURI = "Interface\\AddOns\\"..AddOnName.."\\Media\\Asuri\\";








local function ThemeDir()
	local base = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\";
	if C.pwFrames   then return base .. "pw\\";   end
	if C.darkFrames then return base .. "Dark\\"; end
	return base .. "Light\\";
end












local playerClass;

local function IcyOn()
	if not playerClass then playerClass = select(2, UnitClass("player")); end
	return (C.MageIcyFrame and playerClass == "MAGE") and true or false;
end
K.IcyPlayerFrameOn = IcyOn;

local function AsuriOn()
	return C.UnitFrameCustomTexture and C.AsuriFrames and not IcyOn();
end






local function UpdateGroupIndicator()
	if not PlayerFrameGroupIndicatorText then return; end
	local _, instanceType = IsInInstance();
	PlayerFrameGroupIndicatorText:SetAlpha(instanceType == "arena" and 0 or 1);
end




local groupIndicatorWatcher = CreateFrame("Frame");
groupIndicatorWatcher:RegisterEvent("PLAYER_ENTERING_WORLD");
groupIndicatorWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA");
groupIndicatorWatcher:SetScript("OnEvent", UpdateGroupIndicator);




local function SkinLayoutOn()
	return IcyOn() or C.UnitFrameCustomTexture;
end

local origNameFont;






local BIG_NAME_Y = 35;

local function BigTextOn()
	return K.BigStatusTextOn and K.BigStatusTextOn("player") or false;
end




local function OutlineName(fs)
	if not fs or not fs.GetFont then return; end
	local face, size = fs:GetFont();
	if face and size then pcall(fs.SetFont, fs, face, size, "OUTLINE"); end
	fs:SetShadowOffset(1, -1);
end
K.OutlineBigName = OutlineName;

local function InitializePlayerFrame()
	if isInitialized then return; end
	




	K.CaptureTexture(PlayerFrameTexture, "PlayerFrameTexture");
	K.CaptureTexture(PlayerPVPIcon, "PlayerPVPIcon");
	K.CaptureTexture(PlayerStatusTexture, "PlayerStatusTexture");
	K.CaptureAnchors(PlayerStatusTexture, "PlayerStatusTextureAnchor");
	

	K.MoveFrame(PlayerFrame, "NidhausPlayerFrame", "Player", 105, 27);





	if PlayerFrame.healthbar then
		K.CaptureBarGeometry(PlayerFrame.healthbar, "PlayerHealthBar");
		K.CaptureAnchors(PlayerFrame.healthbar, "PlayerHealthBarAnchors");
		if PlayerFrame.healthbar.TextString then
			K.CaptureAnchors(PlayerFrame.healthbar.TextString, "PlayerHealthText");
		end
	end


	if C.PlayerFrameScale and type(C.PlayerFrameScale) == "number" and C.PlayerFrameScale > 0 and C.PlayerFrameScale <= 3 then
		if NidhausPlayerFrame then 
			NidhausPlayerFrame:SetScale(C.PlayerFrameScale); 
		end
	end
	
	if PlayerFrame.manabar then
		K.CaptureAnchors(PlayerFrame.manabar, "PlayerManaBarAnchors");
	end





	if PlayerFrame.name then
		K.CaptureAnchors(PlayerFrame.name, "PlayerName");
	end



	if PlayerFrameBackground and not PlayerFrameBackground._nufOrig then
		PlayerFrameBackground._nufOrig = {
			w = PlayerFrameBackground:GetWidth(),
			h = PlayerFrameBackground:GetHeight(),
			pts = { PlayerFrameBackground:GetPoint(1) },
		};
	end

	if PlayerFrame.name and not origNameFont then
		origNameFont = PlayerFrame.name:GetFontObject();
	end

	isInitialized = true;
end


local function Nidhaus_UnitFrames_Style_PlayerFrame(self)
	if C.statusbarOn then
		self.healthbar:SetStatusBarTexture(C.statusbarTexture);
		self.manabar:SetStatusBarTexture(C.statusbarTexture);
	end;
	if AsuriOn() then




		PlayerStatusTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\UI-Player-Status3");
		PlayerStatusTexture:ClearAllPoints();
		PlayerStatusTexture:SetPoint("CENTER", NidhausPlayerFrame, "CENTER", 16, 8);
	elseif SkinLayoutOn() then
		PlayerStatusTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\UI-Player-Status2");
		PlayerStatusTexture:ClearAllPoints();
		PlayerStatusTexture:SetPoint("CENTER", NidhausPlayerFrame, "CENTER", 16, 8);
	else

		K.RestoreTexture(PlayerStatusTexture, "PlayerStatusTexture");
		K.RestoreAnchors(PlayerStatusTexture, "PlayerStatusTextureAnchor");
	end
	PlayerFrameGroupIndicatorText:ClearAllPoints();
	PlayerFrameGroupIndicatorText:SetPoint("BOTTOMLEFT", NidhausPlayerFrame, "TOP", 0, -20);
	PlayerFrameGroupIndicatorLeft:Hide();
	PlayerFrameGroupIndicatorMiddle:Hide();
	PlayerFrameGroupIndicatorRight:Hide();
	UpdateGroupIndicator();
	










	if IcyOn() then

		PlayerFrameTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\icy.tga");
		PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
	elseif not C.UnitFrameCustomTexture then
		K.RestoreTexture(PlayerFrameTexture, "PlayerFrameTexture");
		K.RestoreTexture(PlayerPVPIcon, "PlayerPVPIcon");
	elseif C.AsuriFrames then
		PlayerFrameTexture:SetTexture(ASURI.."AsuriFrame");
		PlayerFrameTexture:SetVertexColor(0.25, 0.25, 0.25);
		PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
	else
		PlayerFrameTexture:SetTexture(ThemeDir() .. "UI-TargetingFrame");


		if C.darkFrames or C.pwFrames then
			PlayerPVPIcon:SetTexture(ThemeDir() .. "UI-PVP-FFA");
		else
			PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
		end
	end;








	if IcyOn() then

		PlayerFrameTexture:SetVertexColor(1, 1, 1);
	elseif not C.AsuriFrames then
		if not (K.ApplyLortiTint and K.ApplyLortiTint(PlayerFrameTexture,
			"LortiUI_PlayerTargetFocus")) then
			PlayerFrameTexture:SetVertexColor(1, 1, 1);
		end
	end
end;

local function Nidhaus_UnitFrames_PlayerFrame_ToPlayerArt(self)

	Nidhaus_UnitFrames_Style_PlayerFrame(self);



	K.RestoreAnchors(self.name, "PlayerName");
	if C.PlayerNameOffset and type(C.PlayerNameOffset) == "table" then
		self.name:SetPoint(K.SetOffset(self.name, unpack(C.PlayerNameOffset)));
	end

	if AsuriOn() then



		self.name:SetAlpha(1);
		if origNameFont then self.name:SetFontObject(origNameFont); end
		local nameHost = _G["NidhausPlayerFrame"] or self;
		self.name:ClearAllPoints();
		self.name:SetPoint("CENTER", nameHost, "CENTER", 50, 25);
	elseif origNameFont then
		self.name:SetAlpha(1);
		self.name:SetFontObject(origNameFont);
		self.name:SetShadowOffset(1, -1);
	end





	if BigTextOn() then
		local nameHost = _G["NidhausPlayerFrame"] or self;
		self.name:ClearAllPoints();
		self.name:SetPoint("CENTER", nameHost, "CENTER", 50, BIG_NAME_Y);
		OutlineName(self.name);
	end





	if PlayerLevelText then


		local hideLevel = (not IcyOn())
			and (AsuriOn() or (C.UnitFrameCustomTexture and C.pwFrames));
		PlayerLevelText:SetAlpha(hideLevel and 0 or 1);
	end
	
	if AsuriOn() then
		local host = _G["NidhausPlayerFrame"] or self;
		K.RestoreAnchors(self.healthbar, "PlayerHealthBarAnchors");
		self.healthbar:ClearAllPoints();
		self.healthbar:SetPoint("CENTER", host, "CENTER", 50, 7);
		self.healthbar:SetHeight(16);
		self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, 0);
		if self.manabar then
			self.manabar:ClearAllPoints();
			self.manabar:SetPoint("CENTER", host, "CENTER", 50, -7);
			self.manabar:SetHeight(13);
		end
	elseif SkinLayoutOn() then




		K.RestoreAnchors(self.healthbar, "PlayerHealthBarAnchors");
		self.healthbar:SetPoint("TOPLEFT", 106, -24);
		self.healthbar:SetHeight(28);


		self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0,
			BigTextOn() and 0 or -5);
	else




		K.RestoreBarGeometry(self.healthbar, "PlayerHealthBar");
		K.RestoreAnchors(self.healthbar.TextString, "PlayerHealthText");
	end
	if not AsuriOn() and self.manabar then
		K.RestoreAnchors(self.manabar, "PlayerManaBarAnchors");
	end



	if PlayerFrameBackground then
		if AsuriOn() then
			PlayerFrameBackground:SetWidth(119);
			PlayerFrameBackground:SetHeight(29);
			PlayerFrameBackground:ClearAllPoints();
			PlayerFrameBackground:SetPoint("TOPLEFT", 106, -34);
		elseif PlayerFrameBackground._nufOrig then
			local o = PlayerFrameBackground._nufOrig;
			PlayerFrameBackground:SetWidth(o.w);
			PlayerFrameBackground:SetHeight(o.h);
			if o.pts and o.pts[1] then
				PlayerFrameBackground:ClearAllPoints();
				PlayerFrameBackground:SetPoint(o.pts[1], o.pts[2] or PlayerFrame,
					o.pts[3] or o.pts[1], o.pts[4] or 0, o.pts[5] or 0);
			end
		end
	end
	RuneFrame:ClearAllPoints();
	RuneFrame:SetPoint("TOP", NidhausPlayerFrame, "BOTTOM", 52, 34);

	PlayerFrameFlash:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash");
	PlayerFrameFlash:SetTexCoord(0.9453125, 0, 0, 0.181640625);
end;


local function playerPvpIcon()
	local factionGroup = UnitFactionGroup("player");
	if factionGroup and factionGroup ~= "Neutral" and UnitIsPVP("player") then
		if C.UnitFrameCustomTexture and (C.darkFrames or C.pwFrames) and not IcyOn() then
			PlayerPVPIcon:SetTexture(ThemeDir() .. "UI-PVP-" .. factionGroup);
		else

			PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);
		end;
	end;
end;


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


local function Nidhaus_UnitFrames_PetFrame_Update(self, override)
	if (not PlayerFrame.animating) or (override) then
		if UnitIsVisible(self.unit) and not PlayerFrame.vehicleHidesPet then
			if UnitPowerMax(self.unit) == 0 then
				PetFrameTexture:SetTexture(ThemeDir() .. "UI-SmallTargetingFrame-NoMana");
				PetFrameManaBarText:Hide();
			else
				PetFrameTexture:SetTexture(ThemeDir() .. "UI-SmallTargetingFrame");
			end;





			if not (K.ApplyLortiTint and K.ApplyLortiTint(PetFrameTexture,
				"LortiUI_PlayerTargetFocus")) then
				PetFrameTexture:SetVertexColor(1, 1, 1);
			end
		end;
	end;
end;


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








function K.ApplyPlayerFrameSkin()
	if not isInitialized then return; end

	if UnitInVehicle and UnitInVehicle("player") then return; end
	Nidhaus_UnitFrames_PlayerFrame_ToPlayerArt(PlayerFrame);
	playerPvpIcon();


	if K.InvalidateAbbrevAnchors then K.InvalidateAbbrevAnchors(); end
end


function K.ApplyPetFrameScale(scale)
	scale = scale or C.PetFrameScale or 1.0;
	if PetFrame then PetFrame:SetScale(scale); end
end

K.RegisterConfigEvent("CONFIG_LOADED", function()

	InitializePlayerFrame();


	if K.ApplyPetFrameScale then K.ApplyPetFrameScale(C.PetFrameScale); end
	

	Nidhaus_UnitFrames_Style_PlayerFrame(PlayerFrame);
	

	hooksecurefunc("PlayerFrame_ToPlayerArt", Nidhaus_UnitFrames_PlayerFrame_ToPlayerArt);
	hooksecurefunc("PlayerFrame_UpdatePvPStatus", playerPvpIcon);
	hooksecurefunc("PlayerFrame_ToVehicleArt", Nidhaus_UnitFrames_PlayerFrame_ToVehicleArt);
	hooksecurefunc("PetFrame_Update", Nidhaus_UnitFrames_PetFrame_Update);



	if type(PlayerFrame_UpdateGroupIndicator) == "function" then
		hooksecurefunc("PlayerFrame_UpdateGroupIndicator", UpdateGroupIndicator);
	end
	

	ApplyBackdrop();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if isInitialized and C.PlayerFrameScale then
		K.ApplyPlayerFrameScale(C.PlayerFrameScale);
	end
end);



local playerFrameEventWatcher = CreateFrame("Frame");
playerFrameEventWatcher:RegisterEvent("UI_SCALE_CHANGED");
playerFrameEventWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED");
playerFrameEventWatcher:SetScript("OnEvent", function(self)
	if not isInitialized then return; end

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