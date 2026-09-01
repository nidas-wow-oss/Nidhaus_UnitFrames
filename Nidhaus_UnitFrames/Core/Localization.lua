local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- Localization.lua - Sistema de localización EN/ES
--
-- Detecta el idioma del cliente WoW con GetLocale()
-- esES / esMX = Español, todo lo demás = English

local locale = GetLocale();
local isSpanish = (locale == "esES" or locale == "esMX");

-- ============================================================
-- ENGLISH (default)
-- ============================================================

-- Tags reutilizables
local INSTANT = "|cffFFD100\226\156\147 Applies instantly|r";
local RELOAD  = "|cffFFAA00\226\154\160 Requires /reload|r";

-- === TOOLTIPS ===
L["TIP_classColor"]              = "Colors health bars by class.";
L["TIP_statusbarBackdrop"]       = "Adds dark background to bars.\n\n"..RELOAD;
L["TIP_HealthPercentage"]        = "Shows health % on target.";
L["TIP_CastingTimers"]           = "Shows the remaining cast time in seconds on the player and target casting bars.";
L["TIP_SetPositions"]            = "Use addon custom positions.\n\nON: Custom positions (Settings.lua)\nOFF: Restore default positions saved at startup";
L["TIP_LockPositions"]           = "Lock frame positions.\n\nOFF: You can drag Player, Target and Party frames\nwith Shift + Alt + Left Click\nON: Frames are locked in place";
L["TIP_PartyIndividualMove"]     = "Move party frames individually.\n\nON: Each party member can be dragged separately\nOFF: All party frames move as a group";
L["TIP_PlayerFrameScale"]        = "Player frame scale.";
L["TIP_TargetFrameScale"]        = "Target frame scale.";
L["TIP_FocusScale"]              = "Focus frame scale.";
L["TIP_FocusSpellBarScale"]      = "Focus castbar scale.";
L["TIP_FocusAuraLimit"]          = "Limit focus auras.\n\n"..RELOAD;
L["TIP_PartyFrameOn"]            = "Enable party modifications.\n\n"..RELOAD;
L["TIP_PartyFrameScale"]         = "Party scale.";
L["TIP_PartyMemberFrameSpacing"] = "Party spacing.";
L["TIP_PartyMode3v3"]            = "Special 3v3 mode: Party 1-2 at 1.5 scale, Party 3-4 normal.\n\nRequires \"Use Custom Positions\" enabled.";
L["TIP_BossTargetFrameSpacing"]  = "Boss frame spacing.\n\n"..RELOAD;
L["TIP_ArenaFrameOn"]            = "Enable arena modifications.";
L["TIP_ArenaFrameScale"]         = "Arena scale.";
L["TIP_ArenaFrame_Trinkets"]     = "Arena trinkets.";
L["TIP_ArenaFrame_Trinket_Voice"] = "Trinket voice.";
L["TIP_ArenaMirrorMode"]         = "Flips arena frames: portrait on the left,\nbars on the right (mirror of party frames).";
L["TIP_ArenaFrameSpacing"]       = "Vertical spacing between arena frames.";
L["TIP_ArenaCustomTexture"]      = "Use custom textures on arena frames.\nDisable to restore Blizzard defaults.";
L["TIP_BossFrameScale"]          = "Boss frame scale.";
L["TIP_NewPartyFrame"]           = "Replaces party frame textures with a custom style.\n\n"..RELOAD;
L["TIP_PartyTargets"]            = "Shows who your party members are targeting.\nTarget-of-Target style compact frames.\nUse /ptarget for specific options.";
L["TIP_PartyBuffs"]              = "Shows extended buffs/debuffs on party frames.\nUse /pbuffs for specific options.";
L["TIP_PartyCastingBars"]       = "Shows a casting bar next to each party member's unit frame.\n\nUse /pcb (or /partycastingbars) for its own options: size, colors, icon and position.";
L["CB_PARTY_CASTBARS_SHORT"]    = "Party Castbars";
L["CB_PARTY_TARGETS_SHORT"]     = "Party Targets";
L["CB_NEW_PARTY_FRAME_SHORT"]   = "New Party";
L["CB_PARTY_BUFFS_SHORT"]       = "Party Buffs";

-- FLAT STYLE TOOLTIPS
L["TIP_ArenaFlatWidth"]          = "Total width of the flat arena frame.";
L["TIP_ArenaFlatHealthBarHeight"] = "Height of the health bar in flat mode.";
L["TIP_ArenaFlatPowerBarHeight"] = "Height of the power bar in flat mode.";
L["TIP_ArenaFlatHealthFontSize"] = "Font size for health bar text. Set to 0 to hide.";
L["TIP_ArenaFlatPowerFontSize"]  = "Font size for power bar text. Set to 0 to hide.";
L["TIP_ArenaFlatMirrored"]       = "Mirror flat frames: portrait on left, bars on right.";
L["TIP_ArenaFlatStatusText"]     = "Force health/mana text to always show in flat mode.\nIf disabled, respects Interface > Status Text settings.";

-- CAST BAR TOOLTIPS
L["TIP_ArenaCastBarEnable"]      = "Enable custom cast bar scaling and width.\nDisable to use Blizzard default size.";
L["TIP_ArenaCastBarScale"]       = "Cast bar scale.";
L["TIP_ArenaCastBarWidth"]       = "Cast bar width.";

-- === OPTIONS PANEL ===
L["PANEL_TITLE"]                 = "Nidhaus UnitFrames";
L["PANEL_VERSION"]               = "|cffFFAA00v3.6|r";
L["PANEL_SUBTITLE"]              = "Unit Frame Customization & Arena Tools";
L["PANEL_SIZE_RESET"]            = "Options window restored to 820x620 and centered.";

-- Tabs
L["TAB_GENERAL"]                 = "Interface";
L["TAB_FRAMES"]                  = "Frames";
L["TAB_ARENA"]                   = "Arena";
L["TAB_ARENA_BOSS"]              = "Arena/Boss";
L["TAB_MODULES"]                 = "Modules";

-- ── Pestañas y secciones nuevas (rediseño estilo TidyPlates) ──
L["CB_BLOCK_DUELS"]              = "Decline Duels";
L["TIP_BlockDuels"]              = "Automatically declines any duel request and closes the popup. Useful in cities and outside arena gates.";
L["DUEL_BLOCKED"]                = "Duel from %s declined.";
L["DUEL_BLOCK_ON"]               = "Duels are now declined automatically.";
L["DUEL_BLOCK_OFF"]              = "Duels are allowed again.";
L["HEADER_FRAMES_MIRROR"]        = "Unit Frames";
L["NOTE_FRAMES_MIRROR"]          = "Same two options as in the Frames tab: change one and the other follows.";
L["PVP_HUD"]                     = "Combat HUD";
L["PVP_HUD_NOTE"]                = "Bars that sit next to your character so you do not have to look at the unit frames.";
L["CB_POWERBAR_COMBAT"]          = "Only show it in combat";
L["CB_POWERBAR_PCT"]             = "Show percentage instead of current / max";
L["CB_POWERBAR_HEALTH"]          = "Also show a health bar";
L["CB_POWERBAR_GRADIENT"]        = "Health bar changes color as it drops";
L["TIP_PowerBarGradient"]        = "The health bar goes green > yellow > red as you lose health, so you notice it out of the corner of your eye.";
L["CB_POWERBAR_HIDEFULL"]        = "Hide it when full out of combat";
L["TIP_PowerBarHideFull"]        = "Hides the bar while you are at full health and resource outside combat. It comes back on its own.";
L["TIP_PowerBarHealth"]          = "Adds a health bar above the resource bar, so the Power Bar works like a mini player frame.";
L["TIP_PowerBarCombatOnly"]      = "Hides the power bar out of combat so it does not clutter the screen.";
L["SIDEGRP_COMBAT"]              = "Combat";
L["CB_LOCK_CLASS_BARS"]          = "Lock the bars";
L["TIP_ClassTimersLocked"]       = "Locked: the bars ignore the mouse, so you can click through them. Unlocked: drag them with the left mouse button.";
L["BTN_SHOW_BARS"]               = "Show to position";
L["BTN_HIDE_BARS"]               = "Hide";
L["CLASSTIMERS_PREVIEW_ON"]      = "Class bars shown. Drag them, then /nufclass hide.";
L["CLASSTIMERS_RESET"]           = "Class bar positions reset.";
L["CB_MINIMAP_HIDE_ZONEBG"]      = "Hide Zone Name Background";
L["CB_MINIMAP_HIDE_ICONS"]       = "Hide addon icons";
L["MOD_PFI"]                     = "Party Frames Improved";
L["MOD_PFI_DESC"]                = "Wider, cleaner texture for the party frames, with smaller name / health / mana text and a bigger health bar.";
L["MOD_SHIELDWATCH"]             = "ShieldWatch";
L["MOD_SHIELDWATCH_DESC"]        = "Bar showing how much is left on your magic shields and barriers, with a warning when they are about to break. /shieldwatch options to configure it.";
L["MOD_ABBREV_STATUS"]           = "Abbreviated Status Text";
L["MOD_ABBREV_STATUS_DESC"]      = "Shortens the health/mana numbers on unit frames (12.3k instead of 12345) and can show the percentage next to them.";
L["MOD_DTSU"]                    = "DTSU - Damage Tracker";
L["MOD_DTSU_DESC"]               = "Floating icons with your outgoing swing / spell / dot damage (total, last hit, hits). /dtsu move to reposition.";
L["MOD_PALADIN_ICD"]             = "Paladin ICD";
L["MOD_PALADIN_ICD_DESC"]        = "Visual internal cooldown of your paladin defensives (Divine Protection, Divine Shield, Hand of Protection, Avenging Wrath, Lay on Hands). /paladinicd to move it.";
L["HEADER_STATUS_TEXT"]          = "|cffFFD100Status Text|r";
L["CB_ABBREV_STATUS"]            = "Abbreviated health / mana text";
L["TIP_ABBREV_STATUS"]           = "Shortens the numbers on the unit frame bars. Click Open to set it up per unit (health, mana, percentage, position).";
L["ABBREV_DECIMALS"]             = "Decimals";
L["ABBREV_FROM"]                 = "Abbreviate from";
L["ABBREV_RESET"]                = "Restore defaults";
L["ABBREV_ON"]                   = "On";
L["ABBREV_POS_NOTE"]             = "Move the health / mana texts of the selected unit.";
L["ABBREV_POS_THEME"]            = "Theme";
L["NOTE_FOCUS_SPELLBAR"]         = "Focus cast bar scale lives in Interface > Cast Bar.";
L["PANEL_LOAD_FAIL"]             = "Could not load the options panel";
L["PANEL_LOAD_HINT"]             = "Check that the Nidhaus_UnitFrames_Config folder sits next to the addon folder and is enabled in the addon list.";
L["MOD_PARTYPETFRAME"]           = "Party pet enhanced";
L["MOD_PARTYPETFRAME_DESC"]      = "Custom frame for the pet of your first party member: portrait, health and mana, cast bar and CC warning.";
L["CB_PARTY_PETS_HIDE"]          = "Hide party pet frames";
L["CB_PARTY_PETS"]               = "Show party pet frames";
L["TIP_PartyPets"]               = "The small frames for your party members pets (hunter, warlock, DK...). Turning them off cleans up the screen in arena.";
L["HEADER_PARTY_STYLE"]          = "Frame Style";
L["NOTE_PARTY_STYLE"]            = "Pick one. The two custom styles retexture the same frames, so they cannot be on at the same time.";
L["PARTY_STYLE_DEFAULT"]         = "Blizzard";
L["PARTY_STYLE_NEW"]             = "New Party";
L["PARTY_STYLE_IMPROVED"]        = "Improved";
L["PARTY_STYLE_PW"]              = "Big Blizzard";
L["PARTY_STYLE_PW2"]             = "Compact 2";
L["PARTY_STYLE_CURRENT"]         = "current";
L["TIP_PartyStyle_Default"]      = "Leaves the party frames exactly as Blizzard made them.";
L["TIP_PartyStyle_New"]          = "NewPartyFrame: custom style with reworked bars and layout.";
L["TIP_PartyStyle_Improved"]     = "PartyFramesImproved: wider, cleaner texture with smaller text and a bigger health bar.";
L["MOD_COMBOWATCH"]              = "Combo Points";
L["MOD_COMBOWATCH_DESC"]         = "Big combo point counter, colored by amount, with a pulsing frame when you hit 5.";
L["PVP_COMBO"]                   = "Combo Points";
L["CB_LOCK_COMBO"]               = "Lock it in place";
L["TIP_ComboWatchLocked"]        = "Locked: it ignores the mouse, so you can click through it. Unlocked: drag it with the left mouse button.";
L["COMBOWATCH_WRONG_CLASS"]      = "Only rogues and druids generate combo points.";
L["PVP_ROGUE_POISON"]            = "Poison timers";
L["PVP_ROGUE_VANISH"]            = "Vanish / Sprint ready";
L["PVP_DRUID_FORM"]              = "Active form indicator";
L["PVP_DRUID_HOTS"]              = "HoT tracker";
L["HEADER_PARTY_TRINKET"]        = "Party Trinkets";
L["NOTE_PARTY_TRINKET"]          = "PvP trinket cooldown next to each party member. Independent from the arena tracking, and the position is shared by all four.";
L["CB_PARTY_TRINKETS"]           = "Show party trinkets";
L["TIP_PartyTrinkets"]           = "Shows the PvP trinket cooldown of each party member. Works in arena and in battlegrounds.";
L["BTN_MOVE_TRINKETS"]           = "Move them";
L["BTN_LOCK_TRINKETS"]           = "Done";
L["SLIDER_PARTY_TRINKET_SIZE"]   = "Trinket Size";
L["NOTE_PARTY_SUBADDONS"]        = "Commands: /pbuffs, /ptarget, /pcb";
L["MOD_PETBUFFS"]                = "Pet Buffs";
L["MOD_PETBUFFS_DESC"]           = "Icons under the pet frame for Mend Pet, Cower and Last Stand, with their remaining duration.";
L["PVP_HUNTER_PETSECTION"]       = "Pet";
L["CB_LOCK_PETBUFFS"]            = "Lock them in place";
L["TIP_PetBuffsLocked"]          = "Locked: the icons ignore the mouse, so you can click through them. Unlocked: drag the row with the left mouse button.";
L["SLIDER_PETBUFF_SIZE"]         = "Icon Size";
L["SLIDER_SCALE"]                = "Scale";
L["HEADER_TIMER_SCALES"]         = "|cffFFD100Timer size|r";
L["SCALE_COUNTDOWN"]             = "Countdown";
L["SCALE_DALARAN"]               = "Dalaran";
L["SCALE_ROV"]                   = "Ring of Valor";
L["SLIDER_SWING_SCALE"]          = "Scale";
L["SLIDER_ICONS_PER_ROW"]        = "Icons per row";
L["NOTE_ICONS_PER_ROW"]          = "How many buff icons fit in one row before wrapping to the next.";
L["SLIDER_POWERBAR_SCALE"]       = "Scale";
L["SLIDER_POWERBAR_WIDTH"]       = "Width";
L["SLIDER_POWERBAR_HEIGHT"]      = "Bar height";
L["PETBUFFS_WRONG_CLASS"]        = "This module is only for hunters.";
L["SIDE_BOSS"]                   = "Boss";
L["SIDE_PET"]                    = "Pet";
L["HEADER_PET"]                  = "Pet Frame";
L["NOTE_PET"]                    = "Scale of your pet frame (hunter, warlock, mage water elemental, death knight ghoul).";
L["SLIDER_PET_SCALE"]            = "Pet Frame Scale";
L["TAB_ADDONS"]                  = "Addons";
L["TAB_PVP"]                     = "PvP";
L["TAB_PROFILES"]                = "Profiles";

