-- =========================================================
-- ArenaDR  ·  Diminishing Returns junto a cada marco de arena enemigo.
--
-- Un icono por categoria de DR activa en ese enemigo. El icono es un
-- hechizo de TU clase de esa categoria (Paladin: Arrepentimiento,
-- Mago: Polimorfia, Cazador: Trampa congelante...). Si tu clase no tiene
-- hechizo en esa categoria, se usa el icono del CC que le cayo.
--
-- Texto del icono:  1/2 = el proximo CC de esa categoria dura la mitad
--                   1/4 = el proximo dura un cuarto
--                   X   = inmune
-- El reloj girando es lo que falta para que el DR se resetee (arranca
-- cuando el CC se va).
--
-- Datos:
--  * Categorias por spellID (el ID del AURA que cae en el enemigo), sacadas
--    de DRTracker (DRData.lua) y completadas con DRData-1.0 de
--    DiminishingReturns. Por ID y no por nombre: Psychic Horror pone dos
--    auras con el mismo nombre (horror + desarme) y Wyvern Sting deja un
--    DoT que tambien se llama Wyvern Sting; por nombre contaban doble.
--  * Iconos por clase: los mismos de DRTracker.
--
-- Eventos: APPLIED y REFRESH suben un escalon (re-castear un CC sobre
-- alguien que todavia lo tiene es una aplicacion nueva con DR). REMOVED
-- arranca el reloj. UNIT_DIED no se usa: Fingir Muerte lo dispara.
-- Solo escucha el combat log dentro de una arena.
--
-- OPCIONES (pestaña Arena > DR):
--   C.ArenaDR           prendido / apagado
--   C.ArenaDRSize       tamaño de cada icono
--   C.ArenaDRSpacing    separacion entre iconos
--   C.ArenaDRGrow       hacia donde crece la fila: AUTO / LEFT / RIGHT / UP / DOWN
--   C.ArenaDRBorder     borde del color del nivel (si no, borde negro fino)
--   C.ArenaDRText       texto 1/2 · 1/4 · X
--   C.ArenaDRHideCats   categorias que NO se muestran, separadas por coma
--                       ("" = todas). Las casillas de la pestaña la arman.
--   C.ArenaDRClassOnly  VIEJO: "solo mi clase". Se pasa a ArenaDRHideCats
--                       la primera vez (ahora es el boton "Mi clase").
--
-- Una categoria oculta se sigue CONTANDO: si la volves a tildar en plena
-- arena aparece con el escalon real, no desde cero.
--
-- POSICION. Sin posicion guardada va encima de la cast bar, del lado
-- donde este (no la pisa, y el trinket va del otro lado). Con el modo Test
-- de arena prendido aparece la vista previa: Shift+Alt+arrastrar mueve la
-- fila (la de los cinco marcos a la vez). Se guarda por estilo + espejo,
-- igual que el trinket y la cast bar (NidhausUnitFramesDB.ArenaDRPositions).
--
-- Prueba:  /nufdr        (vista previa: prende el modo Test de arena)
--          /nufdr clear  (la apaga)
-- =========================================================
local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local GetTime, UnitGUID, UnitExists, GetSpellInfo, IsInInstance =
	GetTime, UnitGUID, UnitExists, GetSpellInfo, IsInInstance;
local CooldownFrame_SetTimer = CooldownFrame_SetTimer;
local ipairs, pairs, tinsert, tremove, select, max, min, floor =
	ipairs, pairs, table.insert, table.remove, select, math.max, math.min, math.floor;

local MAX_ARENA = MAX_ARENA_ENEMIES or 5;

-- ---------- Fijos ----------
local DR_RESET  = 18;   -- s hasta el reset (DRData usa 20, DRTracker 17)
local MAX_ICONS = 6;    -- iconos maximos por enemigo
local LIFT_Y    = 5;    -- separacion por encima de la cast bar (posicion auto)
local DEF_SIZE  = 22;
local DEF_GAP   = 2;

