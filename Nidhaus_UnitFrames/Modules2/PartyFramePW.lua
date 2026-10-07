local AddOnName, ns = ...;
local K, C, L = unpack(ns);






























local MAX_PARTY = MAX_PARTY_MEMBERS or 4;

local PW_DIR   = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\pw\\";













local function PWTex()
	if K.GetPartyFrameStyle and K.GetPartyFrameStyle() == "PW2" then






		return PW_DIR .. "UI-TargetingFrame";
	end
	return PW_DIR .. "UI-PartyFrame";
end

local function PWFlash()
	if K.GetPartyFrameStyle and K.GetPartyFrameStyle() == "PW2" then
		return PW_DIR .. "UI-PartyFrame2-Flash";
	end
	return PW_DIR .. "UI-PARTYFRAME-FLASH";
end











local PW_COLOR = { 1, 1, 1, 1 };






local function TintFrame(tex)
	if not tex then return; end
	if not (K.ApplyLortiTint and K.ApplyLortiTint(tex, "LortiUI_Party")) then
		tex:SetVertexColor(unpack(PW_COLOR));
	end
end

local LAYOUT = {
	health    = { x = 46, y = -13, h = 12 },
	mana      = { x = 46, y = -25 },
	healthTxt = { x = 18, y =  9 },
	manaTxt   = { x = 18, y = -1 },
};
































local PW2 = {
	crop = { 1.0, 0.09375, 0, 0.78125 },









	blockX = -17,
	tex  = { w = 121, h = 52, x = 0, y = 0 },

	bars = { w = 61,  x = 57, hy = -13, my = -27, hh = 14, mh = 6 },


	portrait = { size = 30, x = 25, y = -8 },














	bg = { x = -5, y = -2, w = 61, h = 21, alpha = 94 },
};












local AURA_DROP = -2;




local AURA_DROP_PW2 = -63;
















local function ArenaTextFont()
	return C.ArenaFrameFont or { "Fonts\\FRIZQT__.TTF", 7, "OUTLINE" };
end

local function AuraDrop()
	if K.GetPartyFrameStyle and K.GetPartyFrameStyle() == "PW2" then
		return AURA_DROP_PW2;
	end
	return AURA_DROP;
end

local orig = {};
local applied = false;




local function SnapPoint(region)
	if not region then return nil; end
	local point, relTo, relPoint, x, y = region:GetPoint(1);
	if not point then return nil; end
	return {
		point = point, relTo = relTo, relPoint = relPoint,
		x = x or 0, y = y or 0,
		h = region:GetHeight(),
	};
end

local function RestorePoint(region, s)
	if not region or not s then return; end
	region:ClearAllPoints();
	region:SetPoint(s.point, s.relTo, s.relPoint, s.x, s.y);
	if s.h and s.h > 0 and region.SetHeight then region:SetHeight(s.h); end
end




local function FindFrameBG(f, fn)
	if f.nufBGRegion then return f.nufBGRegion; end

	local byName = _G[fn .. "Background"];
	if byName then f.nufBGRegion = byName; return byName; end

	for _, r in ipairs({ f:GetRegions() }) do
		if r.GetTexture and r.GetObjectType and r:GetObjectType() == "Texture" then
			local tx = r:GetTexture();
			if type(tx) == "string" and string.find(string.lower(tx), "background") then
				f.nufBGRegion = r;
				return r;
			end
		end
	end
	return nil;
end

