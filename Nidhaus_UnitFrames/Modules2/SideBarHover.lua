local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local BARS = { "MultiBarLeft", "MultiBarRight" };

local LINGER = 5;
local FADE   = 3;
local TICK   = 0.05;

local ticker = CreateFrame("Frame");
ticker:Hide();
local acc = 0;
local lastOver = {};

local function SetBarsAlpha(a)
	for _, name in ipairs(BARS) do
		local f = _G[name];
		if f and f.SetAlpha then f:SetAlpha(a); end
	end
end

local function AlphaFor(name, t)
	local idle = t - (lastOver[name] or t);
	if idle <= LINGER then return 1; end
	if idle >= LINGER + FADE then return 0; end
	local a = 1 - (idle - LINGER) / FADE;

	if a < 0.01 then a = 0; end
	return a;
end

ticker:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < TICK then return; end
	acc = 0;

	local t = GetTime();
	local forced = K.IsGlobalUnlocked and K.IsGlobalUnlocked();
	for _, name in ipairs(BARS) do
		local f = _G[name];
		if f and f:IsShown() then
			if forced or MouseIsOver(f) then lastOver[name] = t; end
			local a = AlphaFor(name, t);
			local cur = f:GetAlpha() or 1;

			if cur - a > 0.001 or a - cur > 0.001 then f:SetAlpha(a); end
		end
	end
end);

function K.ApplySideBarHover()
	if C.SideBarsHover then
		if not ticker:IsShown() then

			local t = GetTime();
			for _, name in ipairs(BARS) do lastOver[name] = t; end
		end
		acc = 0;
		ticker:Show();
	else
		ticker:Hide();
		SetBarsAlpha(1);
	end
end

local ev = CreateFrame("Frame");
ev:RegisterEvent("PLAYER_ENTERING_WORLD");
ev:SetScript("OnEvent", function()
	if K.ApplySideBarHover then K.ApplySideBarHover(); end
end);