L["SIDE_GENERAL"]                = "General Settings";
L["SIDE_GENERAL_HINT"]           = "Affects everything";
L["SIDE_ACTIONBARS"]             = "Action Bars";
L["SIDE_MINIMAP"]                = "Minimap";
L["SIDE_CHAT"]                   = "Chat";
L["SIDE_CASTBAR"]                = "Cast Bar";
L["SLIDER_ARENA_TOT_SCALE"]      = "Target of Target Scale";
L["CB_ARENA_TOT_CLASSICON"]      = "Class Icon";
L["CB_ARENA_TOT_MIRROR"]         = "Mirror Frame";
L["CB_ARENA_TOT_SQUARE"]         = "Square Style";
L["TIP_ArenaToTSquare"]          = "Square portrait with the class icon, the same look Party Targets uses.";
L["PCB_TITLE"]                   = "Party Cast Bars";
L["PCB_SCALE_LABEL"]             = "Bar scale:";
L["PCB_CB_ICONS"]                = "Show spell icons";
L["PCB_CB_PARENT"]               = "Attach bars to party frames";
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
L["HEADER_AURA_BORDERS"]         = "|cffFFD100Target and Focus Auras|r";
L["CB_AURA_BORDERS"]             = "Custom aura borders";
L["CB_AURA_PURGE"]               = "Highlight purgeable buffs";
L["NOTE_AURA_BORDERS"]           = "Thin border on every buff and debuff icon, coloured by school: Magic blue, Curse purple, Poison green, Disease brown.";
L["TIP_AuraBordersEnabled"]      = "Crops the spell icon and gives it a thin border. Debuffs take the colour of their school, replacing Blizzard's thick ring.";
L["TIP_AuraBordersPurge"]        = "Glow around the enemy's Magic buffs, the ones a purge or a dispel can remove.";
L["SIDE_MOVEALL"]                = "Move Everything";
L["HEADER_CASTBAR"]              = "|cffFFD100Cast Bar|r";
L["CB_CASTBAR_PW"]               = "Custom Cast Bar";
L["CB_CASTBAR_PW_ICON"]          = "Show spell icon";
L["CB_CASTBAR_PW_DARK"]          = "Dark border";
L["CB_CASTBAR_PW_TARGET"]        = "Apply to target";
L["CB_CASTBAR_PW_FOCUS"]         = "Apply to focus";
L["SLIDER_CASTBAR_PW_SIZE"]      = "Icon Size";
L["SLIDER_CASTBAR_PW_SCALE"]     = "Cast Bar Scale";
L["NOTE_CASTBAR_PW"]             = "Replaces the border, flash and shield of the player, target and focus casting bars, and shows the spell icon above the bar.";
L["TIP_CastBarPWEnabled"]        = "New look for the three casting bars: custom border, flash and non-interruptible shield, plus the spell icon.";
L["TIP_CastBarPWIcon"]           = "Shows the spell icon. On the player bar it floats above the centre; on target and focus it stays beside the bar.";
L["TIP_CastBarPWIconSize"]       = "Size of the player spell icon. The target and focus icons follow proportionally.";
L["TIP_CastBarPWDark"]           = "Tints the border grey. Turn it off to see the texture at its normal brightness.";
L["TIP_CastBarPWTarget"]         = "Applies the custom cast bar style to your target's bar. Off leaves it as Blizzard's.";
L["TIP_CastBarPWFocus"]          = "Applies the custom cast bar style to your focus' bar. Off leaves it as Blizzard's.";
L["SIDE_TOOLTIP"]                = "Tooltip";
L["HEADER_TOOLTIP"]              = "Tooltip";
L["CB_TOOLTIP_ARENA_EXP"]        = "Arena experience";
L["NOTE_TOOLTIP_ARENA_EXP"]      = "Adds the player's highest personal arena rating (2v2, 3v3, 5v5) to their tooltip. Read from achievement statistics, so it only works on players who have them.";
L["CB_TOOLTIP_TALENTS"]          = "Show talents";
L["NOTE_TOOLTIP_TALENTS"]        = "Adds the target's main talent tree and point spread. Needs an inspect, so the first read may take a moment; results are cached.";
L["CB_TOOLTIP_QUALITY"]          = "Item quality border";
L["CB_TOOLTIP_ICONS"]            = "Show tooltip icons";
L["NOTE_TOOLTIP_ICONS"]          = "Puts the item or spell icon next to its name, in the first line of the tooltip.";
L["TIP_TooltipIcons"]            = "Shows the icon of the item or spell at the start of the tooltip.";
L["NOTE_TOOLTIP_QUALITY"]        = "Colors the tooltip border with the item quality color, from uncommon upwards.";
L["TOOLTIP_NO_TALENT"]           = "No talents";
L["TOOLTIP_LOADING"]             = "Loading...";
L["TIP_TooltipArenaExp"]         = "Compares achievement statistics to read the rating. It queries the server, so it is skipped in combat.";
L["TIP_TooltipTalents"]          = "Based on TipTacTalents. Skipped while the inspect window is open.";
L["TIP_TooltipQualityBorder"]    = "Only from uncommon (green) upwards: grey and white items keep the normal border.";
L["CB_AURA_CAST_BY"]             = "Show who cast the aura";
L["SLIDER_BUTTON_SPACE"]         = "Buttons space";
L["CB_MINIMAP_THINBORDER"]         = "Light Border";
L["ARENA_STYLE_COMPACT"]         = "Borderless";
L["ARENA_STYLE_COMPACT2"]        = "Compact";
L["MOD_SACREDSHIELD"]            = "Sacred Shield (target)";
L["MOD_SACREDSHIELD_DESC"]       = "Shows the Sacred Shield timer on your target.";
L["MOD_SS_TRACKER"]              = "Sacred Shield tracker (group)";
L["MOD_SS_TRACKER_DESC"]         = "Tracks Sacred Shield on every group member.";
L["MOD_SEDUCTION"]               = "Seduction on you (arena)";
L["MOD_SEDUCTION_DESC"]          = "Warns when a Succubus seduces you in arena.";
L["MOD_SYSTEM_SPAM"]             = "Hide system spam";
L["MOD_SYSTEM_SPAM_DESC"]        = "Filters repetitive system messages out of the chat.";
L["CB_TAB_BINDER"]               = "Tab targets enemy players in PvP";
L["CB_MINIBAR_NO_BG"]            = "Hide bar background";
L["TIP_MiniBarHideBackground"]   = "Hides the MainMenuBar artwork behind the buttons, plus the experience and reputation bar art. The gryphons have their own option.";
L["TIP_TabBinderEnabled"]        = "In arenas, battlegrounds and contested zones, your target key switches to nearest enemy PLAYER, so Tab stops grabbing pets, totems and critters. It reverts on its own when you leave. Rebinds the real key, so it will not change during combat: it waits until you drop out of it.";
L["MOVE_AURA_BAR"]               = "Aura Bar";
L["MOVE_PRESENCE_BAR"]           = "Presence Bar";
L["MOVE_FORM_BAR"]               = "Form Bar";
L["MOVE_STANCE_BAR"]             = "Stance Bar";
L["TIP_MinimapThinBorder"]         = "Replaces the plain square border with a thin, clean one. Square shape only.";
L["NOTE_AURA_CAST_BY"]           = "Adds a line to buff and debuff tooltips with the name of whoever cast it, colored by class or faction.";
L["TOOLTIP_CAST_BY"]             = "Cast by:";
L["TIP_AuraCastBy"]              = "Works on any buff or debuff icon, Blizzard's or NUF's. Pet auras also show their owner.";
L["TIP_CastBarPWScale"]          = "Scale of the player and target casting bars. The focus bar has its own slider under Frames.";
L["SIDE_PTF"]                    = "General";
L["SIDE_PARTY"]                  = "Party";
L["SIDE_AURAS"]                  = "Buffs and Debuffs";
L["SIDE_PVE"]                    = "Pet and Boss";
L["SIDE_CLASSOPT"]               = "Class Options";
L["SIDE_CLASSOPT_HINT"]          = "Detected automatically";
L["SIDE_ENEMY"]                  = "Enemies";
L["SIDE_SELF"]                   = "Yourself";


L["HEADER_APPEARANCE"]           = "Appearance";
L["HEADER_BAR_STYLE"]            = "Bar Style";
L["HEADER_BAR_TEXT"]             = "Text and Feedback";
L["HEADER_BAR_SIZE"]             = "Size";
L["HEADER_SCALES"]               = "Scale";
L["HEADER_PARTY_PETS"]          = "|cffAAAAAA\226\128\148 Pets \226\128\148|r";
L["HEADER_PARTY_MODE"]           = "Mode";
L["HEADER_AURAS"]                = "Player Buffs and Debuffs";
L["DESC_AURAS"]                  = "Unlock to drag the buff and debuff blocks anywhere on the screen.";
L["NOTE_MIRRORED"]               = "These three are the same options as in the Action Bars section: change one and the other follows.";
L["NOTE_EXTRA_MOVED"]            = "Auto repair, sell junk and the chat options moved to Interface > General Settings and Interface > Chat.";

L["HEADER_MINIMAP_SHAPE"]        = "Shape";
L["HEADER_MINIMAP_BORDER"]       = "Border";
L["DD_MINIMAP_BORDER"]           = "Border style";
L["MINIMAP_BORDER_DEFAULT"]      = "Default";
L["MINIMAP_BORDER_LIGHT"]        = "Light";
L["MINIMAP_BORDER_TOOLTIP"]      = "Tooltip";
L["MINIMAP_BORDER_THIN"]         = "Thin";
L["MINIMAP_BORDER_FLAT"]         = "Flat";
L["MINIMAP_BORDER_BLIZZARD"]     = "Blizzard";
L["NOTE_MINIMAP_BORDER"]         = "Tooltip, Thin, Flat and Blizzard work with both shapes.";
L["NOTE_MINIMAP_BORDER_SQUARE"]  = "Light only works with the square shape.";
L["HEADER_MINIMAP_DECOR"]        = "Decorations";
L["HEADER_MINIMAP_ICONS"]        = "Addon Icons";
L["HEADER_MINIMAP_SIZE"]         = "Size";
L["MINIMAP_ROUND"]               = "Round";
L["MINIMAP_SQUARE"]              = "Square";
L["CB_MINIMAP_HIDE_ZONE"]        = "Hide Zone Name";
L["CB_MINIMAP_HIDE_CLOCK"]       = "Hide Clock";
L["CB_MINIMAP_HIDE_ZOOM"]        = "Hide Zoom Buttons";
L["CB_MINIMAP_HIDE_CALENDAR"]    = "Hide Calendar";
L["CB_MINIMAP_HIDE_WORLDMAP"]    = "Hide World Map";
L["CB_MINIMAP_WHEEL"]            = "Mouse Wheel Zoom";
L["SLIDER_MINIMAP_SCALE"]        = "Minimap Scale";
L["NOTE_MINIMAP_ICONS"]          = "Adds a small button on the minimap corner that hides or shows every addon icon at once.";

L["CB_HIDE_CHAT_BUTTON"]         = "Hide Chat Buttons";

L["SUBTAB_ARENA_OPTIONS"]        = "Options";
L["SUBTAB_ARENA_POINTS"]         = "Arena Points";
L["SUBTAB_ARENA_TIMERS"]         = "Timers";
L["HEADER_ARENA_POINTS"]         = "Arena Points";
L["MOD_APC"]                     = "Arena Points Calculator";
L["MOD_APC_DESC"]                = "Calculates the arena points you will get each week from your rating. /apc to open it.";
L["BTN_APC_OPEN"]                = "Open the calculator";
L["BTN_MODULE_OPEN"]             = "Open";

L["BTN_PARTY_TEST"]              = "Test mode (4 fake members)";
L["BTN_MOVE_AURAS"]              = "Unlock buffs / debuffs";
L["BTN_MOVE_BARS"]               = "Move the bars";
L["BTN_LOCK_BARS"]               = "Lock the bars";

L["PVP_DETECTED"]                = "Detected class:";
L["PVP_DETECTED_SUB"]            = "Only the modules your class can actually use are shown here.";
L["PVP_NO_CLASS_MODULES"]        = "There are no class specific modules for this class yet. The list grows as they get added.";
L["PVP_SOON"]                    = "coming soon";
L["PVP_SOON_HEADER"]             = "Planned";
L["PVP_TIMERS"]                  = "Timers";
L["PVP_SHOOTING"]                = "Shooting";
L["PVP_MELEE"]                   = "Melee";
L["PVP_MAGE_CS"]                 = "Counterspell ready alert";
L["PVP_MAGE_HS"]                 = "Hot Streak charge counter";
L["PVP_MAGE_APPEARANCE"]         = "Appearance";
L["CB_MAGE_ICY"]                 = "Icy player frame";
L["TIP_MageIcy"]                 = "Frost / ice skin for your player frame. Works on its own, no other option needed.";
L["PVP_HUNTER_ASPECT"]           = "Active aspect indicator";
L["PVP_HUNTER_PET"]              = "Pet buffs";
L["PVP_HUNTER_TRAP"]             = "Trap ready alert";
L["PVP_WARRIOR_PROCS"]           = "Overpower / Revenge available";
L["PVP_WARRIOR_STANCE"]          = "Stance reminder";
L["PVP_PALADIN_DEF"]             = "Defensives";
L["PVP_PALADIN_ICD_NOTE"]        = "The icon goes gray while the internal cooldown is running and turns back to color when it is ready (Divine Protection, Divine Shield, Hand of Protection, Avenging Wrath, Lay on Hands).";
L["CB_PALADIN_ICD_KEEP"]         = "Keep it on screen when ready";
L["TIP_PaladinICDKeep"]          = "Leaves the icon visible in color once the cooldown is over, so you can see at a glance that it is up. Otherwise it hides until you use it again.";
L["PVP_PALADIN_WINGS"]           = "Wings / bubble ready alert";
L["BTN_MOVE_IT"]                 = "Move it";
L["BTN_LOCK_IT"]                 = "Lock it";
L["PVP_ENEMY_HEADER"]            = "Enemy awareness";
L["PVP_ENEMY_NOTE"]              = "What the enemy is doing. The arena frames already show their trinket.";
L["BTN_SPELL_LIST"]              = "Spell list";
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
L["GARG_MODE"]                   = "Style";
L["GARG_MODE_BLIZZ"]             = "Blizzard";
L["GARG_MODE_CUSTOM"]            = "Custom";
L["GARG_WHERE"]                  = "Show it in:";
L["GARG_ARENA"]                  = "Arena";
L["GARG_BG"]                     = "Battlegrounds";
L["GARG_DUEL"]                   = "Duels";
L["GARG_WORLD"]                  = "Open world";
L["BTN_TEST_MODE"]               = "Test mode";
L["MOD_ENEMYALERT"]              = "Enemy Spell Alert";
L["MOD_ENEMYALERT_DESC"]         = "Shows the spell icon on screen when an enemy casts a trap, fear or interrupt.";
L["PVP_ENEMYALERT_NOTE"]         = "Shows the spell icon on screen when an enemy casts a trap, fear or interrupt. Use \"Spell list\" to pick which ones.";
L["CB_LOCK_ENEMYALERT"]          = "Lock it in place";
L["TIP_EnemyAlertLocked"]        = "While locked it ignores the mouse: you can click through it.";
L["PVP_ENEMY_CD"]                = "Enemy defensive cooldown tracker";
L["PVP_ENEMY_DISPEL"]            = "Dispel / purge received alert";
L["PVP_ENEMY_RES"]               = "Enemy resurrection alert";
L["PVP_SELF_HEADER"]             = "Your own state";
L["PVP_SELF_NOTE"]               = "Reminders about your own cooldowns and crowd control.";
L["PVP_SELF_CC"]                 = "Crowd control timer on yourself";
L["PVP_SELF_DR"]                 = "Diminishing returns bar";
L["PVP_SELF_BUFFS"]              = "Missing buffs reminder at the gates";
L["TIP_MageWaterEle"]            = "Duration bar for the Water Elemental. Hidden automatically if you have the Glyph of Eternal Water, since the pet is permanent.";
L["TIP_MageMirror"]              = "30 second duration bar for Mirror Image.";

L["TAB_EXTRA"]                   = "Profiles";
L["TAB_ABOUT"]                   = "About";

-- Tab 1 - General
L["HEADER_GENERAL"]              = "|cffFFD100General Settings|r";
L["DESC_GENERAL"]                = "Basic visual options and frame positioning";
L["CB_CLASS_COLOR"]              = "Class Color Health Bars";
L["CB_BACKDROP"]                 = "Statusbar Backdrop";
L["CB_HEALTH_PCT"]               = "Health Percentage";
L["CB_CASTING_TIMERS"]           = "Casting Bar Timers";
L["HEADER_POSITIONS"]            = "|cffFFD100Frame Positions & Draggable|r";
L["POS_HINT_ENABLE"]            = "|cffFFCC44Enable Custom Positions|r |cffAAAAAAto move Player, Target & Party frames.|r";
L["POS_HINT_DRAG"]              = "|cff6699FFShift+Alt+Click|r |cffAAAAAAto drag a frame.|r";
L["CB_CUSTOM_POS"]               = "Use Custom Positions";
L["CB_LOCK_POS"]                 = "Lock Positions";
L["CB_PARTY_INDIVIDUAL"]         = "Move Party Individually";
L["CB_PARTY_3V3"]                = "Party Mode 3v3";
L["HEADER_THEME"]                = "|cffFFD100Visual Theme|r";
L["DRAG_HINT"]                   = "|cffAAAAAA(Shift+Alt+Click to drag frames)|r";
L["BTN_RESET_POS"]               = "Reset Positions & Scale";
L["RESET_POS_DONE"]              = "Positions & scale reset!";
L["RESET_POS_CONFIRM"]           = "Reset all frame positions and scale to defaults?\n\n|cffFFAA00This won't reload your UI.|r";
L["RESET_POS_BTN_YES"]           = "Reset";
L["RESET_POS_BTN_NO"]            = "Cancel";
L["THEME_DARK"]                  = "Current theme: |cff888888Dark|r";
L["THEME_LIGHT"]                 = "Current theme: |cffEEEEEELight|r";
L["THEME_HINT"]                  = "To change theme: Edit |cffFFD100Config/Settings.lua|r (C[\"darkFrames\"]) and /reload";

-- Tab 2 - Frames
L["HEADER_FRAMES"]               = "|cffFFD100Frame Settings|r";
L["DESC_FRAMES"]                 = "Adjust scale and spacing for player/target/party frames";
L["SLIDER_PLAYER_SCALE"]         = "Player Frame Scale";
L["SLIDER_TARGET_SCALE"]         = "Target Frame Scale";
L["HEADER_FOCUS"]                = "|cffFFD100Focus|r";
L["SLIDER_FOCUS_SCALE"]          = "Focus Scale";
L["SLIDER_FOCUS_SPELLBAR"]       = "Focus Cast Bar Scale";
L["HEADER_PARTY"]                = "|cffFFD100Party|r";
L["HEADER_PARTY_FEATURES"]      = "|cffAAAAAA\226\128\148 Party Features \226\128\148|r";
L["CB_PARTY_BUFFS"]              = "Party Buffs";
L["CB_PARTY_TARGETS"]            = "Party Targets";
L["SLIDER_PARTY_SCALE"]          = "Party Frame Scale";
L["SLIDER_PARTY_SPACING"]        = "Party Member Spacing";

