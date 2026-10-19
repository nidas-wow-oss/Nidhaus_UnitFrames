local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- Localization.lua - Sistema de localización EN/ES
--
-- Detecta el idioma del cliente WoW con GetLocale()
-- esES / esMX = Español, todo lo demás = English

local locale = GetLocale();
local isSpanish = (locale == "esES" or locale == "esMX");

-- NOTA: los textos que solo usa el panel de opciones viven en
-- Nidhaus_UnitFrames_Config/SubTabs.lua (ese addon se carga recien al abrir
-- el panel, asi que no ocupan memoria mientras jugas). Aca quedan los que
-- usa el addon principal. Un texto nuevo del panel va alla.


-- ============================================================
-- ENGLISH (default)
-- ============================================================

-- Tags reutilizables
local INSTANT = "|cffFFD100\226\156\147 Applies instantly|r";
local RELOAD  = "|cffFFAA00\226\154\160 Requires /reload|r";

-- === TOOLTIPS ===

-- FLAT STYLE TOOLTIPS

-- CAST BAR TOOLTIPS

-- === OPTIONS PANEL ===

-- Tabs

-- ── Pestañas y secciones nuevas (rediseño estilo TidyPlates) ──
L["DUEL_BLOCKED"]                = "Duel from %s declined.";
L["DUEL_BLOCK_ON"]               = "Duels are now declined automatically.";
L["DUEL_BLOCK_OFF"]              = "Duels are allowed again.";
L["CLASSTIMERS_PREVIEW_ON"]      = "Class bars shown. Drag them, then /nufclass hide.";
L["CLASSTIMERS_RESET"]           = "Class bar positions reset.";
L["MOD_PFI"]                     = "Party Frames Improved";
L["MOD_PFI_DESC"]                = "Wider, cleaner texture for the party frames, with smaller name / health / mana text and a bigger health bar.";
L["MOD_SHIELDWATCH"]             = "ShieldWatch";
L["MOD_SHIELDWATCH_DESC"]        = "Bar showing how much is left on your magic shields and barriers, with a warning when they are about to break. /shieldwatch options to configure it.";
L["SW_LOCK"]                     = "Lock the bar";
L["SW_LOCK_TIP"]                 = "While unlocked you can drag the bar with the left mouse button. Right-click opens its menu.";
L["SW_FLASH"]                    = "Flash the border on warning";
L["SW_WARN_TIME"]                = "Warn when little time is left";
L["SW_WARN_TIME_VALUE"]          = "Seconds left";
L["SW_WARN_PCT"]                 = "Warn when the shield runs low";
L["SW_WARN_PCT_VALUE"]           = "Remaining %";
L["SW_SCALE"]                    = "Bar scale";
L["MOD_ABBREV_STATUS"]           = "Abbreviated Status Text";
L["MOD_ABBREV_STATUS_DESC"]      = "Shortens the health/mana numbers on unit frames (12.3k instead of 12345) and can show the percentage next to them.";
L["MOD_DTSU"]                    = "DTSU - Damage Tracker";
L["MOD_DTSU_DESC"]               = "Floating icons with your outgoing swing / spell / dot damage (total, last hit, hits). /dtsu move to reposition.";
L["MOD_PALADIN_ICD"]             = "Paladin ICD";
L["MOD_PALADIN_ICD_DESC"]        = "Visual internal cooldown of your paladin defensives (Divine Protection, Divine Shield, Hand of Protection, Avenging Wrath, Lay on Hands). /paladinicd to move it.";
L["ABBREV_DECIMALS"]             = "Decimals";
L["ABBREV_FROM"]                 = "Abbreviate from";
L["ABBREV_RESET"]                = "Restore defaults";
L["ABBREV_ON"]                   = "On";
L["ABBREV_POS_NOTE"]             = "Move the health / mana texts of the selected unit.";
L["ABBREV_POS_THEME"]            = "Theme";
L["PANEL_LOAD_FAIL"]             = "Could not load the options panel";
L["PANEL_LOAD_HINT"]             = "Check that the Nidhaus_UnitFrames_Config folder sits next to the addon folder and is enabled in the addon list.";
L["MOD_PARTYPETFRAME"]           = "Party pet enhanced";
L["MOD_PARTYPETFRAME_DESC"]   = "Custom frames for your party members' pets (party 1 to 4): portrait with the CC they get, health and mana, buffs, debuffs and cast bar. Options in Frames > Party > Pets.";
L["PARTY_STYLE_CURRENT"]         = "current";
L["MOD_COMBOWATCH"]              = "Combo Points";
L["MOD_COMBOWATCH_DESC"]         = "Big combo point counter, colored by amount, with a pulsing frame when you hit 5.";
L["COMBOWATCH_WRONG_CLASS"]      = "Only rogues and druids generate combo points.";
L["MOD_PETBUFFS"]                = "Pet Buffs";
L["MOD_PETBUFFS_DESC"]           = "Icons under the pet frame for Mend Pet, Cower and Last Stand, with their remaining duration.";
L["SLIDER_SCALE"]                = "Scale";
L["PETBUFFS_WRONG_CLASS"]        = "This module is only for hunters.";

L["PCB_TITLE"]                   = "Party Cast Bars";
L["PCB_SCALE_LABEL"]             = "Bar scale:";
L["PCB_CB_ICONS"]                = "Show spell icons";
L["PCB_CB_PARENT"]               = "Attach bars to party frames";
L["PCB_STYLE_TITLE"]             = "Bar style:";
L["PCB_STYLE_ARCANE"]            = "Arcane";
L["PCB_STYLE_BLIZZ"]             = "Blizzard";
L["PCB_STYLE_ARENA"]             = "Arena";
L["PCB_COLORS_LABEL"]            = "Bar colours:";
L["PCB_FRIENDLY"]                = "Friendly";
L["PCB_HOSTILE"]                 = "Hostile";
L["PCB_TYPE_CAST"]               = "Casting";
L["PCB_TYPE_CHANNEL"]            = "Channel";
L["PCB_TYPE_SUCCESS"]            = "Success";
L["PCB_TYPE_FAILURE"]            = "Failure";
L["PCB_SWATCH_TIP"]              = "Click to change this colour.";
L["PCB_BTN_RESET_COLORS"]        = "Reset colours";
L["PCB_BTN_RESET_POS"]           = "Reset positions";
L["PCB_BTN_DRAG_ON"]             = "Move bars";
L["PCB_BTN_DRAG_OFF"]            = "Stop moving";
L["TOOLTIP_NO_TALENT"]           = "No talents";
L["TOOLTIP_LOADING"]             = "Loading...";
L["MOD_SACREDSHIELD"]            = "Sacred Shield (target)";
L["MOD_SACREDSHIELD_DESC"]       = "Shows an icon while your target has the Sacred Shield absorb up.";
L["MOD_SS_TRACKER"]              = "Sacred Shield tracker (group)";
L["MOD_SS_TRACKER_DESC"]         = "Who has your Sacred Shield and how long is left (glows under 5 s), plus the 6 s absorb when it procs.";
L["MOD_SEDUCTION"]               = "Seduction on you (arena)";
L["MOD_SEDUCTION_DESC"]          = "Warns when a Succubus seduces you in arena.";
L["MOD_SYSTEM_SPAM"]             = "Hide system spam";
L["MOD_SYSTEM_SPAM_DESC"]        = "Filters repetitive system messages out of the chat.";
L["MOVE_AURA_BAR"]               = "Aura Bar";
L["MOVE_PRESENCE_BAR"]           = "Presence Bar";
L["MOVE_FORM_BAR"]               = "Form Bar";
L["MOVE_STANCE_BAR"]             = "Stance Bar";
L["TOOLTIP_CAST_BY"]             = "Cast by:";

L["MOD_APC"]                     = "Arena Points Calculator";
L["MOD_APC_DESC"]                = "Calculates the arena points you will get each week from your rating. /apc to open it.";
L["BTN_MODULE_OPEN"]             = "Open";

L["BTN_LOCK_IT"]                 = "Lock it";
L["ALERT_ICON_SIZE"]             = "Icon size";
L["ALERT_ADD_HINT"]              = "Add by ID or name:";
L["ALERT_ADD"]                   = "Add";
L["ALERT_ADDED"]                 = "Added";
L["ALERT_NOTFOUND"]              = "Spell ID not found.";
L["ALERT_CUSTOM"]                = "Added by you";
L["ALERT_REMOVE"]                = "Remove";
L["ALERT_PREVIEW"]               = "Preview";
L["ALERT_PREVIEW_NOTE"]          = "This is how the icon appears on screen when an enemy casts a watched spell.";
L["ALERT_ALL"]                   = "All";
L["ALERT_NONE"]                  = "None";
L["ALERT_DEFAULTS"]              = "Defaults";
L["MOD_GARGOYLE"]                = "Gargoyle Tracker";
L["MOD_GARGOYLE_DESC"]           = "Timer, cast bar and health of the enemy Ebon Gargoyle (Death Knight).";
L["MOD_ENEMYALERT"]              = "Enemy Spell Alert";
L["MOD_ENEMYALERT_DESC"]         = "Shows the spell icon on screen when an enemy casts a trap, fear or interrupt.";

-- Tab 1 - General

-- Tab 2 - Frames

-- Missing keys for Frames/General panels

-- Tab 3 - Arena

-- Flat Style UI

-- Cast Bar UI

-- Pet Frame

-- Visual Theme

-- Flat Style labels (sArena style)

-- Tab 4 - Modules

-- Bottom buttons
L["BTN_CLOSE"]                   = "Close";

-- === COMMANDS ===
L["CMD_HEADER"]                  = "|cffFF0000NUF|r: Slash commands:";
L["CMD_HELP"]                    = "  |cff00FFFFhelp|r - Show this help";
L["CMD_OPTIONS"]                 = "  |cff00FFFFoptions|r - Open options panel";
L["CMD_BOSS"]                    = "  |cff00FFFFboss|r - Show/Hide BossFrames";
L["CMD_ARENA"]                   = "  |cff00FFFFarena|r - Show/Hide ArenaFrames mover";
L["CMD_MODULES"]                 = "  |cff00FFFFmodules|r - List registered modules";
L["CMD_RESET"]                   = "  |cff00FFFFreset|r - Reset all settings";

-- === MODULE MANAGER ===
L["MM_REGISTER_ERROR"]           = "|cffFF0000NUF:|r RegisterModule: missing id or info";
L["MM_ERROR_ENABLING"]           = "|cffFF0000NUF:|r Error enabling ";
L["MM_ERROR_DISABLING"]          = "|cffFF0000NUF:|r Error disabling ";
L["MM_ERROR_INIT"]               = "|cffFF0000NUF:|r Error initializing ";
L["MM_LIST_HEADER"]              = "|cffFFFF00NUF Modules:|r";
L["MM_LIST_EMPTY"]               = "  (No modules registered)";
L["MM_LIST_HINT"]                = "  Add .lua files in Modules2/ and register them with K.RegisterModule()";

