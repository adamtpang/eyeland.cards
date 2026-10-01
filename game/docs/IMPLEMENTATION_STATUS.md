
## September 20: Foundations collection in native Godot

The current native catalog is **100 cards (25 Air, 25 Water, 25 Fire, 25 Earth; 60 minions / 40 spells; mana 0–10; 45 Common, 28 Rare, 19 Epic, 8 Legendary)**. Collection has search, element/type/rarity/mana/ownership filters, pagination, card inspection and owned five-card deck replacement. Selecting a support slot switches to owned cards. Four borrowed 30-card elemental practice decks let the whole catalog be played without mutating adventure saves; inspecting a card can guarantee it in the opening hand. This is preset practice, not a custom 30-card deckbuilder.

Engine additions: draw, empty-crystal ramp, board healing, summons, enemy/all-board damage and board/element buffs. Prototype art for 91 new cards reuses the original paintings and is labelled in hover details. Only the original starter/support cards and Crab reward are currently obtainable in the adventure. No progression, new wild encounters, crafting, multiplayer, unique art for every new card or deployment is implied.

[Roadmap](ROADMAP.md) separates working systems from proposed milestones; [Foundations index](FOUNDATIONS_CARDS.md) lists all cards. Tests: 472 collection checks including 40 element-match simulations, 328 core checks, 15 drag/structure checks, 12 reward/reload journey checks and 18 layout checks. Isolated test saves; these are automated checks, not balance or fun ratings. Screenshots: `game/evidence/godot-collection-2026-09-20/`.

## Latest: actual third-person Godot island and tabletop battles (2026-09-20)

Adam clarified that a moving map marker was not the intended overworld. `../godot/world_3d.gd` now builds physical 3D terrain, a visible CharacterBody3D adventurer, walking/sprinting/jumping, animated limbs, following elemental companion, collision-aware orbit/zoom camera, buildings/trees, six landmarks and optional stepping stones. E enters the native battle; retreat/defeat returns to camp. Optional saved `world_position` migrates older grid-position profiles without discarding collection progress.

`duel_board.gd` adopts the Hearthstone tabletop arrangement: opponent hero/backs above, two creature rows, your hero/power below, hand at bottom, deck stacks and End Turn at right. Oval tokens, Taunt frame, dim unavailable hand cards, native drag-to-play/target/attack, targeting arrow and attack feedback are implemented. Native engine now has opening-hand replacement and second-player 4+Coin. The adventure is still five cards and one encounter. **Full rules parity is unfinished**; read `../godot/PARITY.md` rather than applying the web client's completed checklist to Godot.

Read the complete saved JelloApocalypse transcript; synthesis and implemented-versus-planned adaptations are in `../docs/JELLO_LESSONS.md`. Current verification: 328 core checks including 300 simulations, 13 physical-world checks, 10 battle-structure/native-drag checks, 12 real-battle reward/reload journey checks, and 18 desktop/small-window UI checks. These are automated Godot input/handler tests, not an unaided human test. Evidence: `../evidence/godot-third-person-2026-09-20/`. Simple low-poly art remains prototype art. No deployment, crafting, XP, evolution or multiplayer added.

---

## Earlier implementation history

# Implementation status — 2026-09-20

## Inspected before editing

Existing repository: `C:/Users/adamp/Aether/eyeland.cards`, saved Codex project **🐉 eyeland.cards**. Read the mobile/desktop bridge in the existing `themain.quest` repository, root agent/Claude instructions, current continuation notes, and prior game-design research. No duplicate project or repository was created.

The working tree already contained extensive modified/untracked work, including the entire `game/web` directory. Preserved it; did not commit, reset, clean, deploy or push. Root landing-page and historical Unity descriptions lagged behind the actual implementation.

### Existing before this pass

- React 19 / TypeScript / Vite web client with Phaser 4 installed; Phaser template scenes were unused.
- Real two-player card engine and GreedyAI, 72 shared cards plus 21 web parity cards, 13 non-neutral classes, Fire/Water/Storm content, four rarities.
- Illustrated card/board UI, targeting, mulligan, timed turns and the mechanics described in `../web/PARITY.md`.
- Four-encounter Ember Reach, 12-card deck editor, creature-card/shard rewards and browser-local expedition saves.
- Thirty-card constructed practice; older Unity/C# client and simulation code retained as reference.
- Baseline: 81 engine checks and TypeScript checking passed locally before changes.

## Added in this pass

The default web entry is a separate **Home Island story sketch**. Choose Warrior/Ranger/Wizard and Fire/Water/Earth/Air. Explore an authored land/water grid with arrow keys, WASD or on-screen controls. Visit family, a friend, a resin crop, campfire and lookout. Start a Resin Crab encounter using the existing duel, not a second battle engine.

