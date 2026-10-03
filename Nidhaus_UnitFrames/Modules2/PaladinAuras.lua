local AddOnName, ns = ...;
local K, C, L = unpack(ns);






















local ART_OF_WAR_SPELL = 59578;


local SELF_BUFF = "Holy Strength";











local HEAL_DEBUFF_IDS = {
	12294,
	19434,
	13218,
};


local HEAL_DEBUFF_FALLBACK = {
	"Mortal Strike", "Aimed Shot", "Wound Poison",
};

local HEAL_DEBUFFS;

local function BuildHealDebuffNames()
	if HEAL_DEBUFFS then return HEAL_DEBUFFS; end
	HEAL_DEBUFFS = {};
	for _, id in ipairs(HEAL_DEBUFF_IDS) do
		local nm = GetSpellInfo(id);
		if nm then HEAL_DEBUFFS[nm] = true; end
	end
	for _, nm in ipairs(HEAL_DEBUFF_FALLBACK) do
		HEAL_DEBUFFS[nm] = true;
	end
	return HEAL_DEBUFFS;
end

local UNITS = { "player", "party1", "party2", "party3", "party4" };

local enabled  = false;
local previewOn = false;




local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.PaladinAuras then
		NidhausUnitFramesDB.PaladinAuras = { x = -60, y = 38, scale = 0.95 };
	end
	return NidhausUnitFramesDB.PaladinAuras;
end




local anchor = CreateFrame("Frame", "NUF_PaladinAuras", UIParent);
anchor:SetWidth(200);
anchor:SetHeight(120);
anchor:SetMovable(true);
anchor:SetClampedToScreen(true);
anchor:EnableMouse(false);
anchor:Hide();

if K.RegisterScalable then K.RegisterScalable("PaladinAuras", anchor, 0.95); end








local function RestorePosition()
	local db = DB();
	anchor:ClearAllPoints();
	anchor:SetPoint(db.point or "CENTER", UIParent,
		db.relativePoint or "CENTER", db.x or -60, db.y or 38);
	anchor:SetScale(db.scale or 0.95);
end

local function SavePosition()
	local db = DB();
	local point, _, relativePoint, x, y = anchor:GetPoint();
	db.point, db.relativePoint = point, relativePoint;
	db.x, db.y = x or -60, y or 38;
end

anchor:SetScript("OnMouseDown", function(self, btn)
	if btn == "LeftButton" and previewOn then self:StartMoving(); end
end);
anchor:SetScript("OnMouseUp", function(self, btn)
	if btn == "LeftButton" and previewOn then
		self:StopMovingOrSizing();
		SavePosition();
	end
end);




local function MakeIcon(name, size, x, y, parent)
	parent = parent or anchor;
	local f = CreateFrame("Frame", "NUF_PalAura_" .. name, parent);
	f:SetWidth(size);
	f:SetHeight(size);

	if parent == anchor then
		f:SetPoint("CENTER", parent, "CENTER", x + 134, y + 98);
	else
		f:SetPoint("TOP", parent, "TOP", x, y);
	end

	f.tex = f:CreateTexture(nil, "ARTWORK");
	f.tex:SetAllPoints(f);

	f.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93);

	f.border = f:CreateTexture(nil, "BACKGROUND");
	f.border:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2);
	f.border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2);
	f.border:SetTexture(0, 0, 0, 0.9);

	f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate");
	f.cd:SetAllPoints(f);









	f.cd:SetReverse(true);




	f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	f.label:SetPoint("BOTTOM", f, "BOTTOM", 0, -12);
	f.label:SetText("");

	f:Hide();
	return f;
end

local icoHoly = MakeIcon("HolyStrength", 50,  -73, -128);
local icoHeal = MakeIcon("HealDebuff",   55, -134,  -69);
local icoWar  = MakeIcon("ArtOfWar",     55, -134, -128);













local TURN_EVIL     = GetSpellInfo(10326) or "Turn Evil";



local TE_UNITS = { "arenapet1", "arenapet2", "arenapet3", "arenapet4", "arenapet5" };





local TURN_EVIL_ID  = 10326;














local TE_DURATION     = 20;
local TE_DURATION_PVP = 10;
local TE_ICON       = select(3, GetSpellInfo(TURN_EVIL_ID))
                      or "Interface\\Icons\\Spell_Holy_TurnUndead";

local band = bit and bit.band;
local CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER or 0x00000100;

local function TurnEvilDuration(dstFlags)
	if band and dstFlags and band(dstFlags, CONTROL_PLAYER) > 0 then
		return TE_DURATION_PVP;
	end
	return TE_DURATION;
