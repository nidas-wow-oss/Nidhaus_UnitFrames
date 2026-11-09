local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local ANCHOR_W, ANCHOR_H = 330, 90;

local function BuffRoot()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.AuraAnchor then NidhausUnitFramesDB.AuraAnchor = {}; end
	return NidhausUnitFramesDB.AuraAnchor;
end

local function DebuffRoot()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.DebuffAnchor then NidhausUnitFramesDB.DebuffAnchor = {}; end
	return NidhausUnitFramesDB.DebuffAnchor;
end

local MODES = { "mini", "unify", "plain" };

local function Mode()
	if K.LayoutActiveMode then return K.LayoutActiveMode(); end

	if C.MiniBarEnabled  == true then return "mini";  end
	if C.UnifyActionBars == true then return "unify"; end
	return "plain";
end

local function PerMode(root)
	if root.point ~= nil and type(root.byMode) ~= "table" then
		root.byMode = {};
		for _, m in ipairs(MODES) do
			root.byMode[m] = {
				point = root.point, relativePoint = root.relativePoint,
				x     = root.x,     y             = root.y,
			};
		end
		root.point, root.relativePoint, root.x, root.y = nil, nil, nil, nil;
	end
	if type(root.byMode) ~= "table" then root.byMode = {}; end
	local m = Mode();
	if type(root.byMode[m]) ~= "table" then root.byMode[m] = {}; end
	return root.byMode[m];
end

local function DB()       return PerMode(BuffRoot());   end
local function DebuffDB() return PerMode(DebuffRoot()); end

local function WipeAllModes(root)
	root.point, root.relativePoint, root.x, root.y = nil, nil, nil, nil;
	root.byMode = {};
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

local function BuffScale()
	return (K.GetModuleScale and K.GetModuleScale("PlayerBuffs")) or 1;
end
local function DebuffScale()
	return (K.GetModuleScale and K.GetModuleScale("PlayerDebuffs")) or 1;
end

local function ApplyDefaultAnchorPos()
	local s = BuffScale();
	if not s or s <= 0 then s = 1; end
	anchor:SetScale(s);
	anchor:ClearAllPoints();
	local bf = _G["BuffFrame"];
	if bf and bf.GetRight then
		anchor:SetPoint("TOPRIGHT", bf, "TOPRIGHT", 0, 0);
	else
		anchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -MinimapInset() / s, -13 / s);
	end
end

local ROOT_NAMES = { "BuffFrame", "ConsolidatedBuffs", "TemporaryEnchantFrame" };
local rootBase   = {};
local rootShift  = 0;
local applyingRoots = false;

local function CaptureRoot(name, f)
	local p, rel, rp, x, y = f:GetPoint(1);
	if p and (rel == nil or rel == UIParent) then
		rootBase[name] = { p, rp or p, x or 0, y or 0 };
	else
		rootBase[name] = false;
	end
end

local function PlaceRoot(name)
	local f, b = _G[name], rootBase[name];
	if not (f and b) then return; end
	local s = f:GetScale() or 1;
	if s == 0 then s = 1; end
	applyingRoots = true;
	f:ClearAllPoints();
	f:SetPoint(b[1], UIParent, b[2], b[3] - rootShift / s, b[4]);
	applyingRoots = false;
end

local function HookRoot(name)
	local f = _G[name];
	if not f or not f.GetPoint or f._nufRootHook then return; end
	f._nufRootHook = true;
	CaptureRoot(name, f);

	hooksecurefunc(f, "SetPoint", function(self)
		if applyingRoots then return; end
		CaptureRoot(name, self);
		if rootShift ~= 0 then PlaceRoot(name); end
	end);
end

local function MinimapShift()
	local mc, bf = MinimapCluster, _G["BuffFrame"];
	if not (mc and bf and mc.GetLeft and bf.GetRight) then return 0; end
	local ui = UIParent:GetEffectiveScale();
	if not ui or ui == 0 then return 0; end
	local l, r, tp, bo = mc:GetLeft(), mc:GetRight(), mc:GetTop(), mc:GetBottom();
	local br, bt = bf:GetRight(), bf:GetTop();
	if not (l and r and tp and bo and br and bt) then return 0; end
	local ms = (mc:GetEffectiveScale() or 1) / ui;
	local bs = (bf:GetEffectiveScale() or 1) / ui;
	l, r, tp, bo = l * ms, r * ms, tp * ms, bo * ms;

	local baseRight, baseTop = br * bs + rootShift, bt * bs;

	local bandBottom = baseTop - 2 * (30 + 12) * (BuffScale() or 1);
	local sameHeight = tp > bandBottom and bo < baseTop;
	local onTheRight = r > baseRight;
	if not (sameHeight and onTheRight) then return 0; end
	local shift = baseRight - (l - CLUSTER_PAD);
	if shift < 0 then shift = 0; end
	return shift;
end

