"""SBC models.

``exact_model`` and ``formulation="legacy"`` keep the previous per-card PuLP
model. The legacy objective is ``1000 * coins + fodder`` (or the net weight).
The default formulation collapses identical cards, counts chemistry once per
club, league and nation, and solves lexicographically: coins, then fodder.

HiGHS is always run with a time limit. The result reports status, objective,
dual bound, and MIP gap. PuLP labels a feasible time-limit stop as Optimal;
the status here stays TimeLimit unless the gap is effectively zero.
"""

import collections
import multiprocessing
import warnings

import pulp

# PuLP 3.3 warns that the direct constructor goes away in 4.0. This solver
# stays on the 3.3 API the canonical script uses, without a warning per card.
try:
    from pulp.v4_migration import set_v4_migration_warnings

    set_v4_migration_warnings(False)
except Exception:
    warnings.filterwarnings(
        "ignore",
        message=r"Constructing LpVariable.*deprecated",
        category=DeprecationWarning,
    )

from eafc.sbc.shared.rating import add_team_rating, squad_rating
from eafc.sbc.shared.specs import DEFAULT_CHEMISTRY

try:
    import highspy
except ImportError:  # pragma: no cover - the package is a required dependency
    highspy = None

try:
    import numpy as np
except ImportError:  # pragma: no cover
    np = None


class _HiGHSStart(pulp.HiGHS):
    """In-process HiGHS with an optional MIP start.

    PuLP 3.3's highspy binding has no ``warmStart`` flag. Passing one through
    would be forwarded to ``setOptionValue`` and rejected. The start is applied
    with ``Highs.setSolution`` after the columns exist and before ``run``.
    """

    def __init__(self, *args, start=None, **kwargs):
        self._start = start or {}
        super().__init__(*args, **kwargs)

    def createAndConfigureSolver(self, lp):
        # HiGHS keeps one process-wide thread scheduler. A later solve that
        # asks for a different thread count is rejected unless that scheduler
        # is cleared first.
        if self.threads is not None and highspy is not None:
            reset = getattr(highspy.Highs, "resetGlobalScheduler", None)
            if reset is not None:
                try:
                    reset(True)
                except TypeError:
                    try:
                        reset()
                    except Exception:
                        pass
                except Exception:
                    pass
        super().createAndConfigureSolver(lp)

    def callSolver(self, lp):
        if self._start and highspy is not None and np is not None:
            indexes = []
            values = []
            for var in lp.variables():
                if var.name in self._start:
                    indexes.append(var.index)
                    values.append(float(self._start[var.name]))
            if indexes:
                try:
                    lp.solverModel.setSolution(
                        len(indexes),
                        np.asarray(indexes, dtype=np.int32),
                        np.asarray(values, dtype=np.float64),
                    )
                except Exception:
                    # A rejected start must not block the solve. HiGHS still
                    # searches from scratch when no solution was accepted.
                    pass
        lp.solverModel.run()


def _finite(value):
    if value is None:
        return None
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    if number != number or number in (float("inf"), float("-inf")):
        return None
    return number


def _status_name(model_status):
    name = getattr(model_status, "name", str(model_status))
    if name.startswith("k"):
        name = name[1:]
    if name in {"UnboundedOrInfeasible"}:
        return "Infeasible"
    if name in {"Notset", "Unknown", "LoadError", "ModelError", "PresolveError", "SolveError"}:
        return "NotSolved"
    return name or "NotSolved"


def _gap_report(solver_model):
    """Return status, scaled objective, dual bound, and MIP gap fraction."""
    if solver_model is None or not hasattr(solver_model, "getInfo"):
        return "NotSolved", None, None, None
    info = solver_model.getInfo()
    status = _status_name(solver_model.getModelStatus())
    objective = _finite(getattr(info, "objective_function_value", None))
    bound = _finite(getattr(info, "mip_dual_bound", None))
    gap = _finite(getattr(info, "mip_gap", None))
    if gap is None and objective not in (None, 0) and bound is not None:
        gap = abs(objective - bound) / abs(objective)
    if objective == 0 and bound == 0:
        gap = 0.0
    if gap is not None and gap <= 1e-8 and status == "TimeLimit":
        status = "Optimal"
        gap = 0.0
    return status, objective, bound, gap


