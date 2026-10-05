local AddOnName, ns = ...;
local K, C, L = unpack(ns);




























local BARS = {};
do
	local list = {
		{ "PlayerFrameHealthBar", "player", true  }, { "PlayerFrameManaBar", "player", false },
		{ "TargetFrameHealthBar", "target", true  }, { "TargetFrameManaBar", "target", false },
		{ "FocusFrameHealthBar",  "focus",  true  }, { "FocusFrameManaBar",  "focus",  false },
	};
	for _, e in ipairs(list) do
		local bar = _G[e[1]];
		if bar then BARS[bar] = { unit = e[2], hp = e[3] }; end
	end
end

local function Clamp(v, def)
	v = tonumber(v) or def;
	v = math.floor(v + 0.5);
	if v < 8 then v = 8; elseif v > 16 then v = 16; end
	return v;
end



local origSize = {};

local function SetSize(fs, size)
	if not fs or not fs.GetFont then return; end
	local face, cur, flags = fs:GetFont();
	if not face then return; end
	if size then
		if not origSize[fs] then origSize[fs] = cur; end
		if not cur or math.abs(cur - size) > 0.05 then
			pcall(fs.SetFont, fs, face, size, flags);
		end
	else
		local o = origSize[fs];
		if o and cur and math.abs(cur - o) > 0.05 then
			pcall(fs.SetFont, fs, face, o, flags);
		end
	end
end

local function ApplyBar(bar, info)
	local size;
	if K.BigStatusSizeOn and K.BigStatusSizeOn(info.unit) then
		size = info.hp and Clamp(C.BigTextHealthSize, 12) or Clamp(C.BigTextManaSize, 10);
	end
	SetSize(bar.TextString, size);


	if K.MirrorAbbrevPct then K.MirrorAbbrevPct(bar); else SetSize(bar._nufPct, size); end
end






hooksecurefunc("TextStatusBar_UpdateTextString", function(bar)
	local info = BARS[bar];
	if info then pcall(ApplyBar, bar, info); end
end);

function K.RefreshBigStatusFonts()
	for bar, info in pairs(BARS) do pcall(ApplyBar, bar, info); end
end



function K.ApplyBigStatusText()
	if K.ApplyPlayerFrameSkin    then pcall(K.ApplyPlayerFrameSkin);    end
	if K.ApplyTargetFrameSkin    then pcall(K.ApplyTargetFrameSkin);    end
	if K.InvalidateAbbrevAnchors then pcall(K.InvalidateAbbrevAnchors); end
	K.RefreshBigStatusFonts();
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	K.RefreshBigStatusFonts();
end);