-- Missing keys for Frames/General panels
L["CB_NEW_PARTY_FRAME"]          = "New Party Frame";
L["SLIDER_BOSS_SCALE"]           = "Boss Frame Scale";
L["SLIDER_ACTIONBAR_SCALE"]      = "Action Bar Scale";
L["CB_MINIBAR"]                  = "MiniBar";
L["CB_HIDE_GRYPHONS"]            = "Hide Gryphons";
L["CB_BAGPACK"]                  = "BagPack Background";

-- Tab 3 - Arena
L["HEADER_ARENA_BOSS"]           = "|cffFFD100Arena & Boss Settings|r";
L["DESC_ARENA_BOSS"]             = "PvP and PvE encounter frame settings";
L["HEADER_BOSS"]                 = "|cffFFD100Boss Frames|r";
L["SLIDER_BOSS_SPACING"]         = "Boss Frame Spacing";
L["HEADER_ARENA"]                = "|cffFFD100Arena Frames|r";
L["DESC_ARENA"]                  = "PvP arena frame settings";
L["CB_ARENA_ON"]                 = "Enable Arena Frame Mod";
L["CB_ARENA_CUSTOM_TEX"]         = "Arena Custom Texture";
L["LABEL_ARENA_STYLE"]           = "Arena Style";
L["SLIDER_ARENA_SCALE"]          = "Arena Frame Scale";
L["SLIDER_ARENA_SPACING"]        = "Arena Frame Spacing";
L["BTN_SHOW_ARENA"]              = "Show Arena Frame";
L["BTN_SHOW_BOSS"]               = "Show Boss Frame";
L["BTN_RESET_FLAT"]              = "Reset";
L["ARENA_HINT"]                  = "Use |cff00FFFF/nuf arena|r\nto show/hide\nthe arena mover";
L["ARENA_MOVE_HINT"]             = "|cffFFAA00\226\128\160Shift+Alt+Click to move various elements|r";
L["HEADER_ARENA_MODULES"]        = "|cffFFD100Arena Modules|r";
L["CB_MIRROR_MODE"]              = "Arena Mirror Mode";
L["CB_TRINKET_TRACK"]            = "Arena Trinket Tracking";
L["CB_TRINKET_VOICE"]            = "Arena Trinket Voice Alerts";

-- Flat Style UI
L["CB_FLAT_MIRRORED"]            = "Flat Mirrored";
L["SLIDER_FLAT_WIDTH"]           = "Flat Width";
L["SLIDER_FLAT_HB_HEIGHT"]      = "Health Bar Height";
L["SLIDER_FLAT_PB_HEIGHT"]      = "Power Bar Height";
L["SLIDER_FLAT_HB_FONT"]        = "Health Font Size";
L["SLIDER_FLAT_PB_FONT"]        = "Power Font Size";

-- Cast Bar UI
L["HEADER_CASTBAR"]              = "|cffFFD100Cast Bar|r";
L["CB_CASTBAR_ENABLE"]           = "Custom Cast Bar";
L["SLIDER_CASTBAR_SCALE"]       = "Cast Bar Scale";
L["SLIDER_CASTBAR_WIDTH"]       = "Cast Bar Width";

-- Pet Frame
L["CB_PET_FRAME_SHOW"]          = "Show Pet Frame (Test Mode)";
L["CB_FLAT_PET_STYLE"]          = "Flat Pet Style";
L["CB_FLAT_STATUS_TEXT"]        = "Force Status Text";
L["LABEL_PET_STYLE"]            = "Pet Frame Style (Flat only)";

-- Visual Theme
L["LABEL_THEME"]                 = "Visual Theme";
L["THEME_OPT_LIGHT"]            = "Light";
L["THEME_OPT_DARK"]             = "Dark";
L["THEME_CHANGED"]              = "|cffFFD100NUF:|r Theme changed. |cffFFAA00/reload to apply.|r";
L["CB_UNITFRAME_CUSTOM_TEX"]    = "Custom Skin (Player/Target/Focus)";
L["TIP_UnitFrameCustomTexture"] = "Use custom .blp textures on Player, Target and Focus frames (border, PVP icon, bar sizes, status icon).\nDisable to restore the default Blizzard frames.\n\n"..INSTANT;

-- Flat Style labels (sArena style)
L["SLIDER_FLAT_WIDTH_FULL"]      = "Frame Width";
L["SLIDER_FLAT_HB_HEIGHT_FULL"]  = "Health Bar Height";
L["SLIDER_FLAT_PB_HEIGHT_FULL"]  = "Power Bar Height";
L["SLIDER_FLAT_HB_FONT_FULL"]   = "Health Font Size";
L["SLIDER_FLAT_PB_FONT_FULL"]   = "Power Font Size";
L["CB_FLAT_MIRRORED_FULL"]      = "Mirrored Frames";

-- Tab 4 - Modules
L["HEADER_MODULES"]              = "|cffFFD100Modules|r";
L["DESC_MODULES"]                = "Enable or disable extra modules. Add .lua files in Modules2/";
L["MODULES_NONE"]                = "|cffAAAAAA(No modules registered)|r";
L["MODULES_ENABLED"]             = "|cffFFD100\226\156\147 Enabled|r";
L["MODULES_DISABLED"]            = "|cffFF0000\226\156\151 Disabled|r";
L["MODULES_HOWTO"]               = "|cffFFFF00How to add modules:|r\n\n"..
	"1. Place your .lua file in the |cffFFD100Modules2/|r folder\n\n"..
	"2. Add this at the beginning of the file:\n"..
	"   |cff00FFFF"..
	'K.RegisterModule("ModuleName", {\n'..
	'       name = "My Module",\n'..
	'       desc = "Module description",\n'..
	"   })|r\n\n"..
	"3. Add the line to the |cffFFD100.toc|r file:\n"..
	"   |cff00FFFFModules2/ModuleName.lua|r\n\n"..
	"4. Do |cffFFAA00/reload|r and the checkbox will appear here automatically.";

-- Bottom buttons
L["BTN_RELOAD"]                  = "Reload UI";
L["BTN_RESET"]                   = "Reset Defaults";
L["BTN_CLOSE"]                   = "Close";
L["BTN_SHOW_CONFIG"]             = "Show Config";
L["RESET_CONFIRM"]               = "Reset EVERYTHING to defaults?\n\nOptions, module on/off, positions and scales.\nYour saved profiles are kept.\n\n|cffFF0000This will reload your UI!|r";
L["RESET_BTN_YES"]               = "Reset";
L["RESET_BTN_NO"]                = "Cancel";

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
L["PETTARGET_PREFIX"]            = "Target: ";
L["PETTARGET_NONE"]              = "Target: None";
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
L["APC_BTN_TIP_DRAG"]            = "Alt + drag to move it";
L["APC_BTN_RESET_DONE"]          = "Button position reset.";
L["TT_SOLO_QUEUE"]               = "Solo Queue";

-- Party Targets
L["PT_HIDE_NAME"]                = "Hide target name";
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
L["LORTI_SUBOPTIONS"]            = "Sub-options (requires /reload):";
L["MOVER_DRAG"]                  = "NUF - drag to move";
L["MOVER_HINT"]                  = "Shift+Alt+Click to move various elements";
L["BOSS_DRAG"]                   = "BOSS FRAMES [drag]";
L["HP_NA"]                       = "N/A";
L["HP_DEAD"]                     = "Dead";

-- Paneles de Config
L["PANEL_STYLE"]                 = "Style";
L["TIP_PANEL_THEME"]             = "Switch panel theme";
L["ARENA_PET_STYLE"]             = "Pet Style";
L["ARENA_TOT"]                   = "Target of Target";
L["PROFILE_NONE_YET"]            = "(No profiles yet)";
L["SLOT_NONE_YET"]               = "(No characters yet)";
L["ERR_PREFIX"]                  = "Error: ";
L["CMD_MODULE_OFF"]              = "%s is turned off. Enable it in the options panel to use its commands.";
L["PVP_HINT_EXPAND"]             = "Tick a module to show its options.";
L["SLIDER_BUFF_SCALE"]           = "Buff scale";
L["SLIDER_DEBUFF_SCALE"]         = "Debuff scale";
L["BARS_RELOADING"]              = "Action bar mode changed \226\128\148 reloading UI...";

-- Claves que se usaban en el codigo pero nunca se habian definido.
L["BTN_RESET_CASTBAR"]           = "Reset";
L["BTN_RESET_PET_POS"]           = "Reset";
L["CB_ARENA_COUNTDOWN"]          = "Arena Countdown + Shadow Sight";
L["LABEL_PARTY_MEMBER"]          = "Party";
L["MOD_MELEESWING"]              = "Melee Swing Timer";
L["MOD_MELEESWING_DESC"]         = "Shows the time left until your next melee swing.";
L["TIP_HideChatButton"]          = "Hides the chat menu button.";

-- Tab 5 - Extra Options
L["HEADER_EXTRA"]                = "|cffFFD100Extra Options|r";
L["DESC_EXTRA"]                  = "Additional settings and experimental features";

-- Profiles
L["HEADER_PROFILES"]             = "|cffFFD100Profiles|r";
L["DESC_PROFILES"]               = "Export your config to share or backup, import to restore.";
L["BTN_EXPORT"]                  = "Export Profile";
L["BTN_IMPORT"]                  = "Import Profile";
L["BTN_COPY"]                    = "Copy";
L["PROFILE_COPY_FROM"]           = "Copy profile from:";
L["PROFILE_CURRENT"]             = "current";
L["PROFILE_ERR_SELECT"]          = "Select a profile first!";
L["PROFILE_ERR_CURRENT"]         = "That is your current profile!";
L["PROFILE_COPYING"]             = "Copying profile from";
L["TIP_EXPORT"]                  = "Generates a text string with all your settings.\nCopy it and save it somewhere safe.";
L["TIP_IMPORT"]                  = "Paste a profile string to restore settings.\nThis will overwrite your current config and reload UI.";

-- Character Setup (barras / macros / bindeos) - NADA que ver con los
-- perfiles de arriba, que son la config del addon.
L["HEADER_SLOTS"]                = "|cffFFD100Character Setup|r";
L["DESC_SLOTS"]                  = "Action bars, macros and keybinds. This is your character, not the addon settings.";
L["SLOT_COPY_FROM"]              = "Copy bars & macros from:";
L["SLOT_BTN_EXPORT"]             = "Export Setup";
L["SLOT_BTN_IMPORT"]             = "Import Setup";
L["SLOT_EXPORT_TITLE"]           = "|cffFFD100Export Character Setup|r";
L["SLOT_IMPORT_TITLE"]           = "|cffFFAA00Import Character Setup|r";
L["SLOT_EXPORT_HINT"]            = "|cffAAAAAA(Ctrl+A to select all, Ctrl+C to copy. Compatible with MySlot.)|r";
L["SLOT_IMPORT_HINT"]            = "|cffAAAAAA(Paste a setup string, then click Import)|r";
L["SLOT_BTN_WIPEBARS"]           = "Clear Bars";
L["SLOT_BTN_WIPEMACROS"]         = "Delete Macros";
L["SLOT_BTN_RESETBINDS"]         = "Default Keys";
L["SLOT_BTN_UNDO"]               = "Undo";
L["SLOT_CONFIRM_WIPEBARS"]       = "Clear ALL %d action bar slots?\n\nA backup is saved first: use Undo to get them back.";
L["SLOT_CONFIRM_WIPEMACROS"]     = "Delete ALL %d macros?\n\nA backup is saved first: use Undo to get them back.";
L["SLOT_CONFIRM_RESETBINDS"]     = "Restore Blizzard's default keybinds?\n\nA backup is saved first: use Undo to get them back.";
L["SLOT_CONFIRM_IMPORT"]         = "Apply this setup to %s?\n\nYour current bars, macros and keybinds will be overwritten.\nA backup is saved first.";
L["SLOT_DONE_IMPORT"]            = "Setup applied: %d slots, %d keybinds.";
L["SLOT_DONE_WIPEBARS"]          = "Cleared %d slots.";
L["SLOT_DONE_WIPEMACROS"]        = "Deleted %d macros.";
L["SLOT_DONE_RESETBINDS"]        = "Default keybinds restored.";
L["SLOT_BACKUP_DONE"]            = "Backup restored.";
L["SLOT_ERR_COMBAT"]             = "Can't do this in combat.";
L["SLOT_ERR_EMPTY"]              = "Paste a string first.";
L["SLOT_ERR_DECODE"]             = "The string is corrupt or incomplete.";
L["SLOT_ERR_PARSE"]              = "Invalid string: ";
L["SLOT_ERR_NOBACKUP"]           = "There is no backup yet.";
L["SLOT_ERR_NOPROFILE"]          = "That setup no longer exists.";
L["SLOT_MACRO_FULL"]             = "Macro '%s' skipped: no free macro slots.";
L["SLOT_NOTE_LOGOUT"]            = "To copy between characters you must LOG OUT (not /reload) so the game writes the data to disk.";
L["TIP_SLOT_EXPORT"]             = "Generates a text string with your action bars, macros and keybinds.\nCompatible with MySlot strings.";
L["TIP_SLOT_IMPORT"]             = "Paste a setup string to apply it to this character.\nSpells your character does not know are skipped.";

L["PROFILE_EXPORT_TITLE"]        = "|cffFFD100Export Profile|r";
L["PROFILE_EXPORT_HINT"]         = "|cffAAAAAA(Ctrl+A to select all, Ctrl+C to copy)|r";
L["PROFILE_IMPORT_TITLE"]        = "|cffFFAA00Import Profile|r";
L["PROFILE_IMPORT_HINT"]         = "|cffAAAAAA(Paste your profile string, then click Import)|r";
L["PROFILE_IMPORT_BTN"]          = "Import";
L["PROFILE_CANCEL"]              = "Cancel";
L["PROFILE_IMPORT_EMPTY"]        = "Paste a profile string first!";
L["PROFILE_IMPORT_ERROR"]        = "Import error: ";
L["PROFILE_IMPORT_SUCCESS"]      = "Profile imported! Reloading...";

-- Utility
L["HEADER_UTILITY"]              = "|cffFFD100Utility|r";
L["CB_AUTO_SELL"]                = "Auto Sell Gray Items";
L["TIP_AutoSellGray"]            = "Automatically sells all gray (junk) items when you open a vendor.";
L["CB_AUTO_REPAIR"]              = "Auto Repair";
L["TIP_AutoRepair"]              = "Automatically repairs all items when you open a vendor.\nUses guild bank first if available.\nHold Shift to skip.";
L["CB_ERROR_HIDE"]               = "Hide Errors in Combat";
L["TIP_ErrorHideInCombat"]       = "Hides red error messages during combat.\nShows them again when combat ends.";

-- Arena Timers
L["HEADER_ARENA_TIMERS"]         = "|cffFFD100Arena Timers|r";
L["CB_DALARAN_PIPE"]             = "Dalaran Waterfall Timer";
L["TIP_ArenaDalaranPipeTimer"]   = "Shows a 10 second icon timer when the Dalaran Arena waterfall is about to push players off the pipe.";
L["CB_ROV_PILLARS"]              = "Ring of Valor Pillar Timer";
L["TIP_ArenaRoVPillarTimer"]     = "Shows when the pillars rise in the Ring of Valor arena.\nFirst cycle 45s, then every 25s.";
L["CB_ARENA_END"]                = "Arena Time Remaining";
L["TIP_ArenaEndTimer"]           = "Shows how much time is left before the arena ends in a draw.";
L["ARENA_END_PREFIX"]            = "Arena: ";
L["TIMERS_TEST_HINT"]            = "Arena timers test mode toggled. Hold Alt and drag to move them.";

-- Action Bar Text
L["HEADER_BAR_TEXT"]             = "|cffFFD100Action Bar Text|r";
L["CB_HIDE_KEYBIND"]             = "Hide Keybind Text";
L["TIP_HideKeybindText"]         = "Hides the keybind text on action bar buttons.";
L["CB_HIDE_MACRO"]               = "Hide Macro Names";
L["TIP_HideMacroText"]           = "Hides the macro name text on action bar buttons.";

-- Frames subtabs
L["BTN_RESET_SCALES"]            = "Reset All Scales";
L["BTN_RESET_POSITIONS"]         = "Reset Positions";
L["SCALES_RESET_DONE"]           = "Scales and positions reset. /reload to fully restore the defaults.";
L["SUBTAB_FR_SCALES"]            = "Frames";
L["SUBTAB_FR_POSITIONS"]         = "Positions";
L["SUBTAB_FR_PARTY"]             = "Party";
L["SUBTAB_FR_PVE"]               = "PvE";
L["HEADER_PVE"]                  = "PvE";
L["DESC_PVE"]                    = "Boss frames and raid encounter settings.";
L["PARTY_3V3_NOTE"]              = "Party Mode 3v3 and individual movement are in the Positions tab.";

