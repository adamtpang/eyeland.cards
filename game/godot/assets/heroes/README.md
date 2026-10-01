# Hero and hero-power artwork

Generated September 20, 2026 with the built-in image_gen tool. Six original full-bleed square illustrations, stored locally and consumed by native Godot UI. Exact prompts: [PROMPTS.json](PROMPTS.json).

| Class | Hero portrait | Power artwork |
|---|---|---|
| Warrior | warrior.png | brace.png: protective shield |
| Ranger | ranger.png | true-shot.png: luminous arrow and bow |
| Wizard | wizard.png | spark.png: hand casting blue-violet magic |

Hero identity follows class, independently of starter creature and element. These are preset class portraits, not player-customized avatars. The enemy Resin Crab continues using its original illustrated portrait. No enemy hero power was invented for this encounter.

`hero_art_button.gd` renders framed portraits and round power art, mana cost, availability glow, used/disabled state and an enlarged hover preview. `duel_board.gd` retains existing power and enemy target/drop handlers. No battle rules or saved profile format changed.

Validation: 11 rendered checks cover all three classes, power activation/targeting, correct mana and effect, used-state disabling, and 1024x720 fit. Evidence: `game/evidence/godot-hero-art-2026-09-20/`. The actual player session was not restarted because a battle was active.