def canonical_trim(pool, spec, left):
    """Owned cards still unused, anchors, and the cheapest market cards.

    Market cards: 4 cheapest per (league, nation), 14 cheapest per league,
    plus 25 cheapest of a required nation. There is no club bucket and no
    nation bucket. Owned cards are not force-kept once ``left`` is 0, and
    cards under ``minr`` are dropped even if owned.
    """
    keep = []
    by_ln = collections.defaultdict(list)
    by_league = collections.defaultdict(list)
    anchor = spec.get("anchor", (set(),))[0]
    for index, card in enumerate(pool):
        if card["rating"] < spec["minr"]:
            continue
        if left[card["rid"]] > 0 or card["club"] in anchor:
            keep.append(index)
        elif card["price"]:
            by_ln[card["league"], card["nation"]].append(index)
            by_league[card["league"]].append(index)
    for buckets, limit in ((by_ln, 4), (by_league, 14)):
        for indexes in buckets.values():
            keep += sorted(indexes, key=lambda i: pool[i]["price"])[:limit]
    if "nation" in spec:
        nation_id = spec["nation"][0]
        priced = [
            i
            for i, card in enumerate(pool)
            if card["nation"] == nation_id and card["price"] and card["rating"] >= spec["minr"]
        ]
        keep += sorted(priced, key=lambda i: pool[i]["price"])[:25]
    return sorted(set(keep))


def _effective_cost(card, left, net):
    owned = left[card["rid"]] > 0
    price = card["price"]
    if net:
        return (95 * price) if owned else (100 * price)
    return price if owned else (1000 * price)


def drop_dominated(indexes, pool, spec, left, net):
    """Drop cards that cannot beat ``n`` strictly cheaper substitutes.

    A substitute shares rating, linked club, league and nation, and its
    positions are a superset. Equal-cost cards are kept. This cannot remove
    the last ``n`` cards of a role, so a feasible squad stays feasible and an
    optimal squad stays optimal.
    """
    groups = collections.defaultdict(list)
    for index in indexes:
        card = pool[index]
        groups[card["rating"], card["club"], card["league"], card["nation"]].append(index)
    needed = spec["n"]
    drop = set()
    for members in groups.values():
        costs = {index: _effective_cost(pool[index], left, net) for index in members}
        for index in members:
            positions = pool[index]["pos"]
            cheaper = 0
            for other in members:
                if other == index:
                    continue
                if positions <= pool[other]["pos"] and costs[other] < costs[index]:
                    cheaper += 1
            if cheaper >= needed:
                drop.add(index)
    return [index for index in indexes if index not in drop]


def _points(count, thresholds):
    return sum(count >= step for step in thresholds)


def _squad_chem(in_position, chemistry):
    if not in_position:
        return 0, []
    clubs = collections.Counter(card["club"] for card in in_position)
    leagues = collections.Counter(card["league"] for card in in_position)
    nations = collections.Counter(card["nation"] for card in in_position)
    per_card = []
    for card in in_position:
        raw = (
            _points(clubs[card["club"]], chemistry["club"])
            + _points(leagues[card["league"]], chemistry["league"])
            + _points(nations[card["nation"]], chemistry["nation"])
        )
        per_card.append(min(3, raw))
    return sum(per_card), per_card