-- === CONFIG MANAGER ===
L["CFG_HEADER"]                  = "|cffFFFF00NUF Configuration|r";
L["CFG_NOT_LOADED"]              = "|cffFF0000ERROR: Configuration not loaded yet!|r";
L["CFG_FORMAT"]                  = "|cffFFFF00Format: [OK/ERR] Key: DB_value (type) | C_value (type)|r";
L["CFG_SAVED_POS"]               = "|cffFFFF00Saved Positions:|r";
L["CFG_NO_SAVED_POS"]            = "|cffFFFF00No saved positions.|r";
L["CFG_ALL_SYNC"]                = "|cffFFD100All values synchronized!|r";
L["CFG_OUT_OF_SYNC"]             = "|cffFF0000WARNING: Some values out of sync!|r";
L["CFG_RESET_OK"]                = "|cffFFD100NUF ConfigManager:|r Configuration reset to defaults!";

-- Textos que estaban escritos a mano dentro de los modulos.
-- Los tres primeros estaban fijos EN ESPANOL, o sea rotos al reves: un
-- cliente en ingles los veia en castellano.
L["PPF_PREVIEW_PET"]          = "Pet";
L["DRAG_LABEL"]                  = "DRAG";

-- === Ventanas propias de los modulos ===
-- Estos textos estaban escritos a mano dentro de cada modulo y por eso no
-- se traducian a ningun idioma.
L["BTN_SAVE"]                    = "Save";
L["BTN_RESET_SHORT"]             = "Reset";

-- Arena Points Calculator
L["APC_TITLE"]                   = "Arena Points Calculator";
L["APC_MY_POINTS"]               = "My Points This Week";
L["APC_NO_TEAMS"]                = "You are not in any arena team.";
L["APC_MANUAL"]                  = "Manual Calculator";
L["APC_RATING"]                  = "Rating:";
L["APC_CALCULATE"]               = "Calculate";
L["APC_NEED_GAMES"]              = ">>> 0 points - you need to play games!";
L["APC_SERVER_X2"]               = "Warmane Blackrock \226\128\148 Points x2";
L["APC_INVALID_RATING"]          = "Enter a valid rating.";
L["APC_SHORT"]                   = "Arena Calculator";
L["APC_BTN_PTS"]                 = "pts";
L["APC_BTN_NO_GAMES"]            = "No games";
L["APC_BTN_TIP_BEST"]            = "Points you will receive this week";
L["APC_BTN_TIP_CLICK"]           = "Click to open the calculator";
L["TT_SOLO_QUEUE"]               = "Solo Queue";

-- Party Targets
L["PT_HIDE_NAME"]                = "Hide target name";
L["PT_CLASS_ICON"]               = "Class icon in portrait";
L["PT_CLASS_ICON_TIP"]           = "Shows the class icon instead of the face (players only; NPCs keep their face).";
L["PT_STYLE"]                    = "Frame style:";
L["PT_STYLE_CLASSIC"]            = "Classic (wide)";
L["PT_STYLE_SQUARE"]             = "Square (compact)";
L["PT_TITLE"]                    = "Party Targets";
L["PT_MIRROR"]                   = "Mirror Party Frames";
L["PT_ANCHOR"]                   = "Anchor to Party Frames";
L["PT_ANCHOR_HINT"]              = "ON: drag one moves all | OFF: move each";
L["PT_LOCK"]                     = "Lock Frames";
L["PT_LOCK_HINT"]                = "Shift+Alt+drag always overrides lock";
L["PT_SCALE"]                    = "Scale:";

-- Party Buffs
L["PB_TITLE"]                    = "Party Buffs";
L["PB_SCALEMAX"]                 = "Scale / Max";
L["PB_SCALE_ICONS"]              = "Scale icons:";
L["PB_MAX_ICONS"]                = "Max icons:";

-- NiceDamage
L["ND_TITLE"]                    = "Font Selector";
L["ND_FONT"]                     = "Font";
L["ND_TIP_D"]                    = "Enemy Damage";
L["ND_TIP_D_NOTE"]               = "Requires reopening WoW";
L["ND_TIP_H"]                    = "Heals, Auras & Self Text";
L["ND_TIP_H_NOTE"]               = "Applies instantly";
L["ND_LEG_D"]                    = "= Enemy Damage (requires reopening WoW)";
L["ND_LEG_H"]                    = "= Heals / Auras / Self Text (instant)";
L["ND_OPEN"]                     = "Open Font Selector";

-- Gargoyle Tracker
L["GT_DUR"]                      = "Dur";
L["GT_HP"]                       = "HP";
L["GT_CAST"]                     = "Cast";

-- Varios
L["SW_NO_SHIELD"]                = "no shield";
L["LBL_STYLE"]                   = "Style:";
L["SPECICONS_HINT"]              = "Round icon on Blizzard/Custom, rectangular on Flat style.";
L["MOVER_DRAG"]                  = "NUF - drag to move";
L["MOVER_HINT"]                  = "Shift+Alt+Click to move various elements";
L["BOSS_DRAG"]                   = "BOSS FRAMES [drag]";
L["HP_NA"]                       = "N/A";
L["HP_DEAD"]                     = "Dead";

-- Paneles de Config
L["CMD_MODULE_OFF"]              = "%s is turned off. Enable it in the options panel to use its commands.";

-- Claves que se usaban en el codigo pero nunca se habian definido.

-- Tab 5 - Extra Options

-- Profiles

-- Character Setup (barras / macros / bindeos) - NADA que ver con los
-- perfiles de arriba, que son la config del addon.
L["SLOT_BACKUP_DONE"]            = "Backup restored.";
L["SLOT_ERR_COMBAT"]             = "Can't do this in combat.";
L["SLOT_ERR_EMPTY"]              = "Paste a string first.";
L["SLOT_ERR_DECODE"]             = "The string is corrupt or incomplete.";
L["SLOT_ERR_PARSE"]              = "Invalid string: ";
L["SLOT_ERR_NOBACKUP"]           = "There is no backup yet.";
L["SLOT_ERR_NOPROFILE"]          = "That setup no longer exists.";
L["SLOT_MACRO_FULL"]             = "Macro '%s' skipped: no free macro slots.";

-- Utility

-- Arena Timers
L["ARENA_END_PREFIX"]            = "Arena: ";
L["TIMERS_TEST_HINT"]            = "Arena timers test mode toggled. Hold Alt and drag to move them.";

-- Action Bar Text

-- Frames subtabs

-- Mover todo
L["MOVE_RESET_DONE"]             = "Every frame is back to its default position.";
L["MOVE_HELP_ALL"]               = "unlock everything";
L["MOVE_HELP_FRAMES"]            = "only the unit frames";
L["MOVE_HELP_LOCK"]              = "lock it back";
L["MOVE_HELP_RESET"]             = "back to default positions";
L["MOVER_HINT_SCALE"]            = "Ctrl + mouse wheel over a box to scale it";
L["MOVER_CONSOLE"]                = "Move Everything";
L["LBL_MOVE_GRID"]               = "Grid";
L["PARTYTEST_COMBAT"]            = "Cannot start party test mode during combat.";
L["BTN_MOVE_RESET"]              = "Reset";
L["MOVE_COMBAT_BLOCK"]           = "Action bars cannot be moved during combat.";

-- Minimapa
L["MOD_MINIMAP_TOGGLE"]          = "Minimap Icon Toggle";
L["MOD_MINIMAP_TOGGLE_DESC"]     = "Button on the minimap corner that hides or shows the addon icons.";
L["MINIMAP_TOGGLE_TITLE"]        = "Minimap Icons";
L["MINIMAP_TOGGLE_TIP"]          = "Click to hide or show the addon icons. Zoom, clock and calendar are set in Decorations.";
L["MINIMAP_TOGGLE_DISABLED"]     = "Enable the Minimap Icon Toggle module first.";

L["BTN_MODULE_MOVE"]             = "Move";
L["BTN_MODULE_LOCK"]             = "Lock";
L["BTN_MODULE_TOGGLE"]           = "Toggle";

-- Nuevos modulos
L["MOD_ARROWCOUNT"]              = "Arrow / Bullet Count";
L["MOD_DUNGEONROLES"]            = "Dungeon Finder Roles";
L["MOD_DUNGEONROLES_DESC"]       = "While queued for a dungeon, shows tank, healer and 3 dps icons and lights up the roles already filled. Alt + drag to move.";
L["MOD_ARROWCOUNT_DESC"]         = "Shows how much ammo you have left. /arrowcount lock | unlock.";
L["MOD_POWERBAR"]                = "Power Bar";
L["MOD_POWERBAR_DESC"]           = "Movable mana / energy / rage / runic power bar next to your character. Alt + drag to move it.";
L["BAR_WATER_ELE"]               = "Water Elemental";
L["BAR_MIRROR"]                  = "Mirror Image";
L["MOD_AUTOSHOT"]                = "Auto Shot Timer";
L["MOD_AUTOSHOT_DESC"]           = "Hunter auto shot timing bar. /nufshot unlock to move it.";
L["MOD_SWINGTIMER"]              = "Melee Swing Timer";
L["MOD_SWINGTIMER_DESC"]         = "Bar showing the time until your next melee white hit. /nufswing unlock to move it.";
L["SWING_LABEL"]                 = "Auto attack";
L["MOD_TURN_EVIL"]               = "Turn Evil tracker";
L["MOD_TURN_EVIL_DESC"]          = "Shows who is under Turn Evil and how long is left: arena pets, summons like the Gargoyle, and undead or demons in the open world.";
L["MOD_PALADIN_AURAS"]           = "Paladin tracker";
L["MOD_PALADIN_AURAS_DESC"]      = "Holy Strength proc, healing reduction on any party member, and The Art of War proc. /nufpal to move them.";
L["MOD_CLASSOUTLINE"]            = "Class Colored Outlines";
L["MOD_CLASSOUTLINE_DESC"]       = "Adds a class colored ring around the player, target and focus portraits.";
L["SWING_USE_GLOBAL"]            = "Move Everything is on: drag the blue box from there.";

-- Barras

-- Subtabs

-- Unit Name Color

-- Chat
L["CHATCOPY_DISABLED"]           = "Chat copy is disabled in the options.";
L["URL_POPUP_TEXT"]              = "Copy the link (Ctrl+C):";

