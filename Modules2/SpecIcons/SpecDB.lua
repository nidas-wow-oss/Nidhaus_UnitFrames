local AddOnName, ns = ...;

-- SpecDB.lua - Spec detection database for SpecIcons module
-- Stores class→spec→icon mappings and class→spec→spellIDs

ns.SpecMetaDB = {
	DEATHKNIGHT = {
		blood = "spell_deathknight_bloodpresence",
		frost = "spell_deathknight_frostpresence",
		unholy = "spell_deathknight_unholypresence",
	},
	DRUID = {
		balance = "spell_nature_starfall",
		feral = "ability_racial_bearform",
		restoration = "spell_nature_healingtouch",
	},
	HUNTER = {
		beastmastery = "ability_hunter_beasttaming",
		marksmanship = "ability_marksmanship",
		survival = "ability_hunter_swiftstrike",
	},
	MAGE = {
		arcane = "spell_holy_magicalsentry",
		fire = "spell_fire_firebolt02",
		frost = "spell_frost_frostbolt02",
	},
	PALADIN = {
		holy = "spell_holy_holybolt",
		protection = "spell_holy_devotionaura",
		retribution = "spell_holy_auraoflight",
	},
	PRIEST = {
		discipline = "spell_holy_wordfortitude",
		holy = "spell_holy_holybolt",
		shadow = "spell_shadow_shadowwordpain",
	},
	ROGUE = {
		assassination = "ability_rogue_eviscerate",
		combat = "ability_backstab",
		subtlety = "ability_stealth",
	},
	SHAMAN = {
		elemental = "spell_nature_lightning",
		enhancement = "spell_nature_lightningshield",
		restoration = "spell_nature_magicimmunity",
	},
	WARLOCK = {
		affliction = "spell_shadow_deathcoil",
		demonology = "spell_shadow_metamorphosis",
		destruction = "spell_shadow_rainoffire",
	},
	WARRIOR = {
		arms = "ability_rogue_eviscerate",
		fury = "ability_warrior_innerrage",
		protection = "ability_warrior_defensivestance",
	},
};

