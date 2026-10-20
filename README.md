*[Leer en español](README.es.md)*

# Nidhaus UnitFrames (NUF)

A PvP-focused UI addon for World of Warcraft WotLK 3.3.5a (Warmane Blackrock and other private servers).

NUF combines and reworks several existing addons — Eazy Frames and sArena among them — with its own features into one package focused on UI and PvP, all set up from a single in-game panel.

> ## Download
>
> **Latest version: 4.3** — this is the current, recommended build and the one actively in use.
>
> **[Download v4.3 (latest release)](../../releases/latest)**
>
> One download, everything included: the addon and its options panel.

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-blue)
![Client](https://img.shields.io/badge/Client-WotLK-orange)
![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-red)

## Features

<img src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/panel.png" width="559" alt="NUF options panel" />

- **Unit frames** — player, target, focus, party and boss, with custom skins, class colors and per-frame scale.
- **Arena** — arena frames in two styles (Default and Flat) with trinkets, spec icons, DR and DoT tracking and countdown, plus a test mode to place them outside a match.
- **Party** — 3v3 arena layout with per-member scale, and a test mode to arrange the group while you are alone.
- **Move Everything** — drag any frame and resize it with Ctrl + mouse wheel.
- **Optional modules** — action bars, class trackers, tooltip, chat and quality-of-life extras, each one on or off from the panel.
- **Character Setup** — copy action bars, macros and keybinds between characters (nExtraBars included).
- **Profiles** — export and import your whole configuration.

<img width="215" alt="Arena" src="https://github.com/user-attachments/assets/ace03d46-ccb9-4952-b3c1-bdbd25d2b891" /> <img width="220" alt="Arena" src="https://github.com/user-attachments/assets/ba6e5101-b017-4d48-a4bc-9b57ba7d2023" /> <img width="212" alt="Arena" src="https://github.com/user-attachments/assets/431c3a78-f485-40e2-b942-b1a4e6202e0c" /> <img width="137" alt="DoT warning" src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/arena-dot-warning.png" />

| New Party Frame | Party Targets | NiceDamage |
|:-:|:-:|:-:|
| <img width="75" alt="NewPartyFrame" src="https://github.com/user-attachments/assets/79210886-68ca-4a54-adaf-a69cfa139953" /> | <img width="100" alt="PartyTargets" src="https://github.com/user-attachments/assets/6ac41efa-3557-4d9f-aeb2-bbe5dc4608d0" /> | <img width="200" alt="NiceDamage" src="https://github.com/user-attachments/assets/fcb8a2a1-1adb-40fc-be00-0c09d2f801ec" /> |

## Arena: DR and DoTs

Two trackers that sit next to the arena frames. Both are on out of the box, and both are set up
in the panel under **Arena > DR** and **Arena > DoT** (Preview places them without being in a match;
Shift + Alt + drag moves all five frames together).

### Diminishing Returns

<img src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/arena-dr-panel.png" width="555" alt="DR options" /> <img src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/arena-dr-ingame.png" width="316" alt="DR icons next to the arena frames" />

One icon per DR category on each arena enemy, with a clock counting down to the reset: **1/2** means
the next CC of that kind will last half, **1/4** a quarter, **X** that they are immune. DR is shared
per category, so the hunter's trap shares it with Polymorph, Sap, Repentance and the rest.

Out of the box: icons of 25 growing to the left, the clock on, no colored border and no
"1/2 - 1/4 - X" text — the clock already tells you what you need mid-fight.

<img src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/arena-dr-categories.png" width="298" alt="DR categories" />

Only **Stuns** and **Incapacitates** are shown. The other categories keep counting in the background,
so ticking one later shows it already up to date. *All*, *My class* and *None* set the whole list
at once.

### DoTs

<img src="https://raw.githubusercontent.com/nidas-wow-oss/Nidhaus_UnitFrames/readme-images/images/arena-dot-panel.png" width="389" alt="DoT options" />

The periodic damage you have running on each arena enemy, as small icons beside their frame, so you
can see at a glance who is missing yours and when it is about to fall off.

Out of the box: up to 3 icons of 14 with no gap, growing outward from the frame, without the "DoT"
label or the red border.

## Installation

1. Download **`Nidhaus_UnitFrames-v4.4.zip`** from the [releases page](../../releases/latest).
   Take that file, **not** "Source code (zip)": GitHub wraps the source download in an extra
   `Nidhaus_UnitFrames-main` folder, and copying *that* into `Interface/AddOns/` does nothing.
2. Extract the archive. You will get three folders: `Nidhaus_UnitFrames`, `Nidhaus_UnitFrames_Config` and `Nidhaus_UnitFrames_Arena`.
3. Copy **all three** folders into your WoW `Interface/AddOns/` directory.
4. Restart the WoW client, or type `/reload` if you are already in-game.
5. Enable **all three** addons on the character selection screen. `Nidhaus_UnitFrames_Arena` is new in v4.4 and holds the arena frames: if it is not ticked, arena will not work.

> **Updating from an older version?** Delete the old `Nidhaus_UnitFrames` folder before copying the new
> one instead of overwriting it — files get reorganised between releases, and leftovers can cause
> errors. Your saved settings live in the `WTF` folder and are preserved.

> **The green *Code* button is not the download you want.** It gives you a folder called
> `Nidhaus_UnitFrames-main` with the three addon folders *inside* it. WoW will not see them:
> `Interface/AddOns/` needs the three `Nidhaus_UnitFrames*` folders themselves, not their container.
> If you did download it that way, open `Nidhaus_UnitFrames-main` and copy out the three folders.

## Slash Commands

| Command | Action |
|---------|--------|
| `/nuf` | Open the options panel |
| `/nuf config` | Show saved variables in chat |
| `/nuf arena` | Toggle arena test mode |
| `/nuf boss` | Toggle boss test mode |
| `/nuf reset` | Reset all settings to default |
| `/nuf modules` | List all modules and their status |
| `/move` or `/nufmove` | Move Everything: unlock every frame and drag it |

The minimap button also provides quick access: left-click opens the options panel, right-click toggles the arena mover.

## Compatibility

- **Client:** WoW 3.3.5a (WotLK)
- **Tested on:** Warmane Blackrock
- **API Level:** Compatible with 3.3.5a Lua sandbox (no HTTP, no hardware calls)

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


All rights reserved. This addon is provided as-is for personal use.
