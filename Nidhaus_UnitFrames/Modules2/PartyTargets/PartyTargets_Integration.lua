local AddOnName, ns = ...;
local K, C, L = unpack(ns);










local PT_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"PARTY_MEMBERS_CHANGED",
	"PARTY_MEMBER_ENABLE",
	"PARTY_MEMBER_DISABLE",
	"PARTY_LOOT_METHOD_CHANGED",
	"VARIABLES_LOADED",
	"UNIT_FACTION",
	"UNIT_TARGET",
	"UNIT_PVP_UPDATE",
	"UNIT_HEALTH",
	"UNIT_MAXHEALTH",
	"UNIT_MANA",
	"UNIT_ENERGY",
	"UNIT_FOCUS",
	"UNIT_RAGE",
	"UNIT_RUNIC_POWER",
};


local function DisableTargetFrame(frame)
	if not frame then return; end

	UnregisterUnitWatch(frame);

	for _, evt in ipairs(PT_EVENTS) do
		frame:UnregisterEvent(evt);
	end

	frame:Hide();
	frame:SetScript("OnUpdate", nil);
end


local function EnableTargetFrame(frame)
	if not frame then return; end

	RegisterUnitWatch(frame);

	for _, evt in ipairs(PT_EVENTS) do
		frame:RegisterEvent(evt);
	end

	local PT = LibStub and LibStub("PartyTargets-3.3", true);
	if PT and PT.OnUpdate then
		frame:SetScript("OnUpdate", function(self, elapsed)
			PT.OnUpdate(self, elapsed);
		end);
	end
end


function K.ApplyPartyTargetsState(enabled)
	for i = 1, MAX_PARTY_MEMBERS do
		local frame = _G["PartyTargetFrame"..i];
		if frame then
			if enabled then
				EnableTargetFrame(frame);
			else
				DisableTargetFrame(frame);
			end
		end
	end
end


K.RegisterConfigEvent("CONFIG_LOADED", function()

	local delayFrame = CreateFrame("Frame");
	delayFrame:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil);
		if C.PartyTargetsEnabled == false then
			K.ApplyPartyTargetsState(false);
		end
	end);
end);




local pewGuard = CreateFrame("Frame");
local pewDelay = CreateFrame("Frame");
pewDelay:Hide();
pewDelay:SetScript("OnUpdate", function(s)
	s:SetScript("OnUpdate", nil);
	s:Hide();
	if C.PartyTargetsEnabled == false then
		K.ApplyPartyTargetsState(false);
	end
end);

pewGuard:RegisterEvent("PLAYER_ENTERING_WORLD");
pewGuard:SetScript("OnEvent", function(self, event)
	if C.PartyTargetsEnabled == false then

		pewDelay:Show();
		pewDelay:SetScript("OnUpdate", function(s)
			s:SetScript("OnUpdate", nil);
			s:Hide();
			if C.PartyTargetsEnabled == false then
				K.ApplyPartyTargetsState(false);
			end
		end);
	end
end);