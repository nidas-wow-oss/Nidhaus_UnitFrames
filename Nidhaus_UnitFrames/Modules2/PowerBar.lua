local AddOnName, ns = ...;
local K, C, L = unpack(ns);



















local DEFAULT_W, DEFAULT_H = 160, 16;

local enabled = false;





local DB;







local CLASS_R, CLASS_G, CLASS_B;
do
	local _, class = UnitClass("player");
	local t = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class])
		or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]);
	if t then CLASS_R, CLASS_G, CLASS_B = t.r, t.g, t.b; end
end

local POWER_COLORS = {
	[0] = { 0.20, 0.35, 0.90 },
	[1] = { 0.85, 0.15, 0.15 },
	[2] = { 0.90, 0.55, 0.20 },
	[3] = { 0.95, 0.90, 0.25 },
	[6] = { 0.00, 0.75, 0.95 },
};




local frame = CreateFrame("Frame", "NUF_PowerBarFrame", UIParent);
frame:SetSize(DEFAULT_W, DEFAULT_H);
frame:Hide();
frame:SetMovable(true);



frame:EnableMouse(false);
frame:SetClampedToScreen(true);

frame:SetBackdrop({
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
});
frame:SetBackdropColor(0, 0, 0, 0.6);
frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.9);

local PAD, BAR_H, GAP = 4, 14, 2;


local healthBar = CreateFrame("StatusBar", "NUF_PowerBarHealth", frame);
healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
healthBar:SetMinMaxValues(0, 100);
healthBar:SetValue(100);
healthBar:Hide();

local healthBG = healthBar:CreateTexture(nil, "BACKGROUND");
healthBG:SetAllPoints(healthBar);
healthBG:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
healthBG:SetVertexColor(0.1, 0.1, 0.1, 0.6);

local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0);


local bar = CreateFrame("StatusBar", "NUF_PowerBarStatus", frame);
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
bar:SetMinMaxValues(0, 100);
bar:SetValue(100);

local barBG = bar:CreateTexture(nil, "BACKGROUND");
barBG:SetAllPoints(bar);
barBG:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
barBG:SetVertexColor(0.1, 0.1, 0.1, 0.6);

local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
text:SetPoint("CENTER", bar, "CENTER", 0, 0);
text:SetText("0 / 0");
















local DEF_AURA_SIZE, DEF_AURA_PERROW = 16, 8;
local AURA_GAP, AURA_MARGIN = 2, 4;












local BUFF_FILTER   = "HELPFUL|RAID";
local DEBUFF_FILTER = "HARMFUL|RAID";



local AURA_FILTER_OK;

local function AuraAt(i, filter)
	if AURA_FILTER_OK == nil then
		AURA_FILTER_OK = pcall(UnitAura, "player", 1, BUFF_FILTER) and true or false;
	end
	if AURA_FILTER_OK then return UnitAura("player", i, filter); end
	if filter == DEBUFF_FILTER then return UnitDebuff("player", i); end
	return UnitBuff("player", i);
end


local DEBUFF_COLORS = {
	Magic   = { 0.20, 0.60, 1.00 },
	Curse   = { 0.60, 0.00, 1.00 },
	Disease = { 0.60, 0.40, 0.00 },
	Poison  = { 0.00, 0.60, 0.00 },
};
local DEBUFF_DEFAULT = { 0.80, 0.10, 0.10 };






local BUFF_EDGE = { 0, 0, 0 };

local buffRow   = CreateFrame("Frame", nil, frame);
local debuffRow = CreateFrame("Frame", nil, frame);
local buffIcons, debuffIcons = {}, {};

local function MakeIcon(parent)





	local f = CreateFrame("Button", nil, parent);
	f:EnableMouse(false);
	f:RegisterForClicks("RightButtonUp");
	f:SetScript("OnClick", function(self)
		if not self.spell then return; end
		local db = DB();
		if type(db.auraHidden) ~= "table" then db.auraHidden = {}; end
		db.auraHidden[self.spell] = true;
		print("|cff4FC3F7NUF:|r Power Bar - |cffffff00" .. self.spell
			.. "|r " .. (L["POWERBAR_AURA_HIDDEN"] or "is no longer shown.") .. " |cffaaaaaa/nufpower auras|r " .. (L["POWERBAR_AURA_HINT"] or "to show them all again."));
		if K.ApplyPowerBarAuras then K.ApplyPowerBarAuras(); end
	end);




	f.edge = f:CreateTexture(nil, "BACKGROUND");
	f.edge:SetTexture("Interface\\Buttons\\WHITE8X8");
	f.edge:SetPoint("TOPLEFT",     f, "TOPLEFT",     -1,  1);
	f.edge:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",  1, -1);
	f.edge:Hide();

	f.icon = f:CreateTexture(nil, "ARTWORK");
	f.icon:SetAllPoints(f);
	f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);

	f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate");
	f.cd:SetAllPoints(f);

	f.count = f:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall");
	f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, 0);

	f:Hide();
	return f;
