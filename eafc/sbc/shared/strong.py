"""Tighter SBC formulation.

Cards that share rating, positions, linked club, raw club, league, nation,
version, price, owned/storage flag and item score collapse to one integer
variable. Chemistry is one count per club, league and nation. Threshold
indicators are forced both ways, and the big-M is the number of cards that
can sit in that group. Each in-position card is still capped at 3 chemistry.
Identical slots are ordered by group index.

The default objective is lexicographic: minimum coins, then minimum owned
value with coins fixed. ``weighted`` keeps ``1000 * coins + fodder`` so the
formulation can be compared with the legacy model. ``net`` keeps
``100 * coins + 95 * fodder``.
"""

import collections
import os

import pulp

from eafc.sbc.shared.model import (
    _HiGHSStart,
    _assign_slots,
    _gap_report,
    _meets,
    _squad_chem,
    canonical_trim,
    drop_dominated,
)
from eafc.sbc.shared.rating import add_team_rating
from eafc.sbc.shared.specs import DEFAULT_CHEMISTRY


def default_threads(threads):
    if threads is None:
        return max(1, min(8, os.cpu_count() or 1))
    return max(1, int(threads))


def _asset(card):
    return card.get("asset", card["rid"])


def _as_int(value):
    if value is None:
        return 0
    return int(round(float(value)))


class _Group:
    def __init__(self, gid, members, pool, owned, stored):
        card = pool[members[0]]
        self.gid = gid
        self.members = list(members)
        self.ub = len(members)
        self.rating = int(card["rating"])
        self.pos = set(card["pos"])
        self.club = card["club"]
        self.club_raw = card.get("club_raw", card["club"])
        self.league = card["league"]
        self.nation = card["nation"]
        self.price = int(card["price"])
        self.version = int(card.get("version", 0))
        self.score = int(card.get("score", 0))
        self.owned = bool(owned)
        self.storage = bool(stored)
        self.assets = tuple(_asset(pool[i]) for i in members)


def _collapse_key(card, owned, stored):
    return (
        int(card["rating"]),
        tuple(sorted(card["pos"])),
        card["club"],
        card.get("club_raw", card["club"]),
        card["league"],
        card["nation"],
        int(card.get("version", 0)),
        int(card["price"]),
        bool(owned),
        bool(stored),
        int(card.get("score", 0)),
    )


def drop_dominated_lex(indexes, pool, spec, left):
    """Lexicographic version of ``drop_dominated``.

    Cost is (coins, fodder). An owned card costs no coins. A card is dropped
    only when at least ``n`` strictly cheaper cards share its rating, linked
    club, league and nation and can play every position it can play.
    """
    groups = collections.defaultdict(list)
    for index in indexes:
        card = pool[index]
        groups[card["rating"], card["club"], card["league"], card["nation"]].append(index)

    def cost(index):
        card = pool[index]
        if left[card["rid"]] > 0:
            return (0, int(card["price"]))
        return (int(card["price"]), 0)

    needed = spec["n"]
    drop = set()
    for members in groups.values():
        costs = {index: cost(index) for index in members}
        for index in members:
            positions = set(pool[index]["pos"])
            cheaper = 0
            for other in members:
                if other == index:
                    continue
                if positions <= set(pool[other]["pos"]) and costs[other] < costs[index]:
                    cheaper += 1
            if cheaper >= needed:
                drop.add(index)
    return [index for index in indexes if index not in drop]


