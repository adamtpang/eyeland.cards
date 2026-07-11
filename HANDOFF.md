# HANDOFF.md — eyeland.cards

Continuation context for Claude Code / Codex sessions. Updated 2026-07-11
(originally written earlier the same day; the Hearthstone project has since
**moved into this repo** — read this file after `CLAUDE.md` when resuming).

## What this repo is

**eyeland.cards is Adam's game project**, in two phases:

1. **Now — Hearthstone tooling**, in [`hearthstone/`](hearthstone/): a
   competitive Rafaam (Timethief) Warlock deckbuilding project. Start every
   Hearthstone session by reading `hearthstone/CLAUDE.md` — it has the working
   rules (oracle MCP for all card facts, date-checked web meta only,
   decision-first mobile-friendly replies, card in/out/why/curve delta, end
   with deck code, dust-flag unowned cards).
2. **Later — the original game.** Open-world card-combat MMORPG (Wizard101
   spell-duels × Hearthstone deckbuilding × Pokémon open world), built in
   Unity with a Unity MCP. Build ladder:
   `v0 Duel → v1 Deck → v2 Island → v3 World → v4 Online`.
   The Hearthstone work is deliberate practice: archetypes, curve theory,
   card economy, ladder-driven iteration all feed the card-duel core design.

## Career angle (noted 2026-07-11)

**HSReplay is hiring.** Building on their platform is a real opportunity, and
this repo's Hearthstone tooling doubles as a portfolio piece for an
application. Caveat from Adam: their platform is more **Battlegrounds**-focused,
which is not what he plays — his work is constructed Standard. Keep this in
mind if tooling choices could tilt toward something HSReplay-relevant
(deck-code tooling, meta trackers, collection analysis).

## State of the Hearthstone project (as of 2026-07-11)

Set up today, fully verified via the hearthstone-oracle MCP + meta research
(9-agent workflow, ~475 tool calls, sources date-checked):

- **Archetype:** "Rafaamlock" (HSGuru's name) — Timethief Rafaam + Godfrey the
  Betrayer, 40-card Warlock. Week 1 of Escape from Violet Hold (patch 36.0,
  live 2026-07-07). Archetype at **44.2% WR / 37,274 games** (HSGuru,
  Diamond–Legend); farms Priest (69%)/DH/DK, folds to Hunter (35%) and Rogue
  (38%, 22.5% of field). First Violet Hold vS Data Reaper Report not yet
  published — re-pull meta before big decisions.
- **`hearthstone/collection.md`** — Oracle-verified checklist of every card in
  current Rafaamlock lists, grouped by cost with dust. **WAITING ON ADAM to
  check boxes.** Until then treat everything non-Core as unowned.
- **`hearthstone/lists/v01-consensus-godfrey-rafaamlock.md`** — the consensus
  big build (#431 Legend 7-5; 45.1% WR/5,534 games) with Oracle-verified deck
  code. A ~3,200-dust-cheaper "cycle" variant is documented inside.
- **`hearthstone/log.md`** — empty ladder log, ready for results.
- **Key mechanic:** Timethief's 9 sibling Rafaams are uncollectible tokens that
  come with him; only Timethief (1600 dust) is ever crafted.
- **Oracle gotcha:** `get_card` fuzzy match returns HERO_SKINS portraits for
  named characters — cross-check with `search_cards` filters.

**Next actions:** Adam checks collection.md boxes → compute cheapest path to a
playable 40 → he ladders → results into log.md → iterate the list.

## Codebase / deploy state (2026-07-11)

- **Stack:** static landing page `index.html` (self-contained) + `favicon.svg`,
  now plus the `hearthstone/` markdown project.
- **Git:** branch `main`, remote `https://github.com/adamtpang/eyeland.cards.git`
  (public). `hearthstone/` + docs committed 2026-07-11 (Adam's "continue where
  needed" go-ahead) with a **`.vercelignore`** so the deployed site serves only
  the landing page — repo markdown (incl. `hearthstone/`) is NOT reachable on
  eyelandcards.vercel.app, but IS visible in the public GitHub repo (intended:
  it doubles as the portfolio surface).
- GitHub → Vercel auto-deploy on main is verified working (project
  `prj_RcKHNraIL8v3KxhPe0m5nenho7nm`, team `team_94z2L2r0X8hywHS0hi2ahkW7`).
- **Landing page:** waitlist is still a validated `mailto:` to
  adamtpang@gmail.com — no backend capture yet.

## Domain decision (2026-07-11)

**Stay on eyeland.cards** (Adam's call). If a dedicated Hearthstone domain is
ever wanted, these were available at **$1.99/yr** on Vercel domains:
`deckcode.fun` (best generic fit), `rafaam.lol`, `wellmet.fun` / `wellmet.xyz`,
`ladderlegend.xyz`. (`innkeeper.club` $29.47 — skip; curvestone.com,
topdeck.xyz, mulligan.xyz, fortycards.com, hearthdeck.com, deckslot.com,
thecoin.fun, fatigue.lol, hearth.fun all taken.)

## Open tasks

- [ ] Adam: check boxes in `hearthstone/collection.md`.
- [x] Decide: commit `hearthstone/` to the repo — done 2026-07-11, with
      `.vercelignore` (site serves landing page only; GitHub shows everything).
- [ ] Ladder + log; iterate toward >50% WR (archetype baseline is 44%).
- [ ] Add the real itch.io URL to the landing page once a playable build exists.
- [ ] Replace the `mailto:` waitlist with real backend capture before traffic.
- [ ] Later: scaffold the Unity game (v0 Duel) with a Unity MCP.
- [ ] Optional: shape one tool into an HSReplay-application portfolio piece.

## How to resume a session here

1. Read `CLAUDE.md`, then this file.
2. Hearthstone work → `hearthstone/CLAUDE.md` and follow its session workflow.
3. Game work → start at the card-duel core (`v0 Duel`) per the build ladder.
4. Landing/deploy work → check latest deployment via the Vercel MCP
   (`list_deployments` with the IDs above).
