> **September 20 collection update:** [Current roadmap](ROADMAP.md) and [100-card Foundations index](FOUNDATIONS_CARDS.md). Godot now has the searchable catalog and isolated elemental practice; adventure acquisition still covers only the starter cards and Crab reward. Earlier inventories below are historical.

# Godot MVP handoff — Adam's confirmed direction, 2026-09-20

## Latest instruction takes precedence

Adam explicitly corrected the web continuation: “yeah lets build the mvp game in godot,” and asked to transfer the documents, prompt and complete relevant brainstorm context to his existing **🐉 eyeland.cards** Codex task. Godot is now the chosen MVP engine. Earlier notes saying to retain React/TypeScript as the target are historical and superseded. Preserve that prototype as a reference; do not continue web development as the primary deliverable or reopen the engine decision without a concrete blocker.

Receiving task: `01a07a68-c70e-7dc3-ad79-36883192f4cd`.
Repository: `C:/Users/adamp/Aether/eyeland.cards`.
Source handoff task: `01a0be5c-8536-7bc1-9fc4-70858b2e2d54`.
Brainstorm: **Brainstorm Island Cards**, `6aae9db1-ace8-83ec-8f2b-4e4a48e32282`, September 19–20. All 105 available turns were read during the original handoff, back to the spelling correction. Use read_thread with this conversation ID and pagination for any details needed; do not ask Adam to repeat the discussion.

## Read before implementation

Read root AGENTS.md/CLAUDE.md and applicable nested instructions, inspect current Git/local state, and read `C:/Users/adamp/Aether/themain.quest/MOBILE_DESKTOP_BRIDGE.md`. There are extensive unrelated modified/untracked files, including the web client. Preserve them. Work in the existing repository; no duplicate project.

Read every Markdown file in `game/docs/`. The full design set already lives in this repo and needs no upload/import:

- README.md: provenance, confidence labels and reconciliation.
- GAME_VISION.md, CORE_LOOP.md, COMBAT_SYSTEM.md, PROGRESSION.md.
- WORLD_AND_STORY.md, ISLANDS.md, CLASSES_ELEMENTS_AND_ROLES.md.
- CARDS_AND_COLLECTION.md, COOP_AND_PVP.md, ECONOMY_CRAFTING_AND_TRADING.md.
- EXPLORATION_MOUNTS_GEAR.md, SOCIAL_SYSTEMS.md, V1_SCOPE.md, OPEN_QUESTIONS.md.
- IMPLEMENTATION_STATUS.md and PLAY_STARTER_ISLAND.md: existing web slice and exact test limits.

Also retain the useful prior research in game/DESIGN.md, EYELAND-IDENTITY.md, ELAN-LEE-LESSONS.md and GDC-LESSONS.md. These do not override the now-confirmed Godot decision.

## Game direction, condensed

Spell **eyeland.cards** exactly. Hearthstone-style minion/spell battles; Pokémon collection, starter attachment and evolution; Wizard101 quests/worlds/small-party co-op; Minecraft materials/recipes; FIFA tradable/untradable market and SBC-style card sacrifices; Breath of the Wild exploration/growth/recovery; Cradle ranks, immense world scale and power gap; Avatar's Fire/Water/Earth/Air clarity plus mythic elemental beings/monarch domains; One Piece islands/factions/bounties; Overwatch tank/support/damage synergy.

Cards are literal vessels capturing minions and spells. Creatures are cards, not a separate Pokémon move system. Start with a Legendary companion and four other cards; deck growth roughly 5→10→15→20→25→30. Common/Rare/Epic/Legendary; ordinarily two copies and one of each Legendary. Starter evolution example: 3/6/9 mana forms, trigger undecided. Character mastery permits reliable higher-rarity use; above-mastery fizzle is intended, with 50% Rare success only an example. The starter Legendary exemption remains unresolved.

Initially Warrior/Ranger/Wizard with four elements; class, element, starter and role are separate axes. Around 30 player HP. AI party helpers around 10 HP and ten-card mini-decks, replaced by human friends in a 1–4 player concept; revive/heal/substitution desired. Turn order and boss HP/action scaling are unresolved. Do not mistake these goals for functioning multiplayer.

