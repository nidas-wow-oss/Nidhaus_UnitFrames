# Nidhaus UnitFrames (NUF)

A comprehensive unit frame replacement and UI enhancement addon for **World of Warcraft WotLK 3.3.5a** (Warmane Blackrock and other private servers).

NUF replaces and enhances the default Blizzard unit frames with fully customizable player, target, party, boss, and arena frames — plus a modular system of optional features covering action bars, floating combat text, party buffs, and more.

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-blue)
![Client](https://img.shields.io/badge/Client-WotLK-orange)
![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-red)

---

## Features

### Core Unit Frames

- **Player Frame** — Rescalable player frame with dark/light texture variants, vehicle art support, and integrated pet frame styling.
- **Target Frame** — Customizable target, focus, target-of-target (ToT), and target-of-focus (ToF) frames with independent scaling.
- **Party Frames** — Party frame container with adjustable spacing, scaling, and a dedicated 3v3 layout mode for arena.
- **Boss Frames** — Draggable boss frames with a visual mover anchor and adjustable spacing/scale.
- **Class-Colored Health Bars** — Applies class colors to health bars on all frames, with NPC reaction color support.
- **Health Percentage** — Displays health percentage on the target frame with an execute phase indicator (configurable threshold).

### Arena Systems

- **Arena Frames** — Two fully styled arena frame modes: **Default** (enhanced Blizzard style) and **Flat** (minimal, competitive style).
- **Arena Mover** — Test mode with class preview, allowing you to position arena frames outside of a match. Accessible via `/nuf arena` or right-clicking the minimap button.
- **Trinket Tracker** — Tracks enemy PvP trinket usage on arena frames with cooldown indicators. Draggable per style and mirror mode.
- **Spec Detection (SpecIcons)** — Detects enemy specializations via combat log analysis using a database of 600+ spell-to-spec mappings. Displays spec icons on Target, Focus, and Arena frames with style-aware positioning.
- **Arena Countdown** — Visual countdown timer that activates from arena system messages (supports English, Spanish, and numeric server patterns). Includes a Shadow Sight timer overlay.
- **Arena Position Saver** — Saves arena frame positions independently per style and mirror mode using composite keys, so your layout is preserved across sessions and configurations.

### Mirror Mode

Horizontally flips the UI layout (player frame on the right, target on the left, etc.), allowing a mirrored setup for players who prefer reversed positioning. Arena frames, cast bars, and party frames all respect the mirror state independently.

### Frame Positioning

- **Frame Dragger** — Move any supported frame with `Shift + Alt + Click`. Positions are saved per-frame to the database and persist across sessions.
- **Frame Positions Manager** — Applies saved or default positions to Player, Target, Party, and Boss frames on load.

### Modular System

NUF uses a module manager that allows enabling/disabling features independently. All modules can be toggled from the in-game options panel.

| Module | Description |
|--------|-------------|
| **ActionBars** | Unifies and reskins the default action bars. Includes texture hiding, combat lockdown guards, vehicle handling, and deferred execution for safe toggling during combat. |
| **NiceDamage** | Floating combat text replacement with dual-font selection (separate fonts for damage and healing). Includes a font preview system and validation. |
| **NewPartyFrame** | Custom-styled party frames with enhanced visuals, integrated with PartyBuffs and PartyTargets for seamless operation. |
| **PartyBuffs** | Displays buff/debuff icons on party frames with layout adjustments for both Blizzard and NewPartyFrame modes. Commands: `/pbuffs`, `/partybuffs`. |
| **PartyTargets** | Shows target-of-party-member indicators with optional horizontal mirroring. Automatically disables mirror when NewPartyFrame is active to prevent visual conflicts. |
| **ClassIcons** | Replaces unit portraits with class icons. Throttled refresh in arena for performance. |
| **Round3DPortraits** | Applies round 3D portrait rendering to target frames with proper strata and render order. |
| **ButtonRange** | Tints action buttons red when the target is out of range. |
| **HideActionBarTextures** | Removes default action bar art and decorations for a cleaner UI. |
| **HideChatButton** | Adds a toggle button to show/hide the entire chat frame. |
| **ArenaTimes** | Displays arena queue invite timer and time-in-queue next to the minimap. |
| **MiniBar** | Compact micro action bar with bag/menu access. |
| **ArenaCountDown** | Visual arena start countdown (see Arena Systems above). |
| **AutoSell** | Automatically sells grey (junk) items when visiting a vendor. Displays total gold earned. |
| **AutoRepair** | Automatically repairs gear at vendors using available gold. Displays repair cost. |
| **ErrorHide** | Suppresses the red error text frame during combat. Includes a safety net to restore the frame if anything goes wrong. |

### Options Panel

A full in-game configuration interface organized into tabs:

- **General** — Global settings (class colors, health percentage, mirror mode, frame dragger toggle).
- **Frames** — Per-frame scale and position controls for Player, Target, Party, and Boss frames with real-time preview.
- **Arena** — Arena frame style selection (Default/Flat), trinket display options, spec icon toggles, and arena-specific scaling.
- **Modules** — Toggle individual modules on/off. Modules with sub-options display collapsible configuration panels.
- **Extra** — Additional utilities (AutoSell, AutoRepair, ErrorHide).
- **About** — Addon info, version, and slash command reference.

### Profile System

- **Export/Import** — Serialize your entire configuration to a string for sharing or backup. Import with sandboxed deserialization for safety.
- **Named Save Slots** — Save and load named configuration profiles via a dropdown UI.

---

## Installation

1. Download or clone this repository.
2. Copy the `Nidhaus_UnitFrames` folder into your WoW `Interface/AddOns/` directory.
3. Restart the WoW client or type `/reload` if already in-game.

```
World of Warcraft/
└── Interface/
    └── AddOns/
        └── Nidhaus_UnitFrames/
            ├── Nidhaus_UnitFrames.toc
            ├── Nidhaus_UnitFrames.xml
            ├── Core/
            ├── Config/
            ├── UnitFrames/
            ├── Modules/
            └── Modules2/
```

---

## Slash Commands

| Command | Action |
|---------|--------|
| `/nuf` | Open the options panel |
| `/nuf config` | Show saved variables in chat |
| `/nuf arena` | Toggle arena test mode |
| `/nuf boss` | Toggle boss test mode |
| `/nuf reset` | Reset all settings to default |
| `/nuf modules` | List all modules and their status |

The minimap button also provides quick access: left-click opens the options panel, right-click toggles the arena mover.

---

## Architecture

NUF is built around a shared namespace (`K` for functions, `C` for config, `L` for localization) initialized in `Init.lua`. The addon follows a strict load order defined in the XML file:

1. **Core** — Init, API, Settings, ConfigManager, ModuleManager, FrameDragger, FramePositions
2. **Config** — OptionsPanel (modular: General, Frames, Arena, Extra, About tabs), Commands, Localization
3. **UnitFrames** — PlayerFrame, TargetFrame, PartyFrame, BossFrame, ArenaFrame, ArenaFlat, ClassColor
4. **Modules** — ActionBars, MirrorMode, ArenaMover, ArenaFrame_Trinkets, ArenaFramePositionSaver, PartyMode3v3, HealthPercentage, MinimapButton, and more
5. **Modules2** — NiceDamage, NewPartyFrame, PartyBuffs, PartyTargets, ClassIcons, SpecIcons, ArenaCountDown, MiniBar, AutoSell, AutoRepair, ErrorHide

The ConfigManager provides a custom event system (`CONFIG_LOADED`, `CONFIG_CHANGED`, `CONFIG_RESET`) that modules subscribe to for reactive updates. Configuration is stored in `NidhausUnitFramesDB` (SavedVariables).

---

## Compatibility

- **Client:** WoW 3.3.5a (WotLK)
- **Tested on:** Warmane Blackrock
- **API Level:** Compatible with 3.3.5a Lua sandbox (no HTTP, no hardware calls)

---

## Author

**Nidhaus**

---

## License

All rights reserved. This addon is provided as-is for personal use.
