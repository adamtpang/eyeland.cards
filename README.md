# eyeland.cards

An open-world **card-combat MMORPG** — the spell-duels of Wizard101, the deckbuilding of Hearthstone, and the open world of Pokémon, set across a floating archipelago called **the Eyeland**. Built in Unity with Claude.

This repo currently hosts:

- the **pre-launch landing page** (`index.html`) — a self-contained static page deployed to Vercel ([eyelandcards.vercel.app](https://eyelandcards.vercel.app))
- [`hearthstone/`](hearthstone/) — a competitive **Rafaamlock (Timethief Rafaam Warlock)** deckbuilding workspace: oracle-verified card data, versioned decklists with deck codes, a collection-aware dust budget, and a ladder log that drives iteration. It's deliberate practice for the game's card-duel core — archetype shapes, curve theory, and card economy studied on the live Hearthstone ladder. (Only the landing page deploys; see `.vercelignore`.)

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