Each element supplies one three-mana Legendary placeholder plus four supporting cards. All four starters intentionally share stats/effect for this scaffold; names/portraits differ. The fixed class maps to an existing hero power, with Warrior using `fighter`. Earth/Air data loading was added without removing legacy Storm. Home-only card data is loaded for the encounter and restored afterward, keeping prototype cards out of normal constructed/Discover pools.

Victory returns remaining HP and grants one Crab card plus two luminous resin once. Rematches do not duplicate it. Retreat/defeat returns to the campfire at 1 HP; rest returns to 30. No collection is destroyed. The new story sketch is **session-only** and resets on reload or leaving it for Ember Reach. It does not read/write the existing expedition save key. Its collected Crab is visible but not yet equippable; the established expedition still has its original deck editor.

### Files

- `../web/src/starter/content.ts`: class/element registries, map, encounters, movement and outcome reducer.
- `../web/src/starter/starter-cards.json`: original placeholder card definitions.
- `../web/src/starter/StarterIsland.tsx` and `starter.css`: start/map/dialogue/recovery flow.
- `../web/src/starter/selftest.ts`: content, reachability, reward/defeat invariants and 300 battle simulations.
- Existing App, DuelScreen, engine element union, loader and card-art map receive small integration changes; `package.json` adds starter checks to `npm test`.

## Verification

`npm test`: 81 existing checks pass (including 1,000 baseline and 400 constructed simulations). Starter checks pass with 300 terminating games across all 12 class/element combinations. The AI pilot wins all 300: this is deliberately easy tutorial tuning, not evidence of balanced or enjoyable human play.

`npm run typecheck` and `npm run build` pass. No new dependency was installed. Repository-wide `git diff --check` finds pre-existing trailing whitespace in `game/unity/ProjectSettings/ProjectSettings.asset:686`; that unrelated file was not changed here.

Helium browser verification used native clicks for start, family interaction, six eastward moves, encounter entry, mulligan confirmation and playing Breeze Finch. A disclosed development-only real-engine AI sequence completed the remaining battle (32 actions), then a native Continue returned to the map at **23/30 HP with 2 resin**. Native rematch verified 23 starting HP; Retreat/Continue returned at 1 HP, and campfire restored 30 while preserving the existing reward. Ember Reach and practice loaded; practice's global card pool contained no `home-` cards. This is a mixed native-input/automated check, not a full unaided human playtest.

Screenshots: `../evidence/starter-2026-09-20/home-after-victory.png` and `mobile-map.png`. Only the local game viewport was captured. Desktop and 390px-wide map layouts were visually inspected; the narrow viewport has no horizontal overflow (document width 390px). Final typecheck/build passed again after adding creature placeholder symbols. Human fun, complete first-hour storytelling and online systems remain unvalidated.

## Limitations / next implementation

No save for the new story, starter evolution, fizzle, XP/ranks, card capture action, party allies/co-op, crafting, market, equipment/mounts, invasion cinematic or second island. The new map is a small React grid, not a final Phaser/3D overworld. The next useful test is the five-card encounter and whether its reward motivates a deck change; add a small story-deck editor and versioned persistence when this flow is understood.

## Godot vertical slice verified (2026-09-20)

Godot is the confirmed current engine. `game/godot` now runs in Godot 4.7.2 with a drawn starter island, three class powers/four elements, five-card battles, procedural creature portraits, first-victory Crab/resin rewards, owned-deck swapping, camp recovery and separate versioned local saves. Start with `Play Eyeland.cmd`; controls and limitations are in `game/godot/README.md` and `game/docs/PLAY_GODOT_MVP.md`.

Verification: 328/328 model/combat checks including 300 terminating simulations; 13/13 rendered journey assertions using injected Godot mouse/keyboard events plus UI signals/handlers, real victory, reward equip, scene restart, earned-card play, retreat and rest. Screenshots visually inspected in `game/evidence/godot-2026-09-20`. This is automated verification, not an unaided human playtest. It does not establish full Hearthstone parity, crafting, evolution, multiplayer or a complete island episode. Web/Unity preserved as references. Next gate: Adam's unaided playtest.

## Godot design pass (2026-09-20)

The current Godot client now uses an illustrated coastal storybook design: original generated nine-card art atlas and island background, local OFL fonts, parchment card faces, card inspection, quest journal, destination pathfinding, clear targeting, mana gems, damage feedback, Escape cancellation and confirmed retreat. See game/godot/DESIGN.md and assets/ART-PROVENANCE.md. Verified 328 model/combat checks, 14 rendered journey checks and 18 UI/layout checks (1280x800 and 1024x720 window sizes). Evidence: game/evidence/godot-design-2026-09-20. Human enjoyment and comprehension remain untested; this pass does not implement crafting, multiplayer or new progression. The map is illustrative over the existing navigation grid.
