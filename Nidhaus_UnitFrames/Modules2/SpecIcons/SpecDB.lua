local AddOnName, ns = ...;




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
			55262, 55261, 55260, 55259, 55258, 55050,
			55233,
			49016,
			49028,
		},
		frost = {
			55268, 51419, 51418, 51417, 51416, 49143,
			50436, 50435, 50434,
			51271,
			49203,
			51411, 51410, 51409, 49184,
			50485,
		},
		unholy = {
			55271, 55270, 55265, 55090,
			51735, 51734, 51726,
			49222,
			51052,
			63560,
			49206,
			50510, 50509, 50508,
			66803, 66802, 66801, 66800, 63583,
		},
	},
	DRUID = {
		balance = {
			24858,
			53227, 61387, 61388, 61390, 61391,
			53201, 53200, 53199, 48505,
			48391,
			48517, 48518,
			60433, 60432, 60431,
			33831,
		},
		feral = {
			24932,
			58181, 58180, 58179,
			48564, 48563, 33987, 33986, 33878,
			48566, 48565, 33983, 33982, 33876,
			50334,
		},
		restoration = {
			33891,
			53251, 53249, 53248, 48438,
			18562,
			45283, 45282, 45281,
			48504,
		},
	},
	HUNTER = {
		beastmastery = {
			19574,
			53257,
		},
		marksmanship = {
			19506,
			53209,
			34490,
			63468,
			53220,
		},
		survival = {
			49012, 49011, 27068, 24133, 24132, 19386,
			63672, 63671, 63670, 63669, 63668, 3674,
			60053, 60052, 60051, 53301,
			34501,
			34837, 34836, 34835, 34834, 34833,
			64420, 64419, 64418,
		},
	},
	MAGE = {
		arcane = {
			31589,
			44401,
			44781, 44780, 44425,
			12042,
			44413,
		},
		fire = {
			55360, 55359, 44457,
			42950, 42949, 33043, 33042, 33041, 31661,
			28682,
			48108,
			64346,
			54741,
		},
		frost = {
			43039, 43038, 33405, 27134, 13033, 13032, 13031, 11426,
			44572,
			31687,
			55080,
			74396,
			57761,
		},
	},
	PALADIN = {
		holy = {
			48825, 48824, 33072, 27174, 20930, 20929, 20473,
			53563,
			31842,
			31834,
			54153, 54152, 53657, 53656, 53655,
			53659,
		},
		protection = {
			48952, 48951, 27179, 20928, 20927, 20925,
			48827, 48826, 32700, 32699, 31935,
			53595,
			68055,
			20132, 20131, 20128,
			66233,
		},
		retribution = {
			35395,
			53385,
			20066,
			59578, 53489,
			54203,
			61840,
		},
	},
	PRIEST = {
		discipline = {
			10060,
			33206,
			45242, 45241, 45237,
			63944,
			47753,
			47930,
			59891, 59890, 59889, 59888, 59887,
		},
		holy = {
			48089, 48088, 34866, 34865, 34864, 34863, 34861,
			48087, 48086, 28275, 27871, 27870, 724,
			48085, 48084, 28276, 27874, 27873, 7001,
			63725, 63724, 34754,
			33143,
			65081, 64128,
			63734, 63735, 63731,
			47788,
		},
		shadow = {
			15473,
			48160, 48159, 34917, 34916, 34914,
			33198, 33197, 33196,
			64044,
			47585,
		},
	},
	ROGUE = {
		assassination = {
			48666, 48663, 34413, 34412, 34411, 1329,
			58427,
			51662,
			52910, 52915, 52914,
		},
		combat = {
			13750,
			51690,
			58683, 58684,
		},
		subtlety = {
			36554,
			51713,
			14183,
			45182,
			51693,
		},
	},
	SHAMAN = {
		elemental = {
			57722, 57721, 57720, 30706,
			59159, 59158, 59156, 51490,
			16166,
			64695,
			65264, 65263, 64694,
			52179,
		},
		enhancement = {
			17364,
			60103,
			30823,
			53817,
			51533,
		},
		restoration = {
			49284, 49283, 32594, 32593, 974,
			61301, 61300, 61299, 61295,
			51886,
			16190,
			53390,
			31616,
		},
	},
	WARLOCK = {
		affliction = {
			47843, 47841, 30405, 30404, 30108, 31117,
			59164, 59163, 59161, 48181,
			64371, 64370, 64368,
			59092, 27265, 18938, 18937, 18220,
		},
		demonology = {
			47193,
			63167, 63165,
			30146,
			47241,
		},
		destruction = {
			17962,
			47847, 47846, 30414, 30413, 30283,
			59172, 59171, 59170, 50796,
			63244, 63243, 18093,
			54277, 54276, 54274,
		},
	},
	WARRIOR = {
		arms = {
			47486, 47485, 30330, 25248, 21553, 21552, 21551, 12294,
			46924,
			29842, 29841,
			65156,
			52437,
		},
		fury = {
			23881,
			60970,
			56112,
			46916,
		},
		protection = {
			47498, 47497, 30022, 30016, 20243,
			46968,
			50720,
			46947, 46946,
			50227,
		},
	},
};
