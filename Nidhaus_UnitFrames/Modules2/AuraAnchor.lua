local AddOnName, ns = ...;
local K, C, L = unpack(ns);
















local ANCHOR_W, ANCHOR_H = 330, 90;




local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.AuraAnchor then NidhausUnitFramesDB.AuraAnchor = {}; end
	return NidhausUnitFramesDB.AuraAnchor;
end

local function DebuffDB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.DebuffAnchor then NidhausUnitFramesDB.DebuffAnchor = {}; end
	return NidhausUnitFramesDB.DebuffAnchor;
end

local function HasCustomPosition()
	return DB().point ~= nil;
end

local function HasCustomDebuffPosition()
	return DebuffDB().point ~= nil;
end




local anchor = CreateFrame("Frame", "NUF_BuffAnchor", UIParent);
anchor:SetSize(ANCHOR_W, ANCHOR_H);
anchor:SetMovable(true);
anchor:SetClampedToScreen(true);
anchor:EnableMouse(false);


local debuffAnchor = CreateFrame("Frame", "NUF_DebuffAnchor", UIParent);
debuffAnchor:SetSize(ANCHOR_W, 50);
debuffAnchor:SetMovable(true);
debuffAnchor:SetClampedToScreen(true);
debuffAnchor:EnableMouse(false);




if K.RegisterScalable then
	K.RegisterScalable("PlayerBuffs",   anchor,       1.0);
	K.RegisterScalable("PlayerDebuffs", debuffAnchor, 1.0);
end












local DEFAULT_INSET = 205;
local CLUSTER_PAD   = 6;

local function MinimapInset()
	local mc = MinimapCluster;
	if not mc or not mc.GetLeft then return DEFAULT_INSET; end
	local left = mc:GetLeft();


	if not left then return DEFAULT_INSET; end
	local uiScale = UIParent:GetEffectiveScale();
	if not uiScale or uiScale == 0 then return DEFAULT_INSET; end


	left = left * mc:GetEffectiveScale() / uiScale;
	local inset = UIParent:GetWidth() - left + CLUSTER_PAD;
	if inset < DEFAULT_INSET then inset = DEFAULT_INSET; end
	return inset;
end


local function ApplyDefaultAnchorPos()
	anchor:ClearAllPoints();
	anchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -MinimapInset(), -13);
	anchor:SetScale(1);
end





function K.RefreshAuraAnchorDefault()
	if HasCustomPosition() then return; end
	ApplyDefaultAnchorPos();
	if BuffFrame_UpdateAllBuffAnchors then pcall(BuffFrame_UpdateAllBuffAnchors); end
end

local function ApplyDefaultDebuffPos()
	debuffAnchor:ClearAllPoints();
	debuffAnchor:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -20);
	debuffAnchor:SetScale(1);
end

local function RestoreAnchorPosition()
	local db = DB();
	if db.point then
		anchor:ClearAllPoints();
		anchor:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
		if db.scale then anchor:SetScale(db.scale); end
	else
		ApplyDefaultAnchorPos();
	end

	local ddb = DebuffDB();
	if ddb.point then
		debuffAnchor:ClearAllPoints();
		debuffAnchor:SetPoint(ddb.point, UIParent, ddb.relativePoint, ddb.x, ddb.y);
		if ddb.scale then debuffAnchor:SetScale(ddb.scale); end
	else
		ApplyDefaultDebuffPos();
	end
end

function K.SaveAuraAnchorPosition()
	local db = DB();
	local point, _, relativePoint, x, y = anchor:GetPoint();
	if not point then return; end
	db.point = point; db.relativePoint = relativePoint; db.x = x; db.y = y;
	if K.UpdateAuraAnchorEvents then K.UpdateAuraAnchorEvents(); end
end

function K.SaveAuraAnchorScale(scale)
	DB().scale = scale;
end

function K.GetAuraAnchor()
	return anchor;
