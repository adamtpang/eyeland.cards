# Rafaam Warlock — ladder project

Deckbuilding workspace for a competitive Rafaam (Timethief) Warlock list in
current Hearthstone Standard, tuned to my collection and my ladder results.

## Files

- **CLAUDE.md** — context for Claude Code sessions (rules, tools, working style)
- **collection.md** — checklist of which relevant cards I own
- **lists/** — versioned decklists: deck code + what changed + why
- **log.md** — ladder results table + self-diagnosis note

## Kicking off a session

Open Claude Code in this folder and say something like:

> "Read the project files. Here's my latest ladder session: …" — paste results,
> then ask for changes.

Or:

> "Check HSReplay/vS for the current meta and tell me if the list needs to
> adapt."

Claude will pull card facts from the hearthstone-oracle MCP, meta data from the
web (date-checked), propose changes as card in / card out / why / curve delta,
and end with a deck code.

## Maintenance

- Check boxes in `collection.md` as the collection grows.
- Log every ladder session in `log.md` — the log drives the iteration.
- Never delete old lists in `lists/`; they're the changelog.
