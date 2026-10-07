local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hooksecurefunc, unpack = hooksecurefunc, unpack;
local UnitIsPlayer, UnitClass, UnitIsConnected, UnitExists, UnitReaction = UnitIsPlayer, UnitClass, UnitIsConnected, UnitExists, UnitReaction;
local UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList = UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList;
local UnitPlayerControlled = UnitPlayerControlled;
local CUSTOM_CLASS_COLORS, RAID_CLASS_COLORS, FACTION_BAR_COLORS = CUSTOM_CLASS_COLORS, RAID_CLASS_COLORS, FACTION_BAR_COLORS;

local isInitialized = false;


local function unitClassColors(healthbar, unit)
	if not healthbar or not unit then return; end
	if not UnitIsPlayer(unit) or unit ~= healthbar.unit then return; end
	if not UnitClass(unit) then return; end
	
















	local isArena = unit and string.find(unit, "^arena%d") ~= nil;
	local useClass;

	if isArena then
		if (C.ArenaFrameStyle or "Custom") == "Blizzard" then
			useClass = (C.ArenaBlizzardClassColor == true);
		else
			useClass = true;
		end
	else
		useClass = C.classColor and true or false;
	end

	if useClass then
		if not UnitIsConnected(unit) then
			healthbar:SetStatusBarColor(0.6, 0.6, 0.6, 0.5);
			return;
		end
		
		local _, class = UnitClass(unit);
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class];
		if color then
			healthbar:SetStatusBarColor(color.r, color.g, color.b);
		end
	else
		if not UnitIsConnected(unit) then
			healthbar:SetStatusBarColor(0.6, 0.6, 0.6, 0.5);
		else
			healthbar:SetStatusBarColor(0, 1.0, 0);
		end
	end
end

local function npcReactionColors(healthbar, unit)
	if not healthbar or not unit then return; end
	if not UnitExists(unit) or UnitIsPlayer(unit) or unit ~= healthbar.unit then return; end
















	if UnitPlayerControlled(unit) or (not C.UnitFrameCustomTexture) then
		if UnitIsConnected(unit) == false then
			healthbar:SetStatusBarColor(0.6, 0.6, 0.6, 0.5);
		else
			healthbar:SetStatusBarColor(0, 1.0, 0);
		end
		return;
	end

	if not UnitPlayerControlled(unit) and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit) then
		healthbar:SetStatusBarColor(0.5, 0.5, 0.5);
	else
		local reaction = UnitReaction(unit, "player");
		if reaction and FACTION_BAR_COLORS[reaction] then
			local color = FACTION_BAR_COLORS[reaction];
			healthbar:SetStatusBarColor(color.r, color.g, color.b);
		else
			healthbar:SetStatusBarColor(0, 0.6, 0.1);
		end
	end
end









local function Recolor(bar)
	if not bar then return; end
	local unit = bar.unit;
	if not unit or not UnitExists(unit) then return; end
	unitClassColors(bar, unit);
	npcReactionColors(bar, unit);
end

local function ForceUpdateAllFrames()
	if PlayerFrame then Recolor(PlayerFrame.healthbar); end
	if TargetFrame then Recolor(TargetFrame.healthbar); end
	if FocusFrame then Recolor(FocusFrame.healthbar); end

	for i = 1, (MAX_PARTY_MEMBERS or 4) do
		local partyFrame = _G["PartyMemberFrame"..i];
		if partyFrame then Recolor(partyFrame.healthbar); end
	end

	for i = 1, (MAX_ARENA_ENEMIES or 0) do
		local arenaFrame = _G["ArenaEnemyFrame"..i];
		if arenaFrame then Recolor(arenaFrame.healthbar); end
	end

	for i = 1, (MAX_BOSS_FRAMES or 0) do
		local bossFrame = _G["Boss"..i.."TargetFrame"];
		if bossFrame then Recolor(bossFrame.healthbar); end
	end
end

local function InitializeClassColors()
	if isInitialized then return; end
	

	hooksecurefunc("UnitFrameHealthBar_Update", function(healthbar, unit)
		unitClassColors(healthbar, unit);
		npcReactionColors(healthbar, unit);
	end);
	

	hooksecurefunc("HealthBar_OnValueChanged", function(self)
		unitClassColors(self, self.unit);
		npcReactionColors(self, self.unit);
	end);
	
	ForceUpdateAllFrames();
	isInitialized = true;
end

function K.ToggleClassColors(enabled)
	if not isInitialized then return; end
	ForceUpdateAllFrames();
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	InitializeClassColors();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if isInitialized then
		ForceUpdateAllFrames();
	end
end);