ns.SpecSpellDB = {
	DEATHKNIGHT = {
		blood = {
			55262, 55261, 55260, 55259, 55258, 55050, -- Heart Strike
			55233, -- Vampiric Blood
			49016, -- Hysteria
			49028, -- Dancing Rune Weapon
		},
		frost = {
			55268, 51419, 51418, 51417, 51416, 49143, -- Frost Strike
			50436, 50435, 50434, -- Icy Clutch
			51271, -- Unbreakable Armor
			49203, -- Hungering Cold
			51411, 51410, 51409, 49184, -- Howling Blast
			50485, -- Acclimation
		},
		unholy = {
			55271, 55270, 55265, 55090, -- Scourge Strike
			51735, 51734, 51726, -- Ebon Plague
			49222, -- Bone Shield
			51052, -- Anti-Magic Zone
			63560, -- Ghoul Frenzy
			49206, -- Summon Gargoyle
			50510, 50509, 50508, -- Crypt Fever
			66803, 66802, 66801, 66800, 63583, -- Desolation
		},
	},
	DRUID = {
		balance = {
			24858, -- Moonkin Form
			53227, 61387, 61388, 61390, 61391, -- Typhoon
			53201, 53200, 53199, 48505, -- Starfall
			48391, -- Owlkin Frenzy
			48517, 48518, -- Eclipse
			60433, 60432, 60431, -- Earth and Moon
			33831, -- Force of Nature
		},
		feral = {
			24932, -- Leader of the Pack
			58181, 58180, 58179, -- Infected Wounds
			48564, 48563, 33987, 33986, 33878, -- Mangle (Bear)
			48566, 48565, 33983, 33982, 33876, -- Mangle (Cat)
			50334, -- Berserk
		},
		restoration = {
			33891, -- Tree of Life
			53251, 53249, 53248, 48438, -- Wild Growth
			18562, -- Swiftmend
			45283, 45282, 45281, -- Natural Perfection
			48504, -- Living Seed
		},
	},
	HUNTER = {
		beastmastery = {
			19574, -- Bestial Wrath
			53257, -- Cobra Strikes
		},
		marksmanship = {
			19506, -- Trueshot Aura
			53209, -- Chimera Shot
			34490, -- Silencing Shot
			63468, -- Piercing Shots
			53220, -- Improved Steady Shot
		},
		survival = {
			49012, 49011, 27068, 24133, 24132, 19386, -- Wyvern Sting
			63672, 63671, 63670, 63669, 63668, 3674, -- Black Arrow
			60053, 60052, 60051, 53301, -- Explosive Shot
			34501, -- Expose Weakness
			34837, 34836, 34835, 34834, 34833, -- Master Tactician
			64420, 64419, 64418, -- Sniper Training
		},
	},
	MAGE = {
		arcane = {
			31589, -- Slow
			44401, -- Missile Barrage
			44781, 44780, 44425, -- Arcane Barrage
			12042, -- Arcane Power
			44413, -- Incanter's Absorption
		},
		fire = {
			55360, 55359, 44457, -- Living Bomb
			42950, 42949, 33043, 33042, 33041, 31661, -- Dragon's Breath
			28682, -- Combustion
			48108, -- Hot Streak
			64346, -- Fiery Payback
			54741, -- Firestarter
		},
		frost = {
			43039, 43038, 33405, 27134, 13033, 13032, 13031, 11426, -- Ice Barrier
			44572, -- Deep Freeze
			31687, -- Summon Water Elemental
			55080, -- Shattered Barrier
			74396, -- Fingers of Frost
			57761, -- Brain Freeze
		},
	},
	PALADIN = {
		holy = {
			48825, 48824, 33072, 27174, 20930, 20929, 20473, -- Holy Shock
			53563, -- Beacon of Light
			31842, -- Divine Illumination
			31834, -- Light's Grace
			54153, 54152, 53657, 53656, 53655, -- Judgements of the Pure
			53659, -- Sacred Cleansing
		},
		protection = {
			48952, 48951, 27179, 20928, 20927, 20925, -- Holy Shield
			48827, 48826, 32700, 32699, 31935, -- Avenger's Shield
			53595, -- Hammer of the Righteous
			68055, -- Judgements of the Just
			20132, 20131, 20128, -- Redoubt
			66233, -- Ardent Defender
		},
		retribution = {
			35395, -- Crusader Strike
			53385, -- Divine Storm
			20066, -- Repentance
			59578, 53489, -- The Art of War
			54203, -- Sheath of Light
			61840, -- Righteous Vengeance
		},
	},
	PRIEST = {
		discipline = {
			10060, -- Power Infusion
			33206, -- Pain Suppression
			45242, 45241, 45237, -- Focused Will
			63944, -- Renewed Hope
			47753, -- Divine Aegis
			47930, -- Grace
			59891, 59890, 59889, 59888, 59887, -- Borrowed Time
		},
		holy = {
			48089, 48088, 34866, 34865, 34864, 34863, 34861, -- Circle of Healing
			48087, 48086, 28275, 27871, 27870, 724, -- Lightwell
			48085, 48084, 28276, 27874, 27873, 7001, -- Lightwell Renew
			63725, 63724, 34754, -- Holy Concentration
			33143, -- Blessed Resilience
			65081, 64128, -- Body and Soul
			63734, 63735, 63731, -- Serendipity
			47788, -- Guardian Spirit
		},
		shadow = {
			15473, -- Shadowform
			48160, 48159, 34917, 34916, 34914, -- Vampiric Touch
			33198, 33197, 33196, -- Misery
			64044, -- Psychic Horror
			47585, -- Dispersion
		},
	},
	ROGUE = {
		assassination = {
			48666, 48663, 34413, 34412, 34411, 1329, -- Mutilate
			58427, -- Overkill
			51662, -- Hunger For Blood
			52910, 52915, 52914, -- Turn the Tables
		},
		combat = {
			13750, -- Adrenaline Rush
			51690, -- Killing Spree
			58683, 58684, -- Savage Combat
		},
		subtlety = {
			36554, -- Shadowstep
			51713, -- Shadow Dance
			14183, -- Premeditation
			45182, -- Cheat Death
			51693, -- Waylay
		},
	},
	SHAMAN = {
		elemental = {
			57722, 57721, 57720, 30706, -- Totem of Wrath
			59159, 59158, 59156, 51490, -- Thunderstorm
			16166, -- Elemental Mastery
			64695, -- Earthgrab
			65264, 65263, 64694, -- Lava Flows
			52179, -- Astral Shift
		},
		enhancement = {
			17364, -- Stormstrike
			60103, -- Lava Lash
			30823, -- Shamanistic Rage
			53817, -- Maelstrom Weapon
			51533, -- Feral Spirit
		},
		restoration = {
			49284, 49283, 32594, 32593, 974, -- Earth Shield
			61301, 61300, 61299, 61295, -- Riptide
			51886, -- Cleanse Spirit
			16190, -- Mana Tide Totem
			53390, -- Tidal Waves
			31616, -- Nature's Guardian
		},
	},
	WARLOCK = {
		affliction = {
			47843, 47841, 30405, 30404, 30108, 31117, -- Unstable Affliction
			59164, 59163, 59161, 48181, -- Haunt
			64371, 64370, 64368, -- Eradication
			59092, 27265, 18938, 18937, 18220, -- Dark Pact
		},
		demonology = {
			47193, -- Demonic Empowerment
			63167, 63165, -- Decimation
			30146, -- Summon Felguard
			47241, -- Metamorphosis
		},
		destruction = {
			17962, -- Conflagrate
			47847, 47846, 30414, 30413, 30283, -- Shadowfury
			59172, 59171, 59170, 50796, -- Chaos Bolt
			63244, 63243, 18093, -- Pyroclasm
			54277, 54276, 54274, -- Backdraft
		},
	},
	WARRIOR = {
		arms = {
			47486, 47485, 30330, 25248, 21553, 21552, 21551, 12294, -- Mortal Strike
			46924, -- Bladestorm
			29842, 29841, -- Second Wind
			65156, -- Juggernaut
			52437, -- Sudden Death
		},
		fury = {
			23881, -- Bloodthirst
			60970, -- Heroic Fury
			56112, -- Furious Attacks
			46916, -- Bloodsurge
		},
		protection = {
			47498, 47497, 30022, 30016, 20243, -- Devastate
			46968, -- Shockwave
			50720, -- Vigilance
			46947, 46946, -- Safeguard
			50227, -- Sword and Board
		},
	},
};
