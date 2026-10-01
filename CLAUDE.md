# CLAUDE.md - eyeland.cards

Context for Claude Code, Codex, and humans working in this folder.

> **2026-07-11:** Read `HANDOFF.md` next: it has the current deploy report,
> the domain decision (stay on eyeland.cards), and the continuation context.
> The Hearthstone deckbuilding project now **lives in this repo** at
> `hearthstone/` (read its own CLAUDE.md before Hearthstone work); the Unity
> card game (via Unity MCP) comes after. Career note: HSReplay is hiring:
> the tooling here doubles as portfolio material.

## What this is

This handoff was generated on 2026-07-08 during the new-day Claude/Codex sync.
No repo-local `CLAUDE.md` existed before this run, so this file was created from
the best available local context.

## Detected project facts

- Workspace folder: `eyeland.cards`
- Git repository: yes
- Detected stack: static HTML
- HTML title: eyeland.cards, open-world card-combat MMORPG
- Notable top-level files: .gitignore, favicon.svg, index.html, README.md

## 2026-07-08 Codex landing page update

- `index.html` was tightened for ASAP prelaunch/itch.io use:
  - Hero now leads with `eyeland.cards` as the product name.
  - Above-the-fold copy says `Unity pre-alpha` and `itch.io build next`.
  - Added development status chips and a `First Build` navigation target.
  - Added a compact build ladder: `v0 Duel -> v1 Deck -> v2 Island -> v3 World -> v4 Online`.
  - Waitlist CTA now asks for the first itch.io playable link.
- Waitlist is still intentionally lightweight: it validates an email and opens a `mailto:` to `adamtpang@gmail.com`; no backend capture exists yet.
- Milanote mood-board link was provided by Adam, but the plain web fetch did not expose content in this run. Current design pass stayed grounded in the repo-local floating-islands/card-combat context.
- Verification run: `node C:\tmp\eyeland-static-check.mjs` passed. It checks inline JS parsing, local anchor targets, and required hero/build/waitlist copy.
- Visual screenshot verification was attempted but blocked by local browser/runtime availability: node_repl hit an AppData `EPERM`, bundled Playwright lacked `playwright-core`, and Chrome/Edge were not visible at common paths from the sandbox.

## Current open launch tasks

- Add the real itch.io URL once the page/build exists.
- Replace mailto with a real waitlist backend before sending traffic.
- Run a browser screenshot pass on desktop/mobile when a browser path is available.

## Imported existing context

Source: `README.md`

```markdown
# eyeland.cards

An open-world **card-combat MMORPG** — the spell-duels of Wizard101, the deckbuilding of Hearthstone, and the open world of Pokémon, set across a floating archipelago called **the Eyeland**. Built in Unity with Claude.

This repo currently hosts the **pre-launch landing page** (`index.html`), a self-contained static page deployed to Vercel.

## Status
- [x] Landing page v1
- [ ] Card-duel core — turn-based combat engine (cards as ScriptableObjects + pip/turn/resolution loop)
- [ ] Deckbuilding
- [ ] Overworld + wild encounters
- [ ] Online layer

## Build ladder
`v0 Duel → v1 Deck → v2 Island → v3 World → v4 Online` — build the game first, add the MMO layer last.

## Landing page
`index.html` is fully self-contained (no external fonts, images, or scripts). Open it directly in a browser, or deploy the repo root to any static host.
```

## How to keep this useful

- Update this file when Claude or Codex learns new project facts.
- Keep `AGENTS.md` synchronized so Codex sees the same context inline.

## Eyeland progression clarification (2026-09-09)

Adam confirmed: defeating creatures awards their own cards plus crafting
resources. Defeating stronger creatures strengthens the player's deck.
Creatures/cards have Common, Rare, Epic, and Legendary tiers. Read
`game/DESIGN.md` Principle 11a and `MASTERPLAN.md` for the updated reward scope.
This is design direction; integrated loot and crafting are not implemented.

## Elan Lee research (2026-09-11)

Read `game/ELAN-LEE-LESSONS.md` before designing progression or onboarding.
It synthesizes all 23 available @ElanLee caption transcripts with source links,
explicit digital adaptations and three unrun playtests. Next proposed test:
defeat one creature, award its own card plus a resource token, and observe
whether the player uses a new tactic in the next fight. Preserve Adam's four
rarity tiers and game direction; the current C# rarity enum still lacks Epic.
Raw captions remain outside the repository. This research does not establish
that integrated rewards, saving, the turn timer or a complete island are built.

