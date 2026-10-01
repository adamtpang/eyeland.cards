# eyeland.cards: Summon status

<!--
summon-status-version: 1
canonical-template: summon.company/templates/STATUS.md
update-rule: Change claims only when dated evidence changes.
-->

**As of:** 2026-08-29  
**Repository:** `eyeland.cards`  
**Public surface:** https://eyeland.cards  
**Lifecycle:** Playable pre-alpha, pre-monetization  
**Overall status:** The duel and deckbuilding foundations are real, but fun, balance, and repeat play have not been proven with external players.

## Perfect version

eyeland.cards becomes an open-world card-combat MMORPG by climbing an honest build ladder: a fun duel, meaningful deckbuilding, one explorable island, a connected world, and only then an online layer across the floating Eyeland archipelago.

### Company outcome

- **Buyer or user:** Card-game and MMO players who want Hearthstone-style deckbuilding inside a Wizard101-like duel and Pokemon-like world.
- **Painful problem:** Existing games separate deep card construction from a persistent world worth exploring.
- **Transformation:** The player builds a personal deck, masters readable tactical duels, explores the Eyeland, and returns because the loop stays surprising and fair.
- **Proof that would make this undeniable:** External players complete repeated duel and deck sessions, report that the loop is fun, and show improving balance and return-play evidence.

## Current truth

The project reports progress 2 of 6. A portable C# turn engine, terminal harness, AI, balance simulator, and tested 70-card Unity deckbuilder-to-duel flow exist. The landing is discoverable. Analytics, named funnel events, real waitlist capture, pricing, and sales do not exist. This is intentional: the project’s own scope guard rejects monetizing or building the online layer before there is a game worth returning to.

### Verified evidence

- `game/src/Eyeland.Duel` implements cards, board, taunt, turns, and AI.
- A full ten-turn play session exposed and fixed a missing opening-hand bug.
- The 500-game simulator reports a still-open first-player win rate around 71 to 73 percent.
- The README records a tested 70-card deckbuilder-to-duel flow.
- The public waitlist remains a `mailto:` link, and `EVIDENCE.md` contains no player, usage, or revenue receipt.

### Revenue chain

Revenue requires all three links to be true at once.

| Link | Status | Evidence |
| --- | --- | --- |
| Offer: real, priced, payable | MISSING | No priced offer exists by design. |
| Reach: shown to a real stranger | MISSING | No external playtest or real waitlist receipt is recorded. |
| Convert: a real stranger paid | MISSING | No checkout or sale exists. |

## One binding constraint

**Prove that the duel-and-deck loop is fun and sufficiently balanced for real players.**

Analytics, monetization, overworld scope, and online architecture should wait until repeated external play shows that the current core deserves expansion.

## Summon company gates

| # | Gate | Status | Project-specific evidence or gap |
| ---: | --- | --- | --- |
| 1 | Outcome | PASS | The game fantasy and staged build ladder are explicit. |
| 2 | Evidence | PARTIAL | Internal play and simulation evidence exist; external player evidence does not. |
| 3 | Workspace | PASS | Landing, C# duel core, Unity deckbuilder, simulator, and design research exist. |
| 4 | Organization | PARTIAL | Project relationships are declared; no active production team is evidenced. |
| 5 | Skills | PASS | Duel execution, deckbuilding, AI simulation, and research distillation exist. |
| 6 | Runtime | PARTIAL | Local playable paths exist; no public playable build is documented. |
| 7 | Governance | PASS | The no-fake-MMO and no-premature-monetization scope guard is explicit. |
| 8 | Critical path | PASS | Duel, deck, island, world, online is an ordered ladder. |
| 9 | Execution | PARTIAL | Duel and deck rungs execute; island and later rungs do not. |
| 10 | Verification | PARTIAL | Tests and simulation exist; player fun and retention are unverified. |

Status vocabulary: `PASS` is backed by evidence, `PARTIAL` has a real beginning but a named gap, `MISSING` has no verified implementation, and `HELD` awaits an explicit board decision or external input.

## Personalized roadmap

### Now

1. Define the v1 Deck playtest receipt, including match completion, rematch intent, confusion points, and balance measures.
2. Reduce the first-player advantage without obscuring the current baseline.
3. Package the smallest locally playable duel-and-deck build for review.

### Next

1. Let a small external test group play without coaching; Adam handles every invitation manually.
2. Record sessions, rematches, deck changes, losses, and qualitative fun evidence.
3. Decide whether the next rung is more duel depth or the first island based on the receipts.

### Later, only after evidence unlocks it

1. Ship an itch.io build and replace the mailto waitlist with consented capture.
2. Add the overworld only after the duel-and-deck loop earns repeated play.
3. Add payment and online architecture only after a game worth paying for exists.

## Core 8 focus

| Department | Current responsibility |
| --- | --- |
| Engineering | Fix balance defects and keep the duel core portable and tested. |
| Design | Own card readability, deck decisions, counterplay, and fun evidence. |
| Marketing | Show honest playable progress, not MMO-scale promises. |
| Sales | No sales motion until player value exists. |
| Finance | Avoid online infrastructure or monetization spend before proof. |
| Operations | Run repeatable playtests and preserve the build ladder. |
| Support | Capture player confusion, bugs, frustration, and rematch intent. |
| Legal | Protect research attribution, player privacy, and platform permissions. |

## Board gates

Adam must authorize every external playtest invitation, public build, itch.io publication, analytics addition, payment rail, provider spend, and deployment. The existence of a landing page does not authorize monetization.

External messages, publication, deployment, spending, contracts, payment changes, refunds, destructive actions, and new commitments remain human-authorized. Drafts and reversible internal work do not imply permission to perform the external action.

## Sources of truth

- `repos.yaml`
- `NORTH_STAR.md`
- `EVIDENCE.md`
- `OFFER.md`
- `README.md`
- `CLAUDE.md`
- `game/README.md`
- `game/DESIGN.md`

## Update contract

- Keep exactly one binding constraint.
- Record facts, dates, receipts, and test results. Do not turn activity into evidence.
- Self-use proves personal utility, not market demand. Label both honestly.
- A draft is not reach. A checkout visit is not conversion. A self-payment is not stranger revenue.
- Change the roadmap when evidence changes, not because another feature sounds exciting.
- Preserve this company’s specific buyer, workflow, risks, and personality. The template is shared; the company is not generic.

