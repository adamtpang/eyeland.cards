# Hearthstone battle parity checklist (web client)

Each item is done only when the engine implements it, a self-test covers it, and the
duel UI exposes it. New mechanics live in `src/data/parity-cards.json` so the shared
`game/data/cards.json` (also read by the C# and Unity builds) keeps loading there.

## Core rules
- [x] Hand limit 10: overdrawn cards burn
- [x] Board limit 7 also blocks playing a creature
- [x] Opening hands: first player 3 cards, second player 4 plus The Coin
- [x] Mulligan: choose cards to replace before turn 1
- [x] Fatigue: drawing from an empty deck deals 1, 2, 3...
- [x] Armor absorbs damage before health
- [x] Constructed rules for free duels: 30-card decks, 2 copies max, 1 per legendary

## Card types and keywords
- [x] Creatures, spells, Battlecry, Deathrattle, Taunt, Rush, Charge, Divine Shield,
      Lifesteal, Windfury, Poisonous, Stealth, Freeze, Spell Damage, auras
- [x] Weapons and hero attacks (durability, the hero takes damage back)
- [x] Secrets (hidden until triggered by the opponent)
- [x] Discover (pick 1 of 3)
- [x] Choose One
- [x] Combo (another card played earlier this turn)
- [x] Silence
- [x] Overload

## Presentation
- [x] Hearthstone-style card frames, art, minion tokens, heroes, mana crystals
- [x] Turn timer with rope
- [x] Opponent hand shown as card backs
- [x] Attack animation and floating damage numbers
- [x] Emotes

## Status (2026-09-18)

Every item above is implemented, covered by `npm test` (81 checks, including 400
constructed AI-vs-AI games with every rule on) and exposed in the duel UI. Browser
checks in the dev preview: mulligan screen, The Coin, Choose One (Grove's Gift to
face for 3), Armor gem, weapon equip plus hero attack with the lunge, a hidden
Secret, Overload locking a crystal next turn, emotes with an AI reply, opponent
draws hidden in the log, and three complete practice games with no page errors.

Where this is still smaller than Hearthstone, on purpose:
- Secrets trigger on three events (enemy attacks, plays a creature, casts a spell).
- The card pool is 93 cards; Discover draws from your class plus neutral.
- Island expeditions keep their 12-card decks by design. Constructed rules apply to
  the Practice duel button on the island screen.
- No sound yet.
