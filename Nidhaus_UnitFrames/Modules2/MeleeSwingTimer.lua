local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local format, floor = string.format, math.floor;















local BAR_WIDTH  = 195;
local BAR_HEIGHT = 14;

local enabled  = false;
local unlocked = false;

local playerGUID;




local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.MeleeSwingTimer then
		NidhausUnitFramesDB.MeleeSwingTimer = { x = 0, y = 222, scale = 1.0 };
	end
	return NidhausUnitFramesDB.MeleeSwingTimer;
end




local mover = CreateFrame("Frame", "NUF_SwingMover", UIParent);
mover:SetSize(BAR_WIDTH + 4, BAR_HEIGHT + 4);
mover:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 222);
mover:SetMovable(true);
mover:SetClampedToScreen(true);
mover:EnableMouse(false);
mover:Hide();

local bar = CreateFrame("StatusBar", "NUF_SwingBar", mover);
bar:SetSize(BAR_WIDTH, BAR_HEIGHT);
bar:SetPoint("CENTER", mover, "CENTER", 0, 0);
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
local BAR_R, BAR_G, BAR_B = 0.85, 0.25, 0.25;
bar:SetStatusBarColor(BAR_R, BAR_G, BAR_B);
bar:SetMinMaxValues(0, 1);
bar:SetValue(1);

local bg = bar:CreateTexture(nil, "BACKGROUND");
bg:SetAllPoints(bar);
bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
bg:SetVertexColor(0.1, 0.1, 0.1, 0.75);

local border = CreateFrame("Frame", nil, bar);
border:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2);
border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2);
border:SetBackdrop({
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 12,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
});
border:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.9);

local spark = bar:CreateTexture(nil, "OVERLAY");
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
spark:SetSize(16, BAR_HEIGHT + 10);
spark:SetBlendMode("ADD");
spark:SetPoint("CENTER", bar, "LEFT", 0, 0);

local textLeft = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
textLeft:SetPoint("LEFT", bar, "LEFT", 4, 1);
textLeft:SetText(L["SWING_LABEL"] or "Auto attack");

local textRight = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
textRight:SetPoint("RIGHT", bar, "RIGHT", -4, 1);

local unlockOverlay = mover:CreateTexture(nil, "OVERLAY");
unlockOverlay:SetAllPoints(mover);
unlockOverlay:SetTexture(0, 0.8, 1, 0.25);
unlockOverlay:Hide();

local unlockText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
unlockText:SetPoint("CENTER", mover, "CENTER", 0, 0);
unlockText:SetText("|cff00ccff" .. (L["DRAG_LABEL"] or "DRAG") .. "|r");
unlockText:Hide();




local function SavePosition()
	local db = DB();
	local _, _, _, x, y = mover:GetPoint();
	db.x = x or 0;
	db.y = y or 222;
end

local function RestorePosition()
	local db = DB();
	mover:ClearAllPoints();
	mover:SetPoint("BOTTOM", UIParent, "BOTTOM", db.x or 0, db.y or 222);
	mover:SetScale(db.scale or 1.0);
end

mover:SetScript("OnMouseDown", function(self, btn)
	if btn == "LeftButton" and unlocked then self:StartMoving(); end
end);
mover:SetScript("OnMouseUp", function(self, btn)
	if btn == "LeftButton" and unlocked then
		self:StopMovingOrSizing();
		SavePosition();
	end
end);




local function ShowBar()
	if enabled or unlocked then mover:Show(); end
end

local function HideBar()
	if not unlocked then mover:Hide(); end
end















local castBorder;

local function CurrentBorderStyle()
	local v = C.SwingTimerBorderStyle;
	if v == "None" or v == "Blizzard" or v == "Tooltip" then return v; end

	if C.SwingTimerBorderless == true then return "None"; end
	return "Tooltip";
end

local function BorderTint(r, g, b, a)
	if castBorder and castBorder:IsShown() then




		if unlocked then
			castBorder:SetVertexColor(r, g, b, a);
		else
			castBorder:SetVertexColor(1, 1, 1, 1);
		end
	elseif border:IsShown() then
		border:SetBackdropBorderColor(r, g, b, a);
	end
end













local MATCH_BLIZZ_COLOR = false;
local DEFAULT_FILL = "Interface\\TargetingFrame\\UI-StatusBar";

