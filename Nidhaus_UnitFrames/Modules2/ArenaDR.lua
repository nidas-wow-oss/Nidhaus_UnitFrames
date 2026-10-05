


















































local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local GetTime, UnitGUID, UnitExists, GetSpellInfo, IsInInstance =
	GetTime, UnitGUID, UnitExists, GetSpellInfo, IsInInstance;
local CooldownFrame_SetTimer = CooldownFrame_SetTimer;
local ipairs, pairs, tinsert, tremove, select, max, min, floor =
	ipairs, pairs, table.insert, table.remove, select, math.max, math.min, math.floor;

local MAX_ARENA = MAX_ARENA_ENEMIES or 5;


local DR_RESET  = 18;
local MAX_ICONS = 6;
local LIFT_Y    = 5;
local DEF_SIZE  = 22;
local DEF_GAP   = 2;


local CATEGORIES = {
	ctrlstun = {
		20253,
		408, 8643,
		853, 5588, 5589, 10308,
		44572,
		30283, 30413, 30414, 47846, 47847,
		12809,
		46968,
		5211, 6798, 8983,
		22570, 49802,
		47481,
		20549,
		2812, 10318, 27139, 48816, 48817,
		58861,
		50518, 53558, 53559, 53560, 53561, 53562,
		50519, 53564, 53565, 53566, 53567, 53568,
		60995,
		30153, 30195, 30197, 47995,
		22703,
	},
	openstun = {
		1833,
		9005, 9823, 9827, 27006, 49803,
	},
	rndstun = {
		12355,
		39796,
		20170,
		12798,
	},
	disorient = {
		6770, 2070, 11297, 51724,
		1776,
		118, 12824, 12825, 12826, 28271, 28272, 61025, 61305, 61721, 61780,
		20066,
		49203,
		3355, 14308, 14309,
		60210,
		19386, 24132, 24133, 27068, 49011, 49012,
		51514,
		31661, 33041, 33042, 33043, 42949, 42950,
		9484, 9485, 10955,
	},
	fear = {
		2094,
		5782, 6213, 6215,
		5484, 17928,
		5246, 20511,
		8122, 8124, 10888, 10890,
		6358,
		1513, 14326, 14327,
		10326,
	},
	horror = {
		64044,
		6789, 17925, 17926, 27223, 47859, 47860,
	},
	silence = {
		47476, 49913, 49914, 49915, 49916,
		34490,
		18469, 55021,
		15487,
		1330,
		24259,
		18498,
		25046, 28730, 50613,
		31117,
		63529,
		18425,
		53588, 53589,
	},
	cyclone = { 33786 },
	ctrlroot = {
		33395,
		122, 865, 6131, 10230, 27088, 42917,
		339, 1062, 5195, 5196, 9852, 9853, 26989, 53308,
		19970, 19971, 19972, 19973, 19974, 19975, 27010, 53313,
		50245, 53544, 53545, 53546, 53547, 53548,
		4167,
		54706, 55505, 55506, 55507, 55508, 55509,
		64695, 8377, 31983,
	},
	rndroot = {
		23694,
		12494,
		55080,
	},
	sleep = { 2637, 18657, 18658 },
	disarm = {
		51722,
		64058,
		676,
		53359,
		50541, 53537, 53538, 53540, 53542, 53543,
	},
	entrapment   = { 19185, 64803, 64804 },
	scatter      = { 19503 },
	mc           = { 605 },
	banish       = { 710, 18647 },
	charge       = { 7922 },
	intimidation = { 24394 },
};

local idToCat = {};
for cat, ids in pairs(CATEGORIES) do
	for _, id in ipairs(ids) do idToCat[id] = cat; end
end


