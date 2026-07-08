<!-- BEGIN:claude-chat-continuation -->
# Continue From Claude Chats

Claude Code transcripts for this project have been indexed for Codex in `CODEX_CONTINUE_FROM_CLAUDE.md`. Read that file when the user asks to continue work from Claude, resume a Claude session, or understand what Claude already tried.
<!-- END:claude-chat-continuation -->

<!-- BEGIN:claude-codex-sync -->
# Claude/Codex sync

Before making changes, read `CLAUDE.md` in this project if it exists. It is the live handoff from Claude Code and the source of truth for current project progress, design decisions, constraints, and open tasks. Keep future progress updates there so Claude and Codex stay in sync.

If this file contains older project context that conflicts with `CLAUDE.md`, prefer `CLAUDE.md` unless the user says otherwise.
<!-- END:claude-codex-sync -->

<!-- BEGIN:imported-claude-context -->
# Imported Claude context

Copied from `CLAUDE.md` on 2026-07-08 so Codex starts with the same project context Claude Code used. Keep `CLAUDE.md` as the source of truth and refresh this block after meaningful Claude-side progress.

<!-- SOURCE: CLAUDE.md -->

# CLAUDE.md - eyeland.cards

Context for Claude Code, Codex, and humans working in this folder.

## What this is

This handoff was generated on 2026-07-08 during the new-day Claude/Codex sync.
No repo-local `CLAUDE.md` existed before this run, so this file was created from
the best available local context.

## Detected project facts

- Workspace folder: `eyeland.cards`
- Git repository: yes
- Detected stack: static HTML
- HTML title: eyeland.cards — open-world card-combat MMORPG
- Notable top-level files: .gitignore, favicon.svg, index.html, README.md

## 2026-07-08 Codex landing page update

- `index.html` was tightened for ASAP prelaunch/itch.io use:
  - Hero now leads with `eyeland.cards` as the product name.
  - Above-the-fold copy says `Unity pre-alpha` and `itch.io build next`.
  - Added development status chips and a `First Build` navigation target.
  - Added a compact build ladder: `v0 Duel -> v1 Deck -> v2 Island -> v3 World -> v4 Online`.
  - Waitlist CTA now asks for the first itch.io playable link.
- Waitlist is still intentionally lightweight: it validates an email and opens a `mailto:` to `adamtpang@gmail.com`; no backend capture exists yet.
- Milanote mood-board link was provided by Adam, but the plain web fetch did not expose content in this run. Current design pass stayed grounded in the repo-local floating-islands/card-combat context.
- Verification run: `node C:\tmp\eyeland-static-check.mjs` passed. It checks inline JS parsing, local anchor targets, and required hero/build/waitlist copy.
- Visual screenshot verification was attempted but blocked by local browser/runtime availability: node_repl hit an AppData `EPERM`, bundled Playwright lacked `playwright-core`, and Chrome/Edge were not visible at common paths from the sandbox.

## Current open launch tasks

- Add the real itch.io URL once the page/build exists.
- Replace mailto with a real waitlist backend before sending traffic.
- Run a browser screenshot pass on desktop/mobile when a browser path is available.

## Imported existing context

Source: `README.md`

```markdown
# eyeland.cards

An open-world **card-combat MMORPG** — the spell-duels of Wizard101, the deckbuilding of Hearthstone, and the open world of Pokémon, set across a floating archipelago called **the Eyeland**. Built in Unity with Claude.

This repo currently hosts the **pre-launch landing page** (`index.html`), a self-contained static page deployed to Vercel.

## Status
- [x] Landing page v1
- [ ] Card-duel core — turn-based combat engine (cards as ScriptableObjects + pip/turn/resolution loop)
- [ ] Deckbuilding
- [ ] Overworld + wild encounters
- [ ] Online layer

## Build ladder
`v0 Duel → v1 Deck → v2 Island → v3 World → v4 Online` — build the game first, add the MMO layer last.

## Landing page
`index.html` is fully self-contained (no external fonts, images, or scripts). Open it directly in a browser, or deploy the repo root to any static host.
```

## How to keep this useful

- Update this file when Claude or Codex learns new project facts.
- Keep `AGENTS.md` synchronized so Codex sees the same context inline.
<!-- END:imported-claude-context -->
