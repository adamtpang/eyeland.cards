# Shared EA FC 27 SBC solver

One PuLP / HiGHS model for every daily SBC. A new challenge is a new JSON file in `specs/`. Personal club data, protect names, and the done list stay in gitignored local files.

This is a public repository. Do not commit inventory exports, FUTBIN club dumps, player profiles, protect lists, consumed-card lists, done lists, or `plan.json`.

## Install

Python 3.12 or 3.14. PuLP 3.3.x and highspy 1.15.x (highspy publishes Python 3.14 wheels). No OR-Tools.

```bash
pip install -r eafc/sbc/requirements-shared.txt
```

The cloud check for this change ran on Python 3.12 with PuLP 3.3.2 and highspy 1.15.1. Python 3.14 was not installed in that environment. The solver uses only the PuLP 3.3 `HiGHS(timeLimit=...)` path plus highspy's `setSolution` / `getInfo` APIs.

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
| `local/plan.json` | Solver output |

The loader picks the newest existing inventory path by mtime and prints the path and timestamp. If two files share an mtime, the earlier config path wins. EasySBC is the source that knows `sbcStorage` and `activeSquad`. The FUTBIN file has no storage flag, so every card mapped from it is treated as not in SBC Storage, and XI names are treated as the active squad. FUTBIN rows are joined to profiles by name and rating.

`transferList` and `isObjectivePlayer` are on the export and are not protection rules. The canonical solver does not read them.

## Run

```bash
python -m eafc.sbc.shared fetch --set-id 78
python -m eafc.sbc.shared fetch --players
python -m eafc.sbc.shared import-done --sets eafc/sbc/local/sets.json
python -m eafc.sbc.shared solve --secs 180
python -m eafc.sbc.shared solve --net --keep84 --ids 121,120
python -m eafc.sbc.shared solve --exact-model
```

`--secs` defaults to 180. The original Marquee script defaulted to 120 when no number was passed.

Each SBC line prints HiGHS status, pool size, cash, chemistry, scaled objective, best bound, and MIP gap. `plan.json` stores the same fields. PuLP itself reports a feasible time-limit stop as Optimal; this solver keeps the HiGHS status (`TimeLimit`) unless the gap is effectively zero.

Specs are solved from highest chemistry to lowest. Equal chemistry uses the `sequence` field, which on the committed files is the original list order. Ids in `done.json` are skipped before that.

## Rules that match the canonical solver

* Usable owned cards are normal versions (`versionId` 0 or 1) that survive protection. Copies of one `resourceId` can be used once per SBC, then the leftover copy is available to the next SBC.
* Protect order: special/loan, protect-file substring, active squad, missing profile, then with `--net` any 84+, then with `--keep84` club 84+ (storage copies stay in), then with `--keep84` inventory `price` above 2000, then chem-3 meta >= 85 unless the card is in SBC Storage.
* Chem-3 meta is the max `metaRating` whose `chemistry` is 3. Storage cards skip that rule.
* Market cards enter the pool only under the price cap (1300, or 6000 for club ids 131681 and 131682 after linked-club merge). Owned cards skip the cap. The objective price is the profile `priceInfo.displayPrice`, not the inventory price. The keep84 "above 2000" check uses the inventory price.
* Trim keeps unused owned cards at or above `minr`, anchor-club cards, the 4 cheapest market cards per (league, nation), the 14 cheapest per league, and 25 cheapest of a required nation. There is no extra club or nation bucket, and an owned card is not force-kept once its remaining count is 0.
* Linked clubs use the canonical union-find on `base.json` `linkedClubIds`. Chemistry and every club count (anchor, same-club, clubs min/max) use that root.
* Default objective is fewest coins, then owned-card value: `1000 * cash + fodder`. `--net` is coins plus 95% of owned value: `100 * cash + 95 * fodder` (divide by 100 for the coin amount).
* Chemistry steps are club 2/4/7, league 3/5/8, nation 2/5/8, in-position only, max 3. Out-of-position cards add 0. This is not the club 2/5/8 table in the older FUTBIN checker `solve.py`.
* Team-rating text on Liverpool v Arsenal is encoded as a raw rating sum of 825, which is what the canonical model constrains. It does not use the EA over-average squad rating.

Committed specs are the canonical ids 118, 119, 120, 121, 114, and 75. Slots for the formation challenges are the public `uniquePositions` with the canonical side aliases (`RCB`→`CB`, `RS`→`ST`, and the same for LCB, RCM, LCM, RAM, LAM, LS). Boo Hoo Party is 9 players on the 11-slot 4-5-1. Freaky Zombie is the canonical 7 slots, not a full formation. Live EasySBC challenge ids move when the SBC rotates; drop a new spec file in rather than editing a script.

## Speed extras

On by default, off with `--exact-model`:

* Dominance drops a card when at least `n` strictly cheaper cards share its rating, linked club, league, and nation and can play every position it plays. Equal-cost cards stay.
* Identical slots are ordered by card index.
* A feasible greedy squad is given to HiGHS with `setSolution` when one can be built.

These should not change the optimal objective. They can change which equal-cost card is chosen. `--exact-model` is the comparison to use when a plan disagrees and you want the canonical constraint set only. Pool order is resourceId order, not the original script's directory order, so a pure tie can still differ.

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

This environment cannot see your club, so nobody has compared `plan.json` to the canonical script on real cards. Synthetic tests cover linked clubs, storage versus chem-3 meta, `--keep84`, default versus `--net`, the done list, trim limits, and gap fields. They do not prove a real Marquee plan.

On your machine, from the private folder that already contains `easy-inventory.json`, `base.json`, `player-*.json`, and the canonical `solve.py`:

1. Copy the example config into `eafc/sbc/shared/config.json` and point `inventory_paths`, `profiles_dir`, and `base_path` at those private files.
2. Put your protect names in `local/protect.json` (substring match, same strings the canonical `PROTECT` list used).
3. If you want the post-submission state the canonical script baked in, add the submitted SBC id to `local/done.json` and the used names to `local/consumed.json`. Leave both empty for a fresh club. An empty done list will still try Boo Hoo Party. The canonical script skipped it.
4. Run the canonical script the way you usually do, and keep its `plan.json`.
5. Run `python -m eafc.sbc.shared solve --exact-model --secs 180` and open `eafc/sbc/local/plan.json`.
6. Compare, per SBC that both actually solved: status, cash, chemistry, and the multiset of `(name, rating, owned, cash)`. A tie between equal-price cards can swap names. The scaled objective should match (`1000 * cash + fodder`, or `100 * cash + 95 * fodder` with `--net`).
7. If `--exact-model` matches and the default run does not, the difference is dominance, slot order, or the warm start, not a rule change. The objective should still match.

Do not paste the real `plan.json` or protect list into the public repo.
