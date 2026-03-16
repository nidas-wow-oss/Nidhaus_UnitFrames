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
local INSTANT = "|cff00FF00\226\156\147 Applies instantly|r";
local RELOAD  = "|cffFFAA00\226\154\160 Requires /reload|r";

-- === TOOLTIPS ===
L["TIP_classColor"]              = "Colors health bars by class.";
L["TIP_statusbarBackdrop"]       = "Adds dark background to bars.\n\n"..RELOAD;
L["TIP_HealthPercentage"]        = "Shows health % on target.";
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
L["TIP_PartyCastingBars"]       = "Shows a casting bar next to each party member's unit frame.\nRequires the PartyCastingBars sub-addon to be loaded.";
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
L["PANEL_VERSION"]               = "|cffFFAA00v3.5|r";
L["PANEL_SUBTITLE"]              = "Unit Frame Customization & Arena Tools";

-- Tabs
L["TAB_GENERAL"]                 = "General";
L["TAB_FRAMES"]                  = "Frames";
L["TAB_ARENA"]                   = "Arena";
L["TAB_ARENA_BOSS"]              = "Arena/Boss";
L["TAB_MODULES"]                 = "Modules";
L["TAB_EXTRA"]                   = "Extra Options";
L["TAB_ABOUT"]                   = "About";

-- Tab 1 - General
L["HEADER_GENERAL"]              = "|cff00FF00General Settings|r";
L["DESC_GENERAL"]                = "Basic visual options and frame positioning";
L["CB_CLASS_COLOR"]              = "Class Color Health Bars";
L["CB_BACKDROP"]                 = "Statusbar Backdrop";
L["CB_HEALTH_PCT"]               = "Health Percentage";
L["HEADER_POSITIONS"]            = "|cff00FF00Frame Positions & Draggable|r";
L["CB_CUSTOM_POS"]               = "Use Custom Positions";
L["CB_LOCK_POS"]                 = "Lock Positions";
L["CB_PARTY_INDIVIDUAL"]         = "Move Party Individually";
L["CB_PARTY_3V3"]                = "Party Mode 3v3";
L["HEADER_THEME"]                = "|cff00FF00Visual Theme|r";
L["DRAG_HINT"]                   = "|cffAAAAAA(Shift+Alt+Click to drag frames)|r";
L["BTN_RESET_POS"]               = "Reset Positions & Scale";
L["RESET_POS_DONE"]              = "Positions & scale reset!";
L["RESET_POS_CONFIRM"]           = "Reset all frame positions and scale to defaults?\n\n|cffFFAA00This won't reload your UI.|r";
L["RESET_POS_BTN_YES"]           = "Reset";
L["RESET_POS_BTN_NO"]            = "Cancel";
L["THEME_DARK"]                  = "Current theme: |cff888888Dark|r";
L["THEME_LIGHT"]                 = "Current theme: |cffEEEEEELight|r";
L["THEME_HINT"]                  = "To change theme: Edit |cff00FF00Config/Settings.lua|r (C[\"darkFrames\"]) and /reload";

-- Tab 2 - Frames
L["HEADER_FRAMES"]               = "|cff00FF00Frame Settings|r";
L["DESC_FRAMES"]                 = "Adjust scale and spacing for player/target/party frames";
L["SLIDER_PLAYER_SCALE"]         = "Player Frame Scale";
L["SLIDER_TARGET_SCALE"]         = "Target Frame Scale";
L["HEADER_FOCUS"]                = "|cff00FF00Focus|r";
L["SLIDER_FOCUS_SCALE"]          = "Focus Scale";
L["SLIDER_FOCUS_SPELLBAR"]       = "Focus Spellbar Scale";
L["HEADER_PARTY"]                = "|cff00FF00Party|r";
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
L["HEADER_ARENA_BOSS"]           = "|cff00FF00Arena & Boss Settings|r";
L["DESC_ARENA_BOSS"]             = "PvP and PvE encounter frame settings";
L["HEADER_BOSS"]                 = "|cff00FF00Boss Frames|r";
L["SLIDER_BOSS_SPACING"]         = "Boss Frame Spacing";
L["HEADER_ARENA"]                = "|cff00FF00Arena Frames|r";
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
L["HEADER_ARENA_MODULES"]        = "|cff00FF00Arena Modules|r";
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
L["HEADER_CASTBAR"]              = "|cff00FF00Cast Bar|r";
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
L["THEME_CHANGED"]              = "|cff00FF00NUF:|r Theme changed. |cffFFAA00/reload to apply.|r";

