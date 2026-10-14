local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- CATEGORIAS DE CC  (que CC comparte DR con cual)
--
-- Vivia adentro de Modules2/ArenaDR.lua, pero los modulos de arena ahora
-- se cargan solo cuando hacen falta (ver Core/ArenaLoader.lua) y esta
-- tabla NO es solo de arena: el marco de las mascotas del grupo la usa
-- para poner el CC en el retrato, en cualquier lado.
--
-- Son 5 KB que se quedan en el addon principal; los otros 400 del paquete
-- de arena ya no se leen en cada login.
--
-- La usan:
--   K.GetCCCategory(spellID) -> "ctrlstun", "fear", ... o nil
--   K.CCCategories           -> la tabla entera (la recorre ArenaDR)
-- =========================================================
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

K.CCCategories = CATEGORIES;

local idToCat = {};
for cat, ids in pairs(CATEGORIES) do
	for _, id in ipairs(ids) do idToCat[id] = cat; end
end

function K.GetCCCategory(spellID)
	return spellID and idToCat[spellID] or nil;
end