def build_groups(spec, pool, left, storage, *, net, objective_mode):
    canonical = canonical_trim(pool, spec, left)
    if objective_mode == "lex" and not net:
        indexes = drop_dominated_lex(canonical, pool, spec, left)
    else:
        indexes = drop_dominated(canonical, pool, spec, left, net)
    bundles = collections.defaultdict(list)
    for index in indexes:
        card = pool[index]
        owned = left[card["rid"]] > 0
        stored = bool(owned and card["rid"] in storage)
        bundles[_collapse_key(card, owned, stored)].append(index)
    asset_count = collections.Counter(_asset(pool[index]) for index in indexes)
    blocks = []
    for members in bundles.values():
        members = sorted(members, key=lambda i: (pool[i]["rid"], i))
        clean = [i for i in members if asset_count[_asset(pool[i])] == 1]
        dirty = [i for i in members if asset_count[_asset(pool[i])] != 1]
        if clean:
            blocks.append(clean)
        for index in dirty:
            blocks.append([index])
    blocks.sort(key=lambda members: (pool[members[0]]["rid"], members[0]))
    groups = []
    for gid, members in enumerate(blocks):
        card = pool[members[0]]
        owned = left[card["rid"]] > 0
        stored = bool(owned and card["rid"] in storage)
        groups.append(_Group(gid, members, pool, owned, stored))
    return groups, indexes, canonical


def _blank(spec, status, pool_size, canonical_size, **extra):
    result = {
        "id": spec["id"],
        "name": spec["name"],
        "status": status,
        "pulp_status": status,
        "objective": None,
        "best_bound": None,
        "mip_gap": None,
        "pool": pool_size,
        "canonical_pool": canonical_size,
        "groups": extra.pop("groups", 0),
        "chem": 0,
        "cash": 0,
        "fodder": 0,
        "warm_start": False,
        "warm_start_source": None,
        "engine": extra.pop("engine", "highs"),
        "objective_mode": extra.pop("objective_mode", "lex"),
        "gap_metric": extra.pop("gap_metric", None),
        "players": [],
    }
    result.update(extra)
    return result


def _rows_from(spec, pool, left, storage, chosen, placed, chemistry):
    if len(chosen) != spec["n"]:
        return None
    placed_at = set(placed.values())
    in_position = [pool[index] for index in chosen if index in placed_at]
    chem_total, parts = _squad_chem(in_position, chemistry)
    chem_of = {card["rid"]: part for card, part in zip(in_position, parts)}
    cards = [pool[index] for index in chosen]
    if not _meets(spec, cards, in_position, chem_total):
        return None
    rows = []
    for index in chosen:
        card = pool[index]
        mine = left[card["rid"]] > 0
        rows.append(
            {
                "name": card["name"],
                "rating": card["rating"],
                "pos": sorted(card["pos"]),
                "inpos": index in placed_at,
                "chem": int(chem_of.get(card["rid"], 0)),
                "owned": mine,
                "storage": bool(mine and card["rid"] in storage),
                "cash": 0 if mine else card["price"],
                "value": card["price"],
                "meta": round(card.get("meta", 0), 1),
                "club": card["club"],
                "league": card["league"],
                "nation": card["nation"],
                "rid": card["rid"],
            }
        )
    rows.sort(key=lambda row: (not row["owned"], -row["rating"], row["name"]))
    return rows, chem_total


def _consume(rows, left):
    for row in rows:
        if row["owned"]:
            left[row["rid"]] -= 1


def _hint_indexes(spec, pool, indexes, plan_squads, chemistry):
    if not plan_squads:
        return None, None
    squad = next((item for item in plan_squads if int(item.get("id", -1)) == int(spec["id"])), None)
    if not squad:
        return None, None
    by_rid = {pool[index]["rid"]: index for index in indexes}
    chosen = []
    for row in squad.get("players") or []:
        rid = row.get("rid")
        if rid is None:
            return None, None
        index = by_rid.get(int(rid))
        if index is None:
            return None, None
        chosen.append(index)
    if len(chosen) != spec["n"] or len(set(chosen)) != len(chosen):
        return None, None
    assignment, _oop = _assign_slots(chosen, spec, pool)
    in_position = [pool[index] for index in chosen if index in set(assignment.values())]
    chem_total, _parts = _squad_chem(in_position, chemistry)
    cards = [pool[index] for index in chosen]
    if not _meets(spec, cards, in_position, chem_total):
        return None, None
    return chosen, assignment


