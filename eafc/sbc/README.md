# Our own EasySBC

**One command:** `python sbc.py sbcs/<sbc>.json [--exclude "Name"] [--budget 180]`
club import (if the web app is open) -> solve -> live price check -> `sbc-report.html` with card images and 3 ready-made swaps per card.

- `club_snapshot.py`: read-only club import through the web app's own Club search (`club_fetch.js`), tags starter/bench/loan/spare.
- `optimize.py`: exact integer program per rating sum, time budget, starts from the last saved squad (`result.json`), keep-value for good club cards (`--keep-premium`, `--free-below`).
- `solve.py`: requirement checker and chemistry, verified 11/11 against EA's own per-player chemistry (Icon rule included).
- `report.py`: live PC prices and card screenshots from FUTBIN, one page every few seconds.
- FUTBIN rate-limits bulk fetching (403). Prices cache in `%TEMP%/eafc-sbc-cache`; `FUTBIN_OFFLINE=1` uses the cache only.

Swaps inflated cards out of a working SBC squad for the cheapest players that still meet every requirement.

Read-only by design: it reads public FUTBIN pages through the Helium CDP bridge (`cdp.py`, port 9333) and prints a shopping list. It never touches EA, the web app or the transfer market. You buy and submit by hand.

    python solve.py sbcs/england-v-spain.json
    python solve.py sbcs/england-v-spain.json --exclude "Oyarzabal,Kiwior"
    python solve.py sbcs/england-v-spain.json --owned owned.json   # FUTBIN ids you already own cost 0

- `sbcs/*.json`: slots, requirements, a known-good base squad (FUTBIN ids) and which FUTBIN lists to pull candidates from.
- Prices are cached for 3 hours in `%TEMP%/eafc-sbc-cache`.
- Chemistry: club 2/5/8, nation 2/5/8, league 3/5/8, max 3 each, only for players in their slot position. Rating uses the EA over-average formula.
- Limits: candidates are the first 30 cheapest per list, so add pools for rarer needs. Single then pair swaps, not a full optimizer.
