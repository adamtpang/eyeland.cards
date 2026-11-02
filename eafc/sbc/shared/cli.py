"""Command line for the shared SBC solver.

  python -m eafc.sbc.shared solve --net --keep84 --secs 180
  python -m eafc.sbc.shared import-done --sets local/sets.json
  python -m eafc.sbc.shared fetch --set-id 78

Copy ``config.example.json`` to ``config.json`` (gitignored) and point it at
local inventory, profiles, base data, and the protect / done files.
"""

import argparse
import json
import os
import sys
from collections import Counter
from pathlib import Path

from eafc.sbc.shared.clubs import link_root
from eafc.sbc.shared.done import import_solved, load_done, write_done
from eafc.sbc.shared.fetch_public import fetch_base, fetch_challenges, fetch_player, fetch_solutions
from eafc.sbc.shared.inventory import (
    apply_consumed,
    build_pool,
    load_inventory,
    load_name_list,
    load_profiles,
)
from eafc.sbc.shared.model import solve_squads
from eafc.sbc.shared.specs import load_chemistry, load_specs, read_json

PACKAGE_DIR = Path(__file__).resolve().parent
SBC_DIR = PACKAGE_DIR.parent


def _resolve(config_file, value):
    if value is None:
        return None
    path = Path(value)
    if not path.is_absolute():
        path = Path(config_file).resolve().parent / path
    return path


def load_config(path):
    file = Path(path)
    if not file.is_file():
        example = PACKAGE_DIR / "config.example.json"
        raise SystemExit(f"missing config {file}. Copy {example} and point it at local files.")
    raw = read_json(file)
    config = dict(raw)
    config["config_path"] = file
    for key in (
        "profiles_dir",
        "base_path",
        "protect_path",
        "consumed_path",
        "done_path",
        "sets_path",
        "plan_path",
        "specs_dir",
        "chemistry_path",
    ):
        if key in raw and raw[key]:
            config[key] = _resolve(file, raw[key])
    config["inventory_paths"] = [_resolve(file, item) for item in raw.get("inventory_paths", [])]
    return config


def default_config_path():
    for candidate in (PACKAGE_DIR / "config.json", SBC_DIR / "local" / "config.json"):
        if candidate.is_file():
            return candidate
    return PACKAGE_DIR / "config.json"


def _gap_text(gap):
    if gap is None:
        return "n/a"
    return f"{gap:.2%}"


def _num(value):
    if value is None:
        return "n/a"
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return f"{value:.4f}" if isinstance(value, float) else str(value)