def _greedy_indexes(spec, pool, groups, left, net, objective_mode, chemistry):
    def cost(group):
        if net:
            return (95 * group.price) if group.owned else (100 * group.price)
        if objective_mode == "weighted":
            return group.price if group.owned else (1000 * group.price)
        if group.owned:
            return (0, group.price)
        return (group.price, 0)

    order = sorted(groups, key=lambda group: (cost(group), -group.rating, group.gid))
    chosen = []
    used_assets = set()
    for group in order:
        if len(chosen) >= spec["n"]:
            break
        for index in group.members:
            if len(chosen) >= spec["n"]:
                break
            asset = _asset(pool[index])
            if asset in used_assets:
                continue
            chosen.append(index)
            used_assets.add(asset)
    if len(chosen) != spec["n"]:
        return None, None
    assignment, _oop = _assign_slots(chosen, spec, pool)
    in_position = [pool[index] for index in chosen if index in set(assignment.values())]
    chem_total, _parts = _squad_chem(in_position, chemistry)
    if not _meets(spec, [pool[index] for index in chosen], in_position, chem_total):
        return None, None
    return chosen, assignment


def _scaled(cash, fodder, objective_mode):
    if objective_mode == "net":
        return float(100 * cash + 95 * fodder)
    return float(1000 * cash + fodder)


def solve_strong(
    spec,
    pool,
    left,
    storage,
    *,
    net=False,
    seconds=180,
    chemistry=None,
    objective_mode="lex",
    engine="highs",
    threads=None,
    plan_squads=None,
):
    chemistry = chemistry or DEFAULT_CHEMISTRY
    if net and objective_mode != "weighted":
        objective_mode = "net"
    groups, indexes, canonical = build_groups(
        spec, pool, left, storage, net=net, objective_mode=objective_mode
    )
    if engine == "cpsat":
        return _solve_cpsat(
            spec,
            pool,
            left,
            storage,
            groups,
            indexes,
            canonical,
            chemistry=chemistry,
            objective_mode=objective_mode,
            seconds=seconds,
            threads=8 if threads is None else default_threads(threads),
            plan_squads=plan_squads,
            net=net,
        )
    return _solve_highs(
        spec,
        pool,
        left,
        storage,
        groups,
        indexes,
        canonical,
        chemistry=chemistry,
        objective_mode=objective_mode,
        seconds=seconds,
        threads=default_threads(threads),
        plan_squads=plan_squads,
        net=net,
    )


def _prepare_choice(spec, pool, groups, indexes, chemistry, plan_squads, left, net, objective_mode):
    chosen, assignment = _hint_indexes(spec, pool, indexes, plan_squads, chemistry)
    if chosen is not None:
        return chosen, assignment, "plan"
    chosen, assignment = _greedy_indexes(spec, pool, groups, left, net, objective_mode, chemistry)
    if chosen is not None:
        return chosen, assignment, "greedy"
    return None, None, None


def _highs_start(spec, pool, groups, y, x, in_pos, chem_vars, chosen, assignment, chemistry):
    """A complete 0/1 chemistry start, or None when team-rating auxiliaries exist."""
    if "team_rating_min" in spec:
        return None
    by_index = {}
    for group in groups:
        for index in group.members:
            by_index[index] = group.gid
    counts = collections.Counter(by_index[index] for index in chosen)
    placed = collections.defaultdict(list)
    for slot, index in assignment.items():
        placed[by_index[index]].append(slot)
    values = {}
    for group in groups:
        gid = group.gid
        values[y[gid].name] = counts[gid]
        slots = placed.get(gid, [])
        values[in_pos[gid].name] = len(slots)
        for slot in chem_vars["eligible"][gid]:
            values[x[gid, slot].name] = 1 if slot in slots else 0
    return values


