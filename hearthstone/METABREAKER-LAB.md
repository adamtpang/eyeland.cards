# Collection-only metabreaker research

Confirmed direction: 2026-09-12. Adam wants AI-assisted original deckbuilding: discover overlooked package combinations that outperform the current field, with reaching #1 Legend an aspiration. Zero crafting unless explicitly authorized. Prefer pairs of non-Legendaries. Prefer coherent engines with permanent or compounding progress. This document specifies a workflow; it is not evidence of an implemented autonomous optimizer or a discovered winning deck.

## Historical evidence

- FunkiMonki's Libroom Paladin: vS #173 (September 17, 2020) explicitly credits him as pioneer. Neutral draw via Salhet's Pride/Loot Hoarders improved consistency; Animated Broomstick added comeback potential. It was not Tier 1 at this initial report. https://www.vicioussyndicate.com/vs-data-reaper-report-173/
- vS #174 (September 24, 2020) identifies Priest/Mage as remaining weaknesses and discusses potential to become the best deck if improved. This supports emergence and refinement, not a timeless #1 claim. https://www.vicioussyndicate.com/vs-data-reaper-report-174/
- Garrote Contact Rogue: vS #206 (September 9, 2021) distinguishes the Field Contact engine from Auctioneer builds and describes Orange/Fr0zen's tournament success, a misunderstood game plan, and initially unimpressive aggregate results. https://www.vicioussyndicate.com/vs-data-reaper-report-206/
- Naga Priest: vS #238 (August 11, 2022) describes a strong but unpopular deck and improvements from maintaining Naga density, Cathedral and Boon. https://www.vicioussyndicate.com/vs-data-reaper-report-238/
- Libroom counter adaptation: vS #182 (December 24, 2020) describes adapting to Evolve Shaman without sacrificing too much elsewhere. https://www.vicioussyndicate.com/vs-data-reaper-report-182/

## Research loop

1. Freeze a dated collection snapshot, legal card definitions and rank-specific opponent distribution. Reject missing cards before ranking candidates; account for generated/Fabled cards and sideboards correctly.
2. Keep a measured owned baseline. Public deck matching is retrieval, not original deck search; no exact owned matches does not imply no strong build exists.
3. For each candidate package, document its enablers, payoffs, consistency, and failure mode. Search all legal owned cards for a fix, including unfamiliar neutral cards.
4. Generate at most three coherent variants. Each needs an exact code, changed pairs, ownership validation, a specific matchup hypothesis, and what it sacrifices. Never attach a parent deck's win rate to a variant.
5. Rank hypotheses by expected field-weighted performance: sum(opponent share * matchup win probability), with uncertainty and provenance retained. Novelty is a tie-breaker; surprise alone is not durable strength.
6. Use probability calculations for draw consistency. Do not present language-model imagined matches as simulated evidence. Game simulations require a validated rules engine and credible opponents.
7. Adam plays the candidates. Record version, rank, matchup, result, key turn and stranded cards; distinguish sequencing errors from structural failures. Short trials diagnose failures, not establish superiority.
8. Compare finalists and baseline in interleaved sessions in the same patch/rank. Preserve held-out validation games; repeated selection of the luckiest list inflates apparent win rates. Expand testing only for candidates with a plausible and observed edge.

## First experiment

Use the original fully owned Egg Warrior as baseline (lists/v04-owned-egg-warrior-sep12.md). Obtain actual ranked losses before choosing the limiting matchup or altering the engine. No craft, no automatic ladder play, no new deck-strength claim yet. The measured Gold result does not establish Diamond strength. Investigate owned pair substitutions only after identifying a recurring failure mode; do not assume that maximizing rarity or adding Legendaries helps.

## Candidate report contract

- Hypothesis and target opponents
- Verified interaction that enables the advantage
- Exact owned 30-card list/code and sideboard, if any
- Changes, curve impact and zero-dust check
- What gets worse
- Measured results vs estimates vs unknowns
- Next playtest and a condition that would reject the idea