end

local teLog = {};









local TURN_EVIL_MAX = 1;
local TE_SIZE, TE_SPACE = 64, 2;

local teAnchor = CreateFrame("Frame", "NUF_TurnEvilStack", UIParent);
teAnchor:SetWidth(TE_SIZE);
teAnchor:SetHeight(TURN_EVIL_MAX * (TE_SIZE + TE_SPACE));
teAnchor:SetMovable(true);
teAnchor:SetClampedToScreen(true);
teAnchor:EnableMouse(false);
teAnchor:Hide();

if K.RegisterScalable then K.RegisterScalable("TurnEvil", teAnchor, 1.2); end

local function TeDB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.TurnEvil then
		NidhausUnitFramesDB.TurnEvil = { x = 99, y = 201, scale = 1.2 };
	end
	return NidhausUnitFramesDB.TurnEvil;
end

local function TeRestore()
	local db = TeDB();
	teAnchor:ClearAllPoints();
	teAnchor:SetPoint(db.point or "TOP", UIParent,
		db.relativePoint or "CENTER", db.x or 99, db.y or 201);
	teAnchor:SetScale(db.scale or 1.2);
end

local function TeSave()
	local db = TeDB();
	local point, _, relativePoint, x, y = teAnchor:GetPoint();
	db.point, db.relativePoint = point, relativePoint;
	db.x, db.y = x or 99, y or 201;
end

local teEnabled, tePreview = false, false;

teAnchor:SetScript("OnMouseDown", function(self, btn)
	if btn == "LeftButton" and tePreview then self:StartMoving(); end
end);
teAnchor:SetScript("OnMouseUp", function(self, btn)
	if btn == "LeftButton" and tePreview then
		self:StopMovingOrSizing();
		TeSave();
	end
end);
















local GLOW_PATH = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\Glow\\";
local GLOW_R, GLOW_G, GLOW_B = 0.15, 1.0, 0.25;


local GLOW_L, GLOW_RI, GLOW_T, GLOW_B2 = 0.00781250, 0.50781250, 0.27734375, 0.52734375;


local ANTS_SHEET, ANTS_CELL, ANTS_FRAMES = 256, 48, 22;
local ANTS_PER_ROW = math.floor(ANTS_SHEET / ANTS_CELL);



local ANTS_STEP    = 0.05;



local ANTS_GROW    = 0.14;



local GLOW_ALPHA_MIN   = 0.22;
local GLOW_ALPHA_RANGE = 0.26;

local GLOW_PULSE       = 2.2;


local function AntsFrame(tex, index)
	local col = index % ANTS_PER_ROW;
	local row = math.floor(index / ANTS_PER_ROW);
	local l = (col * ANTS_CELL) / ANTS_SHEET;
	local t = (row * ANTS_CELL) / ANTS_SHEET;
	local d = ANTS_CELL / ANTS_SHEET;
	tex:SetTexCoord(l, l + d, t, t + d);
end

local function AttachGlow(icon)
	if icon.glow then return icon.glow; end



	local g = CreateFrame("Frame", nil, icon);
	g:SetAllPoints(icon);
	g:SetFrameLevel(icon:GetFrameLevel() + 4);
	g:Hide();


	g.ring = g:CreateTexture(nil, "ARTWORK");
	g.ring:SetTexture(GLOW_PATH .. "IconAlert");
	g.ring:SetTexCoord(GLOW_L, GLOW_RI, GLOW_T, GLOW_B2);
	g.ring:SetBlendMode("ADD");
	g.ring:SetVertexColor(GLOW_R, GLOW_G, GLOW_B);


	g.ants = g:CreateTexture(nil, "OVERLAY");
	g.ants:SetTexture(GLOW_PATH .. "IconAlertAnts");
	do
		local pad = icon:GetWidth() * ANTS_GROW;
		g.ants:SetPoint("TOPLEFT",     icon, "TOPLEFT",     -pad,  pad);
		g.ants:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT",  pad, -pad);
	end
	g.ants:SetBlendMode("ADD");
	g.ants:SetVertexColor(GLOW_R, GLOW_G, GLOW_B);
	AntsFrame(g.ants, 0);

	g.t, g.antT, g.antI = 0, 0, 0;
	g:SetScript("OnUpdate", function(self, elapsed)

		self.antT = self.antT + elapsed;
		while self.antT >= ANTS_STEP do
			self.antT = self.antT - ANTS_STEP;
			self.antI = (self.antI + 1) % ANTS_FRAMES;
			AntsFrame(self.ants, self.antI);
		end


		self.t = self.t + elapsed;
		local wave = math.sin((self.t % GLOW_PULSE) / GLOW_PULSE * math.pi * 2) * 0.5 + 0.5;
		local grow = icon:GetWidth() * (0.35 + wave * 0.15);
		self.ring:ClearAllPoints();
		self.ring:SetPoint("TOPLEFT", icon, "TOPLEFT", -grow, grow);
		self.ring:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", grow, -grow);
		self.ring:SetAlpha(GLOW_ALPHA_MIN + wave * GLOW_ALPHA_RANGE);
	end);

	icon.glow = g;
	return g;