## 2026-09-11: Ember Reach local playable prototype

The default Unity boot now opens a connected solo expedition: three camps and a Warden, timed real-engine duels, defeated-creature card rewards, ember shards, owned 12-card deck editing and browser-local saves. Common/Rare/Epic/Legendary are represented. The route is an encounter menu with seeded supporting cards and shuffles; a walkable 3D island, crafting recipes and multiplayer are still not implemented.

Play instructions: game/PLAY-EMBER-REACH.md. Local URL: http://127.0.0.1:8765/ while the server runs; restart with game/scripts/play-ember-reach.ps1. Build with game/scripts/build-ember-reach.ps1. Unity 6000.5.7f1 plus WebGL was restored under Adam's AppData/Local/EyelandTools; see game/LOCAL-UNITY-RUNTIME.md. Production was not deployed.

MVP-READINESS.md records 100/100 for the fixed local technical scope: final 10/10 Unity tests, a four-encounter UI-handler journey, 400 terminating engine simulations, and native Helium first victory -> reward -> deck edit -> reload -> earned card in next duel. The full four-fight journey was not played through native browser input. Human enjoyment and session length remain unvalidated. MVP-NEXT-PROMPT.md starts with Adam's unaided playtest; preserve prior research and unrelated working-tree changes.

## Creature art and game identity (2026-09-11)

Read game/EYELAND-IDENTITY.md: Adam reaffirmed creature collection/capture, resources and crafting, persistent RPG progression and multiplayer questing. Victory-card collection is implemented; separate capture, recipes, character leveling and co-op remain planned. Eight Ember Reach creature portraits were generated and saved in Unity Resources. CardVisual.cs provides illustrated hand/board cards and hover/focus inspection; game/CREATURE-ART-PROMPTS.json records exact built-in generation prompts. Do not treat art completion as implementation of the planned RPG/MMO systems.

## GDC learning (2026-09-12)

Read `game/GDC-LESSONS.md` before changing card progression, onboarding, combat feedback or crafting. It synthesizes three fully read available GDC transcripts plus a focused fourth-talk excerpt, with timestamp citations, source limitations and three unrun playtests. The strongest next test is an unaided victory -> earned Wolf -> intentional deck change -> useful next-fight action. Do not confuse technical readiness with human enjoyment. Resources are currently derived from clears; real crafting requires a saved expenditure ledger. The full GDC copy stays private in `knowledge-private/gdc/`, excluded from Git and Vercel. No gameplay changes or tests were executed by this research pass.

## Web client scaffold (2026-09-14)