-- Module collapse

-- Tab 6 - About

-- === MINIMAP BUTTON ===
L["MINIMAP_TITLE"]               = "|cffffffffNidhaus|r |cffFFD100UnitFrames|r";
L["MINIMAP_LEFT_CLICK"]          = "|cffFFFFFFLeft Click:|r Open Options";
L["MINIMAP_RIGHT_CLICK"]         = "|cffFFFFFFRight Click:|r Toggle Arena Mover";
L["MINIMAP_CTRL_CLICK"]          = "|cffFFFFFFCtrl + Click:|r Move Everything";
L["MINIMAP_SHIFT_CLICK"]         = "|cffFFFFFFShift + Click:|r Reload UI";
L["MINIMAP_DRAG"]                = "|cffFFFFFFDrag:|r Move icon";

-- === UNIFY ACTION BARS MODULE ===

-- ============================================================
-- ESPAÑOL (override si el cliente es esES o esMX)
-- ============================================================

-- === LISTA DE COMANDOS (/nuf help) ===
-- Faltaban ENTERAS: el codigo las pedia con L["..."] or "ingles", asi
-- que la lista salia en ingles en los dos idiomas y nadie lo notaba,
-- porque el texto de respaldo estaba ahi mismo. Definidas aca, la
-- version en español de mas abajo ya tiene que traducir.
L["CMDLIST_GENERAL"] = "General";
L["CMDLIST_NUF"] = "Open the options panel";
L["CMDLIST_NUF_HELP"] = "This list";
L["CMDLIST_NUF_RESET"] = "Reset every setting";
L["CMDLIST_CFG_DB"] = "Dump the saved settings to chat";
L["CMDLIST_CFG_SIZE"] = "Restore the panel window size";
L["CMDLIST_MOVING"] = "Moving things";
L["CMDLIST_MOVE"] = "Move Everything (also /move, /nufunlock)";
L["CMDLIST_SLOT"] = "Layout profiles per character";
L["CMDLIST_PARTYTEST"] = "Fake party, to position the frames alone";
L["CMDLIST_FRAMES"] = "Frames";
L["CMDLIST_PARTYSTYLE"] = "Party frame style: default | new | improved | pw | pw2";
L["CMDLIST_PW2"] = "Fine tuning window for the Compact 2 party style";
L["CMDLIST_PTSTYLE"] = "Square style for the unit frames";
L["CMDLIST_NAMES"] = "Name colour and border";
L["CMDLIST_POWER"] = "Power bar";
L["CMDLIST_PPF"] = "Party pet frames (also /partypetframe)";
L["CMDLIST_PTARGET"] = "Party targets (also /partytargets)";
L["CMDLIST_PBUFFS"] = "Party buffs (also /partybuffs)";
L["CMDLIST_PCB"] = "Party cast bars (also /partycastingbars)";
L["CMDLIST_ARENA"] = "Arena and PvP";
L["CMDLIST_TIMERS"] = "Arena timers: round end, pipe, pillars";
L["CMDLIST_APC"] = "Arena points calculator (also /arenapts)";
L["CMDLIST_DUEL"] = "Block duels";
L["CMDLIST_SEDUC"] = "Succubus seduction alert";
L["CMDLIST_CLASS"] = "Class";
L["CMDLIST_CLASS_T"] = "Class timers (water elemental, mirror images)";
L["CMDLIST_PAL"] = "Paladin auras and Turn Evil";
L["CMDLIST_PALICD"] = "Paladin internal cooldowns";
L["CMDLIST_SS"] = "Sacred Shield (also /sacredshield)";
L["CMDLIST_SST"] = "Sacred Shield tracker";
L["CMDLIST_GT"] = "Gargoyle tracker";
L["CMDLIST_COMBO"] = "Combo point watcher";
L["CMDLIST_SWING"] = "Melee swing timer";
L["CMDLIST_SHOT"] = "Auto shot timer";
L["CMDLIST_AMMO"] = "Ammo counter";
L["CMDLIST_PETBUFFS"] = "Hunter pet buffs";
L["CMDLIST_SWH"] = "Shield watch (also /swh)";
L["CMDLIST_INTERFACE"] = "Interface";
L["CMDLIST_MAP"] = "Minimap shape: square | round";
L["CMDLIST_MMICON"] = "Show or hide the addon icons";
L["CMDLIST_HIDEBAR"] = "Hide the action bar art";
L["CMDLIST_HCB"] = "Hide the chat buttons";
L["CMDLIST_COPY"] = "Copy chat text";
L["CMDLIST_SPAM"] = "System message filter";
L["CMDLIST_DTSU"] = "Damage / healing text";
L["CMDLIST_ND"] = "Floating combat text (also /nd)";
L["CMDLIST_HEADER"] = "commands";
L["CMDLIST_OFF"] = "module off";

-- === ARENA: OJO / DR / DOTS ===
L["HEADER_ARENA_DR"]             = "Diminishing Returns";
L["DR_MOVE_HINT"]                = "Preview: Shift+Alt+drag the icons to move them (all five frames move together).";
L["DR_PREVIEW_NEEDS_ARENA"]      = "the preview needs the arena frames mod (Arena > Frames).";
L["DR_NEED_ENABLE"]              = "turn it on in Arena > DR.";
L["HEADER_ARENA_DOT"]            = "DoT warning";
L["DOT_NEED_ENABLE"]             = "turn it on in Arena > DoT.";