def _meets(spec, chosen, in_position, chem_total):
    if len(chosen) != spec["n"]:
        return False
    if chem_total < spec["chem"]:
        return False

    def count(pred):
        return sum(1 for card in chosen if pred(card))

    if "anchor" in spec and count(lambda card: card["club"] in spec["anchor"][0]) < spec["anchor"][1]:
        return False
    if "nation" in spec and count(lambda card: card["nation"] == spec["nation"][0]) < spec["nation"][1]:
        return False
    if "league" in spec and count(lambda card: card["league"] == spec["league"][0]) < spec["league"][1]:
        return False
    if "gold_min" in spec and count(lambda card: card["rating"] >= 75) < spec["gold_min"]:
        return False
    if "rating_sum" in spec and sum(card["rating"] for card in chosen) < spec["rating_sum"]:
        return False
    for rule in spec.get("rating_floors") or []:
        if count(lambda card, rule=rule: card["rating"] >= rule["min"]) < rule["count"]:
            return False
    for rule in spec.get("item_score_floors") or []:
        if count(lambda card, rule=rule: card.get("score", 0) >= rule["min"]) < rule["count"]:
            return False
    if spec.get("team_rating_min") and squad_rating(card["rating"] for card in chosen) < spec["team_rating_min"]:
        return False
    club_field = "club" if spec.get("count_linked_clubs", True) else "club_raw"
    for key, lo, hi in (
        ("club", "clubs_min", "clubs_max"),
        ("league", "leagues_min", "leagues_max"),
        ("nation", "nations_min", "nations_max"),
    ):
        field = club_field if key == "club" else key
        distinct = {card.get(field, card[key]) for card in chosen}
        if lo in spec and len(distinct) < spec[lo]:
            return False
        if hi in spec and len(distinct) > spec[hi]:
            return False
    for key, lo, hi in (
        ("club", "same_club_min", "same_club_max"),
        ("league", "same_league_min", "same_league_max"),
        ("nation", "same_nation_min", "same_nation_max"),
    ):
        counts = collections.Counter(card[key] for card in chosen)
        if hi in spec and any(value > spec[hi] for value in counts.values()):
            return False
        if lo in spec and not any(value >= spec[lo] for value in counts.values()):
            return False
    return True


def _assign_slots(chosen_indexes, spec, pool):
    """Put chosen cards on slots. Identical slots end up index-ordered."""
    remaining = set(chosen_indexes)
    assignment = {}
    open_slots = list(range(len(spec["slots"])))
    while remaining and open_slots:
        options = {}
        for index in remaining:
            slots = [slot for slot in open_slots if spec["slots"][slot] in pool[index]["pos"]]
            if slots:
                options[index] = slots
        if not options:
            break
        index = min(options, key=lambda i: (len(options[i]), i))
        slot = min(options[index])
        assignment[slot] = index
        remaining.remove(index)
        open_slots.remove(slot)
    groups = []
    start = 0
    slots = spec["slots"]
    while start < len(slots):
        end = start + 1
        while end < len(slots) and slots[end] == slots[start]:
            end += 1
        groups.append((start, end))
        start = end
    for begin, end in groups:
        filled = [assignment[slot] for slot in range(begin, end) if slot in assignment]
        for slot in range(begin, end):
            assignment.pop(slot, None)
        # Empty identical slots stay at the front so the order constraint holds.
        for offset, index in enumerate(sorted(filled)):
            assignment[end - len(filled) + offset] = index
    out_of_position = sorted(remaining)
    return assignment, out_of_position


