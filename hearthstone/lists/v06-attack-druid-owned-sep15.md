# Attack Druid: best owned build, zero dust

2026-09-15. Proposed test, not performance-validated.

Built from two sources: the 16 Attack Druid lists from the 2026 World
Championship (HSGuru Worlds page) and HSGuru's Top 1k Attack Druid card stats
(past week, 11,967 games). Every card is owned in the 2026-09-12 collection
snapshot. 0 dust. Every non-Legendary is paired (Adam's rule, restated
2026-09-15: no single copies of a non-Legendary, so the original lone Rustrot
Viper was replaced).

Elise needs 10 distinct costs. Without a 3 or an 8, the list has 9. Two
variants fix that; both are 30 cards, round-trip checked, and have no
non-Legendary singles.

## Variant B, recommended: 2 Feral Rage (costs 0-7, 9, 10)

```text
AAECAZICBqn1BqyIB4KYB+DAB+XEB6PaBwyunwS4oASqrwesrwfosQe+sgfXwAfk2QeR2gfH5ge85wfK5wcA
```

Changes from the table below: -1 Rustrot Viper, -1 Amirdrassil, +2 Feral Rage.
Feral Rage (3, Choose One: +4 hero Attack this turn, or gain 8 Armor) feeds the
engine: Staff of Trickery discounts by hero Attack, Spider Rider draws and
Infest the Scullery improves after hero attacks; the armor mode covers
aggressive matchups. Cost: Amirdrassil is in all 16 Worlds lists, though its
Top 1k drawn impact is 0.0. No HSGuru data exists for Feral Rage in this deck.

## Variant A: 1 Mister Clocksworth (costs 0-2, 4-10)

```text
AAECAZICCKn1Bq+HB6yIB4KYB8auB+DAB+XEB6PaBwuunwSqrwesrwfosQe+sgfXwAfk2QeR2gfH5ge85wfK5wcA
```

Changes from the table below: -1 Rustrot Viper, +1 Mister Clocksworth (8,
Legendary, Rewind x3, Battlecry: summon 2 random Legendary minions). Keeps
every Worlds-universal card, but adds a third expensive, random top-end card.
No HSGuru data for it in this deck either.

Superseded original code (had a single Rustrot Viper):
`AAECAZICCM2eBqn1Bq+HB6yIB4KYB+DAB+XEB6PaBwuunwSqrwesrwfosQe+sgfXwAfk2QeR2gfH5ge85wfK5wcA`

## List

| Cost | Card | Copies | Top 1k drawn impact |
|---:|---|---:|---:|
| 0 | Innervate | 2 | +2.4 |
| 0 | Secret Ingredient | 2 | +1.7 |
| 1 | Spiderling | 2 | +2.4 |
| 1 | Waveshaping | 2 | +0.7 |
| 2 | Felwood Treant | 2 | +2.3 |
| 2 | Acceleration Aura | 2 | +0.4 |
| 2 | Ebb and Flow | 2 | +1.1 |
| 2 | Press the Advantage | 2 | +0.5 |
| 2 | Spider Rider | 2 | +0.3 |
| 2 | Widow's Bite | 2 | +0.7 |
| 3 | Rustrot Viper | 1 | -1.1 |
| 4 | Staff of Trickery | 1 | +2.7 |
| 4 | Elise the Navigator | 1 | +1.7 |
| 5 | Infest the Scullery | 2 | +1.9 |
| 5 | Amirdrassil | 1 | 0.0 |
| 6 | Wickerfang | 1 | +2.0 |
| 7 | Bashana Runetotem | 1 | +0.6 |
| 9 | Ysera, Emerald Aspect | 1 | -0.4 |
| 10 | Fyrakk the Blazing | 1 | +0.6 |

## Versus the pro lists

- Out, not owned: Shaladrassil (+1.3), Merithra (-0.5), Xavius.
- Out by data: Horn of Plenty (-2.0), Lifebloom (negative in Diamond).
- Out: Naralex. It discounts Dragons, and this list runs only two.
- In: 2 Widow's Bite (+0.7), used by the Hyosung/Kwanuu/Che0nsu list.
- Ysera over Lifebloom at 9 (-0.4 vs -0.8 Diamond). Rustrot Viper stays only
  to enable Elise.

## Playtest question

Log 10 games: matchup, result, and whether Spiderling or Felwood Treant was in
the opening hand. If losses cluster in games without an early engine card, the
problem is mulligans. If they cluster by opponent class, the problem is the
matchup and the flex slots.