def _read_choice(groups, y, x, eligible):
    chosen = []
    placed = {}
    for group in groups:
        count = _as_int(y[group.gid].value())
        if count <= 0:
            continue
        count = min(count, group.ub)
        members = group.members[:count]
        chosen.extend(members)
        on = [slot for slot in eligible[group.gid] if (x[group.gid, slot].value() or 0) > 0.5]
        for slot, index in zip(on, members):
            placed[slot] = index
    return chosen, placed


def _finish(spec, pool, left, storage, rows, chem_total, report, base):
    cash = sum(row["cash"] for row in rows)
    fodder = sum(row["value"] for row in rows if row["owned"])
    proven = report["status"] == "Optimal" and (report["gap"] is None or report["gap"] <= 1e-8)
    if proven:
        objective = _scaled(cash, fodder, base["objective_mode"])
        bound = objective
        gap = 0.0
        status = "Optimal"
    else:
        status = report["status"]
        objective = report["objective"]
        bound = report["bound"]
        gap = report["gap"]
    if rows:
        _consume(rows, left)
    result = _blank(
        spec,
        status,
        base["pool"],
        base["canonical"],
        groups=base["groups"],
        engine=base["engine"],
        objective_mode=base["objective_mode"],
        gap_metric=report.get("metric"),
    )
    result.update(
        {
            "pulp_status": report.get("pulp_status", status),
            "objective": objective,
            "best_bound": bound,
            "mip_gap": gap,
            "chem": chem_total,
            "cash": cash,
            "fodder": fodder,
            "warm_start": bool(base.get("warm_source")),
            "warm_start_source": base.get("warm_source"),
            "players": rows,
            "stage1_status": report.get("stage1_status"),
            "stage2_status": report.get("stage2_status"),
        }
    )
    return result