-- Flat Style labels (sArena style)
L["SLIDER_FLAT_WIDTH_FULL"]      = "Width (for custom Styles)";
L["SLIDER_FLAT_HB_HEIGHT_FULL"]  = "Health Bar Height (for custom Styles)";
L["SLIDER_FLAT_PB_HEIGHT_FULL"]  = "Power Bar Height (for custom Styles)";
L["SLIDER_FLAT_HB_FONT_FULL"]   = "Health Bar Font Size";
L["SLIDER_FLAT_PB_FONT_FULL"]   = "Power Bar Font Size";
L["CB_FLAT_MIRRORED_FULL"]      = "Mirrored Frames";

-- Tab 4 - Modules
L["HEADER_MODULES"]              = "|cff00FF00Modules|r";
L["DESC_MODULES"]                = "Enable or disable extra modules. Add .lua files in Modules2/";
L["MODULES_NONE"]                = "|cffAAAAAA(No modules registered)|r";
L["MODULES_ENABLED"]             = "|cff00FF00\226\156\147 Enabled|r";
L["MODULES_DISABLED"]            = "|cffFF0000\226\156\151 Disabled|r";
L["MODULES_HOWTO"]               = "|cffFFFF00How to add modules:|r\n\n"..
	"1. Place your .lua file in the |cff00FF00Modules2/|r folder\n\n"..
	"2. Add this at the beginning of the file:\n"..
	"   |cff00FFFF"..
	'K.RegisterModule("ModuleName", {\n'..
	'       name = "My Module",\n'..
	'       desc = "Module description",\n'..
	"   })|r\n\n"..
	"3. Add the line to the |cff00FF00.toc|r file:\n"..
	"   |cff00FFFFModules2/ModuleName.lua|r\n\n"..
	"4. Do |cffFFAA00/reload|r and the checkbox will appear here automatically.";

-- Bottom buttons
L["BTN_RELOAD"]                  = "Reload UI";
L["BTN_RESET"]                   = "Reset Defaults";
L["BTN_CLOSE"]                   = "Close";
L["BTN_SHOW_CONFIG"]             = "Show Config";
L["RESET_CONFIRM"]               = "Reset all settings to default?\n\n|cffFF0000This will reload your UI!|r";
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
L["CFG_ALL_SYNC"]                = "|cff00FF00All values synchronized!|r";
L["CFG_OUT_OF_SYNC"]             = "|cffFF0000WARNING: Some values out of sync!|r";
L["CFG_RESET_OK"]                = "|cff00FF00NUF ConfigManager:|r Configuration reset to defaults!";

-- Tab 5 - Extra Options
L["HEADER_EXTRA"]                = "|cff00FF00Extra Options|r";
L["DESC_EXTRA"]                  = "Additional settings and experimental features";

-- Profiles
L["HEADER_PROFILES"]             = "|cff00FF00Profiles|r";
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
L["PROFILE_EXPORT_TITLE"]        = "|cff00FF00Export Profile|r";
L["PROFILE_EXPORT_HINT"]         = "|cffAAAAAA(Ctrl+A to select all, Ctrl+C to copy)|r";
L["PROFILE_IMPORT_TITLE"]        = "|cffFFAA00Import Profile|r";
L["PROFILE_IMPORT_HINT"]         = "|cffAAAAAA(Paste your profile string, then click Import)|r";
L["PROFILE_IMPORT_BTN"]          = "Import";
L["PROFILE_CANCEL"]              = "Cancel";
L["PROFILE_IMPORT_EMPTY"]        = "Paste a profile string first!";
L["PROFILE_IMPORT_ERROR"]        = "Import error: ";
L["PROFILE_IMPORT_SUCCESS"]      = "Profile imported! Reloading...";