local CLASS_ICONS = {
	DEATHKNIGHT = { ctrlstun = "spell_deathknight_gnaw_ghoul", disorient = "inv_staff_15",
	                silence = "spell_shadow_soulleech_3" },
	DRUID       = { ctrlstun = "ability_druid_bash", cyclone = "spell_nature_earthbind",
	                ctrlroot = "spell_nature_stranglevines", sleep = "spell_nature_sleep",
	                openstun = "ability_druid_supriseattack" },
	HUNTER      = { disarm = "ability_hunter_chimerashot2", entrapment = "spell_nature_stranglevines",
	                disorient = "spell_frost_chainsofice", ctrlroot = "spell_nature_web",
	                fear = "ability_druid_cower", scatter = "ability_golemstormbolt",
	                ctrlstun = "ability_druid_primaltenacity", silence = "ability_theblackarrow",
	                intimidation = "ability_devour" },
	MAGE        = { ctrlstun = "ability_mage_deepfreeze", ctrlroot = "spell_frost_frostnova",
	                disorient = "spell_nature_polymorph", silence = "spell_frost_iceshock" },
	PALADIN     = { ctrlstun = "spell_holy_sealofmight", disorient = "spell_holy_prayerofhealing",
	                fear = "spell_holy_turnundead", silence = "spell_holy_avengersshield" },
	PRIEST      = { fear = "spell_shadow_psychicscream", mc = "spell_shadow_shadowworddominate",
	                horror = "spell_shadow_psychichorrors", disarm = "ability_warrior_disarm",
	                disorient = "spell_nature_slow", silence = "spell_shadow_impphaseshift" },
	ROGUE       = { fear = "spell_shadow_mindsteal", openstun = "ability_cheapshot",
	                disarm = "ability_rogue_dismantle", silence = "ability_rogue_garrote",
	                disorient = "ability_gouge", ctrlstun = "ability_rogue_kidneyshot" },
	SHAMAN      = { ctrlstun = "ability_druid_bash", disorient = "spell_shaman_hex" },
	WARLOCK     = { banish = "spell_shadow_cripple", horror = "spell_shadow_deathcoil",
	                ctrlstun = "spell_shadow_shadowfury", fear = "spell_shadow_possession",
	                silence = "spell_shadow_mindrot" },
	WARRIOR     = { ctrlstun = "ability_thunderbolt", disarm = "ability_warrior_disarm",
	                silence = "ability_warrior_shieldbash", fear = "ability_golemthunderclap" },
};

local playerClass;
local function IconForCategory(cat, spellID)
	playerClass = playerClass or select(2, UnitClass("player"));
	local own = CLASS_ICONS[playerClass] and CLASS_ICONS[playerClass][cat];
	if own then return "Interface\\Icons\\" .. own; end
	return select(3, GetSpellInfo(spellID)) or "Interface\\Icons\\INV_Misc_QuestionMark";
end



local state = {};
local holders = {};
local guidToIdx = {};
local enabled = false;
local listening = false;
local previewOn = false;

local function InArena()
	local _, instanceType = IsInInstance();
	return instanceType == "arena";
end

local function IsTestMode()
	return K._testModeActive or (NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover
		and NidhausUnitFramesDB.ArenaMover.IsShown) and true or false;
end

local function RefreshGUIDs()
	for i = 1, MAX_ARENA do
		local u = "arena" .. i;
		if UnitExists(u) then
			local g = UnitGUID(u);
			if g then guidToIdx[g] = i; end
		end
	end
end

local function IdxFromGUID(guid)
	local i = guidToIdx[guid];
	if i then return i; end
	RefreshGUIDs();
	return guidToIdx[guid];
end

local function FindRec(idx, cat)
	local list = state[idx];
	if not list then return nil; end
	for _, rec in ipairs(list) do
		if rec.cat == cat then return rec; end
	end
	return nil;
end


local function OptSize()
	local s = tonumber(C.ArenaDRSize) or DEF_SIZE;
	if s < 12 then s = 12; elseif s > 48 then s = 48; end
	return s;
end
local function OptGap()
	local g = tonumber(C.ArenaDRSpacing) or DEF_GAP;
	if g < 0 then g = 0; elseif g > 20 then g = 20; end
	return g;
end
local GROW_OK = { AUTO = true, LEFT = true, RIGHT = true, UP = true, DOWN = true };
local function OptGrow()
	local g = C.ArenaDRGrow;
	return GROW_OK[g] and g or "AUTO";
end