def _greedy_values(spec, indexes, pool, variables, left, net, chemistry):
    """A complete feasible 0/1 assignment, or None."""
    costs = {index: _effective_cost(pool[index], left, net) for index in indexes}
    order = sorted(indexes, key=lambda i: (costs[i], -pool[i]["rating"], i))
    chosen = []
    assets = set()
    for index in order:
        if len(chosen) >= spec["n"]:
            break
        if pool[index]["asset"] in assets:
            continue
        chosen.append(index)
        assets.add(pool[index]["asset"])
    if len(chosen) != spec["n"]:
        return None
    assignment, _oop = _assign_slots(chosen, spec, pool)
    in_position_indexes = set(assignment.values())
    in_position = [pool[index] for index in chosen if index in in_position_indexes]
    chem_total, _per = _squad_chem(in_position, chemistry)
    chosen_cards = [pool[index] for index in chosen]
    if not _meets(spec, chosen_cards, in_position, chem_total):
        return None

    y, x, o, c = variables["y"], variables["x"], variables["o"], variables["c"]
    values = {var.name: 0 for var in list(y.values()) + list(o.values()) + list(c.values()) + list(x.values())}
    for index in indexes:
        if index in chosen:
            values[y[index].name] = 1
        placed = next((slot for slot, owner in assignment.items() if owner == index), None)
        if placed is None and index in chosen:
            values[o[index].name] = 1
    for slot, index in assignment.items():
        values[x[index, slot].name] = 1
        values[o[index].name] = 0

    counts = {
        key: collections.Counter(pool[index][key] for index in in_position_indexes)
        for key in ("club", "league", "nation")
    }
    for (key, group, step), var in variables["bins"].items():
        values[var.name] = 1 if counts[key][group] >= step else 0
    for index in indexes:
        if index not in in_position_indexes:
            values[c[index].name] = 0
            continue
        card = pool[index]
        raw = sum(values[variables["bins"][key, card[key], step].name] for key, steps in chemistry.items() for step in steps)
        values[c[index].name] = min(3, raw)
    for (key, group), var in variables["ons"].items():
        if key == "club" and not spec.get("count_linked_clubs", True):
            total = sum(
                1 for index in chosen if pool[index].get("club_raw", pool[index]["club"]) == group
            )
        else:
            total = sum(1 for index in chosen if pool[index][key] == group)
        values[var.name] = 1 if total >= 1 else 0
    for (key, group), var in variables["zs"].items():
        values[var.name] = 0
    for key, lo, _hi in (
        ("club", "same_club_min", "same_club_max"),
        ("league", "same_league_min", "same_league_max"),
        ("nation", "same_nation_min", "same_nation_max"),
    ):
        if lo not in spec:
            continue
        totals = collections.Counter(pool[index][key] for index in chosen)
        for group, total in totals.items():
            if total >= spec[lo] and (key, group) in variables["zs"]:
                values[variables["zs"][key, group].name] = 1
    return values


def _add_count_bounds(model, spec, groups, prefix):
    for key, lo, hi in (
        ("club", "clubs_min", "clubs_max"),
        ("league", "leagues_min", "leagues_max"),
        ("nation", "nations_min", "nations_max"),
    ):
        if lo not in spec and hi not in spec:
            continue
        if key not in groups:
            continue
        present = groups[key]
        flags = {group: pulp.LpVariable(f"{prefix}on_{key}_{group}", cat="Binary") for group in present}
        big = max(11, spec["n"])
        for group, total in present.items():
            model += total <= big * flags[group]
            model += flags[group] <= total
        if lo in spec:
            model += pulp.lpSum(flags.values()) >= spec[lo]
        if hi in spec:
            model += pulp.lpSum(flags.values()) <= spec[hi]
        yield key, flags