end

local function EnsureIcons(list, parent, n)
	for i = #list + 1, n do
		list[i] = MakeIcon(parent);
	end
end



local function LayoutAuras()
	local db   = DB();
	local size = db.auraSize   or DEF_AURA_SIZE;
	local per  = db.auraPerRow or DEF_AURA_PERROW;
	local pos  = C.PowerBarAuraPos or "RIGHT";
	local rowW = (per * size) + ((per - 1) * AURA_GAP);

	EnsureIcons(buffIcons,   buffRow,   per);
	EnsureIcons(debuffIcons, debuffRow, per);

	for _, row in ipairs({ buffRow, debuffRow }) do
		row:SetWidth(rowW);
		row:SetHeight(size);
	end

	for _, list in ipairs({ buffIcons, debuffIcons }) do
		for i, ic in ipairs(list) do
			ic:SetWidth(size);
			ic:SetHeight(size);
			ic:ClearAllPoints();
			ic:SetPoint("LEFT", ic:GetParent(), "LEFT", (i - 1) * (size + AURA_GAP), 0);
			if i > per then ic:Hide(); end
		end
	end

	buffRow:ClearAllPoints();
	debuffRow:ClearAllPoints();

	if pos == "BOTTOM" then
		buffRow:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -AURA_MARGIN);
		debuffRow:SetPoint("TOPLEFT", buffRow, "BOTTOMLEFT", 0, -AURA_GAP);
	elseif pos == "TOP" then


		debuffRow:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, AURA_MARGIN);
		buffRow:SetPoint("BOTTOMLEFT", debuffRow, "TOPLEFT", 0, AURA_GAP);
	else
		buffRow:SetPoint("TOPLEFT", frame, "TOPRIGHT", AURA_MARGIN, 0);
		debuffRow:SetPoint("TOPLEFT", buffRow, "BOTTOMLEFT", 0, -AURA_GAP);
	end
end

local function FillRow(list, filter, per)
	local isDebuff = (filter == DEBUFF_FILTER);
	local hidden   = DB().auraHidden;
	local slot, i  = 0, 1;



	while slot < per and i <= 40 do
		local name, _, icon, count, dtype, duration, expires = AuraAt(i, filter);
		if not name then break; end
		i = i + 1;

		if icon and not (hidden and hidden[name]) then
			slot = slot + 1;
			local ic = list[slot];
			if not ic then break; end

			ic.spell = name;
			ic.icon:SetTexture(icon);



			local col = isDebuff
				and (DEBUFF_COLORS[dtype or ""] or DEBUFF_DEFAULT)
				or BUFF_EDGE;
			ic.edge:SetVertexColor(col[1], col[2], col[3]);
			ic.edge:Show();

			if count and count > 1 then
				ic.count:SetText(count);
				ic.count:Show();
			else
				ic.count:Hide();
			end








			ic.cd:Hide();

			ic:Show();
		end
	end

	for k = slot + 1, #list do
		if list[k] then list[k]:Hide(); end
	end
	return slot;
end

local function UpdateAuras()
	if not C.PowerBarShowAuras then
		buffRow:Hide();
		debuffRow:Hide();
		return;
	end
	local per = DB().auraPerRow or DEF_AURA_PERROW;
	FillRow(buffIcons,   BUFF_FILTER,   per);
	FillRow(debuffIcons, DEBUFF_FILTER, per);
	buffRow:Show();
	debuffRow:Show();
end


function K.GetPowerBarAuraSize()   return DB().auraSize   or DEF_AURA_SIZE;   end
function K.GetPowerBarAuraPerRow() return DB().auraPerRow or DEF_AURA_PERROW; end
function K.GetPowerBarAuraPos()    return C.PowerBarAuraPos or "RIGHT";       end

function K.SavePowerBarAuraSize(v)   DB().auraSize   = v; LayoutAuras(); UpdateAuras(); end
function K.SavePowerBarAuraPerRow(v) DB().auraPerRow = v; LayoutAuras(); UpdateAuras(); end

function K.SetPowerBarAuraPos(v)
	local val = (v == "TOP" and "TOP") or (v == "BOTTOM" and "BOTTOM") or "RIGHT";
	K.SaveConfig("PowerBarAuraPos", val);
	LayoutAuras();
	UpdateAuras();
end

function K.ApplyPowerBarAuras()
	LayoutAuras();
	UpdateAuras();
end


local function SetAuraMouse(on)
	for _, list in ipairs({ buffIcons, debuffIcons }) do
		for _, ic in ipairs(list) do ic:EnableMouse(on and true or false); end
	end