end

local function SetGlow(icon, on)
	if on then
		AttachGlow(icon);
		icon.glow.t, icon.glow.antT, icon.glow.antI = 0, 0, 0;
		icon.glow:Show();
	elseif icon.glow then
		icon.glow:Hide();
	end
end





local BORDER_DIM = 0.55;

local teIcons = {};
for i = 1, TURN_EVIL_MAX do
	local f = MakeIcon("TurnEvil" .. i, TE_SIZE, 0,
		-((i - 1) * (TE_SIZE + TE_SPACE)), teAnchor);
	f.border:SetTexture(GLOW_R * BORDER_DIM, GLOW_G * BORDER_DIM,
		GLOW_B * BORDER_DIM, 0.95);
	teIcons[i] = f;
end





local function FindSelfBuff()
	for i = 1, 40 do
		local nm, _, icon, _, _, duration, expires = UnitAura("player", i, "HELPFUL");
		if not nm then break; end
		if nm == SELF_BUFF then return icon, expires, duration; end
	end
end



local function FindArtOfWar()
	local wanted = GetSpellInfo(ART_OF_WAR_SPELL);
	for i = 1, 40 do
		local nm, _, icon, _, _, duration, expires, _, _, _, spellId =
			UnitAura("player", i, "HELPFUL");
		if not nm then break; end
		if (wanted and nm == wanted) or spellId == ART_OF_WAR_SPELL then
			return icon, expires, duration;
		end
	end
end



local function FindHealDebuff()
	local names = BuildHealDebuffNames();
	local woundBase = GetSpellInfo(13218);
	for _, unit in ipairs(UNITS) do
		if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
			for i = 1, 40 do
				local nm, _, icon, _, _, duration, expires = UnitAura(unit, i, "HARMFUL");
				if not nm then break; end


				if names[nm]
					or (woundBase and string.sub(nm, 1, string.len(woundBase)) == woundBase) then
					return icon, expires, duration, (UnitName(unit) or unit);
				end
			end
		end
	end
end




local function Refresh()
	if not enabled then return; end


	local icon, expires, duration = FindSelfBuff();
	if icon then
		icoHoly.tex:SetTexture(icon);
		if duration and duration > 0 then
			icoHoly.cd:SetCooldown(expires - duration, duration);
		else
			icoHoly.cd:SetCooldown(0, 0);
		end
		icoHoly:Show();
	elseif not previewOn then
		icoHoly:Hide();
	end


	local dIcon, dExp, dDur, who = FindHealDebuff();
	if dIcon then
		icoHeal.tex:SetTexture(dIcon);
		if dDur and dDur > 0 then
			icoHeal.cd:SetCooldown(dExp - dDur, dDur);
		else
			icoHeal.cd:SetCooldown(0, 0);
		end
		icoHeal.label:SetText(who or "");
		icoHeal:Show();
	elseif not previewOn then
		icoHeal:Hide();
	end











	local wIcon, wExp, wDur = FindArtOfWar();
	if wIcon then
		icoWar.tex:SetTexture(wIcon);
		if wDur and wDur > 0 then
			icoWar.cd:SetCooldown(wExp - wDur, wDur);
		else
			icoWar.cd:SetCooldown(0, 0);
		end
		icoWar:Show();
	elseif not previewOn then
		icoWar:Hide();
	end
end