-- === TEXTOS QUE ESTABAN FIJOS EN EL CODIGO (modulos, mensajes de comandos, modo mover) ===
L["ERR_IN_EVENT"]                = "Error in";
L["ERR_CONFIG_LOAD"]             = "Config load error:";
L["ARENA_MOVER_COMBAT"]          = "Cannot toggle arena mover in combat.";
L["MOD_ARENA_TIMES"]             = "Arena Times";
L["MOD_ARENA_TIMES_DESC"]        = "Timer on arena invite popup + queue time next to minimap.";
L["MOD_BUTTON_RANGE"]            = "Button Range";
L["MOD_BUTTON_RANGE_DESC"]       = "Colors out-of-range action buttons red.";
L["MOD_CLASS_ICONS"]             = "Class Icons";
L["MOD_CLASS_ICONS_DESC"]        = "Replaces portraits with class icons (default, modern, hs, ex)";
L["MOD_HIDE_BAR_TEX"]            = "Hide Action Bar Textures";
L["MOD_HIDE_BAR_TEX_DESC"]       = "Hides action bar decorative textures.";
L["MOD_HIDE_CHAT_BTN"]           = "Hide Chat Button";
L["MOD_HIDE_CHAT_BTN_DESC"]      = "Small button to hide or show the chat frame.";
L["MOD_PARTYBUFFS_DESC"]         = "Extended buffs and/or debuffs (1-20 icons) on party frames. /pbuffs | /pbuffs reset";
L["MOD_SPEC_ICONS"]              = "Spec Icons";
L["MOD_SPEC_ICONS_DESC"]         = "Detects enemy spec via combat log. Shows spec icon on Target, Focus and Arena frames.";
L["CLASSICON_DEFAULT"]           = "Default";
L["CLASSICON_MODERN"]            = "Modern";
L["CLASSICON_EX"]                = "Exprmtl";
L["SPEC_DB_MISSING"]             = "SpecIcons: SpecDB not loaded!";
L["ARROW_RESET"]                 = "Ammo counter - position and scale reset.";
L["ARROW_SCALE"]                 = "Ammo counter - scale:";
L["REPAIR_NO_FUNDS"]             = "Insufficient funds to repair!";
L["AUTOSHOT_UNLOCKED"]           = "Auto Shot - drag the bar. /nufshot lock to lock it.";
L["AUTOSHOT_LOCKED"]             = "Auto Shot - bar locked.";
L["AUTOSHOT_SCALE"]              = "Auto Shot - scale:";
L["AUTOSHOT_RESET"]              = "Auto Shot - position and scale reset.";
L["SWING_UNLOCKED"]              = "Swing Timer - drag the bar. /nufswing lock to lock it.";
L["SWING_LOCKED"]                = "Swing Timer - bar locked.";
L["SWING_SCALE"]                 = "Swing Timer - scale:";
L["SWING_RESET"]                 = "Swing Timer - position and scale reset.";
L["CMD_USAGE"]                   = "Usage:";
L["DUNGEONROLES_MOVE"]           = "Dungeon Roles - Alt + drag to move it.";
L["HIDEBAR_HIDDEN"]              = "HideBar: textures hidden.";
L["HIDEBAR_VISIBLE"]             = "HideBar: textures visible.";
L["MINIBAR_CAPTURE_ERR"]         = "Error capturing the original state:";
L["DTSU_MOVE_ON"]                = "move mode on, drag the green box. /dtsu move again to lock it.";
L["DTSU_MOVE_OFF"]               = "anchor locked.";
L["DTSU_SHORT"]                  = "short numbers =";
L["SS_POS_RESET"]                = "Sacred Shield - position restored to the WeakAura's.";
L["SST_POS_RESET"]               = "Sacred Shield Tracker - position reset.";
L["SED_POS_RESET"]               = "Seduction alert - position reset.";
L["SED_TEST"]                    = "Seduction alert - test. /seduction test again or change zone to hide it.";
L["PAL_PREVIEW_ON"]              = "Paladin tracker + Turn Evil: drag each group. /nufpal to lock. /nufpal debug for diagnostics.";
L["PAL_PREVIEW_OFF"]             = "Paladin tracker: position locked.";
L["PB_NO_FRAME"]                 = "PartyMemberFrame1 not available. Use /reload.";
L["PB_RESET_DONE"]               = "Reset done. Positions and scale restored.";
L["CMD_AVAILABLE"]               = "Available commands:";
L["PB_HELP_OPEN"]                = "Open the settings panel and the movers";
L["PB_HELP_RESET"]               = "Reset positions and scale to defaults";
L["PCB_ENABLE_FIRST"]            = "Enable PartyCastingBars first (/pcb enable).";
L["CMD_COMMANDS"]                = "commands:";
L["PCB_HELP_NOARG"]              = "(no argument)";
L["PCB_HELP_OPEN"]               = "Open the options window";
L["PCB_HELP_DRAG"]               = "Toggle drag/position mode";
L["PCB_HELP_ICON"]               = "Toggle spell icons";
L["PCB_HELP_SCALE"]              = "Set bar scale";
L["PCB_HELP_PARENT"]             = "Toggle frame parenting";
L["PCB_HELP_RESET"]              = "Reset bar positions";
L["PPF_CLICK_ON"]                = "Click enabled - click to target the pet";
L["PPF_CLICK_OFF"]               = "Click disabled";
L["PPF_ARENA_ONLY"]              = "Arenas only";
L["PPF_EVERYWHERE"]              = "Everywhere";
L["PPF_POS_RESET"]               = "Position reset";
L["CMD_COMMANDS_TITLE"]          = "Commands:";
L["PPF_HELP_LOCK"]               = "Lock/unlock the row";
L["PPF_HELP_CLICK"]              = "Enable/disable click to target";
L["PPF_HELP_ARENA"]              = "Switch between arenas only and everywhere";
L["PPF_HELP_RESET"]              = "Reset the row position";
L["PPF_HELP_DRAG"]               = "Drag the top frame: the other three follow it.";
L["PT_HELP_OPEN"]                = "Open config panel";
L["PT_RESET_CONFIRM"]            = "Reset all PartyTargets settings to defaults?";
L["PT_CONFIG_OPEN"]              = "Config open - drag target frames to reposition.";
L["POWERBAR_AURA_HIDDEN"]        = "is no longer shown.";
L["POWERBAR_AURA_HINT"]          = "to show them all again.";
L["POWERBAR_MOVE_ON"]            = "Power Bar - Alt + drag to move it. Right-click an aura to hide it. Click Move again to exit.";
L["POWERBAR_RESET"]              = "Power Bar - position reset.";
L["POWERBAR_AURAS"]              = "Power Bar - all auras are shown again.";
L["POWERBAR_HELP"]               = "Power Bar - Alt + drag to move it.";
L["SPAM_FILTER"]                 = "system spam filter";
L["SPAM_ON"]                     = "on";
L["SPAM_OFF"]                    = "off";
L["SPAM_PATTERNS"]               = "patterns";
L["LORTI_GROUP_FRAMES"]          = "Frames";
L["LORTI_GROUP_UI"]              = "Interface";
L["LORTI_RELOAD_NOTE"]           = "needs /reload";
L["LORTI_COL_LORTI"]          = "Lorti";
L["LORTI_COL_COLOR"]          = "Color";
L["LORTI_Z_Player"]           = "Player";
L["LORTI_Z_Target"]           = "Target";
L["LORTI_Z_Focus"]            = "Focus";
L["LORTI_Z_Party"]            = "Party";
L["LORTI_Z_PartyTargets"]     = "Party targets";
L["LORTI_Z_PartyPet"]         = "Party pets";
L["LORTI_Z_Arena"]            = "Arena";
L["LORTI_Z_CastBar"]          = "Cast bars";
L["LORTI_Z_ActionBars"]       = "Action bars";
L["LORTI_Z_Minimap"]          = "Minimap";
L["LORTI_Z_Buffs"]            = "Your buffs";
L["LORTI_Z_Debuffs"]          = "Your debuffs";
L["LORTI_ZTIP_Player"]        = "Your frame and your pet's frame, in any style (Default, Light, Dark, Compact or Asuri). The mage's Icy frame keeps its own colors.";
L["LORTI_ZTIP_Target"]        = "The target frame and its target of target, in any style.";
L["LORTI_ZTIP_Focus"]         = "The focus frame and its target, in any style.";
L["LORTI_ZTIP_Party"]         = "The 4 party frames, their pets and their vehicle frame, in any party style (Default, New, Improved or Compact).";
L["LORTI_ZTIP_PartyTargets"]  = "The target-of-party frames.";
L["LORTI_ZTIP_PartyPet"]      = "The enhanced party pet frames and their cast bar border.";
L["LORTI_ZTIP_Arena"]         = "The enemy arena frames and their pets.";
L["LORTI_ZTIP_CastBar"]       = "The border of the cast bars: yours, target and focus.";
L["LORTI_ZTIP_ActionBars"]    = "The action bar art (also the XP and reputation bars) and the glow around the action buttons.";
L["LORTI_ZTIP_Minimap"]       = "The Lorti UI border of the minimap, and the clock. Same option as Interface > Minimap > Border style: Lorti UI.\nAlso: right-click the minimap to open the calendar.";
L["LORTI_ZTIP_Buffs"]         = "Your buffs (top right) and your weapon enchants: cut icon, Lorti border and glow. The target and focus auras stay normal.";
L["LORTI_ZTIP_Debuffs"]       = "Your debuffs: cut icon and glow. The border keeps the school color (Magic, Curse, Poison, Disease).";
L["LORTI_COLOR_TIP"]          = "Your own color instead of black. Click the square to choose it; right-click it for the default color.";
L["LORTI_COLOR_OFF"]          = "Tick 'Lorti' on this row first.";
L["LORTI_SWATCH_TIP"]         = "Click: choose the color (applies instantly).\nRight-click: back to the default color.";
L["LORTI_ALL_COLOR"]          = "Same color for all";
L["LORTI_ALL_COLOR_TIP"]      = "Paints every row that has 'Lorti' ticked with this color, and ticks its 'Color'. Cancel in the picker leaves everything as it was.";
L["LORTI_DEFAULT_COLORS"]     = "Default colors";
L["LORTI_DEFAULT_COLORS_TIP"] = "Every row back to the black of Lorti UI: unticks 'Color' and resets the colors to the default light blue.";
L["LORTI_REQ_RELOAD"]            = "Requires /reload";
L["MOD_LORTI_DESC"]           = "Lorti UI look: dark (or your color) frames, action buttons, minimap and your buffs. Turning the module on or off needs /reload.";
L["LORTI_MINIMAP_ERR"]           = "Minimap init error:";
L["MOVER_LBL_Player"]            = "Player";
L["MOVER_LBL_Target"]            = "Target";
L["MOVER_LBL_Pet"]               = "Pet";
L["MOVER_LBL_Party1"]            = "Party 1";
L["MOVER_LBL_Party2"]            = "Party 2";
L["MOVER_LBL_Party3"]            = "Party 3";
L["MOVER_LBL_Party4"]            = "Party 4";
L["MOVER_LBL_Buffs"]             = "Buffs";
L["MOVER_LBL_Debuffs"]           = "Debuffs";
L["MOVER_LBL_CastBar"]           = "Cast Bar";
L["MOVER_LBL_MainBar"]           = "Action Bar 1";
L["MOVER_LBL_ActionBar2"]        = "Action Bar 2";
L["MOVER_LBL_ActionBar3"]        = "Action Bar 3";
L["MOVER_LBL_PetBar"]            = "Pet Bar";
L["MOVER_LBL_StanceBar"]         = "Stance Bar";
L["MOVER_LBL_TotemBar"]          = "Totem Bar";
L["MOVER_LBL_PossessBar"]        = "Possess Bar";
L["MOVER_LBL_AutoShot"]          = "Auto Shot";
L["MOVER_LBL_SwingTimer"]        = "Auto attack";
L["MOVER_LBL_PaladinICD"]        = "Paladin ICD";
L["MOVER_LBL_PalAuras"]          = "Paladin tracker";
L["MOVER_LBL_TurnEvil"]          = "Turn Evil";
L["MOVER_LBL_SacredShield"]      = "Sacred Shield";
L["MOVER_LBL_SSTracker"]         = "Sacred Shield tracker";
L["MOVER_LBL_Seduction"]         = "Seduction alert";
L["MOVER_LBL_Gargoyle"]          = "Gargoyle";
L["MOVER_LBL_EnemyAlert"]        = "Spell Alert";
L["MOVER_LBL_ArrowCount"]        = "Ammo";
L["MOVER_LBL_DungeonRoles"]      = "Dungeon roles";
L["MOVER_LBL_PartyCast"]         = "Party Cast Bar";
L["MOVER_LBL_PartyTarget"]       = "Party Target";
L["MOVER_LBL_Minimap"]           = "Minimap";
L["MOVER_LBL_BGScore"]           = "BG score";
L["MOVER_LBL_CaptureBar"]        = "Capture bar";
L["MOVER_LBL_DalaranPipe"]       = "Dalaran waterfall";
L["MOVER_LBL_RoVPillars"]        = "RoV pillars";
L["MOVER_LBL_ArenaEnd"]          = "Arena time";
L["MOVER_LBL_ShadowSight"]       = "Shadow Sight (eye)";
L["MOVER_LBL_WaterEle"]          = "Water Elemental";
L["MOVER_LBL_MirrorImg"]         = "Mirror Image";

if isSpanish then

-- Tags
local INSTANTE = "|cffFFD100\226\156\147 Aplica al instante|r";
local RECARGA  = "|cffFFAA00\226\154\160 Requiere /reload|r";

-- === TOOLTIPS ===

-- FLAT STYLE TOOLTIPS

-- CAST BAR TOOLTIPS

-- === OPTIONS PANEL ===

-- Tabs