def _solve_highs(
    spec,
    pool,
    left,
    storage,
    groups,
    indexes,
    canonical,
    *,
    chemistry,
    objective_mode,
    seconds,
    threads,
    plan_squads,
    net,
):
    pool_size = len(indexes)
    canonical_size = len(canonical)
    base = {
        "pool": pool_size,
        "canonical": canonical_size,
        "groups": len(groups),
        "engine": "highs",
        "objective_mode": objective_mode,
    }
    if spec["n"] <= 0 or sum(group.ub for group in groups) < spec["n"]:
        return _blank(spec, "Infeasible", pool_size, canonical_size, **_public(base))
    prefix = f"s{spec['id']}_"
    model = pulp.LpProblem(f"{prefix}sbc", pulp.LpMinimize)
    y = {group.gid: pulp.LpVariable(f"{prefix}y{group.gid}", lowBound=0, upBound=group.ub, cat="Integer") for group in groups}
    eligible = {
        group.gid: [slot for slot, name in enumerate(spec["slots"]) if name in group.pos] for group in groups
    }
    x = {
        (group.gid, slot): pulp.LpVariable(f"{prefix}x{group.gid}_{slot}", cat="Binary")
        for group in groups
        for slot in eligible[group.gid]
    }
    in_pos = {
        group.gid: pulp.LpVariable(f"{prefix}p{group.gid}", lowBound=0, upBound=group.ub, cat="Integer")
        for group in groups
    }
    for group in groups:
        gid = group.gid
        model += in_pos[gid] == pulp.lpSum(x[gid, slot] for slot in eligible[gid])
        model += y[gid] >= in_pos[gid]
    for slot in range(len(spec["slots"])):
        model += pulp.lpSum(var for (gid, placed), var in x.items() if placed == slot) <= 1
    model += pulp.lpSum(y.values()) == spec["n"]
    asset_groups = collections.defaultdict(list)
    for group in groups:
        for asset in set(group.assets):
            asset_groups[asset].append(group.gid)
    for gids in asset_groups.values():
        if len(gids) > 1:
            model += pulp.lpSum(y[gid] for gid in gids) <= 1

    flags = {}
    if spec["chem"] > 0:
        attr_ub = {}
        attr_count = {}
        for attr in ("club", "league", "nation"):
            values = {getattr(group, attr) for group in groups}
            for value in values:
                members = [group for group in groups if getattr(group, attr) == value and eligible[group.gid]]
                upper = min(spec["n"], sum(group.ub for group in members))
                if upper <= 0:
                    continue
                count = pulp.lpSum(in_pos[group.gid] for group in members)
                attr_ub[attr, value] = upper
                attr_count[attr, value] = count
                for step in chemistry[attr]:
                    flag = pulp.LpVariable(f"{prefix}b_{attr}_{value}_{step}", cat="Binary")
                    flags[attr, value, step] = flag
                    if upper < step:
                        model += flag == 0
                    else:
                        model += count >= step * flag
                        model += count <= (step - 1) + (upper - (step - 1)) * flag
        point_terms = collections.defaultdict(list)
        for (attr, value, _step), flag in flags.items():
            point_terms[attr, value].append(flag)
        point_expr = {key: pulp.lpSum(terms) for key, terms in point_terms.items()}

        def point_sum(group):
            terms = [point_expr[attr, getattr(group, attr)] for attr in ("club", "league", "nation") if (attr, getattr(group, attr)) in point_expr]
            return pulp.lpSum(terms) if terms else 0

        chem_total = []
        for group in groups:
            gid = group.gid
            if not eligible[gid]:
                continue
            if group.ub == 1:
                chem = pulp.LpVariable(f"{prefix}c{gid}", lowBound=0, upBound=3, cat="Integer")
                model += chem <= 3 * in_pos[gid]
                model += chem <= point_sum(group)
            else:
                # points * in-position count, then cap each card at 3.
                pieces = []
                for attr in ("club", "league", "nation"):
                    for step in chemistry[attr]:
                        flag = flags.get((attr, getattr(group, attr), step))
                        if flag is None:
                            continue
                        part = pulp.LpVariable(
                            f"{prefix}h{gid}_{attr}_{step}", lowBound=0, upBound=group.ub, cat="Integer"
                        )
                        model += part <= group.ub * flag
                        model += part <= in_pos[gid]
                        model += part >= in_pos[gid] - group.ub * (1 - flag)
                        pieces.append(part)
                chem = pulp.LpVariable(f"{prefix}c{gid}", lowBound=0, upBound=3 * group.ub, cat="Integer")
                model += chem <= 3 * in_pos[gid]
                model += chem <= (pulp.lpSum(pieces) if pieces else 0)
            chem_total.append(chem)
        if chem_total:
            model += pulp.lpSum(chem_total) >= spec["chem"]
        chem_vars = {"eligible": eligible, "flags": flags}
    else:
        chem_vars = {"eligible": eligible, "flags": {}}

    def selected(pred):
        return pulp.lpSum(y[group.gid] for group in groups if pred(group))

    if "anchor" in spec:
        model += selected(lambda group: group.club in spec["anchor"][0]) >= spec["anchor"][1]
    if "nation" in spec:
        model += selected(lambda group: group.nation == spec["nation"][0]) >= spec["nation"][1]
    if "league" in spec:
        model += selected(lambda group: group.league == spec["league"][0]) >= spec["league"][1]
    if "gold_min" in spec:
        model += selected(lambda group: group.rating >= 75) >= spec["gold_min"]
    if "rating_sum" in spec:
        model += pulp.lpSum(group.rating * y[group.gid] for group in groups) >= spec["rating_sum"]
    for rule in spec.get("rating_floors") or []:
        model += selected(lambda group, rule=rule: group.rating >= rule["min"]) >= rule["count"]
    for rule in spec.get("item_score_floors") or []:
        model += selected(lambda group, rule=rule: group.score >= rule["min"]) >= rule["count"]
    if "team_rating_min" in spec:
        add_team_rating(
            model,
            [(y[group.gid], group.rating, group.ub) for group in groups],
            spec["n"],
            spec["team_rating_min"],
            prefix,
        )

    club_attr = "club" if spec.get("count_linked_clubs", True) else "club_raw"
    _add_distinct(model, spec, groups, y, prefix, "club", club_attr, "clubs_min", "clubs_max")
    _add_distinct(model, spec, groups, y, prefix, "league", "league", "leagues_min", "leagues_max")
    _add_distinct(model, spec, groups, y, prefix, "nation", "nation", "nations_min", "nations_max")
    _add_same(model, spec, groups, y, prefix, "club", "same_club_min", "same_club_max")
    _add_same(model, spec, groups, y, prefix, "league", "same_league_min", "same_league_max")
    _add_same(model, spec, groups, y, prefix, "nation", "same_nation_min", "same_nation_max")

    for slot in range(len(spec["slots"]) - 1):
        if spec["slots"][slot] != spec["slots"][slot + 1]:
            continue
        earlier = pulp.lpSum((gid + 1) * var for (gid, placed), var in x.items() if placed == slot)
        later = pulp.lpSum((gid + 1) * var for (gid, placed), var in x.items() if placed == slot + 1)
        model += earlier <= later

    cash_expr = pulp.lpSum(group.price * y[group.gid] for group in groups if not group.owned)
    fodder_expr = pulp.lpSum(group.price * y[group.gid] for group in groups if group.owned)
    chosen, assignment, source = _prepare_choice(
        spec, pool, groups, indexes, chemistry, plan_squads, left, net, objective_mode
    )
    start = None
    if chosen is not None and "team_rating_min" not in spec:
        start = _highs_start(spec, pool, groups, y, x, in_pos, chem_vars, chosen, assignment, chemistry)
        if start is None:
            source = None
    base["warm_source"] = source if start else None

    def run(objective, start_values, metric):
        model.setObjective(objective)
        solver = _HiGHSStart(
            msg=False,
            timeLimit=float(seconds),
            threads=threads,
            gapRel=0.0,
            start=start_values,
        )
        model.solve(solver)
        pulp_status = pulp.LpStatus.get(model.status, "NotSolved")
        try:
            status, objective_value, bound, gap = _gap_report(getattr(model, "solverModel", None))
        except Exception:
            status, objective_value, bound, gap = pulp_status, None, None, None
        return {
            "status": status,
            "pulp_status": pulp_status,
            "objective": objective_value,
            "bound": bound,
            "gap": gap,
            "metric": metric,
        }

    if objective_mode == "lex":
        stage1 = run(cash_expr, start, "coins")
        stage1["stage1_status"] = stage1["status"]
        stage1["stage2_status"] = None
        proven_coins = stage1["status"] == "Optimal" and (stage1["gap"] is None or stage1["gap"] <= 1e-8)
        chosen_now, placed_now = _read_choice(groups, y, x, eligible)
        built = _rows_from(spec, pool, left, storage, chosen_now, placed_now, chemistry) if chosen_now else None
        if not proven_coins or built is None:
            if built is None:
                return _blank(
                    spec,
                    stage1["status"] if stage1["status"] != "Optimal" else "NotSolved",
                    pool_size,
                    canonical_size,
                    **_public(base),
                    objective=stage1["objective"],
                    best_bound=stage1["bound"],
                    mip_gap=stage1["gap"],
                    gap_metric="coins",
                    pulp_status=stage1["pulp_status"],
                    stage1_status=stage1["status"],
                )
            rows, chem_total = built
            return _finish(spec, pool, left, storage, rows, chem_total, stage1, base)
        opt_cash = sum(row["cash"] for row in built[0])
        model += cash_expr <= opt_cash
        # A card that costs more than the proven coin optimum can never be bought.
        for group in groups:
            if not group.owned and group.price > opt_cash:
                model += y[group.gid] == 0
        stage1_values = {}
        for var in model.variables():
            if var.value() is not None:
                stage1_values[var.name] = float(var.value())
        stage2 = run(fodder_expr, stage1_values, "fodder")
        stage2["stage1_status"] = stage1["status"]
        stage2["stage2_status"] = stage2["status"]
        chosen_now, placed_now = _read_choice(groups, y, x, eligible)
        built2 = _rows_from(spec, pool, left, storage, chosen_now, placed_now, chemistry) if chosen_now else None
        if built2 is None:
            rows, chem_total = built
            stage2["status"] = stage2["status"] if stage2["status"] != "Optimal" else "NotSolved"
            return _finish(spec, pool, left, storage, rows, chem_total, stage2, base)
        rows, chem_total = built2
        # Coins were fixed. A fodder gap is the remaining gap; a proven stage 2
        # closes the lexicographic objective.
        if stage2["status"] == "Optimal" and (stage2["gap"] is None or stage2["gap"] <= 1e-8):
            stage2["metric"] = "lex"
        return _finish(spec, pool, left, storage, rows, chem_total, stage2, base)

    metric = "net" if objective_mode == "net" else "weighted"
    objective = (100 * cash_expr + 95 * fodder_expr) if objective_mode == "net" else (1000 * cash_expr + fodder_expr)
    report = run(objective, start, metric)
    report["stage1_status"] = report["status"]
    report["stage2_status"] = None
    chosen_now, placed_now = _read_choice(groups, y, x, eligible)
    built = _rows_from(spec, pool, left, storage, chosen_now, placed_now, chemistry) if chosen_now else None
    if built is None:
        return _blank(
            spec,
            report["status"] if report["status"] != "Optimal" else "NotSolved",
            pool_size,
            canonical_size,
            **_public(base),
            objective=report["objective"],
            best_bound=report["bound"],
            mip_gap=report["gap"],
            gap_metric=metric,
            pulp_status=report["pulp_status"],
        )
    rows, chem_total = built
    return _finish(spec, pool, left, storage, rows, chem_total, report, base)


