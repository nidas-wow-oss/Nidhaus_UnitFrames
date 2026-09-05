*[Leer en español](README.es.md)*

# Nidhaus UnitFrames (NUF)

A PvP-focused UI addon for World of Warcraft WotLK 3.3.5a (Warmane Blackrock and other private servers).

NUF was built by combining and reworking several existing addons — including Eazy Frames and Sarena — along with new custom features, especially around party frames. Everything has been unified into a single package focused entirely on UI and PvP, giving arena and battleground players fully customizable unit frames, arena-specific tools (trinket tracking, spec detection, countdown timers, frame positioning per style), and a modular system of optional features — all configurable from a single in-game options panel.

> ## Download
>
> **Latest version: 3.6** — this is the current, recommended build and the one actively in use.
>
> **[Download v3.6 (latest release)](../../releases/latest)**
>
> One download, everything included: the addon and its options panel.

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

NUF uses a module manager: every feature below can be turned on or off independently from the in-game
options panel, and each one restores the original state when disabled.

#### Moving things around

| Module | Description |
|--------|-------------|
| **GlobalUnlock** | *Unlock everything* mode. Shows a draggable overlay on top of every movable frame — player, target, focus, party, action bars, buffs, debuffs, cast bar, Auto Shot and swing timers — and saves each position. Frames snap to a grid so aligning two of them is easy, and `Ctrl + mouse wheel` resizes the ones that support it. Commands: `/move`, `/nufmove`, `/nufunlock` (`/move lock`, `/move reset`, `/move frames`). |
| **Frame Dragger** | Move any supported frame with `Shift + Alt + Click`. Positions are saved per frame and persist across sessions. |
| **AuraAnchor** | Moves your buffs and debuffs. Works around Blizzard re-anchoring `BuffButton1` every update, which is why dragging `BuffFrame` alone never works in 3.3.5a. |
| **PartyTestMode** | Shows the four party frames filled with fake data while you are alone, so you can arrange them — and Party Buffs, Party Targets and Party Casting Bars with them — without needing a real group. `/nufparty` |
| **ArenaMover** | Arena frame test mode with class preview, to position arena frames outside a match. `/nuf arena` or right-click the minimap button. |

#### Arena and PvP

| Module | Description |
|--------|-------------|
| **SpecIcons** | Detects enemy specialisation from the combat log using a database of 600+ spell-to-spec mappings. Shows the spec icon on Target, Focus and Arena frames. |
| **Trinket Tracker** | Tracks enemy PvP trinket and control-breaking racial usage by spell ID (not by name, so it works across client locales). Draggable per style and mirror mode. |
| **ArenaToT** | Shows who each arena enemy is targeting, using Blizzard ToT-style frames. Draggable, scalable, class icon or portrait. |
| **ArenaCountDown** | Visual countdown at the arena gates, driven by the arena system messages. Includes a Shadow Sight timer overlay. |
| **ArenaEndTimer** | Time left until the arena ends in a draw. `Alt + drag` to move. `/nuftimers` |
| **ArenaDalaranPipeTimer** | Timer for the Dalaran Sewers waterfall, with the cycle verified against the Warmane WeakAura. |
| **ArenaRoVPillarTimer** | Timer for the Ruins of Lordaeron pillars: 45s for the first cycle, then every 25s. |
| **ArenaPointsCalc** | Arena points calculator, integrated from Arena Points Calculator v2.1. `/apc`, `/arenapts` |
| **ArenaTimes** | Timer on the arena invite popup and queue time next to the minimap. Also matches battlegrounds. |
| **EnemySpellAlert** | When a watched enemy spell is cast, its icon flashes on screen for a few seconds. Based on the *Announce Spells* WeakAura. |
| **SeductionAlert** | Warns when an enemy succubus starts casting Seduction on you. Ported from a WeakAura. |
| **TabBinder** | In arenas, battlegrounds and contested zones, restricts `Tab` targeting to enemy players. |
| **TooltipExtras** | Adds arena experience (personal best 2v2/3v3/5v5 rating) and other details to unit tooltips. |

#### Party frames