-- ── Pestañas y secciones nuevas (rediseño estilo TidyPlates) ──
L["DUEL_BLOCKED"]                = "Duelo de %s rechazado.";
L["DUEL_BLOCK_ON"]               = "Los duelos ahora se rechazan solos.";
L["DUEL_BLOCK_OFF"]              = "Los duelos vuelven a estar permitidos.";
L["CLASSTIMERS_PREVIEW_ON"]      = "Barras de clase a la vista. Arrastralas y despu\195\169s /nufclass hide.";
L["CLASSTIMERS_RESET"]           = "Posiciones de las barras de clase reiniciadas.";
L["MOD_PFI"]                     = "Party Frames Improved";
L["MOD_PFI_DESC"]                = "Textura m\195\161s ancha y limpia para los marcos de party, con los textos de nombre / vida / man\195\161 m\195\161s chicos y la barra de vida m\195\161s grande.";
L["MOD_SHIELDWATCH"]             = "ShieldWatch";
L["MOD_SHIELDWATCH_DESC"]        = "Barra con lo que queda de tus escudos y barreras m\195\161gicas, con aviso cuando est\195\161n por romperse. /shieldwatch options para configurarlo.";
L["SW_LOCK"]                     = "Bloquear la barra";
L["SW_LOCK_TIP"]                 = "Desbloqueada se arrastra con el boton izquierdo. El derecho abre su menu.";
L["SW_FLASH"]                    = "Destello del borde al avisar";
L["SW_WARN_TIME"]                = "Avisar cuando queda poco tiempo";
L["SW_WARN_TIME_VALUE"]          = "Segundos restantes";
L["SW_WARN_PCT"]                 = "Avisar cuando queda poco escudo";
L["SW_WARN_PCT_VALUE"]           = "Escudo restante %";
L["SW_SCALE"]                    = "Escala de la barra";
L["MOD_ABBREV_STATUS"]           = "Texto de estado abreviado";
L["MOD_ABBREV_STATUS_DESC"]      = "Acorta los n\195\186meros de vida/man\195\161 de los marcos de unidad (12.3k en vez de 12345) y puede mostrar el porcentaje al lado.";
L["MOD_DTSU"]                    = "DTSU - Tracker de da\195\177o";
L["MOD_DTSU_DESC"]               = "Iconos flotantes con tu da\195\177o saliente (swing / hechizo / dot): total, ultimo golpe y cantidad de hits. /dtsu move para reubicarlo.";
L["MOD_PALADIN_ICD"]             = "Paladin ICD";
L["MOD_PALADIN_ICD_DESC"]        = "CD interno visual de tus defensivas de paladin (Divine Protection, Escudo Divino, Mano de Protecci\195\179n, Ira Vengadora, Imposici\195\179n de Manos). /paladinicd para moverlo.";
L["ABBREV_DECIMALS"]             = "Decimales";
L["ABBREV_FROM"]                 = "Abreviar desde";
L["ABBREV_RESET"]                = "Restaurar valores";
L["ABBREV_ON"]                   = "Act";
L["ABBREV_POS_NOTE"]             = "Mueve los textos de vida / man\195\161 de la unidad seleccionada.";
L["ABBREV_POS_THEME"]            = "Tema";
L["PANEL_LOAD_FAIL"]             = "No se pudo cargar el panel de opciones";
L["PANEL_LOAD_HINT"]             = "Revisa que la carpeta Nidhaus_UnitFrames_Config este junto a la del addon y activada en la lista.";
L["MOD_PARTYPETFRAME"]           = "Party pet enhanced";
L["MOD_PARTYPETFRAME_DESC"]   = "Marcos propios para las mascotas de tus compa\195\177eros (party 1 a 4): retrato con el CC que les ponen, vida y man\195\161, buffs, debuffs y barra de casteo. Opciones en Frames > Party > Mascotas.";
L["PARTY_STYLE_CURRENT"]         = "actual";
L["MOD_COMBOWATCH"]              = "Puntos de combo";
L["MOD_COMBOWATCH_DESC"]         = "Contador grande de puntos de combo, con color seg\195\186n cu\195\161ntos llev\195\161s y un marco que late al llegar a 5.";
L["COMBOWATCH_WRONG_CLASS"]      = "Solo p\195\173caros y druidas generan puntos de combo.";
L["MOD_PETBUFFS"]                = "Buffos de la mascota";
L["MOD_PETBUFFS_DESC"]           = "Iconos debajo del marco de la mascota con Aliviar mascota, Agazaparse y Aguante, con lo que les queda de duraci\195\179n.";
L["SLIDER_SCALE"]                = "Escala";
L["PETBUFFS_WRONG_CLASS"]        = "Este m\195\179dulo es solo para cazadores.";

L["PCB_TITLE"]                   = "Barras de casteo del grupo";
L["PCB_SCALE_LABEL"]             = "Escala de las barras:";
L["PCB_CB_ICONS"]                = "Mostrar el icono del hechizo";
L["PCB_CB_PARENT"]               = "Pegar las barras a los marcos del grupo";
L["PCB_STYLE_TITLE"]             = "Estilo de barra:";
L["PCB_STYLE_ARCANE"]            = "Arcano";
L["PCB_STYLE_BLIZZ"]             = "Blizzard";
L["PCB_STYLE_ARENA"]             = "Arena";
L["PCB_COLORS_LABEL"]            = "Colores de las barras:";
L["PCB_FRIENDLY"]                = "Amistoso";
L["PCB_HOSTILE"]                 = "Hostil";
L["PCB_TYPE_CAST"]               = "Casteo";
L["PCB_TYPE_CHANNEL"]            = "Canalizado";
L["PCB_TYPE_SUCCESS"]            = "Exito";
L["PCB_TYPE_FAILURE"]            = "Fallo";
L["PCB_SWATCH_TIP"]              = "Clic para cambiar este color.";
L["PCB_BTN_RESET_COLORS"]        = "Restablecer colores";
L["PCB_BTN_RESET_POS"]           = "Restablecer posiciones";
L["PCB_BTN_DRAG_ON"]             = "Mover barras";
L["PCB_BTN_DRAG_OFF"]            = "Dejar de mover";
L["TOOLTIP_NO_TALENT"]           = "Sin talentos";
L["TOOLTIP_LOADING"]             = "Cargando...";
L["MOD_SACREDSHIELD"]            = "Escudo sagrado (objetivo)";
L["MOD_SACREDSHIELD_DESC"]       = "Muestra un icono mientras tu objetivo tiene el absorbe de Escudo sagrado.";
L["MOD_SS_TRACKER"]              = "Rastreador de Escudo sagrado (grupo)";
L["MOD_SS_TRACKER_DESC"]         = "Qui\195\169n tiene tu Escudo sagrado y cu\195\161nto le queda (brilla con menos de 5 s), y el absorbe de 6 s cuando salta.";
L["MOD_SEDUCTION"]               = "Seduccion sobre vos (arena)";
L["MOD_SEDUCTION_DESC"]          = "Avisa cuando una Sucubo te seduce en arena.";
L["MOD_SYSTEM_SPAM"]             = "Ocultar spam del sistema";
L["MOD_SYSTEM_SPAM_DESC"]        = "Filtra del chat los mensajes repetitivos del sistema.";
L["MOVE_AURA_BAR"]               = "Barra de auras";
L["MOVE_PRESENCE_BAR"]           = "Barra de presencias";
L["MOVE_FORM_BAR"]               = "Barra de formas";
L["MOVE_STANCE_BAR"]             = "Barra de posturas";
L["TOOLTIP_CAST_BY"]             = "Lanzado por:";

L["MOD_APC"]                     = "Calculadora de puntos de arena";
L["MOD_APC_DESC"]                = "Calcula los puntos de arena que vas a recibir cada semana seg\195\186n tu rating. /apc para abrirla.";
L["BTN_MODULE_OPEN"]             = "Abrir";

L["BTN_LOCK_IT"]                 = "Fijar";
L["ALERT_ICON_SIZE"]             = "Tama\195\177o del icono";
L["ALERT_ADD_HINT"]              = "Agregar por ID o nombre:";
L["ALERT_ADD"]                   = "Agregar";
L["ALERT_ADDED"]                 = "Agregado";
L["ALERT_NOTFOUND"]              = "No se encontro ese ID de hechizo.";
L["ALERT_CUSTOM"]                = "Agregados por vos";
L["ALERT_REMOVE"]                = "Quitar";
L["ALERT_PREVIEW"]               = "Vista previa";
L["ALERT_PREVIEW_NOTE"]          = "As\195\173 se ve el icono en pantalla cuando un enemigo lanza un hechizo vigilado.";
L["ALERT_ALL"]                   = "Todos";
L["ALERT_NONE"]                  = "Ninguno";
L["ALERT_DEFAULTS"]              = "Por defecto";
L["MOD_GARGOYLE"]                = "Gargoyle Tracker";
L["MOD_GARGOYLE_DESC"]           = "Tiempo, barra de casteo y vida de la Gargola de Ebano enemiga (Caballero de la Muerte).";
L["MOD_ENEMYALERT"]              = "Alerta de hechizos enemigos";
L["MOD_ENEMYALERT_DESC"]         = "Muestra el icono del hechizo en pantalla cuando un enemigo lanza una trampa, miedo o interrupci\195\179n.";

-- Tab 1 - General

-- Tab 2 - Frames

-- Missing keys for Frames/General panels

-- Tab 3 - Arena

-- Flat Style UI

-- Cast Bar UI

-- Pet Frame

-- Visual Theme

-- Flat Style labels (sArena style)

-- Tab 4 - Modules

-- Bottom buttons
L["BTN_CLOSE"]                   = "Cerrar";

-- === COMMANDS ===
L["CMD_HEADER"]                  = "|cffFF0000NUF|r: Comandos:";
L["CMD_HELP"]                    = "  |cff00FFFFhelp|r - Mostrar ayuda";
L["CMD_OPTIONS"]                 = "  |cff00FFFFoptions|r - Abrir panel de opciones";
L["CMD_BOSS"]                    = "  |cff00FFFFboss|r - Mostrar/Ocultar BossFrames";
L["CMD_ARENA"]                   = "  |cff00FFFFarena|r - Mostrar/Ocultar mover de Arena";
L["CMD_MODULES"]                 = "  |cff00FFFFmodules|r - Listar módulos registrados";
L["CMD_RESET"]                   = "  |cff00FFFFreset|r - Resetear configuración";

-- === MODULE MANAGER ===
L["MM_REGISTER_ERROR"]           = "|cffFF0000NUF:|r RegisterModule: falta id o info";
L["MM_ERROR_ENABLING"]           = "|cffFF0000NUF:|r Error activando ";
L["MM_ERROR_DISABLING"]          = "|cffFF0000NUF:|r Error desactivando ";
L["MM_ERROR_INIT"]               = "|cffFF0000NUF:|r Error inicializando ";
L["MM_LIST_HEADER"]              = "|cffFFFF00NUF Módulos:|r";
L["MM_LIST_EMPTY"]               = "  (No hay módulos registrados)";
L["MM_LIST_HINT"]                = "  Agregá archivos .lua en Modules2/ y registralos con K.RegisterModule()";

-- === CONFIG MANAGER ===
L["CFG_HEADER"]                  = "|cffFFFF00Configuración NUF|r";
L["CFG_NOT_LOADED"]              = "|cffFF0000ERROR: ¡La configuración todavía no cargó!|r";
L["CFG_FORMAT"]                  = "|cffFFFF00Formato: [OK/ERR] Clave: valor_DB (tipo) | valor_C (tipo)|r";
L["CFG_SAVED_POS"]               = "|cffFFFF00Posiciones guardadas:|r";
L["CFG_NO_SAVED_POS"]            = "|cffFFFF00No hay posiciones guardadas.|r";
L["CFG_ALL_SYNC"]                = "|cffFFD100¡Todos los valores sincronizados!|r";
L["CFG_OUT_OF_SYNC"]             = "|cffFF0000AVISO: ¡Hay valores desincronizados!|r";
L["CFG_RESET_OK"]                = "|cffFFD100NUF ConfigManager:|r ¡Configuración reseteada a defaults!";

L["PPF_PREVIEW_PET"]          = "Mascota";
L["DRAG_LABEL"]                  = "ARRASTRAR";

-- === Ventanas propias de los modulos ===
L["BTN_SAVE"]                    = "Guardar";
L["BTN_RESET_SHORT"]             = "Resetear";

