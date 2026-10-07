local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local format, floor = string.format, math.floor;









local BAR_WIDTH  = 195;
local BAR_HEIGHT = 14;

local AUTO_SHOT   = GetSpellInfo(75);
local FEIGN_DEATH = GetSpellInfo(5384);

local enabled  = false;
local unlocked = false;




local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.AutoShotTimer then
		NidhausUnitFramesDB.AutoShotTimer = { x = 0, y = 246, scale = 1.0 };
	end
	return NidhausUnitFramesDB.AutoShotTimer;
end




local mover = CreateFrame("Frame", "NUF_AutoShotMover", UIParent);
mover:SetSize(BAR_WIDTH + 4, BAR_HEIGHT + 4);
mover:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 246);
mover:SetMovable(true);
mover:SetClampedToScreen(true);
mover:EnableMouse(false);
mover:Hide();

local bar = CreateFrame("StatusBar", "NUF_AutoShotBar", mover);
bar:SetSize(BAR_WIDTH, BAR_HEIGHT);
bar:SetPoint("CENTER", mover, "CENTER", 0, 0);
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
local BAR_R, BAR_G, BAR_B = 1, 0.7, 0;
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
textLeft:SetText(AUTO_SHOT or "Auto Shot");

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


local tip = CreateFrame("GameTooltip", "NUF_AutoShotTooltip", UIParent, "GameTooltipTemplate");
tip:SetOwner(UIParent, "ANCHOR_NONE");




local function SavePosition()
	local db = DB();
	local _, _, _, x, y = mover:GetPoint();
	db.x = x or 0;
	db.y = y or 246;
end

local function RestorePosition()
	local db = DB();
	mover:ClearAllPoints();
	mover:SetPoint("BOTTOM", UIParent, "BOTTOM", db.x or 0, db.y or 246);
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
	local v = C.AutoShotBorderStyle;
	if v == "None" or v == "Blizzard" or v == "Tooltip" then return v; end

	if C.AutoShotBorderless == true then return "None"; end
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













local MATCH_BLIZZ_COLOR = true;
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

function K.GetAutoShotBorderStyle()
	return CurrentBorderStyle();
end

function K.SetAutoShotBorderStyle(style)
	local v = (style == "None" and "None")
		or (style == "Blizzard" and "Blizzard")
		or "Tooltip";
	K.SaveConfig("AutoShotBorderStyle", v);
	ApplyBorderStyle();
	return v;
end

function K.CycleAutoShotBorderStyle()
	local cur = CurrentBorderStyle();
	local nxt = (cur == "Tooltip" and "None")
		or (cur == "None" and "Blizzard")
		or "Tooltip";
	K.SaveConfig("AutoShotBorderStyle", nxt);
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




local function GetUnmodifiedRangedSpeed()
	tip:SetOwner(UIParent, "ANCHOR_NONE");
	tip:SetInventoryItem("player", 18);
	for i = 1, 10 do
		local line = _G["NUF_AutoShotTooltipTextRight" .. i];
		if line and line:IsVisible() then
			local spd = tonumber(string.match(line:GetText() or "", "([%d%.]+)"));
			if spd then return spd; end
		end
	end
	return nil;
end

local function OnStart(spellName)
	if unlocked then return; end
	local speed = UnitRangedDamage("player");
	if spellName == FEIGN_DEATH then
		speed = GetUnmodifiedRangedSpeed() or speed;
	end
	if not speed or speed <= 0 then return; end

	local now = GetTime();
	bar:SetMinMaxValues(now, now + speed);
	bar:SetValue(now);
	textRight:SetText(string.format("%0.1f", speed));
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
events:SetScript("OnEvent", function(self, event, arg1, arg2)
	if not enabled then return; end

	if event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
		if arg2 == AUTO_SHOT or arg2 == FEIGN_DEATH then
			OnStart(arg2);
		end
	elseif event == "START_AUTOREPEAT_SPELL" then
		ShowBar();
	elseif event == "STOP_AUTOREPEAT_SPELL" or event == "PLAYER_ENTERING_WORLD" then
		HideBar();
	end
end);




SLASH_NUFAUTOSHOT1 = "/nufshot";
SlashCmdList["NUFAUTOSHOT"] = function(msg)
	msg = string.lower(msg or "");
	local cmd, val = string.match(msg, "^(%a*)%s*(.*)$");

	if cmd == "unlock" or cmd == "move" then
		Unlock();
		print("|cff4FC3F7NUF:|r " .. (L["AUTOSHOT_UNLOCKED"] or "Auto Shot - drag the bar. /nufshot lock to lock it."));
	elseif cmd == "lock" then
		Lock();
		print("|cff4FC3F7NUF:|r " .. (L["AUTOSHOT_LOCKED"] or "Auto Shot - bar locked."));
	elseif cmd == "scale" then
		local s = tonumber(val);
		if s and s >= 0.5 and s <= 2.5 then
			DB().scale = s;
			mover:SetScale(s);
			print("|cff4FC3F7NUF:|r " .. (L["AUTOSHOT_SCALE"] or "Auto Shot - scale:") .. " " .. string.format("%.1f", s));
		else
			print("|cff4FC3F7NUF:|r " .. (L["CMD_USAGE"] or "Usage:") .. " /nufshot scale <0.5 - 2.5>");
		end
	elseif cmd == "reset" then
		local db = DB();
		db.x, db.y, db.scale = 0, 246, 1.0;
		RestorePosition();
		Lock();
		print("|cff4FC3F7NUF:|r " .. (L["AUTOSHOT_RESET"] or "Auto Shot - position and scale reset."));
	else
		print("|cff4FC3F7NUF:|r /nufshot unlock | lock | scale <n> | reset");
	end
end



function K.GetAutoShotScale()
	return DB().scale or 1.0;
end

function K.SaveAutoShotScale(s)
	s = tonumber(s) or 1.0;
	DB().scale = s;
	mover:SetScale(s);
end


function K.ResetAutoShotTimerPosition()
	local db = DB();
	db.x, db.y, db.scale = 0, 246, 1.0;
	RestorePosition();
	Lock();
end




K.RegisterModule("AutoShotTimer", {
	name    = L["MOD_AUTOSHOT"] or "Auto Shot Timer",
	desc    = L["MOD_AUTOSHOT_DESC"] or "Hunter auto shot timing bar. /nufshot unlock to move it.",
	default = false,
	configLabel = L["BTN_MODULE_MOVE"] or "Move",
	configFunc = function()
		if unlocked then Lock(); else Unlock(); end
	end,
	onEnable = function()
		enabled = true;
		RestorePosition();
		ApplyBorderStyle();
		events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
		events:RegisterEvent("START_AUTOREPEAT_SPELL");
		events:RegisterEvent("STOP_AUTOREPEAT_SPELL");
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		unlocked = false;
		mover:Hide();
	end,
});
