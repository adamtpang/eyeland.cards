"""Optional CP-SAT SBC engine.

Run as a script so this process never imports PuLP or highspy. Those packages
and OR-Tools each ship a HiGHS library, and loading both in one process
fails with an undefined-symbol error. The default solver does not import this
module.

  python eafc/sbc/shared/cpsat_engine.py < payload.pickle > result.pickle
"""

import collections
import pickle
import sys


class _Group:
    def __init__(self, raw):
        self.gid = raw["gid"]
        self.members = list(raw["members"])
        self.ub = int(raw["ub"])
        self.pos = set(raw["pos"])
        self.club = raw["club"]
        self.club_raw = raw["club_raw"]
        self.league = raw["league"]
        self.nation = raw["nation"]
        self.rating = int(raw["rating"])
        self.price = int(raw["price"])
        self.owned = bool(raw["owned"])
        self.score = int(raw["score"])
        self.assets = tuple(raw["assets"])


def solve(payload):
    from ortools.sat.python import cp_model

    spec = payload["spec"]
    chemistry = payload["chemistry"]
    groups = [_Group(raw) for raw in payload["groups"]]
    objective_mode = payload["objective_mode"]
    seconds = float(payload["seconds"])
    threads = int(payload["threads"])
    hint_chosen = payload.get("chosen")
    hint_assignment = payload.get("assignment") or {}
    hint_source = payload.get("warm_source")

    if spec["n"] <= 0 or sum(group.ub for group in groups) < spec["n"]:
        return {"status": "Infeasible", "pulp_status": "INFEASIBLE", "chosen": [], "placed": {}}

    model = cp_model.CpModel()
    y = {group.gid: model.NewIntVar(0, group.ub, f"y{group.gid}") for group in groups}
    eligible = {
        group.gid: [slot for slot, name in enumerate(spec["slots"]) if name in group.pos] for group in groups
    }
    x = {
        (group.gid, slot): model.NewBoolVar(f"x{group.gid}_{slot}")
        for group in groups
        for slot in eligible[group.gid]
    }
    for group in groups:
        gid = group.gid
        model.Add(y[gid] >= sum(x[gid, slot] for slot in eligible[gid]))
    for slot in range(len(spec["slots"])):
        model.Add(sum(var for (gid, placed), var in x.items() if placed == slot) <= 1)
    model.Add(sum(y.values()) == spec["n"])
    asset_groups = collections.defaultdict(list)
    for group in groups:
        for asset in set(group.assets):
            asset_groups[asset].append(group.gid)
    for gids in asset_groups.values():
        if len(gids) > 1:
            model.Add(sum(y[gid] for gid in gids) <= 1)

    if spec["chem"] > 0:
        flags = {}
        for attr in ("club", "league", "nation"):
            values = {getattr(group, attr) for group in groups}
            for value in values:
                members = [group for group in groups if getattr(group, attr) == value and eligible[group.gid]]
                upper = min(spec["n"], sum(group.ub for group in members))
                if upper <= 0:
                    continue
                count = model.NewIntVar(0, upper, f"c_{attr}_{value}")
                model.Add(count == sum(x[group.gid, slot] for group in members for slot in eligible[group.gid]))
                for step in chemistry[attr]:
                    flag = model.NewBoolVar(f"b_{attr}_{value}_{step}")
                    flags[attr, value, step] = flag
                    if upper < step:
                        model.Add(flag == 0)
                    else:
                        model.Add(count >= step).OnlyEnforceIf(flag)
                        model.Add(count <= step - 1).OnlyEnforceIf(flag.Not())
        chem_parts = []
        for group in groups:
            gid = group.gid
            if not eligible[gid]:
                continue
            point_flags = [
                flags[attr, getattr(group, attr), step]
                for attr in ("club", "league", "nation")
                for step in chemistry[attr]
                if (attr, getattr(group, attr), step) in flags
            ]
            if group.ub == 1:
                chem = model.NewIntVar(0, 3, f"chem{gid}")
                model.Add(chem <= 3 * sum(x[gid, slot] for slot in eligible[gid]))
                model.Add(chem <= sum(point_flags) if point_flags else 0)
            else:
                in_pos = model.NewIntVar(0, group.ub, f"ip{gid}")
                model.Add(in_pos == sum(x[gid, slot] for slot in eligible[gid]))
                pieces = []
                for flag_index, flag in enumerate(point_flags):
                    part = model.NewIntVar(0, group.ub, f"h{gid}_{flag_index}")
                    model.Add(part == in_pos).OnlyEnforceIf(flag)
                    model.Add(part == 0).OnlyEnforceIf(flag.Not())
                    pieces.append(part)
                chem = model.NewIntVar(0, 3 * group.ub, f"chem{gid}")
                model.Add(chem <= 3 * in_pos)
                model.Add(chem <= sum(pieces) if pieces else 0)
            chem_parts.append(chem)
        if chem_parts:
            model.Add(sum(chem_parts) >= spec["chem"])

    def require(pred, minimum):
        terms = [y[group.gid] for group in groups if pred(group)]
        if not terms:
            if int(minimum) > 0:
                model.Add(1 == 0)
            return
        model.Add(sum(terms) >= int(minimum))

    if "anchor" in spec:
        require(lambda group: group.club in spec["anchor"][0], spec["anchor"][1])
    if "nation" in spec:
        require(lambda group: group.nation == spec["nation"][0], spec["nation"][1])
    if "league" in spec:
        require(lambda group: group.league == spec["league"][0], spec["league"][1])
    if "gold_min" in spec:
        require(lambda group: group.rating >= 75, spec["gold_min"])
    if "rating_sum" in spec:
        model.Add(sum(group.rating * y[group.gid] for group in groups) >= spec["rating_sum"])
    for rule in spec.get("rating_floors") or []:
        require(lambda group, rule=rule: group.rating >= rule["min"], rule["count"])
    for rule in spec.get("item_score_floors") or []:
        require(lambda group, rule=rule: group.score >= rule["min"], rule["count"])
    if spec.get("team_rating_min"):
        _team_rating(model, groups, y, spec["n"], int(spec["team_rating_min"]))

    club_attr = "club" if spec.get("count_linked_clubs", True) else "club_raw"
    _distinct(model, spec, groups, y, "club", club_attr, "clubs_min", "clubs_max")
    _distinct(model, spec, groups, y, "league", "league", "leagues_min", "leagues_max")
    _distinct(model, spec, groups, y, "nation", "nation", "nations_min", "nations_max")
    _same(model, spec, groups, y, "club", "same_club_min", "same_club_max")
    _same(model, spec, groups, y, "league", "same_league_min", "same_league_max")
    _same(model, spec, groups, y, "nation", "same_nation_min", "same_nation_max")

    for slot in range(len(spec["slots"]) - 1):
        if spec["slots"][slot] != spec["slots"][slot + 1]:
            continue
        earlier = sum((gid + 1) * var for (gid, placed), var in x.items() if placed == slot)
        later = sum((gid + 1) * var for (gid, placed), var in x.items() if placed == slot + 1)
        model.Add(earlier <= later)

    price_cap = max(1, sum(max(group.price, 0) * group.ub for group in groups))
    cash = model.NewIntVar(0, price_cap, "cash")
    fodder = model.NewIntVar(0, price_cap, "fodder")
    model.Add(cash == sum(group.price * y[group.gid] for group in groups if not group.owned))
    model.Add(fodder == sum(group.price * y[group.gid] for group in groups if group.owned))

    if hint_chosen:
        by_index = {}
        for group in groups:
            for index in group.members:
                by_index[index] = group.gid
        counts = collections.Counter(by_index[index] for index in hint_chosen if index in by_index)
        for group in groups:
            model.AddHint(y[group.gid], int(counts[group.gid]))
        used = set()
        for slot, index in hint_assignment.items():
            if index in by_index:
                used.add((by_index[index], int(slot)))
        for key, var in x.items():
            model.AddHint(var, 1 if key in used else 0)

    def search(metric):
        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = seconds
        solver.parameters.num_search_workers = threads
        code = solver.Solve(model)
        name = solver.StatusName(code)
        if name == "OPTIMAL":
            status, gap = "Optimal", 0.0
        elif name == "FEASIBLE":
            status = "TimeLimit"
            obj = solver.ObjectiveValue()
            bound = solver.BestObjectiveBound()
            gap = 0.0 if obj == 0 and bound == 0 else abs(obj - bound) / abs(obj or 1)
        elif name == "INFEASIBLE":
            status, gap = "Infeasible", None
        else:
            status, gap = "NotSolved", None
        objective = solver.ObjectiveValue() if status in {"Optimal", "TimeLimit"} else None
        bound = solver.BestObjectiveBound() if status in {"Optimal", "TimeLimit"} else None
        return solver, {
            "status": status,
            "pulp_status": name,
            "objective": objective,
            "bound": bound,
            "gap": gap,
            "metric": metric,
        }

    def read(solver):
        chosen = []
        placed = {}
        for group in groups:
            count = int(solver.Value(y[group.gid]))
            if count <= 0:
                continue
            members = group.members[:count]
            chosen.extend(members)
            on = [slot for slot in eligible[group.gid] if solver.Value(x[group.gid, slot])]
            for slot, index in zip(on, members):
                placed[int(slot)] = index
        return chosen, placed

    warm = hint_source if hint_chosen else None
    if objective_mode == "lex":
        model.Minimize(cash)
        solver1, stage1 = search("coins")
        stage1["stage1_status"] = stage1["status"]
        stage1["stage2_status"] = None
        stage1["warm_source"] = warm
        if stage1["status"] not in {"Optimal", "TimeLimit"}:
            stage1["chosen"] = []
            stage1["placed"] = {}
            return stage1
        chosen, placed = read(solver1)
        stage1["chosen"] = chosen
        stage1["placed"] = placed
        if stage1["status"] != "Optimal":
            return stage1
        # Coin optimum is fixed. The parent checks the squad; this process
        # still minimises fodder under that coin cap.
        opt_cash = int(round(solver1.ObjectiveValue()))
        model.Add(cash <= opt_cash)
        for group in groups:
            if not group.owned and group.price > opt_cash:
                model.Add(y[group.gid] == 0)
        model.Minimize(fodder)
        solver2, stage2 = search("fodder")
        stage2["stage1_status"] = "Optimal"
        stage2["stage2_status"] = stage2["status"]
        stage2["warm_source"] = warm
        if stage2["status"] not in {"Optimal", "TimeLimit"}:
            stage2["chosen"] = chosen
            stage2["placed"] = placed
            stage2["fallback"] = True
            return stage2
        chosen2, placed2 = read(solver2)
        if stage2["status"] == "Optimal":
            stage2["metric"] = "lex"
        stage2["chosen"] = chosen2
        stage2["placed"] = placed2
        return stage2

    metric = "net" if objective_mode == "net" else "weighted"
    if objective_mode == "net":
        model.Minimize(100 * cash + 95 * fodder)
    else:
        model.Minimize(1000 * cash + fodder)
    solver, report = search(metric)
    report["stage1_status"] = report["status"]
    report["stage2_status"] = None
    report["warm_source"] = warm
    if report["status"] in {"Optimal", "TimeLimit"}:
        chosen, placed = read(solver)
    else:
        chosen, placed = [], {}
    report["chosen"] = chosen
    report["placed"] = placed
    return report