-- Mover todo
L["MOVE_RESET_DONE"]             = "Every frame is back to its default position.";
L["MOVE_HELP_ALL"]               = "unlock everything";
L["MOVE_HELP_FRAMES"]            = "only the unit frames";
L["MOVE_HELP_LOCK"]              = "lock it back";
L["MOVE_HELP_RESET"]             = "back to default positions";
L["MOVER_HINT_SCALE"]            = "Ctrl + mouse wheel over a box to scale it";
L["MOVER_CONSOLE"]                = "Move Everything";
L["LBL_MOVE_GRID"]               = "Grid";
L["DESC_MOVE_GRID"]              = "Frames snap to a grid while you drag them, so lining two of them up is easy. Smaller steps move more freely.";
L["TIP_MOVE_GRID"]               = "Cells of %d pixels a side.";
L["HEADER_MOVE_ALL"]             = "|cffFFD100Move Everything|r";
L["DESC_MOVE_ALL"]               = "Unlocks everything: unit frames, action bars, buffs, debuffs, cast bar and the NUF timer bars. Shows fake party members so you can place them. Ctrl + mouse wheel resizes.";
L["BTN_MOVE_ALL"]                = "Unlock Everything";
L["HEADER_MOVE_FRAMES"]          = "|cffFFD100Move Unit Frames|r";
L["DESC_MOVE_FRAMES"]            = "Unlocks only Player, Target, Focus, Party, Arena and Boss frames. Drag the blue boxes, Ctrl + mouse wheel to resize, then lock again.";
L["BTN_MOVE_FRAMES"]             = "Unlock Unit Frames";
L["PARTYTEST_ON"]                = "Party test mode ON - 4 fake members shown. /nufparty to turn it off.";
L["PARTYTEST_OFF"]               = "Party test mode OFF.";
L["PARTYTEST_COMBAT"]            = "Cannot start party test mode during combat.";
L["BTN_MOVE_ALL_DONE"]           = "Lock All Frames";
L["BTN_OPEN"]                    = "Open";
L["BTN_MOVE_RESET"]              = "Reset";
L["MOVE_ON"]                     = "Move mode ON - drag the blue boxes. /nufmove to finish.";
L["MOVE_OFF"]                    = "Move mode OFF - positions saved.";
L["MOVE_RESET"]                  = "Saved positions cleared. /reload to restore the defaults.";
L["MOVE_COMBAT_BLOCK"]           = "Action bars cannot be moved during combat.";

-- Minimapa
L["MOD_MINIMAP_TOGGLE"]          = "Minimap Icon Toggle";
L["MOD_MINIMAP_TOGGLE_DESC"]     = "Button on the minimap corner that hides or shows every minimap icon.";
L["MINIMAP_TOGGLE_TITLE"]        = "Minimap Icons";
L["MINIMAP_TOGGLE_TIP"]          = "Click to hide or show every minimap icon (zoom, clock, addons).";
L["MINIMAP_TOGGLE_DISABLED"]     = "Enable the Minimap Icon Toggle module first.";

L["BTN_MODULE_CONFIG"]           = "Configure";
L["BTN_MODULE_MOVE"]             = "Move";
L["BTN_MODULE_TOGGLE"]           = "Toggle";

-- Nuevos modulos
L["MOD_ARROWCOUNT"]              = "Arrow / Bullet Count";
L["MOD_DUNGEONROLES"]            = "Dungeon Finder Roles";
L["MOD_DUNGEONROLES_DESC"]       = "While queued for a dungeon, shows tank, healer and 3 dps icons and lights up the roles already filled. Alt + drag to move.";
L["MOD_ARROWCOUNT_DESC"]         = "Shows how much ammo you have left. Alt + drag to move it.";
L["MOD_POWERBAR"]                = "Power Bar";
L["MOD_POWERBAR_DESC"]           = "Movable mana / energy / rage / runic power bar next to your character. Alt + drag to move it.";
L["BAR_WATER_ELE"]               = "Water Elemental";
L["BAR_MIRROR"]                  = "Mirror Image";
L["MOD_AUTOSHOT"]                = "Auto Shot Timer";
L["MOD_AUTOSHOT_DESC"]           = "Hunter auto shot timing bar. /nufshot unlock to move it.";
L["MOD_SWINGTIMER"]              = "Melee Swing Timer";
L["MOD_SWINGTIMER_DESC"]         = "Bar showing the time until your next melee white hit. /nufswing unlock to move it.";
L["SWING_LABEL"]                 = "Auto attack";
L["THEME_OPT_ASURI"]             = "Asuri";
L["THEME_OPT_PW"]                = "Compact";
L["PVP_PALADIN_AURAS"]           = "Auras";
L["PVP_PALADIN_AURAS_NOTE"]      = "Holy Strength proc, healing reduction (Mortal Strike / Aimed Shot / Wound Poison) on any party member, and The Art of War cooldown.";
L["MOD_TURN_EVIL"]               = "Turn Evil tracker";
L["MOD_TURN_EVIL_DESC"]          = "Stack of up to 3 icons showing which group members have Turn Evil on them.";
L["MOD_PALADIN_AURAS"]           = "Paladin tracker";
L["MOD_PALADIN_AURAS_DESC"]      = "Holy Strength proc, healing reduction on any party member, and The Art of War cooldown. /nufpal to move them.";
L["SLIDER_PARTY_FONT_SIZE"]      = "Text size";
L["PARTY_FONT_AUTO"]             = "Auto";
L["TIP_PartyFontSize"]           = "Size of the health / mana numbers on party frames. Auto keeps whatever size the chosen style uses.";
L["CB_PARTY_HIDE_TEXT"]          = "Hide health / mana numbers";
L["TIP_PartyHideHealthManaText"] = "Hides the health and mana numbers on party bars only (does not affect Arena / Player / Target).\nThe bars stay visible, only the numbers go away.";
L["CB_FULL_VALUE"]               = "Current value only (no /max)";
L["TIP_ShowCurrentValueOnly"]    = "Shows \"33401\" instead of \"33401 / 33401\" on health and mana bars.";
L["HEADER_PARTY_FONT"]           = "Text Outline";
L["LBL_PARTY_FONT"]              = "Font outline";
L["OUTLINE_NONE"]                = "None";
L["OUTLINE_NORMAL"]              = "Outline";
L["OUTLINE_THICK"]               = "Thick outline";
L["OUTLINE_BLIZZ"]               = "Like health / mana text";
L["HEADER_CLASS_INDICATORS"]     = "Class Colored Indicators";
L["MOD_CLASSOUTLINE"]            = "Class Colored Outlines";
L["MOD_CLASSOUTLINE_DESC"]       = "Adds a class colored ring around the player, target and focus portraits.";
L["SLIDER_OUTLINE_SIZE"]         = "Ring size";
L["SWING_USE_GLOBAL"]            = "Move Everything is on: drag the blue box from there.";

-- Barras
L["SUBTAB_GEN_UI"]               = "Interface";
L["SUBTAB_GEN_BARS"]             = "Action Bars";
L["CB_HIDE_BAR_TEXTURES"]        = "Hide Action Bar Textures";
L["TIP_HideBarTextures"]         = "Hides the decorative textures of the main action bar.";
L["CB_BUTTON_RANGE"]             = "Button Range";
L["TIP_ButtonRange"]             = "Tints action buttons red when the target is out of range.";

-- Subtabs
L["SUBTAB_ARENA_FRAMES"]         = "Frames";
L["SUBTAB_ARENA_TIMERS"]         = "Timers";
L["SUBTAB_ARENA_MODULES"]        = "Options";
L["HEADER_ARENA_QUEUE"]          = "|cffFFD100Queue|r";
L["CB_ARENA_TIMES"]              = "Queue timer + invite popup timer";
L["TIP_ArenaTimes"]              = "Shows a countdown bar on the arena invite popup and the queue time next to the minimap.";
L["CB_ARENA_TOT"]                = "Enable Target of Target";
L["TIP_ArenaToT"]                = "Shows the current target of each arena enemy.";
L["TIMERS_MOVE_NOTE"]            = "Use /nuftimers to show the timers and Alt + drag to move them.";

-- Unit Name Color
L["HEADER_NAME_COLOR"]           = "|cffFFD100Name Color|r";
L["NAME_COLOR_DEFAULT"]          = "Default";
L["NAME_COLOR_WHITE"]            = "White";
L["NAME_COLOR_CLASS"]            = "Class";
L["TIP_UnitNameColorMode"]       = "Color of unit names on Player, Target, Focus, Party and Arena frames.\n\nDefault: Blizzard colors\nWhite: all names white\nClass: names by class color\n\nSwitching back to Default may need /reload.";
L["CB_SIDEBARS_HOVER"]           = "Show side bars on mouseover";
L["TIP_SideBarsHover"]           = "The right side bars stay hidden and only appear when the mouse is over them. They still work while hidden.";
L["HEADER_BAR_MOVE"]             = "|cffFFD100Position|r";
L["NOTE_BAR_MOVE"]               = "Turns on move mode: drag the blue box to place the action bars. Click again to lock and save.";
L["BTN_MOVE_BARS"]               = "Move action bars";
L["BTN_LOCK_BARS"]               = "Lock bars";
L["NAME_BORDER"]                 = "Name border";
L["NAME_BORDER_NONE"]            = "None";
L["NAME_BORDER_OUTLINE"]         = "Outline";
L["NAME_BORDER_THICK"]           = "Thick Outline";
L["NAME_BORDER_SHADOW"]          = "Like health / mana text";

-- Chat
L["HEADER_CHAT"]                 = "|cffFFD100Chat|r";
L["CB_CHAT_COPY"]                = "Copy Chat Text";
L["TIP_ChatCopyEnabled"]         = "Double click a chat tab to open a copyable view of the chat history.\nUse Ctrl+A / Ctrl+C, Escape to close.\nAlso available with /nufcopy.";
L["CB_CHAT_URLS"]                = "Clickable Links";
L["TIP_ChatClickableURLs"]       = "Turns URLs written in chat into clickable links.\nClicking one opens a small window with the link ready to copy.";
L["CHATCOPY_DISABLED"]           = "Chat copy is disabled in the options.";
L["URL_POPUP_TEXT"]              = "Copy the link (Ctrl+C):";

-- Module collapse
L["MODULE_EXPAND"]               = "Click to expand options";
L["MODULE_COLLAPSE"]             = "Click to collapse options";
L["COLLAPSE_ICON_EXPAND"]        = "[>]";
L["COLLAPSE_ICON_COLLAPSE"]      = "[v]";

-- Tab 6 - About
L["HEADER_ABOUT"]                = "|cffFFD100About|r";
L["ABOUT_ADDON_NAME"]            = "|cffffffffNidhaus|r |cffFFD100UnitFrames|r";
L["ABOUT_DESCRIPTION"]           = "A PVP-focused UI addon for WoW WotLK 3.3.5a.\nCustom arena frames, trinket tracking, mirror mode,\nclass-colored health bars, and optimized frame positioning\ndesigned for competitive arena gameplay.";
L["ABOUT_VERSION"]               = "|cffFFAA00Version:|r 3.6";
L["ABOUT_COMMANDS_HEADER"]       = "|cffFFAA00Slash Commands:|r";
L["ABOUT_CMD_OPTIONS"]           = "|cffFFFFFF/nuf|r — Open options panel";
L["ABOUT_CMD_CONFIG"]            = "|cffFFFFFF/nuf config|r — Show saved variables";
L["ABOUT_CMD_ARENA"]             = "|cffFFFFFF/nuf arena|r — Toggle arena test mode";
L["ABOUT_CMD_BOSS"]              = "|cffFFFFFF/nuf boss|r — Toggle boss test mode";
L["ABOUT_CMD_RESET"]             = "|cffFFFFFF/nuf reset|r — Reset all settings";
L["ABOUT_GITHUB_LABEL"]          = "|cffFFAA00GitHub:|r";
L["ABOUT_GITHUB_LINK"]           = "https://github.com/nidas-wow-oss";
L["ABOUT_CONTACT_LABEL"]         = "|cffFFAA00Discord:|r";
L["ABOUT_CONTACT_LINK"]          = "https://discord.gg/p3sqeram";
L["ABOUT_COPY_HINT"]             = "|cffAAAAAA(Click to select, Ctrl+C to copy)|r";

-- === MINIMAP BUTTON ===
L["MINIMAP_TITLE"]               = "|cffffffffNidhaus|r |cffFFD100UnitFrames|r";
L["MINIMAP_LEFT_CLICK"]          = "|cffFFFFFFLeft Click:|r Open Options";
L["MINIMAP_RIGHT_CLICK"]         = "|cffFFFFFFRight Click:|r Toggle Arena Mover";
L["MINIMAP_CTRL_CLICK"]          = "|cffFFFFFFCtrl + Click:|r Move Everything";
L["MINIMAP_SHIFT_CLICK"]         = "|cffFFFFFFShift + Click:|r Reload UI";
L["MINIMAP_DRAG"]                = "|cffFFFFFFDrag:|r Move icon";


-- === UNIFY ACTION BARS MODULE ===
L["MOD_UAB_NAME"]          = "Unify Action Bars";
L["MOD_UAB_DESC"]          = "Repositions and cleans up default action bar elements.";
L["MOD_UAB_DISABLED"]      = "|cffFFD100NUF:|r Unify Action Bars disabled.";
L["HEADER_ACTIONBARS"]     = "|cffFFD100Action Bars|r";
L["CB_UNIFY_ACTIONBARS"]   = "Unify Action Bars";
L["TIP_UnifyActionBars"]   = "Repositions and cleans up default action bar UI elements:\nbags, micro menu, pet bar, stance bar and paging buttons.";

-- ============================================================
-- ESPAÑOL (override si el cliente es esES o esMX)
-- ============================================================
if isSpanish then

-- Tags
local INSTANTE = "|cffFFD100\226\156\147 Aplica al instante|r";
local RECARGA  = "|cffFFAA00\226\154\160 Requiere /reload|r";

-- === TOOLTIPS ===
L["TIP_classColor"]              = "Colorea la barra de vida según la clase.";
L["TIP_statusbarBackdrop"]       = "Agrega fondo oscuro a las barras.\n\n"..RECARGA;
L["TIP_HealthPercentage"]        = "Muestra el porcentaje de vida en el objetivo.";
L["TIP_CastingTimers"]           = "Muestra el tiempo de casteo restante en segundos sobre las barras de casteo del jugador y del objetivo.";
L["TIP_SetPositions"]            = "Usar posiciones personalizadas del addon.\n\nON: Usa posiciones custom (Settings.lua)\nOFF: Vuelve a las posiciones por defecto guardadas al iniciar";
L["TIP_LockPositions"]           = "Bloquear posiciones de frames.\n\nOFF: Podés arrastrar Player, Target y Party\ncon Shift + Alt + Click Izquierdo\nON: Los frames quedan bloqueados";
L["TIP_PartyIndividualMove"]     = "Mover party frames individualmente.\n\nON: Cada miembro del party se arrastra por separado\nOFF: Todo el party se mueve junto";
L["TIP_PlayerFrameScale"]        = "Escala del PlayerFrame.";
L["TIP_TargetFrameScale"]        = "Escala del TargetFrame.";
L["TIP_FocusScale"]              = "Escala del Focus.";
L["TIP_FocusSpellBarScale"]      = "Escala de la castbar del Focus.";
L["TIP_FocusAuraLimit"]          = "Limita auras del focus.\n\n"..RECARGA;
L["TIP_PartyFrameOn"]            = "Activa modificaciones de party.\n\n"..RECARGA;
L["TIP_PartyFrameScale"]         = "Escala party.";
L["TIP_PartyMemberFrameSpacing"] = "Espaciado party.";
L["TIP_PartyMode3v3"]            = "Modo especial 3v3: Party 1-2 a escala 1.5, Party 3-4 normal.\n\nRequiere \"Usar Posiciones Custom\" activado.";
L["TIP_BossTargetFrameSpacing"]  = "Espaciado boss frames.\n\n"..RECARGA;
L["TIP_ArenaFrameOn"]            = "Activa modificaciones de arena.";
L["TIP_ArenaFrameScale"]         = "Escala arena.";
L["TIP_ArenaFrame_Trinkets"]     = "Trinkets arena.";
L["TIP_ArenaFrame_Trinket_Voice"] = "Voz trinket.";
L["TIP_ArenaMirrorMode"]         = "Voltea los arena frames: portrait a la izquierda,\nbarras a la derecha (espejo de los party frames).";
L["TIP_ArenaFrameSpacing"]       = "Espaciado vertical entre arena frames.";
L["TIP_ArenaCustomTexture"]      = "Usa texturas custom en los arena frames.\nDesactivar restaura las texturas default de Blizzard.";
L["TIP_BossFrameScale"]          = "Escala del boss frame.";
L["TIP_NewPartyFrame"]           = "Reemplaza las texturas del party frame con un estilo custom.\n\n"..RECARGA;
L["TIP_PartyTargets"]            = "Muestra a quién están targeteando tus compañeros de party.\nEstilo compacto Target-of-Target.\nUsá /ptarget para opciones específicas.";
L["TIP_PartyBuffs"]              = "Muestra buffs/debuffs extendidos en los frames de party.\nUsá /pbuffs para opciones específicas.";
L["TIP_PartyCastingBars"]       = "Muestra una barra de casteo junto al marco de cada miembro del grupo.\n\nUs\195\161 /pcb (o /partycastingbars) para sus propias opciones: tama\195\177o, colores, icono y posici\195\179n.";
L["CB_PARTY_CASTBARS_SHORT"]    = "Party Castbars";
L["CB_PARTY_TARGETS_SHORT"]     = "Party Targets";
L["CB_NEW_PARTY_FRAME_SHORT"]   = "New Party";
L["CB_PARTY_BUFFS_SHORT"]       = "Party Buffs";