-- ---------- Categorias (spellID del aura -> categoria) ----------
local CATEGORIES = {
	ctrlstun = {
		20253,                                  -- Intercept
		408, 8643,                              -- Kidney Shot
		853, 5588, 5589, 10308,                 -- Hammer of Justice
		44572,                                  -- Deep Freeze
		30283, 30413, 30414, 47846, 47847,      -- Shadowfury
		12809,                                  -- Concussion Blow
		46968,                                  -- Shockwave
		5211, 6798, 8983,                       -- Bash
		22570, 49802,                           -- Maim
		47481,                                  -- Gnaw (ghoul)
		20549,                                  -- War Stomp
		2812, 10318, 27139, 48816, 48817,       -- Holy Wrath
		58861,                                  -- Bash (pet)
		50518, 53558, 53559, 53560, 53561, 53562, -- Ravage (pet)
		50519, 53564, 53565, 53566, 53567, 53568, -- Sonic Blast (pet)
		60995,                                  -- Demon Charge
		30153, 30195, 30197, 47995,             -- Intercept (felguard)
		22703,                                  -- Inferno
	},
	openstun = {                                -- aperturas: DR propio
		1833,                                   -- Cheap Shot
		9005, 9823, 9827, 27006, 49803,         -- Pounce
	},
	rndstun = {
		12355,                                  -- Impact
		39796,                                  -- Stoneclaw Stun
		20170,                                  -- Seal of Justice
		12798,                                  -- Revenge Stun
	},
	disorient = {                               -- Poly, Sap, Repentance...
		6770, 2070, 11297, 51724,               -- Sap
		1776,                                   -- Gouge
		118, 12824, 12825, 12826, 28271, 28272, 61025, 61305, 61721, 61780, -- Polymorph
		20066,                                  -- Repentance
		49203,                                  -- Hungering Cold
		3355, 14308, 14309,                     -- Freezing Trap
		60210,                                  -- Freezing Arrow
		19386, 24132, 24133, 27068, 49011, 49012, -- Wyvern Sting (el sueño, no el DoT)
		51514,                                  -- Hex
		31661, 33041, 33042, 33043, 42949, 42950, -- Dragon's Breath
		9484, 9485, 10955,                      -- Shackle Undead
	},
	fear = {
		2094,                                   -- Blind
		5782, 6213, 6215,                       -- Fear
		5484, 17928,                            -- Howl of Terror
		5246, 20511,                            -- Intimidating Shout
		8122, 8124, 10888, 10890,               -- Psychic Scream
		6358,                                   -- Seduction
		1513, 14326, 14327,                     -- Scare Beast
		10326,                                  -- Turn Evil
	},
	horror = {
		64044,                                  -- Psychic Horror (horror)
		6789, 17925, 17926, 27223, 47859, 47860, -- Death Coil
	},
	silence = {
		47476, 49913, 49914, 49915, 49916,      -- Strangulate
		34490,                                  -- Silencing Shot
		18469, 55021,                           -- Improved Counterspell
		15487,                                  -- Silence
		1330,                                   -- Garrote - Silence
		24259,                                  -- Spell Lock
		18498,                                  -- Gag Order
		25046, 28730, 50613,                    -- Arcane Torrent
		31117,                                  -- Unstable Affliction (al dispelear)
		63529,                                  -- Shield of the Templar
		18425,                                  -- Improved Kick
		53588, 53589,                           -- Nether Shock (pet)
	},
	cyclone = { 33786 },
	ctrlroot = {
		33395,                                  -- Freeze (elemental de agua)
		122, 865, 6131, 10230, 27088, 42917,    -- Frost Nova
		339, 1062, 5195, 5196, 9852, 9853, 26989, 53308, -- Entangling Roots
		19970, 19971, 19972, 19973, 19974, 19975, 27010, 53313, -- Nature's Grasp
		50245, 53544, 53545, 53546, 53547, 53548, -- Pin (pet)
		4167,                                   -- Web (pet)
		54706, 55505, 55506, 55507, 55508, 55509, -- Venom Web Spray (pet)
		64695, 8377, 31983,                     -- Earthgrab
	},
	rndroot = {
		23694,                                  -- Improved Hamstring
		12494,                                  -- Frostbite
		55080,                                  -- Shattered Barrier
	},
	sleep = { 2637, 18657, 18658 },             -- Hibernate
	disarm = {
		51722,                                  -- Dismantle
		64058,                                  -- Psychic Horror (desarme)
		676,                                    -- Disarm
		53359,                                  -- Chimera Shot - Scorpid
		50541, 53537, 53538, 53540, 53542, 53543, -- Snatch (pet)
	},
	entrapment   = { 19185, 64803, 64804 },
	scatter      = { 19503 },                   -- Scatter Shot
	mc           = { 605 },                     -- Mind Control
	banish       = { 710, 18647 },
	charge       = { 7922 },                    -- Charge Stun
	intimidation = { 24394 },                   -- Intimidation (pet)
};

