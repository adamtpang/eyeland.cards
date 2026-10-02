# Eyeland roadmap

**Latest playtest decision:** Adam requested Hearthstone-style 30-card decks immediately, superseding the five-card active-match plan. Godot now saves a custom 30-card deck; all 100 cards are available for testing; both sides start at 30 health, powers cost 2 and mana caps at 10. Island fights also use these rules. Earned inventory is preserved separately. See [current parity and play instructions](../godot/PARITY.md). Deck-size progression described below is historical brainstorm direction, no longer the active implementation target.

Updated September 20, 2026. **Current engine: Godot. Current product: a local solo prototype, not a finished island or MMO.** This reconciles the September 19–20 **Brainstorm Island Cards** conversation (`6aae9db1-ace8-83ec-8f2b-4e4a48e32282`), the saved design documents, Adam's subsequent requests, and the native code. The brainstorm's user messages were revisited through its opening turn for this update. Earlier Unity/web checklists are historical reference, not Godot completion evidence.

## The game we are building

Explore a world → battle creatures → earn their cards and resources → improve your deck → reach more dangerous places → protect the people back home. Hearthstone supplies the battle language; Pokémon supplies collection and companion attachment; Wizard101 supplies questing and the eventual small-party adventure. Cards capture both creatures and spells.

Last night's strongest direction was a weak, beloved home island with family, friends and a valuable resource. An overwhelmingly powerful pirate threat gives the player a reason to leave and grow. Islands are chapters with new creatures, cards, bosses and stories. The longer first-arc concept is five islands and roughly 50 levels; the later idea of releasing the first island as one satisfying chapter keeps that ambition shippable.

## What is built now

| Area | Working in native Godot | Boundary |
|---|---|---|
| Exploration | Visible third-person character, walking, running, jumping, collisions, companion, follow camera, manual orbit and zoom | Small prototype home island; not a complete region |
| Identity | Warrior, Ranger, Wizard; Air, Water, Fire, Earth; Legendary starter choice | Starters share a simple ability; no evolution or separate class questlines |
| Combat | Mana, minions, spells, Taunt, armor, healing, fatigue, AI, hero powers, mulligan, Coin, hand/board limits, timed turns | Full Hearthstone rules parity remains incomplete |
| Battle presentation | Portraits and power art, two minion rows, drag/drop, placement, targeting, attack/damage feedback, gray unavailable hand cards, hover inspection | Sound, animation polish and several battle affordances remain |
| Collection | **100 definitions: 25 per element, 60 minions, 40 spells, 0–10 mana, four rarities**; search, filters, pages and inspection | Prototype tuning. 91 new definitions share existing illustrations |
| Decks and practice | Saved five-card owned adventure deck; protected companion; four borrowed 30-card elemental practice decks; selected card can start in practice opening hand | No custom 30-card deck editor or adventure deck-size progression yet |
| Card interactions | Targeted damage, armor, hero/board healing, draw, empty-crystal ramp, summoning, enemy/all-board damage, board-wide and matching-element buffs | No unsupported card text is advertised as a working keyword |
| Rewards and persistence | First Crab victory awards its card plus 2 resin; equip it, reload, and use it; camp restores health; local saves | Only this encounter awards cards. Catalog entries are not automatically owned |

**The current adventure contains one repeatable encounter.** The larger catalog is playable in practice; it is not evidence that 100 creatures, acquisition routes, quests or unique illustrations exist. Practice neither spends nor grants adventure resources and does not alter adventure health or ownership.

## What is next, in order

These are proposed production milestones, not promised dates. Each should end with a playable build and a human test.

### 1. Make the first collection loop worth repeating

- Playtest the four elemental practice decks and identify interesting packages. Tune costs/stats from observed games, not AI win rates alone.
- Give the four starter companions distinct roles while preserving attachment.
- Add a small set of different wild encounters that award their actual cards; show where an unowned card can be obtained once that route exists.
- Replace the current fixed starter/reward ownership validator with a migrated acquisition ledger before adding new reward sources. Preserve old saves and prevent duplicate first-clear grants.
- Replace shared study art with unique creature/spell illustrations in batches.

**Exit test:** Adam deliberately wins a desired card, equips it, and uses a new tactic in the next fight. The reward, source and save survive restarting.

### 2. Complete the first island episode