local function Capture(i)
	local fn = "PartyMemberFrame" .. i;
	if orig[fn] then return; end

	local hp  = _G[fn .. "HealthBar"];
	local mp  = _G[fn .. "ManaBar"];
	local tex = _G[fn .. "Texture"];
	local fl  = _G[fn .. "Flash"];

	orig[fn] = {
		health    = SnapPoint(hp),
		mana      = SnapPoint(mp),
		healthTxt = hp and SnapPoint(hp.TextString) or nil,
		manaTxt   = mp and SnapPoint(mp.TextString) or nil,

		healthFont = (hp and hp.TextString) and { hp.TextString:GetFont() } or nil,
		manaFont   = (mp and mp.TextString) and { mp.TextString:GetFont() } or nil,


		name      = SnapPoint(_G[fn .. "Name"]),
		texPath   = tex and tex:GetTexture() or nil,


		texSize   = tex and { tex:GetWidth(), tex:GetHeight() } or nil,
		texPoint  = SnapPoint(tex),
		hpW       = hp and hp:GetWidth() or nil,
		hpTex     = (hp and hp.GetStatusBarTexture and hp:GetStatusBarTexture()
		             and hp:GetStatusBarTexture():GetTexture()) or nil,
		mpTex     = (mp and mp.GetStatusBarTexture and mp:GetStatusBarTexture()
		             and mp:GetStatusBarTexture():GetTexture()) or nil,
		portPoint = SnapPoint(_G[fn .. "Portrait"]),
		portSize  = _G[fn .. "Portrait"] and { _G[fn .. "Portrait"]:GetWidth(), _G[fn .. "Portrait"]:GetHeight() } or nil,
		mpW       = mp and mp:GetWidth() or nil,
		flashPath = fl and fl:GetTexture() or nil,
		buff1     = SnapPoint(_G[fn .. "Buff1"]),
		debuff1   = SnapPoint(_G[fn .. "Debuff1"]),
	};
end








local function DropAura(fn, suffix, s)
	if not s then return; end
	local r = _G[fn .. suffix];
	if not r then return; end
	if s.relTo ~= _G[fn] then return; end

	r:ClearAllPoints();
	r:SetPoint(s.point, s.relTo, s.relPoint, s.x, s.y + AuraDrop());
end




























local function InPartyVehicle(i)
	local f = _G["PartyMemberFrame" .. i];



	if f and f.state == "vehicle" then return true; end
	if UnitInVehicle and UnitInVehicle("party" .. i) then return true; end
	return false;
end



local StyleOne, RestoreOne;




