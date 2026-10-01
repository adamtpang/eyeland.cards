# The 1,000 games queue

The fourth 1000-life-loop pillar, alongside `ESSAYS-1000.md` (pangaea.blog),
`SONGS-1000.md` (strummer.fun), and the apps pillar (thedojo.fun). Same
discipline as essays: **a queue entry is a scoped mechanic, not a genre
word.** "A deckbuilder" is not a game. "Chop down MFR rubber trees before
mana runs out" is a real Match turn already shipped inside eyeland.cards
itself. Do not pad this file to 1,000. A queue you trust beats a queue
that is full.

**Honest count:** 2 shipped, 6 queued (№ 003-008). The queued six are
each grounded in a real pivotal game from Adam's own note (raw notes,
2026-08-09) or the games-as-life-microcosm research already in
`game/DESIGN.md`: not invented from a bare topic word. Every future
entry keeps that rule: name the real game it's stolen from, and the one
mechanic it's actually testing.

**Rule (same as DESIGN.md Principle 1):** never expand scope before the
current entry is proven fun. One entry at a time, small, shipped, played.

---

## Shipped

001. **Eyeland Duel v0**: 1v1 card duel, mana/attack/turn engine, real
     10-turn console playthrough + AI-vs-AI balance simulator. The proof
     this whole pillar rests on: a tiny, real, honestly-tested game, not
     a pitch.

002. **Falling Block Clear** *(Tetris/TETR.IO)*, one mechanic: rotate and
     drop, clear a full line. `game/src/Eyeland.Games.FallingBlockClear` +
     `.Console` (`dotnet run --seed <n>`), same portable-core-plus-console-
     harness pattern as v0 Duel, chosen specifically because it needed zero
     Unity GUI/licensing to actually playtest tonight. 8x14 board, 3 piece
     shapes (I/O/L), no wall-kicks, no hold, no next-piece preview, win at
     10 lines cleared: DESIGN.md Principle 2's "one mechanic, absolute
     elegance" applied literally, not just cited.
     **Real playtest findings (Principle 3):** two bugs caught by actually
     playing, not by review. (1) `Render()` was labeling every locked cell
     with the *current falling piece's* kind instead of the kind it
     actually locked in as: fixed before ship. (2) A genuine line clear
     was verified by deliberately packing an O-piece + two L-pieces
     edge-to-edge across all 8 columns (`a a a x` / `x` / `d d d x` under
     `--seed 99`), confirmed via the real log line
     `Cleared 1 line(s). Total: 1/10.`, not assumed from code reading.

## RUN 1 · One mechanic each, stolen from the pivotal-games note

Each of these is ONE real mechanic from a named favorite, built to prove
just that mechanic: no genre-scale scope, no art budget, no meta-progression.
Speedrun means the whole thing ships in a sitting, not that it's rushed.
003. **Single-lane tower defense** *(Bloons)*, one tower type, one enemy
     wave, one win condition: don't let it reach the end.
004. **Penalty shootout** *(FIFA)*, one mechanic: a timing bar sets power
     and direction, one shot, one save/miss.
005. **Note-timing lane** *(Guitar Hero / Rock Band)*, one mechanic: hit
     the falling note on the beat, miss breaks the streak.
006. **School-typed duel** *(Wizard101, distinct from eyeland's own combat)*,
     one mechanic: rock-paper-scissors school typing resolved as a single
     best-of-three duel, no deck, no mana.
007. **Single-lane auto-battler skirmish** *(Stick War / Epic War)*, one
     mechanic: spend a resource to spawn units on a lane, watch them fight,
     first base to zero loses.
008. **Rubber-tree harvest loop** *(MFR / FTB, tonight's real speedrun blocker)*,
     one mechanic: chop trees before a mana/stamina bar empties, bank
     resources before the timer resets. The actual real problem from
     tonight's Minecraft speedrun, extracted into its own tiny game.

---

Next slots fill the same way runs 15-18 filled ESSAYS-1000.md: mining real
source material (this session's transcripts, the parked-captures sweep
files, future pivotal-games notes) rather than inventing genre words to
hit a number.

## Devlog habit

Added 2026-08-12, prompted by real research (`Field Notes: How the
Breakouts Were Built`): every solo/small-team breakout studied had a real
audience built *before* the hit, usually via a plain devlog habit. GAMES-1000
had the shipping discipline already; it didn't have this.

**Rule:** after every entry ships or gets a real, honest update, write a
short post (~300-450 words, same "seedling" ethos as ESSAYS-1000: allowed
unfinished, defuses posting aversion) to `pangaea.blog/src/content/posts/`,
tagged `[devlog, eyeland-cards, games-1000]`. No new infrastructure: reuse
pangaea.blog's existing `/write` pipeline and posts collection rather than
building a separate one. Leave the essay `number` field unset so devlog
posts never inflate the real ESSAYS-1000 count.

**Content bar, same as Principle 3 (fairness/honest bug logging):** every
entry names at least one real bug or failure caught by actually running the
thing, not just what shipped. A devlog with no real friction in it isn't
worth the post.

First entry: [GAMES-1000 devlog #1](../pangaea.blog/src/content/posts/games-1000-devlog-1-the-webgl-preview-loop.md), covering entry 002's ship and the WebGL build pipeline.