local CAT_ORDER = {
	"ctrlstun", "openstun", "rndstun", "disorient", "fear", "horror",
	"silence", "cyclone", "ctrlroot", "rndroot", "sleep", "disarm",
	"entrapment", "scatter", "mc", "banish", "charge", "intimidation",
};

local function OwnCats()
	playerClass = playerClass or select(2, UnitClass("player"));
	return CLASS_ICONS[playerClass] or {};
end



local hiddenSrc, hiddenSet;
local function HiddenSet()
	local s = C.ArenaDRHideCats;
	if type(s) ~= "string" then s = ""; end
	if s ~= hiddenSrc then
		hiddenSrc = s;
		hiddenSet = {};
		for cat in string.gmatch(s, "[^,%s]+") do hiddenSet[cat] = true; end
	end
	return hiddenSet;
end

local function CatShown(cat)
	if HiddenSet()[cat] then return false; end


	if C.ArenaDRClassOnly and not OwnCats()[cat] then return false; end
	return true;
end



local function Visible(rec)
	return CatShown(rec.cat);
end


local function PosKey()
	if K.GetArenaPositionKey then return K.GetArenaPositionKey(); end
	return C.ArenaMirrorMode and "mirror" or "normal";
end





local DIR_OK = { LEFT = true, RIGHT = true, UP = true, DOWN = true };
local function GetSavedPos()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaDRPositions;
	local p = db and db[PosKey()];
	if type(p) == "table" and tonumber(p[1]) and tonumber(p[2]) then
		return tonumber(p[1]), tonumber(p[2]), DIR_OK[p[3]] and p[3] or nil;
	end
end

local function SavePos(x, y, dir)
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if type(NidhausUnitFramesDB.ArenaDRPositions) ~= "table" then
		NidhausUnitFramesDB.ArenaDRPositions = {};
	end
	NidhausUnitFramesDB.ArenaDRPositions[PosKey()] = { x, y, dir };
end


local LEVEL_COLOR = {
	{ 1.00, 0.90, 0.10 },
	{ 1.00, 0.45, 0.00 },
	{ 1.00, 0.10, 0.10 },
};
local LEVEL_TEXT = { "1/2", "1/4", "X" };

local RefreshAll;

local function StartDrag(h)
	if not previewOn or h._moving then return; end
	if InCombatLockdown and InCombatLockdown() then return; end
	if not (IsShiftKeyDown() and IsAltKeyDown()) then return; end
	h:SetMovable(true);
	h:StartMoving();
	h._moving = true;
end

local function StopDrag(h)
	if not h._moving then return; end
	h:StopMovingOrSizing();
	h._moving = false;
	local af = h:GetParent();
	local hx, hy = h:GetCenter();

	local ax, ay;
	if af then ax, ay = af:GetCenter(); end
	if hx and hy and ax and ay then




		local hs = h:GetEffectiveScale() or 1;
		local as = af:GetEffectiveScale() or 1;
		if hs == 0 then hs = 1; end
		local x = floor(((hx * hs - ax * as) / hs) * 10 + 0.5) / 10;
		local y = floor(((hy * hs - ay * as) / hs) * 10 + 0.5) / 10;
		SavePos(x, y, h._lastDir);
	end
	RefreshAll();
end

local function ShowMoveTip(self)
	if not previewOn then return; end
	GameTooltip:SetOwner(self, "ANCHOR_TOP");
	GameTooltip:SetText(L["HEADER_ARENA_DR"] or "Diminishing Returns", 1, 1, 1);
	GameTooltip:AddLine(L["DR_MOVE_HINT"] or "Shift+Alt+drag to move", nil, nil, nil, true);
	GameTooltip:Show();
end

local function CreateHolder(idx)
	local af = _G["ArenaEnemyFrame" .. idx];
	if not af then return nil; end
	local h = CreateFrame("Frame", nil, af);



	h:SetFrameStrata("MEDIUM");
	h:SetFrameLevel(af:GetFrameLevel() + 5);
	h:SetClampedToScreen(true);
	h:EnableMouse(false);
	h:SetScript("OnMouseDown", function(self, b) if b == "LeftButton" then StartDrag(self); end end);
	h:SetScript("OnMouseUp", function(self, b) if b == "LeftButton" then StopDrag(self); end end);
	h:SetScript("OnHide", function(self)
		if self._moving then self:StopMovingOrSizing(); self._moving = false; end
	end);
	h.icons = {};
	return h;