function StyleOne(i)
	local fn = "PartyMemberFrame" .. i;
	local f  = _G[fn];
	if not f then return; end

	if InPartyVehicle(i) then








		if orig[fn] then RestoreOne(i); end
		return;
	end

	Capture(i);

	local tex = _G[fn .. "Texture"];
	if tex then
		tex:SetTexture(PWTex());
		TintFrame(tex);











		local isPW2 = (K.GetPartyFrameStyle and K.GetPartyFrameStyle() == "PW2");
		if isPW2 then

			tex:SetTexCoord(unpack(PW2.crop));
			tex:ClearAllPoints();
			tex:SetPoint("TOPLEFT", f, "TOPLEFT", PW2.tex.x + PW2.blockX, PW2.tex.y);
			tex:SetSize(PW2.tex.w, PW2.tex.h);
		else
			tex:SetTexCoord(0, 1, 0, 1);
		end
	end

	local fl = _G[fn .. "Flash"];
	if fl then fl:SetTexture(PWFlash()); end




	local petTex = _G[fn .. "PetFrameTexture"];
	TintFrame(petTex);

	local isPW2b = (K.GetPartyFrameStyle and K.GetPartyFrameStyle() == "PW2");

	local hp = _G[fn .. "HealthBar"];
	if hp then
		hp:ClearAllPoints();
		if isPW2b then
			hp:SetPoint("TOPLEFT", f, "TOPLEFT", PW2.bars.x + PW2.blockX, PW2.bars.hy);
			hp:SetWidth(PW2.bars.w);
			hp:SetHeight(PW2.bars.hh);
		else
			hp:SetPoint("TOPLEFT", f, "TOPLEFT", LAYOUT.health.x, LAYOUT.health.y);
		end
		if not isPW2b then hp:SetHeight(LAYOUT.health.h); end
		if hp.TextString then
			hp.TextString:ClearAllPoints();
			if isPW2b then
				hp.TextString:SetPoint("CENTER", hp);
				hp.TextString:SetFont(unpack(ArenaTextFont()));
			else
				hp.TextString:SetPoint("CENTER", f, "CENTER",
					LAYOUT.healthTxt.x, LAYOUT.healthTxt.y);
			end
		end
	end







	if isPW2b and C.statusbarOn and C.statusbarTexture then
		if hp then hp:SetStatusBarTexture(C.statusbarTexture); end
		local mpBar = _G[fn .. "ManaBar"];
		if mpBar then mpBar:SetStatusBarTexture(C.statusbarTexture); end
	end










	local nameFS = _G[fn .. "Name"];
	if nameFS and hp then
		nameFS:ClearAllPoints();


		nameFS:SetPoint("BOTTOM", hp, "TOP", 0, 2);
	end










	local bg = FindFrameBG(f, fn);
	if bg and isPW2b then
		if not bg.nufBase then
			bg.nufBase = {
				point = { bg:GetPoint(1) },
				w = bg:GetWidth(), h = bg:GetHeight(),
				alpha = bg:GetAlpha(),
			};
		end
		local b = bg.nufBase;
		if b.point[1] then
			bg:ClearAllPoints();
			bg:SetPoint(b.point[1], b.point[2], b.point[3],
				(b.point[4] or 0) + PW2.bg.x, (b.point[5] or 0) + PW2.bg.y);
		end
		if PW2.bg.w > 0 then bg:SetWidth(PW2.bg.w); elseif b.w then bg:SetWidth(b.w); end
		if PW2.bg.h > 0 then bg:SetHeight(PW2.bg.h); elseif b.h then bg:SetHeight(b.h); end
		bg:SetAlpha(PW2.bg.alpha / 100);
	elseif bg and bg.nufBase then
		local b = bg.nufBase;
		if b.point[1] then
			bg:ClearAllPoints();
			bg:SetPoint(unpack(b.point));
		end
		if b.w then bg:SetWidth(b.w); end
		if b.h then bg:SetHeight(b.h); end
		bg:SetAlpha(b.alpha or 1);
	end


	local port = _G[fn .. "Portrait"];
	if port and isPW2b then
		port:ClearAllPoints();
		port:SetPoint("TOPLEFT", f, "TOPLEFT", PW2.portrait.x + PW2.blockX, PW2.portrait.y);
		port:SetSize(PW2.portrait.size, PW2.portrait.size);
	end

	local mp = _G[fn .. "ManaBar"];
	if mp then
		mp:ClearAllPoints();
		if isPW2b then
			mp:SetPoint("TOPLEFT", f, "TOPLEFT", PW2.bars.x + PW2.blockX, PW2.bars.my);
			mp:SetWidth(PW2.bars.w);
			mp:SetHeight(PW2.bars.mh);
		else
			mp:SetPoint("TOPLEFT", f, "TOPLEFT", LAYOUT.mana.x, LAYOUT.mana.y);
		end
		if mp.TextString then
			mp.TextString:ClearAllPoints();
			if isPW2b then
				mp.TextString:SetPoint("CENTER", mp);
				mp.TextString:SetFont(unpack(ArenaTextFont()));
			else
				mp.TextString:SetPoint("CENTER", f, "CENTER",
					LAYOUT.manaTxt.x, LAYOUT.manaTxt.y);
			end
		end
	end








	local pbBuffs, pbDebuffs;
	if K.PartyBuffsOwnsBuffs then
		pbBuffs, pbDebuffs = K.PartyBuffsOwnsBuffs(), K.PartyBuffsOwnsDebuffs();
	else
		pbBuffs = K.IsPartyBuffsActive and K.IsPartyBuffsActive();
		pbDebuffs = pbBuffs;
	end
	if not pbBuffs then DropAura(fn, "Buff1", orig[fn].buff1); end
	if not pbDebuffs then DropAura(fn, "Debuff1", orig[fn].debuff1); end
end