end

function K.ResetPowerBarHiddenAuras()
	DB().auraHidden = nil;
	UpdateAuras();
end



local function ApplyBarLayout()
	local db = DB();
	local barH = db.barHeight or BAR_H;
	bar:ClearAllPoints();
	healthBar:ClearAllPoints();
	if C.PowerBarShowHealth then
		healthBar:Show();
		healthBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",   PAD, -PAD);
		healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD);
		healthBar:SetHeight(barH);
		bar:SetPoint("TOPLEFT",  healthBar, "BOTTOMLEFT",  0, -GAP);
		bar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, -GAP);
		bar:SetHeight(barH);
		frame:SetHeight(PAD + barH + GAP + barH + PAD);
	else
		healthBar:Hide();
		bar:SetPoint("TOPLEFT",  frame, "TOPLEFT",   PAD, -PAD);
		bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD);
		bar:SetHeight(barH);
		frame:SetHeight(PAD + barH + PAD);
	end


	LayoutAuras();
end
K.ApplyPowerBarLayout = ApplyBarLayout;


function K.SavePowerBarWidth(w)
	DB().width = w;
	frame:SetWidth(w);
end
function K.GetPowerBarWidth() return DB().width or DEFAULT_W; end

function K.SavePowerBarBarHeight(h)
	DB().barHeight = h;
	ApplyBarLayout();
end
function K.GetPowerBarBarHeight() return DB().barHeight or BAR_H; end





function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.PowerBar then
		NidhausUnitFramesDB.PowerBar = {};
	end
	return NidhausUnitFramesDB.PowerBar;
end

local function SavePosition()
	local db = DB();
	local point, _, relativePoint, x, y = frame:GetPoint();
	if not point then return; end
	db.point = point; db.relativePoint = relativePoint; db.x = x; db.y = y;
end

local function RestorePosition()
	local db = DB();
	frame:ClearAllPoints();
	if db.point then
		frame:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
	else

		frame:SetPoint("CENTER", UIParent, "CENTER", 0, -140);
	end
	frame:SetScale(db.scale or 1);
	frame:SetWidth(db.width or DEFAULT_W);
	ApplyBarLayout();
end

function K.SavePowerBarScale(scale)
	DB().scale = scale;
	frame:SetScale(scale or 1);
end

function K.GetPowerBarScale()
	return DB().scale or 1;
end

function K.ResetPowerBarPosition()
	local db = DB();
	db.point, db.relativePoint, db.x, db.y, db.scale = nil, nil, nil, nil, nil;
	db.width, db.height, db.barHeight = nil, nil, nil;
	RestorePosition();
end

frame:RegisterForDrag("LeftButton");
frame:SetScript("OnDragStart", function(self)
	if IsAltKeyDown() then self:StartMoving(); end
end);
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing();
	SavePosition();
end);




local testMode = false;

local function ShouldBeVisible()
	if not enabled then return false; end
	if testMode then return true; end

	if C.PowerBarCombatOnly and not InCombatLockdown() then return false; end




	if C.PowerBarHideWhenFull and not InCombatLockdown() then
		local cur, max = UnitPower("player") or 0, UnitPowerMax("player") or 0;
		local hp, hpmax = UnitHealth("player") or 0, UnitHealthMax("player") or 0;
		local powerFull  = (max <= 0) or (cur >= max);
		local healthFull = (hpmax <= 0) or (hp >= hpmax);
		if powerFull and healthFull then return false; end
	end

	return true;
end


local function HealthColor(pct)
	if pct > 0.5 then

		local t = (1 - pct) * 2;
		return 0.15 + (0.85 * t), 0.75, 0.15;
	else

		local t = pct * 2;
		return 1, 0.75 * t, 0.15 * t;
	end
end

local function UpdateBar()
	if not ShouldBeVisible() then frame:Hide(); return; end

	local cur = UnitPower("player") or 0;
	local max = UnitPowerMax("player") or 0;
	if max <= 0 then frame:Hide(); return; end

	local ptype = UnitPowerType("player") or 0;
	local col = POWER_COLORS[ptype] or POWER_COLORS[0];
	bar:SetStatusBarColor(col[1], col[2], col[3]);
	bar:SetMinMaxValues(0, max);
	bar:SetValue(cur);



	if C.PowerBarHideText then
		text:Hide();
	else
		if C.PowerBarShowPercent then
			text:SetText(string.format("%d%%", math.floor(cur / max * 100 + 0.5)));
		else
			text:SetText(cur .. " / " .. max);
		end
		text:Show();
	end


	if C.PowerBarShowHealth then
		local hp    = UnitHealth("player") or 0;
		local hpmax = UnitHealthMax("player") or 0;
		if hpmax > 0 then
			healthBar:SetMinMaxValues(0, hpmax);
			healthBar:SetValue(hp);





			if C.PowerBarHealthClassColor and CLASS_R then
				healthBar:SetStatusBarColor(CLASS_R, CLASS_G, CLASS_B);
			elseif C.PowerBarHealthGradient then
				healthBar:SetStatusBarColor(HealthColor(hp / hpmax));
			else
				healthBar:SetStatusBarColor(0.15, 0.75, 0.15);
			end
			if C.PowerBarHideText then
				healthText:Hide();
			else
				if C.PowerBarShowPercent then
					healthText:SetText(string.format("%d%%", math.floor(hp / hpmax * 100 + 0.5)));
				else
					healthText:SetText(hp .. " / " .. hpmax);
				end
				healthText:Show();
			end
		end
	end

	frame:Show();