-- FLAT STYLE TOOLTIPS
L["TIP_ArenaFlatWidth"]          = "Ancho total del arena frame en modo Flat.";
L["TIP_ArenaFlatHealthBarHeight"] = "Altura de la barra de vida en modo Flat.";
L["TIP_ArenaFlatPowerBarHeight"] = "Altura de la barra de poder en modo Flat.";
L["TIP_ArenaFlatHealthFontSize"] = "Tamaño de fuente de vida. 0 para ocultar.";
L["TIP_ArenaFlatPowerFontSize"]  = "Tamaño de fuente de poder. 0 para ocultar.";
L["TIP_ArenaFlatMirrored"]       = "Espejea los frames Flat: portrait izquierda, barras derecha.";
L["TIP_ArenaFlatStatusText"]     = "Fuerza que el texto de vida/maná se muestre siempre en modo flat.\nSi está desactivado, respeta la config de Interface > Status Text.";

-- CAST BAR TOOLTIPS
L["TIP_ArenaCastBarEnable"]      = "Activa escala y ancho custom de la castbar.\nDesactivar usa el tamaño default de Blizzard.";
L["TIP_ArenaCastBarScale"]       = "Escala de la castbar.";
L["TIP_ArenaCastBarWidth"]       = "Ancho de la castbar.";

-- === OPTIONS PANEL ===
L["PANEL_TITLE"]                 = "Nidhaus UnitFrames";
L["PANEL_SUBTITLE"]              = "Personalización de Unit Frames & Herramientas de Arena";
L["PANEL_SIZE_RESET"]            = "Ventana de opciones restaurada a 820x620 y centrada.";

-- Tabs
L["TAB_GENERAL"]                 = "Interfaz";
L["TAB_FRAMES"]                  = "Frames";
L["TAB_ARENA"]                   = "Arena";
L["TAB_ARENA_BOSS"]              = "Arena/Boss";
L["TAB_MODULES"]                 = "Módulos";

-- ── Pestañas y secciones nuevas (rediseño estilo TidyPlates) ──
L["CB_BLOCK_DUELS"]              = "Rechazar duelos";
L["TIP_BlockDuels"]              = "Rechaza autom\195\161ticamente cualquier desaf\195\173o a duelo y cierra el cartel. \195\154til en ciudades y afuera de las puertas de arena.";
L["DUEL_BLOCKED"]                = "Duelo de %s rechazado.";
L["DUEL_BLOCK_ON"]               = "Los duelos ahora se rechazan solos.";
L["DUEL_BLOCK_OFF"]              = "Los duelos vuelven a estar permitidos.";
L["HEADER_FRAMES_MIRROR"]        = "Marcos de unidad";
L["NOTE_FRAMES_MIRROR"]          = "Las mismas dos opciones que en la pesta\195\177a Frames: toc\195\161s una y la otra se actualiza sola.";
L["PVP_HUD"]                     = "HUD de combate";
L["PVP_HUD_NOTE"]                = "Barras al lado del personaje, para no tener que mirar a los marcos de unidad.";
L["CB_POWERBAR_COMBAT"]          = "Mostrarla solo en combate";
L["CB_POWERBAR_PCT"]             = "Mostrar porcentaje en vez de actual / m\195\161ximo";
L["CB_POWERBAR_HEALTH"]          = "Mostrar tambien una barra de vida";
L["CB_POWERBAR_GRADIENT"]        = "La barra de vida cambia de color al bajar";
L["TIP_PowerBarGradient"]        = "La barra de vida va de verde a amarillo y rojo a medida que perd\195\169s vida, para notarlo de reojo.";
L["CB_POWERBAR_HIDEFULL"]        = "Ocultarla a full fuera de combate";
L["TIP_PowerBarHideFull"]        = "Esconde la barra mientras est\195\161s a full vida y recurso fuera de combate. Vuelve a aparecer sola.";
L["TIP_PowerBarHealth"]          = "Agrega una barra de vida arriba de la de recurso, para que el Power Bar funcione como un mini marco de jugador.";
L["TIP_PowerBarCombatOnly"]      = "Oculta la barra de recurso fuera de combate para no ensuciar la pantalla.";
L["SIDEGRP_COMBAT"]              = "Combate";
L["CB_LOCK_CLASS_BARS"]          = "Fijar las barras";
L["TIP_ClassTimersLocked"]       = "Fijadas: las barras ignoran el mouse, pod\195\169s clickear a trav\195\169s. Sueltas: las arrastr\195\161s con el bot\195\179n izquierdo.";
L["BTN_SHOW_BARS"]               = "Mostrar para acomodar";
L["BTN_HIDE_BARS"]               = "Ocultar";
L["CLASSTIMERS_PREVIEW_ON"]      = "Barras de clase a la vista. Arrastralas y despu\195\169s /nufclass hide.";
L["CLASSTIMERS_RESET"]           = "Posiciones de las barras de clase reiniciadas.";
L["CB_MINIMAP_HIDE_ZONEBG"]      = "Ocultar el fondo del nombre de zona";
L["CB_MINIMAP_HIDE_ICONS"]       = "Ocultar los iconos de addons";
L["MOD_PFI"]                     = "Party Frames Improved";
L["MOD_PFI_DESC"]                = "Textura m\195\161s ancha y limpia para los marcos de party, con los textos de nombre / vida / man\195\161 m\195\161s chicos y la barra de vida m\195\161s grande.";
L["MOD_SHIELDWATCH"]             = "ShieldWatch";
L["MOD_SHIELDWATCH_DESC"]        = "Barra con lo que queda de tus escudos y barreras m\195\161gicas, con aviso cuando est\195\161n por romperse. /shieldwatch options para configurarlo.";
L["MOD_ABBREV_STATUS"]           = "Texto de estado abreviado";
L["MOD_ABBREV_STATUS_DESC"]      = "Acorta los n\195\186meros de vida/man\195\161 de los marcos de unidad (12.3k en vez de 12345) y puede mostrar el porcentaje al lado.";
L["MOD_DTSU"]                    = "DTSU - Tracker de da\195\177o";
L["MOD_DTSU_DESC"]               = "Iconos flotantes con tu da\195\177o saliente (swing / hechizo / dot): total, ultimo golpe y cantidad de hits. /dtsu move para reubicarlo.";
L["MOD_PALADIN_ICD"]             = "Paladin ICD";
L["MOD_PALADIN_ICD_DESC"]        = "CD interno visual de tus defensivas de paladin (Divine Protection, Escudo Divino, Mano de Protecci\195\179n, Ira Vengadora, Imposici\195\179n de Manos). /paladinicd para moverlo.";
L["HEADER_STATUS_TEXT"]          = "|cffFFD100Texto de estado|r";
L["CB_ABBREV_STATUS"]            = "Texto de vida / man\195\161 abreviado";
L["TIP_ABBREV_STATUS"]           = "Acorta los n\195\186meros de las barras de los marcos. Toc\195\161 Abrir para configurarlo por unidad (vida, man\195\161, porcentaje, posici\195\179n).";
L["ABBREV_DECIMALS"]             = "Decimales";
L["ABBREV_FROM"]                 = "Abreviar desde";
L["ABBREV_RESET"]                = "Restaurar valores";
L["ABBREV_ON"]                   = "Act";
L["ABBREV_POS_NOTE"]             = "Mueve los textos de vida / man\195\161 de la unidad seleccionada.";
L["ABBREV_POS_THEME"]            = "Tema";
L["NOTE_FOCUS_SPELLBAR"]         = "La escala de la barra de casteo del foco esta en Interfaz > Barra de casteo.";
L["PANEL_LOAD_FAIL"]             = "No se pudo cargar el panel de opciones";
L["PANEL_LOAD_HINT"]             = "Revisa que la carpeta Nidhaus_UnitFrames_Config este junto a la del addon y activada en la lista.";
L["MOD_PARTYPETFRAME"]           = "Party pet enhanced";
L["MOD_PARTYPETFRAME_DESC"]      = "Marco propio para la mascota de tu primer compa\195\177ero: retrato, vida y man\195\161, barra de casteo y aviso de CC.";
L["CB_PARTY_PETS_HIDE"]          = "Ocultar mascotas del grupo";
L["CB_PARTY_PETS"]               = "Mostrar mascotas del grupo";
L["TIP_PartyPets"]               = "Los marquitos de las mascotas de tus compa\195\177eros (cazador, brujo, DK...). Apagarlos despeja la pantalla en arena.";
L["HEADER_PARTY_STYLE"]          = "Estilo de los marcos";
L["NOTE_PARTY_STYLE"]            = "Eleg\195\173 uno. Los dos estilos custom retexturizan los mismos marcos, as\195\173 que no pueden estar prendidos a la vez.";
L["PARTY_STYLE_DEFAULT"]         = "Blizzard";
L["PARTY_STYLE_NEW"]             = "New Party";
L["PARTY_STYLE_IMPROVED"]        = "Improved";
L["PARTY_STYLE_PW"]              = "Compacto";
L["PARTY_STYLE_CURRENT"]         = "actual";
L["TIP_PartyStyle_Default"]      = "Deja los marcos de party tal cual los hizo Blizzard.";
L["TIP_PartyStyle_New"]          = "NewPartyFrame: estilo custom con las barras y el orden rehechos.";
L["TIP_PartyStyle_Improved"]     = "PartyFramesImproved: textura m\195\161s ancha y limpia, con los textos m\195\161s chicos y la barra de vida m\195\161s grande.";
L["MOD_COMBOWATCH"]              = "Puntos de combo";
L["MOD_COMBOWATCH_DESC"]         = "Contador grande de puntos de combo, con color seg\195\186n cu\195\161ntos llev\195\161s y un marco que late al llegar a 5.";
L["PVP_COMBO"]                   = "Puntos de combo";
L["CB_LOCK_COMBO"]               = "Fijarlo en su lugar";
L["TIP_ComboWatchLocked"]        = "Fijado: ignora el mouse, pod\195\169s clickear a trav\195\169s. Suelto: lo arrastr\195\161s con el bot\195\179n izquierdo.";
L["COMBOWATCH_WRONG_CLASS"]      = "Solo p\195\173caros y druidas generan puntos de combo.";
L["PVP_ROGUE_POISON"]            = "Temporizador de venenos";
L["PVP_ROGUE_VANISH"]            = "Aviso de Esfumarse / Sprint listos";
L["PVP_DRUID_FORM"]              = "Indicador de forma activa";
L["PVP_DRUID_HOTS"]              = "Seguimiento de HoTs";
L["HEADER_PARTY_TRINKET"]        = "Trinkets de party";
L["NOTE_PARTY_TRINKET"]          = "Cooldown del trinket PvP al lado de cada miembro. Es independiente del rastreo de arena, y la posici\195\179n la comparten los cuatro.";
L["CB_PARTY_TRINKETS"]           = "Mostrar trinkets de party";
L["TIP_PartyTrinkets"]           = "Muestra el cooldown del trinket PvP de cada miembro del grupo. Funciona en arena y en battlegrounds.";
L["BTN_MOVE_TRINKETS"]           = "Moverlos";
L["BTN_LOCK_TRINKETS"]           = "Listo";
L["SLIDER_PARTY_TRINKET_SIZE"]   = "Tama\195\177o del trinket";
L["NOTE_PARTY_SUBADDONS"]        = "Comandos: /pbuffs, /ptarget, /pcb";
L["MOD_PETBUFFS"]                = "Buffos de la mascota";
L["MOD_PETBUFFS_DESC"]           = "Iconos debajo del marco de la mascota con Aliviar mascota, Agazaparse y Aguante, con lo que les queda de duraci\195\179n.";
L["PVP_HUNTER_PETSECTION"]       = "Mascota";
L["CB_LOCK_PETBUFFS"]            = "Fijarlos en su lugar";
L["TIP_PetBuffsLocked"]          = "Fijados: los iconos ignoran el mouse, pod\195\169s clickear a trav\195\169s. Sueltos: arrastr\195\161s la fila con el bot\195\179n izquierdo.";
L["SLIDER_PETBUFF_SIZE"]         = "Tama\195\177o de los iconos";
L["SLIDER_SCALE"]                = "Escala";
L["HEADER_TIMER_SCALES"]         = "|cffFFD100Tama\195\177o de los timers|r";
L["SCALE_COUNTDOWN"]             = "Cuenta atr\195\161s";
L["SCALE_DALARAN"]               = "Dalaran";
L["SCALE_ROV"]                   = "Ring of Valor";
L["SLIDER_SWING_SCALE"]          = "Escala";
L["SLIDER_ICONS_PER_ROW"]        = "Iconos por fila";
L["NOTE_ICONS_PER_ROW"]          = "Cuantos iconos de buff entran en una fila antes de pasar a la siguiente.";
L["SLIDER_POWERBAR_SCALE"]       = "Escala";
L["SLIDER_POWERBAR_WIDTH"]       = "Ancho";
L["SLIDER_POWERBAR_HEIGHT"]      = "Alto de barra";
L["PETBUFFS_WRONG_CLASS"]        = "Este m\195\179dulo es solo para cazadores.";
L["SIDE_BOSS"]                   = "Boss";
L["SIDE_PET"]                    = "Mascota";
L["HEADER_PET"]                  = "Marco de la mascota";
L["NOTE_PET"]                    = "Escala del marco de tu mascota (cazador, brujo, elemental de agua del mago, ghoul del DK).";
L["SLIDER_PET_SCALE"]            = "Escala del marco de mascota";
L["TAB_ADDONS"]                  = "Addons";
L["TAB_PVP"]                     = "PvP";
L["TAB_PROFILES"]                = "Perfiles";

