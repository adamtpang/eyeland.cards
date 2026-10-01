> Latest: the painted-map exploration and flat battle rows described historically below have been replaced by a physical third-person island and tabletop battle layout. See [README](README.md), [parity status](PARITY.md), and [Jello lessons](../docs/JELLO_LESSONS.md).

# Coastal storybook interface

Design pass: September 20, 2026. Native Godot UI, retaining the existing battle/model/save behavior.

## Reference and direction

Adam's named reference is Hearthstone. The [official card library](https://hearthstone.blizzard.com/en-us/cards) grounds the card hierarchy: creature illustration, mana, name, rules, attack and health. Eyeland uses original artwork and frames, not Blizzard assets. The adventure's coastal identity comes from the existing Eyeland design documents: a home worth protecting, collectible companions, a resource garden and the promise of islands beyond it.

Direction: illustrated coastal fantasy, comfortable exploration and compact battles. Deep marine surfaces, warm parchment cards, brass actions, serif titles and readable sans-serif controls. The combat screen keeps hand, both boards, mana and End turn visible together. No web framework or dependencies were added.

## Tokens

| Role | Value |
|---|---|
| Background | `#09131a` (existing Godot background) |
| Ink | `#102833` |
| Panel | `#183541` |
| Foreground | `#f6eddc` |
| Secondary text | `#a9bec1` |
| Primary / focus | `#e6be77` |
| Playable / success | `#77d2bd` |
| Parchment | `#e8dcc3` |
| Body | Poppins Regular |
| Titles | Cormorant Garamond |
| Panel radius | 14 px |
| Button radius | 9–12 px |
| Main spacing | 12 px; 6 px in battle |
| Screen transition | 180 ms fade |
| Walking | Continuous 3.6 navigation units/sec, normalized diagonals |

Fonts are local with OFL license files in `assets/fonts`. Native Godot theme tokens live in `skin.gd`; card frames/inspection in `card_face.gd`. This game has one intentional dark theme, not a website light/dark toggle.

## Player-facing improvements

- Class selection previews the class power; companion selection previews the actual card and larger portrait.
- A painted island, landmark pins, hover destination cue and pathfinding replace the block grid. The background is illustrative; the navigation still uses the existing logical grid.
- A three-step quest journal shows family interaction, victory and equipped reward independently.
- Contextual nearby actions, persistent deck navigation and an expandable how-to-play guide.
- Parchment cards with blue mana, gold attack, red health and rarity gems. Hover inspection shows larger artwork, complete rules and current creature stats.
- Ready/selected/target states carry text as well as border colors. Unaffordable hand cards explain the missing mana in their tooltip.
- Stable opposing/friendly board lanes, visible mana crystals and a thin turn timer.
- Floating damage numbers for targeted player actions. This is feedback, not a complete combat animation system; opponent actions still progress with the existing paced AI and log.
- Escape cancels targeting. Retreat asks for confirmation and pauses the player's clock while the dialog is open.
- Victory leads directly to deck editing; defeat offers immediate rest. Collection changes have a saved confirmation.

## Verification

- 328/328 existing model/combat checks, including 300 simulated tutorial games.
- 14/14 rendered journey checks after redesign: injected Godot mouse/keyboard input plus UI callbacks, real battle victory, earned-card swap, scene restart, earned-card play, retreat, rest, destination pathfinding and rejected ocean destination.
- 18/18 design checks: desktop 1280×800 and window size 1024×720, horizontal bounds, battle vertical bounds, legal Taunt/spell targets, Escape, cancelled retreat, pathfinding. Screenshots include deliberately constructed battle fixtures; these are distinct from the real-engine journey.
- Visually inspected setup, island, battle, collection and small-window captures in `../evidence/godot-design-2026-09-20`.
- Calculated text contrast: foreground/panel 11.12:1; secondary/panel 6.66:1; primary button 8.74:1; card rules/parchment 11.25:1; gold/panel 7.39:1; success/panel 7.23:1. These verify the named flat-color pairs, not every antialiased pixel or illustration.

Still unverified: unaided player comprehension, human enjoyment, screen-reader access, touch devices, exported binaries and varied GPU/display configurations. Tooltips provide larger rules at small window sizes, but readability remains a playtest question. The map artwork does not add a free-roaming world or new collisions. No multiplayer, crafting, progression or engine-parity features were implied by this art pass.

## Walking follow-up

A 1.65× following camera and animated cloaked character replace the map marker. Hold WASD/arrows, click to pathfind or press E near a landmark. Battle hand availability uses a dedicated desaturation/dimming shader; collection colors are unchanged. See README for verification and collision limits.
