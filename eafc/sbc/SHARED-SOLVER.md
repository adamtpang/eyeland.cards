# Shared EA FC 27 SBC solver

One solver for every daily SBC. A new challenge is a new JSON file in `specs/`. Personal club data, protect names, and the done list stay in gitignored local files.

This is a public repository. Do not commit inventory exports, FUTBIN club dumps, player profiles, protect lists, consumed-card lists, done lists, or `plan.json`.

## Install

Python 3.12 or 3.14. PuLP 3.3.x and highspy 1.15.x (highspy publishes Python 3.14 wheels).

```bash
pip install -r eafc/sbc/requirements-shared.txt
```

The default engine is PuLP / HiGHS. It does not import OR-Tools. `--engine cpsat` is an optional cross-check (`pip install -r eafc/sbc/requirements-cpsat.txt`). OR-Tools and highspy each ship a HiGHS library, and loading both in one process fails, so CP-SAT runs in a separate Python process. OR-Tools may not publish a Python 3.14 wheel; that does not affect the HiGHS path.

HiGHS is given an explicit `threads` value (default `min(8, cpu)`). Before that option is set, the process-wide HiGHS scheduler is reset, because a later solve that asks for a different thread count is otherwise rejected.

## Local files

Copy the example and point it at a folder that git already ignores:

```bash
mkdir -p eafc/sbc/local/profiles
cp eafc/sbc/shared/config.example.json eafc/sbc/shared/config.json
cp eafc/sbc/shared/protect.example.json eafc/sbc/local/protect.json
```

`config.json` paths are relative to the config file. The example expects:

| Path | What it is |
| --- | --- |
| `local/easy-inventory.json` | EasySBC inventory export (`players`, `stats`, `plat`) |
| `local/club_futbin.json` | Optional older fallback. Keys `imported`, `read`, `xi`, `players` |
| `local/profiles/player-<resourceId>.json` | EasySBC `players/{id}` profiles |
| `local/base.json` | Public `base-data` (formations and `linkedClubIds`) |
| `local/protect.json` | `{"names": ["..."]}` substrings. Saved squads have no export field; this is how those cards stay out |
| `local/consumed.json` | Optional `{"names": ["..."]}` exact pool names already submitted |
| `local/done.json` | `{"ids": [114]}` SBC ids to skip |
| `local/sets.json` | EasySBC sets export used by `import-done` |
| `local/plan.json` | Solver output. If it already exists, the next solve uses its squads as a HiGHS starting point, matched by `rid` |

The loader picks the newest existing inventory path by mtime and prints the path and timestamp. If two files share an mtime, the earlier config path wins. EasySBC is the source that knows `sbcStorage` and `activeSquad`. The FUTBIN file has no storage flag, so every card mapped from it is treated as not in SBC Storage, and XI names are treated as the active squad.

FUTBIN rows join to profiles in this order: resource id (`resourceId`, `resource_id`, or an `id` that is a known profile id), then accent-folded exact name plus rating, then a single-token short name plus rating (a row `Rafa` can match a profile `Rafa Northwind`). Club id and nation id break ties when the row has them. Ambiguous rows are not guessed. Every unmatched or ambiguous row is printed and kept with a synthetic id so it is protected as "no profile" instead of being dropped.

`transferList` and `isObjectivePlayer` are on the export and are not protection rules. The canonical solver does not read them.

## Run

```bash
python -m eafc.sbc.shared fetch --set-id 78
python -m eafc.sbc.shared fetch --players
python -m eafc.sbc.shared import-done --sets eafc/sbc/local/sets.json
python -m eafc.sbc.shared solve --secs 180
python -m eafc.sbc.shared solve --net --keep84 --ids 121,120
python -m eafc.sbc.shared solve --exact-model
python -m eafc.sbc.shared solve --engine cpsat --threads 8
python -m eafc.sbc.shared.benchmark --secs 60
```

`--secs` defaults to 180 and is the limit for each stage of a lexicographic solve. `--jobs` defaults to `min(8, cpu)` and solves pending SBCs in separate processes against the starting inventory, then accepts them from highest chemistry to lowest. A squad that needs a card an earlier SBC took is solved again on what remains, so the objective matches the sequential run. Equal-cost cards can still swap. `--exact-model` stays sequential and uses the previous per-card model.

Each SBC line prints engine, objective mode, HiGHS or CP-SAT status, pool size, cash, fodder, chemistry, objective, best bound, and MIP gap. `plan.json` stores the same fields. A feasible time-limit stop stays `TimeLimit` unless the gap is effectively zero. For the default objective the gap is on coins if stage 1 did not prove, and on fodder if coins are proven and stage 2 is not. `gap_metric` says which.

Specs are solved from highest chemistry to lowest. Equal chemistry uses the `sequence` field, which on the committed files is the original list order. Ids in `done.json` are skipped before that.