local function ApplyMinimapAvoidance()
	for _, n in ipairs(ROOT_NAMES) do HookRoot(n); end
	local new = MinimapShift();
	if math.abs(new - rootShift) < 0.5 then return; end
	rootShift = new;
	for _, n in ipairs(ROOT_NAMES) do PlaceRoot(n); end
	if K.RequestMoverRefresh then K.RequestMoverRefresh(); end
end
K.ApplyBuffMinimapAvoidance = ApplyMinimapAvoidance;

function K.RefreshAuraAnchorDefault()

	ApplyMinimapAvoidance();
	if HasCustomPosition() then return; end
	ApplyDefaultAnchorPos();

	if K.ReanchorAuras then K.ReanchorAuras(); end
	if K.ReanchorDebuffs then K.ReanchorDebuffs(); end
end

local function BlizzardDebuffOffset()
	local te  = _G["TempEnchant1"];
	local h   = (te and te.GetHeight and te:GetHeight()) or 30;
	if type(h) ~= "number" or h < 8 then h = 30; end
	local sp  = tonumber(BUFF_ROW_SPACING) or 0;
	local per = tonumber(BUFFS_PER_ROW) or 8;
	if per < 1 then per = 8; end
	local bf  = _G["BuffFrame"];
	local nb  = (tonumber(BUFF_ACTUAL_DISPLAY) or 0) + ((bf and tonumber(bf.numEnchants)) or 0);
	local nc  = (bf and tonumber(bf.numConsolidated)) or 0;
	if nc > 0 then nb = nb - nc + 1; end
	local rows = math.ceil(nb / per);
	local px;
	if rows < 2 then px = (2 * sp) + h; else px = rows * (sp + h); end

	local te_es = te and te.GetEffectiveScale and te:GetEffectiveScale();
	local da_es = debuffAnchor.GetEffectiveScale and debuffAnchor:GetEffectiveScale();
	if te_es and da_es and te_es > 0 and da_es > 0 then
		px = px * te_es / da_es;
	end
	return px;
end

local function ApplyDefaultDebuffPos()

	if debuffAnchor._nufDragging then return; end
	local s = DebuffScale();
	if not s or s <= 0 then s = 1; end
	debuffAnchor:SetScale(s);
	debuffAnchor:ClearAllPoints();
	local te = _G["TempEnchant1"];
	if te then
		debuffAnchor:SetPoint("TOPRIGHT", te, "BOTTOMRIGHT", 0, -BlizzardDebuffOffset());
	else

		debuffAnchor:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -20 / s);
	end
end

local function RestoreAnchorPosition()
	ApplyMinimapAvoidance();

	local broot = BuffRoot();
	if broot.scale then
		if K.SetModuleScale then K.SetModuleScale("PlayerBuffs", broot.scale); end
		broot.scale = nil;
	end

	local db = DB();
	if db.point then
		anchor:ClearAllPoints();
		anchor:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
		anchor:SetScale(BuffScale());
	else
		ApplyDefaultAnchorPos();
	end

	local droot = DebuffRoot();
	if droot.scale then
		if K.SetModuleScale then K.SetModuleScale("PlayerDebuffs", droot.scale); end
		droot.scale = nil;
	end

	local ddb = DebuffDB();
	if ddb.point then
		debuffAnchor:ClearAllPoints();
		debuffAnchor:SetPoint(ddb.point, UIParent, ddb.relativePoint, ddb.x, ddb.y);
		debuffAnchor:SetScale(DebuffScale());
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
	if K.SetModuleScale then K.SetModuleScale("PlayerBuffs", scale); end
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
	if K.SetModuleScale then K.SetModuleScale("PlayerDebuffs", scale); end
end

function K.ResetAuraAnchor()

	WipeAllModes(BuffRoot());
	WipeAllModes(DebuffRoot());

	if K.ResetModuleScale then
		K.ResetModuleScale("PlayerBuffs");
		K.ResetModuleScale("PlayerDebuffs");
	end

	ApplyDefaultAnchorPos();
	ApplyDefaultDebuffPos();

	if not InCombatLockdown() and UIParent_ManageFramePositions then
		pcall(UIParent_ManageFramePositions);
	end
	if K.UpdateAuraAnchorEvents then K.UpdateAuraAnchorEvents(); end
end

local function ScaledLayout()
	return math.abs(BuffScale() - 1) > 0.001 or math.abs(DebuffScale() - 1) > 0.001;
end

local function RowHead()
	local cb = _G["ConsolidatedBuffs"];
	if cb and cb:IsShown() then return cb; end
	local te = _G["TempEnchant1"];
	if te and te:IsShown() then return te; end
	for i = 1, (BUFF_ACTUAL_DISPLAY or 0) do
		local b = _G["BuffButton" .. i];
		if b and b:IsShown() and not b.consolidated then return b; end
	end
end

local function FixBuffRows()
	local cb = _G["ConsolidatedBuffs"];
	if not cb then return; end
	local head = RowHead();
	if not head or head == cb then return; end
	local sp = tonumber(BUFF_ROW_SPACING) or 0;
	for i = 1, (BUFF_ACTUAL_DISPLAY or 0) do
		local b = _G["BuffButton" .. i];
		if b and b ~= head and b:GetNumPoints() > 0 then
			local p, rel = b:GetPoint(1);
			if p == "TOP" and rel == cb then
				b:ClearAllPoints();
				b:SetPoint("TOP", head, "BOTTOM", 0, -sp);
			end
		end
	end
