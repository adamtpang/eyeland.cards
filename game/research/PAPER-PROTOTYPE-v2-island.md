# Paper prototype: the v2 Island loop

**The one question this answers:** is *fight camps → win cards → deck
changes → fight warden* a fun loop?

**What it deliberately does NOT test:** whether card combat is fun. `v0
Duel` already answered that with a real playtest and an AI-vs-AI balance
simulator. Combat here is abstracted to a single fast roll-up on purpose,
because testing it again would triple the runtime and answer a question
that is already answered.

Method borrowed from `FIELD-NOTES-paper-prototyping.md`: Dodds and Brode
cut paper into cards before writing any Hearthstone code, and Elan Lee
carried a physical deck everywhere before Exploding Kittens existed as a
product. This is that step, for this specific slice.

**Time:** ~1 hour to build, ~20 minutes to play. Matches the v2 slice's
own "playable start to finish in 20 minutes" standard.

---

## Materials

- ~30 index cards (or A4 cut into eighths)
- 1 pen
- 1 six-sided die
- 1 sheet of paper for the island map and the run tracker

---

## Build: the 16-card starter deck

Exactly the deck `CardSet.StarterDeck()` already ships. **Power** is the
one number the prototype adds, derived from real stats (creature =
attack + health, spell = effect magnitude). Write name, cost, and power
on each card. Text is optional; you will not resolve it.

| Card | Cost | Real stats / effect | Power | Copies |
|---|---|---|---|---|
| Glowing Ember | 1 | 1/2, deal 1 to face | **4** | 2 |
| Ember Bolt | 2 | Deal 3, draw if first spell | **4** | 2 |
| Tide Guard | 2 | 1/4 Taunt | **5** | 2 |
| Squall Caller | 2 | 2/2, draw a card | **5** | 2 |
| Cinder Wolf | 3 | 4/2 | **6** | 2 |
| Stormcaller Elemental | 4 | 3/5 | **8** | 2 |
| Tidewisp | 3 | 3/4, heal 2 | **8** | 1 |
| Riptide | 4 | Heal 5, draw | **6** | 1 |
| Rolling Thunder | 6 | Deal 4 to a creature | **8** | 1 |
| Eye of the Storm | 5 | Deal 2 to all, draw 2 | **9** | 1 |

**16 cards.** If Power feels wrong while playing, that is a finding, not a
bug. Write down what felt wrong.

## Build: the reward cards (Ember Reach, a fire island)

This tests the v2 scope decision that **theme drives the mob table, which
drives the card drops.** Ember Reach is fire-themed, so every drop is fire.
Four of these are new cards invented for the prototype; that is the point.

| Card | Cost | Concept | Power | Offered at |
|---|---|---|---|---|
| Ash Imp | 1 | 2/1 | **3** | Camp 1 |
| Glowing Ember (3rd copy) | 1 | 1/2, deal 1 | **4** | Camp 1 |
| Emberclaw Prowler | 2 | 3/2 | **5** | Camp 2 |
| Cinder Wolf (3rd copy) | 3 | 4/2 | **6** | Camp 2 |
| Magma Shell | 3 | 2/6 Taunt | **8** | Camp 3 |
| Firestorm | 4 | Deal 3 to all enemies | **9** | Camp 3 |

---

## The island

Draw four boxes on the paper, left to right:

```
[Camp 1] → [Camp 2] → [Camp 3] → [WARDEN]
```

| | Mana | Threat |
|---|---|---|
| Camp 1 | 3 | 7 |
| Camp 2 | 4 | 9 |
| Camp 3 | 5 | 11 |
| **Warden** | 7 | 15 |

**These numbers are tuned, not guessed.** The first draft used 8/11/14/20
and a 20,000-run Monte Carlo showed a **0.3% win rate** — the base deck
mathematically could not clear camps 3 or 4 at all. The values above give a
**~23% overall win rate**, with per-camp clear rates of 61 / 73 / 71 / 66%.
The rise from camp 1 to camp 2 is the deck-improvement effect appearing in
the numbers, which is the loop this prototype exists to test.

**You start with 3 Wounds.** Lose all 3 and the run ends.

---

## The skirmish (one fight, ~2 minutes)

1. **Shuffle** your deck. **Draw 4 cards.**
2. You have that camp's **Mana**.
3. **Play any cards** from those 4 whose **total cost ≤ Mana**.
4. **Sum their Power.** That is your **Strike**.
5. **Strike ≥ Threat → you win.**
6. **Strike < Threat → second wind.** Discard the hand, draw 4 new, try
   once more.
7. **Fail twice → lose 1 Wound**, take no reward, move to the next camp
   anyway.

Played cards go back in the deck and are reshuffled for the next fight.
There is no health, no board, no turn order. That is intentional.

## The reward choice (after each won camp)

Choose exactly **one**:

- **(a) Add** one of the 2 cards offered at that camp, or
- **(b) Remove** any one card from your deck, permanently.

Option (b) is the deck-thinning lever that gives Slay the Spire much of its
depth. If you never once want it, that is a real finding about whether the
deck layer has any depth at all.

## Procedural variation (the part testing "procgen")

Before each camp, **roll the die** and apply that trait. This is the
cheapest possible test of whether procedural variation adds real fun or
just noise.

| Roll | Trait | Effect |
|---|---|---|
| 1 | **Swarm** | Threat +2, but choose from **3** reward cards |
| 2 | **Fortified** | **1 less mana** this fight |
| 3 | **Rich** | Keep **both** offered reward cards |
| 4 | **Ambush** | Draw **3** cards, not 4 |
| 5 | **Volatile** | **No second wind.** One attempt only |
| 6 | **Sleeping** | Threat **-3** |

---

## The run tracker

Copy this onto the paper and fill it in as you go. This is the actual
output of the prototype.

```
RUN #___          Island: Ember Reach

Camp 1   trait:______  strike:___ / 7    won? ___   took: add____ / remove____
Camp 2   trait:______  strike:___ / 9    won? ___   took: add____ / remove____
Camp 3   trait:______  strike:___ / 11   won? ___   took: add____ / remove____
WARDEN   trait:______  strike:___ / 15   won? ___

Wounds left: ___        Final deck size: ___
```

## The five questions (answer immediately after, in writing)

1. **Did you want to play again?** *(Adam's own stated test, from the
   Milanote export: "we only ask one question: did you want to play
   again?")*
2. **Was any reward choice actually hard?** If every pick was obvious,
   the deckbuilding layer is not doing work yet.
3. **Did your deck feel different by the warden fight?** If it felt the
   same, the loop's core promise is not landing.
4. **Which camp trait was the most fun? The least?** The least-fun one is
   a cut-list candidate, not something to balance.
5. **Did you ever want to remove a card?** If never, deck thinning is not
   earning its slot.

---

## How to read the results

- **"Yes, again" plus at least one genuinely hard reward choice** → the
  loop works. Build it in Unity as specced.
- **"Yes, again" but every choice was obvious** → the loop works but the
  card pool is too flat. Fix the cards before writing v2 code, not after.
- **"No" but individual fights were tense** → the fights carry it and the
  progression does not. That is a real finding worth a scope change, and
  much cheaper to learn here than three weeks into Unity.
- **"No" and it felt like arithmetic** → the abstraction is too thin, or
  the loop genuinely needs the real combat to be fun. Either way, run it
  again with actual `v0 Duel` fights in place of the strike roll-up
  before concluding anything about the loop itself.

**Run it at least twice.** Once solo, once with someone else playing while
you watch and say nothing. Per the field notes, watching someone else play
is where Hearthstone and Exploding Kittens both found the things internal
debate missed.