- Author family/friend relationships, a short quest chain, multiple encounters and one meaningful boss.
- Introduce a visible pirate threat and a concrete reason to leave; finish with a departure hook.
- Add quest flags, encounter state, readable objectives and persistent world changes.
- Refine traversal, environment art, encounters, feedback and audio based on actual play.

**Exit test:** an unaided player can finish an enjoyable beginning–crisis–payoff story and explain why they want the next island. No completion/fun claim based only on automation.

### 3. Add growth and crafting that support that story

- Deck capacity grows from **5 → 10 → 15 → 20 → 25 → 30**, with exact thresholds still to decide.
- XP and recognizable ranks; starter evolution, using the brainstorm's **3/6/9-mana** stages as an example rather than a locked formula.
- Recipe NPC, known recipes, card/resource ingredients, atomic consumption and saved outputs. Protect starter cards and equipped-deck legality.
- Decide mastery/fizzle explicitly, including the Legendary starter exception and whether failed casts spend a card/mana.

**Exit test:** one earned progression milestone changes a real deck choice; one craft consumes exactly the shown ingredients once and remains correct after reload.

### 4. Prove a small cooperative battle, then network it

- First test two allies versus a boss locally. Decide separate/shared boards, turn order, support targets and boss scaling before networking.
- Prototype AI helpers with mini-decks and human replacement of their slots; revive/substitution rules remain open.
- Then add authoritative game state, join/leave/reconnect behavior, individual rewards and quest ownership.

**Exit test:** two actual players complete a quest together, each makes meaningful decisions, and disconnect/rejoin cannot corrupt turns or rewards. Current status: none of this is implemented.

### 5. Expand the archipelago and social world

- More themed islands, bosses, elemental domains and monarchs; faction and bounty consequences.
- Additional classes, mounts/traversal, gear and party companions when the core loop supports them.
- Tavern PvP, friends, text chat and optional party voice, with player controls and moderation.
- In-game gold, island packs, tradable/bound provenance and a player market after a trustworthy inventory/economy exists.

**Exit test:** each new island contributes a memorable story and deckbuilding decision; old cards still matter. Five islands/~50 levels is the first-arc direction, not a requirement to delay the first playable release.

## Decisions still open

- Evolution trigger and whether forms replace or coexist; starter rarity versus mastery/fizzle.
- Exact XP, rank and deck-size thresholds; how five-card fatigue feels.
- Guaranteed victory cards versus an additional capture action, repeat rewards and bonus boss RNG.
- Multiplayer board/turn model and scaling; PvP normalization.
- Recipe costs, gold/pack economy, trade binding and market rules.
- Final home/island names, pirate motive and departure event.

Class/element selection, a UI button, a rarity gem or a written design document does not resolve these systems.

## Evidence and references

- [Foundations card index](FOUNDATIONS_CARDS.md), [native data](../godot/data/cards.json), [collection and combat tests](../godot/tests/collection.gd).
- [Native parity checklist](../godot/PARITY.md), [implementation history](IMPLEMENTATION_STATUS.md), [play instructions](PLAY_GODOT_MVP.md).
- [Brainstorm design index](README.md), [cards](CARDS_AND_COLLECTION.md), [progression](PROGRESSION.md), [story](WORLD_AND_STORY.md), [co-op](COOP_AND_PVP.md), [economy](ECONOMY_CRAFTING_AND_TRADING.md).
- Verification for this collection update: 472 collection/content/effect/practice checks, including 40 terminating element-match simulations; existing 328 core checks, 15 battle-structure checks and 12 reward/reload journey checks pass. These are automated checks, not balance or enjoyment evidence. Collection screenshots are in `game/evidence/godot-collection-2026-09-20/`.

No online deployment or standalone distribution build was produced by this update. Launch the local game with `Play Eyeland.cmd`.

## September 24: Three.js browser comparison
Adam approved a browser island prototype after reviewing Tidewater. `game/web` now starts in `src/world/WorldIsland.tsx`: third-person Three.js/WebGL2 island, click/WASD movement, run/jump, follow/orbit camera, companion, one Wolf encounter using the older TypeScript duel, and saved first-clear card/shard reward plus equip. See `game/web/THREE-ISLAND.md` for evidence and limitations. Godot remains the more complete battle/art reference; no full engine replacement or Godot parity port is claimed. Local dev URL is http://127.0.0.1:8080/ while running. No production deployment.

