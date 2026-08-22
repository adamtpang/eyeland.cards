# Field notes: two open-source card engines, and what eyeland took

Researched 2026-08-22 by reading both codebases directly, not summaries.

**Licensing, up front, because it governs everything else.** SabberStone is
**AGPLv3** and Spellsource ships its own `LICENSE.md`. AGPL is the strongest
copyleft there is: copy the code and eyeland must also be AGPL with source
disclosed. That does not block selling on itch.io or Steam, but it is a real
decision, not a footnote.

**So: architecture only.** Game mechanics and architectural patterns are not
copyrightable (a point ChatGPT already made to Adam years ago, preserved in
`milanote-game-ideas-export.md`). Everything below is an idea taken from
reading, then implemented from scratch in eyeland's own model. No lines were
copied from either project.

---

## SabberStone — the onion system

[github.com/HearthSim/SabberStone](https://github.com/HearthSim/SabberStone) ·
C# / .NET · AGPLv3 · ~98% of standard cards · last substantive work 2019.

Notably it comes from **HearthSim**, the same org behind Hearthstone Deck
Tracker and HSReplay, whose collection API this repo already reads in
`hearthstone/scripts/refresh-collection.mjs`.

Its README names the "onion system" but never explains it. The explanation is
in the source. Two files carry it:

**`SabberStoneCore/src/Enchants/AuraEffects.cs`** — described in its own doc
comment as *"a simple container for saving tag value perturbations from
external Auras."* It is a flat `int[]`, one slot per game tag, with fixed
indices per entity type (minions get slots for ATK, Health, Charge, Taunt,
Lifesteal, Rush, CantAttack).

**`SabberStoneCore/src/Model/Entities/Controller.cs:155`** — the read path,
and the whole trick in one line:

```csharp
return value + ControllerAuraEffects[t];
```

The stored value is never the answer. The answer is the stored value plus the
aura layer, computed at read time.

### The three layers

| Layer | What | Stored? |
|---|---|---|
| Base | printed card values | immutable |
| Enchantments | permanent modifiers attached to the entity | yes |
| Auras | continuous effects from *other* entities | **no**, recomputed |

The reason auras must not be stored is the classic bug they prevent: if a
buff is written into a minion's attack, and the minion granting it dies, you
have to subtract exactly the right amount from a number that other effects
have also touched. Recomputing from scratch makes that failure impossible.

---

## Spellsource — cards as data, not code

[github.com/hiddenswitch/Spellsource](https://github.com/hiddenswitch/Spellsource) ·
Java · actively maintained · 100% of Hearthstone plus hundreds of community
cards.

Every card is a JSON file. Two real ones, read from the repo:

```json
{
  "name": "Defensive Pheremone",
  "type": "ENCHANTMENT",
  "description": "Your units have Guard.",
  "auras": [
    { "class": "AttributeAura", "target": "FRIENDLY_MINIONS", "attribute": "AURA_TAUNT" }
  ]
}
```

```json
{
  "name": "Crypto, the Trapper",
  "baseManaCost": 6, "baseAttack": 8, "baseHp": 4,
  "type": "MINION", "rarity": "LEGENDARY", "race": "BEAST",
  "battlecry": {
    "targetSelection": "MINIONS",
    "spell": { "class": "custom.AnobiiSpell", "card": "permanent_cocoon", "secondaryTarget": "SELF" }
  },
  "deathrattle": { "class": "NullSpell" },
  "fileFormatVersion": 1
}
```

Three things worth stealing from that shape:

1. **`baseManaCost` / `baseAttack` / `baseHp`.** The `base` prefix is not
   decoration. Spellsource independently arrived at the same layered model.
2. **`AURA_TAUNT` is a different attribute from `TAUNT`.** Aura-granted
   keywords are tracked separately from printed ones, for exactly the reason
   above.
3. **Cards are data; only novel effects are code.** A card names a spell
   class and its parameters. New cards need no recompile, and someone who
   cannot write Java can still author one.

---

## What eyeland actually took, and what it did not

### Taken: the onion, implemented fresh

`game/src/Eyeland.Duel/Stats.cs` and a rewritten `BoardCreature`.

Before, `BoardCreature` had flat mutable `Attack`, `Health` and `Taunt`. That
works for ten cards and breaks the moment two effects touch the same stat.

Now:

```
Attack     = max(0, base + Σ enchantments + auraBuffer)
MaxHealth  = max(1, base + Σ enchantments + auraBuffer)
Health     = MaxHealth − Damage
Taunt      = (printed + Σ enchantments + auraBuffer) > 0
```

**Damage is now separate from health.** This was the real bug in the old
model, and it is the one the verification suite proves. Under flat stats,
buffing a damaged creature's max health silently healed it, and losing that
buff could kill a creature that had never been hurt.

`AuraSystem.Refresh` recomputes every aura from scratch on each board change.
Full recompute rather than incremental bookkeeping is deliberate: a board caps
at 7 per side, so the cost is nothing, and incremental aura tracking is
precisely where stale-buff bugs live.

`CleanupDead` became the single choke point and now loops until stable, since
losing an aura can lower a creature's max health below damage already taken,
killing it, which can drop another aura.

**Proof it works** — 24 assertions, all passing, including the two failure
modes this refactor exists to prevent:

- *buff a damaged creature*: max health rises to 7, current to 3, not to 7.
  Remove the buff and it returns to 1, the damage correctly re-applied.
- *aura source dies mid-combat*: the ally's +1 disappears in the same step,
  with no stale bonus.

`Storm Totem` (3 mana 0/4, "Your other creatures have +1 Attack") is the
first real aura card, added to exercise the layer end to end rather than
leave it as untested scaffolding.

**Balance is unchanged**, which is what a pure refactor should do: the AI-vs-AI
simulator still reports **71.8%** first-player advantage over 500 games,
inside the 71-73% band already logged in `game/README.md`. That finding is
still open and still honest.

### Not taken, but recommended: cards as data

eyeland's cards are C# lambdas in `Cards.cs`. Every new card is a recompile,
and only someone editing C# can add one. Spellsource proves the data-driven
approach scales to 100% of Hearthstone plus hundreds of community cards.

This matters for eyeland specifically because the Milanote export already
asks for things a code-only card model makes hard: *"make a card editor"*,
*"relegation cards crowdsourced or from me"*, *"have a forum for game ideas /
suggestions"*, and *"look at customhearthstone for their best cards"*. All of
those want cards to be data.

Not done here because it is a real migration, not a refactor, and
`MASTERPLAN.md` says not to expand scope before the current rung's vertical
slice is proven fun. Worth doing when the card count passes roughly 30, or
the first time a card editor is genuinely wanted.