end

function K.SaveDebuffAnchorPosition()
	local db = DebuffDB();
	local point, _, relativePoint, x, y = debuffAnchor:GetPoint();
	if not point then return; end
	db.point = point; db.relativePoint = relativePoint; db.x = x; db.y = y;
	if K.UpdateAuraAnchorEvents then K.UpdateAuraAnchorEvents(); end
end

function K.SaveDebuffAnchorScale(scale)
	DebuffDB().scale = scale;
end

function K.ResetAuraAnchor()


	local db = DB();
	db.point, db.relativePoint, db.x, db.y, db.scale = nil, nil, nil, nil, nil;
	local ddb = DebuffDB();
	ddb.point, ddb.relativePoint, ddb.x, ddb.y, ddb.scale = nil, nil, nil, nil, nil;

	ApplyDefaultAnchorPos();
	ApplyDefaultDebuffPos();
	if BuffFrame_UpdateAllBuffAnchors then pcall(BuffFrame_UpdateAllBuffAnchors); end
	if not InCombatLockdown() and UIParent_ManageFramePositions then
		pcall(UIParent_ManageFramePositions);
	end
	if K.UpdateAuraAnchorEvents then K.UpdateAuraAnchorEvents(); end
end




local function ReanchorAuras()
	if not HasCustomPosition() then return; end


	local first = _G["BuffButton1"];
	if first then
		first:ClearAllPoints();
		first:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0);
	end


	local temp = _G["TempEnchant1"];
	if temp then
		temp:ClearAllPoints();
		temp:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0);

		if first and temp:IsShown() then
			first:ClearAllPoints();
			first:SetPoint("TOPRIGHT", temp, "TOPLEFT", -5, 0);
		end
	end
end


local function ReanchorDebuffs()
	if not HasCustomDebuffPosition() then return; end
	local first = _G["DebuffButton1"];
	if first then
		first:ClearAllPoints();
		first:SetPoint("TOPRIGHT", debuffAnchor, "TOPRIGHT", 0, 0);
	end
end
K.ReanchorDebuffs = ReanchorDebuffs;
K.ReanchorAuras = ReanchorAuras;









local function GetIconsPerRow()
	local v = C.AuraIconsPerRow;
	if type(v) ~= "number" or v < 1 then return 8; end
	return math.floor(v);
end
K.GetAuraIconsPerRow = GetIconsPerRow;















_G.BUFFS_PER_ROW = GetIconsPerRow();


function K.ApplyAuraIconsPerRow()
	_G.BUFFS_PER_ROW = GetIconsPerRow();
	if BuffFrame_UpdateAllBuffAnchors then pcall(BuffFrame_UpdateAllBuffAnchors); end
end

if type(BuffFrame_UpdateAllBuffAnchors) == "function" then
	hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
		ReanchorAuras();
		ReanchorDebuffs();
	end);
end

if type(BuffFrame_Update) == "function" then
	hooksecurefunc("BuffFrame_Update", function() ReanchorAuras(); ReanchorDebuffs(); end);
end






local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");

function K.UpdateAuraAnchorEvents()
	if HasCustomPosition() or HasCustomDebuffPosition() then
		events:RegisterEvent("UNIT_AURA");
	else
		events:UnregisterEvent("UNIT_AURA");
	end
end

events:SetScript("OnEvent", function(self, event, unit)
	if event == "UNIT_AURA" and unit ~= "player" then return; end
	if event == "PLAYER_ENTERING_WORLD" then
		RestoreAnchorPosition();
K.UpdateAuraAnchorEvents();
		K.UpdateAuraAnchorEvents();
	end
	ReanchorAuras();
	ReanchorDebuffs();
end);

RestoreAnchorPosition();
K.UpdateAuraAnchorEvents();












if K.LayoutRegisterStore then
	K.LayoutRegisterStore("AuraAnchor", RestoreAnchorPosition);
end
