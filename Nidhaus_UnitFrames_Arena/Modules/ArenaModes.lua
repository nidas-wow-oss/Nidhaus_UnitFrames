local AddOnName = ...;

local ns = NidhausUnitFramesNS;
local K, C, L = unpack(ns);

local STYLE_KEYS = {
	"ArenaFrameScale", "ArenaFrameSpacing",
	"ArenaCastBarScale", "ArenaCastBarWidth",
	"ArenaDRSize", "ArenaDRSpacing",
	"ArenaDoTSize", "ArenaDoTSpacing",
	"ArenaToTScale",
};
K.ArenaStyleKeys = STYLE_KEYS;

local ANCHOR_KEYS = { "ArenaMover", "NidhausArenaAnchor" };

local function StyleOf() return C.ArenaFrameStyle or "Custom"; end
local function ModeOf()
	if K.GetArenaPositionKey then return K.GetArenaPositionKey(); end
	return StyleOf() .. "_" .. (C.ArenaMirrorMode and "mirror" or "normal");
end

local function Store(name)
	if type(NidhausUnitFramesDB) ~= "table" then NidhausUnitFramesDB = {}; end
	if type(NidhausUnitFramesDB[name]) ~= "table" then NidhausUnitFramesDB[name] = {}; end
	return NidhausUnitFramesDB[name];
end

local function Copy(t)
	if type(t) ~= "table" then return nil; end
	local o = {};
	for k, v in pairs(t) do o[k] = v; end
	return o;
end

local activeStyle, activeMode;

local function StashStyle(style)
	local t = {};
	for _, k in ipairs(STYLE_KEYS) do t[k] = C[k]; end
	Store("ArenaStyleValues")[style] = t;
end

local function LoadStyle(style)
	local t = Store("ArenaStyleValues")[style];
	for _, k in ipairs(STYLE_KEYS) do
		local v = t and t[k];
		if v == nil and K.GetConfigDefault then v = K.GetConfigDefault(k); end
		if v ~= nil then
			if not (K.SaveConfigSilent and K.SaveConfigSilent(k, v)) then C[k] = v; end
		end
	end
end

local function StashAnchor(mode)
	local pos = Store("positions");
	local t = {};
	for _, k in ipairs(ANCHOR_KEYS) do t[k] = Copy(pos[k]); end
	Store("ArenaModeAnchors")[mode] = t;
end

local function LoadAnchor(mode)
	local pos = Store("positions");
	local t = Store("ArenaModeAnchors")[mode];
	for _, k in ipairs(ANCHOR_KEYS) do pos[k] = t and Copy(t[k]) or nil; end
end

local function SavedPoint(p)
	local point = p.point or p[1];
	local relName = p.relativeTo or p[2];
	local rel = (type(relName) == "string" and _G[relName]) or UIParent;
	return point, rel, p.relativePoint or p[3], p.x or p[4] or 0, p.y or p[5] or 0;
end

local function ApplyAnchor()
	if K.AfterCombat("ArenaModeAnchor", ApplyAnchor) then return; end
	local pos = NidhausUnitFramesDB and NidhausUnitFramesDB.positions;
	local p = pos and (pos.ArenaMover or pos.NidhausArenaAnchor);
	for _, name in ipairs({ "NidhausArenaEnemyFrames", "NUF_ArenaMover" }) do
		local f = _G[name];
		if f then
			f:ClearAllPoints();
			if type(p) == "table" and (p.point or p[1]) then
				f:SetPoint(SavedPoint(p));
			elseif C.ArenaFramePoint then
				f:SetPoint(unpack(C.ArenaFramePoint));
			end
		end
	end
end

local function ApplyStyleValues()
	if K.ApplyArenaScale then K.ApplyArenaScale(C.ArenaFrameScale); end
	if C.ArenaFrameOn and K.ApplyArenaSpacing then K.ApplyArenaSpacing(); end
	if C.ArenaCastBarEnable and K.ToggleArenaCastBar then K.ToggleArenaCastBar(true); end
	if K.ApplyArenaToTScale then K.ApplyArenaToTScale(C.ArenaToTScale); end

end

function K.RefreshArenaModeLayout()
	if K.RestoreCastBarPositions then pcall(K.RestoreCastBarPositions); end
	if K.PositionArenaTrinkets then pcall(K.PositionArenaTrinkets); end
	if K.RestorePetFramePositions then pcall(K.RestorePetFramePositions); end
	if K.RefreshArenaDRLayout then pcall(K.RefreshArenaDRLayout); end
	if K.RefreshArenaDoTLayout then pcall(K.RefreshArenaDoTLayout); end
	if K.RepositionAllArenaToT then pcall(K.RepositionAllArenaToT); end
	if K.RefreshArenaPanelSliders then pcall(K.RefreshArenaPanelSliders); end
end

local applyPending = false;
local applier = CreateFrame("Frame");
applier:Hide();

local function SwapIfChanged()
	if not activeStyle then activeStyle, activeMode = StyleOf(), ModeOf(); end
	local style, mode = StyleOf(), ModeOf();
	local changed = false;
	if style ~= activeStyle then
		StashStyle(activeStyle);
		LoadStyle(style);
		activeStyle = style;
		changed = true;
	end
	if mode ~= activeMode then
		StashAnchor(activeMode);
		LoadAnchor(mode);
		activeMode = mode;
		changed = true;
	end
	if changed then
		applyPending = true;
		applier:Show();
	end
	return changed;
end
K.SwapArenaModeData = SwapIfChanged;

local function ApplyPending()
	applier:Hide();
	if not applyPending then return false; end
	applyPending = false;
	pcall(ApplyAnchor);
	pcall(ApplyStyleValues);
	K.RefreshArenaModeLayout();
	return true;
end
applier:SetScript("OnUpdate", function() ApplyPending(); end);

function K.SyncArenaMode()
	SwapIfChanged();
	return ApplyPending();
end

function K.GetActiveArenaStyle() return activeStyle or StyleOf(); end

local LEGACY_TABLES = { "CastBarPositions", "TrinketPositions", "PetFramePositions" };

local function MigrateLegacy()
	if type(NidhausUnitFramesDB) ~= "table" then return; end
	local style = StyleOf();
	for _, name in ipairs(LEGACY_TABLES) do
		local db = NidhausUnitFramesDB[name];
		if type(db) == "table" then
			local n = db.normal or db.global;
			local m = db.mirror or db.global;
			if n and db[style .. "_normal"] == nil then db[style .. "_normal"] = n; end
			if m and db[style .. "_mirror"] == nil then db[style .. "_mirror"] = m; end
			db.normal, db.mirror, db.global = nil, nil, nil;
		end
	end
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	MigrateLegacy();
	activeStyle, activeMode = StyleOf(), ModeOf();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if activeStyle then SwapIfChanged(); end
end);