-- Arena Points Calculator
L["APC_TITLE"]                   = "Calculadora de Puntos de Arena";
L["APC_MY_POINTS"]               = "Mis Puntos Esta Semana";
L["APC_NO_TEAMS"]                = "No estás en ningún equipo de arena.";
L["APC_MANUAL"]                  = "Calculadora Manual";
L["APC_RATING"]                  = "Rating:";
L["APC_CALCULATE"]               = "Calcular";
L["APC_NEED_GAMES"]              = ">>> 0 puntos - ¡tenés que jugar partidas!";
L["APC_SERVER_X2"]               = "Warmane Blackrock \226\128\148 Puntos x2";
L["APC_INVALID_RATING"]          = "Ingresá un rating válido.";
L["APC_SHORT"]                   = "Calc. de Arena";
L["APC_BTN_PTS"]                 = "pts";
L["APC_BTN_NO_GAMES"]            = "Sin partidas";
L["APC_BTN_TIP_BEST"]            = "Puntos que vas a recibir esta semana";
L["APC_BTN_TIP_CLICK"]           = "Click para abrir la calculadora";
L["TT_SOLO_QUEUE"]               = "Solo Queue";

-- Party Targets
L["PT_HIDE_NAME"]                = "Ocultar el nombre del objetivo";
L["PT_CLASS_ICON"]               = "Icono de clase en el retrato";
L["PT_CLASS_ICON_TIP"]           = "Muestra el icono de la clase en vez de la cara (solo jugadores; los NPC siguen con su cara).";
L["PT_STYLE"]                    = "Estilo del marco:";
L["PT_STYLE_CLASSIC"]            = "Cl\195\161sico (ancho)";
L["PT_STYLE_SQUARE"]             = "Cuadrado (compacto)";
L["PT_TITLE"]                    = "Objetivos del Grupo";
L["PT_MIRROR"]                   = "Espejar Frames de Grupo";
L["PT_ANCHOR"]                   = "Anclar a los Frames de Grupo";
L["PT_ANCHOR_HINT"]              = "ON: arrastrar uno mueve todos | OFF: mover cada uno";
L["PT_LOCK"]                     = "Bloquear Frames";
L["PT_LOCK_HINT"]                = "Shift+Alt+arrastrar siempre ignora el bloqueo";
L["PT_SCALE"]                    = "Escala:";

-- Party Buffs
L["PB_TITLE"]                    = "Party Buffs";
L["PB_SCALEMAX"]                 = "Escala / Máx";
L["PB_SCALE_ICONS"]              = "Escala de iconos:";
L["PB_MAX_ICONS"]                = "Máx. iconos:";

-- NiceDamage
L["ND_TITLE"]                    = "Selector de Fuente";
L["ND_FONT"]                     = "Fuente";
L["ND_TIP_D"]                    = "Daño Enemigo";
L["ND_TIP_D_NOTE"]               = "Requiere reabrir el WoW";
L["ND_TIP_H"]                    = "Sanaciones, Auras y Texto Propio";
L["ND_TIP_H_NOTE"]               = "Se aplica al instante";
L["ND_LEG_D"]                    = "= Daño Enemigo (requiere reabrir el WoW)";
L["ND_LEG_H"]                    = "= Sanaciones / Auras / Texto Propio (al instante)";
L["ND_OPEN"]                     = "Abrir Selector de Fuente";

-- Gargoyle Tracker
L["GT_DUR"]                      = "Dur";
L["GT_HP"]                       = "PS";
L["GT_CAST"]                     = "Casteo";

-- Varios
L["SW_NO_SHIELD"]                = "sin escudo";
L["LBL_STYLE"]                   = "Estilo:";
L["SPECICONS_HINT"]              = "Icono redondo en Blizzard/Custom, rectangular en estilo Flat.";
L["MOVER_DRAG"]                  = "NUF - arrastrar para mover";
L["MOVER_HINT"]                  = "Shift+Alt+Click para mover varios elementos";
L["BOSS_DRAG"]                   = "FRAMES DE BOSS [arrastrar]";
L["HP_NA"]                       = "N/D";
L["HP_DEAD"]                     = "Muerto";

-- Paneles de Config
L["CMD_MODULE_OFF"]              = "%s est\195\161 apagado. Prendelo en el panel de opciones para poder usar sus comandos.";

-- Claves que se usaban en el codigo pero nunca se habian definido.

-- Tab 5 - Extra Options

-- Profiles

-- Character Setup (barras / macros / bindeos) - NADA que ver con los
-- perfiles de arriba, que son la config del addon.
L["SLOT_BACKUP_DONE"]            = "Backup restaurado.";
L["SLOT_ERR_COMBAT"]             = "No se puede hacer esto en combate.";
L["SLOT_ERR_EMPTY"]              = "Pegá una cadena primero.";
L["SLOT_ERR_DECODE"]             = "La cadena está corrupta o incompleta.";
L["SLOT_ERR_PARSE"]              = "Cadena inválida: ";
L["SLOT_ERR_NOBACKUP"]           = "Todavía no hay backup.";
L["SLOT_ERR_NOPROFILE"]          = "Esa configuración ya no existe.";
L["SLOT_MACRO_FULL"]             = "Macro '%s' salteada: no quedan espacios de macro libres.";

-- Utility

-- Timers de Arena
L["ARENA_END_PREFIX"]            = "Arena: ";
L["TIMERS_TEST_HINT"]            = "Modo test de timers activado/desactivado. Manten\195\169 Alt y arrastr\195\161 para moverlos.";

-- Texto de Barras de Acci\195\179n

-- Subpesta\195\177as de Frames

-- Mover todo
L["MOVE_RESET_DONE"]             = "Todos los marcos volvieron a su posici\195\179n por defecto.";
L["MOVE_HELP_ALL"]               = "desbloquear todo";
L["MOVE_HELP_FRAMES"]            = "solo los marcos de unidad";
L["MOVE_HELP_LOCK"]              = "volver a bloquear";
L["MOVE_HELP_RESET"]             = "volver a las posiciones por defecto";
L["MOVER_HINT_SCALE"]            = "Ctrl + rueda del mouse sobre un recuadro para escalarlo";
L["MOVER_CONSOLE"]                = "Mover todo";
L["LBL_MOVE_GRID"]               = "Cuadr\195\173cula";
L["PARTYTEST_COMBAT"]            = "No se puede activar el modo prueba de party en combate.";
L["BTN_MOVE_RESET"]              = "Resetear";
L["MOVE_COMBAT_BLOCK"]           = "Las barras de acci\195\179n no se pueden mover en combate.";

-- Minimapa
L["MOD_MINIMAP_TOGGLE"]          = "Ocultar Iconos del Minimapa";
L["MOD_MINIMAP_TOGGLE_DESC"]     = "Boton en la esquina del minimapa que oculta o muestra los iconos de addon.";
L["MINIMAP_TOGGLE_TITLE"]        = "Iconos del Minimapa";
L["MINIMAP_TOGGLE_TIP"]          = "Click para ocultar o mostrar los iconos de addon. El zoom, el reloj y el calendario se eligen en Decorations.";
L["MINIMAP_TOGGLE_DISABLED"]     = "Activ\195\161 primero el m\195\179dulo Ocultar Iconos del Minimapa.";

L["BTN_MODULE_MOVE"]             = "Mover";
L["BTN_MODULE_LOCK"]             = "Bloquear";
L["BTN_MODULE_TOGGLE"]           = "Alternar";

-- Modulos nuevos
L["MOD_ARROWCOUNT"]              = "Contador de Flechas / Balas";
L["MOD_DUNGEONROLES"]            = "Roles del buscador de mazmorras";
L["MOD_DUNGEONROLES_DESC"]       = "Mientras estas en la cola, muestra tanque, sanador y 3 dps, y enciende los puestos que ya estan cubiertos. Alt + arrastrar para moverlo.";
L["MOD_ARROWCOUNT_DESC"]         = "Muestra cu\195\161nta munici\195\179n te queda. /arrowcount lock | unlock.";
L["MOD_POWERBAR"]                = "Barra de Recurso";
L["MOD_POWERBAR_DESC"]           = "Barra movible de man\195\161 / energ\195\173a / rabia / poder r\195\186nico al lado del personaje. Alt + arrastrar para moverla.";
L["BAR_WATER_ELE"]               = "Elemental de Agua";
L["BAR_MIRROR"]                  = "Im\195\161genes Espejo";
L["MOD_AUTOSHOT"]                = "Timer de Disparo Autom\195\161tico";
L["MOD_AUTOSHOT_DESC"]           = "Barra con el tiempo del disparo autom\195\161tico del cazador. /nufshot unlock para moverla.";
L["MOD_SWINGTIMER"]              = "Timer de Golpe Cuerpo a Cuerpo";
L["MOD_SWINGTIMER_DESC"]         = "Barra con el tiempo hasta tu pr\195\179ximo golpe blanco de melee. /nufswing unlock para moverla.";
L["SWING_LABEL"]                 = "Auto attack";
L["MOD_TURN_EVIL"]               = "Rastreador de Turn Evil";
L["MOD_TURN_EVIL_DESC"]          = "Muestra qui\195\169n est\195\161 bajo Turn Evil y cu\195\161nto le queda: mascotas de arena, invocaciones como la G\195\161rgola, y no-muertos o demonios en el mundo.";
L["MOD_PALADIN_AURAS"]           = "Paladin tracker";
L["MOD_PALADIN_AURAS_DESC"]      = "Proc de Holy Strength, reducci\195\179n de curaci\195\179n sobre cualquiera del grupo, y proc de The Art of War. /nufpal para moverlas.";
L["MOD_CLASSOUTLINE"]            = "Contorno del color de clase";
L["MOD_CLASSOUTLINE_DESC"]       = "Agrega un anillo del color de la clase alrededor de los retratos de jugador, objetivo y foco.";
L["SWING_USE_GLOBAL"]            = "Mover todo esta activo: arrastr\195\161 la caja azul desde ahi.";

-- Barras

-- Subpesta\195\177as

-- Color de Nombres

-- Chat
L["CHATCOPY_DISABLED"]           = "La copia del chat est\195\161 desactivada en las opciones.";
L["URL_POPUP_TEXT"]              = "Copi\195\161 el link (Ctrl+C):";

-- Module collapse

-- Tab 6 - About

-- === MINIMAP BUTTON ===
L["MINIMAP_TITLE"]               = "|cffffffffNidhaus|r |cffFFD100UnitFrames|r";
L["MINIMAP_LEFT_CLICK"]          = "|cffFFFFFFClick Izquierdo:|r Abrir Opciones";
L["MINIMAP_RIGHT_CLICK"]         = "|cffFFFFFFClick Derecho:|r Toggle Arena Mover";
L["MINIMAP_CTRL_CLICK"]          = "|cffFFFFFFCtrl + Click:|r Mover todo";
L["MINIMAP_SHIFT_CLICK"]         = "|cffFFFFFFShift + Click:|r Recargar UI";
L["MINIMAP_DRAG"]                = "|cffFFFFFFArrastrar:|r Mover icono";