function RestoreOne(i)
	local fn = "PartyMemberFrame" .. i;
	local s  = orig[fn];
	if not s then return; end

	local tex = _G[fn .. "Texture"];
	if tex then
		if s.texPath then tex:SetTexture(s.texPath); end


		tex:SetTexCoord(0, 1, 0, 1);
		if s.texSize then tex:SetSize(s.texSize[1], s.texSize[2]); end
		RestorePoint(tex, s.texPoint);



		tex:SetVertexColor(1, 1, 1);
	end

	local fl = _G[fn .. "Flash"];
	if fl and s.flashPath then fl:SetTexture(s.flashPath); end

	local petTex = _G[fn .. "PetFrameTexture"];
	if petTex then petTex:SetVertexColor(1, 1, 1); end

	local hp = _G[fn .. "HealthBar"];
	RestorePoint(hp, s.health);
	if hp and s.hpW then hp:SetWidth(s.hpW); end
	if hp and s.hpTex then hp:SetStatusBarTexture(s.hpTex); end







	local pf = _G[fn];
	local bgR = pf and FindFrameBG(pf, fn);
	if bgR and bgR.nufBase then
		local b = bgR.nufBase;
		if b.point[1] then
			bgR:ClearAllPoints();
			bgR:SetPoint(unpack(b.point));
		end
		if b.w then bgR:SetWidth(b.w); end
		if b.h then bgR:SetHeight(b.h); end
		bgR:SetAlpha(b.alpha or 1);
	end

	local port = _G[fn .. "Portrait"];
	RestorePoint(port, s.portPoint);
	if port and s.portSize then port:SetSize(s.portSize[1], s.portSize[2]); end
	if hp then RestorePoint(hp.TextString, s.healthTxt); end
	if hp and hp.TextString and s.healthFont and s.healthFont[1] then
		hp.TextString:SetFont(unpack(s.healthFont));
	end


	RestorePoint(_G[fn .. "Name"], s.name);

	local mp = _G[fn .. "ManaBar"];
	RestorePoint(mp, s.mana);
	if mp and s.mpW then mp:SetWidth(s.mpW); end
	if mp and s.mpTex then mp:SetStatusBarTexture(s.mpTex); end
	if mp then RestorePoint(mp.TextString, s.manaTxt); end
	if mp and mp.TextString and s.manaFont and s.manaFont[1] then
		mp.TextString:SetFont(unpack(s.manaFont));
	end


	RestorePoint(_G[fn .. "Buff1"], s.buff1);
	RestorePoint(_G[fn .. "Debuff1"], s.debuff1);
end




function K.EnablePartyFramePW()
	applied = true;
	for i = 1, MAX_PARTY do StyleOne(i); end
end

function K.DisablePartyFramePW()
	if not applied then return; end
	applied = false;
	for i = 1, MAX_PARTY do RestoreOne(i); end
end

function K.IsPartyFramePWActive()
	return applied;
end









local function Reapply()
	if not applied then return; end
	if InCombatLockdown() then return; end
	for i = 1, MAX_PARTY do StyleOne(i); end
end




































local pwVehiclePending = false;
local pwVehState       = {};

local function VehicleStateChanged()
	local changed = false;
	for i = 1, MAX_PARTY do
		local now = InPartyVehicle(i) and true or false;
		if pwVehState[i] ~= now then
			pwVehState[i] = now;
			changed = true;
		end
	end
	return changed;
end

local function ReapplyVehicle(force)
	if not applied then return; end
	local changed = VehicleStateChanged();
	if not changed and not force then return; end
	for i = 1, MAX_PARTY do StyleOne(i); end
	if InCombatLockdown() then pwVehiclePending = true; end
end




























local function PinName(i)
	if not applied then return; end
	local fn = "PartyMemberFrame" .. i;
	local f  = _G[fn];
	if not f or not f:IsShown() then return; end


	if InPartyVehicle(i) then return; end

	local nameFS = _G[fn .. "Name"];
	local hp     = _G[fn .. "HealthBar"];
	if not nameFS or not hp then return; end










	local point, rel, relPoint, _, y = nameFS:GetPoint(1);
	if (nameFS:GetNumPoints() or 0) == 1 and point == "BOTTOM" and rel == hp
		and relPoint == "TOP" and y == 2 then
		return;
	end

	nameFS:ClearAllPoints();
	nameFS:SetPoint("BOTTOM", hp, "TOP", 0, 2);
end

local function PinNames()
	for i = 1, MAX_PARTY do PinName(i); end
end

if type(PartyMemberFrame_UpdateMember) == "function" then
	hooksecurefunc("PartyMemberFrame_UpdateMember", function()
		Reapply();

		PinNames();
	end);
end
if type(PartyMemberFrame_ToPlayerArt) == "function" then



	hooksecurefunc("PartyMemberFrame_ToPlayerArt", function()
		ReapplyVehicle();
		PinNames();
	end);
end

























if type(PartyMemberFrame_ToVehicleArt) == "function" then



	hooksecurefunc("PartyMemberFrame_ToVehicleArt", function() ReapplyVehicle(); end);
end