-- Utility
L["HEADER_UTILITY"]              = "|cff00FF00Utility|r";
L["CB_AUTO_SELL"]                = "Auto Sell Gray Items";
L["TIP_AutoSellGray"]            = "Automatically sells all gray (junk) items when you open a vendor.";
L["CB_AUTO_REPAIR"]              = "Auto Repair";
L["TIP_AutoRepair"]              = "Automatically repairs all items when you open a vendor.\nUses guild bank first if available.\nHold Shift to skip.";
L["CB_ERROR_HIDE"]               = "Hide Errors in Combat";
L["TIP_ErrorHideInCombat"]       = "Hides red error messages during combat.\nShows them again when combat ends.";

-- Module collapse
L["MODULE_EXPAND"]               = "Click to expand options";
L["MODULE_COLLAPSE"]             = "Click to collapse options";
L["COLLAPSE_ICON_EXPAND"]        = "[>]";
L["COLLAPSE_ICON_COLLAPSE"]      = "[v]";

-- Tab 6 - About
L["HEADER_ABOUT"]                = "|cff00FF00About|r";
L["ABOUT_ADDON_NAME"]            = "|cffffffffNidhaus|r |cff00FF00UnitFrames|r";
L["ABOUT_DESCRIPTION"]           = "A PVP-focused UI addon for WoW WotLK 3.3.5a.\nCustom arena frames, trinket tracking, mirror mode,\nclass-colored health bars, and optimized frame positioning\ndesigned for competitive arena gameplay.";
L["ABOUT_AUTHOR"]                = "|cffFFAA00Author:|r Nidhaus";
L["ABOUT_VERSION"]               = "|cffFFAA00Version:|r 1.0";
L["ABOUT_COMMANDS_HEADER"]       = "|cffFFAA00Slash Commands:|r";
L["ABOUT_CMD_OPTIONS"]           = "|cffFFFFFF/nuf|r — Open options panel";
L["ABOUT_CMD_CONFIG"]            = "|cffFFFFFF/nuf config|r — Show saved variables";
L["ABOUT_CMD_ARENA"]             = "|cffFFFFFF/nuf arena|r — Toggle arena test mode";
L["ABOUT_CMD_BOSS"]              = "|cffFFFFFF/nuf boss|r — Toggle boss test mode";
L["ABOUT_CMD_RESET"]             = "|cffFFFFFF/nuf reset|r — Reset all settings";
L["ABOUT_CONTACT_LABEL"]         = "|cffFFAA00Discord:|r";
L["ABOUT_CONTACT_LINK"]          = "https://discord.gg/p3sqeram";
L["ABOUT_COPY_HINT"]             = "|cffAAAAAA(Click to select, Ctrl+C to copy)|r";

-- === MINIMAP BUTTON ===
L["MINIMAP_TITLE"]               = "|cffffffffNidhaus|r |cff00FF00UnitFrames|r";
L["MINIMAP_LEFT_CLICK"]          = "|cffFFFFFFLeft Click:|r Open Options";
L["MINIMAP_RIGHT_CLICK"]         = "|cffFFFFFFRight Click:|r Toggle Arena Mover";
L["MINIMAP_SHIFT_CLICK"]         = "|cffFFFFFFShift + Click:|r Reload UI";
L["MINIMAP_DRAG"]                = "|cffFFFFFFDrag:|r Move icon";


-- === UNIFY ACTION BARS MODULE ===
L["MOD_UAB_NAME"]          = "Unify Action Bars";
L["MOD_UAB_DESC"]          = "Repositions and cleans up default action bar elements.";
L["MOD_UAB_DISABLED"]      = "|cff00FF00NUF:|r Unify Action Bars disabled.";
L["HEADER_ACTIONBARS"]     = "|cff00FF00Action Bars|r";
L["CB_UNIFY_ACTIONBARS"]   = "Unify Action Bars";
L["TIP_UnifyActionBars"]   = "Repositions and cleans up default action bar UI elements:\nbags, micro menu, pet bar, stance bar and paging buttons.";

-- ============================================================
-- ESPAÑOL (override si el cliente es esES o esMX)
-- ============================================================
if isSpanish then

