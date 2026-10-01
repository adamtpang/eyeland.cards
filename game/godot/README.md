> **Latest: Foundations collection.** Open **Collection** to browse 100 cards, filter/search, inspect, and replace an owned support card. **Practice** borrows a 30-card elemental deck; the card inspector can guarantee a selected card in your opening hand. Practice leaves adventure health, cards and rewards unchanged. New cards currently share prototype art; most acquisition routes are still planned. See [roadmap](../docs/ROADMAP.md) and [card index](../docs/FOUNDATIONS_CARDS.md). Verified by `tests/collection.gd` (472 checks).

# Eyeland: Godot third-person prototype

**Current playtest overrides the earlier collection instructions above:** launch `Play Eyeland.cmd`, then **Play**. Saved custom **30-card** decks, **30 starting health each**, **2-mana powers**, **10 max mana**. Click deck entries to remove; Add beneath cards to replace. Ordinary cards: max 2, Legendary: max 1. All 100 cards are available for testing. F8 / Report bug captures local match diagnostics. [Parity gaps and instructions](PARITY.md). Earlier five-card inventories are historical.

September 20, 2026. Godot 4.7.2, GDScript, desktop compatibility renderer. A small physical 3D island connected to native card battles. The character, buildings and terrain use simple original low-poly geometry; this is a prototype, not final production art.

## Play

Double-click **Play Eyeland.cmd** in the repository root, or run `game/scripts/play-godot.ps1`. The launcher uses Godot under `%LOCALAPPDATA%/EyelandTools/Godot/`; use `-Editor` to edit the project.

- **WASD / arrows:** walk relative to the camera.
- **Shift:** run. **Space:** jump.
- The camera smoothly turns behind your direction of travel and follows your position/jumps. It stays still when you stop.
- **Right mouse drag:** manually orbit; automatic following pauses while you look around and briefly afterward. **Wheel:** zoom.
- **E:** talk, inspect, rest or battle at a nearby landmark.
- **Your deck:** equip owned cards; your Legendary companion stays with you.

Explore the family home, Mira, garden, campfire, lookout and optional jumping stones. Walk to the Resin Crab near the garden and press E. The elemental companion follows you. First victory adds one Crab card and two resin, and flowers appear at the garden. Camp heals you. Defeat or retreat returns you there at 1 HP.

In battle, choose opening-hand replacements, then begin. Drag a playable card onto your field, or click it. Drag targeted damage onto an enemy. Drag a ready creature onto an enemy to attack, or select it then click the target. Taunt protects other enemies from attacks. Cards you cannot currently play appear slightly gray; hover still shows their details. Hero power and End Turn sit at the right of your hero/field. The turn timer waits until the opening hand is confirmed.

## Current scope

One explorable island, one encounter, three classes, four elemental starter variants, nine starter card definitions plus Coin, five-card adventure decks, owned-card editing, local saves and first-victory rewards. Continuous 3D character physics, terrain/building/tree collision, sprint/jump/gravity, animated limbs, companion following, collision-aware orbit camera and position persistence are implemented.

The battle screen now follows Hearthstone's basic tabletop structure and supports opening-hand replacement, Coin, drag/target interactions, oval tokens and attack feedback. **Full Hearthstone rules parity is unfinished**; see [PARITY.md](PARITY.md) for implemented behavior and exact gaps. No crafting expenditure, XP, evolution, multiplayer, extra islands, accounts or public deployment.

Design reading: [JelloApocalypse lessons](../docs/JELLO_LESSONS.md). Existing web/Unity prototypes and research remain reference material.

## Saves

`%APPDATA%/eyeland-godot-mvp/home-v1.json`, separate from the older web/Unity saves. Older Godot grid-position saves load into the 3D island; optional `world_position` stores the new coordinates. Closing mid-battle counts as retreat on the next launch. Invalid/unknown-version saves are preserved. Tests use their own temporary saves.

## Verification

- `tests/check.gd`: 328 checks, including 300 terminating tutorial simulations.
- `tests/world3d.gd`: physical movement, sprint, jump/landing, camera orbit, cottage collision, E interaction, encounter entry, retreat location, focus-loss stopping and position reload.
- `tests/duel_structure.gd`: 10 checks including real injected Godot mouse drags, mulligan, Coin and burn.
- `tests/journey.gd`: 12 full-loop checks, real battle victory through saved/reloaded reward use.
- `tests/design.gd`: 18 targeting/confirmation/layout checks at desktop and 1024x720.
- `tests/walking.gd` is a compatibility entry point for the new 3D tests. Old painted-map movement evidence is historical.

Run from repository root with the console Godot executable and `--path game/godot --script res://tests/<name>.gd`. Use `--headless` for `check.gd`; run the other tests with rendering enabled. Evidence lives in `../evidence/godot-third-person-2026-09-20/`.

Automation establishes behavior, not fun. The next human test is exploring unaided, winning the Crab card, equipping it, and seeing whether the rematch feels meaningfully different.

## Hero artwork

Warrior, Ranger and Wizard now have distinct face portraits and matching illustrated hero powers. Hover either for a larger preview. The power shows its 2-mana cost and dims when unavailable; USED marks a power already activated this turn. Assets and exact generation prompts: [hero artwork](assets/heroes/README.md). Verified with 11 rendered hero-art checks and the 10-check native drag regression.

## Drag/drop and quieter screens

Drag a card onto the highlighted battlefield. The insertion slot previews creature placement, including drops over existing creatures. Drag damage cards or ready creatures onto highlighted enemies. Release outside a valid area or press Escape to cancel without spending mana. Clicking still works. Explanations now live in hover details or the ? guide; health, mana, rewards, actions and card rules stay visible. The recent action log is on the small history control at the left of the board.