local pwVehicle = CreateFrame("Frame");
pwVehicle:RegisterEvent("UNIT_ENTERED_VEHICLE");
pwVehicle:RegisterEvent("UNIT_EXITED_VEHICLE");
pwVehicle:RegisterEvent("PLAYER_ENTERING_WORLD");
pwVehicle:RegisterEvent("PLAYER_REGEN_ENABLED");
pwVehicle:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_REGEN_ENABLED" then
		if not pwVehiclePending then return; end
		pwVehiclePending = false;
		Reapply();
		return;
	end
	if event == "PLAYER_ENTERING_WORLD" then


		ReapplyVehicle(true);
		return;
	end

	if type(unit) ~= "string" or string.sub(unit, 1, 5) ~= "party" then return; end
	ReapplyVehicle();
end);















local PW2_DEFAULTS = {
	tex  = { PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y },
	bars = { PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my, PW2.bars.hh, PW2.bars.mh },
	aura = AURA_DROP_PW2,
	portrait = { PW2.portrait.size, PW2.portrait.x, PW2.portrait.y },
	bg = { PW2.bg.x, PW2.bg.y, PW2.bg.w, PW2.bg.h, PW2.bg.alpha },
	blockX = PW2.blockX,
};

local function PW2DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB.PW2 = NidhausUnitFramesDB.PW2 or {};
	return NidhausUnitFramesDB.PW2;
end

local function PW2Load()
	local db = PW2DB();
	if db.tex then
		PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y = unpack(db.tex);
	end
	if db.bars then
		local w, x, hy, my, hh, mh = unpack(db.bars);
		PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my = w, x, hy, my;

		PW2.bars.hh = hh or PW2.bars.hh;
		PW2.bars.mh = mh or PW2.bars.mh;
	end
	if db.aura then AURA_DROP_PW2 = db.aura; end



	if db.blockX then PW2.blockX = db.blockX; end
	if db.bg and #db.bg >= 5 then
		local bx, by, bw, bh, ba = unpack(db.bg);
		PW2.bg.x, PW2.bg.y = bx or 0, by or 0;
		PW2.bg.w, PW2.bg.h = bw or 0, bh or 0;
		PW2.bg.alpha = ba or 100;
	end
	if db.portrait then
		PW2.portrait.size, PW2.portrait.x, PW2.portrait.y = unpack(db.portrait);
	end
end

local function PW2Apply()
	if not applied then return; end
	for i = 1, MAX_PARTY do StyleOne(i); end
end

local function PW2Print()
	print("|cff4FC3F7NUF Compact 2|r");
	print(string.format("  tex  %d %d %d %d", PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y));
	print(string.format("  bars %d %d %d %d", PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my));
	print(string.format("  aura %d", AURA_DROP_PW2));
	print(string.format("  portrait %d %d %d",
		PW2.portrait.size, PW2.portrait.x, PW2.portrait.y));
end

