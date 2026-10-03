local AddOnName, ns = ...;
local K, C, L = unpack(ns);






















local TEX = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\DungeonRoles\\";
local ICON = 20;
local GAP  = 1;

local enabled = false;
local testMode = false;




local frame = CreateFrame("Frame", "NUF_DungeonRoles", UIParent);
frame:SetSize((ICON * 5) + (GAP * 4), ICON);
frame:SetMovable(true);


frame:EnableMouse(false);
frame:SetClampedToScreen(true);
frame:RegisterForDrag("LeftButton");
frame:Hide();

local icons = {};
local ORDER = { "tank", "healer", "dps", "dps", "dps" };

for i = 1, 5 do
	local t = frame:CreateTexture(nil, "ARTWORK");
	t:SetSize(ICON, ICON);
	t:SetPoint("LEFT", frame, "LEFT", (i - 1) * (ICON + GAP), 0);
	t._role = ORDER[i];
	icons[i] = t;
end






local function SetIcon(t, ready)
	t:SetTexture(TEX .. t._role .. (ready and "Ready" or ""));
end




local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.DungeonRoles then
		NidhausUnitFramesDB.DungeonRoles = {};
	end
	return NidhausUnitFramesDB.DungeonRoles;
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


		frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -34, -175);
	end
	if db.scale then frame:SetScale(db.scale); end
end

frame:SetScript("OnDragStart", function(self)
	if IsAltKeyDown() then self:StartMoving(); end
end);
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing();
	SavePosition();
end);




local function Hide()
	frame:Hide();
end

local function Show(tankNeeds, healerNeeds, dpsNeeds)
	SetIcon(icons[1], tankNeeds   == 0);
	SetIcon(icons[2], healerNeeds == 0);



	for i = 3, 5 do
		SetIcon(icons[i], (i - 2) > (dpsNeeds or 3));
	end
	frame:Show();
end

local function Update()
	if not enabled then Hide(); return; end
	if testMode then return; end

	if not GetLFGInfoServer or not GetLFGQueueStats then Hide(); return; end

	local _, _, queued = GetLFGInfoServer();
	if not queued then Hide(); return; end

	local _, _, tankNeeds, healerNeeds, dpsNeeds = GetLFGQueueStats();
	Show(tankNeeds or 1, healerNeeds or 1, dpsNeeds or 3);
end

local events = CreateFrame("Frame");
local EVENTS = {
	"LFG_UPDATE", "LFG_PROPOSAL_SUCCEEDED", "LFG_PROPOSAL_SHOW",
	"LFG_PROPOSAL_FAILED", "LFG_PROPOSAL_UPDATE",
	"LFG_QUEUE_STATUS_UPDATE", "PARTY_MEMBERS_CHANGED", "UPDATE_LFG_LIST",
};
events:SetScript("OnEvent", function(self, event)

	if event == "LFG_PROPOSAL_SHOW" or event == "LFG_PROPOSAL_SUCCEEDED" then
		if not testMode then Hide(); end
		return;
	end
	Update();
end);

local function RegisterEvents()
	for _, e in ipairs(EVENTS) do pcall(events.RegisterEvent, events, e); end
end




function K.SetDungeonRolesPreview(show)
	testMode = show and true or false;
	RestorePosition();
	frame:EnableMouse(testMode);
	if testMode then

		Show(1, 0, 1);
	else
		Update();
	end
end

K.RegisterModule("DungeonRoles", {
	name    = L["MOD_DUNGEONROLES"] or "Dungeon Finder Roles",
	desc    = L["MOD_DUNGEONROLES_DESC"]
		or "While queued for a dungeon, shows which roles are still missing. Alt + drag to move.",
	default = false,
	configLabel = L["BTN_MODULE_MOVE"] or "Move",
	configFunc = function()
		K.SetDungeonRolesPreview(not testMode);
		if testMode then
			print("|cff4FC3F7NUF:|r Dungeon Roles - Alt + arrastrar para moverlo.");
		end
	end,
	onEnable = function()
		enabled = true;
		RegisterEvents();
		RestorePosition();
		Update();
	end,
	onDisable = function()
		enabled = false;
		testMode = false;
		events:UnregisterAllEvents();
		frame:EnableMouse(false);
		frame:Hide();
	end,
});