## Rules that match the canonical solver

* Usable owned cards are normal versions (`versionId` 0 or 1) that survive protection. Copies of one `resourceId` can be used once per SBC, then the leftover copy is available to the next SBC.
* Protect order: special/loan, protect-file substring, active squad, missing profile, then with `--net` any 84+, then with `--keep84` club 84+ (storage copies stay in), then with `--keep84` inventory `price` above 2000, then chem-3 meta >= 85 unless the card is in SBC Storage.
* Chem-3 meta is the max `metaRating` whose `chemistry` is 3. Storage cards skip that rule.
* Market cards enter the pool only under the price cap (1300, or 6000 for club ids 131681 and 131682 after linked-club merge). Owned cards skip the cap. The objective price is the profile `priceInfo.displayPrice`, not the inventory price. The keep84 "above 2000" check uses the inventory price.
* Trim keeps unused owned cards at or above `minr`, anchor-club cards, the 4 cheapest market cards per (league, nation), the 14 cheapest per league, and 25 cheapest of a required nation. There is no extra club or nation bucket, and an owned card is not force-kept once its remaining count is 0.
* Chemistry steps are club 2/4/7, league 3/5/8, nation 2/5/8, in-position only, max 3. Out-of-position cards add 0. This is not the club 2/5/8 table in the older FUTBIN checker `solve.py`.
* Team-rating text on Liverpool v Arsenal is still the raw rating sum of 825. New specs can also set `team_rating_min`, `rating_floors`, and `item_score_floors` (see below). The raw sum does not use the squad-rating formula.

Committed specs are the canonical ids 118, 119, 120, 121, 114, and 75. Slots for the formation challenges are the public `uniquePositions` with the canonical side aliases (`RCB`→`CB`, `RS`→`ST`, and the same for LCB, RCM, LCM, RAM, LAM, LS). Boo Hoo Party is 9 players on the 11-slot 4-5-1. Freaky Zombie is the canonical 7 slots, not a full formation. Live EasySBC challenge ids move when the SBC rotates; drop a new spec file in rather than editing a script.

## Objective

Default is lexicographic, in two stages: minimise coins, then fix coins at that optimum and minimise owned-card value (fodder). `--net` is unchanged and stays one objective, `100 * coins + 95 * fodder`.

The old default `1000 * coins + fodder` is no longer used. That weight matched coin-then-fodder only when a fodder swing could not outweigh 1000 coins. An owned card priced at 1000 or more can now stay in the squad where the old weight would have bought a cheaper replacement. `--exact-model` still optimises the old weight, for comparison.

When both stages prove optimality the printed objective is `1000 * cash + fodder` so it can be compared with an exact-model run. The squad's `cash` and `fodder` are the two stages.

## Linked clubs and Clubs min/max

Chemistry uses the linked-club root from `base.json` `linkedClubIds`. EA's FC 24 Ultimate Team pitch notes say affiliated men's and women's clubs link for chemistry ("you'll also be able to link women's footballers to men's footballers who play for their affiliated Club"), and the same note says league links stay inside each league. FIFPlay's FC 27 chemistry guide says the same: affiliated clubs contribute chemistry together, and men's and women's players do not link through their leagues.

Sources:

* https://www.ea.com/en-au/games/ea-sports-fc/pitch-notes/news/fc-24-ultimate-team-deep-dive (section "How will Chemistry work?")
* https://www.fifplay.com/fc-27-chemistry/ (section "Men's and Women's Players")

Neither source, and no EasySBC or FUTBIN help page found in this pass, says whether a Clubs min/max requirement counts those affiliated clubs as one club or as two. The default is therefore unchanged: clubs min/max use the linked root, so they count as one. Set `"count_linked_clubs": false` on a spec to count raw club ids for clubs min/max only. Same-club minimums, anchor clubs, and chemistry stay on the linked root.

## Rating floors and squad rating

A spec can require counts of players at or above a rating, a minimum squad rating, and counts by profile `itemScore`:

```json
{
  "rating_floors": [{"min": 80, "count": 5}],
  "team_rating_min": 80,
  "item_score_floors": [{"min": 10, "count": 11}]
}
```

`team_rating_min` is the usual SBC squad rating on the submitted players only: floor(average + the total amount by which players sit above that average). It is not the 18-player club squad rating, and it does not replace the raw `rating_sum` on the Liverpool spec. `gold_min` is still "at least this many players rated 75+".

## Speed model

On by default, off with `--exact-model`:

* Cards that share rating, positions, linked club, raw club, league, nation, version, price, owned/storage flag, and item score collapse to one integer variable with that upper bound. Cards that share an asset id are not collapsed together.
* Dominance drops a card when at least `n` strictly cheaper cards share its rating, linked club, league, and nation and can play every position it plays. The default order is lexicographic (coins, then fodder). Equal-cost cards stay.
* Chemistry is one count per club, league, and nation. Each threshold indicator is forced on when the count reaches the step and off otherwise. The big-M is the number of cards that can actually sit in that group, not a flat 11. A group's chemistry is capped at 3 per in-position card.
* Identical slots are ordered by group index.
* A feasible plan.json squad, or else a feasible greedy squad, is passed to HiGHS with `setSolution`.
* After coins are proven, any market card priced above that coin total is fixed out of stage 2.

These should not change the lexicographic optimum. They can change which equal-cost card is chosen. `--exact-model` is the previous constraint set and the old weighted objective. Pool order is resourceId order, not the original script's directory order, so a pure tie can still differ.

## Synthetic benchmark

`python -m eafc.sbc.shared.benchmark` builds an invented 1,000-card, 8-slot squad (names `Synthetic 0000` and up). It is not a real SBC and not a club export. On the cloud runner, Python 3.12, PuLP 3.3.2, highspy 1.15.1, one run with a 30s cap, trim left 977 candidates:

| Run | Status | Gap | Cash | Fodder | Groups | Seconds |
| --- | --- | --- | --- | --- | --- | --- |
| Legacy weighted, no thread override | Optimal | 0 | 0 | 1033 | per card | 11.93 |
| Legacy weighted, 8 threads | Optimal | 0 | 0 | 1033 | per card | 11.81 |
| Strong lex (new default), 8 threads | Optimal | 0 | 0 | 1033 | 813 | 13.61 |
| Strong weighted, 8 threads | Optimal | 0 | 0 | 1033 | 813 | 21.37 |
| CP-SAT lex, 8 workers | Optimal | 0 | 0 | 1033 | 813 | 14.69 |

Threads did not change this case. CP-SAT proved optimality and was not faster, so the default engine stays HiGHS. The new default matched the old optimum here because the coin optimum was already 0 and every relevant price was inside the range where `1000 * coins + fodder` is a true lexicographic encoding. This case was not the 6-minute gap the owner's machine saw; that still needs a timed run on the real club.

## Done list

```bash
python -m eafc.sbc.shared import-done --sets eafc/sbc/local/sets.json
```

The importer adds set ids whose `solved` field is exactly true. `solvedCount` and `remainingCost` do not count. A public sets fetch (the shape in a logged-out `sets` response) has `solved: false` on every row, so importing it marks nothing. A logged-in export is what records challenges you have already submitted.

The original script also hardcoded a skip of Boo Hoo Party and decremented specific owned names after that SBC was submitted. Those names are not in this repo. For a matching run, put that SBC id in `local/done.json` and those exact pool names in `local/consumed.json`:

```json
{"names": ["one exact pool name"]}
```

## Parity check on your PC

This environment cannot see your club, so nobody has compared `plan.json` to the canonical script on real cards. Synthetic tests cover linked clubs, raw versus linked Clubs max, storage versus chem-3 meta, `--keep84`, default versus `--net`, the done list, trim limits, rating floors, squad rating, FUTBIN name matching, parallel objectives, and gap fields. They do not prove a real Marquee plan.

On your machine, from the private folder that already contains `easy-inventory.json`, `base.json`, `player-*.json`, and the canonical `solve.py`:

1. Copy the example config into `eafc/sbc/shared/config.json` and point `inventory_paths`, `profiles_dir`, and `base_path` at those private files.
2. Put your protect names in `local/protect.json` (substring match, same strings the canonical `PROTECT` list used).
3. If you want the post-submission state the canonical script baked in, add the submitted SBC id to `local/done.json` and the used names to `local/consumed.json`. Leave both empty for a fresh club. An empty done list will still try Boo Hoo Party. The canonical script skipped it.
4. Run the canonical script the way you usually do, and keep its `plan.json`.
5. Run `python -m eafc.sbc.shared solve --exact-model --secs 180` and open `eafc/sbc/local/plan.json`.
6. Compare, per SBC that both actually solved: status, cash, chemistry, and the multiset of `(name, rating, owned, cash)`. A tie between equal-price cards can swap names. With `--exact-model` the scaled objective should match (`1000 * cash + fodder`, or `100 * cash + 95 * fodder` with `--net`).
7. Run the default solver (no `--exact-model`) on the same files and time it, including one `--keep84` run. Expect the same coins and fodder as `--exact-model` when no owned card in the tradeoff is priced at 1000 or more. Above that, the default keeps the zero-coin card and `--exact-model` can spend coins to avoid the fodder. Record status, gap, cash, fodder, and seconds. That is the run this cloud benchmark could not do.
8. If `--exact-model` matches the canonical script and the default run differs only on cards priced at 1000 or more, the difference is the lexicographic objective, not a chemistry or club-count change.

Do not paste the real `plan.json` or protect list into the public repo.