L["SIDE_GENERAL"]                = "Ajustes generales";
L["SIDE_GENERAL_HINT"]           = "Afecta a todo";
L["SIDE_ACTIONBARS"]             = "Barras de acci\195\179n";
L["SIDE_MINIMAP"]                = "Minimapa";
L["SIDE_CHAT"]                   = "Chat";
L["SIDE_CASTBAR"]                = "Barra de casteo";
L["SLIDER_ARENA_TOT_SCALE"]      = "Escala del objetivo del objetivo";
L["CB_ARENA_TOT_CLASSICON"]      = "Icono de clase";
L["CB_ARENA_TOT_MIRROR"]         = "Marco espejado";
L["CB_ARENA_TOT_SQUARE"]         = "Estilo cuadrado";
L["TIP_ArenaToTSquare"]          = "Retrato cuadrado con el icono de clase, el mismo aspecto que usa Party Targets.";
L["PCB_TITLE"]                   = "Barras de casteo del grupo";
L["PCB_SCALE_LABEL"]             = "Escala de las barras:";
L["PCB_CB_ICONS"]                = "Mostrar el icono del hechizo";
L["PCB_CB_PARENT"]               = "Pegar las barras a los marcos del grupo";
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
L["HEADER_AURA_BORDERS"]         = "|cffFFD100Auras del objetivo y el foco|r";
L["CB_AURA_BORDERS"]             = "Bordes de aura propios";
L["CB_AURA_PURGE"]               = "Resaltar los buffs purgables";
L["NOTE_AURA_BORDERS"]           = "Borde fino en cada icono de buff y debuff, pintado segun la escuela: Magia azul, Maldicion violeta, Veneno verde, Enfermedad marron.";
L["TIP_AuraBordersEnabled"]      = "Recorta el icono del hechizo y le pone un borde fino. Los debuffs toman el color de su escuela, en lugar del aro gordo de Blizzard.";
L["TIP_AuraBordersPurge"]        = "Resplandor alrededor de los buffs magicos del enemigo, los que saca una purga o una disipacion.";
L["SIDE_MOVEALL"]                = "Mover todo";
L["HEADER_CASTBAR"]              = "|cffFFD100Barra de casteo|r";
L["CB_CASTBAR_PW"]               = "Barra de casteo personalizada";
L["CB_CASTBAR_PW_ICON"]          = "Mostrar el icono del hechizo";
L["CB_CASTBAR_PW_DARK"]          = "Borde oscuro";
L["CB_CASTBAR_PW_TARGET"]        = "Aplicar al objetivo";
L["CB_CASTBAR_PW_FOCUS"]         = "Aplicar al foco";
L["SLIDER_CASTBAR_PW_SIZE"]      = "Tamaño del icono";
L["SLIDER_CASTBAR_PW_SCALE"]     = "Escala de la barra";
L["NOTE_CASTBAR_PW"]             = "Cambia el borde, el destello y el escudo de las barras de casteo del jugador, del objetivo y del foco, y muestra el icono del hechizo arriba de la barra.";
L["TIP_CastBarPWEnabled"]        = "Otro aspecto para las tres barras de casteo: borde, destello y escudo de no interrumpible propios, mas el icono del hechizo.";
L["TIP_CastBarPWIcon"]           = "Muestra el icono del hechizo. En la barra del jugador queda flotando arriba del centro; en objetivo y foco se queda al costado.";
L["TIP_CastBarPWIconSize"]       = "Tamaño del icono del jugador. Los del objetivo y el foco lo siguen en proporcion.";
L["TIP_CastBarPWDark"]           = "Tiñe el borde de gris. Apagalo para ver la textura con su brillo normal.";
L["TIP_CastBarPWTarget"]         = "Aplica el estilo custom a la barra de casteo del objetivo. Apagado la deja como la de Blizzard.";
L["TIP_CastBarPWFocus"]          = "Aplica el estilo custom a la barra de casteo del foco. Apagado la deja como la de Blizzard.";
L["SIDE_TOOLTIP"]                = "Tooltip";
L["HEADER_TOOLTIP"]              = "Tooltip";
L["CB_TOOLTIP_ARENA_EXP"]        = "Experiencia de arena";
L["NOTE_TOOLTIP_ARENA_EXP"]      = "Agrega al tooltip el mejor rating personal de arena del jugador (2v2, 3v3, 5v5). Sale de las estadisticas de logros, asi que solo funciona con quien las tenga.";
L["CB_TOOLTIP_TALENTS"]          = "Mostrar talentos";
L["NOTE_TOOLTIP_TALENTS"]        = "Agrega el arbol principal y el reparto de talentos del objetivo. Necesita inspeccionar, asi que la primera lectura puede tardar un momento; despues queda en cache.";
L["CB_TOOLTIP_QUALITY"]          = "Borde por calidad de objeto";
L["CB_TOOLTIP_ICONS"]            = "Mostrar iconos en el tooltip";
L["NOTE_TOOLTIP_ICONS"]          = "Pone el icono del objeto o del hechizo al lado de su nombre, en la primera linea del tooltip.";
L["TIP_TooltipIcons"]            = "Muestra el icono del objeto o del hechizo al principio del tooltip.";
L["NOTE_TOOLTIP_QUALITY"]        = "Pinta el borde del tooltip con el color de calidad del objeto, de poco comun para arriba.";
L["TOOLTIP_NO_TALENT"]           = "Sin talentos";
L["TOOLTIP_LOADING"]             = "Cargando...";
L["TIP_TooltipArenaExp"]         = "Compara estadisticas de logros para leer el rating. Consulta al servidor, por eso no corre en combate.";
L["TIP_TooltipTalents"]          = "Basado en TipTacTalents. Se saltea si tenes abierta la ventana de inspeccion.";
L["TIP_TooltipQualityBorder"]    = "Solo de poco comun (verde) para arriba: gris y blanco conservan el borde normal.";
L["CB_AURA_CAST_BY"]             = "Mostrar quien lanzo el aura";
L["SLIDER_BUTTON_SPACE"]         = "Separacion entre botones";
L["CB_MINIMAP_THINBORDER"]         = "Borde fino";
L["ARENA_STYLE_COMPACT"]         = "Sin bordes";
L["ARENA_STYLE_COMPACT2"]        = "Compact";
L["MOD_SACREDSHIELD"]            = "Escudo sagrado (objetivo)";
L["MOD_SACREDSHIELD_DESC"]       = "Muestra el tiempo de Escudo sagrado sobre tu objetivo.";
L["MOD_SS_TRACKER"]              = "Rastreador de Escudo sagrado (grupo)";
L["MOD_SS_TRACKER_DESC"]         = "Sigue el Escudo sagrado en cada miembro del grupo.";
L["MOD_SEDUCTION"]               = "Seduccion sobre vos (arena)";
L["MOD_SEDUCTION_DESC"]          = "Avisa cuando una Sucubo te seduce en arena.";
L["MOD_SYSTEM_SPAM"]             = "Ocultar spam del sistema";
L["MOD_SYSTEM_SPAM_DESC"]        = "Filtra del chat los mensajes repetitivos del sistema.";
L["CB_TAB_BINDER"]               = "Tab apunta solo a jugadores en PvP";
L["CB_MINIBAR_NO_BG"]            = "Ocultar fondo de las barras";
L["TIP_MiniBarHideBackground"]   = "Esconde el arte de MainMenuBar que va detras de los botones, y el de las barras de experiencia y reputacion. Los grifos tienen su propia opcion.";
L["TIP_TabBinderEnabled"]        = "En arena, campos de batalla y zonas en disputa, la tecla de objetivo pasa a apuntar al JUGADOR enemigo mas cercano, asi el Tab deja de agarrar mascotas, totems y bichos. Al salir vuelve sola. Reasigna la tecla de verdad, asi que no cambia en combate: espera a que salgas.";
L["MOVE_AURA_BAR"]               = "Barra de auras";
L["MOVE_PRESENCE_BAR"]           = "Barra de presencias";
L["MOVE_FORM_BAR"]               = "Barra de formas";
L["MOVE_STANCE_BAR"]             = "Barra de posturas";
L["TIP_MinimapThinBorder"]         = "Cambia el borde cuadrado simple por uno fino y limpio. Solo con la forma cuadrada.";
L["NOTE_AURA_CAST_BY"]           = "Agrega al tooltip de buffs y debuffs una linea con el nombre de quien lo lanzo, con el color de su clase o faccion.";
L["TOOLTIP_CAST_BY"]             = "Lanzado por:";
L["TIP_AuraCastBy"]              = "Funciona con cualquier icono de buff o debuff, de Blizzard o de NUF. Las auras de mascotas muestran ademas a su dueño.";
L["TIP_CastBarPWScale"]          = "Escala de las barras del jugador y del objetivo. La del foco tiene su propio slider en Frames.";
L["SIDE_PTF"]                    = "General";
L["SIDE_PARTY"]                  = "Party";
L["SIDE_AURAS"]                  = "Buffos y debuffos";
L["SIDE_PVE"]                    = "Mascota y boss";
L["SIDE_CLASSOPT"]               = "Opciones de clase";
L["SIDE_CLASSOPT_HINT"]          = "Se detecta sola";
L["SIDE_ENEMY"]                  = "Enemigos";
L["SIDE_SELF"]                   = "Vos";


L["HEADER_APPEARANCE"]           = "Apariencia";
L["HEADER_BAR_STYLE"]            = "Estilo de barras";
L["HEADER_BAR_TEXT"]             = "Textos y feedback";
L["HEADER_BAR_SIZE"]             = "Tama\195\177o";
L["HEADER_SCALES"]               = "Escala";
L["HEADER_PARTY_PETS"]          = "|cffAAAAAA\226\128\148 Mascotas \226\128\148|r";
L["HEADER_PARTY_MODE"]           = "Modo";
L["HEADER_AURAS"]                = "Buffos y debuffos del jugador";
L["DESC_AURAS"]                  = "Desbloque\195\161 para arrastrar los bloques de buffos y debuffos a donde quieras.";
L["NOTE_MIRRORED"]               = "Estas tres son las mismas opciones que en la secci\195\179n Barras de acci\195\179n: toc\195\161s una y la otra se actualiza sola.";
L["NOTE_EXTRA_MOVED"]            = "Reparar autom\195\161tico, vender basura y las opciones de chat se mudaron a Interfaz > Ajustes generales e Interfaz > Chat.";

L["HEADER_MINIMAP_SHAPE"]        = "Forma";
L["HEADER_MINIMAP_BORDER"]       = "Borde";
L["DD_MINIMAP_BORDER"]           = "Estilo de borde";
L["MINIMAP_BORDER_DEFAULT"]      = "Predeterminado";
L["MINIMAP_BORDER_LIGHT"]        = "Fino";
L["MINIMAP_BORDER_TOOLTIP"]      = "Tooltip";
L["MINIMAP_BORDER_THIN"]         = "Delgado";
L["MINIMAP_BORDER_FLAT"]         = "Plano";
L["MINIMAP_BORDER_BLIZZARD"]     = "Blizzard";
L["NOTE_MINIMAP_BORDER"]         = "Tooltip, Delgado, Plano y Blizzard sirven con las dos formas.";
L["NOTE_MINIMAP_BORDER_SQUARE"]  = "Fino solo funciona con la forma cuadrada.";
L["HEADER_MINIMAP_DECOR"]        = "Adornos";
L["HEADER_MINIMAP_ICONS"]        = "Iconos de addons";
L["HEADER_MINIMAP_SIZE"]         = "Tama\195\177o";
L["MINIMAP_ROUND"]               = "Redondo";
L["MINIMAP_SQUARE"]              = "Cuadrado";
L["CB_MINIMAP_HIDE_ZONE"]        = "Ocultar el nombre de la zona";
L["CB_MINIMAP_HIDE_CLOCK"]       = "Ocultar el reloj";
L["CB_MINIMAP_HIDE_ZOOM"]        = "Ocultar los botones de zoom";
L["CB_MINIMAP_HIDE_CALENDAR"]    = "Ocultar el calendario";
L["CB_MINIMAP_HIDE_WORLDMAP"]    = "Ocultar el mapa del mundo";
L["CB_MINIMAP_WHEEL"]            = "Zoom con la rueda del mouse";
L["SLIDER_MINIMAP_SCALE"]        = "Escala del minimapa";
L["NOTE_MINIMAP_ICONS"]          = "Agrega un bot\195\179n chiquito en la esquina del minimapa que oculta o muestra todos los iconos de addons de una.";

L["CB_HIDE_CHAT_BUTTON"]         = "Ocultar los botones del chat";

L["SUBTAB_ARENA_OPTIONS"]        = "Opciones";
L["SUBTAB_ARENA_POINTS"]         = "Puntos de arena";
L["SUBTAB_ARENA_TIMERS"]         = "Tiempos";
L["HEADER_ARENA_POINTS"]         = "Puntos de arena";
L["MOD_APC"]                     = "Calculadora de puntos de arena";
L["MOD_APC_DESC"]                = "Calcula los puntos de arena que vas a recibir cada semana seg\195\186n tu rating. /apc para abrirla.";
L["BTN_APC_OPEN"]                = "Abrir la calculadora";
L["BTN_MODULE_OPEN"]             = "Abrir";

L["BTN_PARTY_TEST"]              = "Modo prueba (4 miembros falsos)";
L["BTN_MOVE_AURAS"]              = "Desbloquear buffos / debuffos";
L["BTN_MOVE_BARS"]               = "Mover las barras";
L["BTN_LOCK_BARS"]               = "Fijar las barras";

L["PVP_DETECTED"]                = "Clase detectada:";
L["PVP_DETECTED_SUB"]            = "Ac\195\161 solo se muestran los m\195\179dulos que tu clase puede usar.";
L["PVP_NO_CLASS_MODULES"]        = "Todav\195\173a no hay m\195\179dulos espec\195\173ficos para esta clase. La lista se va llenando a medida que se agreguen.";
L["PVP_SOON"]                    = "pr\195\179ximo";
L["PVP_SOON_HEADER"]             = "En la lista";
L["PVP_TIMERS"]                  = "Temporizadores";
L["PVP_SHOOTING"]                = "Disparo";
L["PVP_MELEE"]                   = "Cuerpo a cuerpo";
L["PVP_MAGE_CS"]                 = "Aviso de Contrahechizo listo";
L["PVP_MAGE_HS"]                 = "Contador de cargas de Racha Ardiente";
L["PVP_MAGE_APPEARANCE"]         = "Apariencia";
L["CB_MAGE_ICY"]                 = "Marco de jugador de hielo";
L["TIP_MageIcy"]                 = "Skin de hielo para tu marco de jugador. Funciona solo, no necesita ninguna otra opci\195\179n.";
L["PVP_HUNTER_ASPECT"]           = "Indicador de aspecto activo";
L["PVP_HUNTER_PET"]              = "Buffos de la mascota";
L["PVP_HUNTER_TRAP"]             = "Aviso de trampa lista";
L["PVP_WARRIOR_PROCS"]           = "Sobrepasar / Revancha disponibles";
L["PVP_WARRIOR_STANCE"]          = "Recordatorio de postura";
L["PVP_PALADIN_DEF"]             = "Defensivas";
L["PVP_PALADIN_ICD_NOTE"]        = "El icono se pone gris mientras corre el CD interno y vuelve a color cuando esta listo (Divine Protection, Escudo Divino, Mano de Protecci\195\179n, Ira Vengadora, Imposici\195\179n de Manos).";
L["CB_PALADIN_ICD_KEEP"]         = "Dejarlo en pantalla cuando esta listo";
L["TIP_PaladinICDKeep"]          = "Deja el icono a la vista y a color cuando el CD termino, para ver de un vistazo que lo tenes disponible. Si no, se oculta hasta que lo vuelvas a usar.";
L["PVP_PALADIN_WINGS"]           = "Aviso de alas / burbuja listas";
L["BTN_MOVE_IT"]                 = "Mover";
L["BTN_LOCK_IT"]                 = "Fijar";
L["PVP_ENEMY_HEADER"]            = "Informaci\195\179n del enemigo";
L["PVP_ENEMY_NOTE"]              = "Lo que est\195\161 haciendo el enemigo. Los marcos de arena ya muestran su trinket.";
L["BTN_SPELL_LIST"]              = "Lista de hechizos";
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
L["GARG_MODE"]                   = "Estilo";
L["GARG_MODE_BLIZZ"]             = "Blizzard";
L["GARG_MODE_CUSTOM"]            = "Custom";
L["GARG_WHERE"]                  = "Mostrarlo en:";
L["GARG_ARENA"]                  = "Arena";
L["GARG_BG"]                     = "Campos de batalla";
L["GARG_DUEL"]                   = "Duelos";
L["GARG_WORLD"]                  = "Mundo abierto";
L["BTN_TEST_MODE"]               = "Modo test";
L["MOD_ENEMYALERT"]              = "Alerta de hechizos enemigos";
L["MOD_ENEMYALERT_DESC"]         = "Muestra el icono del hechizo en pantalla cuando un enemigo lanza una trampa, miedo o interrupci\195\179n.";
L["PVP_ENEMYALERT_NOTE"]         = "Muestra el icono en pantalla cuando un enemigo lanza una trampa, miedo o interrupci\195\179n. Con \"Lista de hechizos\" eleg\195\173s cuales.";
L["CB_LOCK_ENEMYALERT"]          = "Fijar en su lugar";
L["TIP_EnemyAlertLocked"]        = "Bloqueado ignora el mouse: pod\195\169s hacer click a trav\195\169s.";
L["PVP_ENEMY_CD"]                = "Contador de cooldowns defensivos enemigos";
L["PVP_ENEMY_DISPEL"]            = "Aviso de dispel / purga recibida";
L["PVP_ENEMY_RES"]               = "Aviso de resurrecci\195\179n enemiga";
L["PVP_SELF_HEADER"]             = "Tu propio estado";
L["PVP_SELF_NOTE"]               = "Recordatorios de tus cooldowns y del control que te comes.";
L["PVP_SELF_CC"]                 = "Temporizador del control que te aplican";
L["PVP_SELF_DR"]                 = "Barra de diminishing returns";
L["PVP_SELF_BUFFS"]              = "Recordatorio de buffos faltantes en la puerta";
L["TIP_MageWaterEle"]            = "Barra de duraci\195\179n del elemental de agua. Se oculta sola si ten\195\169s el glifo de Agua Eterna, porque ah\195\173 el elemental es permanente.";
L["TIP_MageMirror"]              = "Barra de 30 segundos para Im\195\161genes Espejo.";

L["TAB_EXTRA"]                   = "Perfiles";
L["TAB_ABOUT"]                   = "About";

-- Tab 1 - General
L["HEADER_GENERAL"]              = "|cffFFD100Configuración General|r";
L["DESC_GENERAL"]                = "Opciones visuales básicas y posicionamiento de frames";
L["CB_CLASS_COLOR"]              = "Barras de vida por clase";
L["CB_BACKDROP"]                 = "Fondo de barras";
L["CB_HEALTH_PCT"]               = "Porcentaje de vida";
L["CB_CASTING_TIMERS"]           = "Tiempo de Casteo";
L["HEADER_POSITIONS"]            = "|cffFFD100Posiciones & Arrastrables|r";
L["POS_HINT_ENABLE"]            = "|cffFFCC44Activá Custom Positions|r |cffAAAAAApara mover Player, Target y Party.|r";
L["POS_HINT_DRAG"]              = "|cff6699FFShift+Alt+Click|r |cffAAAAAApara arrastrar un frame.|r";
L["CB_CUSTOM_POS"]               = "Usar Posiciones Custom";
L["CB_LOCK_POS"]                 = "Bloquear Posiciones";
L["CB_PARTY_INDIVIDUAL"]         = "Mover Party Individual";
L["CB_PARTY_3V3"]                = "Modo Party 3v3";
L["HEADER_THEME"]                = "|cffFFD100Tema Visual|r";
L["DRAG_HINT"]                   = "|cffAAAAAA(Shift+Alt+Click para arrastrar frames)|r";
L["BTN_RESET_POS"]               = "Resetear Posiciones & Escala";
L["RESET_POS_DONE"]              = "\194\161Posiciones y escala reseteadas!";
L["RESET_POS_CONFIRM"]           = "\194\191Resetear todas las posiciones y escalas a default?\n\n|cffFFAA00No va a recargar la UI.|r";
L["RESET_POS_BTN_YES"]           = "Resetear";
L["RESET_POS_BTN_NO"]            = "Cancelar";
L["THEME_DARK"]                  = "Tema actual: |cff888888Oscuro|r";
L["THEME_LIGHT"]                 = "Tema actual: |cffEEEEEEClaro|r";
L["THEME_HINT"]                  = "Para cambiar tema: Editá |cffFFD100Config/Settings.lua|r (C[\"darkFrames\"]) y /reload";

