# Hearthstone AI deckbuilding partner

Help build and refine my own decks using my collection, verified card
synergies, and current meta evidence. **Current use case: Egg Priest.**
Read [PRODUCT.md](PRODUCT.md) for the deck-design review requirements and
implementation boundary. The Rafaam Warlock lists remain historical work.

## Files

- **CLAUDE.md**: context for Claude Code sessions (rules, tools, working style)
- **collection.md**: checklist of which relevant cards I own
- **lists/**: versioned decklists: deck code + what changed + why
- **log.md**: ladder results table + self-diagnosis note

## Kicking off a session

Run the collection-aware deck report first:

```powershell
node hearthstone/scripts/deckbuilder.mjs
```

It decodes the newest list in `lists/`, compares every collectible card with
`collection-full.json`, calculates missing dust and the mana curve, and shows
owned replacement shortlists. To generate a grounded packet for Claude or
Codex:

```powershell
node hearthstone/scripts/deckbuilder.mjs --prompt
```

Other useful inputs:

```powershell
node hearthstone/scripts/deckbuilder.mjs --deck-code "PASTE_CODE"
node hearthstone/scripts/deckbuilder.mjs --deck hearthstone/lists/v01-consensus-godfrey-rafaamlock.md --json
node --test hearthstone/scripts/deckbuilder.test.mjs
```

Then start a session with something like:

> "Read the project files. Here's my latest ladder session: …", paste results,
> then ask for changes.

Or:

> "Check HSReplay/vS for the current meta and tell me if the list needs to
> adapt."

Claude will pull card facts from the hearthstone-oracle MCP, meta data from the
web (date-checked), propose changes as card in / card out / why / curve delta,
and end with a deck code.

## Maintenance

### Live personal product test (2026-09-10)

With HSReplay signed in through Helium, run:

```powershell
./hearthstone/scripts/test-my-decks.ps1
```

This captures the collection and deck-statistics requests observed on the real
HSReplay pages, validates permanent versus trial copies, refreshes local card
definitions, and compares current-patch decks with permanent ownership.
Results are private in `scripts/.cache/self-test.md` and `self-test.json`.
Source timestamps and rank/region/time filters are retained. No login secrets
are saved. Helium may need one manual remote-debugging approval.

First test: 249 source decks, 9 exact zero-craft matches, one candidate passing
the trial screen (500+ games and over 50% observed wins). HSReplay independently
showed that candidate's personal crafting cost as zero. This is a manually run
local pipeline, not a hosted AI service or proof of competitive performance.

Limitations: exact-ID ownership may undercount equivalent reprints; sideboard
decks are excluded from trial recommendations; independent Oracle and in-game
legality verification remain necessary. The accessible snapshot was Standard,
Bronze–Gold, all regions, current patch. vS report #356 was manually reviewed as
pre-patch qualitative background; automated vS ingestion is not implemented.

Tests: `node --test hearthstone/scripts/*.test.mjs`.

- Refresh the generated collection files with
  `node hearthstone/scripts/refresh-collection.mjs`; do not hand-edit their
  ownership state.
- Log every ladder session in `log.md`: the log drives the iteration.
- Never delete old lists in `lists/`; they're the changelog.