def run_solve(config, args):
    base_path = config.get("base_path")
    if base_path is None or not Path(base_path).is_file():
        raise SystemExit(f"missing base.json at {base_path}. Run: python -m eafc.sbc.shared fetch")
    base = read_json(base_path)
    root = link_root(base.get("managerData", {}).get("clubs", []))
    profiles = load_profiles(config["profiles_dir"])
    loaded = load_inventory(config["inventory_paths"], profiles)
    protect = load_name_list(config.get("protect_path"))
    pool, kept, storage = build_pool(
        loaded["players"],
        profiles,
        root,
        protect,
        net=args.net,
        keep84=args.keep84,
        price_cap=int(config.get("price_cap", 1300)),
        anchor_big=config.get("anchor_big_clubs", (131681, 131682)),
        anchor_big_cap=int(config.get("anchor_big_cap", 6000)),
    )
    left = Counter({card["rid"]: card["own"] for card in pool if card["own"]})
    apply_consumed(pool, left, load_name_list(config.get("consumed_path")))
    specs = load_specs(config["specs_dir"], base=base, root=root)
    if args.ids:
        wanted = {int(item) for item in args.ids.split(",") if item}
        specs = [spec for spec in specs if spec["id"] in wanted]
    done = load_done(config.get("done_path"))
    chemistry = load_chemistry(config.get("chemistry_path"))
    plan_squads = None
    plan_path = Path(config["plan_path"])
    if plan_path.is_file() and not args.exact_model:
        try:
            previous = read_json(plan_path)
            plan_squads = previous.get("squads") if isinstance(previous, dict) else None
        except (OSError, ValueError, json.JSONDecodeError):
            print(f"plan ignored (unreadable): {plan_path}", flush=True)
    jobs = args.jobs if args.jobs is not None else min(8, os.cpu_count() or 1)
    print(
        f"pool {len(pool)} owned cards usable {sum(left.values())} kept {len(kept)}",
        flush=True,
    )
    try:
        squads, skipped = solve_squads(
            specs,
            pool,
            left,
            storage,
            net=args.net,
            seconds=args.secs,
            chemistry=chemistry,
            exact_model=args.exact_model,
            done=done,
            jobs=jobs,
            engine=args.engine,
            threads=args.threads,
            plan_squads=plan_squads,
        )
    except RuntimeError as exc:
        raise SystemExit(str(exc)) from exc
    if skipped:
        print("skipped done ids", ",".join(str(item) for item in skipped), flush=True)
    for squad in squads:
        print(
            f"\n== {squad['name']}: {squad['status']}, {squad.get('engine', 'highs')} "
            f"{squad.get('objective_mode', 'weighted')}, pool {squad['pool']} "
            f"(canonical {squad['canonical_pool']}, groups {squad.get('groups', squad['pool'])}), "
            f"cash {squad['cash']:,}, fodder {squad.get('fodder', 0):,}, chem {squad['chem']}, "
            f"objective {_num(squad['objective'])}, bound {_num(squad['best_bound'])}, "
            f"gap {_gap_text(squad['mip_gap'])}"
            + (f" on {squad['gap_metric']}" if squad.get("gap_metric") else ""),
            flush=True,
        )
        for row in squad["players"]:
            if row["storage"]:
                source = "STORAGE"
            elif row["owned"]:
                source = "CLUB"
            else:
                source = f"BUY {row['cash']:,}"
            oop = "" if row["inpos"] else " (OOP)"
            print(
                f"  {row['name']:32} {row['rating']} chem {row['chem']}{oop}  {source}  value {row['value']:,}",
                flush=True,
            )
    print("\nTOTAL CASH", sum(squad["cash"] for squad in squads), flush=True)
    plan = {
        "inventory": {
            "path": str(loaded["path"]),
            "kind": loaded["kind"],
            "mtime": loaded["mtime_iso"],
        },
        "objective": "net" if args.net else "coins",
        "keep84": bool(args.keep84),
        "exact_model": bool(args.exact_model),
        "engine": "highs" if args.exact_model else args.engine,
        "threads": args.threads,
        "jobs": jobs,
        "seconds": args.secs,
        "skipped_done": skipped,
        "squads": squads,
        "kept": kept,
    }
    plan_path = Path(config["plan_path"])
    plan_path.parent.mkdir(parents=True, exist_ok=True)
    plan_path.write_text(json.dumps(plan, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"wrote {plan_path}", flush=True)
    return plan


def run_import_done(config, args):
    sets_path = Path(args.sets) if args.sets else config.get("sets_path")
    done_path = Path(args.done) if args.done else config.get("done_path")
    if sets_path is None or not Path(sets_path).is_file():
        raise SystemExit(f"missing sets file {sets_path}")
    if done_path is None:
        raise SystemExit("missing done_path")
    document = read_json(sets_path)
    merged, marked, total = import_solved(document, load_done(done_path))
    write_done(done_path, merged)
    print(
        f"marked {len(marked)} solved set ids ({total} sets in {sets_path}); done file now has {len(merged)}",
        flush=True,
    )
    if not marked:
        print(
            "No set had solved true. A public EasySBC sets fetch shows solved false for every set; "
            "only a logged-in export marks the ones already submitted.",
            flush=True,
        )
    return merged


def run_fetch(config, args):
    local = Path(config["base_path"]).parent
    local.mkdir(parents=True, exist_ok=True)
    base_file = fetch_base(config["base_path"])
    print(f"wrote {base_file}", flush=True)
    profiles = Path(config["profiles_dir"])
    profiles.mkdir(parents=True, exist_ok=True)
    ids = set()
    inventory = next((path for path in config["inventory_paths"] if path.is_file()), None)
    if inventory is not None:
        document = read_json(inventory)
        for row in document.get("players") or []:
            if "resourceId" in row:
                ids.add(int(row["resourceId"]))
    for set_id in args.set_id:
        dest = local / f"requirements-{int(set_id)}.json"
        challenges = json.loads(fetch_challenges(set_id, dest).read_text(encoding="utf-8"))
        print(f"wrote {dest} ({len(challenges)} challenges)", flush=True)
        if args.solutions:
            for challenge in challenges:
                solution_path = local / f"solution-{challenge['id']}.json"
                try:
                    payload = json.loads(fetch_solutions(challenge["id"], solution_path).read_text(encoding="utf-8"))
                except Exception as exc:  # noqa: BLE001 - public solutions are optional
                    print(f"solution {challenge['id']} skipped: {exc}", flush=True)
                    continue
                for solution in payload.get("solutions") or []:
                    for player in solution.get("players") or []:
                        resource = player.get("resource_id") or player.get("resourceId")
                        if resource:
                            ids.add(int(resource))
    if args.players:
        for resource_id in sorted(ids):
            dest = profiles / f"player-{resource_id}.json"
            if dest.is_file() and not args.refresh_players:
                continue
            try:
                fetch_player(resource_id, dest)
            except Exception as exc:  # noqa: BLE001 - one missing profile should not abort the rest
                print(f"player {resource_id} skipped: {exc}", flush=True)
        print(f"profiles in {profiles}", flush=True)


def build_parser():
    parser = argparse.ArgumentParser(prog="eafc.sbc.shared", description="Shared EA FC 27 SBC solver")
    parser.add_argument(
        "command",
        nargs="?",
        default="solve",
        choices=("solve", "import-done", "fetch"),
        help="solve (default), import-done, or fetch",
    )
    parser.add_argument("--config", type=Path, help="path to config.json (default: shared/config.json)")
    parser.add_argument("--net", action="store_true", help="minimize coins + 95%% of owned card value")
    parser.add_argument("--keep84", action="store_true", help="keep club 84+ and inventory prices above 2000")
    parser.add_argument("--secs", type=float, default=180, help="time limit per SBC stage (default 180)")
    parser.add_argument("--engine", choices=("highs", "cpsat"), default="highs", help="highs (default) or cpsat")
    parser.add_argument("--threads", type=int, default=None, help="HiGHS threads, or CP-SAT workers (default 8)")
    parser.add_argument(
        "--jobs",
        type=int,
        default=None,
        help="solve independent SBCs in this many processes (default min(8, cpu))",
    )
    parser.add_argument("--ids", help="comma-separated spec ids to solve")
    parser.add_argument(
        "--exact-model",
        action="store_true",
        help="disable dominance, slot symmetry, and the greedy warm start",
    )
    parser.add_argument("--sets", help="sets JSON for import-done (logged-in export)")
    parser.add_argument("--done", help="done-list JSON to update")
    parser.add_argument("--set-id", action="append", type=int, help="EasySBC set id to fetch (repeatable)")
    parser.add_argument("--solutions", action="store_true", help="also download public solution samples")
    parser.add_argument("--players", action="store_true", help="download player profiles for owned and solution ids")
    parser.add_argument("--refresh-players", action="store_true", help="overwrite player profiles that already exist")
    return parser


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    args = build_parser().parse_args(argv)
    if not args.set_id:
        args.set_id = []
    config = load_config(args.config or default_config_path())
    if args.command == "import-done":
        run_import_done(config, args)
    elif args.command == "fetch":
        run_fetch(config, args)
    else:
        run_solve(config, args)


if __name__ == "__main__":
    main()