local idToCat = {};
for cat, ids in pairs(CATEGORIES) do
	for _, id in ipairs(ids) do idToCat[id] = cat; end
end

-- ---------- Icono de TU clase por categoria (los de DRTracker) ----------
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

-- ---------- Estado ----------
-- state[idx] = lista de { cat, n, active, expire, icon, lastApplied, preview }
local state = {};
local holders = {};      -- holders[idx] = fila (contenedor) de ese marco
local guidToIdx = {};
local enabled = false;   -- opcion prendida
local listening = false; -- escuchando el combat log (prendida + en arena)
local previewOn = false; -- vista previa (modo Test de arena)

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

-- ---------- Opciones ----------
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

-- ---------- Filtro por categoria ----------
-- Orden en que se listan (en el panel van primero las de tu clase).
local CAT_ORDER = {
	"ctrlstun", "openstun", "rndstun", "disorient", "fear", "horror",
	"silence", "cyclone", "ctrlroot", "rndroot", "sleep", "disarm",
	"entrapment", "scatter", "mc", "banish", "charge", "intimidation",
};

local function OwnCats()
	playerClass = playerClass or select(2, UnitClass("player"));
	return CLASS_ICONS[playerClass] or {};
end

-- La opcion es un texto ("scatter,silence") porque la config de NUF solo
-- guarda numeros, textos y booleanos. Se parsea una vez por cambio.
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
	-- Por si la migracion de "solo mi clase" no se pudo guardar: sigue
	-- filtrando como antes en vez de mostrar todo de golpe.
	if C.ArenaDRClassOnly and not OwnCats()[cat] then return false; end
	return true;
end

-- Se muestra este registro? Vale tambien para la vista previa: asi se ve
-- en el momento que hace cada casilla.
local function Visible(rec)
	return CatShown(rec.cat);
end

-- ---------- Posicion guardada (por estilo + espejo) ----------
local function PosKey()
	if K.GetArenaPositionKey then return K.GetArenaPositionKey(); end
	return C.ArenaMirrorMode and "mirror" or "normal";
end

-- { x, y, dir }: dir es hacia donde crecia la fila al soltarla. Con la
-- direccion en Auto se respeta esa: antes se recalculaba segun de que lado
-- del centro del marco habia quedado, y al soltar un poco del otro lado
-- la fila se daba vuelta (parecia que "se imantaba" a cualquier lado).
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

-- ---------- Iconos ----------
local LEVEL_COLOR = {
	{ 1.00, 0.90, 0.10 },   -- 1/2
	{ 1.00, 0.45, 0.00 },   -- 1/4
	{ 1.00, 0.10, 0.10 },   -- inmune
};
local LEVEL_TEXT = { "1/2", "1/4", "X" };

