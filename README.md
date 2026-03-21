Changelog
v3.6

Fix style menu options
Fix text display issues
Fix various frame bugs

# Nidhaus UnitFrames (NUF)

A PvP-focused UI addon for World of Warcraft WotLK 3.3.5a (Warmane Blackrock and other private servers).

NUF was built by combining and reworking several existing addons — including Eazy Frames and Sarena — along with new custom features, especially around party frames. Everything has been unified into a single package focused entirely on UI and PvP, giving arena and battleground players fully customizable unit frames, arena-specific tools (trinket tracking, spec detection, countdown timers, frame positioning per style), and a modular system of optional features — all configurable from a single in-game options panel.

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
<img width="215" alt="Image" src="https://github.com/user-attachments/assets/ace03d46-ccb9-4952-b3c1-bdbd25d2b891" />

<img width="220" alt="Image" src="https://github.com/user-attachments/assets/ba6e5101-b017-4d48-a4bc-9b57ba7d2023" />

<img width="212" alt="Image" src="https://github.com/user-attachments/assets/431c3a78-f485-40e2-b942-b1a4e6202e0c" />

- **Arena Mover** — Test mode with class preview, allowing you to position arena frames outside of a match. Accessible via `/nuf arena` or right-clicking the minimap button.
- **Trinket Tracker** — Tracks enemy PvP trinket usage on arena frames with cooldown indicators. Draggable per style and mirror mode.
- **Spec Detection (SpecIcons)** — Detects enemy specializations via combat log analysis using a database of 600+ spell-to-spec mappings. Displays spec icons on Target, Focus, and Arena frames with style-aware positioning.
- **Arena Countdown** — Visual countdown timer that activates from arena system messages. Includes a Shadow Sight timer overlay.
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
| **NiceDamage** | Floating combat text replacement with dual-font selection (separate fonts for damage and healing). Includes a font preview system and validation.<br><img width="200" alt="NiceDamage" src="https://github.com/user-attachments/assets/fcb8a2a1-1adb-40fc-be00-0c09d2f801ec" /> |
| **NewPartyFrame** | Custom-styled party frames with enhanced visuals, integrated with PartyBuffs and PartyTargets for seamless operation.<br><img width="75" alt="Image" src="https://github.com/user-attachments/assets/79210886-68ca-4a54-adaf-a69cfa139953" /> 
| **PartyBuffs** | Displays buff/debuff icons on party frames with layout adjustments for both Blizzard and NewPartyFrame modes. Commands: `/pbuffs`, `/partybuffs`. |
| **PartyTargets** | Shows target-of-party-member indicators with optional horizontal mirroring. Automatically disables mirror when NewPartyFrame is active to prevent visual conflicts.<br><img width="100" alt="Image" src="https://github.com/user-attachments/assets/6ac41efa-3557-4d9f-aeb2-bbe5dc4608d0" /> 
| **ClassIcons** | Replaces unit portraits with class icons. Throttled refresh in arena for performance. |
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
4. Delete " -main " in the name addon.

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
