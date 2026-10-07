local AddOnName, ns = ...;
local K, C, L = unpack(ns);




















local TEX_PATH = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\PartyFramesImproved\\Textures\\";
local TEX_FRAME   = TEX_PATH .. "PartyFramesImproved-UI-PartyFrame";
local TEX_FLASH   = TEX_PATH .. "PartyFramesImproved-UI-PARTYFRAME-FLASH";
local TEX_VEHICLE = TEX_PATH .. "PartyFramesImproved-UI-VEHICLES-PARTYFRAME";

local MAX_PARTY = MAX_PARTY_MEMBERS or 4;

local enabled  = false;
local hooked   = false;
local original = {};




local function CaptureOriginal(i)
	if original[i] then return; end

	local name     = _G["PartyMemberFrame" .. i .. "Name"];
	local hptext   = _G["PartyMemberFrame" .. i .. "HealthBarText"];
	local manatext = _G["PartyMemberFrame" .. i .. "ManaBarText"];
	local texture  = _G["PartyMemberFrame" .. i .. "Texture"];
	local flash    = _G["PartyMemberFrame" .. i .. "Flash"];
	local hpbar    = _G["PartyMemberFrame" .. i .. "HealthBar"];
	local bg       = _G["PartyMemberFrame" .. i .. "Background"];
	if not (name and texture and hpbar) then return; end

	local o = {};

	local f, s, fl = name:GetFont();
	o.nameFont = { f, s, fl };
	o.namePoint = { name:GetPoint() };

	if hptext then
		local hf, hs, hfl = hptext:GetFont();
		o.hpFont = { hf, hs, hfl };
	end
	if manatext then
		local mf, ms, mfl = manatext:GetFont();
		o.manaFont = { mf, ms, mfl };
	end

	o.texture      = texture:GetTexture();
	o.texturePoint = { texture:GetPoint() };

	if flash then
		o.flash      = flash:GetTexture();
		o.flashPoint = { flash:GetPoint() };
	end

	o.hpPoint  = { hpbar:GetPoint() };
	o.hpHeight = hpbar:GetHeight();



	local hpTex = hpbar.GetStatusBarTexture and hpbar:GetStatusBarTexture();
	if hpTex then o.hpBarTexture = hpTex:GetTexture(); end
	local manabar0 = _G["PartyMemberFrame" .. i .. "ManaBar"];
	if manabar0 then
		local mTex = manabar0.GetStatusBarTexture and manabar0:GetStatusBarTexture();
		if mTex then o.manaBarTexture = mTex:GetTexture(); end
	end

	if bg then
		o.bgPoint  = { bg:GetPoint() };
		o.bgHeight = bg:GetHeight();
		o.bgWidth  = bg:GetWidth();
	end

	original[i] = o;
end



local function SafeSetPoint(region, stored)
	if not (region and stored and stored[1]) then return; end
	region:ClearAllPoints();
	region:SetPoint(stored[1], stored[2] or region:GetParent(),
		stored[3] or stored[1], stored[4] or 0, stored[5] or 0);
end




local function StyleFrame(i)
	local name     = _G["PartyMemberFrame" .. i .. "Name"];
	local hptext   = _G["PartyMemberFrame" .. i .. "HealthBarText"];
	local manatext = _G["PartyMemberFrame" .. i .. "ManaBarText"];
	local texture  = _G["PartyMemberFrame" .. i .. "Texture"];
	local flash    = _G["PartyMemberFrame" .. i .. "Flash"];
	local hpbar    = _G["PartyMemberFrame" .. i .. "HealthBar"];
	local bg       = _G["PartyMemberFrame" .. i .. "Background"];
	if not (name and texture and hpbar) then return; end

	CaptureOriginal(i);





	local nameOutline = C.PartyFontOutline;
	if nameOutline == "" or nameOutline == "Blizz" then nameOutline = nil; end
	name:SetFont("Fonts\\FRIZQT__.TTF", 7, nameOutline);
	name:ClearAllPoints();
	name:SetPoint("TOPLEFT", 50, -4);





	texture:SetTexture(TEX_FRAME);
	texture:ClearAllPoints();
	texture:SetPoint("TOPLEFT", 0, 6);

	if flash then
		flash:SetTexture(TEX_FLASH);
		flash:ClearAllPoints();
		flash:SetPoint("TOPLEFT", 0, 6);
	end

	hpbar:ClearAllPoints();
	hpbar:SetPoint("TOPLEFT", 47, -3);
	hpbar:SetHeight(17);

	if bg then
		bg:ClearAllPoints();
		bg:SetPoint("TOPLEFT", 46, -3);
		bg:SetHeight(24);
		bg:SetWidth(70);
	end





	if C.statusbarOn and C.statusbarTexture then
		hpbar:SetStatusBarTexture(C.statusbarTexture);
		local manabar = _G["PartyMemberFrame" .. i .. "ManaBar"];
		if manabar then manabar:SetStatusBarTexture(C.statusbarTexture); end
	end
