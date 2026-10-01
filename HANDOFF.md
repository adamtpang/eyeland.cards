# HANDOFF.md: eyeland.cards

Continuation context for Claude Code / Codex sessions. Updated 2026-07-11
(originally written earlier the same day; the Hearthstone project has since
**moved into this repo**; read this file after `CLAUDE.md` when resuming).

## What this repo is

**eyeland.cards is Adam's game project**, in two phases:

1. **Now, Hearthstone tooling**, in [`hearthstone/`](hearthstone/): a
   competitive Rafaam (Timethief) Warlock deckbuilding project. Start every
   Hearthstone session by reading `hearthstone/CLAUDE.md`: it has the working
   rules (oracle MCP for all card facts, date-checked web meta only,
   decision-first mobile-friendly replies, card in/out/why/curve delta, end
   with deck code, dust-flag unowned cards).
2. **Later, the original game.** Open-world card-combat MMORPG (Wizard101
   spell-duels × Hearthstone deckbuilding × Pokémon open world), built in
   Unity with a Unity MCP. Build ladder:
   `v0 Duel → v1 Deck → v2 Island → v3 World → v4 Online`.
   The Hearthstone work is deliberate practice: archetypes, curve theory,
   card economy, ladder-driven iteration all feed the card-duel core design.
   **`game/`** now holds real progress on this phase: `game/README.md` (the
   v0 Duel C# engine, playable, no Unity needed) and **`game/DESIGN.md`**
   (concrete design rules distilled from researched origin stories of the
   greatest games; read before designing any new card, boss, or system).
   `game/unity/` is a real Unity 6 project with the MCP-for-Unity bridge wired
   in. This repo's own root `CLAUDE.md`/this file predate that work; treat
   `game/README.md` and `game/DESIGN.md` as more current on anything they
   cover.

## Career angle (noted 2026-07-11)

**HSReplay is hiring.** Building on their platform is a real opportunity, and
this repo's Hearthstone tooling doubles as a portfolio piece for an
application. Caveat from Adam: their platform is more **Battlegrounds**-focused,
which is not what he plays; his work is constructed Standard. Keep this in
mind if tooling choices could tilt toward something HSReplay-relevant
(deck-code tooling, meta trackers, collection analysis).

## State of the Hearthstone project (as of 2026-07-11)

Set up today, fully verified via the hearthstone-oracle MCP + meta research
(9-agent workflow, ~475 tool calls, sources date-checked):

- **Archetype:** "Rafaamlock" (HSGuru's name): Timethief Rafaam + Godfrey the
  Betrayer, 40-card Warlock. Week 1 of Escape from Violet Hold (patch 36.0,
  live 2026-07-07). Archetype at **44.2% WR / 37,274 games** (HSGuru,
  Diamond–Legend); farms Priest (69%)/DH/DK, folds to Hunter (35%) and Rogue
  (38%, 22.5% of field). First Violet Hold vS Data Reaper Report not yet
  published; re-pull meta before big decisions.
- **`hearthstone/collection.md`**: Oracle-verified checklist of every card in
  current Rafaamlock lists, grouped by cost with dust. **WAITING ON ADAM to
  check boxes.** Until then treat everything non-Core as unowned.
- **`hearthstone/lists/v01-consensus-godfrey-rafaamlock.md`**: the consensus
  big build (#431 Legend 7-5; 45.1% WR/5,534 games) with Oracle-verified deck
  code. A ~3,200-dust-cheaper "cycle" variant is documented inside.
- **`hearthstone/log.md`**: empty ladder log, ready for results.
- **Key mechanic:** Timethief's 9 sibling Rafaams are uncollectible tokens that
  come with him; only Timethief (1600 dust) is ever crafted.
- **Oracle gotcha:** `get_card` fuzzy match returns HERO_SKINS portraits for
  named characters; cross-check with `search_cards` filters.

**Next actions:** Adam checks collection.md boxes → compute cheapest path to a
playable 40 → he ladders → results into log.md → iterate the list.

## Codebase / deploy state (2026-07-11)

- **Stack:** static landing page `index.html` (self-contained) + `favicon.svg`,
  now plus the `hearthstone/` markdown project.
- **Git:** branch `main`, remote `https://github.com/adamtpang/eyeland.cards.git`
  (public). `hearthstone/` + docs committed 2026-07-11 (Adam's "continue where
  needed" go-ahead) with a **`.vercelignore`** so the deployed site serves only
  the landing page; repo markdown (incl. `hearthstone/`) is NOT reachable on
  eyelandcards.vercel.app, but IS visible in the public GitHub repo (intended:
  it doubles as the portfolio surface).
- GitHub → Vercel auto-deploy on main is verified working (project
  `prj_RcKHNraIL8v3KxhPe0m5nenho7nm`, team `team_94z2L2r0X8hywHS0hi2ahkW7`).
- **Landing page:** waitlist is still a validated `mailto:` to
  adamtpang@gmail.com; no backend capture yet.

## Domain decision (2026-07-11)

**Stay on eyeland.cards** (Adam's call). If a dedicated Hearthstone domain is
ever wanted, these were available at **$1.99/yr** on Vercel domains:
`deckcode.fun` (best generic fit), `rafaam.lol`, `wellmet.fun` / `wellmet.xyz`,
`ladderlegend.xyz`. (`innkeeper.club` $29.47, skip; curvestone.com,
topdeck.xyz, mulligan.xyz, fortycards.com, hearthdeck.com, deckslot.com,
thecoin.fun, fatigue.lol, hearth.fun all taken.)

## Open tasks

- [ ] Adam: check boxes in `hearthstone/collection.md`.
- [x] Decide: commit `hearthstone/` to the repo, done 2026-07-11, with
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

## 2026-09-11: Ember Reach local playable prototype

The default Unity boot now opens a connected solo expedition: three camps and a Warden, timed real-engine duels, defeated-creature card rewards, ember shards, owned 12-card deck editing and browser-local saves. Common/Rare/Epic/Legendary are represented. The route is an encounter menu with seeded supporting cards and shuffles; a walkable 3D island, crafting recipes and multiplayer are still not implemented.

Play instructions: game/PLAY-EMBER-REACH.md. Local URL: http://127.0.0.1:8765/ while the server runs; restart with game/scripts/play-ember-reach.ps1. Build with game/scripts/build-ember-reach.ps1. Unity 6000.5.7f1 plus WebGL was restored under Adam's AppData/Local/EyelandTools; see game/LOCAL-UNITY-RUNTIME.md. Production was not deployed.

MVP-READINESS.md records 100/100 for the fixed local technical scope: final 10/10 Unity tests, a four-encounter UI-handler journey, 400 terminating engine simulations, and native Helium first victory -> reward -> deck edit -> reload -> earned card in next duel. The full four-fight journey was not played through native browser input. Human enjoyment and session length remain unvalidated. MVP-NEXT-PROMPT.md starts with Adam's unaided playtest; preserve prior research and unrelated working-tree changes.

## 2026-09-11: creature artwork and identity clarification

Adam asked for illustrated collectible minions and reaffirmed creature collection, resources/crafting, RPG progression and multiplayer questing. Read game/EYELAND-IDENTITY.md for direction versus implemented scope. Eight expedition creatures received original built-in image_gen portraits in game/unity/Assets/Resources/Art/Creatures; exact prompts are in game/CREATURE-ART-PROMPTS.json. CardVisual.cs adds portrait rendering, cost/stat labels and non-intercepting hover/focus inspection to hand, battlefield and deck builder. Card mechanics and saved deck IDs are unchanged. Existing 10 Unity tests pass (game/card-art-tests.xml); see the subsequent visual verification entry for WebGL evidence.

### Creature visual pass verification (2026-09-11)

Final WebGL build: 2026-09-11T07:53:20Z; wasm SHA256 ECD6CCE78291B1BCE8A5A2789DF3F94F76FF02C087849371CCD39BA0BE50FF5B. This supersedes the earlier build fingerprint. Build succeeded; the ten existing Unity PlayMode tests passed with CardVisual integration before the final log-line/status-label layout adjustment. Final browser verification used native Helium input: persisted deck loaded, portrait hover inspection, summon Glowing Ember, end turn, select attacker and target face. Opponent health fell from 19 to 18 on summon and to 17 after the attack. Inspected 1280x720 and 1920x1080. Evidence: game/evidence/card-art-2026-09-11/{wolf-inspect,final-board,final-target,final-attack,final-1920}.png. Final events contain no Runtime.exceptionThrown or console error. The combat log now displays the two most recent lines to fit its smaller region. Full rules remain available through hover/focus inspection; spells retain an element-colored SPELL visual. The prior full progression tests remain complementary evidence; this presentation pass did not repeat an entire native four-fight expedition. Server remains at http://127.0.0.1:8765/. Refresh an already-open game to load the new build; completed progress is preserved, unfinished fights restart.

## GDC learning (2026-09-12)

Read `game/GDC-LESSONS.md` before changing card progression, onboarding, combat feedback or crafting. It synthesizes three fully read available GDC transcripts plus a focused fourth-talk excerpt, with timestamp citations, source limitations and three unrun playtests. The strongest next test is an unaided victory -> earned Wolf -> intentional deck change -> useful next-fight action. Do not confuse technical readiness with human enjoyment. Resources are currently derived from clears; real crafting requires a saved expenditure ledger. The full GDC copy stays private in `knowledge-private/gdc/`, excluded from Git and Vercel. No gameplay changes or tests were executed by this research pass.