-- === UNIFY ACTION BARS MODULE ===

-- === LISTA DE COMANDOS (/nuf help) ===
L["CMDLIST_GENERAL"] = "General";
L["CMDLIST_NUF"] = "Abrir el panel de opciones";
L["CMDLIST_NUF_HELP"] = "Esta lista";
L["CMDLIST_NUF_RESET"] = "Volver todo a los valores de f\195\161brica";
L["CMDLIST_CFG_DB"] = "Volcar al chat lo que hay guardado";
L["CMDLIST_CFG_SIZE"] = "Devolver el tama\195\177o de la ventana de opciones";
L["CMDLIST_MOVING"] = "Mover cosas";
L["CMDLIST_MOVE"] = "Move Everything (tambi\195\169n /move, /nufunlock)";
L["CMDLIST_SLOT"] = "Perfiles de barras y bindeos por personaje";
L["CMDLIST_PARTYTEST"] = "Grupo de prueba, para acomodar los marcos solo";
L["CMDLIST_FRAMES"] = "Marcos";
L["CMDLIST_PARTYSTYLE"] = "Estilo del marco de grupo: default | new | improved | pw | pw2";
L["CMDLIST_PW2"] = "Ventana de ajuste fino del estilo Compact 2";
L["CMDLIST_PTSTYLE"] = "Estilo cuadrado para los marcos de unidad";
L["CMDLIST_NAMES"] = "Color y borde del nombre";
L["CMDLIST_POWER"] = "Barra de poder";
L["CMDLIST_PPF"] = "Marcos de mascota del grupo (tambi\195\169n /partypetframe)";
L["CMDLIST_PTARGET"] = "Objetivos del grupo (tambi\195\169n /partytargets)";
L["CMDLIST_PBUFFS"] = "Buffs del grupo (tambi\195\169n /partybuffs)";
L["CMDLIST_PCB"] = "Barras de casteo del grupo (tambi\195\169n /partycastingbars)";
L["CMDLIST_ARENA"] = "Arena y PvP";
L["CMDLIST_TIMERS"] = "Tiempos de arena: fin de ronda, ca\195\177o, pilares";
L["CMDLIST_APC"] = "Calculadora de puntos de arena (tambi\195\169n /arenapts)";
L["CMDLIST_DUEL"] = "Bloquear duelos";
L["CMDLIST_SEDUC"] = "Aviso de seducci\195\179n de la s\195\186cubo";
L["CMDLIST_CLASS"] = "Clase";
L["CMDLIST_CLASS_T"] = "Tiempos de clase (elemental de agua, im\195\161genes especulares)";
L["CMDLIST_PAL"] = "Auras de palad\195\173n y Turn Evil";
L["CMDLIST_PALICD"] = "Cooldowns internos del palad\195\173n";
L["CMDLIST_SS"] = "Escudo sagrado (tambi\195\169n /sacredshield)";
L["CMDLIST_SST"] = "Rastreador de escudo sagrado";
L["CMDLIST_GT"] = "Rastreador de g\195\161rgola";
L["CMDLIST_COMBO"] = "Vig\195\173a de puntos de combo";
L["CMDLIST_SWING"] = "Temporizador de golpe cuerpo a cuerpo";
L["CMDLIST_SHOT"] = "Temporizador de disparo autom\195\161tico";
L["CMDLIST_AMMO"] = "Contador de munici\195\179n";
L["CMDLIST_PETBUFFS"] = "Buffs de la mascota del cazador";
L["CMDLIST_SWH"] = "Shield watch (tambi\195\169n /swh)";
L["CMDLIST_INTERFACE"] = "Interfaz";
L["CMDLIST_MAP"] = "Forma del minimapa: square | round";
L["CMDLIST_MMICON"] = "Mostrar u ocultar los iconos de addons";
L["CMDLIST_HIDEBAR"] = "Ocultar el arte de la barra de acci\195\179n";
L["CMDLIST_HCB"] = "Ocultar los botones del chat";
L["CMDLIST_COPY"] = "Copiar texto del chat";
L["CMDLIST_SPAM"] = "Filtro de mensajes del sistema";
L["CMDLIST_DTSU"] = "Texto de da\195\177o y curaci\195\179n";
L["CMDLIST_ND"] = "Texto de combate flotante (tambi\195\169n /nd)";
L["CMDLIST_HEADER"] = "comandos";
L["CMDLIST_OFF"] = "m\195\179dulo apagado";

-- === ARENA: OJO / DR / DOTS ===
L["HEADER_ARENA_DR"]             = "Diminishing Returns (DR)";
L["DR_MOVE_HINT"]                = "Vista previa: Shift+Alt+arrastrar los iconos para moverlos (se mueven los cinco marcos juntos).";
L["DR_PREVIEW_NEEDS_ARENA"]      = "la vista previa necesita el mod de marcos de arena (Arena > Frames).";
L["DR_NEED_ENABLE"]              = "activalo en Arena > DR.";
L["HEADER_ARENA_DOT"]            = "Aviso de DoTs";
L["DOT_NEED_ENABLE"]             = "activalo en Arena > DoT.";

