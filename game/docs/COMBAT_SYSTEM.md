# Combat system

## Direction

Hearthstone-style combat is the core: minions remain on a board, spells resolve effects, costs constrain plays, and a deck produces a hand. Preserve familiar turn-based tactical play while exploration supplies the cards. Player baseline is about **30 HP**. Rarities are Common, Rare, Epic and Legendary; deck duplicates are at most two ordinary copies and one of a given Legendary.

The repository already supports mana growth, draw/fatigue, opening hands/mulligan, The Coin, seven minions, ten-card hands, attacks/targeting, Taunt/Rush and other keywords, hero powers, weapons, armor, Secrets, Discover, Choose One, Combo, Silence and Overload. Reuse this implementation. Its parity checklist is a local feature list, not a claim of complete equivalence to every Hearthstone rule.

## Mastery and fizzle direction

Adam explicitly preferred a success/failure roll when playing above the character's mastery rank, rather than only higher mana cost. A common-mastered character using a Rare with **50% success** was an example, not a final probability table. Show actual odds before commitment. Mastery should eventually make the matching tier reliable.

Open: cost/card consumption on failure, consolation effects, rank-to-rarity mapping, PvP treatment, RNG reproducibility and the starter Legendary exception. A gifted Legendary and low starting mastery conflict unless a bond exemption, dormant form or separate mastery tag is designed. The slice deliberately uses deterministic ordinary combat and labels evolution/mastery as future systems.

## Team combat hypothesis

Tank: protect, Taunt, shield, redirect. Support: heal, buff, draw or resource help. Damage: pressure, burst and combinations. Cross-element setups such as Water → Fire steam are examples, not implemented reactions. Party participants are distinct from summoned minions.

Simultaneous planning with initiative resolution, rotating turns, and shared round windows were competing suggestions. None is locked. Do not rebuild the two-caster engine into multiplayer until a paper/local party test picks a model. See [COOP_AND_PVP.md](COOP_AND_PVP.md).

## Slice choices

Use the existing duel with a five-card tutorial loadout and one weak opponent. Retain draw/fatigue and the current 75-second turn clock for now. Small decks exhaust quickly; measure whether fatigue distracts from learning before choosing recycling or a different opening hand. Defeat/retreat gives no reward and returns to the island; no inventory is destroyed.