local function RefreshTurnEvil()
	if not teEnabled then return; end
	local n = 0;
	local vistos = {};
	for _, unit in ipairs(TE_UNITS) do
		if n >= TURN_EVIL_MAX then break; end
		if UnitExists(unit) then
			vistos[UnitGUID(unit)] = true;
			for i = 1, 40 do
				local nm, _, icon, _, _, duration, expires = UnitAura(unit, i, "HARMFUL");
				if not nm then break; end
				if nm == TURN_EVIL then
					n = n + 1;
					local f = teIcons[n];
					f.tex:SetTexture(icon);
					if duration and duration > 0 then
						f.cd:SetCooldown(expires - duration, duration);
					else
						f.cd:SetCooldown(0, 0);
					end
					f.label:SetText(UnitName(unit) or unit);
					SetGlow(f, true);
					f:Show();
					break;
				end
			end
		end
	end

	local ahora = GetTime();
	for guid, info in pairs(teLog) do
		if info.expires <= ahora then
			teLog[guid] = nil;
		elseif not vistos[guid] and n < TURN_EVIL_MAX then
			n = n + 1;
			local f = teIcons[n];
			f.tex:SetTexture(TE_ICON);
			local dur = info.dur or TE_DURATION;
			f.cd:SetCooldown(info.expires - dur, dur);
			f.label:SetText(info.name or "");
			SetGlow(f, true);
			f:Show();
		end
	end

	if not tePreview then
		for i = n + 1, TURN_EVIL_MAX do
			SetGlow(teIcons[i], false);
			teIcons[i]:Hide();
		end
		if n == 0 then teAnchor:Hide(); else teAnchor:Show(); end
	end
end

function K.SetTurnEvilPreview(state)
	tePreview = state and true or false;
	teAnchor:EnableMouse(tePreview);

	if tePreview then
		TeRestore();
	else
		TeSave();
	end
	if tePreview then
		teAnchor:Show();
		local qm = "Interface\\Icons\\Spell_Holy_TurnUndead";
		for i = 1, TURN_EVIL_MAX do
			local f = teIcons[i];
			if not f.tex:GetTexture() then f.tex:SetTexture(qm); end
			f.label:SetText("");


			SetGlow(f, true);
			f:Show();
		end
	else
		RefreshTurnEvil();
		if not teEnabled then teAnchor:Hide(); end
	end
	return tePreview;
end

function K.IsTurnEvilPreview() return tePreview; end

function K.ResetTurnEvilPosition()
	local db = TeDB();
	db.point, db.relativePoint = "TOP", "CENTER";
	db.x, db.y, db.scale = 99, 201, 1.2;
	TeRestore();
end




local acc = 0;
local ticker = CreateFrame("Frame");
ticker:Hide();
ticker:SetScript("OnUpdate", function(self, elapsed)

	acc = acc + elapsed;
	if acc < 0.1 then return; end
	acc = 0;
	Refresh();
	RefreshTurnEvil();
end);

