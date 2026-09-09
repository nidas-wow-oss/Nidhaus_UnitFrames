local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- CommandList.lua
--
-- LA LISTA DE TODOS LOS COMANDOS, EN UN SOLO LUGAR.
--
-- El addon tiene mas de cuarenta comandos repartidos en cuarenta archivos.
-- Hasta ahora la unica ayuda listaba cinco, y el resto habia que saberlos
-- de memoria o ir a buscarlos al codigo.
--
-- OJO: esta tabla es TEXTO, no el registro real. Los comandos siguen
-- viviendo en su modulo, como corresponde; esto solo los describe. Si
-- agregas uno nuevo, sumale la linea aca.
--
-- La columna 'mod' sirve para dos cosas: no listar comandos de modulos que
-- no existen (ShieldWatch esta fuera del load) y marcar en gris los de
-- modulos apagados, que es informacion util: si un comando "no hace nada",
-- casi siempre es porque su modulo esta destildado.
-- =========================================================

local GROUPS = {
	{ title = L["CMDLIST_GENERAL"] or "General", cmds = {
		{ "/nuf",             L["CMDLIST_NUF"]        or "Open the options panel" },
		{ "/nuf help",        L["CMDLIST_NUF_HELP"]   or "This list" },
		{ "/nuf reset",       L["CMDLIST_NUF_RESET"]  or "Reset every setting" },
		{ "/nufconfig db",    L["CMDLIST_CFG_DB"]     or "Dump the saved settings to chat" },
		{ "/nufconfig reset", L["CMDLIST_CFG_SIZE"]   or "Restore the panel window size" },
	}},
	{ title = L["CMDLIST_MOVING"] or "Moving things", cmds = {
		{ "/nufmove",      L["CMDLIST_MOVE"]      or "Move Everything (also /move, /nufunlock)" },
		{ "/nufslot",      L["CMDLIST_SLOT"]      or "Layout profiles per character", mod = "SlotProfiles" },
		{ "/nufparty",     L["CMDLIST_PARTYTEST"] or "Fake party, to position the frames alone" },
	}},
	{ title = L["CMDLIST_FRAMES"] or "Frames", cmds = {
		{ "/nufpartystyle", L["CMDLIST_PARTYSTYLE"] or "Party frame style: default | new | improved | pw | pw2" },
		{ "/nufpw2",        L["CMDLIST_PW2"]        or "Fine tuning window for the Compact 2 party style" },
		{ "/ptstyle",       L["CMDLIST_PTSTYLE"]    or "Square style for the unit frames" },
		{ "/nufnames",      L["CMDLIST_NAMES"]      or "Name colour and border" },
		{ "/nufpower",      L["CMDLIST_POWER"]      or "Power bar", mod = "PowerBar" },
		{ "/ppf",           L["CMDLIST_PPF"]        or "Party pet frames (also /partypetframe)", mod = "PartyPetFrame" },
		{ "/ptarget",       L["CMDLIST_PTARGET"]    or "Party targets (also /partytargets)" },
		{ "/pbuffs",        L["CMDLIST_PBUFFS"]     or "Party buffs (also /partybuffs)", mod = "PartyBuffs" },
		{ "/pcb",           L["CMDLIST_PCB"]        or "Party cast bars (also /partycastingbars)" },
	}},
	{ title = L["CMDLIST_ARENA"] or "Arena and PvP", cmds = {
		{ "/nuftimers",  L["CMDLIST_TIMERS"] or "Arena timers: round end, pipe, pillars" },
		{ "/apc",        L["CMDLIST_APC"]    or "Arena points calculator (also /arenapts)", mod = "ArenaPointsCalc" },
		{ "/nufduel",    L["CMDLIST_DUEL"]   or "Block duels" },
		{ "/seduction",  L["CMDLIST_SEDUC"]  or "Succubus seduction alert", mod = "SeductionAlert" },
	}},
	{ title = L["CMDLIST_CLASS"] or "Class", cmds = {
		{ "/nufclass",   L["CMDLIST_CLASS_T"] or "Class timers (water elemental, mirror images)" },
		{ "/nufpal",     L["CMDLIST_PAL"]     or "Paladin auras and Turn Evil" },
		{ "/paladinicd", L["CMDLIST_PALICD"]  or "Paladin internal cooldowns", mod = "PaladinICD" },
		{ "/ss",         L["CMDLIST_SS"]      or "Sacred Shield (also /sacredshield)", mod = "SacredShield" },
		{ "/sst",        L["CMDLIST_SST"]     or "Sacred Shield tracker", mod = "SacredShieldTracker" },
		{ "/gt",         L["CMDLIST_GT"]      or "Gargoyle tracker", mod = "GargoyleTracker" },
		{ "/nufcombo",   L["CMDLIST_COMBO"]   or "Combo point watcher", mod = "ComboWatch" },
		{ "/nufswing",   L["CMDLIST_SWING"]   or "Melee swing timer", mod = "MeleeSwingTimer" },
		{ "/nufshot",    L["CMDLIST_SHOT"]    or "Auto shot timer", mod = "AutoShotTimer" },
		{ "/arrowcount", L["CMDLIST_AMMO"]    or "Ammo counter", mod = "ArrowCount" },
		{ "/nufpetbuffs",L["CMDLIST_PETBUFFS"]or "Hunter pet buffs", mod = "HunterPetBuffs" },
		{ "/shieldwatch",L["CMDLIST_SWH"]     or "Shield watch (also /swh)", mod = "ShieldWatch" },
	}},
	{ title = L["CMDLIST_INTERFACE"] or "Interface", cmds = {
		{ "/nufmap",     L["CMDLIST_MAP"]    or "Minimap shape: square | round" },
		{ "/nufminimap", L["CMDLIST_MMICON"] or "Show or hide the addon icons", mod = "MinimapIconToggle" },
		{ "/hidebar",    L["CMDLIST_HIDEBAR"]or "Hide the action bar art", mod = "HideActionBarTextures" },
		{ "/hcb",        L["CMDLIST_HCB"]    or "Hide the chat buttons", mod = "HideChatButton" },
		{ "/nufcopy",    L["CMDLIST_COPY"]   or "Copy chat text" },
		{ "/nufspam",    L["CMDLIST_SPAM"]   or "System message filter", mod = "SystemSpamFilter" },
		{ "/dtsu",       L["CMDLIST_DTSU"]   or "Damage / healing text", mod = "DTSU" },
		{ "/nicedamage", L["CMDLIST_ND"]     or "Floating combat text (also /nd)", mod = "NiceDamage" },
	}},
};

local function ModuleExists(id)
	return id and K.Modules and K.Modules[id] ~= nil;
end

function K.PrintCommandList()
	print("|cff4FC3F7Nidhaus UnitFrames|r — " .. (L["CMDLIST_HEADER"] or "commands"));
	for _, group in ipairs(GROUPS) do
		print("|cffFFD100" .. group.title .. "|r");
		for _, entry in ipairs(group.cmds) do
			local cmd, desc, mod = entry[1], entry[2], entry.mod;
			-- Un modulo que ni siquiera cargo no se lista: su comando no existe.
			local show = true;
			if mod and not ModuleExists(mod) then show = false; end
			if show then
				local off = mod and K.IsModuleEnabled and not K.IsModuleEnabled(mod);
				if off then
					print(string.format("   |cff8A8A8A%-16s %s (%s)|r", cmd, desc,
						L["CMDLIST_OFF"] or "module off"));
				else
					print(string.format("   |cff88FF88%-16s|r %s", cmd, desc));
				end
			end
		end
	end
end
