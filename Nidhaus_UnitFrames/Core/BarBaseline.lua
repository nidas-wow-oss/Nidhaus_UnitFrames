local AddOnName, ns = ...;
local K, C, L = unpack(ns);








































local BAR_FRAMES = {
	"MainMenuBar", "MainMenuBarArtFrame",
	"MainMenuExpBar", "MainMenuBarMaxLevelBar",
	"ReputationWatchBar", "ReputationWatchStatusBar", "ReputationWatchStatusBarText",
	"MainMenuBarExpText", "ExhaustionTick",
	"MainMenuBarLeftEndCap", "MainMenuBarRightEndCap",


	"MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight",
	"BonusActionButton1", "PossessBarFrame", "PossessButton1",


	"ActionBarUpButton", "ActionBarDownButton", "MainMenuBarPageNumber",


	"PetActionBarFrame", "PetActionButton1", "PetActionBarHealthBar", "PetActionBarManaBar",
	"ShapeshiftBarFrame", "ShapeshiftButton1",
	"MultiCastActionBarFrame", "MainMenuBarVehicleLeaveButton",




	"MainMenuBarBackpackButton", "KeyRingButton",
	"CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot",


	"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
	"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
	"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
};

local baseline   = nil;
local capturing  = false;




local function SnapshotFrame(frame)
	local snap = {
		width  = frame.GetWidth  and frame:GetWidth()  or nil,
		height = frame.GetHeight and frame:GetHeight() or nil,
		scale  = frame.GetScale  and frame:GetScale()  or nil,
		alpha  = frame.GetAlpha  and frame:GetAlpha()  or nil,
		shown  = frame.IsShown   and frame:IsShown()   or false,
		parent = frame.GetParent and frame:GetParent() or nil,
		points = {},
	};




	if frame.GetNumPoints and frame.GetPoint then
		for i = 1, (frame:GetNumPoints() or 0) do
			local p, rel, rp, x, y = frame:GetPoint(i);
			if p then
				snap.points[#snap.points + 1] = {
					point = p, rel = rel, relPoint = rp, x = x or 0, y = y or 0,
				};
			end
		end
	end

	return snap;
end


function K.EnsureBarBaseline()
	if baseline or capturing then return baseline ~= nil; end
	capturing = true;















	if K._habRelease then pcall(K._habRelease); end


	if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
	if MainMenuBar_UpdateExperienceBars then pcall(MainMenuBar_UpdateExperienceBars); end

	local snap, n = {}, 0;
	for _, name in ipairs(BAR_FRAMES) do
		local f = _G[name];
		if f then
			local ok, res = pcall(SnapshotFrame, f);
			if ok then snap[name] = res; n = n + 1; end
		end
	end

	baseline = snap;
	capturing = false;
	K._barBaselineCount = n;
	return true;
end




local function RestoreFrame(frame, snap)
	if not (frame and snap) then return; end



	if snap.parent and frame.SetParent and frame:GetParent() ~= snap.parent then
		frame:SetParent(snap.parent);
	end

	if frame.ClearAllPoints then frame:ClearAllPoints(); end
	for _, p in ipairs(snap.points) do
		pcall(frame.SetPoint, frame, p.point, p.rel, p.relPoint, p.x, p.y);
	end

	if snap.width  and snap.width  > 0 and frame.SetWidth  then frame:SetWidth(snap.width);   end
	if snap.height and snap.height > 0 and frame.SetHeight then frame:SetHeight(snap.height); end
	if snap.scale  and snap.scale  > 0 and frame.SetScale  then frame:SetScale(snap.scale);   end
	if snap.alpha  and frame.SetAlpha then frame:SetAlpha(snap.alpha); end







	if frame.Show and frame.Hide then
		if snap.shown then frame:Show(); else frame:Hide(); end
	end
end



function K.RestoreBarBaseline()


	if K.RestoreActionBarButtonSpace then K.RestoreActionBarButtonSpace(); end
	if K.DetachStanceButtons then K.DetachStanceButtons(); end

	if not baseline then return false; end
	if InCombatLockdown() then return false; end

	for name, snap in pairs(baseline) do
		local f = _G[name];
		if f then pcall(RestoreFrame, f, snap); end
	end


	if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
	if MainMenuBar_UpdateExperienceBars then pcall(MainMenuBar_UpdateExperienceBars); end
	return true;
end

function K.HasBarBaseline() return baseline ~= nil; end













