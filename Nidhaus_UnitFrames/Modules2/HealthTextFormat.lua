











local AddOnName, ns = ...;
local K, C, L = unpack(ns);



local function IsPartyBar(statusBar)
	local n = statusBar and statusBar.GetName and statusBar:GetName();
	if not n then return false; end
	return string.find(n, "^PartyMemberFrame%d") ~= nil;
end










local function IsArenaBar(statusBar)
	local n = statusBar and statusBar.GetName and statusBar:GetName();
	if not n then return false; end
	return string.find(n, "^ArenaEnemyFrame") ~= nil
		or string.find(n, "^NUF_Arena") ~= nil;
end

local function OnTextStatusBarUpdateTextString(statusBar)
	local textString = statusBar and statusBar.TextString;
	if not textString then return; end



	if IsPartyBar(statusBar) then
		textString:SetAlpha(C.PartyHideHealthManaText and 0 or 1);
	end

	if not C.ShowCurrentValueOnly then return; end
	if IsArenaBar(statusBar) then return; end

	local value = statusBar.finalValue or statusBar:GetValue();
	if statusBar.currValue and statusBar.currValue > 0 then
		textString:SetText(value);
	end
end

if TextStatusBar_UpdateTextString then
	hooksecurefunc("TextStatusBar_UpdateTextString", OnTextStatusBarUpdateTextString);
end









local TRACKED_BARS = {
	"PlayerFrameHealthBar", "PlayerFrameManaBar",
	"TargetFrameHealthBar", "TargetFrameManaBar",
	"FocusFrameHealthBar", "FocusFrameManaBar",
	"PetFrameHealthBar", "PetFrameManaBar",
	"PartyMemberFrame1HealthBar", "PartyMemberFrame1ManaBar",
	"PartyMemberFrame2HealthBar", "PartyMemberFrame2ManaBar",
	"PartyMemberFrame3HealthBar", "PartyMemberFrame3ManaBar",
	"PartyMemberFrame4HealthBar", "PartyMemberFrame4ManaBar",
};

local MAX_ARENA_HT = MAX_ARENA_ENEMIES or 5;





local htfPending = false;

function K.ApplyHealthTextFormat()
	if not TextStatusBar_UpdateTextString then return; end
	if InCombatLockdown() then htfPending = true; return; end
	htfPending = false;

	for i = 1, #TRACKED_BARS do
		local bar = _G[TRACKED_BARS[i]];
		if bar then
			pcall(TextStatusBar_UpdateTextString, bar);
		end
	end

	for i = 1, MAX_ARENA_HT do
		local hb = _G["ArenaEnemyFrame"..i.."HealthBar"];
		local mb = _G["ArenaEnemyFrame"..i.."ManaBar"];
		if hb then pcall(TextStatusBar_UpdateTextString, hb); end
		if mb then pcall(TextStatusBar_UpdateTextString, mb); end
	end
end

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
initFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
initFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_REGEN_ENABLED" then
		if htfPending then K.ApplyHealthTextFormat(); end
		return;
	end
	self:UnregisterEvent("PLAYER_ENTERING_WORLD");
	K.ApplyHealthTextFormat();
end);
