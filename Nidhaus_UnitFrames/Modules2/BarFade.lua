local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local LINGER = 5;
local FADE   = 3;
local TICK   = 0.05;

local MICRO_BUTTONS = {
	"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
	"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
	"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
};

local function BagsAlphaFrames(out)
	if BagPackFrame then out[#out + 1] = BagPackFrame; end
	for _, name in ipairs(MICRO_BUTTONS) do
		local b = _G[name];
		if b then out[#out + 1] = b; end
	end
	return out;
end

local function BagsOver()
	if BagPackFrame and BagPackFrame:IsVisible() and MouseIsOver(BagPackFrame) then return true; end
	for _, name in ipairs(MICRO_BUTTONS) do
		local b = _G[name];
		if b and b:IsVisible() and MouseIsOver(b) then return true; end
	end
	return false;
end

local groups = {
	bags = { setting = "BarsFadeBags", frames = BagsAlphaFrames, over = BagsOver },
};
for _, g in pairs(groups) do
	g.applied = {};
	g.lastOver = 0;
	g.active = false;
end

local scratchList, scratchSet, scratchTop, scratchNow = {}, {}, {}, {};

local function TopLevelOnly(list)
	wipe(scratchSet); wipe(scratchTop);
	for _, f in ipairs(list) do scratchSet[f] = true; end
	for _, f in ipairs(list) do
		local p, nested = f:GetParent(), false;
		while p do
			if scratchSet[p] then nested = true; break; end
			p = p:GetParent();
		end
		if not nested then scratchTop[#scratchTop + 1] = f; end
	end
	return scratchTop;
end

local function Release(g)
	for f in pairs(g.applied) do
		pcall(f.SetAlpha, f, 1);
		g.applied[f] = nil;
	end
	g.active = false;
end

local function SetGroupAlpha(g, a)
	local frames = TopLevelOnly(g.frames(wipe(scratchList)));
	local now = wipe(scratchNow);
	for _, f in ipairs(frames) do
		now[f] = true;

		local cur = f:GetAlpha() or 1;
		if g.applied[f] ~= a or cur - a > 0.01 or a - cur > 0.01 then
			f:SetAlpha(a);
			g.applied[f] = a;
		end
	end

	for f in pairs(g.applied) do
		if not now[f] then
			pcall(f.SetAlpha, f, 1);
			g.applied[f] = nil;
		end
	end
end

local function AlphaFor(g, t)
	local idle = t - g.lastOver;
	if idle <= LINGER then return 1; end
	if idle >= LINGER + FADE then return 0; end
	return 1 - (idle - LINGER) / FADE;
end

local function ForceShown()
	if UnitHasVehicleUI and UnitHasVehicleUI("player") then return true; end
	if K.IsGlobalUnlocked and K.IsGlobalUnlocked() then return true; end
	return false;
end

local function ModeActive()
	if K.IsAnyBarModeActive then return K.IsAnyBarModeActive(); end
	return (C.UnifyActionBars == true) or (C.MiniBarEnabled == true);
end

local ticker = CreateFrame("Frame");
ticker:Hide();
local acc = 0;

local function Step(t)
	local mode = ModeActive();
	local forced = ForceShown();
	for _, g in pairs(groups) do
		if C[g.setting] == true and mode then
			if not g.active then

				g.active = true;
				g.lastOver = t;
			end
			if forced or g.over() then g.lastOver = t; end
			SetGroupAlpha(g, AlphaFor(g, t));
		elseif g.active or next(g.applied) then
			Release(g);
		end
	end
end

ticker:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < TICK then return; end
	acc = 0;
	Step(GetTime());
end);

function K.ApplyBarFade()
	local any = (C.BarsFadeBags == true);
	if any then
		acc = TICK;
		ticker:Show();
	else
		ticker:Hide();
	end

	Step(GetTime());
end

local ev = CreateFrame("Frame");
ev:RegisterEvent("PLAYER_ENTERING_WORLD");
ev:SetScript("OnEvent", function()
	K.ApplyBarFade();
end);