local RefreshAll;   -- se define abajo (el arrastre la usa)

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
	-- OJO: "af and af:GetCenter()" se queda solo con el primer valor.
	local ax, ay;
	if af then ax, ay = af:GetCenter(); end
	if hx and hy and ax and ay then
		-- A pixeles de pantalla para restar y de vuelta al espacio de la
		-- fila, que es donde SetPoint interpreta el offset (la misma cuenta
		-- que Party Targets). Hoy fila y marco tienen la misma escala, pero
		-- asi no depende de eso.
		local hs = h:GetEffectiveScale() or 1;
		local as = af:GetEffectiveScale() or 1;
		if hs == 0 then hs = 1; end
		local x = floor(((hx * hs - ax * as) / hs) * 10 + 0.5) / 10;
		local y = floor(((hy * hs - ay * as) / hs) * 10 + 0.5) / 10;
		SavePos(x, y, h._lastDir);
	end
	RefreshAll();   -- reubica las cinco filas con la posicion nueva
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
	-- MEDIUM, como el trinket: en el modo Test el contenedor de los marcos
	-- de arena toma el mouse; si la fila queda encima de el (por ejemplo al
	-- moverla entre dos marcos), en LOW no se podia agarrar.
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

	-- El texto va en un frame aparte, por encima del reloj.
	local tf = CreateFrame("Frame", nil, f);
	tf:SetAllPoints(f);
	tf:SetFrameLevel(f.cd:GetFrameLevel() + 2);
	f.txt = tf:CreateFontString(nil, "OVERLAY");
	f.txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE");   -- sin fuente, SetText falla
	f.txt:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 1);

	-- EL TIEMPO LO ESCRIBE ESTE MODULO, NO OMNICC.
	--
	-- Los segundos los ponia OmniCC sobre el reloj, y OmniCC esconde el
	-- numero cuando el reloj le queda chico: calcula 18 x ancho / 36 y si da
	-- menos de 9 (por la escala de los marcos de arena) no lo dibuja. Con el
	-- borde de color el reloj mide 4 px menos que el icono, asi que en el
	-- tamaño por defecto (22) quedaba justo en el limite y desaparecia.
	-- Arriba del icono; el 1/2 · 1/4 · X sigue abajo a la derecha.
	f.time = tf:CreateFontString(nil, "OVERLAY");
	f.time:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE");
	f.time:SetPoint("TOP", f, "TOP", 0, -1);
	f.time:Hide();
	f.cd.noCooldownCount = true;   -- que OmniCC no ponga un segundo numero

	-- Arrastrar desde cualquier icono mueve la fila entera.
	f:EnableMouse(false);
	f:SetScript("OnMouseDown", function(_, b) if b == "LeftButton" then StartDrag(h); end end);
	f:SetScript("OnMouseUp", function(_, b) if b == "LeftButton" then StopDrag(h); end end);
	f:SetScript("OnEnter", ShowMoveTip);
	f:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	f:Hide();
	return f;
end

-- Borde: de color del nivel (2 px) o negro fino (1 px).
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

-- Segundos que faltan para el reset (redondeado para arriba, como un
-- reloj: "1" hasta que llega a cero). Solo cambia el texto cuando cambia
-- el numero. Sin tiempo (el CC todavia activo) o con la opcion apagada,
-- no se muestra.
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

-- De que lado del marco esta la cast bar (si se puede medir); si no, el
-- lado que le toca segun el modo espejo (espejo = cast bar a la derecha).
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
				-- Apoyada sobre la cast bar, desde su borde pegado al marco.
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
					CooldownFrame_SetTimer(w.cd, 0, 0, 0);   -- CC todavia activo
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

-- ---------- Vista previa ----------
-- Muestra las categorias TILDADAS: primero las de tu clase, despues el
-- resto, hasta 4. Si solo dejaste la trampa, la vista previa es un icono
-- de trampa por marco; si destildaste todo, no aparece nada.
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

local driver;   -- se define abajo

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