local function ApplyLookForStyle(style)
	local blizz = (style == "Blizzard");

	local ref = _G.CastingBarFrameText;
	if blizz and ref then
		local f, size, flags = ref:GetFont();
		if f then
			textLeft:SetFont(f, size, flags);
			textRight:SetFont(f, size, flags);
		end
		local r, g, b = ref:GetTextColor();
		if r then
			textLeft:SetTextColor(r, g, b);
			textRight:SetTextColor(r, g, b);
		end
	else
		textLeft:SetFontObject(GameFontNormalSmall);
		textRight:SetFontObject(GameFontNormalSmall);
	end

	local cb  = _G.CastingBarFrame;
	local cbt = cb and cb.GetStatusBarTexture and cb:GetStatusBarTexture();
	local path = cbt and cbt.GetTexture and cbt:GetTexture();
	if blizz and path then
		bar:SetStatusBarTexture(path);
	else
		bar:SetStatusBarTexture(DEFAULT_FILL);
	end












	local cc = blizz and MATCH_BLIZZ_COLOR and _G.CASTING_BAR_COLOR;
	if cc and cc.r then
		bar:SetStatusBarColor(cc.r, cc.g, cc.b);
	else
		bar:SetStatusBarColor(BAR_R, BAR_G, BAR_B);
	end




	bg:SetTexture(DEFAULT_FILL);
	bg:SetVertexColor(0.1, 0.1, 0.1, 0.75);
	bg:Show();



	local sh = 32;
	local sp = _G.CastingBarFrameSpark;
	if sp and (sp:GetHeight() or 0) > 0 then sh = sp:GetHeight(); end
	spark:SetWidth(16);
	spark:SetHeight(sh);
end

local function ApplyBorderStyle()
	local style = CurrentBorderStyle();
	if castBorder then castBorder:Hide(); end
	border:Hide();

	if style == "Tooltip" then
		border:Show();
	elseif style == "Blizzard" then
		local src = _G.CastingBarFrameBorder;
		local ref = _G.CastingBarFrame;
		if src and ref and (ref:GetWidth() or 0) > 0 and (ref:GetHeight() or 0) > 0 then
			if not castBorder then
				castBorder = bar:CreateTexture(nil, "OVERLAY");
			end
			castBorder:SetTexture(src:GetTexture());
			castBorder:SetWidth(BAR_WIDTH   * (src:GetWidth()  / ref:GetWidth()));
			castBorder:SetHeight(BAR_HEIGHT * (src:GetHeight() / ref:GetHeight()));
			castBorder:ClearAllPoints();


			local _, sy = src:GetCenter();
			local _, ry = ref:GetCenter();
			local dy = (sy and ry) and ((sy - ry) * (BAR_HEIGHT / ref:GetHeight())) or 0;
			castBorder:SetPoint("CENTER", bar, "CENTER", 0, dy);
			castBorder:Show();
		else
			border:Show();
		end
	end

	ApplyLookForStyle(style);

	if unlocked then
		BorderTint(0, 0.8, 1, 1);
	else
		BorderTint(0.6, 0.6, 0.6, 0.9);
	end
end

function K.GetMeleeSwingBorderStyle()
	return CurrentBorderStyle();
end

function K.SetMeleeSwingBorderStyle(style)
	local v = (style == "None" and "None")
		or (style == "Blizzard" and "Blizzard")
		or "Tooltip";
	K.SaveConfig("SwingTimerBorderStyle", v);
	ApplyBorderStyle();
	return v;
end

function K.CycleMeleeSwingBorderStyle()
	local cur = CurrentBorderStyle();
	local nxt = (cur == "Tooltip" and "None")
		or (cur == "None" and "Blizzard")
		or "Tooltip";
	K.SaveConfig("SwingTimerBorderStyle", nxt);
	ApplyBorderStyle();
	return nxt;
end

local function Lock()
	unlocked = false;
	mover:EnableMouse(false);
	unlockOverlay:Hide();
	unlockText:Hide();
	BorderTint(0.6, 0.6, 0.6, 0.9);
	SavePosition();
	HideBar();
end

local function Unlock()



	if K.IsGlobalUnlocked and K.IsGlobalUnlocked() then
		print("|cff4FC3F7NUF:|r " .. (L["SWING_USE_GLOBAL"]
			or "Move Everything is on: drag the blue box from there."));
		return;
	end
	unlocked = true;
	mover:EnableMouse(true);
	unlockOverlay:Show();
	unlockText:Show();
	BorderTint(0, 0.8, 1, 1);
	bar:SetMinMaxValues(0, 1);
	bar:SetValue(0.6);
	textRight:SetText("--");
	mover:Show();
end




local function StartSwing()
	if unlocked then return; end

	local mainSpeed = UnitAttackSpeed("player");
	if not mainSpeed or mainSpeed <= 0 then return; end

	local now = GetTime();
	bar:SetMinMaxValues(now, now + mainSpeed);
	bar:SetValue(now);
	textRight:SetText(string.format("%0.1f", mainSpeed));
	ShowBar();