-- Tags
local INSTANTE = "|cff00FF00\226\156\147 Aplica al instante|r";
local RECARGA  = "|cffFFAA00\226\154\160 Requiere /reload|r";

-- === TOOLTIPS ===
L["TIP_classColor"]              = "Colorea la barra de vida según la clase.";
L["TIP_statusbarBackdrop"]       = "Agrega fondo oscuro a las barras.\n\n"..RECARGA;
L["TIP_HealthPercentage"]        = "Muestra % de vida en el target.";
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
L["TIP_PartyCastingBars"]       = "Muestra una barra de casteo junto al frame de cada miembro del grupo.\nRequiere el sub-addon PartyCastingBars cargado.";
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

-- Tabs
L["TAB_GENERAL"]                 = "General";
L["TAB_FRAMES"]                  = "Frames";
L["TAB_ARENA"]                   = "Arena";
L["TAB_ARENA_BOSS"]              = "Arena/Boss";
L["TAB_MODULES"]                 = "Módulos";
L["TAB_EXTRA"]                   = "Extra";
L["TAB_ABOUT"]                   = "About";

-- Tab 1 - General
L["HEADER_GENERAL"]              = "|cff00FF00Configuración General|r";
L["DESC_GENERAL"]                = "Opciones visuales básicas y posicionamiento de frames";
L["CB_CLASS_COLOR"]              = "Barras de vida por clase";
L["CB_BACKDROP"]                 = "Fondo de barras";
L["CB_HEALTH_PCT"]               = "Porcentaje de vida";
L["HEADER_POSITIONS"]            = "|cff00FF00Posiciones & Arrastrables|r";
L["CB_CUSTOM_POS"]               = "Usar Posiciones Custom";
L["CB_LOCK_POS"]                 = "Bloquear Posiciones";
L["CB_PARTY_INDIVIDUAL"]         = "Mover Party Individual";
L["CB_PARTY_3V3"]                = "Modo Party 3v3";
L["HEADER_THEME"]                = "|cff00FF00Tema Visual|r";
L["DRAG_HINT"]                   = "|cffAAAAAA(Shift+Alt+Click para arrastrar frames)|r";
L["BTN_RESET_POS"]               = "Resetear Posiciones & Escala";
L["RESET_POS_DONE"]              = "\194\161Posiciones y escala reseteadas!";
L["RESET_POS_CONFIRM"]           = "\194\191Resetear todas las posiciones y escalas a default?\n\n|cffFFAA00No va a recargar la UI.|r";
L["RESET_POS_BTN_YES"]           = "Resetear";
L["RESET_POS_BTN_NO"]            = "Cancelar";
L["THEME_DARK"]                  = "Tema actual: |cff888888Oscuro|r";
L["THEME_LIGHT"]                 = "Tema actual: |cffEEEEEEClaro|r";
L["THEME_HINT"]                  = "Para cambiar tema: Editá |cff00FF00Config/Settings.lua|r (C[\"darkFrames\"]) y /reload";

-- Tab 2 - Frames
L["HEADER_FRAMES"]               = "|cff00FF00Configuración de Frames|r";
L["DESC_FRAMES"]                 = "Ajustá escala y espaciado para player/target/party";
L["SLIDER_PLAYER_SCALE"]         = "Escala Player Frame";
L["SLIDER_TARGET_SCALE"]         = "Escala Target Frame";
L["HEADER_FOCUS"]                = "|cff00FF00Focus|r";
L["SLIDER_FOCUS_SCALE"]          = "Escala Focus";
L["SLIDER_FOCUS_SPELLBAR"]       = "Escala Spellbar Focus";
L["HEADER_PARTY"]                = "|cff00FF00Party|r";
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
L["HEADER_ARENA_BOSS"]           = "|cff00FF00Arena & Boss|r";
L["DESC_ARENA_BOSS"]             = "Configuración de frames PvP y PvE";
L["HEADER_BOSS"]                 = "|cff00FF00Boss Frames|r";
L["SLIDER_BOSS_SPACING"]         = "Espaciado Boss Frames";
L["HEADER_ARENA"]                = "|cff00FF00Arena Frames|r";
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
L["HEADER_ARENA_MODULES"]        = "|cff00FF00Módulos de Arena|r";
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
L["HEADER_CASTBAR"]              = "|cff00FF00Barra de Casteo|r";
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
L["THEME_CHANGED"]              = "|cff00FF00NUF:|r Tema cambiado. |cffFFAA00/reload para aplicar.|r";

