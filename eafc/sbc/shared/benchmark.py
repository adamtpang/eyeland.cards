"""Time the legacy weighted model against the tighter lexicographic model.

The squad is synthetic: about 1,000 invented cards, fake club ids, no real
players. It is not a replay of a live SBC.

  python -m eafc.sbc.shared.benchmark --secs 60
"""

import argparse
import random
import subprocess
import sys
import time
from collections import Counter

from eafc.sbc.shared.model import solve_sbc
from eafc.sbc.shared.specs import prepare_spec

POSITIONS = ["GK", "CB", "CB", "CM", "CM", "ST", "ST", "CAM"]
OUTFIELD = ["CB", "CM", "ST", "CAM"]


def synthetic_case(count=1000, seed=27):
    """Build an owned-heavy 8-slot squad with ``count`` invented cards."""
    rng = random.Random(seed)
    pool = []
    # Most rows are owned so they survive the canonical market trim, which is
    # what a club of this size looks like to the solver.
    owned_target = count - 120
    for index in range(count):
        rid = 10_000 + index
        club = 1 + (index % 36)
        league = 1 + (club % 8)
        nation = 1 + (index % 14)
        rating = 75 + (index % 9)
        if index % 17 == 0:
            pos = ["GK"]
        elif index % 5 == 0:
            # Identical-attribute copies: same club/league/nation/rating/price.
            pos = ["ST", "CAM"]
            club, league, nation, rating = 4, 2, 6, 78
        else:
            pos = rng.sample(OUTFIELD, 3)
        price = 120 + (index * 13) % 680
        owned = index < owned_target
        pool.append(
            {
                "rid": rid,
                "asset": rid,
                "name": f"Synthetic {index:04d}",
                "rating": rating,
                "price": price if not (index % 5 == 0) else 240,
                "own": 1 if owned else 0,
                "club": club,
                "club_raw": club,
                "league": league,
                "nation": nation,
                "pos": set(pos),
                "meta": 40,
                "score": 20,
                "version": 0,
            }
        )
    spec = prepare_spec(
        {
            "id": 9001,
            "name": "Synthetic Thousand",
            "slots": POSITIONS,
            "n": 8,
            "chem": 18,
            "minr": 75,
            "same_league_min": 4,
            "clubs_max": 6,
            "leagues_min": 2,
        }
    )
    left = Counter({card["rid"]: 1 for card in pool if card["own"]})
    return spec, pool, left, set()


def _run(label, spec, pool, left, storage, seconds, **kwargs):
    started = time.perf_counter()
    result = solve_sbc(spec, pool, Counter(left), storage, seconds=seconds, **kwargs)
    elapsed = time.perf_counter() - started
    return {
        "label": label,
        "status": result["status"],
        "gap": result.get("mip_gap"),
        "metric": result.get("gap_metric"),
        "cash": result.get("cash"),
        "fodder": result.get("fodder"),
        "objective": result.get("objective"),
        "pool": result.get("pool"),
        "groups": result.get("groups"),
        "seconds": elapsed,
        "engine": result.get("engine"),
    }


def _gap_text(gap):
    if gap is None:
        return "n/a"
    return f"{gap:.2%}"


def main(argv=None):
    parser = argparse.ArgumentParser(description="Synthetic SBC solver benchmark")
    parser.add_argument("--secs", type=float, default=60, help="time limit per solve (default 60)")
    parser.add_argument("--cards", type=int, default=1000, help="invented cards (default 1000)")
    parser.add_argument("--threads", type=int, default=8)
    parser.add_argument("--skip-cpsat", action="store_true")
    args = parser.parse_args(argv)
    spec, pool, left, storage = synthetic_case(args.cards)
    print(
        f"synthetic {args.cards}-card 8-slot case (invented names, not a real SBC); "
        f"limit {args.secs:.0f}s",
        flush=True,
    )
    runs = [
        ("legacy-weighted", {"formulation": "legacy"}),
        ("legacy-weighted-threads", {"formulation": "legacy", "threads": args.threads}),
        (
            "strong-lex",
            {"formulation": "strong", "objective_mode": "lex", "threads": args.threads},
        ),
        (
            "strong-weighted",
            {"formulation": "strong", "objective_mode": "weighted", "threads": args.threads},
        ),
    ]
    if not args.skip_cpsat:
        probe = subprocess.run(
            [sys.executable, "-c", "import ortools.sat.python.cp_model"],
            capture_output=True,
            check=False,
        )
        if probe.returncode == 0:
            runs.append(
                (
                    "cpsat-lex",
                    {
                        "formulation": "strong",
                        "objective_mode": "lex",
                        "engine": "cpsat",
                        "threads": args.threads,
                    },
                )
            )
        else:
            print("cpsat skipped: ortools is not installed", flush=True)
    rows = []
    for label, kwargs in runs:
        print(f"running {label}...", flush=True)
        row = _run(label, spec, pool, left, storage, args.secs, **kwargs)
        rows.append(row)
        print(
            f"  {label}: {row['status']} gap {_gap_text(row['gap'])} "
            f"cash {row['cash']} fodder {row['fodder']} "
            f"pool {row['pool']} groups {row['groups']} {row['seconds']:.2f}s",
            flush=True,
        )
    print("\nlabel | status | gap | cash | fodder | pool | groups | seconds", flush=True)
    for row in rows:
        print(
            f"{row['label']} | {row['status']} | {_gap_text(row['gap'])} | "
            f"{row['cash']} | {row['fodder']} | {row['pool']} | {row['groups']} | "
            f"{row['seconds']:.2f}",
            flush=True,
        )
    return rows


if __name__ == "__main__":
    main()