Adam chose a web stack over Unity (slow WebGL build loop) and Godot (Godot 4 still cannot export C# projects to the web). `game/web` was scaffolded from the official Phaser template https://github.com/phaserjs/template-react-ts (MIT) at commit c7265972c856906cacf1f2892d8565d64a358d34: Phaser 4 for the board, React 19 for menus, Vite, TypeScript. The template's `log.js` telemetry ping is removed from the npm scripts (file left unused). `npm install`, `npm run build` and the dev server (port 8080, launch config `eyeland-web`) were verified; it still shows the template's placeholder scenes. No mature permissively licensed web Hearthstone clone exists (Fireplace and SabberStone are AGPL), so no game logic was copied. The Unity prototype still has no unaided human playtest.

### Engine port (2026-09-14)

`game/web/src/engine` is a TypeScript port of the C# engine (engine.ts, loader.ts, ai.ts, island.ts, rng.ts), reading `game/data/cards.json` directly (Vite `server.fs.allow: ['..']`). `npm test` runs 32 checks: data loading, every keyword, spell damage (spells only), auras, deathrattles, hero powers, IslandRun, and a 1,000-game GreedyAI simulation (51.8% first-player wins, 11.9 avg turns vs the C# engine's 51.5% and 11.8). Deliberate differences: seeded mulberry32 instead of System.Random (same seed does not replay the C# sequence), and an attack on a dead or missing target is refused before the swing is spent. `src/duel/DuelScreen.tsx` is a playable React duel vs GreedyAI (class picker for hero power, 75s rope in the front end, targeting, log). Verified in the preview browser: turn loop, AI turn, creature play with battlecry, Ember Bolt to face with first-spell draw. Friendly targeting fixed in the web engine (2026-09-17): cards and hero powers carry a `targetSide` (enemy or friendly), inferred in loader.ts from buffTarget/healTarget/grantTaunt or set explicitly, and mixed cards fail loudly. `TurnEngine.legalCreatureTargets` is the single source for the UI, the AI and the engine, and enemy effects can no longer aim at Stealth. `npm test` is now 43 checks. Verified in the preview: Bard Encore highlighted and buffed only your own creature. The C# engine still has the old enemy-only bug. The template's Phaser scenes in `src/game` are unused for now.

### Ember Reach on the web (2026-09-16)

`src/island/IslandScreen.tsx` is the web version of the Unity expedition: four encounters (three camps and the Warden) unlocked in order, enemy health 14 plus 5 per camp, wins award the creature card (1 copy for the Warden, 2 otherwise) plus shards, `DeckEditor.tsx` edits the 12-card deck from owned cards, `storage.ts` saves seed/cleared/deck to localStorage (`eyeland.island.v1`, fresh runs saved immediately, unreadable saves preserved until a confirmed new expedition). `DuelScreen` now takes the encounter as props (decks, enemy name and health, seed, onEnd) with Retreat and Continue. Verified in the preview browser via scripted clicks: camp launch, defeat path with no reward, victory on turn 7 awarding 2 Cinder Wolf and 2 shards, save surviving reload, deck edit putting the Wolves in. Not yet: class decks, a drawn island map, crafting recipes, art in the web client. The C# and Unity versions are unchanged and remain the reference.

### Hearthstone-style card look (2026-09-17)

`src/duel/CardView.tsx` + `hs.css` render every card like Hearthstone: mana gem, oval art for creatures and window art for spells, name banner, rarity gem, rules text with bold keywords, attack and health gems. Board creatures are portrait tokens (Taunt frame, Divine Shield glow, frozen tint, Stealth fade, hover card preview), heroes are portraits with a health gem, and mana shows as crystals. The deck editor uses the same card face. Art: the 8 painted Unity portraits are resized to `public/art/<id>.jpg` (about 80 KB each); the other 64 cards use a generated element backdrop plus an emoji subject from `src/duel/cardArt.ts`. To swap in real art, add `public/art/<id>.jpg` and add the id to `PAINTED`. The image connector had 0 credits, so no new art was generated or bought. Rules parity with Hearthstone (weapons, secrets, Discover, attack animations, mulligan, 30-card decks) is not done.

### Hearthstone rules parity (2026-09-18)

`game/web/PARITY.md` is the checklist and it is complete: hand limit 10 with burn, board limit on play, 3/4 opening hands with The Coin, mulligan, Armor, 30-card constructed rules (`engine/constructed.ts`), weapons and hero attacks, Secrets, Discover, Choose One, Combo, Silence, Overload, opponent card backs, floating damage numbers, attack lunges and emotes. The new mechanics' cards live in `game/web/src/data/parity-cards.json` (21 cards incl. The Coin), merged at load by `mergeCardJson`, so the shared `game/data/cards.json` still loads in C# and Unity, which do not implement these mechanics. `npm test` is 81 checks. The island screen has a Practice duel button for constructed play. A development-only `window.__duel` hook exists for browser checks and is stripped from production builds.

## 2026-09-20: Brainstorm Island Cards desktop takeover

Read `game/docs/README.md` for the complete recovered design-context set (14 requested systems/scope documents with explicit direction versus hypotheses), and `game/docs/IMPLEMENTATION_STATUS.md` for verified implementation state. The existing React/TypeScript web client is retained; no Godot/Unity restart. Default entry now offers an authored Home Island story sketch with movement, three starter classes, four elements, five-card decks, Legendary placeholders and one real-engine encounter/reward/rest loop. `game/docs/PLAY_STARTER_ISLAND.md` explains local play. New story progress is session-only; existing Ember Reach saves and practice remain separate. Baseline 81 engine checks plus 300 starter simulations, typecheck and build pass. No publishing/deployment/commit was performed. Co-op, market, crafting, fizzle/evolution and full story remain design work.

## 2026-09-20 latest decision: Godot MVP

Adam explicitly chose Godot after reviewing the web handoff and requested continuation in his existing `🐉 eyeland.cards` Codex task. Read `game/docs/GODOT_MVP_HANDOFF.md` first: it contains the receiving prompt, complete design-document manifest, source conversation/task IDs, engine-decision precedence, reference code, test evidence and authorized local MVP scope. Earlier instructions to retain the web engine as the primary target are superseded; retain web/Unity as reference and preserve their files/saves. Receiving task: `01a07a68-c70e-7dc3-ad79-36883192f4cd`.

## Godot vertical slice verified (2026-09-20)

Godot is the confirmed current engine. `game/godot` now runs in Godot 4.7.2 with a drawn starter island, three class powers/four elements, five-card battles, procedural creature portraits, first-victory Crab/resin rewards, owned-deck swapping, camp recovery and separate versioned local saves. Start with `Play Eyeland.cmd`; controls and limitations are in `game/godot/README.md` and `game/docs/PLAY_GODOT_MVP.md`.

Verification: 328/328 model/combat checks including 300 terminating simulations; 13/13 rendered journey assertions using injected Godot mouse/keyboard events plus UI signals/handlers, real victory, reward equip, scene restart, earned-card play, retreat and rest. Screenshots visually inspected in `game/evidence/godot-2026-09-20`. This is automated verification, not an unaided human playtest. It does not establish full Hearthstone parity, crafting, evolution, multiplayer or a complete island episode. Web/Unity preserved as references. Next gate: Adam's unaided playtest.

## Godot design pass (2026-09-20)

The current Godot client now uses an illustrated coastal storybook design: original generated nine-card art atlas and island background, local OFL fonts, parchment card faces, card inspection, quest journal, destination pathfinding, clear targeting, mana gems, damage feedback, Escape cancellation and confirmed retreat. See game/godot/DESIGN.md and assets/ART-PROVENANCE.md. Verified 328 model/combat checks, 14 rendered journey checks and 18 UI/layout checks (1280x800 and 1024x720 window sizes). Evidence: game/evidence/godot-design-2026-09-20. Human enjoyment and comprehension remain untested; this pass does not implement crafting, multiplayer or new progression. The map is illustrative over the existing navigation grid.

## Godot movement and availability (2026-09-20)

Hand cards that cannot currently be played are slightly desaturated/dimmed. Overworld movement now supports held WASD/arrows, normalized continuous motion, an animated character, 1.65x following camera, camera-relative click pathfinding and E interaction. Navigation still uses the original grid over painted 2D scenery; saved positions resume at cell centers. Rendered journey 14/14 and movement/availability 13/13 passed. README and DESIGN in game/godot describe controls and limits.

## Latest: actual third-person Godot island and tabletop battles (2026-09-20)

Adam clarified that a moving map marker was not the intended overworld. `game/godot/world_3d.gd` now builds physical 3D terrain, a visible CharacterBody3D adventurer, walking/sprinting/jumping, animated limbs, following elemental companion, collision-aware orbit/zoom camera, buildings/trees, six landmarks and optional stepping stones. E enters the native battle; retreat/defeat returns to camp. Optional saved `world_position` migrates older grid-position profiles without discarding collection progress.

`duel_board.gd` adopts the Hearthstone tabletop arrangement: opponent hero/backs above, two creature rows, your hero/power below, hand at bottom, deck stacks and End Turn at right. Oval tokens, Taunt frame, dim unavailable hand cards, native drag-to-play/target/attack, targeting arrow and attack feedback are implemented. Native engine now has opening-hand replacement and second-player 4+Coin. The adventure is still five cards and one encounter. **Full rules parity is unfinished**; read `game/godot/PARITY.md` rather than applying the web client's completed checklist to Godot.

Read the complete saved JelloApocalypse transcript; synthesis and implemented-versus-planned adaptations are in `game/docs/JELLO_LESSONS.md`. Current verification: 328 core checks including 300 simulations, 13 physical-world checks, 10 battle-structure/native-drag checks, 12 real-battle reward/reload journey checks, and 18 desktop/small-window UI checks. These are automated Godot input/handler tests, not an unaided human test. Evidence: `game/evidence/godot-third-person-2026-09-20/`. Simple low-poly art remains prototype art. No deployment, crafting, XP, evolution or multiplayer added.

## Illustrated heroes and powers (2026-09-20)

Native Godot battles now show class-specific human hero portraits for Warrior/Ranger/Wizard, separate from the starter creature. Brace, True Shot and Spark have original generated artwork in round power controls with mana cost, availability/used states and enlarged hover previews. Enemy Resin Crab retains its illustrated portrait. Six assets and exact built-in imagegen prompts: `game/godot/assets/heroes/`. `tests/hero_art.gd` passed 11 rendered interaction/layout checks; native drag regression passed 10 checks. Existing player battle was not interrupted; restart after finishing to load the art. No rules/save-format changes.

## Movement-following camera (2026-09-20)

Godot's third-person camera now smoothly aligns behind movement, retaining manual orbit/zoom and a short manual-input grace period. The movement reference is held stable while the same direction key remains pressed so automatic camera rotation cannot cause circular running. Idle camera remains stable. Rendered world suite: 16/16 checks, including directional following, straight movement during orbit and idle stability. Evidence log: game/evidence/godot-camera-follow.log.

## Reliable drag/drop and minimal screen text (2026-09-20)

Battle cards use explicit press/move/release handling with pickup preview, broad field acceptance, visible insertion slots, enemy targeting highlights, and cancellation on invalid drop, Escape or focus loss. Minions accept a board insertion index in `battle.play`; dropping onto occupied friendly slots works. Mouse release after Escape is consumed so it cannot accidentally click-play the card. Click-to-play remains an alternative. `tests/duel_structure.gd`: 15/15 checks, including real injected pointer movement, occupied drops, insertion, cancellation and targeted/untargeted spells. `tests/check.gd`: 328/328; rendered layout 18/18; full reward/save journey 12/12.

Repeated screen instructions, decorative subtitles, persistent action log, success-save footer and distant landmark labels removed. Essential stats/actions/card rules remain; help, class-power descriptions, landmark dialogue, and recent actions are on hover or explicitly requested help. Save errors remain visible. Evidence: `game/evidence/godot-clean-ui-2026-09-20/`, `game/evidence/drag-placement.png`. Full Hearthstone rules parity is still unfinished; see `game/godot/PARITY.md`.


## Godot Foundations collection (2026-09-20)

**Superseding playtest update:** Adam requested 30 health, 2-mana powers, 10 max mana and 30-card decks. `game/godot/constructed.gd` now persists a custom thirty-card deck separately; all 100 cards are available for prototype testing, with two ordinary/one Legendary copy limits. Both practice and island matches use this deck and begin at 30 health each. Legacy earned ownership remains; its five-card deck field no longer drives combat. AI now uses the same class power as the player. Collection Play, result Play again, and F8/Report bug support iteration. Diagnostics stay local under `user://playtest-reports/`. See `game/godot/PARITY.md`. Tests: 25 constructed, 472 collection, 328 core, 14 updated journey, 15 drag and 18 design checks passed. Existing practice sessions do not set adventure battle_pending; do not use that flag alone to assume a running game is between matches.

Read `game/docs/ROADMAP.md` for the current built/partial/planned map grounded in the Sept19–20 brainstorm. Native Godot now loads 100 cards from `game/godot/data/cards.json`: 25 per Air/Water/Fire/Earth, 60 minions/40 spells, 0–10 mana and four rarities. `collection.gd` provides searchable/filterable/paginated catalog, inspection, owned five-card swaps and borrowed 30-card elemental practice. Practice is in-memory and cannot grant rewards or change adventure health. Original save schema/ownership rules remain; most new cards have no adventure acquisition source yet. 91 new cards reuse original art as explicit prototypes. `game/docs/FOUNDATIONS_CARDS.md` lists the set; author additions in `game/scripts/build-foundations.py`. New battle effects include draw, empty-crystal ramp, board healing, summons, area damage and board/element buffs. 472 collection checks, 328 core checks, 15 drag checks, 12 reward journey checks and 18 layout checks passed; not human fun/balance validation. Do not conflate catalog count with encounters, acquisition routes, unique art, full Hearthstone parity or multiplayer.