end

local function GetHolder(idx)
	if not holders[idx] then holders[idx] = CreateHolder(idx); end
	return holders[idx];
end

local function CreateIcon(h)
	local f = CreateFrame("Frame", nil, h);
	f:SetFrameLevel(h:GetFrameLevel() + 1);

	f.tex = f:CreateTexture(nil, "ARTWORK");
	f.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93);

	f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate");


	local tf = CreateFrame("Frame", nil, f);
	tf:SetAllPoints(f);
	tf:SetFrameLevel(f.cd:GetFrameLevel() + 2);
	f.txt = tf:CreateFontString(nil, "OVERLAY");
	f.txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE");
	f.txt:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 1);









	f.time = tf:CreateFontString(nil, "OVERLAY");
	f.time:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE");
	f.time:SetPoint("TOP", f, "TOP", 0, -1);
	f.time:Hide();
	f.cd.noCooldownCount = true;


	f:EnableMouse(false);
	f:SetScript("OnMouseDown", function(_, b) if b == "LeftButton" then StartDrag(h); end end);
	f:SetScript("OnMouseUp", function(_, b) if b == "LeftButton" then StopDrag(h); end end);
	f:SetScript("OnEnter", ShowMoveTip);
	f:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	f:Hide();
	return f;
end


local function ApplyLook(w, col, size)
	local edge = (C.ArenaDRBorder ~= false) and 2 or 1;
	if w._edge ~= edge then
		w:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = edge });
		w.tex:ClearAllPoints();
		w.tex:SetPoint("TOPLEFT", edge, -edge);
		w.tex:SetPoint("BOTTOMRIGHT", -edge, edge);
		w.cd:ClearAllPoints();
		w.cd:SetPoint("TOPLEFT", edge, -edge);
		w.cd:SetPoint("BOTTOMRIGHT", -edge, edge);
		w._edge = edge;
	end
	if edge == 2 then
		w:SetBackdropBorderColor(col[1], col[2], col[3], 1);
	else
		w:SetBackdropBorderColor(0, 0, 0, 1);
	end
	local fs = max(8, floor(size * 0.45 + 0.5));
	if w._fs ~= fs then
		w.txt:SetFont("Fonts\\FRIZQT__.TTF", fs, "OUTLINE");
		w.time:SetFont("Fonts\\FRIZQT__.TTF", fs, "OUTLINE");
		w._fs = fs;
	end
end





local function SetTimeText(w, now)
	local e = w._expire;
	local sec;
	if e and C.ArenaDRTimer ~= false then
		local r = e - now;
		if r > 0 then sec = math.ceil(r); end
	end
	if sec then
		if w._sec ~= sec then
			w.time:SetText(sec);
			w._sec = sec;
		end
		w.time:Show();
	else
		w._sec = nil;
		w.time:Hide();
	end
end



local function CastBarOnLeft(parent, cb)
	if cb then
		local cx = cb:GetCenter();
		local px = parent:GetCenter();
		if cx and px then
			return cx * cb:GetEffectiveScale() < px * parent:GetEffectiveScale();
		end
	end
	return not C.ArenaMirrorMode;
end

