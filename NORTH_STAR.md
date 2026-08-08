# North star — the platonic ideal version of eyeland.cards

One sentence: an open-world card-combat MMORPG — Wizard101's spell-duels, Hearthstone's deckbuilding, Pokemon's open world, across a floating archipelago called the Eyeland — built one honest rung at a time (v0 Duel to v4 Online), never faked.

## The offer
- Who it's for: card-game and MMO players who want the deckbuilding depth of Hearthstone with an explorable world layered on top, plus (eventually) recruiters/HSReplay-style employers who value the tooling as portfolio proof.
- What they get: today, a pre-launch landing page and a playable terminal card-duel core (three real cards: Ember Bolt, Tidewisp, Eye of the Storm) that proves the combat loop is fun before any engine/editor time is spent. Later rungs add real decks, the archipelago overworld, and an online layer.
- What it costs: nothing yet — no priced offer exists. This is pre-revenue, build-ladder stage.

## What this is NOT (scope guard)
- Not a finished MMO — the build ladder is v0 Duel -> v1 Deck -> v2 Island -> v3 World -> v4 Online, and skipping rungs (e.g. jumping straight to Unity/overworld work) is explicitly against the project's own plan.
- Not ready to monetize — no deckbuilding, no overworld, no online layer exist yet; do not build a payment flow before there is a game worth paying for.
- Not the same thing as the `hearthstone/` Rafaamlock ladder project living in this repo — that is a separate deckbuilding-meta tool, not the MMORPG itself.

## Progress ladder (fact-based, not vibes)
- [x] 0. Core loop works — the actual product function runs end to end for a real user
- [ ] 1. Discoverable — sitemap, robots, meta description
- [ ] 2. Tracked — analytics wired in code AND confirmed live
- [ ] 3. Instrumented — named funnel events beyond raw pageviews
- [ ] 4. Payable — real automated checkout, not mailto or invoice-only
- [ ] 5. Converted — at least one verified stranger sale

**Progress: 1/6 (17%)**

Notes: for a game this early, stage 0 is about whether a playable card-duel core exists, not a finished game. It does: `game/src/Eyeland.Duel` is a real C#/.NET turn engine (cards, board, taunt, AI) with a playable terminal harness (`dotnet run`) and a 500-game AI-vs-AI balance simulator; `game/README.md` documents an actual bug found and fixed by playing a full 10-turn game (missing opening hand), plus an honest open finding (first-player win rate 71-73%). That is real, run, verified core-loop evidence, not a landing-page claim. Stage 1 fails because `robots.txt`/`sitemap.xml` point at the stale `eyelandcards.vercel.app` domain instead of the live custom domain, so it is misconfigured rather than genuinely discoverable. The waitlist CTA on `index.html` is a plain `mailto:` link with no capture, so stage 3 is zero. No analytics, no pricing, no sales.

## Next milestone
Fix the misconfigured `robots.txt`/`sitemap.xml` to point at the real eyeland.cards domain — the fastest fix on the board — then decide whether v1 Deck (real 40-card decks) or a real waitlist capture (replacing the mailto link) is the next build priority.