-- Flat Style labels (sArena style)
L["SLIDER_FLAT_WIDTH_FULL"]      = "Ancho (para estilos custom)";
L["SLIDER_FLAT_HB_HEIGHT_FULL"]  = "Altura Barra Vida (para estilos custom)";
L["SLIDER_FLAT_PB_HEIGHT_FULL"]  = "Altura Barra Poder (para estilos custom)";
L["SLIDER_FLAT_HB_FONT_FULL"]   = "Tamaño Fuente Vida";
L["SLIDER_FLAT_PB_FONT_FULL"]   = "Tamaño Fuente Poder";
L["CB_FLAT_MIRRORED_FULL"]      = "Frames Espejados";

-- Tab 4 - Modules
L["HEADER_MODULES"]              = "|cff00FF00Módulos|r";
L["DESC_MODULES"]                = "Activá o desactivá módulos extra. Agregá archivos .lua en Modules2/";
L["MODULES_NONE"]                = "|cffAAAAAA(No hay módulos registrados)|r";
L["MODULES_ENABLED"]             = "|cff00FF00\226\156\147 Habilitado|r";
L["MODULES_DISABLED"]            = "|cffFF0000\226\156\151 Deshabilitado|r";
L["MODULES_HOWTO"]               = "|cffFFFF00Cómo agregar módulos:|r\n\n"..
	"1. Poné tu archivo .lua en la carpeta |cff00FF00Modules2/|r\n\n"..
	"2. Agregá esto al principio del archivo:\n"..
	"   |cff00FFFF"..
	'K.RegisterModule("NombreModulo", {\n'..
	'       name = "Mi Modulo",\n'..
	'       desc = "Descripción del módulo",\n'..
	"   })|r\n\n"..
	"3. Agregá la línea al archivo |cff00FF00.toc|r:\n"..
	"   |cff00FFFFModules2/NombreModulo.lua|r\n\n"..
	"4. Hacé |cffFFAA00/reload|r y el checkbox aparece acá automáticamente.";

-- Bottom buttons
L["BTN_RELOAD"]                  = "Recargar UI";
L["BTN_RESET"]                   = "Resetear";
L["BTN_CLOSE"]                   = "Cerrar";
L["BTN_SHOW_CONFIG"]             = "Ver Config";
L["RESET_CONFIRM"]               = "¿Resetear toda la configuración?\n\n|cffFF0000¡Se va a recargar la UI!|r";
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
L["CFG_RESET_OK"]                = "|cff00FF00NUF ConfigManager:|r ¡Configuración reseteada a defaults!";

-- Tab 5 - Extra Options
L["HEADER_EXTRA"]                = "|cff00FF00Opciones Extra|r";
L["DESC_EXTRA"]                  = "Configuraciones adicionales y funciones experimentales";

-- Profiles
L["HEADER_PROFILES"]             = "|cff00FF00Perfiles|r";
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
L["PROFILE_EXPORT_TITLE"]        = "|cff00FF00Exportar Perfil|r";
L["PROFILE_EXPORT_HINT"]         = "|cffAAAAAA(Ctrl+A para seleccionar todo, Ctrl+C para copiar)|r";
L["PROFILE_IMPORT_TITLE"]        = "|cffFFAA00Importar Perfil|r";
L["PROFILE_IMPORT_HINT"]         = "|cffAAAAAA(Pegá tu texto de perfil, después hacé click en Importar)|r";
L["PROFILE_IMPORT_BTN"]          = "Importar";
L["PROFILE_CANCEL"]              = "Cancelar";
L["PROFILE_IMPORT_EMPTY"]        = "\194\161Pegá un texto de perfil primero!";
L["PROFILE_IMPORT_ERROR"]        = "Error al importar: ";
L["PROFILE_IMPORT_SUCCESS"]      = "\194\161Perfil importado! Recargando...";