def _public(base):
    return {
        "groups": base["groups"],
        "engine": base["engine"],
        "objective_mode": base["objective_mode"],
        "warm_start": bool(base.get("warm_source")),
        "warm_start_source": base.get("warm_source"),
    }


def _add_distinct(model, spec, groups, y, prefix, label, attr, lo_key, hi_key):
    if lo_key not in spec and hi_key not in spec:
        return
    present = collections.defaultdict(list)
    for group in groups:
        present[getattr(group, attr)].append(group)
    flags = {}
    for value, members in present.items():
        total = pulp.lpSum(y[group.gid] for group in members)
        upper = min(spec["n"], sum(group.ub for group in members))
        flag = pulp.LpVariable(f"{prefix}on_{label}_{value}", cat="Binary")
        model += total <= upper * flag
        model += flag <= total
        flags[value] = flag
    if lo_key in spec:
        model += pulp.lpSum(flags.values()) >= spec[lo_key]
    if hi_key in spec:
        model += pulp.lpSum(flags.values()) <= spec[hi_key]


def _add_same(model, spec, groups, y, prefix, attr, lo_key, hi_key):
    if lo_key not in spec and hi_key not in spec:
        return
    present = collections.defaultdict(list)
    for group in groups:
        present[getattr(group, attr)].append(group)
    totals = {}
    for value, members in present.items():
        totals[value] = pulp.lpSum(y[group.gid] for group in members)
    if hi_key in spec:
        for total in totals.values():
            model += total <= spec[hi_key]
    if lo_key in spec:
        flags = []
        for value, total in totals.items():
            upper = min(spec["n"], sum(group.ub for group in present[value]))
            flag = pulp.LpVariable(f"{prefix}z_{attr}_{value}", cat="Binary")
            lo = spec[lo_key]
            model += total >= lo * flag
            if upper >= lo:
                model += total <= (lo - 1) + (upper - (lo - 1)) * flag
            else:
                model += flag == 0
            flags.append(flag)
        model += pulp.lpSum(flags) >= 1