Player market, gold packs, boss RNG extras, recipe NPCs and sacrificing owned cards/resources are desired. Weapons/armor feed card combat; mounts open land/sea/sky/underwater/underground travel. Campfires/inns recover health. Text, party voice, friends and tavern PvP support relationships.

The weak cozy home island has family/friends and a valuable resource. Powerful pirates invade, reveal an enormous power gap and create the reason to leave, grow and protect home. Tease monarchs/domains/factions early. Five islands/50 levels is the first arc concept, new islands roughly every ten levels; the later idea is shipping only the first island episodically. Do not build all five before a playable MVP. Exact story names, resource, invasion staging and later island identities are open. The assistant's proposed human-only race scope, monarch rescue, simultaneous initiative and two-player V1 were not settled decisions.

## What exists to reuse

`game/web/src/engine/` has a working TypeScript engine, loader, AI, RNG, island and constructed-deck rules. `game/data/cards.json` has shared content; `game/web/src/data/parity-cards.json` adds web mechanics. Unity/C# implementations remain as references in game/src and game/unity. Reuse data/concepts and test cases where practical, not incompatible engine infrastructure.

The just-built `game/web/src/starter/` has a small grid overworld, class/element registries, five-card decks, four Legendary placeholder variants, one Resin Crab encounter, family/friend/crop/camp/dock interactions, one-time victory reward and recovery. All starter variants share one ability deliberately. Health carries across battles; retreat returns at 1 HP; camp restores 30. Story progress is session-only, and its earned Crab cannot yet be put in the deck. Those are known MVP gaps, not desired final behavior.

Legacy Ember Reach retains four fights, a 12-card editor, rewards and local saves; practice has 30-card decks. Existing `fighter` corresponds to starter Warrior; Storm remains legacy content alongside new Earth/Air. Do not silently migrate existing saves or delete classes/content.

Previous checks: 81 engine checks (including 1,000 baseline and 400 constructed simulations), 300 starter simulations, typecheck/build all passed. Helium verified native map navigation/card play and an automated real-engine completion, reward, injury, retreat/rest, and legacy pool isolation. Not a full unaided human playtest. Evidence under game/evidence/starter-2026-09-20. These checks do not certify a Godot port.

## Execute now: a playable Godot MVP

Inspect for existing Godot project/runtime/tooling first; continue it if present. Otherwise add a Godot project inside this repository (for example game/godot), retaining the web/Unity reference builds. Use the installed compatible Godot version, document it, and prefer GDScript for a new project unless local evidence strongly favors an existing implementation. Use AI-assisted implementation and available Godot tools; do not block on an optional connector if the editor/CLI is sufficient.

Build and verify a coherent local vertical slice: start/class/element selection; readable starter island and movement/collisions; home/quest/encounter entry; real Hearthstone-like hand/mana/minion/spell turns against one enemy; five-card starting deck with Legendary; visible outcomes, owned-card/resource reward and camp recovery. Make cards/classes/elements data-driven and assets replaceable. Add the smallest collection/deck-change and local save/load loop needed to make the earned card useful and progress survive restart, with safe versioned validation and no overwrite of the older client's saves. Make provisional story/balance choices explicit. The existing prototype is reference behavior, not a requirement to port every advanced mechanic before the slice works.

Use focused checks for turn legality, outcome/reward idempotency, deck ownership/size, persistence and scene integration; run Godot headless import/parse/tests where supported and a real local play-through. Fix failures, document launch instructions and remaining limitations, and leave a reviewable playable build/project. Do not report success from file creation alone. No need to ask Adam to repeat preferences or approve ordinary reversible local work.

Keep networking, market, voice/chat, full crafting economy, mounts, full rank/fizzle/evolution ladder and five-island campaign as documented later systems. A first-island MVP must be small enough to test the actual adventure→battle→collection→deck improvement loop. Preserve all design ambition without pretending it is implemented.

Do not publish, deploy, purchase, delete user data, send messages as Adam or make external commitments. Browser work uses Helium, not Chrome. Finish in this receiving task with what runs, how Adam can play, tests performed and honest remaining gaps.
