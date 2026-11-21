local _, ns = ...;
local K, C, L = unpack(ns);

local ICONS   = "Interface\\AddOns\\Nidhaus_UnitFrames\\Media\\Minimap\\infobar\\";
local WHITE8  = "Interface\\Buttons\\WHITE8X8";
local BG      = { 0.015, 0.028, 0.04, 0.90 };
local BORDER  = { 0.34, 0.28, 0.24, 0.90 };
local TEXT    = { 0.97, 0.95, 0.90 };
local REFRESH = 1;
local ADDON_LIST = 25;

local bar;
local slots = {};

local function PercentColor(pct)
	if pct < 0 then pct = 0 elseif pct > 100 then pct = 100 end
	if pct >= 50 then return (100 - pct) / 50, 1, 0.1 end
	return 1, pct / 50, 0.1;
end

local function Colored(text, r, g, b)
	return ("|cff%02x%02x%02x%s|r"):format(r * 255, g * 255, b * 255, text);
end

local function FormatMemory(kb)
	if kb >= 1024 then return ("%.1f MB"):format(kb / 1024) end
	return ("%d KB"):format(kb);
end

local function FormatTime(h, m)
	if C.MinimapInfo24h ~= false then return ("%02d:%02d"):format(h, m) end
	local suffix = (h >= 12) and "PM" or "AM";
	h = h % 12;
	if h == 0 then h = 12 end
	return ("%d:%02d %s"):format(h, m, suffix);
end

local function LocalTime()
	return FormatTime(tonumber(date("%H")), tonumber(date("%M")));
end

local function ServerTime()
	local h, m = GetGameTime();
	return FormatTime(h, m);
end

local ITEMS = {};

ITEMS.clock = {
	setting = "MinimapInfoClock",
	label   = "Time",
	text    = function()
		return C.MinimapInfoServerTime and ServerTime() or LocalTime();
	end,
	tooltip = function(tt)
		tt:AddDoubleLine("Local time", LocalTime(), 1, 1, 1, 1, 1, 1);
		tt:AddDoubleLine("Server time", ServerTime(), 1, 1, 1, 1, 1, 1);
		tt:AddLine(" ");
		tt:AddLine("Click: calendar", 0.6, 0.6, 0.6);
	end,
	click = function()
		if ToggleCalendar then ToggleCalendar() end
	end,
};