SLASH_NUFPW21 = "/nufpw2";
SlashCmdList["NUFPW2"] = function(msg)
	local args = {};
	for w in tostring(msg or ""):gmatch("%S+") do args[#args + 1] = w; end
	local cmd = string.lower(args[1] or "");

	if cmd == "" then



		if K.TogglePW2Panel then K.TogglePW2Panel(); end
		return;
	end

	if cmd == "reset" then
		local db = PW2DB();
		db.tex, db.bars, db.aura, db.portrait, db.bg, db.blockX = nil, nil, nil, nil, nil, nil;
		PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y = unpack(PW2_DEFAULTS.tex);
		PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my, PW2.bars.hh, PW2.bars.mh = unpack(PW2_DEFAULTS.bars);
		AURA_DROP_PW2 = PW2_DEFAULTS.aura;
		PW2.portrait.size, PW2.portrait.x, PW2.portrait.y = unpack(PW2_DEFAULTS.portrait);
		PW2.bg.x, PW2.bg.y, PW2.bg.w, PW2.bg.h, PW2.bg.alpha = unpack(PW2_DEFAULTS.bg);
		PW2.blockX = PW2_DEFAULTS.blockX;
		PW2Apply(); PW2Print();
		return;
	end

	if cmd == "tex" and args[5] then
		local w, h, x, y = tonumber(args[2]), tonumber(args[3]), tonumber(args[4]), tonumber(args[5]);
		if w and h and x and y then
			PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y = w, h, x, y;
			PW2DB().tex = { w, h, x, y };
			PW2Apply(); PW2Print();
		end
		return;
	end

	if cmd == "bars" and args[5] then
		local w, x, hy, my = tonumber(args[2]), tonumber(args[3]), tonumber(args[4]), tonumber(args[5]);
		if w and x and hy and my then
			PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my = w, x, hy, my;
			PW2DB().bars = { w, x, hy, my };
			PW2Apply(); PW2Print();
		end
		return;
	end

	if cmd == "portrait" and args[4] then
		local s, x, y = tonumber(args[2]), tonumber(args[3]), tonumber(args[4]);
		if s and x and y then
			PW2.portrait.size, PW2.portrait.x, PW2.portrait.y = s, x, y;
			PW2DB().portrait = { s, x, y };
			PW2Apply(); PW2Print();
		end
		return;
	end

	if cmd == "aura" and args[2] then
		local v = tonumber(args[2]);
		if v then
			AURA_DROP_PW2 = v;
			PW2DB().aura = v;
			PW2Apply(); PW2Print();
		end
		return;
	end

	print("|cff4FC3F7NUF:|r /nufpw2 tex <w h x y> | bars <w x hy my> | portrait <lado x y> | aura <n> | reset");
end


local pw2Init = CreateFrame("Frame");
pw2Init:RegisterEvent("PLAYER_LOGIN");
pw2Init:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");
	PW2Load();
	PW2Apply();
end);









local panel;

local ROWS = {
	{ label = "TODO  X",       get = function() return PW2.blockX end,
	  set = function(v) PW2.blockX = v end, key = "block" },

	{ label = "Marco  ancho",  get = function() return PW2.tex.w end,
	  set = function(v) PW2.tex.w = v end, key = "tex" },
	{ label = "Marco  alto",   get = function() return PW2.tex.h end,
	  set = function(v) PW2.tex.h = v end, key = "tex" },
	{ label = "Marco  X",      get = function() return PW2.tex.x end,
	  set = function(v) PW2.tex.x = v end, key = "tex" },
	{ label = "Marco  Y",      get = function() return PW2.tex.y end,
	  set = function(v) PW2.tex.y = v end, key = "tex" },

	{ label = "Barras  ancho", get = function() return PW2.bars.w end,
	  set = function(v) PW2.bars.w = v end, key = "bars" },
	{ label = "Barras  X",     get = function() return PW2.bars.x end,
	  set = function(v) PW2.bars.x = v end, key = "bars" },
	{ label = "Vida  Y",       get = function() return PW2.bars.hy end,
	  set = function(v) PW2.bars.hy = v end, key = "bars" },
	{ label = "Mana  Y",       get = function() return PW2.bars.my end,
	  set = function(v) PW2.bars.my = v end, key = "bars" },

	{ label = "Vida  alto",    get = function() return PW2.bars.hh end,
	  set = function(v) PW2.bars.hh = v end, key = "bars" },
	{ label = "Mana  alto",    get = function() return PW2.bars.mh end,
	  set = function(v) PW2.bars.mh = v end, key = "bars" },

	{ label = "Retrato  lado", get = function() return PW2.portrait.size end,
	  set = function(v) PW2.portrait.size = v end, key = "portrait" },
	{ label = "Retrato  X",    get = function() return PW2.portrait.x end,
	  set = function(v) PW2.portrait.x = v end, key = "portrait" },
	{ label = "Retrato  Y",    get = function() return PW2.portrait.y end,
	  set = function(v) PW2.portrait.y = v end, key = "portrait" },

	{ label = "Fondo  ancho",  get = function() return PW2.bg.w end,
	  set = function(v) PW2.bg.w = math.max(0, v) end, key = "bg" },
	{ label = "Fondo  alto",   get = function() return PW2.bg.h end,
	  set = function(v) PW2.bg.h = math.max(0, v) end, key = "bg" },
	{ label = "Fondo  opacidad", get = function() return PW2.bg.alpha end,
	  set = function(v) PW2.bg.alpha = math.max(0, math.min(100, v)) end, key = "bg" },

	{ label = "Fondo  X",      get = function() return PW2.bg.x end,
	  set = function(v) PW2.bg.x = v end, key = "bg" },
	{ label = "Fondo  Y",      get = function() return PW2.bg.y end,
	  set = function(v) PW2.bg.y = v end, key = "bg" },

	{ label = "Auras  Y",      get = function() return AURA_DROP_PW2 end,
	  set = function(v) AURA_DROP_PW2 = v end, key = "aura" },
};


