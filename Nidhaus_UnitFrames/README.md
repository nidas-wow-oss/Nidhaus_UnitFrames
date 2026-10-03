# Nidhaus UnitFrames (NUF)

A PvP-focused UI addon for World of Warcraft WotLK 3.3.5a (Warmane Blackrock and other private servers).

NUF combines and reworks several existing addons — Eazy Frames and sArena among them — with its own features into one package focused on UI and PvP, all set up from a single in-game panel.

> ## Download
>
> **Latest version: 4.0** — this is the current, recommended build and the one actively in use.
>
> **[Download v4.0 (latest release)](../../releases/latest)**
>
> Grab the `.zip` from the release page rather than the green *Code* button: the release is the packaged,
> ready-to-install version with the correct folder name.

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-blue)
![Client](https://img.shields.io/badge/Client-WotLK-orange)
![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-red)

## Features

<img src="../images/panel.png" width="559" alt="NUF options panel" />

- **Unit frames** — player, target, focus, party and boss, with custom skins, class colors and per-frame scale.
- **Arena** — arena frames in two styles (Default and Flat) with trinkets, spec icons, DR and DoT tracking and countdown, plus a test mode to place them outside a match.
- **Party** — 3v3 arena layout with per-member scale, and a test mode to arrange the group while you are alone.
- **Move Everything** — drag any frame and resize it with Ctrl + mouse wheel.
- **Optional modules** — action bars, class trackers, tooltip, chat and quality-of-life extras, each one on or off from the panel.
- **Character Setup** — copy action bars, macros and keybinds between characters (nExtraBars included).
- **Profiles** — export and import your whole configuration.

<img width="215" alt="Arena" src="https://github.com/user-attachments/assets/ace03d46-ccb9-4952-b3c1-bdbd25d2b891" /> <img width="220" alt="Arena" src="https://github.com/user-attachments/assets/ba6e5101-b017-4d48-a4bc-9b57ba7d2023" /> <img width="212" alt="Arena" src="https://github.com/user-attachments/assets/431c3a78-f485-40e2-b942-b1a4e6202e0c" /> <img width="137" alt="DoT warning" src="../images/arena-dot-warning.png" />

| New Party Frame | Party Targets | NiceDamage |
|:-:|:-:|:-:|
| <img width="75" alt="NewPartyFrame" src="https://github.com/user-attachments/assets/79210886-68ca-4a54-adaf-a69cfa139953" /> | <img width="100" alt="PartyTargets" src="https://github.com/user-attachments/assets/6ac41efa-3557-4d9f-aeb2-bbe5dc4608d0" /> | <img width="200" alt="NiceDamage" src="https://github.com/user-attachments/assets/fcb8a2a1-1adb-40fc-be00-0c09d2f801ec" /> |

## Installation

1. Download **v4.0** from the [releases page](../../releases/latest).
2. Extract it and copy the `Nidhaus_UnitFrames` folder into your WoW `Interface/AddOns/` directory.
3. For the full options panel, also install the companion addon
   **[Nidhaus_UnitFrames_Config](https://github.com/nidas-wow-oss/Nidhaus_UnitFrames_Config)**
   into the same `Interface/AddOns/` directory.
4. Restart the WoW client, or type `/reload` if you are already in-game.

> **Updating from an older version?** Delete the old `Nidhaus_UnitFrames` folder before copying the new
> one instead of overwriting it — files get reorganised between releases, and leftovers can cause
> errors. Your saved settings live in the `WTF` folder and are preserved.

> If you downloaded the repository with the green *Code* button, the extracted folder will be named
> `Nidhaus_UnitFrames-main`. Rename it to `Nidhaus_UnitFrames` or the addon will not load.

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

## Changelog

### v4.0
- New DR tab in Arena: Diminishing Returns icons on every arena enemy (1/2, 1/4, immune), with preview, Shift+Alt drag, grow direction, size, spacing and a border colored by DR level. You pick which categories to show (All, My class, None, or one by one; hovering a category lists the spells that share it), and each icon shows the seconds left until the DR resets.
- New DoT tab in Arena: marks the enemies that have a damage-over-time effect on them, with the same preview and layout options.
- Arena > Frames reorganized: scale and style at the top, and a single 2v2 / 3v3 / 5v5 / Hide preview row instead of Show Arena Frame plus the Test buttons. The test pets follow the number of frames and no longer stay on screen after closing the test.
- Shadow Sight timer starts with the arena start message and stops when the match ends.
- "Arena Points" is now "Arena Calculator".
- Arena, party and pet frames are no longer moved, scaled or hidden during combat (the game blocks it): those changes wait until the fight ends. This removes the "action blocked" errors that filled the taint log.
- Party Buffs and Party Debuffs are now separate options, each with its Castable Buffs / Dispellable Debuffs sub-option, synced with Blizzard's Interface options.
- Party Targets: optional class icon in the portrait, and "Hide target name" now works every time.
- The Party Castbars and Party Buffs windows open above the NUF panel, with a solid background.
- Big text (Interface > General > Status Text): moves the name above the Player, Target and Focus frames and centers the health number, with optional sizes for the health and mana text. Available with the Light, Dark and Compact themes.
- Abbreviated status text: default positions for the Blizzard frames, and a separate set of positions for Big text.
- The Lorti UI minimap border works with the square minimap, applies without /reload, and is the same option as Lorti UI > Minimap in the Addons tab.
- nExtraBars: the stance / aura / presence bar sits above the nExtraBars left bar instead of under it.
- Chat Copy works in whisper tabs.
- Gargoyle Tracker closes when the gargoyle dies, when the match ends or when you change zone.
- Profiles: export and import include the Move Everything positions and scales, and every character is saved on login and logout for Profiles / MySlot.
- The resets use the real default scales and positions, and the panel buttons no longer print messages in the chat.
- Lighter in combat: Spec Icons only read the combat log in arenas, battlegrounds and duels, and the Gargoyle Tracker timer sleeps while there is no gargoyle.
- Bug fixes.

### v3.9
- Pet tab: Pet Buffs checkbox, a Move button that unlocks only the pet frame (no party test frames, arena mover or console), and a Reset that only touches the pet. It used to resize the party frames with 3v3 on: the party scale had a third, hidden owner in the move-mode positions. Old saved values are dropped automatically.
- 3v3 party mode: the scale no longer breaks when you turn it back on after using Party Frame Scale, party frames dragged with 3v3 on stay where you drop them, and the checkbox and the four per-member sliders are mirrored in Frames > General.
- One "Reset Scales & Positions" button for the unit frames: scale and position together, 3v3 sliders included, respecting 3v3 and without /reload.
- Focus Scale applies live while dragging. A dead entry in the scale table made the slider skip its live path.
- Switching the unit frame style or the custom texture applies at once instead of asking for /reload.
- Frames > General reorganized: scales on top in two even columns (Player / Target / Focus and 3v3), position below with Unlock and Reset side by side.
- Character Setup now includes nExtraBars: the 24 buttons of both talent specs, their macros, which bars are enabled, button count and lock. Clear Bars and Undo cover them too. Each character is also saved on logout, so what you set up during the session is what gets copied. With nExtraBars 2.2.3 the bar settings apply without /reload.
- Party Casting Bars: moving one bar moves all four, and their reset brings back all four.
- Hide Action Bar Textures and MiniBar's "Hide bar background" no longer fight each other when toggled.
- Ammo counter: Lock / Unlock button, `/arrowcount lock | unlock`, and it locks itself in combat.
- The resets no longer print to chat.

### v3.8
- Party member names no longer slide down over the health bar during a fight. Blizzard re-anchors them on every party update, and the restyle was skipped in combat.
- Character Setup only lists characters of your own class. Other WoW accounts still need Export / Import: the game never loads their data.
- Gargoyle Tracker works in any client language. The creature name is learned from the summon event instead of being hardcoded in English, and is remembered per language.
- The grey strip left under the action bars is gone. It was looked up under a name that does not exist, so nothing was ever hidden and nothing ever complained.
- Arena: 2, 3 and 5 test frames like sArena; Pet Style only offered in the Flat layout; default Flat width is 100.
- Arena Points Calculator shows up on the first toggle instead of needing a tab change, and its position is fixed.
- 3v3 party mode had no combat guards at all; it does now.
- Lorti UI tints the party target frame again.
- The profiles tab is now "Profiles / MySlot", and the footer button is measured from its text instead of a fixed width.

### v3.7
- Party frames now fall back to Blizzard's own health bar and background while in a vehicle.
- MiniBar no longer fights the vehicle bar while driving (demolishers, cannons).
- Micro menu stays visible on top of the vehicle bar instead of being drawn behind its art.
- Gargoyle Tracker crowd-control timers respect PvP durations (Turn Evil shows 10s, not 20s).
- Move Everything only offers the Pet frame to classes that actually have a pet.
- Cast bar keeps its scale and position when toggled, and stays compatible with Move Everything.
- Profiles dropdown groups characters by realm instead of running off the screen.
- Party pet frames for party1-4, arena-only by default (`/ppf arena`).
- Options window tabs shrink and pack together when the window is resized.
- Minimap: the square shape now loads the Blizzard default border texture.
- Removed the leftover diagnostic slash commands.
- Spanish localisation completed: every string now exists in both languages.

### v3.6
- Fixed style menu options
- Fixed text display issues
- Fixed various frame bugs

## License

All rights reserved. This addon is provided as-is for personal use.
