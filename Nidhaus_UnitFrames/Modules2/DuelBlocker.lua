local AddOnName, ns = ...;
local K, C, L = unpack(ns);













local lastChallenger, lastTime = nil, 0;

local events = CreateFrame("Frame");
events:RegisterEvent("DUEL_REQUESTED");
events:SetScript("OnEvent", function(self, event, challenger)
	if not C.BlockDuels then return; end

	CancelDuel();


	if StaticPopup_Hide then
		StaticPopup_Hide("DUEL_REQUESTED");
	end


	local now = GetTime();
	if challenger and (challenger ~= lastChallenger or (now - lastTime) > 30) then
		lastChallenger, lastTime = challenger, now;
		print("|cff4FC3F7NUF:|r " .. string.format(
			L["DUEL_BLOCKED"] or "Duel from %s declined.", challenger));
	end
end);

SLASH_NUFDUEL1 = "/nufduel";
SlashCmdList["NUFDUEL"] = function()
	local v = not C.BlockDuels;
	K.SaveConfig("BlockDuels", v);
	if v then
		print("|cff4FC3F7NUF:|r " .. (L["DUEL_BLOCK_ON"] or "Duels are now declined automatically."));
	else
		print("|cff4FC3F7NUF:|r " .. (L["DUEL_BLOCK_OFF"] or "Duels are allowed again."));
	end
end