end

local function RestoreFrame(i)
	local o = original[i];
	if not o then return; end

	local name     = _G["PartyMemberFrame" .. i .. "Name"];
	local hptext   = _G["PartyMemberFrame" .. i .. "HealthBarText"];
	local manatext = _G["PartyMemberFrame" .. i .. "ManaBarText"];
	local texture  = _G["PartyMemberFrame" .. i .. "Texture"];
	local flash    = _G["PartyMemberFrame" .. i .. "Flash"];
	local hpbar    = _G["PartyMemberFrame" .. i .. "HealthBar"];
	local bg       = _G["PartyMemberFrame" .. i .. "Background"];

	if name and o.nameFont then
		name:SetFont(o.nameFont[1], o.nameFont[2], o.nameFont[3]);
		SafeSetPoint(name, o.namePoint);
	end


	if texture then
		texture:SetTexture(o.texture);
		SafeSetPoint(texture, o.texturePoint);
	end
	if flash and o.flash then
		flash:SetTexture(o.flash);
		SafeSetPoint(flash, o.flashPoint);
	end
	if hpbar then
		SafeSetPoint(hpbar, o.hpPoint);
		if o.hpHeight then hpbar:SetHeight(o.hpHeight); end
	end
	if o.hpBarTexture and hpbar.SetStatusBarTexture then
		hpbar:SetStatusBarTexture(o.hpBarTexture);
	end
	if o.manaBarTexture then
		local manabar = _G["PartyMemberFrame" .. i .. "ManaBar"];
		if manabar then manabar:SetStatusBarTexture(o.manaBarTexture); end
	end

	if bg then
		SafeSetPoint(bg, o.bgPoint);
		if o.bgHeight then bg:SetHeight(o.bgHeight); end
		if o.bgWidth  then bg:SetWidth(o.bgWidth); end
	end
end

local function StyleAll()
	if InCombatLockdown() then return; end
	for i = 1, MAX_PARTY do StyleFrame(i); end
end

local function RestoreAll()
	if InCombatLockdown() then return; end
	for i = 1, MAX_PARTY do RestoreFrame(i); end
end





K.PFI_Restyle = function()
	local style = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or "Default";
	if style ~= "Improved" then return; end
	StyleAll();
end






local function InstallHooks()
	if hooked then return; end
	hooked = true;

	if type(PartyMemberFrame_ToPlayerArt) == "function" then
		hooksecurefunc("PartyMemberFrame_ToPlayerArt", function()
			if enabled then StyleAll(); end
		end);
	end

	if type(PartyMemberFrame_ToVehicleArt) == "function" then
		hooksecurefunc("PartyMemberFrame_ToVehicleArt", function()
			if not enabled or InCombatLockdown() then return; end
			for i = 1, MAX_PARTY do
				local tex = _G["PartyMemberFrame" .. i .. "VehicleTexture"];
				if tex then tex:SetTexture(TEX_VEHICLE); end
			end
		end);
	end

	if type(PartyMemberFrame_UpdateMember) == "function" then
		hooksecurefunc("PartyMemberFrame_UpdateMember", function()
			if enabled then StyleAll(); end
		end);
	end





	local function ReapplyBarTexture(self)
		if not enabled or not self then return; end
		if not (C.statusbarOn and C.statusbarTexture) then return; end
		local parent = self:GetParent();
		local n = parent and parent.GetName and parent:GetName();
		if n and string.find(n, "^PartyMemberFrame%d+$") then
			self:SetStatusBarTexture(C.statusbarTexture);
		end
	end

	if type(UnitFrameHealthBar_Update) == "function" then
		hooksecurefunc("UnitFrameHealthBar_Update", ReapplyBarTexture);
	end
	if type(UnitFrameManaBar_Update) == "function" then
		hooksecurefunc("UnitFrameManaBar_Update", ReapplyBarTexture);
	end
end

local events = CreateFrame("Frame");
events:SetScript("OnEvent", function()
	if enabled then StyleAll(); end
end);




K.RegisterModule("PartyFramesImproved", {
	name    = L["MOD_PFI"] or "Party Frames Improved",
	desc    = L["MOD_PFI_DESC"]
		or "Wider, cleaner texture for the party frames, with smaller name / health / mana text and a bigger health bar.",
	default = false,
	onEnable = function()
		enabled = true;
		InstallHooks();
		StyleAll();
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
		events:RegisterEvent("PARTY_MEMBERS_CHANGED");


		if K.NotifyPartyStyleFromModule then K.NotifyPartyStyleFromModule("Improved"); end
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		RestoreAll();
		if K.NotifyPartyStyleFromModule and K.GetPartyFrameStyle
			and K.GetPartyFrameStyle() == "Improved" then
			K.NotifyPartyStyleFromModule("Default");
		end
	end,
});