ITEMS.fps = {
	setting = "MinimapInfoFPS",
	label   = "Framerate",
	icon    = "fps",
	text    = function()
		local fps = GetFramerate() or 0;
		local r, g, b = PercentColor(fps / 60 * 100);
		return Colored(("%dfps"):format(fps + 0.5), r, g, b);
	end,
	tooltip = function(tt)
		UpdateAddOnMemoryUsage();
		local list, total = {}, 0;
		for i = 1, GetNumAddOns() do
			local mem = GetAddOnMemoryUsage(i);
			if mem and mem > 0 then
				list[#list + 1] = { name = GetAddOnInfo(i), mem = mem };
				total = total + mem;
			end
		end
		table.sort(list, function(a, b) return a.mem > b.mem end);
		for i = 1, math.min(ADDON_LIST, #list) do
			local e = list[i];
			local r, g, b = PercentColor(100 - math.min(100, e.mem / 8));
			tt:AddDoubleLine(e.name, FormatMemory(e.mem), 0.8, 0.8, 0.8, r, g, b);
		end
		tt:AddLine(" ");
		tt:AddDoubleLine("Total", FormatMemory(total), 1, 1, 1, 1, 1, 1);
		tt:AddDoubleLine("Total incl. Blizzard", FormatMemory(collectgarbage("count")), 1, 1, 1, 1, 1, 1);
		tt:AddLine(" ");
		tt:AddLine("Click: clean memory", 0.6, 0.6, 0.6);
	end,
	click = function(self)
		local before = collectgarbage("count");
		collectgarbage("collect");
		local freed = math.max(0, before - collectgarbage("count"));
		DEFAULT_CHAT_FRAME:AddMessage("|cff4FC3F7NUF:|r Memory cleaned: " .. FormatMemory(freed));

		if GameTooltip:IsOwned(self) and self:GetScript("OnEnter") then
			self:GetScript("OnEnter")(self);
		end
	end,
};

ITEMS.ping = {
	setting = "MinimapInfoPing",
	label   = "Latency",
	icon    = "latency",
	text    = function()
		local _, _, ms = GetNetStats();
		ms = ms or 0;
		local r, g, b = PercentColor(100 - math.min(100, ms / 3));
		return Colored(("%dms"):format(ms), r, g, b);
	end,
	tooltip = function(tt)
		local bwIn, bwOut, ms = GetNetStats();
		tt:AddDoubleLine("Latency", ("%d ms"):format(ms or 0), 1, 1, 1, 1, 1, 1);
		tt:AddDoubleLine("In", ("%.2f KB/s"):format(bwIn or 0), 1, 1, 1, 1, 1, 1);
		tt:AddDoubleLine("Out", ("%.2f KB/s"):format(bwOut or 0), 1, 1, 1, 1, 1, 1);
	end,
};

local ORDER = { "clock", "fps", "ping" };

local function UpdateAll()
	for _, slot in ipairs(slots) do
		local item = slot.item;
		if item and slot:IsShown() then slot.text:SetText(item.text()) end
	end
end

local function CreateSlot()
	local slot = CreateFrame("Button", nil, bar);
	slot:SetHeight(18);
	slot:RegisterForClicks("LeftButtonUp");

	slot.icon = slot:CreateTexture(nil, "ARTWORK");
	slot.icon:SetSize(12, 12);

	slot.text = slot:CreateFontString(nil, "OVERLAY");
	slot.text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE");
	slot.text:SetTextColor(TEXT[1], TEXT[2], TEXT[3]);

	local hl = slot:CreateTexture(nil, "HIGHLIGHT");
	hl:SetAllPoints();
	hl:SetTexture(1, 1, 1, 0.08);

	slot:SetScript("OnEnter", function(self)
		local item = self.item;
		if not item then return end
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
		GameTooltip:SetText(item.label, 1, 0.68, 0.22);
		item.tooltip(GameTooltip);
		GameTooltip:Show();
	end);
	slot:SetScript("OnLeave", function() GameTooltip:Hide() end);
	slot:SetScript("OnClick", function(self)
		local item = self.item;

		if item and item.click and not InCombatLockdown() then item.click(self) end
	end);

	slots[#slots + 1] = slot;
	return slot;
end

local acc = 0;
local function OnUpdate(_, elapsed)
	acc = acc + elapsed;
	if acc < REFRESH then return end
	acc = 0;
	UpdateAll();
end

local function GetBar()
	if bar or not Minimap then return bar end
	bar = CreateFrame("Frame", "NUF_MinimapInfoBar", Minimap);
	bar:SetHeight(20);
	bar:SetBackdrop({
		bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	});
	bar:SetBackdropColor(BG[1], BG[2], BG[3], BG[4]);
	bar:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4]);
	for i = 1, #ORDER do CreateSlot() end
	bar:SetScript("OnUpdate", OnUpdate);
	bar:Hide();
	return bar;
end

function K.ApplyMinimapInfoBar()
	if not C.MinimapInfoBar then
		if bar then bar:Hide() end
		return;
	end
	local b = GetBar();
	if not b then return end

	local square = (C.MinimapSquare == true);
	local gap = square and 4 or 14;
	local side = square and 2 or 0;
	b:ClearAllPoints();
	b:SetPoint("TOPLEFT",  Minimap, "BOTTOMLEFT",  -side, -gap);
	b:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT",  side, -gap);
	b:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 4);

	local active = {};
	for _, id in ipairs(ORDER) do
		local item = ITEMS[id];
		if C[item.setting] ~= false then active[#active + 1] = item end
	end
	if #active == 0 then b:Hide(); return end

	local width = (Minimap:GetWidth() or 140) + side * 2;
	local slotW = (width - 2) / #active;
	local icons = (C.MinimapInfoIcons ~= false);
	for i, slot in ipairs(slots) do
		local item = active[i];
		slot.item = item;
		if item then
			slot:ClearAllPoints();
			slot:SetPoint("LEFT", b, "LEFT", 1 + (i - 1) * slotW, 0);
			slot:SetWidth(slotW);
			slot.text:ClearAllPoints();
			if icons and item.icon then
				slot.icon:SetTexture(ICONS .. item.icon);
				slot.icon:ClearAllPoints();
				slot.icon:SetPoint("RIGHT", slot.text, "LEFT", -3, 0);
				slot.icon:Show();

				slot.text:SetPoint("CENTER", slot, "CENTER", 7, 0);
			else
				slot.icon:Hide();
				slot.text:SetPoint("CENTER", slot, "CENTER", 0, 0);
			end
			slot:Show();
		else
			slot:Hide();
		end
	end
	b:Show();
	acc = REFRESH;
	UpdateAll();
end

local ev = CreateFrame("Frame");
ev:RegisterEvent("PLAYER_ENTERING_WORLD");
ev:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents();
	K.ApplyMinimapInfoBar();
end);
