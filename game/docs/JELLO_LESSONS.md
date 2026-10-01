# JelloApocalypse: lessons for Eyeland

Source: the complete user-supplied [Let's Make a Pokemon Game! transcript](../research/jello-pokemon-pitch-transcript.md), from [JelloApocalypse's video](https://www.youtube.com/watch?v=tGhpDOx0CMk). Read in full on September 20, 2026. The pasted transcript has no timestamps; the topic anchors below identify sections without inventing timestamps. These are design arguments, not measured evidence that a feature is fun.

## Thesis

Jello centers collecting favorites, having a personal journey, and befriending creatures. Eyeland's adaptation is: explore with a companion, defeat a creature, earn its card and resources, deliberately improve your deck, and discover somewhere new. Third-person movement should serve that journey rather than merely connect menus.

| Transcript topic | Eyeland adaptation | Current state |
|---|---|---|
| Short introduction followed by open routes; avoid arbitrary roadblocks | Let players move around home immediately and see destinations before committing to a fight | Free 3D movement, camera orbit/zoom, visible landmarks implemented; only one encounter |
| Collect favorites and develop attachment | Keep the chosen starter physically present during exploration | Following elemental companion implemented as a simple placeholder model; bonding/evolution not implemented |
| Wider camera shows more of the world | Behind-character camera with player-controlled zoom and orbit | Implemented; collision-aware spring arm |
| Optional routes and activities | Small jumping route beside the main paths | Physical stepping stones implemented; no reward or quest attached |
| Research quests and a home that changes with accomplishments | Helping the garden should change its appearance | Flowers appear after the first Crab victory; larger settlement progression is planned |
| Diverse environments and creatures early | Introduce meaningfully different encounter packages on nearby routes | Planned; the current island has one fight, not a varied region |
| Regional danger and safe escape | Show encounter health; allow retreat and recovery at camp | 12-HP encounter label, retreat and camp healing implemented; danger tiers/fast travel planned |
| Gym teams built around strategies, not only types | Design creature encounters around card synergies: armor, tokens, deathrattles, ramp | Planned; no extra encounters were invented for this pass |
| Optional quest solutions and multiple paths | Let exploration, crafting, and combat support different approaches | Planned; crafting and alternative quest completion are absent |
| Affection should not trivialize battles; special power should be earned | Separate cosmetic companionship from combat power; reward new deck options through victories | Companion has no passive battle bonus; first-victory card reward remains implemented |
| Avoid grinding objectively superior copies through IVs | Favor interesting sidegrades and coherent card packages over random stat rolls | Design direction; no randomized card stat system introduced |
| Battle Simulator for immediate experimentation | Eventually offer a separate practice collection with unrestricted deckbuilding | Planned for Godot; do not confuse the older web practice mode with this client |
| Skippable tutorials and challenge options | Keep instructions accessible on demand; offer harder encounters later | How-to guide exists; difficulty selector and richer challenge progression remain planned |

## Preserve Adam's design

The video's proposals to remove most Legendaries, change Pokemon moves, or divide a game into versions are not Eyeland requirements. Keep Adam's Legendary starter, Common/Rare/Epic/Legendary collection direction, card combat, creature-card rewards, crafting ambition, RPG progression, and eventual cooperative questing. Multiplayer remains a later implementation, not something this local scene supplies.

## Next human playtest

1. Without guidance, can Adam identify the avatar, move, orbit, sprint, jump, and find the garden?
2. After the Crab fight, does he recognize the reward as the same creature and intentionally equip it?
3. Does the next battle make that deck change feel useful?
4. Do the companion and changed garden make the victory feel personal?

Record observations before expanding the island. Automated collision and save tests establish correctness, not enjoyment.