def _solve_legacy(
    spec, pool, left, storage, *, net=False, seconds=180, chemistry=None, exact_model=False, threads=None
):
    """Solve one SBC. ``left`` is decremented only when a full squad is returned."""
    chemistry = chemistry or DEFAULT_CHEMISTRY
    canonical = canonical_trim(pool, spec, left)
    indexes = canonical if exact_model else drop_dominated(canonical, pool, spec, left, net)
    prefix = f"s{spec['id']}_"
    model = pulp.LpProblem(f"{prefix}sbc", pulp.LpMinimize)
    y = {i: pulp.LpVariable(f"{prefix}y{i}", cat="Binary") for i in indexes}
    o = {i: pulp.LpVariable(f"{prefix}o{i}", cat="Binary") for i in indexes}
    x = {
        (i, slot): pulp.LpVariable(f"{prefix}x{i}_{slot}", cat="Binary")
        for i in indexes
        for slot, name in enumerate(spec["slots"])
        if name in pool[i]["pos"]
    }
    in_pos = {i: pulp.lpSum(var for (card, _slot), var in x.items() if card == i) for i in indexes}
    for i in indexes:
        model += y[i] == in_pos[i] + o[i]
    for slot in range(len(spec["slots"])):
        model += pulp.lpSum(var for (_card, placed), var in x.items() if placed == slot) <= 1
    model += pulp.lpSum(y.values()) == spec["n"]
    for asset in {pool[i]["asset"] for i in indexes}:
        model += pulp.lpSum(y[i] for i in indexes if pool[i]["asset"] == asset) <= 1

    links = {}
    bins = {}
    for key, steps in chemistry.items():
        for group in {pool[i][key] for i in indexes}:
            count = pulp.lpSum(in_pos[i] for i in indexes if pool[i][key] == group)
            flags = [pulp.LpVariable(f"{prefix}b_{key}_{group}_{step}", cat="Binary") for step in steps]
            for flag, step in zip(flags, steps):
                model += count >= step * flag
            links[key, group] = pulp.lpSum(flags)
            for flag, step in zip(flags, steps):
                bins[key, group, step] = flag
    chem = {i: pulp.LpVariable(f"{prefix}c{i}", 0, 3, cat="Integer") for i in indexes}
    for i in indexes:
        model += chem[i] <= 3 * in_pos[i]
        card = pool[i]
        model += chem[i] <= links["club", card["club"]] + links["league", card["league"]] + links["nation", card["nation"]]
    model += pulp.lpSum(chem.values()) >= spec["chem"]

    def selected(pred):
        return pulp.lpSum(y[i] for i in indexes if pred(pool[i]))

    def grouped(key):
        return {group: pulp.lpSum(y[i] for i in indexes if pool[i][key] == group) for group in {pool[i][key] for i in indexes}}

    if "anchor" in spec:
        model += selected(lambda card: card["club"] in spec["anchor"][0]) >= spec["anchor"][1]
    if "nation" in spec:
        model += selected(lambda card: card["nation"] == spec["nation"][0]) >= spec["nation"][1]
    if "league" in spec:
        model += selected(lambda card: card["league"] == spec["league"][0]) >= spec["league"][1]
    if "gold_min" in spec:
        model += selected(lambda card: card["rating"] >= 75) >= spec["gold_min"]
    if "rating_sum" in spec:
        model += pulp.lpSum(pool[i]["rating"] * y[i] for i in indexes) >= spec["rating_sum"]
    for rule in spec.get("rating_floors") or []:
        model += selected(lambda card, rule=rule: card["rating"] >= rule["min"]) >= int(rule["count"])
    for rule in spec.get("item_score_floors") or []:
        model += selected(lambda card, rule=rule: card.get("score", 0) >= rule["min"]) >= int(rule["count"])
    if spec.get("team_rating_min"):
        add_team_rating(
            model,
            [(y[i], pool[i]["rating"], 1) for i in indexes],
            spec["n"],
            int(spec["team_rating_min"]),
            prefix,
        )

    groups = {key: grouped(key) for key in ("club", "league", "nation")}
    count_groups = dict(groups)
    if not spec.get("count_linked_clubs", True):
        raw_ids = {pool[i].get("club_raw", pool[i]["club"]) for i in indexes}
        count_groups["club"] = {
            raw: pulp.lpSum(
                y[i] for i in indexes if pool[i].get("club_raw", pool[i]["club"]) == raw
            )
            for raw in raw_ids
        }
    ons = {}
    for key, flags in _add_count_bounds(model, spec, count_groups, prefix):
        ons[key] = flags
    # Flatten ons to (key, group) -> var for the warm start.
    on_vars = {(key, group): var for key, flags in ons.items() for group, var in flags.items()}
    z_vars = {}
    for key, lo, hi in (
        ("club", "same_club_min", "same_club_max"),
        ("league", "same_league_min", "same_league_max"),
        ("nation", "same_nation_min", "same_nation_max"),
    ):
        present = groups[key]
        if hi in spec:
            for total in present.values():
                model += total <= spec[hi]
        if lo in spec:
            flags = {group: pulp.LpVariable(f"{prefix}z_{key}_{group}", cat="Binary") for group in present}
            for group, total in present.items():
                model += total >= spec[lo] * flags[group]
                z_vars[key, group] = flags[group]
            model += pulp.lpSum(flags.values()) >= 1

    owned_now = {i: left[pool[i]["rid"]] > 0 for i in indexes}
    cash = pulp.lpSum(y[i] * pool[i]["price"] for i in indexes if not owned_now[i])
    fodder = pulp.lpSum(y[i] * pool[i]["price"] for i in indexes if owned_now[i])
    # Default: coins, then owned-card value. --net: coins plus 95% of owned value
    # (100 * cash + 95 * fodder, so the economic net is the objective / 100).
    model += (100 * cash + 95 * fodder) if net else (1000 * cash + fodder)

    if not exact_model:
        for slot in range(len(spec["slots"]) - 1):
            if spec["slots"][slot] != spec["slots"][slot + 1]:
                continue
            earlier = [(i + 1) * x[i, slot] for i in indexes if (i, slot) in x]
            later = [(i + 1) * x[i, slot + 1] for i in indexes if (i, slot + 1) in x]
            if earlier or later:
                model += pulp.lpSum(earlier) <= pulp.lpSum(later)

    start = None
    if not exact_model and indexes:
        start = _greedy_values(
            spec,
            indexes,
            pool,
            {"y": y, "x": x, "o": o, "c": chem, "bins": bins, "ons": on_vars, "zs": z_vars},
            left,
            net,
            chemistry,
        )
    solver = _HiGHSStart(msg=False, timeLimit=float(seconds), start=start, threads=threads)
    model.solve(solver)
    pulp_status = pulp.LpStatus.get(model.status, "NotSolved")
    try:
        status, objective, bound, gap = _gap_report(getattr(model, "solverModel", None))
    except Exception:
        status = pulp_status
        objective = _finite(pulp.value(model.objective))
        bound = None
        gap = None

    rows = []
    picked = [i for i in indexes if (y[i].value() or 0) > 0.5]
    complete = len(picked) == spec["n"] and status not in {"Infeasible", "NotSolved"}
    if complete:
        for i in picked:
            card = pool[i]
            mine = owned_now[i]
            if mine:
                left[card["rid"]] -= 1
            rows.append(
                {
                    "name": card["name"],
                    "rating": card["rating"],
                    "pos": sorted(card["pos"]),
                    "inpos": (pulp.value(in_pos[i]) or 0) > 0.5,
                    "chem": round(chem[i].value() or 0),
                    "owned": mine,
                    "storage": bool(mine and card["rid"] in storage),
                    "cash": 0 if mine else card["price"],
                    "value": card["price"],
                    "meta": round(card["meta"], 1),
                    "club": card["club"],
                    "league": card["league"],
                    "nation": card["nation"],
                    "rid": card["rid"],
                }
            )
        rows.sort(key=lambda row: (not row["owned"], -row["rating"], row["name"]))
    else:
        rows = []
        if status == "Optimal":
            status = "NotSolved"
    cash_total = sum(row["cash"] for row in rows)
    fodder_total = sum(row["value"] for row in rows if row["owned"])
    return {
        "id": spec["id"],
        "name": spec["name"],
        "status": status,
        "pulp_status": pulp_status,
        "objective": objective,
        "best_bound": bound,
        "mip_gap": gap,
        "pool": len(indexes),
        "canonical_pool": len(canonical),
        "chem": sum(row["chem"] for row in rows),
        "cash": cash_total,
        "fodder": fodder_total,
        "warm_start": bool(start) and not exact_model,
        "warm_start_source": "greedy" if start and not exact_model else None,
        "engine": "highs",
        "objective_mode": "net" if net else "weighted",
        "formulation": "legacy",
        "players": rows,
    }


