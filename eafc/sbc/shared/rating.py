"""Squad rating for upgrade-style SBCs.

The integer used here is the usual SBC squad rating on the submitted
players only: floor(average + the total amount by which players sit above
that average). It is not the 18-player club squad rating, and it is not the
raw rating sum the canonical Liverpool spec still uses.
"""

import pulp


def squad_rating(ratings):
    """Floor of average plus excess over that average. Empty squad is 0."""
    values = [int(r) for r in ratings]
    n = len(values)
    if n <= 0:
        return 0
    total = sum(values)
    above = [rating for rating in values if n * rating > total]
    k = len(above)
    numer = total + (n * sum(above) - k * total)
    return numer // n


def add_team_rating(model, selections, n, minimum, prefix):
    """Constrain the submitted squad rating.

    ``selections`` is a list of ``(count, rating, upper)``. ``count`` is a
    PuLP expression, ``upper`` is the largest value that count can take.
    The constraint is the integer form of ``squad_rating``: with ``S`` the
    rating sum and ``e`` the total ``max(0, n*rating - S)`` over selected
    cards, require ``S + e >= minimum * n``.
    """
    minimum = int(minimum)
    n = int(n)
    if n <= 0 or minimum <= 0 or not selections:
        if minimum > 0 and n > 0 and not selections:
            model += 0 >= minimum * n
        return
    cap = max([99] + [int(rating) for _count, rating, _ub in selections])
    big = n * cap
    total = pulp.lpSum(int(rating) * count for count, rating, _ub in selections)
    excess = []
    for index, (count, rating, upper) in enumerate(selections):
        upper = int(upper)
        rating = int(rating)
        if upper <= 0:
            continue
        above = pulp.LpVariable(f"{prefix}tr_b{index}", cat="Binary")
        spill = pulp.LpVariable(f"{prefix}tr_u{index}", lowBound=0, upBound=big, cat="Integer")
        # above == 1 exactly when this rating is strictly above the squad average.
        model += total <= n * rating - 1 + big * (1 - above)
        model += total >= n * rating - big * above
        model += spill <= big * above
        model += spill >= n * rating - total - big * (1 - above)
        model += spill <= n * rating - total + big * (1 - above)
        picks = [pulp.LpVariable(f"{prefix}tr_k{index}_{k}", cat="Binary") for k in range(upper + 1)]
        model += pulp.lpSum(picks) == 1
        model += count == pulp.lpSum(k * picks[k] for k in range(upper + 1))
        parts = []
        for k, pick in enumerate(picks):
            part = pulp.LpVariable(f"{prefix}tr_w{index}_{k}", lowBound=0, upBound=big, cat="Integer")
            model += part <= big * pick
            model += part <= spill
            model += part >= spill - big * (1 - pick)
            parts.append(k * part)
        excess.append(pulp.lpSum(parts))
    model += total + pulp.lpSum(excess) >= minimum * n