local events = CreateFrame("Frame");
events:SetScript("OnEvent", function(self, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then


		local _, sub, _, _, _, dstGUID, dstName, dstFlags, spellId, spellName = ...;
		if spellId == TURN_EVIL_ID or spellName == TURN_EVIL then
			if sub == "SPELL_AURA_APPLIED" or sub == "SPELL_AURA_REFRESH" then


				local dur = TurnEvilDuration(dstFlags);
				teLog[dstGUID] = {
					name = dstName, dur = dur, expires = GetTime() + dur,
				};
			elseif sub == "SPELL_AURA_REMOVED" or sub == "SPELL_AURA_BROKEN"
				or sub == "SPELL_AURA_BROKEN_SPELL" then
				teLog[dstGUID] = nil;
			end
		end


		return;
	end
	Refresh();
	RefreshTurnEvil();
end);




function K.SetPaladinAurasPreview(state)
	previewOn = state and true or false;
	anchor:EnableMouse(previewOn);







	if previewOn then
		RestorePosition();
	else
		SavePosition();
	end
	if previewOn then
		anchor:Show();
		local qm = "Interface\\Icons\\INV_Misc_QuestionMark";



		local _, _, warIcon = GetSpellInfo(ART_OF_WAR_SPELL);
		if warIcon then icoWar.tex:SetTexture(warIcon); end
		icoHoly.tex:SetTexture("Interface\\Icons\\INV_Sword_04");
		icoHeal.tex:SetTexture("Interface\\Icons\\Ability_Warrior_SavageBlow");
		for _, f in ipairs({ icoHoly, icoHeal, icoWar }) do
			if not f.tex:GetTexture() then f.tex:SetTexture(qm); end
			f:SetAlpha(1);
			f:Show();
		end
		anchor:SetAlpha(1);
		icoHeal.label:SetText(UnitName("player") or "");
		icoHoly.label:SetText("");
		icoWar.label:SetText("");
	else
		Refresh();
		if not enabled then anchor:Hide(); end
	end
	return previewOn;
end

function K.IsPaladinAurasPreview() return previewOn; end

function K.ResetPaladinAurasPosition()
	local db = DB();
	db.point, db.relativePoint = "CENTER", "CENTER";
	db.x, db.y, db.scale = -60, 38, 0.95;
	RestorePosition();
end

SLASH_NUFPALAURAS1 = "/nufpal";
SlashCmdList["NUFPALAURAS"] = function(msg)
	msg = string.lower(msg or "");




	if msg == "debug" then
		local p = function(t) DEFAULT_CHAT_FRAME:AddMessage("|cff4FC3F7NUFpal:|r " .. t); end
		p("modulo PaladinAuras activo: " .. tostring(enabled));
		p("modulo TurnEvil activo: " .. tostring(teEnabled));
		p("preview: " .. tostring(previewOn));
		local pt, _, rp, x, y = anchor:GetPoint();
		p(string.format("ancla: point=%s rel=%s x=%.0f y=%.0f visible=%s alpha=%.1f scale=%.2f",
			tostring(pt), tostring(rp), x or 0, y or 0,
			tostring(anchor:IsShown()), anchor:GetAlpha(), anchor:GetScale()));
		p("iconos mostrados: Holy=" .. tostring(icoHoly:IsShown())
			.. " Heal=" .. tostring(icoHeal:IsShown())
			.. " War=" .. tostring(icoWar:IsShown()));

		local nm, _, ic = GetSpellInfo(ART_OF_WAR_SPELL);
		p("hechizo " .. ART_OF_WAR_SPELL .. ": " .. tostring(nm)
			.. " icono=" .. tostring(ic));
		local st, du, en = GetSpellCooldown(ART_OF_WAR_SPELL);
		p("GetSpellCooldown -> start=" .. tostring(st)
			.. " dur=" .. tostring(du) .. " enabled=" .. tostring(en));

		local bIcon = FindSelfBuff();
		p("buff '" .. SELF_BUFF .. "' encontrado: " .. tostring(bIcon ~= nil));
		p("proc The Art of War activo: " .. tostring(FindArtOfWar() ~= nil));
		local _, _, _, who = FindHealDebuff();
		p("debuff de curacion en el grupo: " .. tostring(who or "no"));
		return;
	end

	local on = K.SetPaladinAurasPreview(not previewOn);
	K.SetTurnEvilPreview(on);
	print("|cff4FC3F7NUF:|r " .. (on
		and "Paladin tracker + Turn Evil: arrastra cada grupo. /nufpal para fijar. /nufpal debug para diagnostico."
		or  "Paladin tracker: posicion fijada."));
end






RestorePosition();
TeRestore();

K.RegisterModule("TurnEvil", {
	name    = L["MOD_TURN_EVIL"] or "Turn Evil tracker",
	desc    = L["MOD_TURN_EVIL_DESC"]
		or "Shows which enemy arena pet is under Turn Evil.",
	default = false,

	onEnable = function()
		teEnabled = true;
		TeRestore();
		events:RegisterEvent("UNIT_AURA");
		events:RegisterEvent("PARTY_MEMBERS_CHANGED");
		events:RegisterEvent("PLAYER_ENTERING_WORLD");

		events:RegisterEvent("ARENA_OPPONENT_UPDATE");

		events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		ticker:Show();
		RefreshTurnEvil();
	end,

	onDisable = function()
		teEnabled = false;
		for i = 1, TURN_EVIL_MAX do
			SetGlow(teIcons[i], false);
			teIcons[i]:Hide();
		end
		if not tePreview then teAnchor:Hide(); end
		if not enabled then
			events:UnregisterAllEvents();
			ticker:Hide();
		end
	end,
});

K.RegisterModule("PaladinAuras", {
	name    = L["MOD_PALADIN_AURAS"] or "Paladin tracker",
	desc    = L["MOD_PALADIN_AURAS_DESC"]
		or "Holy Strength proc, healing reduction on any party member, and The Art of War cooldown.",
	default = false,

	onEnable = function()
		enabled = true;
		RestorePosition();
		anchor:Show();
		events:RegisterEvent("UNIT_AURA");
		events:RegisterEvent("SPELL_UPDATE_COOLDOWN");
		events:RegisterEvent("PARTY_MEMBERS_CHANGED");
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
		ticker:Show();
		Refresh();
	end,

	onDisable = function()
		enabled = false;
		icoHoly:Hide(); icoHeal:Hide(); icoWar:Hide();
		if not previewOn then anchor:Hide(); end


		if not teEnabled then
			events:UnregisterAllEvents();
			ticker:Hide();
		end
	end,
});
