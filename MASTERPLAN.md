# eyeland.cards: Masterplan

Written 2026-08-10, **pivoted 2026-08-20.** This is the constitution: what
this project IS, independent of any single session's mood. If a future
session contradicts a line here, that's a real conversation about the plan
changing, not a routine update — this file's own second version is exactly
that conversation, not drift.

**The pivot, stated plainly:** the 2026-08-10 version of this file explicitly
paused the MMORPG build ladder in favor of a Sokpop-style "1000 tiny games"
queue. Adam said directly on 2026-08-20: *"I actually just want to master
eyeland.cards, not make 1000 tiny shitty games, I want to make 1 master
game. I've been dreaming about this game for years."* That reverses the
2026-08-10 decision on purpose, not by accident. `GAMES-1000.md` and its two
real shipped entries (001 Eyeland Duel v0, 002 Falling Block Clear) stay as
real, honest history — 001 in particular **is** this game's own v0 rung, not
a separate thing — but the queue itself is no longer the active thesis.

## 🎯 THE THESIS

**One master game, finished properly.** The open-world card-combat MMORPG
(Wizard101 spell-duels × Hearthstone deckbuilding × Pokémon open world x
Breath of the Wild's "strength from beating things") Adam has been dreaming
about for years, actually built to completion, not prototyped forever. The
existing build ladder (`v0 Duel → v1 Deck → v2 Island → v3 World → v4
Online`) is the real spine; this file now exists to make sure it survives
contact with real dream-scope ambition instead of dying in development hell,
the way almost every "I've been dreaming about this for years" project does.

## ⚙️ THE MECHANISM

Synthesized 2026-08-20 from real completion stories, not starting stories
(`DESIGN.md`'s 11 principles already cover what makes a game *good*; this is
what actually gets a game *finished*):

1. **Vertical slice before horizontal expansion.** One fully-realized loop —
   final-quality art, real UI, real balance, start to finish — before ten
   shallow ones. v0 Duel already did this once for the duel core (a real
   10-turn playtest, an AI-vs-AI balance simulator). v2 Island needs the
   same treatment as its own vertical slice: one real island, one real
   loop, played start to finish, before "the island system" gets built out.
2. **Real players before real launch.** Supergiant's Hades ran Early Access
   22 months (Dec 2018 to Sept 2020) as its primary design tool, not
   marketing — biomes, characters, balance all shaped by live player
   reactions before 1.0. Get a rough, honest build in front of strangers as
   early as each rung allows; let their reactions, not solo taste, drive
   what gets cut.
3. **Depth over breadth in the core mechanic**, the completion-phase version
   of `DESIGN.md` Principle 2. Braid is one rewind mechanic explored across
   6 worlds, not six shallow mechanics. v2 Island is "the Match loop, but on
   a map," explored deeply — not Match + crafting + housing + trading all
   half-built at once.
4. **A written cut list, defended as hard as the feature list.** Stardew cut
   multiplayer for years past its own solo-dev window; Hollow Knight cut
   entire planned areas. The cut list is the mechanism that keeps the
   vertical slice polished instead of everything staying half-done.
5. **Milestones tied to playable builds, not features.** "v2 Island is 60%
   done" is meaningless. "A stranger can open the build and finish one
   island loop start to finish" is real. Same shape as the existing build
   ladder, just enforced *inside* each rung now, not only between rungs.

**Honest AI-era caveat, per the standing manual-before-automation rule:** AI
compresses grunt work (art passes, dialogue drafts, boilerplate code) none
of the case studies above had. It does **not** compress the actual
bottleneck in every one of them: the playtest-then-cut loop. That loop is
still real time with real people, and it's what this ambition will actually
live or die on.

## 💰 THE MODEL

**Genuinely undecided, still.** The 2026-08-10 version's Sokpop-subscription
model was scoped to a tiny-games queue that no longer exists as the active
thesis; it doesn't automatically transfer to a single finished MMORPG-lite.
Real candidates for a single completed game: one-time purchase, a
Hades-style paid Early Access, or something else entirely. Not picked in
advance of evidence, same discipline this file has held from the start.

## 🧭 THE DISCIPLINE

- Never expand scope before the current rung (or the current rung's own
  vertical slice) is proven fun — `DESIGN.md` Principle 1, still load-bearing.
- Every milestone is a playable-build claim, not a feature-percentage claim.
- Log real imbalances and real bugs honestly instead of quietly patching
  them (already standing practice: v0's 71-73% first-player-advantage
  finding in `game/README.md`, still open, still logged, not hidden).
- CLI-first verification for anything Unity: batch compiles and headless
  PlayMode tests, not computer-use GUI clicking.
- A written cut list lives alongside every rung's scope, updated honestly,
  not padded to look more ambitious than it is.

## 🚫 NOT

- **Not the 1000-games queue as the active thesis anymore.** `GAMES-1000.md`
  stays as real, honest history (001 and 002 genuinely shipped, and 001 IS
  v0 Duel, not a separate credit) — it's paused, not deleted, and not
  reopened without the same kind of explicit, direct reversal this pivot
  itself required.
- **Not AAA scope, and not "prove it's ambitious" padding.** Meta-progression
  systems, extra content, or extra polish don't get bolted onto a rung to
  make it look bigger before its own vertical slice is proven fun.
- **Not vibes-coded, ever.** Every milestone gets actually played by someone
  before it counts as done, same standard v0 Duel already met.

## 🏝️ V2 ISLAND: THE COMMITTED SCOPE (2026-08-22)

The vertical slice this rung is measured against, in one sentence, per the
mechanism above:

> **One procedurally generated island with three mob camps and one warden,
> where every fight is the v0 duel loop and every win drops a card that
> changes your deck for the next fight, playable start to finish in 20
> minutes.**

**Two design decisions committed with it, both Adam's, 2026-08-22:**

1. **Turns are time-bound**, Hearthstone-style, not untimed. A turn timer
   is what makes the core loop *fast*, which is the stated appeal ("fast
   battles, no waiting"). This is a real change to `v0 Duel`'s current
   untimed turn engine and needs to land before the slice counts as done.
2. **Islands are procedurally generated AND themed**, not generic. Same
   instinct as the Jello pitch's three starting areas, where a fire
   factory town, a haunted forest, and a desert oasis all had to be
   genuinely distinct so no player felt cheated by their starting version
   (see `game/research/jello-pokemon-pitch.md`). Theme drives the mob
   table and therefore the card drops, so it's a mechanical decision, not
   a decorative one.

**What this slice deliberately does NOT include**, named so it can't creep
back in silently:

- No automation or idle layer. Real tension, honestly unresolved: Factorio
  automation removes the player from the loop, turn-based combat requires
  them in it every turn. Loop Hero resolves this by making combat automatic
  and moving agency into map building. That's a real fork worth taking
  later, not inside this slice.
- No class or race selection. `DESIGN.md` principle 11 already flags this
  as an open fork (WoW commits at creation, Terraria lets gear define the
  role) and this file won't silently pick it.
- No multiplayer. Adam confirmed 2026-08-22 that solo is a real game, so
  co-op stays at `v4 Online` where the ladder already puts it.
- No crafting, no questbook UI, no overworld beyond the one island.

**Why these four pillars and not the other four:** deckbuilding + procgen +
cards-as-combat-loot is already one proven shape (Slay the Spire, built by
two people; Slay the Spire 2 sold 3M copies in its launch week), and
eyeland already has the combat engine and the deckbuilder shipped. This
slice fires four of Adam's named pillars at once while reusing both
existing rungs, instead of starting a fifth thing from zero.

## 📍 WHERE THINGS STAND (2026-08-20)

- **v0 Duel: shipped.** Real 10-turn playtest, AI-vs-AI balance simulator,
  one honest open finding (71-73% first-player advantage) logged, unfixed.
- **v1 Deck: shipped 2026-08-09**, real deckbuilder + clickable duel screen
  live in the actual Unity project. Committed 2026-08-20: a real layout bug
  fix (rows were stretching full-width on wide screens instead of a fixed
  centered column), a Quick Play button (skip manual building, use the
  starter deck), an invisible-button-color fix, and an unbiased Fisher-Yates
  shuffle replacing a biased `OrderBy(_ => rng.Next())`.
- **v2 Island: scoped 2026-08-22, not started.** Its committed vertical
  slice is written above under "V2 ISLAND: THE COMMITTED SCOPE", along with
  the two design decisions that came with it (time-bound turns, themed
  procgen islands) and an explicit list of what it excludes.
- **`GAMES-1000.md` / `GAME2-MASTERPLAN.md`**: both now describe paused
  side-work relative to this thesis, not the active plan. Not rewritten as
  part of this pivot; flagged here so a future session doesn't read them as
  current without checking this file first.

## 📡 REALITY CHECK

This is the second version of this file in ten days, reversing its own prior
decision. That's not drift, it's Adam naming, directly and explicitly, that
the tiny-games discipline wasn't actually what he wanted, a year-old real
dream was. The honest risk this file exists to guard against now is the
opposite failure mode from before: not "never ships anything," but "dream
scope swallows the project the way it swallows almost every 'I've been
dreaming about this for years' game." The mechanism above (vertical slice,
real players, depth over breadth, a real cut list, playable-build milestones)
is the guard against that specific failure, chosen because it's what
actually worked for the studios who finished, not because it sounds
disciplined.

---
**Next natural handoff:** v2 Island's vertical slice is now written and
committed (2026-08-22), so the next real step is building against it, not
more planning. First concrete task: add a turn timer to `v0 Duel`'s turn
engine, since that is the one decision above that changes already-shipped
code rather than adding new code.
