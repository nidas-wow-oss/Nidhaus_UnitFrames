

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local frame = CreateFrame("Frame");

frame:RegisterEvent("PLAYER_REGEN_DISABLED");
frame:RegisterEvent("PLAYER_REGEN_ENABLED");



frame:RegisterEvent("PLAYER_LOGIN");

frame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN");
		if UIErrorsFrame and not UIErrorsFrame:IsShown() then
			UIErrorsFrame:Show();
		end
		return;
	end



	if event == "PLAYER_REGEN_ENABLED" then
		if UIErrorsFrame and not UIErrorsFrame:IsShown() then
			UIErrorsFrame:Show();
		end
		return;
	end

	if event == "PLAYER_REGEN_DISABLED" then
		if C.ErrorHideInCombat then
			UIErrorsFrame:Hide();
		end
	end
end);