-- Tab 2 - Frames
L["HEADER_FRAMES"]               = "|cffFFD100Configuración de Frames|r";
L["DESC_FRAMES"]                 = "Ajustá escala y espaciado para player/target/party";
L["SLIDER_PLAYER_SCALE"]         = "Escala Player Frame";
L["SLIDER_TARGET_SCALE"]         = "Escala Target Frame";
L["HEADER_FOCUS"]                = "|cffFFD100Focus|r";
L["SLIDER_FOCUS_SCALE"]          = "Escala Focus";
L["SLIDER_FOCUS_SPELLBAR"]       = "Escala de la barra del foco";
L["HEADER_PARTY"]                = "|cffFFD100Party|r";
L["HEADER_PARTY_FEATURES"]      = "|cffAAAAAA\226\128\148 Funciones de Party \226\128\148|r";
L["CB_PARTY_BUFFS"]              = "Party Buffs";
L["CB_PARTY_TARGETS"]            = "Party Targets";
L["SLIDER_PARTY_SCALE"]          = "Escala Party Frame";
L["SLIDER_PARTY_SPACING"]        = "Espaciado Party";

-- Missing keys for Frames/General panels
L["CB_NEW_PARTY_FRAME"]          = "Nuevo Party Frame";
L["SLIDER_BOSS_SCALE"]           = "Escala Boss Frame";
L["SLIDER_ACTIONBAR_SCALE"]      = "Escala Barra de Acción";
L["CB_MINIBAR"]                  = "MiniBar";
L["CB_HIDE_GRYPHONS"]            = "Ocultar Grifos";
L["CB_BAGPACK"]                  = "Fondo de Mochila";

-- Tab 3 - Arena
L["HEADER_ARENA_BOSS"]           = "|cffFFD100Arena & Boss|r";
L["DESC_ARENA_BOSS"]             = "Configuración de frames PvP y PvE";
L["HEADER_BOSS"]                 = "|cffFFD100Boss Frames|r";
L["SLIDER_BOSS_SPACING"]         = "Espaciado Boss Frames";
L["HEADER_ARENA"]                = "|cffFFD100Arena Frames|r";
L["DESC_ARENA"]                  = "Configuración de frames PvP de arena";
L["CB_ARENA_ON"]                 = "Activar Mod Arena Frame";
L["CB_ARENA_CUSTOM_TEX"]         = "Textura Custom Arena";
L["LABEL_ARENA_STYLE"]           = "Estilo Arena";
L["SLIDER_ARENA_SCALE"]          = "Escala Arena Frame";
L["SLIDER_ARENA_SPACING"]        = "Espaciado Arena Frame";
L["BTN_SHOW_ARENA"]              = "Mostrar Arena Frame";
L["BTN_SHOW_BOSS"]               = "Mostrar Boss Frame";
L["BTN_RESET_FLAT"]              = "Reset";
L["ARENA_HINT"]                  = "Usá |cff00FFFF/nuf arena|r\npara mostrar/ocultar\nel mover de arena";
L["ARENA_MOVE_HINT"]             = "|cffFFAA00\226\128\160Shift+Alt+Click para mover varios elementos|r";
L["HEADER_ARENA_MODULES"]        = "|cffFFD100Módulos de Arena|r";
L["CB_MIRROR_MODE"]              = "Modo Espejo Arena";
L["CB_TRINKET_TRACK"]            = "Rastreo Trinkets Arena";
L["CB_TRINKET_VOICE"]            = "Alerta de Voz Trinkets";

-- Flat Style UI
L["CB_FLAT_MIRRORED"]            = "Flat Espejado";
L["SLIDER_FLAT_WIDTH"]           = "Ancho Flat";
L["SLIDER_FLAT_HB_HEIGHT"]      = "Altura Barra Vida";
L["SLIDER_FLAT_PB_HEIGHT"]      = "Altura Barra Poder";
L["SLIDER_FLAT_HB_FONT"]        = "Fuente Vida";
L["SLIDER_FLAT_PB_FONT"]        = "Fuente Poder";

-- Cast Bar UI
L["HEADER_CASTBAR"]              = "|cffFFD100Barra de Casteo|r";
L["CB_CASTBAR_ENABLE"]           = "Cast Bar Custom";
L["SLIDER_CASTBAR_SCALE"]       = "Escala Cast Bar";
L["SLIDER_CASTBAR_WIDTH"]       = "Ancho Cast Bar";

-- Pet Frame
L["CB_PET_FRAME_SHOW"]          = "Mostrar Pet Frame (Modo Prueba)";
L["CB_FLAT_PET_STYLE"]          = "Estilo Flat para Pet";
L["CB_FLAT_STATUS_TEXT"]        = "Forzar Texto de Vida";
L["LABEL_PET_STYLE"]            = "Estilo Pet Frame (solo Flat)";

-- Visual Theme
L["LABEL_THEME"]                 = "Tema Visual";
L["THEME_OPT_LIGHT"]            = "Claro";
L["THEME_OPT_DARK"]             = "Oscuro";
L["THEME_CHANGED"]              = "|cffFFD100NUF:|r Tema cambiado. |cffFFAA00/reload para aplicar.|r";
L["CB_UNITFRAME_CUSTOM_TEX"]    = "Skin Personalizado (Player/Target/Focus)";
L["TIP_UnitFrameCustomTexture"] = "Usa texturas .blp custom en Player, Target y Focus (marco, ícono PVP, tamaño de barras, ícono de status).\nDesactivar restaura los frames predeterminados de Blizzard.\n\n"..INSTANTE;

-- Flat Style labels (sArena style)
L["SLIDER_FLAT_WIDTH_FULL"]      = "Ancho del marco";
L["SLIDER_FLAT_HB_HEIGHT_FULL"]  = "Altura barra de vida";
L["SLIDER_FLAT_PB_HEIGHT_FULL"]  = "Altura barra de poder";
L["SLIDER_FLAT_HB_FONT_FULL"]   = "Fuente de vida";
L["SLIDER_FLAT_PB_FONT_FULL"]   = "Fuente de poder";
L["CB_FLAT_MIRRORED_FULL"]      = "Frames Espejados";

-- Tab 4 - Modules
L["HEADER_MODULES"]              = "|cffFFD100Módulos|r";
L["DESC_MODULES"]                = "Activá o desactivá módulos extra. Agregá archivos .lua en Modules2/";
L["MODULES_NONE"]                = "|cffAAAAAA(No hay módulos registrados)|r";
L["MODULES_ENABLED"]             = "|cffFFD100\226\156\147 Habilitado|r";
L["MODULES_DISABLED"]            = "|cffFF0000\226\156\151 Deshabilitado|r";
L["MODULES_HOWTO"]               = "|cffFFFF00Cómo agregar módulos:|r\n\n"..
	"1. Poné tu archivo .lua en la carpeta |cffFFD100Modules2/|r\n\n"..
	"2. Agregá esto al principio del archivo:\n"..
	"   |cff00FFFF"..
	'K.RegisterModule("NombreModulo", {\n'..
	'       name = "Mi Modulo",\n'..
	'       desc = "Descripción del módulo",\n'..
	"   })|r\n\n"..
	"3. Agregá la línea al archivo |cffFFD100.toc|r:\n"..
	"   |cff00FFFFModules2/NombreModulo.lua|r\n\n"..
	"4. Hacé |cffFFAA00/reload|r y el checkbox aparece acá automáticamente.";

-- Bottom buttons
L["BTN_RELOAD"]                  = "Recargar UI";
L["BTN_RESET"]                   = "Resetear";
L["BTN_CLOSE"]                   = "Cerrar";
L["BTN_SHOW_CONFIG"]             = "Ver Config";
L["RESET_CONFIRM"]               = "¿Resetear TODO a los valores de fábrica?\n\nOpciones, módulos prendidos/apagados, posiciones y escalas.\nTus perfiles guardados se conservan.\n\n|cffFF0000¡Se va a recargar la UI!|r";
L["RESET_BTN_YES"]               = "Resetear";
L["RESET_BTN_NO"]                = "Cancelar";

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

L["PETTARGET_PREFIX"]            = "Objetivo: ";
L["PETTARGET_NONE"]              = "Objetivo: Ninguno";
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
L["APC_BTN_TIP_DRAG"]            = "Alt + arrastrar para moverlo";
L["APC_BTN_RESET_DONE"]          = "Posición del botón restablecida.";
L["TT_SOLO_QUEUE"]               = "Solo Queue";

-- Party Targets
L["PT_HIDE_NAME"]                = "Ocultar el nombre del objetivo";
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
L["LORTI_SUBOPTIONS"]            = "Sub-opciones (requiere /reload):";
L["MOVER_DRAG"]                  = "NUF - arrastrar para mover";
L["MOVER_HINT"]                  = "Shift+Alt+Click para mover varios elementos";
L["BOSS_DRAG"]                   = "FRAMES DE BOSS [arrastrar]";
L["HP_NA"]                       = "N/D";
L["HP_DEAD"]                     = "Muerto";

-- Paneles de Config
L["PANEL_STYLE"]                 = "Estilo";
L["TIP_PANEL_THEME"]             = "Cambiar el tema del panel";
L["ARENA_PET_STYLE"]             = "Estilo de Mascota";
L["ARENA_TOT"]                   = "Objetivo del Objetivo";
L["PROFILE_NONE_YET"]            = "(Todavía no hay perfiles)";
L["SLOT_NONE_YET"]               = "(Todavía no hay personajes)";
L["ERR_PREFIX"]                  = "Error: ";
L["CMD_MODULE_OFF"]              = "%s est\195\161 apagado. Prendelo en el panel de opciones para poder usar sus comandos.";
L["PVP_HINT_EXPAND"]             = "Tild\195\161 un m\195\179dulo para ver sus opciones.";
L["SLIDER_BUFF_SCALE"]           = "Escala de buffs";
L["SLIDER_DEBUFF_SCALE"]         = "Escala de debuffs";
L["BARS_RELOADING"]              = "Cambiaste el modo de barras \226\128\148 recargando la interfaz...";

-- Claves que se usaban en el codigo pero nunca se habian definido.
L["BTN_RESET_CASTBAR"]           = "Resetear";
L["BTN_RESET_PET_POS"]           = "Resetear";
L["CB_ARENA_COUNTDOWN"]          = "Cuenta regresiva de Arena + Vista Sombría";
L["LABEL_PARTY_MEMBER"]          = "Grupo";
L["MOD_MELEESWING"]              = "Timer de Golpe Melee";
L["MOD_MELEESWING_DESC"]         = "Muestra el tiempo que falta para tu próximo golpe cuerpo a cuerpo.";
L["TIP_HideChatButton"]          = "Oculta el botón del menú del chat.";

-- Tab 5 - Extra Options
L["HEADER_EXTRA"]                = "|cffFFD100Opciones Extra|r";
L["DESC_EXTRA"]                  = "Configuraciones adicionales y funciones experimentales";

-- Profiles
L["HEADER_PROFILES"]             = "|cffFFD100Perfiles|r";
L["DESC_PROFILES"]               = "Exportá tu config para compartir o backup, importá para restaurar.";
L["BTN_EXPORT"]                  = "Exportar Perfil";
L["BTN_IMPORT"]                  = "Importar Perfil";
L["BTN_COPY"]                    = "Copiar";
L["PROFILE_COPY_FROM"]           = "Copiar perfil de:";
L["PROFILE_CURRENT"]             = "actual";
L["PROFILE_ERR_SELECT"]          = "Selecciona un perfil primero!";
L["PROFILE_ERR_CURRENT"]         = "Ese es tu perfil actual!";
L["PROFILE_COPYING"]             = "Copiando perfil de";
L["TIP_EXPORT"]                  = "Genera un texto con toda tu configuración.\nCopialo y guardalo en un lugar seguro.";
L["TIP_IMPORT"]                  = "Pegá un texto de perfil para restaurar configuración.\nEsto va a sobreescribir tu config actual y recargar la UI.";

-- Character Setup (barras / macros / bindeos) - NADA que ver con los
-- perfiles de arriba, que son la config del addon.
L["HEADER_SLOTS"]                = "|cffFFD100Personaje|r";
L["DESC_SLOTS"]                  = "Barras, macros y bindeos. Esto es tu personaje, no la config del addon.";
L["SLOT_COPY_FROM"]              = "Copiar barras y macros de:";
L["SLOT_BTN_EXPORT"]             = "Exportar";
L["SLOT_BTN_IMPORT"]             = "Importar";
L["SLOT_EXPORT_TITLE"]           = "|cffFFD100Exportar Personaje|r";
L["SLOT_IMPORT_TITLE"]           = "|cffFFAA00Importar Personaje|r";
L["SLOT_EXPORT_HINT"]            = "|cffAAAAAA(Ctrl+A para seleccionar, Ctrl+C para copiar. Compatible con MySlot.)|r";
L["SLOT_IMPORT_HINT"]            = "|cffAAAAAA(Pegá una cadena y apretá Importar)|r";
L["SLOT_BTN_WIPEBARS"]           = "Vaciar Barras";
L["SLOT_BTN_WIPEMACROS"]         = "Borrar Macros";
L["SLOT_BTN_RESETBINDS"]         = "Teclas por Defecto";
L["SLOT_BTN_UNDO"]               = "Deshacer";
L["SLOT_CONFIRM_WIPEBARS"]       = "¿Vaciar las %d casillas de las barras?\n\nSe guarda un backup antes: con Deshacer las recuperás.";
L["SLOT_CONFIRM_WIPEMACROS"]     = "¿Borrar las %d macros?\n\nSe guarda un backup antes: con Deshacer las recuperás.";
L["SLOT_CONFIRM_RESETBINDS"]     = "¿Volver a los bindeos por defecto de Blizzard?\n\nSe guarda un backup antes: con Deshacer los recuperás.";
L["SLOT_CONFIRM_IMPORT"]         = "¿Aplicar esta configuración a %s?\n\nTus barras, macros y bindeos actuales se van a sobreescribir.\nSe guarda un backup antes.";
L["SLOT_DONE_IMPORT"]            = "Aplicado: %d casillas, %d bindeos.";
L["SLOT_DONE_WIPEBARS"]          = "Se vaciaron %d casillas.";
L["SLOT_DONE_WIPEMACROS"]        = "Se borraron %d macros.";
L["SLOT_DONE_RESETBINDS"]        = "Bindeos por defecto restaurados.";
L["SLOT_BACKUP_DONE"]            = "Backup restaurado.";
L["SLOT_ERR_COMBAT"]             = "No se puede hacer esto en combate.";
L["SLOT_ERR_EMPTY"]              = "Pegá una cadena primero.";
L["SLOT_ERR_DECODE"]             = "La cadena está corrupta o incompleta.";
L["SLOT_ERR_PARSE"]              = "Cadena inválida: ";
L["SLOT_ERR_NOBACKUP"]           = "Todavía no hay backup.";
L["SLOT_ERR_NOPROFILE"]          = "Esa configuración ya no existe.";
L["SLOT_MACRO_FULL"]             = "Macro '%s' salteada: no quedan espacios de macro libres.";
L["SLOT_NOTE_LOGOUT"]            = "Para copiar entre personajes tenés que SALIR DEL JUEGO (no /reload), porque recién ahí se escriben los datos al disco.";
L["TIP_SLOT_EXPORT"]             = "Genera un texto con tus barras, macros y bindeos.\nCompatible con las cadenas de MySlot.";
L["TIP_SLOT_IMPORT"]             = "Pegá una cadena para aplicarla a este personaje.\nLos hechizos que tu personaje no sepa se saltean.";

L["PROFILE_EXPORT_TITLE"]        = "|cffFFD100Exportar Perfil|r";
L["PROFILE_EXPORT_HINT"]         = "|cffAAAAAA(Ctrl+A para seleccionar todo, Ctrl+C para copiar)|r";
L["PROFILE_IMPORT_TITLE"]        = "|cffFFAA00Importar Perfil|r";
L["PROFILE_IMPORT_HINT"]         = "|cffAAAAAA(Pegá tu texto de perfil, después hacé click en Importar)|r";
L["PROFILE_IMPORT_BTN"]          = "Importar";
L["PROFILE_CANCEL"]              = "Cancelar";
L["PROFILE_IMPORT_EMPTY"]        = "\194\161Pegá un texto de perfil primero!";
L["PROFILE_IMPORT_ERROR"]        = "Error al importar: ";
L["PROFILE_IMPORT_SUCCESS"]      = "\194\161Perfil importado! Recargando...";

-- Utility
L["HEADER_UTILITY"]              = "|cffFFD100Utilidades|r";
L["CB_AUTO_SELL"]                = "Vender Grises Automático";
L["TIP_AutoSellGray"]            = "Vende automáticamente todos los items grises al abrir un vendor.";
L["CB_AUTO_REPAIR"]              = "Reparar Automático";
L["TIP_AutoRepair"]              = "Repara automáticamente al abrir un vendor.\nUsa banco de guild primero si está disponible.\nMantené Shift para saltear.";
L["CB_ERROR_HIDE"]               = "Ocultar Errores en Combate";
L["TIP_ErrorHideInCombat"]       = "Oculta los mensajes de error rojos durante combate.\nLos muestra de nuevo al salir de combate.";

-- Timers de Arena
L["HEADER_ARENA_TIMERS"]         = "|cffFFD100Timers de Arena|r";
L["CB_DALARAN_PIPE"]             = "Timer de la Cascada de Dalaran";
L["TIP_ArenaDalaranPipeTimer"]   = "Muestra un icono con cuenta regresiva de 10s antes de que la cascada de la Arena de Dalaran tire a los jugadores de la tuber\195\173a.";
L["CB_ROV_PILLARS"]              = "Timer de Pilares (C\195\173rculo de Valor)";
L["TIP_ArenaRoVPillarTimer"]     = "Muestra cu\195\161ndo suben los pilares en la arena C\195\173rculo de Valor.\nPrimer ciclo 45s, despu\195\169s cada 25s.";
L["CB_ARENA_END"]                = "Tiempo Restante de Arena";
L["TIP_ArenaEndTimer"]           = "Muestra cu\195\161nto falta para que la arena termine en empate.";
L["ARENA_END_PREFIX"]            = "Arena: ";
L["TIMERS_TEST_HINT"]            = "Modo test de timers activado/desactivado. Manten\195\169 Alt y arrastr\195\161 para moverlos.";

