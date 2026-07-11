# CLAUDE.md — Rafaam Warlock ladder project

## Goal

Build and iterate a competitive **Rafaam Warlock** list for current Standard,
optimized for **ladder winrate within Adam's collection** — not theorycraft.
The collection lives in [collection.md](collection.md); treat unchecked cards as
not owned.

## Home

This is the Hearthstone-tooling arm of the **eyeland.cards** game project
(repo root: `../`, see `../HANDOFF.md` for the full picture). Sequence:
Hearthstone tooling now → Adam's own Unity card game later. This deck work is
deliberate practice for the game's card-duel core. Career angle: HSReplay is
hiring — this tooling doubles as a portfolio piece (their platform skews
Battlegrounds, which is not Adam's focus; constructed Standard is).

## Archetype context (2026-07-11)

HSGuru tracks the archetype as **"Rafaamlock"**. Build-arounds: **Timethief
Rafaam** (10-mana 10/10, Fabled+ — deck size 40 but 10 of it is Rafaams;
Battlecry destroys enemy hero if you played the other 9) + **Godfrey the
Betrayer** (Start of Game: overdraw becomes free card advantage). Two known
shapes: the "big" consensus build and a cheaper "cycle" build — see
lists/v01 and collection.md. Project started week 1 of Escape from Violet
Hold, when the archetype was at 44% winrate — the job is to beat that.

## Card facts: hearthstone-oracle MCP only

Use the `hearthstone-oracle` MCP for **all** card facts — card text, mana cost,
stats, rarity, set legality, deck-code decode/encode, curve breakdowns, and
archetype analysis. **Never state card details from memory**; cards get changed
by balance patches and memory goes stale.

Tool gotchas learned so far:

- `get_card` fuzzy matching often returns the HERO_SKINS (portrait) version of a
  named character instead of the collectible card. Cross-check with
  `search_cards` (supports `type`, `player_class`, `mana_cost` filters) and pick
  the collectible version whose cost matches.
- `search_cards` summaries truncate long card text. Get full text via `get_card`
  or by searching distinctive text substrings.

## Meta data: web search, always date-checked

The Oracle has **no meta data**. For winrates, matchup tables, popularity, and
mulligan stats, web-search **HSReplay.net** and **ViciousSyndicate.com** (vS
Data Reaper Report). **Always check the publication date** — balance patches
invalidate meta data fast. If a source predates the latest patch, say so and
discount it. HSGuru (hsguru.com / d0nkey.top) proved the best live archetype
source in week-1 conditions when vS hadn't published yet.

## Working style

- **Lead with the decision, then the reasoning.** Adam often reads on mobile —
  short lines, verdict first.
- Every proposed change states: **card in / card out / why / curve delta.**
- **Always end a decklist with the deck code.**
- **Push back** if a card Adam likes is bad. Say why with Oracle facts and meta
  data, then let him overrule.
- **Don't restate all cards when only 2 changed** — show the diff.
- **Flag dust cost** on anything not checked in collection.md, and offer a
  substitute he does own.

## Session workflow

1. Read this file, [collection.md](collection.md), the newest file in
   [lists/](lists/), and [log.md](log.md).
2. Check the log for what the deck is actually losing to before proposing
   changes.
3. New versions go in `lists/` as `vNN-short-description.md` with: deck code,
   what changed, why, and the date.
4. After ladder sessions, results go in `log.md`.