def solve_sbc(
    spec,
    pool,
    left,
    storage,
    *,
    net=False,
    seconds=180,
    chemistry=None,
    exact_model=False,
    formulation=None,
    objective_mode=None,
    engine="highs",
    threads=None,
    plan_squads=None,
):
    """Solve one SBC.

    ``formulation="legacy"`` is the previous per-card model and the scaled
    objective. The default formulation is the tighter integer model. Its
    default objective is lexicographic (coins, then owned value). ``--net``
    and ``objective_mode="net"`` keep the single weighted net objective.
    ``exact_model`` forces the legacy constraints with dominance, slot
    symmetry and the greedy start turned off.
    """
    if exact_model or formulation == "legacy":
        return _solve_legacy(
            spec,
            pool,
            left,
            storage,
            net=net,
            seconds=seconds,
            chemistry=chemistry,
            exact_model=bool(exact_model),
            threads=threads,
        )
    mode = objective_mode or ("net" if net else "lex")
    from eafc.sbc.shared.strong import solve_strong

    result = solve_strong(
        spec,
        pool,
        left,
        storage,
        net=net,
        seconds=seconds,
        chemistry=chemistry,
        objective_mode=mode,
        engine=engine,
        threads=threads,
        plan_squads=plan_squads,
    )
    result["formulation"] = "strong"
    return result