## Parked: generated overworld (Tencent WorldClaw), reviewed 2026-09-29
WorldClaw (Tencent Hunyuan, Aug 2026) turns one prompt into an editable 3D open world: Claude plans regions, a height-field terrain is built, GPT-Image-2 lays out regions, and SAM3D/Hunyuan3D generate separate textured meshes assembled in Blender (real geometry, game-engine ready, not video or splats). Status: paper and project page only, no code, weights or demo; experiments used 4x NVIDIA H20 GPUs. Sources: [project page](https://tencent-hunyuan.github.io/Hunyuan3D-WorldClaw/), [paper](https://huggingface.co/papers/2608.05248).

- **Why parked:** it makes the island prettier, not proven fun. The recorded next gate is still Adam's unaided playtest, and nothing yet shows the overworld's art is the bottleneck.
- **A "WorldClaw-lite" is reproducible without Tencent's code:** Claude writes a region plan, a script builds terrain (Godot `world_3d.gd` already does this in code), an image-to-3D model generates assets, glTF export into Godot or the Three.js island. Blender 4.4 is installed; asset generation needs a large GPU or a paid hosted service.
- **Cheapest first test (after the playtest):** one afternoon, one Ember Reach region plan plus one generated landmark dropped into the island, to check it fits the storybook art direction before building any pipeline.
- **Revisit if** Tencent releases code/weights, or the playtest shows the world feels empty.

## Lesson: iterate on feel first (Thariq's AI-built game thread, reviewed 2026-10-01)
Source: [Thariq (@trq212), 2026-09-30](https://x.com/trq212/status/2105333496768319969), a former games founder who works on Claude Code. Only the thread text was read; the four videos were not watched, so nothing here judges how his game looks.

What he does: a real-time brawler prototype (Brawl Stars, Avatar, Street Fighter). He has not decided 1v1 or 3v3 and iterates on characters first. The thing he iterates on most is feel ("Do they feel satisfying and powerful?"). He started with one character, tried 2 to 3 control variations for a single jump, calls it prototype quality, and expects 3 to 4 versions of that character before a real game. His rule: the creative process is the satisfying part, so do not outsource it to AI; use AI to bring your own vision to life.

What it means for Eyeland:
- **We went wide before proving one thing feels great:** 100 cards, three clients (Unity, web, Godot) and hundreds of automated checks, with no human playtest. Automated checks cannot tell whether a battle is satisfying.
- **Decide by playing variations, not by writing documents.** Open design questions get settled by 2 to 3 playable versions, picked by feel.
- **Adam's taste is the game.** Decisions about what feels fun come from him playing, not from the agent building.

Working rule until one fight feels satisfying to Adam:
1. Pick one battle moment (play a creature, attack, the hit landing) and polish its animation, timing, sound and impact. The web client has no sound yet.
2. Build 2 to 3 variations of that moment; Adam plays each for a minute and picks.
3. No new cards or systems until then.

This is the same gate as the unaided playtest: play it, name the one thing that feels worst, iterate on that.

## October 1: Home Island loop, small starter fights (Adam's playtest direction)

Adam's notes: starter fights were too hard, slow and complex; "as simple as Pokemon"; and there was no objective. Built in Godot:

- **Objective:** clear three camps, then defeat the Hearth Warden. Shown in the island HUD with a goal plate and a golden marker.
- **Ladder:** Resin Crab (5 health), Mossback Cub (8), Reef Otter (9), Hearth Warden (14). You have 10 health and a 10-card deck. No opening-hand choice, you go first, and wild creatures have no class power.
- **Rewards:** each first win awards that creature's card (two copies, one for the Warden) plus resin. Rematches award nothing. Losing costs nothing.
- **Deck:** a 10-card adventure deck edited on its own Deck screen from the cards you have earned. Practice keeps the 30-card deck with all 100 cards.
- **Balance evidence:** `tests/adventure_sim.gd` plays both sides with the same AI, 300 games each. The player side wins 100% against the Crab and about 80% against the other three. This is not human evidence.
- **Supersedes** the September 20 "island fights use 30 health and the 30-card deck" decision for the adventure only.

Not built: growth of health or deck size, a use for resin, unique models (the Cub uses the Mushnub model, the Otter the Fish, the Warden a large Dragon), and anything after the Warden beyond the dock line.
