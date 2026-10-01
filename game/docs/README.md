> **September 20 collection update:** [Current roadmap](ROADMAP.md) and [100-card Foundations index](FOUNDATIONS_CARDS.md). Godot now has the searchable catalog and isolated elemental practice; adventure acquisition still covers only the starter cards and Crab reward. Earlier inventories below are historical.

> **September 20 collection update:** [Current roadmap](ROADMAP.md) and [100-card Foundations index](FOUNDATIONS_CARDS.md). Godot now has the searchable catalog and isolated elemental practice; adventure acquisition still covers only the starter cards and Crab reward. Earlier inventories below are historical.

# eyeland.cards â€” design context

**Latest decision (2026-09-20): Adam has explicitly chosen Godot for the MVP. Read [GODOT_MVP_HANDOFF.md](GODOT_MVP_HANDOFF.md) first.** Web-engine preservation below describes the earlier implementation pass; the web prototype is now reference material for the Godot build.

Captured 2026-09-20 from the complete available **Brainstorm Island Cards** conversation (2026-09-19â€“20, conversation `6aae9db1-ace8-83ec-8f2b-4e4a48e32282`) and Adam's desktop takeover request. All pages were read back to the opening spelling correction. These documents preserve the game discussion, not unrelated personal context.

## How to read this set

**Direction** means Adam explicitly requested or reaffirmed it; it does not mean implemented. **Hypothesis** means a tentative idea, example, or assistant suggestion. **Slice choice** means a reversible implementation decision for testing. **Open** means unresolved. Code and [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) establish what runs; this design set establishes intent. Older research remains valuable but its dated implementation inventories are historical.

Start with [GAME_VISION.md](GAME_VISION.md), [CORE_LOOP.md](CORE_LOOP.md), and [V1_SCOPE.md](V1_SCOPE.md). Systems: [COMBAT_SYSTEM.md](COMBAT_SYSTEM.md), [PROGRESSION.md](PROGRESSION.md), [WORLD_AND_STORY.md](WORLD_AND_STORY.md), [ISLANDS.md](ISLANDS.md), [CLASSES_ELEMENTS_AND_ROLES.md](CLASSES_ELEMENTS_AND_ROLES.md), [CARDS_AND_COLLECTION.md](CARDS_AND_COLLECTION.md), [COOP_AND_PVP.md](COOP_AND_PVP.md), [ECONOMY_CRAFTING_AND_TRADING.md](ECONOMY_CRAFTING_AND_TRADING.md), [EXPLORATION_MOUNTS_GEAR.md](EXPLORATION_MOUNTS_GEAR.md), [SOCIAL_SYSTEMS.md](SOCIAL_SYSTEMS.md). Unresolved decisions live in [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md).

## Reconciliation with the repository

- The current playable client is React + TypeScript + Vite in `game/web`, scaffolded from Phaser. Unity/C# remains reference code. The conversation's Unity/Godot recommendations were exploratory, not an instruction to discard working code.
- Existing Ember Reach has a 12-card expedition; practice has 30-card constructed decks. The five-card home-island slice is a separate entry point, not a migration of saved expeditions.
- Existing elements include Storm; the new world direction has Fire/Water/Earth/Air. Preserve Storm compatibility; do not silently relabel saved content.
- Existing classes include Fighter and twelve others. The starter display name Warrior maps to Fighter internally. The three starting choices do not delete later-class content.
- Earlier procedural-island ideas and the new authored five-island story need reconciliation before world generation. This slice uses an authored map.
- Creature victory rewards already exist. Separate capture actions, probabilistic boss extras, recipes, marketplace ownership and mastery remain different systems.

## Conversation evolution that matters

Adam corrected the initial interpretation: islands are world/expansion destinations, not cards that create biomes. The early idea that creatures supply separate move cards was superseded by creatures **being** minion cards. The deck discussion explicitly settled on five cards to start after considering ten. The five-island/50-level V1 idea was later narrowed toward a possible first-island episodic release. The assistant's suggested two-player V1, 30â€“50 cards, human-only races, simultaneous initiative, specific rank names, and monarch rescue were never finalized. Keep those as proposals, not promises.

Research continuity: `../DESIGN.md`, `../EYELAND-IDENTITY.md`, `../ELAN-LEE-LESSONS.md`, and `../GDC-LESSONS.md`. Ben Brode, Elan Lee and JelloApocalypse's PokÃ©mon design exercise are design-process inspirations; this handoff does not claim new external research or human playtest results.

Current playable target: [Godot MVP](PLAY_GODOT_MVP.md). Godot verification and limitations are recorded in [the project README](../godot/README.md). Earlier web-client status above is historical.

