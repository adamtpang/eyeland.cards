# Economy, crafting and trading

## Direction

Gather resources, earn creature cards, pursue powerful boss RNG drops and craft desired cards. Minecraft inspires material recipes; FIFA inspires tradable/untradable inventory and SBC-like submission of other collected cards. Recipe NPCs teach or sell knowledge, making exploration part of crafting. Packs can be bought with **in-game gold**, with island-specific sets and differing trade bindings.

The market is a desired player economy. It is not authorization for real-money transactions, tokens, purchases or a live marketplace. No real-money monetization model was decided.

## Intended connected loop

Find an artisan → learn a recipe → identify missing cards/resources → adventure or trade for them → deliberately sacrifice ingredients → receive the target card → adapt a deck → challenge new content. Deterministic recipes can complement random boss excitement; a pity system or exact guarantee was not finalized.

## Future data contract

Separate card definition from inventory instance/provenance. Track recipe ownership, ingredient quantities, eligible bindings and output binding. A craft is atomic: validate all requirements, consume exact ingredients and grant output once, then persist. Prevent consuming a protected starter or leaving an illegal equipped deck without a deliberate solution. These are implementation recommendations, not completed mechanics.

Existing Ember Reach shards are derived from encounter clears, not a spendable ledger. Do not implement crafting by decrementing that derived number. Use an explicit earned/spent or transaction ledger when crafting is actually built.

## Open

Gold sources/sinks, pack price and odds, market fees, listing duration, direct trades versus auctions, bound-output rules, boss drop rates, replay rewards, recipe acquisition prices, salvage and prevention of involuntary starter loss. Guaranteeing a creature's own victory card and rolling bonus boss loot can coexist; define which drop is which.

## Slice boundary

The tutorial grants a small one-time resource and creature-card reward locally. It does not spend, trade, buy packs or connect to other accounts. Local saves are not a trustworthy server authority for a future market.