local function Layout(idx, h, shown)
	local af = _G["ArenaEnemyFrame" .. idx];
	if not af then return; end
	local size, gap = OptSize(), OptGap();
	local dir = OptGrow();

	h:SetWidth(size);
	h:SetHeight(size);
	if not h._moving then
		h:ClearAllPoints();
		local x, y, savedDir = GetSavedPos();
		if x then
			h:SetPoint("CENTER", af, "CENTER", x, y);
			if dir == "AUTO" then dir = savedDir or ((x < 0) and "LEFT" or "RIGHT"); end
		else
			local cb = _G["ArenaEnemyFrame" .. idx .. "CastingBar"];
			local left = CastBarOnLeft(af, cb);
			if cb then

				if left then
					h:SetPoint("BOTTOMRIGHT", cb, "TOPRIGHT", 0, LIFT_Y);
				else
					h:SetPoint("BOTTOMLEFT", cb, "TOPLEFT", 0, LIFT_Y);
				end
			elseif left then
				h:SetPoint("BOTTOMRIGHT", af, "LEFT", -8, 2);
			else
				h:SetPoint("BOTTOMLEFT", af, "RIGHT", 8, 2);
			end
			if dir == "AUTO" then dir = left and "LEFT" or "RIGHT"; end
		end
	elseif dir == "AUTO" then
		dir = (h._lastDir or "LEFT");
	end
	h._lastDir = dir;

	local prev;
	for k = 1, shown do
		local w = h.icons[k];
		w:SetWidth(size);
		w:SetHeight(size);
		w:ClearAllPoints();
		if not prev then
			w:SetPoint("CENTER", h, "CENTER", 0, 0);
		elseif dir == "LEFT" then
			w:SetPoint("RIGHT", prev, "LEFT", -gap, 0);
		elseif dir == "RIGHT" then
			w:SetPoint("LEFT", prev, "RIGHT", gap, 0);
		elseif dir == "UP" then
			w:SetPoint("BOTTOM", prev, "TOP", 0, gap);
		else
			w:SetPoint("TOP", prev, "BOTTOM", 0, -gap);
		end
		prev = w;
	end
end

