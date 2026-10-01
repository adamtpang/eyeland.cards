# eyeland.cards

An open-world **card-combat MMORPG**: the spell-duels of Wizard101, the deckbuilding of Hearthstone, and the open world of Pokémon, set across a floating archipelago called **the Eyeland**. Built in Unity with Claude.

This repo currently hosts:

- the **pre-launch landing page** (`index.html`): a static page deployed at [eyeland.cards](https://eyeland.cards)
- [`hearthstone/`](hearthstone/): a competitive **Rafaamlock (Timethief Rafaam Warlock)** deckbuilding workspace: oracle-verified card data, versioned decklists with deck codes, a collection-aware dust budget, and a ladder log that drives iteration. It's deliberate practice for the game's card-duel core: archetype shapes, curve theory, and card economy studied on the live Hearthstone ladder. (Only the landing page deploys; see `.vercelignore`.)

## Status
- [x] Landing page v1
- [x] Card-duel core: portable turn engine, console harness, AI, and balance simulator
- [x] Deckbuilding: 70-card Unity UI with a tested deckbuilder-to-duel flow
- [ ] Overworld + wild encounters
- [ ] Online layer

## Build ladder
`v0 Duel → v1 Deck → v2 Island → v3 World → v4 Online`: build the game first, add the MMO layer last.

## Landing page
`index.html` and its local assets form a static site. Open it directly in a browser, or deploy the repo root to any static host.

## 2026-09-11: Ember Reach local playable prototype

The default Unity boot now opens a connected solo expedition: three camps and a Warden, timed real-engine duels, defeated-creature card rewards, ember shards, owned 12-card deck editing and browser-local saves. Common/Rare/Epic/Legendary are represented. The route is an encounter menu with seeded supporting cards and shuffles; a walkable 3D island, crafting recipes and multiplayer are still not implemented.

Play instructions: game/PLAY-EMBER-REACH.md. Local URL: http://127.0.0.1:8765/ while the server runs; restart with game/scripts/play-ember-reach.ps1. Build with game/scripts/build-ember-reach.ps1. Unity 6000.5.7f1 plus WebGL was restored under Adam's AppData/Local/EyelandTools; see game/LOCAL-UNITY-RUNTIME.md. Production was not deployed.

MVP-READINESS.md records 100/100 for the fixed local technical scope: final 10/10 Unity tests, a four-encounter UI-handler journey, 400 terminating engine simulations, and native Helium first victory -> reward -> deck edit -> reload -> earned card in next duel. The full four-fight journey was not played through native browser input. Human enjoyment and session length remain unvalidated. MVP-NEXT-PROMPT.md starts with Adam's unaided playtest; preserve prior research and unrelated working-tree changes.