end

K.UpdatePowerBar = UpdateBar;






local events = CreateFrame("Frame");

local function RegisterPowerEvents()
	events:RegisterEvent("PLAYER_ENTERING_WORLD");






	for _, ev in ipairs({
		"UNIT_MANA", "UNIT_MAXMANA", "UNIT_RAGE", "UNIT_MAXRAGE",
		"UNIT_ENERGY", "UNIT_MAXENERGY", "UNIT_FOCUS", "UNIT_MAXFOCUS",
		"UNIT_RUNIC_POWER", "UNIT_MAXRUNIC_POWER", "UNIT_DISPLAYPOWER",
	}) do
		pcall(events.RegisterEvent, events, ev);
	end
	events:RegisterEvent("PLAYER_REGEN_DISABLED");
	events:RegisterEvent("PLAYER_REGEN_ENABLED");


	if C.PowerBarShowAuras then events:RegisterEvent("UNIT_AURA"); end



	if C.PowerBarShowHealth or C.PowerBarHideWhenFull then
		events:RegisterEvent("UNIT_HEALTH");
		events:RegisterEvent("UNIT_MAXHEALTH");
	end
end

events:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_ENTERING_WORLD" then
		RestorePosition();
		UpdateBar();
		UpdateAuras();
		return;
	end


	if unit and unit ~= "player" then return; end
	if event == "UNIT_AURA" then UpdateAuras(); return; end
	UpdateBar();
end);



function K.ApplyPowerBarHealth()
	ApplyBarLayout();
	if enabled then
		events:UnregisterAllEvents();
		RegisterPowerEvents();
		UpdateBar();
		UpdateAuras();
	end
end



function K.ApplyPowerBarAuraToggle()
	if enabled then
		events:UnregisterAllEvents();
		RegisterPowerEvents();
	end
	LayoutAuras();
	UpdateAuras();
end




K.RegisterModule("PowerBar", {
	name    = L["MOD_POWERBAR"] or "Power Bar",
	desc    = L["MOD_POWERBAR_DESC"]
		or "Movable mana / energy / rage / runic power bar. Alt + drag to move.",
	default = false,
	configLabel = L["BTN_MODULE_MOVE"] or "Move",
	configFunc = function()
		RestorePosition();
		testMode = not testMode;
		frame:EnableMouse(testMode);
		SetAuraMouse(testMode);
		if testMode then
			UpdateBar();
			if not frame:IsShown() then
				bar:SetMinMaxValues(0, 100);
				bar:SetValue(70);
				bar:SetStatusBarColor(0.20, 0.35, 0.90);
				text:SetText("70 / 100");
				frame:Show();
			end
			print("|cff4FC3F7NUF:|r " .. (L["POWERBAR_MOVE_ON"] or "Power Bar - Alt + drag to move it. Right-click an aura to hide it. Click Move again to exit."));
		else
			UpdateBar();
		end
	end,
	onEnable = function()
		enabled = true;
		RegisterPowerEvents();
		RestorePosition();
		UpdateBar();
		UpdateAuras();
	end,
	onDisable = function()
		enabled = false;
		testMode = false;
		SetAuraMouse(false);
		events:UnregisterAllEvents();
		frame:Hide();
	end,
});

SLASH_NUFPOWERBAR1 = "/nufpower";
SlashCmdList["NUFPOWERBAR"] = function(msg)
	msg = string.lower(msg or "");
	if msg == "reset" then
		K.ResetPowerBarPosition();
		print("|cff4FC3F7NUF:|r " .. (L["POWERBAR_RESET"] or "Power Bar - position reset."));
	elseif msg == "auras" then
		K.ResetPowerBarHiddenAuras();
		print("|cff4FC3F7NUF:|r " .. (L["POWERBAR_AURAS"] or "Power Bar - all auras are shown again."));
	else
		print("|cff4FC3F7NUF:|r " .. (L["POWERBAR_HELP"] or "Power Bar - Alt + drag to move it.") .. " /nufpower reset  |  /nufpower auras");
	end
end