end

bar:SetScript("OnUpdate", function(self)
	if unlocked then return; end

	local lo, hi = self:GetMinMaxValues();
	if hi <= lo then return; end

	local now = GetTime();



	if now >= hi then
		self:SetMinMaxValues(0, 1);
		self:SetValue(0);
		textRight:SetText("");
		spark:ClearAllPoints();
		spark:SetPoint("CENTER", self, "LEFT", 0, 0);
		HideBar();
		return;
	end

	self:SetValue(now);

	local pct = (now - lo) / (hi - lo);
	spark:ClearAllPoints();
	spark:SetPoint("CENTER", self, "LEFT", pct * BAR_WIDTH, 0);





	local decimas = floor((hi - now) * 10);
	if decimas ~= self.lastDecimas then
		self.lastDecimas = decimas;
		textRight:SetText(format("%0.1f", hi - now));
	end
end);




local events = CreateFrame("Frame");
events:SetScript("OnEvent", function(self, event, ...)
	if not enabled then return; end

	if event == "PLAYER_ENTERING_WORLD" then
		playerGUID = UnitGUID("player");
		RestorePosition();
		ApplyBorderStyle();
		HideBar();
		return;
	end

	if event == "PLAYER_REGEN_ENABLED" then

		return;
	end

	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, subEvent, sourceGUID = ...;
		if sourceGUID ~= playerGUID then return; end
		if subEvent == "SWING_DAMAGE" or subEvent == "SWING_MISSED" then
			StartSwing();
		end
	end
end);




SLASH_NUFSWING1 = "/nufswing";
SlashCmdList["NUFSWING"] = function(msg)
	msg = string.lower(msg or "");
	local cmd, val = string.match(msg, "^(%a*)%s*(.*)$");

	if cmd == "unlock" or cmd == "move" then
		Unlock();
		print("|cff4FC3F7NUF:|r " .. (L["SWING_UNLOCKED"] or "Swing Timer - drag the bar. /nufswing lock to lock it."));
	elseif cmd == "lock" then
		Lock();
		print("|cff4FC3F7NUF:|r " .. (L["SWING_LOCKED"] or "Swing Timer - bar locked."));
	elseif cmd == "scale" then
		local s = tonumber(val);
		if s and s >= 0.5 and s <= 2.5 then
			DB().scale = s;
			mover:SetScale(s);
			print("|cff4FC3F7NUF:|r " .. (L["SWING_SCALE"] or "Swing Timer - scale:") .. " " .. string.format("%.1f", s));
		else
			print("|cff4FC3F7NUF:|r " .. (L["CMD_USAGE"] or "Usage:") .. " /nufswing scale <0.5 - 2.5>");
		end
	elseif cmd == "reset" then
		local db = DB();
		db.x, db.y, db.scale = 0, 222, 1.0;
		RestorePosition();
		Lock();
		print("|cff4FC3F7NUF:|r " .. (L["SWING_RESET"] or "Swing Timer - position and scale reset."));
	else
		print("|cff4FC3F7NUF:|r /nufswing unlock | lock | scale <n> | reset");
	end
end



function K.ResetMeleeSwingTimerPosition()
	local db = DB();
	db.x, db.y, db.scale = 0, 222, 1.0;
	RestorePosition();
	Lock();
end




function K.ToggleMeleeSwingUnlock()
	if unlocked then Lock(); else Unlock(); end
	return unlocked;
end

function K.IsMeleeSwingUnlocked()
	return unlocked;
end

function K.GetMeleeSwingScale()
	return DB().scale or 1.0;
end

function K.SaveMeleeSwingScale(s)
	s = tonumber(s) or 1.0;
	DB().scale = s;
	mover:SetScale(s);
end




K.RegisterModule("MeleeSwingTimer", {
	name    = L["MOD_SWINGTIMER"] or "Melee Swing Timer",
	desc    = L["MOD_SWINGTIMER_DESC"] or "Bar showing the time until your next melee white hit. /nufswing unlock to move it.",
	default = false,
	configLabel = L["BTN_MODULE_MOVE"] or "Move",
	configFunc = function()
		if unlocked then Lock(); else Unlock(); end
	end,
	onEnable = function()
		enabled = true;
		playerGUID = UnitGUID("player");
		RestorePosition();
		events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		events:RegisterEvent("PLAYER_REGEN_ENABLED");
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		unlocked = false;
		mover:Hide();
	end,
});