| Module | Description |
|--------|-------------|
| **NewPartyFrame** | Custom-styled party frames with reworked textures, integrated with Party Buffs and Party Targets. <br><img width="75" alt="NewPartyFrame" src="https://github.com/user-attachments/assets/79210886-68ca-4a54-adaf-a69cfa139953" /> |
| **PartyFramePW** | A fourth party frame style, taken from pw_unitframes. |
| **PartyFrameStyle** | Coordinator for party frame appearance — the styles are mutually exclusive, so this makes sure only one retextures the frames at a time. `/nufpartystyle` |
| **PartyFramesImproved** | Party frame enhancements. `/nufpfi` |
| **PartyBuffs** | Extended buffs and debuffs (1-20 icons) on party frames, with independent positions per party frame mode. `/pbuffs`, `/partybuffs` |
| **PartyTargets** | Shows who each party member is targeting, with an optional mirror and a Square style inspired by pw_unitframes. `/ptarget`, `/ptstyle` <br><img width="100" alt="PartyTargets" src="https://github.com/user-attachments/assets/6ac41efa-3557-4d9f-aeb2-bbe5dc4608d0" /> |
| **PartyCastingBars** | Casting bars for party members, with an options window instead of subcommands. `/pcb` |
| **PartyPetFrame** | Dedicated frame for party member 1's pet: portrait, health/mana, cast bar, buffs/debuffs and CC warning. `/ppf` |
| **Partymode3v3** | Dedicated 3v3 party layout for arena, with per-member scaling from the panel. |

#### Action bars

| Module | Description |
|--------|-------------|
| **ActionBars** | Unifies and reskins the default action bars. Saves the complete original state before touching anything and restores it exactly on disable, with combat lockdown guards and vehicle handling. |
| **MiniBar** | Compact action bar layout — half-width main bar, stacked bars, bag frame. Based on FriskesBar. |
| **SideBarHover** | Shows MultiBarLeft and MultiBarRight only while the mouse is over them. |
| **ButtonRange** | Tints action buttons red when the target is out of range. |
| **HideActionBarTextures** | Removes the default action bar art and decorations. `/hidebar` |
| **HideBindsAndMacros** | Hides hotkey text and/or macro names on action buttons. |
| **SlotProfiles** | Copies action bars, macros and keybindings from one character to another. Ported from MySlot, with the interface translated out of Chinese and four real bugs fixed. `/nufslot` |

#### Class and combat trackers

| Module | Description |
|--------|-------------|
| **ClassTimers** | Class-specific duration bars, logic and look ported from MageNuggets. `/nufclass` |
| **ComboWatch** | Large combo point counter, coloured by count. `/nufcombo` |
| **GargoyleTracker** | Gargoyle tracker for death knights, driven by the combat log. `/gt` |
| **HunterPetBuffs** | Row of icons under the pet frame with the buffs a hunter needs to watch, starting with Mend Pet. `/nufpetbuffs` |
| **AutoShotTimer** | Auto Shot timer bar. Accounts for Feign Death by using the unmodified speed. `/nufshot` |
| **MeleeSwingTimer** | Bar counting down to your next white hit, read from your own combat log. `/nufswing` |
| **PaladinAuras** | Native port of the *paladin wa* WeakAura group: Holy Strength (Crusader proc), healing debuffs (Mortal Strike / Aimed Shot / Wound Poison VII) and more. `/nufpal` |
| **PaladinICD** | Visual internal cooldowns for paladin defensives — Divine Protection, Divine Shield, Hand of Protection, Avenging Wrath, Lay on Hands. `/paladinicd` |
| **SacredShield** | Icon when your target has Sacred Shield. `/ss` |
| **SacredShieldTracker** | Renew reminder and uptime tracking for Sacred Shield, ported from a WeakAura group. `/sst` |
| **ShieldWatch** | Bar with the remaining absorb on shields. `/swh` |
| **DTSU** | Outgoing damage tracker — swing, direct and periodic — with floating icons showing total, last hit and hit count. `/dtsu` |
| **PowerBar** | Movable resource bar (mana, energy, rage, runic power, focus) to keep near your character. Ported from MobileEnergy. `/nufpower` |
| **ArrowCount** | Shows how many arrows or bullets you have in your bags. `Alt + drag` to move. `/arrowcount` |
| **CastingBarTimer** | Cast time in seconds over your own and your target's casting bar. |
| **HealthPercentage** | Health percentage on the target frame, with a configurable execute-phase indicator. |

#### Appearance

| Module | Description |
|--------|-------------|
| **Lorti UI** | Darkens frame textures and styles action bars. Requires `/reload` to apply. |
| **ClassIcons** | Replaces unit portraits with class icons. Four styles: default, modern, hs, ex. Throttled refresh in arena. |
| **ClassOutline** | Class-coloured ring around the portrait. Adapted from RougeUI for 3.3.5a. |
| **AuraBorders** | Buff and debuff icon borders in pw_unitframes style. |
| **CastBarPW** | pw_unitframes-style casting bars for player, target and focus. |
| **AbbreviatedStatus** | Shortens health and mana numbers on unit frames. Own reimplementation of the idea behind Abbreviated Status Text. |
| **HealthTextFormat** | Shows only the current value instead of `current / max`. |
| **UnitNameColor** | Unit name colouring: Default, White or Class. |
| **MinimapStyle** | Round or square minimap, and removal of the decorations nobody uses — zone name, clock, zoom buttons. `/nufmap` |
| **MinimapIconToggle** | Small button on the minimap corner that hides or shows every minimap icon at once. `/nufminimap` |
| **NiceDamage** | Floating combat text replacement with a dual font selector: one font for damage, another for heals and auras, with live preview. `/nd` <br><img width="200" alt="NiceDamage" src="https://github.com/user-attachments/assets/fcb8a2a1-1adb-40fc-be00-0c09d2f801ec" /> |

