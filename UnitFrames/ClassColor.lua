local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hooksecurefunc, unpack = hooksecurefunc, unpack;
local UnitIsPlayer, UnitClass, UnitIsConnected, UnitExists, UnitReaction = UnitIsPlayer, UnitClass, UnitIsConnected, UnitExists, UnitReaction;
local UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList = UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList;
local UnitPlayerControlled = UnitPlayerControlled;
local CUSTOM_CLASS_COLORS, RAID_CLASS_COLORS, FACTION_BAR_COLORS = CUSTOM_CLASS_COLORS, RAID_CLASS_COLORS, FACTION_BAR_COLORS;

local isInitialized = false;

-- FIX: local para evitar colisiones con otros addons
local function unitClassColors(healthbar, unit)
	if not healthbar or not unit then return; end
	if not UnitIsPlayer(unit) or unit ~= healthbar.unit then return; end
	if not UnitClass(unit) then return; end
	
	if C.classColor then
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

local function ForceUpdateAllFrames()
	if PlayerFrame and PlayerFrame.healthbar then
		UnitFrameHealthBar_Update(PlayerFrame.healthbar, "player");
	end
	
	if TargetFrame and TargetFrame.healthbar then
		UnitFrameHealthBar_Update(TargetFrame.healthbar, "target");
	end
	
	if FocusFrame and FocusFrame.healthbar then
		UnitFrameHealthBar_Update(FocusFrame.healthbar, "focus");
	end
	
	for i = 1, (MAX_PARTY_MEMBERS or 4) do
		local partyFrame = _G["PartyMemberFrame"..i];
		if partyFrame and partyFrame.healthbar then
			UnitFrameHealthBar_Update(partyFrame.healthbar, "party"..i);
		end
	end
	
	for i = 1, (MAX_ARENA_ENEMIES or 0) do
		local arenaFrame = _G["ArenaEnemyFrame"..i];
		if arenaFrame and arenaFrame.healthbar then
			UnitFrameHealthBar_Update(arenaFrame.healthbar, "arena"..i);
		end
	end
	
	for i = 1, (MAX_BOSS_FRAMES or 0) do
		local bossFrame = _G["Boss"..i.."TargetFrame"];
		if bossFrame and bossFrame.healthbar then
			UnitFrameHealthBar_Update(bossFrame.healthbar, "boss"..i);
		end
	end
end

local function InitializeClassColors()
	if isInitialized then return; end
	
	-- Un solo hook para UnitFrameHealthBar_Update (class colors + NPC reaction)
	hooksecurefunc("UnitFrameHealthBar_Update", function(healthbar, unit)
		unitClassColors(healthbar, unit);
		npcReactionColors(healthbar, unit);
	end);
	
	-- Un solo hook para HealthBar_OnValueChanged
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