def _team_rating(model, groups, y, n, minimum):
    cap = max([99] + [group.rating for group in groups])
    big = n * cap
    total = sum(group.rating * y[group.gid] for group in groups)
    excess = []
    for group in groups:
        diff = model.NewIntVar(-big, big, f"d{group.gid}")
        model.Add(diff == n * group.rating - total)
        spill = model.NewIntVar(0, big, f"u{group.gid}")
        above = model.NewBoolVar(f"a{group.gid}")
        model.Add(diff >= 1).OnlyEnforceIf(above)
        model.Add(diff <= 0).OnlyEnforceIf(above.Not())
        model.Add(spill == diff).OnlyEnforceIf(above)
        model.Add(spill == 0).OnlyEnforceIf(above.Not())
        part = model.NewIntVar(0, big * group.ub, f"e{group.gid}")
        model.AddMultiplicationEquality(part, [y[group.gid], spill])
        excess.append(part)
    model.Add(total + sum(excess) >= minimum * n)


def _distinct(model, spec, groups, y, label, attr, lo_key, hi_key):
    if lo_key not in spec and hi_key not in spec:
        return
    present = collections.defaultdict(list)
    for group in groups:
        present[getattr(group, attr)].append(group)
    flags = []
    for value, members in present.items():
        total = sum(y[group.gid] for group in members)
        upper = min(spec["n"], sum(group.ub for group in members))
        flag = model.NewBoolVar(f"on_{label}_{value}")
        model.Add(total >= 1).OnlyEnforceIf(flag)
        model.Add(total == 0).OnlyEnforceIf(flag.Not())
        model.Add(total <= upper)
        flags.append(flag)
    if lo_key in spec:
        model.Add(sum(flags) >= spec[lo_key])
    if hi_key in spec:
        model.Add(sum(flags) <= spec[hi_key])


def _same(model, spec, groups, y, attr, lo_key, hi_key):
    if lo_key not in spec and hi_key not in spec:
        return
    present = collections.defaultdict(list)
    for group in groups:
        present[getattr(group, attr)].append(group)
    if hi_key in spec:
        for members in present.values():
            model.Add(sum(y[group.gid] for group in members) <= spec[hi_key])
    if lo_key in spec:
        flags = []
        lo = spec[lo_key]
        for _value, members in present.items():
            total = sum(y[group.gid] for group in members)
            flag = model.NewBoolVar(f"z_{attr}_{_value}")
            model.Add(total >= lo).OnlyEnforceIf(flag)
            model.Add(total <= lo - 1).OnlyEnforceIf(flag.Not())
            flags.append(flag)
        model.Add(sum(flags) >= 1)


if __name__ == "__main__":
    request = pickle.load(sys.stdin.buffer)
    try:
        pickle.dump(solve(request), sys.stdout.buffer)
    except Exception as exc:
        sys.stderr.write(f"{type(exc).__name__}: {exc}\n")
        sys.exit(1)
