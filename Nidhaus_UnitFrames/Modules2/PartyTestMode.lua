local AddOnName, ns = ...;
local K, C, L = unpack(ns);










local MAX_PARTY = MAX_PARTY_MEMBERS or 4;

local active = false;








local hideHooked = {};
local reshowing = false;
local function HookHideForTest(frame)
	if hideHooked[frame] then return; end
	hideHooked[frame] = true;
	hooksecurefunc(frame, "Hide", function(self)
		if reshowing or not active or InCombatLockdown() then return; end
		reshowing = true;
		self:Show();
		reshowing = false;
	end);
end

local FAKE = {
	{ name = "Party 1", class = "PALADIN", hp = 0.85, mp = 0.60 },
	{ name = "Party 2", class = "MAGE",    hp = 0.55, mp = 0.90 },
	{ name = "Party 3", class = "ROGUE",   hp = 1.00, mp = 0.45 },
	{ name = "Party 4", class = "PRIEST",  hp = 0.30, mp = 0.75 },
};




local function GetClassColor(class)
	local color = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class])
		or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]);
	if color then return color.r, color.g, color.b; end
	return 0, 1, 0;
end

local function FillFrame(frame, index)
	local data = FAKE[index];
	if not data then return; end


	local nameFS = frame.name or _G["PartyMemberFrame" .. index .. "Name"];
	if nameFS and nameFS.SetText then nameFS:SetText(data.name); end


	local hb = frame.healthbar or _G["PartyMemberFrame" .. index .. "HealthBar"];
	if hb then
		hb:SetMinMaxValues(0, 100);
		hb:SetValue(data.hp * 100);
		if C.classColor then
			hb:SetStatusBarColor(GetClassColor(data.class));
		else
			hb:SetStatusBarColor(0, 1, 0);
		end
		local hbText = _G[hb:GetName() and (hb:GetName() .. "Text") or ""];
		if hbText then hbText:SetText(math.floor(data.hp * 100) .. "%"); end
	end


	local mb = frame.manabar or _G["PartyMemberFrame" .. index .. "ManaBar"];
	if mb then
		mb:SetMinMaxValues(0, 100);
		mb:SetValue(data.mp * 100);
		mb:SetStatusBarColor(0, 0, 1);
	end


	local portrait = _G["PartyMemberFrame" .. index .. "Portrait"];
	if portrait then
		portrait:SetTexture("Interface\\CharacterFrame\\TempPortrait");
		portrait:SetVertexColor(1, 1, 1, 1);
	end
end




local function Enable()
	if active then return; end
	if InCombatLockdown() then
		print("|cffFF5555NUF:|r " .. (L["PARTYTEST_COMBAT"]
			or "Cannot start party test mode during combat."));
		return;
	end
	active = true;

	for i = 1, MAX_PARTY do
		local frame = _G["PartyMemberFrame" .. i];
		if frame then

			HookHideForTest(frame);


			if UnregisterUnitWatch then pcall(UnregisterUnitWatch, frame); end

			frame:Show();
			FillFrame(frame, i);
		end
	end


	if K.PartyBuffs_OnFramesMoved then pcall(K.PartyBuffs_OnFramesMoved); end
	if K.ApplyPartyFrameSpacing then pcall(K.ApplyPartyFrameSpacing); end
	if C.PartyMode3v3 and K.Apply3v3PartyMode then pcall(K.Apply3v3PartyMode); end

end

local function Disable()
	if not active then return; end
	active = false;

	for i = 1, MAX_PARTY do
		local frame = _G["PartyMemberFrame" .. i];
		if frame then

			if RegisterUnitWatch then pcall(RegisterUnitWatch, frame); end


			if not UnitExists("party" .. i) then
				frame:Hide();
			else
				if PartyMemberFrame_UpdateMember then
					pcall(PartyMemberFrame_UpdateMember, frame);
				end
			end
		end
	end

	if K.PartyBuffs_OnFramesMoved then pcall(K.PartyBuffs_OnFramesMoved); end
end

function K.SetPartyTestMode(state)
	if state then Enable(); else Disable(); end
end

function K.TogglePartyTestMode()
	K.SetPartyTestMode(not active);
end

function K.IsPartyTestMode()
	return active;
end


local combatGuard = CreateFrame("Frame");
combatGuard:RegisterEvent("PLAYER_REGEN_DISABLED");
combatGuard:SetScript("OnEvent", function()
	if active then Disable(); end
end);

SLASH_NUFPARTYTEST1 = "/nufparty";
SlashCmdList["NUFPARTYTEST"] = function()
	K.TogglePartyTestMode();
end