def _group_payload(group):
    return {
        "gid": group.gid,
        "members": list(group.members),
        "ub": group.ub,
        "pos": sorted(group.pos),
        "club": group.club,
        "club_raw": group.club_raw,
        "league": group.league,
        "nation": group.nation,
        "rating": group.rating,
        "price": group.price,
        "owned": group.owned,
        "score": group.score,
        "assets": list(group.assets),
    }


def _solve_cpsat(
    spec,
    pool,
    left,
    storage,
    groups,
    indexes,
    canonical,
    *,
    chemistry,
    objective_mode,
    seconds,
    threads,
    plan_squads,
    net,
):
    """Solve in a fresh interpreter.

    OR-Tools and highspy each ship HiGHS. Importing both in this process
    raises an undefined-symbol error, so CP-SAT never shares it.
    """
    import pickle
    import subprocess
    import sys
    from pathlib import Path

    pool_size = len(indexes)
    canonical_size = len(canonical)
    chosen, assignment, source = _prepare_choice(
        spec, pool, groups, indexes, chemistry, plan_squads, left, net, objective_mode
    )
    base = {
        "pool": pool_size,
        "canonical": canonical_size,
        "groups": len(groups),
        "engine": "cpsat",
        "objective_mode": objective_mode,
        "warm_source": source if chosen is not None else None,
    }
    if spec["n"] <= 0 or sum(group.ub for group in groups) < spec["n"]:
        return _blank(spec, "Infeasible", pool_size, canonical_size, **_public(base))
    payload = {
        "spec": spec,
        "chemistry": {key: tuple(steps) for key, steps in chemistry.items()},
        "groups": [_group_payload(group) for group in groups],
        "objective_mode": objective_mode,
        "seconds": float(seconds),
        "threads": int(threads),
        "chosen": list(chosen) if chosen is not None else None,
        "assignment": {int(slot): int(index) for slot, index in (assignment or {}).items()},
        "warm_source": base["warm_source"],
    }
    engine = Path(__file__).resolve().parent / "cpsat_engine.py"
    try:
        completed = subprocess.run(
            [sys.executable, str(engine)],
            input=pickle.dumps(payload),
            capture_output=True,
            timeout=float(seconds) * (2 if objective_mode == "lex" else 1) + 60,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError("CP-SAT process timed out") from exc
    if completed.returncode != 0 or not completed.stdout:
        detail = (completed.stderr or b"").decode("utf-8", "replace").strip()
        if "No module named" in detail or "ortools" in detail.lower():
            raise RuntimeError(
                "CP-SAT needs the optional ortools package. The default HiGHS engine does not import it."
            )
        raise RuntimeError(detail or "CP-SAT process failed")
    report = pickle.loads(completed.stdout)
    chosen_now = report.get("chosen") or []
    placed = {int(slot): int(index) for slot, index in (report.get("placed") or {}).items()}
    built = _rows_from(spec, pool, left, storage, chosen_now, placed, chemistry) if chosen_now else None
    if built is None:
        status = report.get("status") or "NotSolved"
        if status == "Optimal":
            status = "NotSolved"
        return _blank(
            spec,
            status,
            pool_size,
            canonical_size,
            **_public(base),
            objective=report.get("objective"),
            best_bound=report.get("bound"),
            mip_gap=report.get("gap"),
            gap_metric=report.get("metric"),
            pulp_status=report.get("pulp_status"),
            stage1_status=report.get("stage1_status"),
            stage2_status=report.get("stage2_status"),
        )
    rows, chem_total = built
    return _finish(spec, pool, left, storage, rows, chem_total, report, base)