-- ---------- Reloj: vence los DR y suelta lo que quedo colgado ----------
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
					-- La vista previa da vueltas sola mientras este abierta.
					if now >= rec.expire then
						rec.expire = now + DR_RESET;
						changed = true;
					end
				else
					-- Seguro: si nunca llego el "aura removed" (enemigo fuera de
					-- rango del log), se suelta a los 70 s.
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
				-- Solo los segundos (Refresh ya los pone cuando hay cambios).
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

-- ---------- Combat log ----------
-- 3.3.5a: timestamp, evento, srcGUID, srcName, srcFlags, dstGUID, dstName,
-- dstFlags, spellID, spellName, school, auraType
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
			rec.expire = now + DR_RESET;   -- arranca el reloj del DR
		end
	else
		-- APPLIED o REFRESH: un escalon mas.
		if not rec then
			rec = { cat = cat, n = 1, active = 0 };
			tinsert(state[idx], rec);
		elseif rec.expire and now >= rec.expire then
			rec.n = 1;                       -- el DR ya se habia reseteado
		elseif rec.n >= 3 then
			-- Le entro un CC estando "inmune": la cuenta venia mal (se
			-- perdio un reset). Se vuelve a empezar.
			rec.n = 1;
		else
			rec.n = rec.n + 1;
		end
		-- REFRESH no agrega un aura nueva (la misma se renueva).
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

-- ---------- Activar / desactivar ----------
local ev = CreateFrame("Frame");

-- "Solo las de mi clase" era una casilla; ahora es el boton "Mi clase" de
-- la lista. Quien la tenia tildada la primera vez queda con las mismas
-- categorias tildadas, y desde ahi las puede tocar de a una.
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
	-- Si el modo Test ya estaba abierto al prender la opcion: vista previa.
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
		-- Zona nueva: GUIDs y DRs de la ronda anterior no valen.
		for g in pairs(guidToIdx) do guidToIdx[g] = nil; end
		for i = 1, MAX_ARENA do state[i] = nil; end
		previewOn = false;
		ApplyState();
	else
		ApplyState();
	end
end);

-- El modo Test de arena prende y apaga el mouse de los trinkets al abrirse
-- y al cerrarse (ArenaMover). Es el mismo momento para la vista previa.
if type(K.SetTrinketMouseState) == "function" then
	hooksecurefunc(K, "SetTrinketMouseState", function(on)
		SetPreview(on and IsTestMode() and not InArena());
	end);
end

-- ---------- API para el panel ----------
function K.ToggleArenaDR()
	ApplyState();
end

-- Mirror, tamaño, separacion, direccion, borde, texto, filtro: redibujar.
function K.RefreshArenaDRLayout()
	RefreshAll();
end

function K.IsArenaDRPreviewOn()
	return previewOn;
end

-- Boton "Vista previa": abre o cierra el modo Test de arena; el gancho de
-- arriba prende o apaga la vista previa. Devuelve false si no se puede.
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

-- ---------- Categorias: API para la lista de casillas del panel ----------

-- { key, mine, icon } en el orden del panel: las de tu clase primero.
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

-- Nombres (en el idioma del cliente) de los hechizos que comparten ese DR,
-- sin repetir rangos. Para el tooltip de cada casilla.
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

-- Guarda el set de ocultas (en el orden fijo, para que el texto no cambie
-- solo) y redibuja. Con la vista previa abierta se rearma con lo tildado.
local function SaveHidden(set)
	local out = {};
	for _, cat in ipairs(CAT_ORDER) do
		if set[cat] then out[#out + 1] = cat; end
	end
	if K.SaveConfig then K.SaveConfig("ArenaDRHideCats", table.concat(out, ",")); end
	-- Cualquier cambio a mano deja atras el filtro viejo.
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

-- "all" = todas · "class" = solo las de tu clase · "none" = ninguna
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

-- Vuelve la fila a su lugar automatico (encima de la cast bar), en todos
-- los estilos.
function K.ResetArenaDRPosition()
	if NidhausUnitFramesDB then NidhausUnitFramesDB.ArenaDRPositions = nil; end
	RefreshAll();
end

-- ---------- Prueba por chat ----------
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
