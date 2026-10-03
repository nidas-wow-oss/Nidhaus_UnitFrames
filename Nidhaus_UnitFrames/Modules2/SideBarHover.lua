local AddOnName, ns = ...;
local K, C, L = unpack(ns);


















local BARS = { "MultiBarLeft", "MultiBarRight" };

local ticker = CreateFrame("Frame");
ticker:Hide();
local acc = 0;

local function SetBarsAlpha(a)
	for _, name in ipairs(BARS) do
		local f = _G[name];
		if f and f.SetAlpha then f:SetAlpha(a); end
	end
end

ticker:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < 0.1 then return; end
	acc = 0;

	for _, name in ipairs(BARS) do
		local f = _G[name];
		if f and f:IsShown() then
			f:SetAlpha(MouseIsOver(f) and 1 or 0);
		end
	end
end);


function K.ApplySideBarHover()
	if C.SideBarsHover then
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