#### Chat and quality of life

| Module | Description |
|--------|-------------|
| **ChatCopy** | Double-click a chat tab to open a copyable transcript. `/nufcopy` |
| **ChatURLs** | Turns URLs typed in chat into clickable links, opening a small copyable box. |
| **SystemSpamFilter** | Strips the system messages that are pure noise: other people's duel results, drunkenness, "you have learned X". `/nufspam` |
| **HideChatButton** | Button to hide or show the whole chat frame. `/hcb` |
| **DuelBlocker** | Automatically declines duel requests. `/nufduel` |
| **AutoSell** | Sells grey items automatically at vendors and reports the gold earned. |
| **AutoRepair** | Repairs at vendors automatically, trying guild funds first, and reports the cost. |
| **ErrorHide** | Suppresses the red error text during combat, with a safety net that restores it if anything goes wrong. |
| **DungeonRoles** | While in the dungeon finder queue, shows five icons — tank, healer and three DPS — lighting up as roles are filled. Ported from DisplayDungeon. |

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

## What's in this repository

This repository contains **both addons**. You need both for the full experience:

| Folder | What it is |
|---|---|
| `Nidhaus_UnitFrames/` | The addon itself. Required. |
| `Nidhaus_UnitFrames_Config/` | The in-game options panel (`/nufconfig`). Strongly recommended — without it there is no configuration UI. |

## Installation

1. Download **v3.6** from the [releases page](../../releases/latest).
2. Extract the archive. You will get two folders: `Nidhaus_UnitFrames` and `Nidhaus_UnitFrames_Config`.
3. Copy **both** folders into your WoW `Interface/AddOns/` directory.
4. Restart the WoW client, or type `/reload` if you are already in-game.
5. Enable both addons on the character selection screen.

> **Updating from an older version?** Delete the old `Nidhaus_UnitFrames` folder before copying the new
> one instead of overwriting it — 3.6 reorganised files, and leftovers from a previous build can cause
> errors. Your saved settings live in the `WTF` folder and are preserved.

> If you download the repository with the green *Code* button instead of the release, the extracted folder
> will be named `Nidhaus_UnitFrames-main` and will contain both addon folders inside it. Copy the two
> folders out of it into `Interface/AddOns/` — do not copy `Nidhaus_UnitFrames-main` itself.

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

## Credits

NUF is built on the work of a lot of other people. The engine and several modules are ports or
adaptations, and the credit for those belongs to their original authors:

| Original project | Author | Used for |
|---|---|---|
| Eazy Frames, Sarena | — | Base of the unit frame work |
| pw_unitframes | — | Aura borders, cast bars, PartyFramePW, PartyTargets Square style |
| RE/TabBinder | Veev, AcidWeb | TabBinder |
| TipTacTalents | Aezay | Talents in the tooltip |
| PvPRating | Fernir | Arena experience in the tooltip |
| AuraSource | Renstrom | Buff caster in the tooltip |
| FriskesUI | Friskes | MiniBar (FriskesBar) |
| RougeUI | — | ClassOutline |
| MageNuggets | — | ClassTimers |
| MySlot | tg123 | SlotProfiles |
| MobileEnergy | B-Buck | PowerBar |
| ZAutoShot | — | AutoShotTimer |
| ShieldWatch | — | ShieldWatch |
| !ComboWatch | — | ComboWatch |
| DisplayDungeon | Smokey | DungeonRoles |
| PartyFramesImproved | SoupsBelly, from UnitFramesImproved (kiforsbe) and PartyTarget (Valconeye) | PartyFramesImproved |
| Abbreviated Status Text | RomanSpector | AbbreviatedStatus (reimplemented) |
| Arena Points Calculator | — | ArenaPointsCalc |
| AutoSell, ErrorHide | FatalEntity | Both modules |
| Various WeakAuras | — | PaladinAuras, SacredShield, SacredShieldTracker, SeductionAlert, EnemySpellAlert, Dalaran pipe timer |

Integration, porting to 3.3.5a, bug fixing and everything else: **Nidhaus**.

---

## Author

**Nidhaus**

---

## Changelog

### v3.6
- Fixed style menu options
- Fixed text display issues
- Fixed various frame bugs

---

## License

All rights reserved. This addon is provided as-is for personal use.
