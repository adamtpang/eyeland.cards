# Classes and card sets

One file per class, plus [the common collection](neutral.md).

**These are generated from `game/data/cards.json` by
`node game/scripts/sync-class-docs.mjs`.** Edit the JSON, then re-run it. Do not
hand-edit these files: they will be overwritten.

## The deck rule

**A legal deck is one class plus neutrals.** No mixing two classes.

That single rule is what makes the verbs below mean anything. Choosing Barbarian
is choosing to be good at "damage is fuel" *and* giving up every other class's
answer to your problems.

## The twelve, and one more

| Class | Verb | Set |
|---|---|---|
| Barbarian | damage is fuel | [barbarian.md](barbarian.md) |
| Bard | buff the whole board | [bard.md](bard.md) |
| Cleric | heal and preserve | [cleric.md](cleric.md) |
| Druid | small things that grow | [druid.md](druid.md) |
| Fighter | honest, efficient bodies | [fighter.md](fighter.md) |
| Monk | many cheap actions | [monk.md](monk.md) |
| Paladin | protect, then punish | [paladin.md](paladin.md) |
| Ranger | precision, plus a companion | [ranger.md](ranger.md) |
| Rogue | conditional burst | [rogue.md](rogue.md) |
| Sorcerer | volatile power | [sorcerer.md](sorcerer.md) |
| Warlock | pay health for it | [warlock.md](warlock.md) |
| Wizard | spells pay off spells | [wizard.md](wizard.md) |
| **Tinkerer** | build your own | [tinkerer.md](tinkerer.md) |
| *(any)* | the shared floor | [neutral.md](neutral.md) |

**Tinkerer is not an SRD class.** It is Adam's own, from the Milanote export
("engineer, can craft mounts and mechsuits for battle").

## Keywords

| Keyword | What it does |
|---|---|
| **Taunt** | Enemies must attack this before anything else |
| **Rush** | May attack enemy creatures the turn it lands, but not the enemy caster |
| **Charge** | May attack anything the turn it lands |
| **Divine Shield** | Absorbs the first damage entirely, then is spent |
| **Lifesteal** | Damage it deals heals your caster |
| **Windfury** | Attacks twice each turn |
| **Poisonous** | Any creature it damages is destroyed |
| **Stealth** | Cannot be targeted until it attacks or deals damage |
| **Freeze** | The target loses its next turn's attacks |
| **Spell Damage +N** | Your spells deal N more. Combat is unaffected |
| **Deathrattle** | Fires when this creature dies |
| **Battlecry** | Fires when this card is played |

Keywords are stored as counters on the stat onion, not booleans, which is why a
creature with printed Taunt that also gets Taunt from an aura keeps its printed
Taunt when the aura source dies. See `game/src/Eyeland.Duel/Stats.cs`.

## Licensing

The twelve class names come from the **SRD 5.1**, used under CC-BY-4.0:

> This work includes material taken from the System Reference Document 5.1
> ("SRD 5.1") by Wizards of the Coast LLC and available at
> https://dnd.wizards.com/resources/systems-reference-document. The SRD 5.1 is
> licensed under the Creative Commons Attribution 4.0 International License
> available at https://creativecommons.org/licenses/by/4.0/legalcode.

**The names only.** No SRD stat blocks, spells, rules text or descriptions are
reproduced. Every card name, effect and number is original to eyeland.cards.

## Status

All 66 cards are **designed but unplayed**. The next real move is putting a
class deck in front of the AI simulator, or into the browser prototype, and
finding out which verbs actually feel like anything.
