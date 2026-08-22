# Field notes: how Hearthstone and Exploding Kittens were actually prototyped

Companion to `FIELD-NOTES-breakout-games.md` (how finished games got
finished). This one is narrower and earlier: how two enormously successful
card games were tested **before** they were software, and what that means
for eyeland's v2 Island slice.

Researched 2026-08-22. Everything here is sourced; one common belief is
corrected below.

---

## Hearthstone: paper first, then Flash (not HTML)

**One correction up front.** Hearthstone's first digital prototype was
**Flash**, not HTML. Worth knowing because the reason they chose it still
applies directly to eyeland.

### The team was two people

Early in development, deadlines on another Blizzard project pulled every
member of Team 5 off Hearthstone **except Eric Dodds and Ben Brode**. That
isolation turned out to be an advantage: with only two people, every
prototyping decision could be settled immediately, and they moved through
a huge number of design iterations fast.

Dodds, on the accidental benefit:

> "I wish I could say it was planned, but a lot of our engineers were
> moved to another project, so we got a lot of unintended design time."

### Paper came before code, deliberately

Dodds and Brode built their first prototypes with **pen and paper, cutting
pieces of paper into test cards**. No engine, no code. They spent an
unexpectedly long stretch designing before writing any code at all, and the
result was fewer costly revisions later.

The stated economic argument: two designers making paper prototypes cost
dramatically less than building the same test in-engine.

### Then Flash, specifically to keep experiments out of the real codebase

After paper, they moved to **Flash**. Two real reasons, both worth stealing:

1. It let them experiment with digital card mechanics fast.
2. It kept **experimental code out of the final codebase**. The prototypes
   were crude but functional, easy to swap pieces in and out of, and
   nothing built there had to survive into the shipping game.

### The core lesson

Dodds, plainly:

> "It's not rocket science to iterate fast."

and

> "On Hearthstone we had tons and tons of bad ideas that we needed to try,
> and then not do."

The point of paper and Flash was never speed for its own sake. It was
**making bad ideas cheap to discover and cheap to discard.**

Source: [Iterate fast and other design lessons from Hearthstone](https://www.gamedeveloper.com/design/-iterate-fast-and-other-design-lessons-learned-from-i-hearthstone-i-) ·
[Design and development of Hearthstone](https://hearthstone.wiki.gg/wiki/Design_and_development_of_Hearthstone)

---

## Exploding Kittens: one deck, carried everywhere

### It started as a different game with a different theme

Elan Lee and Shane Small first built a prototype called **"Bomb Squad"**.
The core mechanic was already the final one: a few bad cards (bombs) sit in
the deck, and every other card exists to help you avoid drawing them.

The kittens came later. When they showed it to Matt Inman (The Oatmeal),
he suggested swapping bombs for adorable fuzzy kittens and calling it
Exploding Kittens. **The mechanic was proven before the theme existed.**

### The prototype went everywhere he did

Lee **carried a deck with him everywhere** while developing it, and the
team ran worldwide playtest parties. The game wasn't refined by internal
debate; it was refined by an enormous number of real strangers playing a
physical deck.

### The core lesson

The mechanic is what gets playtested. Theme, art, and name are swappable
later, and in this case swapping them is exactly what made it a phenomenon.
A physical deck you can hand to anyone, anywhere, is the fastest possible
feedback loop.

Source: [Exploding Kittens (Wikipedia)](https://en.wikipedia.org/wiki/Exploding_Kittens) ·
[Elan Lee on Tim Ferriss](https://tim.blog/2023/02/03/elan-lee/) ·
[Mojo Nation interview on failing fast](https://www.mojo-nation.com/exploding-kittens-co-creator-elan-lee-kickstarter-failing-fast-differences-digital-physical-gaming/)

---

## The shared pattern

1. **The mechanic gets proven before the medium.** Paper for Hearthstone,
   a carried deck for Exploding Kittens. Neither started in an engine.
2. **Theme is swappable, mechanic is not.** Bombs became kittens with no
   mechanical change and became a phenomenon.
3. **Prototype code is disposable on purpose.** Hearthstone's Flash build
   existed specifically so experimental code never touched the real
   codebase.
4. **Bad ideas are the point.** You are buying the ability to find and kill
   them cheaply, not trying to be right first time.
5. **Small teams iterate faster.** Two people meant no coordination cost on
   any decision.

---

## What this means for eyeland specifically

**Adam already had this instinct.** The Milanote export
(`milanote-game-ideas-export.md`, written years before this file) contains
a whole `paper proto` section:

> - do paper design for cards
> - add +1 -1 little stickers for the paper prototype
> - go boards have an 18 x 18 grid dimension

and a `prototype` list that starts with `paper prototype` and
`play with kamia`. That's the Brode/Lee method, already written down and
never executed.

**The uncomfortable, useful implication for v2 Island:** the committed
slice (one procgen themed island, three mob camps, one warden, cards as
combat loot, time-bound turns) has two genuinely separable questions:

- **Is the card combat fun?** Already partly answered. v0 Duel is real,
  playable, and has an AI-vs-AI balance simulator. This is the part that
  does NOT need paper.
- **Is "fight camps, win cards, deck changes, fight the warden" a fun
  loop?** This is a **progression** question, not a rendering question,
  and it is exactly the kind of thing paper answers in an afternoon and
  Unity answers in three weeks.

The second one is testable on a table with index cards, a hand-drawn
island, and one other person, before a single line of v2 code exists.
Doing that first is not a detour from the slice. It is the cheapest
possible way to find out whether the slice's core assumption is even
correct.

Per `MASTERPLAN.md`'s own mechanism (vertical slice, real players early,
a real cut list), and per the standing manual-before-automation rule, this
is the manual version of v2 Island.