-- Texto de Barras de Acci\195\179n
L["HEADER_BAR_TEXT"]             = "|cffFFD100Texto de Barras|r";
L["CB_HIDE_KEYBIND"]             = "Ocultar Texto de Bindeos";
L["TIP_HideKeybindText"]         = "Oculta el texto de las teclas en los botones de las barras de acci\195\179n.";
L["CB_HIDE_MACRO"]               = "Ocultar Nombres de Macros";
L["TIP_HideMacroText"]           = "Oculta el nombre de las macros en los botones de las barras de acci\195\179n.";

-- Subpesta\195\177as de Frames
L["BTN_RESET_SCALES"]            = "Restablecer todas las escalas";
L["BTN_RESET_POSITIONS"]         = "Restablecer posiciones";
L["SCALES_RESET_DONE"]           = "Escalas y posiciones reseteadas. /reload para restaurar todo de f\195\161brica.";
L["SUBTAB_FR_SCALES"]            = "Frames";
L["SUBTAB_FR_POSITIONS"]         = "Posiciones";
L["SUBTAB_FR_PARTY"]             = "Party";
L["SUBTAB_FR_PVE"]               = "PvE";
L["HEADER_PVE"]                  = "PvE";
L["DESC_PVE"]                    = "Marcos de boss y opciones de bandas.";
L["PARTY_3V3_NOTE"]              = "El modo 3v3 y el movimiento individual est\195\161n en la subpesta\195\177a Posiciones.";

-- Mover todo
L["MOVE_RESET_DONE"]             = "Todos los marcos volvieron a su posici\195\179n por defecto.";
L["MOVE_HELP_ALL"]               = "desbloquear todo";
L["MOVE_HELP_FRAMES"]            = "solo los marcos de unidad";
L["MOVE_HELP_LOCK"]              = "volver a bloquear";
L["MOVE_HELP_RESET"]             = "volver a las posiciones por defecto";
L["MOVER_HINT_SCALE"]            = "Ctrl + rueda del mouse sobre un recuadro para escalarlo";
L["MOVER_CONSOLE"]                = "Mover todo";
L["LBL_MOVE_GRID"]               = "Cuadr\195\173cula";
L["DESC_MOVE_GRID"]              = "Al arrastrar, los marcos se enganchan a una cuadr\195\173cula, as\195\173 alinear dos es f\195\161cil. Cuanto m\195\161s chico el paso, m\195\161s libre el movimiento.";
L["TIP_MOVE_GRID"]               = "Casilleros de %d p\195\173xeles de lado.";
L["HEADER_MOVE_ALL"]             = "|cffFFD100Mover Todo|r";
L["DESC_MOVE_ALL"]               = "Desbloquea Player, Target, Focus, Party, barras de acci\195\179n, buffs, debuffs, barra de casteo y las barras de timers de NUF. Arrastr\195\161 los recuadros azules y despu\195\169s volv\195\169 a bloquear.";
L["BTN_MOVE_ALL"]                = "Desbloquear Todo";
L["HEADER_MOVE_FRAMES"]          = "|cffFFD100Mover Marcos de Unidad|r";
L["DESC_MOVE_FRAMES"]            = "Desbloquea solo Player, Target, Focus, Party, Arena y Boss. Arrastr\195\161 los recuadros azules, Ctrl + rueda para agrandar, y volv\195\169 a bloquear.";
L["BTN_MOVE_FRAMES"]             = "Desbloquear Marcos";
L["PARTYTEST_ON"]                = "Modo prueba de party ACTIVADO - 4 miembros falsos. /nufparty para apagarlo.";
L["PARTYTEST_OFF"]               = "Modo prueba de party DESACTIVADO.";
L["PARTYTEST_COMBAT"]            = "No se puede activar el modo prueba de party en combate.";
L["BTN_MOVE_ALL_DONE"]           = "Bloquear Todo";
L["BTN_OPEN"]                    = "Abrir";
L["BTN_MOVE_RESET"]              = "Resetear";
L["MOVE_ON"]                     = "Modo mover ACTIVADO - arrastr\195\161 los recuadros azules. /nufmove para terminar.";
L["MOVE_OFF"]                    = "Modo mover DESACTIVADO - posiciones guardadas.";
L["MOVE_RESET"]                  = "Posiciones borradas. /reload para volver a las de f\195\161brica.";
L["MOVE_COMBAT_BLOCK"]           = "Las barras de acci\195\179n no se pueden mover en combate.";

-- Minimapa
L["MOD_MINIMAP_TOGGLE"]          = "Ocultar Iconos del Minimapa";
L["MOD_MINIMAP_TOGGLE_DESC"]     = "Bot\195\179n en la esquina del minimapa que oculta o muestra todos sus iconos.";
L["MINIMAP_TOGGLE_TITLE"]        = "Iconos del Minimapa";
L["MINIMAP_TOGGLE_TIP"]          = "Click para ocultar o mostrar todos los iconos del minimapa (zoom, reloj, addons).";
L["MINIMAP_TOGGLE_DISABLED"]     = "Activ\195\161 primero el m\195\179dulo Ocultar Iconos del Minimapa.";

L["BTN_MODULE_CONFIG"]           = "Configurar";
L["BTN_MODULE_MOVE"]             = "Mover";
L["BTN_MODULE_TOGGLE"]           = "Alternar";

-- Modulos nuevos
L["MOD_ARROWCOUNT"]              = "Contador de Flechas / Balas";
L["MOD_DUNGEONROLES"]            = "Roles del buscador de mazmorras";
L["MOD_DUNGEONROLES_DESC"]       = "Mientras estas en la cola, muestra tanque, sanador y 3 dps, y enciende los puestos que ya estan cubiertos. Alt + arrastrar para moverlo.";
L["MOD_ARROWCOUNT_DESC"]         = "Muestra cu\195\161nta munici\195\179n te queda. Alt + arrastrar para moverlo.";
L["MOD_POWERBAR"]                = "Barra de Recurso";
L["MOD_POWERBAR_DESC"]           = "Barra movible de man\195\161 / energ\195\173a / rabia / poder r\195\186nico al lado del personaje. Alt + arrastrar para moverla.";
L["BAR_WATER_ELE"]               = "Elemental de Agua";
L["BAR_MIRROR"]                  = "Im\195\161genes Espejo";
L["MOD_AUTOSHOT"]                = "Timer de Disparo Autom\195\161tico";
L["MOD_AUTOSHOT_DESC"]           = "Barra con el tiempo del disparo autom\195\161tico del cazador. /nufshot unlock para moverla.";
L["MOD_SWINGTIMER"]              = "Timer de Golpe Cuerpo a Cuerpo";
L["MOD_SWINGTIMER_DESC"]         = "Barra con el tiempo hasta tu pr\195\179ximo golpe blanco de melee. /nufswing unlock para moverla.";
L["SWING_LABEL"]                 = "Auto attack";
L["THEME_OPT_ASURI"]             = "Asuri";
L["THEME_OPT_PW"]                = "Compacto";
L["PVP_PALADIN_AURAS"]           = "Auras";
L["PVP_PALADIN_AURAS_NOTE"]      = "Proc de Holy Strength, reducci\195\179n de curaci\195\179n (Mortal Strike / Aimed Shot / Wound Poison) sobre cualquiera del grupo, y cooldown de The Art of War.";
L["MOD_TURN_EVIL"]               = "Rastreador de Turn Evil";
L["MOD_TURN_EVIL_DESC"]          = "Pila de hasta 3 iconos con los del grupo que tienen Turn Evil encima.";
L["MOD_PALADIN_AURAS"]           = "Paladin tracker";
L["MOD_PALADIN_AURAS_DESC"]      = "Proc de Holy Strength, reducci\195\179n de curaci\195\179n sobre cualquiera del grupo, y cooldown de The Art of War. /nufpal para moverlas.";
L["SLIDER_PARTY_FONT_SIZE"]      = "Tama\195\177o del texto";
L["PARTY_FONT_AUTO"]             = "Auto";
L["TIP_PartyFontSize"]           = "Tama\195\177o de los n\195\186meros de vida y man\195\161 del grupo. En Auto usa el tama\195\177o propio del estilo elegido.";
L["CB_PARTY_HIDE_TEXT"]          = "Ocultar texto vida/man\195\161";
L["TIP_PartyHideHealthManaText"] = "Oculta los n\195\186meros de vida y man\195\161 sobre las barras del grupo (no afecta Arena / Player / Target).\nLas barras siguen visibles, solo se oculta el texto.";
L["CB_FULL_VALUE"]               = "Vida completa (sin /max)";
L["TIP_ShowCurrentValueOnly"]    = "Muestra \"33401\" en vez de \"33401 / 33401\" en las barras de vida y man\195\161.";
L["HEADER_PARTY_FONT"]           = "Contorno del texto";
L["LBL_PARTY_FONT"]              = "Contorno";
L["OUTLINE_NONE"]                = "Ninguno";
L["OUTLINE_NORMAL"]              = "Contorno";
L["OUTLINE_THICK"]               = "Contorno grueso";
L["OUTLINE_BLIZZ"]               = "Como el texto de vida/man\195\161";
L["HEADER_CLASS_INDICATORS"]     = "Indicadores de color de clase";
L["MOD_CLASSOUTLINE"]            = "Contorno del color de clase";
L["MOD_CLASSOUTLINE_DESC"]       = "Agrega un anillo del color de la clase alrededor de los retratos de jugador, objetivo y foco.";
L["SLIDER_OUTLINE_SIZE"]         = "Tama\195\177o del anillo";
L["SWING_USE_GLOBAL"]            = "Mover todo esta activo: arrastr\195\161 la caja azul desde ahi.";

-- Barras
L["SUBTAB_GEN_UI"]               = "Interfaz";
L["SUBTAB_GEN_BARS"]             = "Barras";
L["CB_HIDE_BAR_TEXTURES"]        = "Ocultar Texturas de las Barras";
L["TIP_HideBarTextures"]         = "Oculta las texturas decorativas de la barra de acci\195\179n principal.";
L["CB_BUTTON_RANGE"]             = "Button Range";
L["TIP_ButtonRange"]             = "Pinta de rojo los botones cuando el objetivo est\195\161 fuera de alcance.";

-- Subpesta\195\177as
L["SUBTAB_ARENA_FRAMES"]         = "Frames";
L["SUBTAB_ARENA_TIMERS"]         = "Timers";
L["SUBTAB_ARENA_MODULES"]        = "Opciones";
L["HEADER_ARENA_QUEUE"]          = "|cffFFD100Cola|r";
L["CB_ARENA_TIMES"]              = "Tiempo de cola + timer del popup";
L["TIP_ArenaTimes"]              = "Muestra una barra de cuenta regresiva en el popup de invitaci\195\179n a la arena y el tiempo de cola al lado del minimapa.";
L["CB_ARENA_TOT"]                = "Activar Target of Target";
L["TIP_ArenaToT"]                = "Muestra el objetivo actual de cada enemigo en arena.";
L["TIMERS_MOVE_NOTE"]            = "Us\195\161 /nuftimers para mostrar los timers y Alt + arrastrar para moverlos.";

-- Color de Nombres
L["HEADER_NAME_COLOR"]           = "|cffFFD100Color de Nombres|r";
L["NAME_COLOR_DEFAULT"]          = "Default";
L["NAME_COLOR_WHITE"]            = "Blanco";
L["NAME_COLOR_CLASS"]            = "Clase";
L["CB_SIDEBARS_HOVER"]           = "Mostrar barras laterales al pasar el mouse";
L["TIP_SideBarsHover"]           = "Las barras laterales quedan ocultas y solo aparecen cuando el mouse est\195\161 encima. Igual siguen funcionando mientras est\195\161n ocultas.";
L["HEADER_BAR_MOVE"]             = "|cffFFD100Posici\195\179n|r";
L["NOTE_BAR_MOVE"]               = "Activa el modo mover: arrastr\195\161 la caja azul para ubicar las barras de acci\195\179n. Toc\195\161 de nuevo para fijar y guardar.";
L["BTN_MOVE_BARS"]               = "Mover barras de acci\195\179n";
L["BTN_LOCK_BARS"]               = "Fijar barras";
L["NAME_BORDER"]                 = "Borde del nombre";
L["NAME_BORDER_NONE"]            = "Ninguno";
L["NAME_BORDER_OUTLINE"]         = "Contorno";
L["NAME_BORDER_THICK"]           = "Contorno grueso";
L["NAME_BORDER_SHADOW"]          = "Como el texto de vida/man\195\161";
L["TIP_UnitNameColorMode"]       = "Color de los nombres en los marcos de Player, Target, Focus, Party y Arena.\n\nDefault: colores de Blizzard\nBlanco: todos los nombres en blanco\nClase: nombres con el color de la clase\n\nVolver a Default puede requerir /reload.";

-- Chat
L["HEADER_CHAT"]                 = "|cffFFD100Chat|r";
L["CB_CHAT_COPY"]                = "Copiar Texto del Chat";
L["TIP_ChatCopyEnabled"]         = "Doble click en la pesta\195\177a del chat abre una vista copiable del historial.\nUs\195\161 Ctrl+A / Ctrl+C, Escape para cerrar.\nTambi\195\169n con /nufcopy.";
L["CB_CHAT_URLS"]                = "Links Clicables";
L["TIP_ChatClickableURLs"]       = "Convierte las URLs escritas en el chat en links clicables.\nAl hacer click se abre una ventanita con el link listo para copiar.";
L["CHATCOPY_DISABLED"]           = "La copia del chat est\195\161 desactivada en las opciones.";
L["URL_POPUP_TEXT"]              = "Copi\195\161 el link (Ctrl+C):";

-- Module collapse
L["MODULE_EXPAND"]               = "Click para expandir opciones";
L["MODULE_COLLAPSE"]             = "Click para colapsar opciones";
L["COLLAPSE_ICON_EXPAND"]        = "[>]";
L["COLLAPSE_ICON_COLLAPSE"]      = "[v]";

-- Tab 6 - About
L["HEADER_ABOUT"]                = "|cffFFD100Acerca de|r";
L["ABOUT_ADDON_NAME"]            = "|cffffffffNidhaus|r |cffFFD100UnitFrames|r";
L["ABOUT_DESCRIPTION"]           = "Un addon de interfaz enfocado en PVP para WoW WotLK 3.3.5a.\nArena frames custom, tracking de trinkets, modo espejo,\nbarras de vida por clase, y posicionamiento optimizado\ndiseñado para arena competitivo.";
L["ABOUT_VERSION"]               = "|cffFFAA00Versión:|r 3.6";
L["ABOUT_COMMANDS_HEADER"]       = "|cffFFAA00Comandos:|r";
L["ABOUT_CMD_OPTIONS"]           = "|cffFFFFFF/nuf|r — Abrir panel de opciones";
L["ABOUT_CMD_CONFIG"]            = "|cffFFFFFF/nuf config|r — Mostrar variables guardadas";
L["ABOUT_CMD_ARENA"]             = "|cffFFFFFF/nuf arena|r — Toggle modo test de arena";
L["ABOUT_CMD_BOSS"]              = "|cffFFFFFF/nuf boss|r — Toggle modo test de boss";
L["ABOUT_CMD_RESET"]             = "|cffFFFFFF/nuf reset|r — Resetear configuración";
L["ABOUT_GITHUB_LABEL"]          = "|cffFFAA00GitHub:|r";
L["ABOUT_GITHUB_LINK"]           = "https://github.com/nidas-wow-oss";
L["ABOUT_CONTACT_LABEL"]         = "|cffFFAA00Discord:|r";
L["ABOUT_CONTACT_LINK"]          = "https://discord.gg/p3sqeram";
L["ABOUT_COPY_HINT"]             = "|cffAAAAAA(Click para seleccionar, Ctrl+C para copiar)|r";

-- === MINIMAP BUTTON ===
L["MINIMAP_LEFT_CLICK"]          = "|cffFFFFFFClick Izquierdo:|r Abrir Opciones";
L["MINIMAP_RIGHT_CLICK"]         = "|cffFFFFFFClick Derecho:|r Toggle Arena Mover";
L["MINIMAP_CTRL_CLICK"]          = "|cffFFFFFFCtrl + Click:|r Mover todo";
L["MINIMAP_SHIFT_CLICK"]         = "|cffFFFFFFShift + Click:|r Recargar UI";
L["MINIMAP_DRAG"]                = "|cffFFFFFFArrastrar:|r Mover icono";

-- === UNIFY ACTION BARS MODULE ===
L["MOD_UAB_NAME"]          = "Unificar Barras de Acción";
L["MOD_UAB_DESC"]          = "Reposiciona y limpia los elementos de la barra de acción.";
L["MOD_UAB_DISABLED"]      = "|cffFFD100NUF:|r Unify Action Bars desactivado.";
L["HEADER_ACTIONBARS"]     = "|cffFFD100Barras de Acción|r";
L["CB_UNIFY_ACTIONBARS"]   = "Unificar Barras de Acción";
L["TIP_UnifyActionBars"]   = "Reposiciona y limpia los elementos de la barra de acción:\nbolsas, micro menú, barra de mascota, posturas y botones de paginado.";

end -- isSpanish