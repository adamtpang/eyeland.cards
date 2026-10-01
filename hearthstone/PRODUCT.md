# Collection-aware AI deckbuilding partner

## Metabreaker discovery direction (2026-09-12)

Adam wants original, AI-assisted competitive deck discovery within his owned
collection, inspired by FunkiMonki's Libroom Paladin. Zero crafting unless
explicitly authorized; favor paired non-Legendaries and coherent compounding
engines. Read `METABREAKER-LAB.md` for the sourced history, candidate evaluation
contract and human playtest loop. Retrieval of existing owned lists is only a
baseline, not the intended endpoint. An autonomous discovery/testing system
is not implemented by this documentation update; #1 Legend is an aspiration,
not a promised outcome.

## Confirmed use case: Egg Priest (2026-09-10)

Adam wants help building and refining his own deck. The current working deck
is Egg Priest; obtain its exact code before making card-specific judgments.
Rafaam Warlock remains historical context, not the default for this review.

Adam prefers full pairs of non-Legendary cards, not singleton tech choices.
Recommend two-for-two swaps by default; Legendaries remain one copy. Preserve
the two Doomsayers, two Holy Eggbearers, and Shield's cycling role in the current
Egg Priest review unless Adam changes that direction.

The core product takes a player's deck, intended strategy, full permanent
collection, format, rank, and crafting budget. It explains how the deck works,
finds useful synergies, diagnoses conflicting or unsupported choices, and
recommends concrete changes while preserving the player's intended identity.

## What a useful review delivers

1. State the intended win condition and the sequence of plays supporting it.
2. Explain the synergy packages: enablers, targets, payoffs, and redundancy.
   Verify actual card interactions, not just shared keywords or mana costs.
3. Identify structural problems: cards stranded without support, too many
   payoffs for too few enablers, conflicting effects, weak early turns,
   insufficient draw, recovery, interaction, or ability to finish games.
4. Search the full owned collection for relevant alternatives, including cards
   absent from popular lists. Do not restrict candidates to sets already in
   the input deck or treat same-cost replacements as strategic substitutes.
5. Propose a small, explained revision: card out / card in / why / curve delta,
   ownership, crafting cost, and the tradeoff introduced by each change.
6. Separate verified interactions, dated meta observations, and untested design
   hypotheses. A popular card's win rate does not prove it improves this deck;
   never attach an unchanged source list's win rate to a custom revision.
7. Return a verified import code and a concrete playtest question. Review
   actual match results before claiming the revision performs better.

HSReplay and Vicious Syndicate provide context for opponents and established
lists. Meta ranking is one input to the player's deck-design review.

## Current implementation boundary

The local pipeline refreshes collection and HSReplay deck data and produces
ownership comparisons. Its replacement shortlists use simple heuristics.
The chat assistant can perform a source-grounded review when the deck and
card-verification tools are available. An integrated AI synergy-analysis and
deck-revision loop is not implemented yet. vS ingestion remains manual.

## First acceptance test

Use Adam's actual Egg Priest code. Identify one supported design issue or
explicitly conclude that no change is justified. If a change is warranted,
produce a minimal revision using owned cards where possible, explain the
interaction it improves, validate the resulting deck, and have Adam test it.
Success means useful, accurate help with his chosen deck, not merely selecting
a different archetype with a higher published win rate.