end

local function ReanchorAuras()
	if HasCustomPosition() or ScaledLayout() then FixBuffRows(); end
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
	if not (HasCustomDebuffPosition() or ScaledLayout()) then return; end
	local first = _G["DebuffButton1"];
	if first then
		first:ClearAllPoints();
		first:SetPoint("TOPRIGHT", debuffAnchor, "TOPRIGHT", 0, 0);
	end
end
K.ReanchorDebuffs = ReanchorDebuffs;
K.ReanchorAuras = ReanchorAuras;

if type(K.FramePositionOwners) ~= "table" then K.FramePositionOwners = {}; end
K.FramePositionOwners["Buffs"]   = function() K.SaveAuraAnchorPosition();   ReanchorAuras();   end
K.FramePositionOwners["Debuffs"] = function() K.SaveDebuffAnchorPosition(); ReanchorDebuffs(); end

if type(K.FramePositionIsCustom) ~= "table" then K.FramePositionIsCustom = {}; end
K.FramePositionIsCustom["Buffs"]   = HasCustomPosition;
K.FramePositionIsCustom["Debuffs"] = HasCustomDebuffPosition;

local BUFF_ICONS   = BUFF_MAX_DISPLAY   or 32;
local DEBUFF_ICONS = DEBUFF_MAX_DISPLAY or 16;

local function ScaleIcons(prefix, count, scale)
	for i = 1, count do
		local b = _G[prefix .. i];
		if b and b.SetScale then pcall(b.SetScale, b, scale); end
	end
end

local function ApplyBuffIconScale()
	local s = BuffScale();
	ScaleIcons("BuffButton", BUFF_ICONS, s);

	ScaleIcons("TempEnchant", 3, s);
end

local function ApplyDebuffIconScale()
	ScaleIcons("DebuffButton", DEBUFF_ICONS, DebuffScale());
end

K.ApplyAuraIconScales = function()
	ApplyBuffIconScale();
	ApplyDebuffIconScale();
end

local function OnAuraScaleChanged(id)
	if id == "PlayerBuffs" then
		ApplyBuffIconScale();

		if not HasCustomPosition() then ApplyDefaultAnchorPos(); end
		if not HasCustomDebuffPosition() then ApplyDefaultDebuffPos(); end
	elseif id == "PlayerDebuffs" then
		ApplyDebuffIconScale();
		if not HasCustomDebuffPosition() then ApplyDefaultDebuffPos(); end
	end

	if id == "PlayerBuffs" or id == "PlayerDebuffs" then
		ReanchorAuras();
		ReanchorDebuffs();
	end
end
if type(K.SetModuleScale) == "function" then
	hooksecurefunc(K, "SetModuleScale", OnAuraScaleChanged);
end

if type(K.ResetModuleScale) == "function" then
	hooksecurefunc(K, "ResetModuleScale", OnAuraScaleChanged);
end

local function GetIconsPerRow()
	local v = C.AuraIconsPerRow;
	if type(v) ~= "number" or v < 1 then return 8; end
	return math.floor(v);
end
K.GetAuraIconsPerRow = GetIconsPerRow;

local function ApplyBuffsPerRow()
	local n = GetIconsPerRow();
	if _G.BUFFS_PER_ROW ~= n then
		_G.BUFFS_PER_ROW = n;
	end
end

if K.RegisterConfigEvent then
	K.RegisterConfigEvent("CONFIG_LOADED", ApplyBuffsPerRow);
end

function K.ApplyAuraIconsPerRow()
	ApplyBuffsPerRow();
	if K.ReanchorAuras then K.ReanchorAuras(); end
	if K.ReanchorDebuffs then K.ReanchorDebuffs(); end

	if not HasCustomDebuffPosition() then ApplyDefaultDebuffPos(); end

	if K.RequestMoverRefresh then K.RequestMoverRefresh(); end
end

local function AfterBlizzardLayout()
	if K.ApplyAuraIconScales then K.ApplyAuraIconScales(); end
	ReanchorAuras();
	ReanchorDebuffs();
	if not HasCustomDebuffPosition() then ApplyDefaultDebuffPos(); end
	if K.RequestMoverRefresh then K.RequestMoverRefresh(); end
end

if type(BuffFrame_UpdateAllBuffAnchors) == "function" then
	hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", AfterBlizzardLayout);
end

if type(BuffFrame_Update) == "function" then
	hooksecurefunc("BuffFrame_Update", AfterBlizzardLayout);
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
	end
	ReanchorAuras();
	ReanchorDebuffs();
end);

RestoreAnchorPosition();
K.UpdateAuraAnchorEvents();

if K.LayoutRegisterStore then
	K.LayoutRegisterStore("AuraAnchor", RestoreAnchorPosition);
end