-- === TEXTOS QUE ESTABAN FIJOS EN EL CODIGO (modulos, mensajes de comandos, modo mover) ===
L["ERR_IN_EVENT"]                = "Error en";
L["ERR_CONFIG_LOAD"]             = "Error al cargar la configuraci\195\179n:";
L["ARENA_MOVER_COMBAT"]          = "No se puede abrir el modo mover de arena en combate.";
L["MOD_ARENA_TIMES"]             = "Tiempos de arena";
L["MOD_ARENA_TIMES_DESC"]        = "Timer en el cartel de invitaci\195\179n a la arena + tiempo de cola al lado del minimapa.";
L["MOD_BUTTON_RANGE"]            = "Rango de botones";
L["MOD_BUTTON_RANGE_DESC"]       = "Pinta de rojo los botones de acci\195\179n fuera de rango.";
L["MOD_CLASS_ICONS"]             = "Iconos de clase";
L["MOD_CLASS_ICONS_DESC"]        = "Cambia los retratos por iconos de clase (default, modern, hs, ex)";
L["MOD_HIDE_BAR_TEX"]            = "Ocultar texturas de las barras";
L["MOD_HIDE_BAR_TEX_DESC"]       = "Oculta las texturas decorativas de las barras de acci\195\179n.";
L["MOD_HIDE_CHAT_BTN"]           = "Bot\195\179n para ocultar el chat";
L["MOD_HIDE_CHAT_BTN_DESC"]      = "Un bot\195\179n chiquito para ocultar o mostrar el chat.";
L["MOD_PARTYBUFFS_DESC"]         = "Buffs y/o debuffs extendidos (1-20 iconos) en los marcos del grupo. /pbuffs | /pbuffs reset";
L["MOD_SPEC_ICONS"]              = "Iconos de spec";
L["MOD_SPEC_ICONS_DESC"]         = "Detecta la spec del enemigo por el combat log. Muestra el icono en Target, Focus y los marcos de arena.";
L["CLASSICON_DEFAULT"]           = "Predeterminado";
L["CLASSICON_MODERN"]            = "Moderno";
L["CLASSICON_EX"]                = "Experim.";
L["SPEC_DB_MISSING"]             = "SpecIcons: no se carg\195\179 SpecDB.";
L["ARROW_RESET"]                 = "Contador de munici\195\179n - posici\195\179n y escala reiniciadas.";
L["ARROW_SCALE"]                 = "Contador de munici\195\179n - escala:";
L["REPAIR_NO_FUNDS"]             = "\194\161No te alcanza el oro para reparar!";
L["AUTOSHOT_UNLOCKED"]           = "Auto Shot - arrastr\195\161 la barra. /nufshot lock para fijarla.";
L["AUTOSHOT_LOCKED"]             = "Auto Shot - barra fijada.";
L["AUTOSHOT_SCALE"]              = "Auto Shot - escala:";
L["AUTOSHOT_RESET"]              = "Auto Shot - posici\195\179n y escala reiniciadas.";
L["SWING_UNLOCKED"]              = "Swing Timer - arrastr\195\161 la barra. /nufswing lock para fijarla.";
L["SWING_LOCKED"]                = "Swing Timer - barra fijada.";
L["SWING_SCALE"]                 = "Swing Timer - escala:";
L["SWING_RESET"]                 = "Swing Timer - posici\195\179n y escala reiniciadas.";
L["CMD_USAGE"]                   = "Uso:";
L["DUNGEONROLES_MOVE"]           = "Dungeon Roles - Alt + arrastrar para moverlo.";
L["HIDEBAR_HIDDEN"]              = "HideBar: texturas ocultas.";
L["HIDEBAR_VISIBLE"]             = "HideBar: texturas visibles.";
L["MINIBAR_CAPTURE_ERR"]         = "Error capturando el estado original:";
L["DTSU_MOVE_ON"]                = "modo mover activado, arrastr\195\161 el cuadro verde. /dtsu move de nuevo para fijarlo.";
L["DTSU_MOVE_OFF"]               = "anclaje fijado.";
L["DTSU_SHORT"]                  = "n\195\186meros cortos =";
L["SS_POS_RESET"]                = "Sacred Shield - posici\195\179n restaurada a la de la WeakAura.";
L["SST_POS_RESET"]               = "Sacred Shield Tracker - posici\195\179n restaurada.";
L["SED_POS_RESET"]               = "Alerta de Seducci\195\179n - posici\195\179n restaurada.";
L["SED_TEST"]                    = "Alerta de Seducci\195\179n - prueba. /seduction test otra vez o cambi\195\161 de zona para ocultarla.";
L["PAL_PREVIEW_ON"]              = "Paladin tracker + Turn Evil: arrastr\195\161 cada grupo. /nufpal para fijar. /nufpal debug para diagn\195\179stico.";
L["PAL_PREVIEW_OFF"]             = "Paladin tracker: posici\195\179n fijada.";
L["PB_NO_FRAME"]                 = "PartyMemberFrame1 no est\195\161 disponible. Us\195\161 /reload.";
L["PB_RESET_DONE"]               = "Listo: posiciones y escala restauradas.";
L["CMD_AVAILABLE"]               = "Comandos disponibles:";
L["PB_HELP_OPEN"]                = "Abre el panel de opciones y los recuadros para moverlos";
L["PB_HELP_RESET"]               = "Vuelve posiciones y escala a las de f\195\161brica";
L["PCB_ENABLE_FIRST"]            = "Primero prend\195\169 PartyCastingBars (/pcb enable).";
L["CMD_COMMANDS"]                = "comandos:";
L["PCB_HELP_NOARG"]              = "(sin argumento)";
L["PCB_HELP_OPEN"]               = "Abre la ventana de opciones";
L["PCB_HELP_DRAG"]               = "Prende/apaga el modo para mover las barras";
L["PCB_HELP_ICON"]               = "Muestra/oculta los iconos de hechizo";
L["PCB_HELP_SCALE"]              = "Cambia la escala de las barras";
L["PCB_HELP_PARENT"]             = "Pega/despega las barras de los marcos del grupo";
L["PCB_HELP_RESET"]              = "Vuelve las barras a su lugar";
L["PPF_CLICK_ON"]                = "Clic habilitado - click para seleccionar la mascota";
L["PPF_CLICK_OFF"]               = "Clic deshabilitado";
L["PPF_ARENA_ONLY"]              = "Solo en arenas";
L["PPF_EVERYWHERE"]              = "En todas partes";
L["PPF_POS_RESET"]               = "Posici\195\179n reiniciada";
L["CMD_COMMANDS_TITLE"]          = "Comandos:";
L["PPF_HELP_LOCK"]               = "Bloquear/desbloquear la fila";
L["PPF_HELP_CLICK"]              = "Habilitar/deshabilitar clic para seleccionar";
L["PPF_HELP_ARENA"]              = "Alternar entre solo arenas y todas partes";
L["PPF_HELP_RESET"]              = "Reiniciar la posici\195\179n de la fila";
L["PPF_HELP_DRAG"]               = "Arrastr\195\161 el marco de arriba: los otros tres lo siguen.";
L["PT_HELP_OPEN"]                = "Abrir el panel de opciones";
L["PT_RESET_CONFIRM"]            = "\194\191Volver todas las opciones de Party Targets a las de f\195\161brica?";
L["PT_CONFIG_OPEN"]              = "Opciones abiertas: arrastr\195\161 los marcos de objetivo para moverlos.";
L["POWERBAR_AURA_HIDDEN"]        = "no se muestra m\195\161s.";
L["POWERBAR_AURA_HINT"]          = "para volver a mostrarlas todas.";
L["POWERBAR_MOVE_ON"]            = "Power Bar - Alt + arrastrar para moverla. Click derecho en un aura para esconderla. Click de nuevo en Move para salir.";
L["POWERBAR_RESET"]              = "Power Bar - posici\195\179n reiniciada.";
L["POWERBAR_AURAS"]              = "Power Bar - se vuelven a mostrar todas las auras.";
L["POWERBAR_HELP"]               = "Power Bar - Alt + arrastrar para moverla.";
L["SPAM_FILTER"]                 = "filtro de spam de sistema";
L["SPAM_ON"]                     = "activo";
L["SPAM_OFF"]                    = "apagado";
L["SPAM_PATTERNS"]               = "patrones";
L["LORTI_GROUP_FRAMES"]          = "Marcos";
L["LORTI_GROUP_UI"]              = "Interfaz";
L["LORTI_RELOAD_NOTE"]           = "necesita /reload";
L["LORTI_COL_LORTI"]          = "Lorti";
L["LORTI_COL_COLOR"]          = "Color";
L["LORTI_Z_Player"]           = "Jugador";
L["LORTI_Z_Target"]           = "Objetivo";
L["LORTI_Z_Focus"]            = "Foco";
L["LORTI_Z_Party"]            = "Grupo";
L["LORTI_Z_PartyTargets"]     = "Objetivos del grupo";
L["LORTI_Z_PartyPet"]         = "Mascotas del grupo";
L["LORTI_Z_Arena"]            = "Arena";
L["LORTI_Z_CastBar"]          = "Barras de casteo";
L["LORTI_Z_ActionBars"]       = "Barras de acci\195\179n";
L["LORTI_Z_Minimap"]          = "Minimapa";
L["LORTI_Z_Buffs"]            = "Tus buffs";
L["LORTI_Z_Debuffs"]          = "Tus debuffs";
L["LORTI_ZTIP_Player"]        = "Tu marco y el de tu mascota, en cualquier estilo (Default, Light, Dark, Compact o Asuri). El marco de hielo del mago conserva sus colores.";
L["LORTI_ZTIP_Target"]        = "El marco del objetivo y el de su objetivo, en cualquier estilo.";
L["LORTI_ZTIP_Focus"]         = "El marco del foco y el de su objetivo, en cualquier estilo.";
L["LORTI_ZTIP_Party"]         = "Los 4 marcos del grupo, sus mascotas y el marco de veh\195\173culo, en cualquier estilo de grupo (Default, New, Improved o Compact).";
L["LORTI_ZTIP_PartyTargets"]  = "Los marcos de los objetivos del grupo.";
L["LORTI_ZTIP_PartyPet"]      = "Los marcos mejorados de las mascotas del grupo y el borde de su barra de casteo.";
L["LORTI_ZTIP_Arena"]         = "Los marcos de los enemigos de arena y los de sus mascotas.";
L["LORTI_ZTIP_CastBar"]       = "El borde de las barras de casteo: la tuya, la del objetivo y la del foco.";
L["LORTI_ZTIP_ActionBars"]    = "El arte de las barras de acci\195\179n (tambi\195\169n las de experiencia y reputaci\195\179n) y el contorno de los botones.";
L["LORTI_ZTIP_Minimap"]       = "El borde Lorti UI del minimapa, y el reloj. Es la misma opci\195\179n que Interface > Minimap > Border style: Lorti UI.\nAdem\195\161s: click derecho en el minimapa abre el calendario.";
L["LORTI_ZTIP_Buffs"]         = "Tus buffs (arriba a la derecha) y los encantamientos de arma: icono recortado, borde de Lorti y contorno. Los del objetivo y el foco quedan normales.";
L["LORTI_ZTIP_Debuffs"]       = "Tus debuffs: icono recortado y contorno. El borde conserva el color de la escuela (Magia, Maldici\195\179n, Veneno, Enfermedad).";
L["LORTI_COLOR_TIP"]          = "Tu propio color en vez de negro. Click en el cuadrito para elegirlo; click derecho, el color por defecto.";
L["LORTI_COLOR_OFF"]          = "Primero tild\195\161 'Lorti' en esta fila.";
L["LORTI_SWATCH_TIP"]         = "Click: elegir el color (se aplica al instante).\nClick derecho: volver al color por defecto.";
L["LORTI_ALL_COLOR"]          = "Mismo color a todo";
L["LORTI_ALL_COLOR_TIP"]      = "Pinta con este color todas las filas que tienen 'Lorti' tildada, y les tilda 'Color'. Cancelar en el selector deja todo como estaba.";
L["LORTI_DEFAULT_COLORS"]     = "Colores por defecto";
L["LORTI_DEFAULT_COLORS_TIP"] = "Todas las filas vuelven al negro de Lorti UI: destilda 'Color' y deja los colores en el celeste por defecto.";
L["LORTI_REQ_RELOAD"]            = "Requiere /reload";
L["MOD_LORTI_DESC"]           = "Aspecto Lorti UI: marcos, botones de acci\195\179n, minimapa y tus buffs en oscuro (o en tu color). Prender o apagar el m\195\179dulo necesita /reload.";
L["LORTI_MINIMAP_ERR"]           = "Error al iniciar el minimapa:";
L["MOVER_LBL_Player"]            = "Jugador";
L["MOVER_LBL_Target"]            = "Objetivo";
L["MOVER_LBL_Pet"]               = "Mascota";
L["MOVER_LBL_Party1"]            = "Grupo 1";
L["MOVER_LBL_Party2"]            = "Grupo 2";
L["MOVER_LBL_Party3"]            = "Grupo 3";
L["MOVER_LBL_Party4"]            = "Grupo 4";
L["MOVER_LBL_Buffs"]             = "Buffs";
L["MOVER_LBL_Debuffs"]           = "Debuffs";
L["MOVER_LBL_CastBar"]           = "Barra de casteo";
L["MOVER_LBL_MainBar"]           = "Barra de acci\195\179n 1";
L["MOVER_LBL_ActionBar2"]        = "Barra de acci\195\179n 2";
L["MOVER_LBL_ActionBar3"]        = "Barra de acci\195\179n 3";
L["MOVER_LBL_PetBar"]            = "Barra de mascota";
L["MOVER_LBL_StanceBar"]         = "Barra de posturas";
L["MOVER_LBL_TotemBar"]          = "Barra de t\195\179tems";
L["MOVER_LBL_PossessBar"]        = "Barra de posesi\195\179n";
L["MOVER_LBL_AutoShot"]          = "Disparo autom\195\161tico";
L["MOVER_LBL_SwingTimer"]        = "Ataque autom\195\161tico";
L["MOVER_LBL_PaladinICD"]        = "ICD de palad\195\173n";
L["MOVER_LBL_PalAuras"]          = "Rastreador de palad\195\173n";
L["MOVER_LBL_TurnEvil"]          = "Turn Evil";
L["MOVER_LBL_SacredShield"]      = "Sacred Shield";
L["MOVER_LBL_SSTracker"]         = "Rastreador de Sacred Shield";
L["MOVER_LBL_Seduction"]         = "Alerta de Seducci\195\179n";
L["MOVER_LBL_Gargoyle"]          = "G\195\161rgola";
L["MOVER_LBL_EnemyAlert"]        = "Alerta de hechizos";
L["MOVER_LBL_ArrowCount"]        = "Munici\195\179n";
L["MOVER_LBL_DungeonRoles"]      = "Roles de mazmorra";
L["MOVER_LBL_PartyCast"]         = "Casteo del grupo";
L["MOVER_LBL_PartyTarget"]       = "Objetivo del grupo";
L["MOVER_LBL_Minimap"]           = "Minimapa";
L["MOVER_LBL_BGScore"]           = "Puntuaci\195\179n del BG";
L["MOVER_LBL_CaptureBar"]        = "Barra de captura";
L["MOVER_LBL_DalaranPipe"]       = "Cascada de Dalaran";
L["MOVER_LBL_RoVPillars"]        = "Pilares de RoV";
L["MOVER_LBL_ArenaEnd"]          = "Tiempo de arena";
L["MOVER_LBL_ShadowSight"]       = "Ojo (Shadow Sight)";
L["MOVER_LBL_WaterEle"]          = "Elemental de agua";
L["MOVER_LBL_MirrorImg"]         = "Reflejo exacto";

end -- isSpanish