local function PW2Save(key)
	local db = PW2DB();
	if key == "tex" then
		db.tex = { PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y };
	elseif key == "bars" then
		db.bars = { PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my, PW2.bars.hh, PW2.bars.mh };
	elseif key == "portrait" then
		db.portrait = { PW2.portrait.size, PW2.portrait.x, PW2.portrait.y };
	elseif key == "block" then
		db.blockX = PW2.blockX;
	elseif key == "bg" then
		db.bg = { PW2.bg.x, PW2.bg.y, PW2.bg.w, PW2.bg.h, PW2.bg.alpha };
	elseif key == "aura" then
		db.aura = AURA_DROP_PW2;
	end
end

local function BuildPanel()
	if panel then return panel; end

	panel = CreateFrame("Frame", "NUF_PW2Panel", UIParent);
	panel:SetSize(320, 40 + (#ROWS * 24) + 44);
	panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	panel:SetFrameStrata("DIALOG");
	panel:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 24,
		insets = { left = 6, right = 6, top = 6, bottom = 6 },
	});
	panel:EnableMouse(true);
	panel:SetMovable(true);
	panel:RegisterForDrag("LeftButton");
	panel:SetScript("OnDragStart", panel.StartMoving);
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing);

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	title:SetPoint("TOP", panel, "TOP", 0, -14);
	title:SetText("Compact 2  -  ajuste de marcos");

	local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton");
	close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4);

	local y = -38;
	for _, row in ipairs(ROWS) do
		local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		fs:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, y - 4);
		fs:SetText(row.label);

		local val = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		val:SetPoint("TOPLEFT", panel, "TOPLEFT", 132, y - 4);
		val:SetWidth(34);
		val:SetJustifyH("CENTER");
		row.valFS = val;

		local function Step(delta)
			row.set(row.get() + delta);
			PW2Save(row.key);
			PW2Apply();
			val:SetText(tostring(row.get()));
		end

		local xs = { { -5, "-5", 172 }, { -1, "-", 208 }, { 1, "+", 240 }, { 5, "+5", 272 } };
		for _, b in ipairs(xs) do
			local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate");
			btn:SetSize((b[2] == "-" or b[2] == "+") and 28 or 32, 20);
			btn:SetPoint("TOPLEFT", panel, "TOPLEFT", b[3], y);
			btn:SetText(b[2]);
			btn:SetScript("OnClick", function() Step(b[1]); end);
		end

		val:SetText(tostring(row.get()));
		y = y - 24;
	end

	local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate");
	reset:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 14);
	reset:SetSize(120, 22);
	reset:SetText("Valores de fabrica");
	reset:SetScript("OnClick", function()
		local db = PW2DB();
		db.tex, db.bars, db.aura, db.portrait, db.bg, db.blockX = nil, nil, nil, nil, nil, nil;
		PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y = unpack(PW2_DEFAULTS.tex);
		PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my, PW2.bars.hh, PW2.bars.mh = unpack(PW2_DEFAULTS.bars);
		PW2.portrait.size, PW2.portrait.x, PW2.portrait.y = unpack(PW2_DEFAULTS.portrait);
		PW2.bg.x, PW2.bg.y, PW2.bg.w, PW2.bg.h, PW2.bg.alpha = unpack(PW2_DEFAULTS.bg);
		PW2.blockX = PW2_DEFAULTS.blockX;
		AURA_DROP_PW2 = PW2_DEFAULTS.aura;
		PW2Apply();
		for _, r in ipairs(ROWS) do r.valFS:SetText(tostring(r.get())); end
	end);

	local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
	hint:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 20);
	hint:SetText("se aplica al instante");

	return panel;
end

function K.TogglePW2Panel()
	BuildPanel();
	if panel:IsShown() then
		panel:Hide();
	else
		for _, r in ipairs(ROWS) do r.valFS:SetText(tostring(r.get())); end
		panel:Show();
	end
end