def _solve_squad_payload(payload):
    """Process entry point. ``left`` is copied by the parent before the call."""
    spec, pool, left, storage, options = payload
    return solve_sbc(spec, pool, collections.Counter(left), set(storage), **options)


def _squad_fits(squad, spec, left):
    if squad.get("status") == "Infeasible":
        return True
    if squad.get("status") != "Optimal":
        return False
    if len(squad.get("players") or []) != spec["n"]:
        return False
    need = collections.Counter()
    for row in squad["players"]:
        if row["owned"]:
            need[row["rid"]] += 1
    return all(left[rid] >= count for rid, count in need.items())


def _consume_squad(squad, left):
    for row in squad["players"]:
        if row["owned"]:
            left[row["rid"]] -= 1


def solve_squads(
    specs,
    pool,
    left,
    storage,
    *,
    net=False,
    seconds=180,
    chemistry=None,
    exact_model=False,
    done=(),
    jobs=1,
    engine="highs",
    threads=None,
    plan_squads=None,
    formulation=None,
    objective_mode=None,
):
    """Solve specs from highest chemistry to lowest, skipping done ids.

    Equal chemistry keeps ``sequence`` order. Owned copies are consumed in
    that order. With ``jobs`` above 1, each pending SBC is solved in its own
    process against the starting inventory, then accepted in order when its
    owned cards are still free. A squad that needs a card an earlier SBC took
    is solved again on the reduced inventory, so the objective matches the
    sequential run. Equal-cost cards can still swap.
    """
    skipped = []
    pending = []
    done_ids = {int(item) for item in done}
    for spec in specs:
        if int(spec["id"]) in done_ids:
            skipped.append(spec["id"])
        else:
            pending.append(spec)
    pending.sort(key=lambda spec: (-spec["chem"], spec.get("sequence", spec["id"])))
    options = {
        "net": net,
        "seconds": seconds,
        "chemistry": chemistry,
        "exact_model": exact_model,
        "formulation": formulation,
        "objective_mode": objective_mode,
        "engine": engine,
        "threads": threads,
        "plan_squads": plan_squads,
    }

    def sequential(items):
        solved = []
        for spec in items:
            solved.append(solve_sbc(spec, pool, left, storage, **options))
        return solved

    if jobs <= 1 or len(pending) <= 1 or exact_model:
        return sequential(pending), skipped

    payloads = [
        (spec, pool, dict(left), set(storage), options)
        for spec in pending
    ]
    try:
        ctx = multiprocessing.get_context("spawn")
        with ctx.Pool(processes=min(int(jobs), len(pending))) as pool_workers:
            parallel = pool_workers.map(_solve_squad_payload, payloads)
    except Exception as exc:
        print(f"parallel solve unavailable ({exc}); solving sequentially", flush=True)
        return sequential(pending), skipped

    by_id = {int(spec["id"]): (spec, squad) for spec, squad in zip(pending, parallel)}
    squads = []
    for spec in pending:
        _spec, squad = by_id[int(spec["id"])]
        if _squad_fits(squad, spec, left):
            if squad.get("status") != "Infeasible":
                _consume_squad(squad, left)
            squad = dict(squad)
            squad["search"] = "parallel"
            squads.append(squad)
        else:
            resolved = solve_sbc(spec, pool, left, storage, **options)
            resolved = dict(resolved)
            resolved["search"] = "resolved"
            squads.append(resolved)
    return squads, skipped