local function Refresh(idx)
	local list = state[idx];
	local h = holders[idx];
	if not h and not (enabled and list and #list > 0) then return; end
	h = h or GetHolder(idx);
	if not h then return; end

	local size = OptSize();
	local showText = (C.ArenaDRText ~= false);
	local shown = 0;
	if enabled and list then
		for _, rec in ipairs(list) do
			if shown >= MAX_ICONS then break; end
			if Visible(rec) then
				shown = shown + 1;
				local w = h.icons[shown];
				if not w then w = CreateIcon(h); h.icons[shown] = w; end

				local lvl = min(rec.n, 3);
				local col = LEVEL_COLOR[lvl];
				ApplyLook(w, col, size);
				w.tex:SetTexture(rec.icon);
				w.txt:SetText(LEVEL_TEXT[lvl]);
				w.txt:SetTextColor(col[1], col[2], col[3]);
				if showText then w.txt:Show(); else w.txt:Hide(); end

				if rec.expire then
					CooldownFrame_SetTimer(w.cd, rec.expire - DR_RESET, DR_RESET, 1);
				else
					CooldownFrame_SetTimer(w.cd, 0, 0, 0);
				end
				w._expire = rec.expire;
				SetTimeText(w, GetTime());
				w:EnableMouse(previewOn);
				w:Show();
			end
		end
	end
	for k = shown + 1, #h.icons do h.icons[k]:Hide(); end

	h:EnableMouse(previewOn and shown > 0);
	if shown > 0 then
		Layout(idx, h, shown);
		h:Show();
	else
		h:Hide();
	end
end

RefreshAll = function()
	for i = 1, MAX_ARENA do Refresh(i); end
end

local function WipeAll()
	for i = 1, MAX_ARENA do state[i] = nil; end
	RefreshAll();
end





local function FillPreview()
	local own = OwnCats();
	local cats = {};
	for pass = 1, 2 do
		for _, cat in ipairs(CAT_ORDER) do
			local mine = own[cat] ~= nil;
			if (pass == 1) == mine and CatShown(cat) then cats[#cats + 1] = cat; end
		end
	end

	local now = GetTime();
	local n = min(#cats, 4);
	for idx = 1, MAX_ARENA do
		state[idx] = {};
		for j = 1, n do
			local cat = cats[j];
			tinsert(state[idx], {
				cat = cat, n = ((j + idx - 2) % 3) + 1,
				active = 0,
				expire = now + DR_RESET - j * 3,
				lastApplied = now,
				icon = IconForCategory(cat, CATEGORIES[cat][1]),
				preview = true,
			});
		end
	end
end

local driver;

local function SetPreview(on)
	on = (on and enabled) and true or false;
	if on == previewOn then
		if on then RefreshAll(); end
		return;
	end
	previewOn = on;
	if on then
		FillPreview();
		driver:Show();
	else
		WipeAll();
	end
	RefreshAll();
end


driver = CreateFrame("Frame");
driver:Hide();
local acc = 0;
driver:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < 0.25 then return; end
	acc = 0;

	local now = GetTime();
	local any = false;
	for idx = 1, MAX_ARENA do
		local list = state[idx];
		if list then
			local changed = false;
			for j = #list, 1, -1 do
				local rec = list[j];
				if rec.preview then

					if now >= rec.expire then
						rec.expire = now + DR_RESET;
						changed = true;
					end
				else


					if rec.active > 0 and (now - rec.lastApplied) > 70 then
						rec.active = 0;
						rec.expire = now + DR_RESET;
						changed = true;
					end
					if rec.expire and now >= rec.expire then
						tremove(list, j);
						changed = true;
					end
				end
			end
			if #list > 0 then any = true; else state[idx] = nil; end
			if changed then
				Refresh(idx);
			else

				local h = holders[idx];
				if h and h:IsShown() then
					for _, w in ipairs(h.icons) do
						if w:IsShown() then SetTimeText(w, now); end
					end
				end
			end
		end
	end
	if not any then self:Hide(); end
end);




local function OnCLEU(...)
	local _, sub, _, _, _, dstGUID, _, _, spellID, _, _, auraType = ...;

	if sub ~= "SPELL_AURA_APPLIED" and sub ~= "SPELL_AURA_REFRESH"
		and sub ~= "SPELL_AURA_REMOVED" then return; end
	if auraType ~= "DEBUFF" then return; end

	local cat = idToCat[spellID];
	if not cat then return; end

	local idx = IdxFromGUID(dstGUID);
	if not idx then return; end

	local now = GetTime();
	state[idx] = state[idx] or {};
	local rec = FindRec(idx, cat);

	if sub == "SPELL_AURA_REMOVED" then
		if not rec then return; end
		rec.active = max(0, rec.active - 1);
		if rec.active == 0 then
			rec.expire = now + DR_RESET;
		end
	else

		if not rec then
			rec = { cat = cat, n = 1, active = 0 };
			tinsert(state[idx], rec);
		elseif rec.expire and now >= rec.expire then
			rec.n = 1;
		elseif rec.n >= 3 then


			rec.n = 1;
		else
			rec.n = rec.n + 1;
		end

		if sub == "SPELL_AURA_APPLIED" or rec.active == 0 then
			rec.active = rec.active + 1;
		end
		rec.expire = nil;
		rec.lastApplied = now;
		rec.icon = IconForCategory(cat, spellID);
		driver:Show();
	end

	Refresh(idx);
end


local ev = CreateFrame("Frame");




local function MigrateClassOnly()
	if not C.ArenaDRClassOnly or not K.SaveConfigSilent then return; end
	local own, hide = OwnCats(), {};
	for _, cat in ipairs(CAT_ORDER) do
		if not own[cat] then hide[#hide + 1] = cat; end
	end
	if K.SaveConfigSilent("ArenaDRHideCats", table.concat(hide, ",")) then
		K.SaveConfigSilent("ArenaDRClassOnly", false);
	end
end

local function ApplyState()
	MigrateClassOnly();
	local want = C.ArenaDR and true or false;
	local listen = want and InArena();
	if listen ~= listening then
		listening = listen;
		if listen then
			ev:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			ev:RegisterEvent("ARENA_OPPONENT_UPDATE");
			RefreshGUIDs();
		else
			ev:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			ev:UnregisterEvent("ARENA_OPPONENT_UPDATE");
		end
	end
	if want ~= enabled then
		enabled = want;
		if not enabled then
			previewOn = false;
			driver:Hide();
			WipeAll();
			return;
		end
	end

	SetPreview(IsTestMode() and not InArena());
	RefreshAll();
end

ev:RegisterEvent("PLAYER_ENTERING_WORLD");
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA");
ev:SetScript("OnEvent", function(self, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		return OnCLEU(...);
	elseif event == "ARENA_OPPONENT_UPDATE" then
		RefreshGUIDs();
	elseif event == "PLAYER_ENTERING_WORLD" then

		for g in pairs(guidToIdx) do guidToIdx[g] = nil; end
		for i = 1, MAX_ARENA do state[i] = nil; end
		previewOn = false;
		ApplyState();
	else
		ApplyState();
	end
end);



if type(K.SetTrinketMouseState) == "function" then
	hooksecurefunc(K, "SetTrinketMouseState", function(on)
		SetPreview(on and IsTestMode() and not InArena());
	end);
end


function K.ToggleArenaDR()
	ApplyState();
end


function K.RefreshArenaDRLayout()
	RefreshAll();
end

function K.IsArenaDRPreviewOn()
	return previewOn;
end



function K.ToggleArenaDRPreview()
	if not C.ArenaDR or not C.ArenaFrameOn or InArena() then return false; end
	if InCombatLockdown and InCombatLockdown() then return false; end
	if IsTestMode() then
		if previewOn then
			if K.ToggleArenaFramesMover then K.ToggleArenaFramesMover(); end
		else
			SetPreview(true);
		end
	elseif K.ToggleArenaFramesMover then
		K.ToggleArenaFramesMover();
	end
	return true;
end




function K.GetArenaDRCategories()
	local own, list = OwnCats(), {};
	for pass = 1, 2 do
		for _, cat in ipairs(CAT_ORDER) do
			local mine = own[cat] ~= nil;
			if (pass == 1) == mine then
				list[#list + 1] = {
					key = cat, mine = mine,
					icon = IconForCategory(cat, CATEGORIES[cat][1]),
				};
			end
		end
	end
	return list;
end



function K.GetArenaDRCategorySpells(cat)
	local seen, out = {}, {};
	for _, id in ipairs(CATEGORIES[cat] or {}) do
		local name = GetSpellInfo(id);
		if name and not seen[name] then
			seen[name] = true;
			out[#out + 1] = name;
		end
	end
	return out;
end

function K.IsArenaDRCategoryShown(cat)
	return CatShown(cat);
end



local function SaveHidden(set)
	local out = {};
	for _, cat in ipairs(CAT_ORDER) do
		if set[cat] then out[#out + 1] = cat; end
	end
	if K.SaveConfig then K.SaveConfig("ArenaDRHideCats", table.concat(out, ",")); end

	if C.ArenaDRClassOnly and K.SaveConfig then K.SaveConfig("ArenaDRClassOnly", false); end
	if previewOn then FillPreview(); end
	RefreshAll();
end

function K.SetArenaDRCategoryShown(cat, on)
	if not CATEGORIES[cat] then return; end
	local set = {};
	for _, c in ipairs(CAT_ORDER) do set[c] = not CatShown(c); end
	set[cat] = not on;
	SaveHidden(set);
end


function K.SetArenaDRCategoryPreset(which)
	local own, set = OwnCats(), {};
	for _, c in ipairs(CAT_ORDER) do
		if which == "none" then
			set[c] = true;
		elseif which == "class" then
			set[c] = (own[c] == nil);
		else
			set[c] = false;
		end
	end
	SaveHidden(set);
end



function K.ResetArenaDRPosition()
	if NidhausUnitFramesDB then NidhausUnitFramesDB.ArenaDRPositions = nil; end
	RefreshAll();
end


SLASH_NUFDR1 = "/nufdr";
SlashCmdList["NUFDR"] = function(msg)
	if msg == "clear" then
		if previewOn and IsTestMode() and K.ToggleArenaFramesMover then
			K.ToggleArenaFramesMover();
		end
		SetPreview(false);
		return;
	end
	if not C.ArenaDR then
		print("|cffFFD100NUF DR|r: " .. (L["DR_NEED_ENABLE"] or "turn it on in Arena > DR."));
		return;
	end
	if not C.ArenaFrameOn then
		print("|cffFFD100NUF DR|r: " .. (L["DR_PREVIEW_NEEDS_ARENA"] or "the preview needs the arena frames mod (Arena > Frames)."));
		return;
	end
	if not previewOn then K.ToggleArenaDRPreview(); end
end