-- Utility
L["HEADER_UTILITY"]              = "|cff00FF00Utilidades|r";
L["CB_AUTO_SELL"]                = "Vender Grises Automático";
L["TIP_AutoSellGray"]            = "Vende automáticamente todos los items grises al abrir un vendor.";
L["CB_AUTO_REPAIR"]              = "Reparar Automático";
L["TIP_AutoRepair"]              = "Repara automáticamente al abrir un vendor.\nUsa banco de guild primero si está disponible.\nMantené Shift para saltear.";
L["CB_ERROR_HIDE"]               = "Ocultar Errores en Combate";
L["TIP_ErrorHideInCombat"]       = "Oculta los mensajes de error rojos durante combate.\nLos muestra de nuevo al salir de combate.";

-- Module collapse
L["MODULE_EXPAND"]               = "Click para expandir opciones";
L["MODULE_COLLAPSE"]             = "Click para colapsar opciones";
L["COLLAPSE_ICON_EXPAND"]        = "[>]";
L["COLLAPSE_ICON_COLLAPSE"]      = "[v]";

-- Tab 6 - About
L["HEADER_ABOUT"]                = "|cff00FF00Acerca de|r";
L["ABOUT_ADDON_NAME"]            = "|cffffffffNidhaus|r |cff00FF00UnitFrames|r";
L["ABOUT_DESCRIPTION"]           = "Un addon de interfaz enfocado en PVP para WoW WotLK 3.3.5a.\nArena frames custom, tracking de trinkets, modo espejo,\nbarras de vida por clase, y posicionamiento optimizado\ndiseñado para arena competitivo.";
L["ABOUT_AUTHOR"]                = "|cffFFAA00Autor:|r Nidhaus";
L["ABOUT_VERSION"]               = "|cffFFAA00Versión:|r 1.0";
L["ABOUT_COMMANDS_HEADER"]       = "|cffFFAA00Comandos:|r";
L["ABOUT_CMD_OPTIONS"]           = "|cffFFFFFF/nuf|r — Abrir panel de opciones";
L["ABOUT_CMD_CONFIG"]            = "|cffFFFFFF/nuf config|r — Mostrar variables guardadas";
L["ABOUT_CMD_ARENA"]             = "|cffFFFFFF/nuf arena|r — Toggle modo test de arena";
L["ABOUT_CMD_BOSS"]              = "|cffFFFFFF/nuf boss|r — Toggle modo test de boss";
L["ABOUT_CMD_RESET"]             = "|cffFFFFFF/nuf reset|r — Resetear configuración";
L["ABOUT_CONTACT_LABEL"]         = "|cffFFAA00Discord:|r";
L["ABOUT_CONTACT_LINK"]          = "https://discord.gg/p3sqeram";
L["ABOUT_COPY_HINT"]             = "|cffAAAAAA(Click para seleccionar, Ctrl+C para copiar)|r";

-- === MINIMAP BUTTON ===
L["MINIMAP_LEFT_CLICK"]          = "|cffFFFFFFClick Izquierdo:|r Abrir Opciones";
L["MINIMAP_RIGHT_CLICK"]         = "|cffFFFFFFClick Derecho:|r Toggle Arena Mover";
L["MINIMAP_SHIFT_CLICK"]         = "|cffFFFFFFShift + Click:|r Recargar UI";
L["MINIMAP_DRAG"]                = "|cffFFFFFFArrastrar:|r Mover icono";

-- === UNIFY ACTION BARS MODULE ===
L["MOD_UAB_NAME"]          = "Unificar Barras de Acción";
L["MOD_UAB_DESC"]          = "Reposiciona y limpia los elementos de la barra de acción.";
L["MOD_UAB_DISABLED"]      = "|cff00FF00NUF:|r Unify Action Bars desactivado.";
L["HEADER_ACTIONBARS"]     = "|cff00FF00Barras de Acción|r";
L["CB_UNIFY_ACTIONBARS"]   = "Unificar Barras de Acción";
L["TIP_UnifyActionBars"]   = "Reposiciona y limpia los elementos de la barra de acción:\nbolsas, micro menú, barra de mascota, posturas y botones de paginado.";

end -- isSpanish