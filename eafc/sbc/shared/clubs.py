"""Linked-club union-find, matching the canonical Marquee solver.

``parent[root(v)] = root(club id)`` is applied once per linkedClubIds entry,
in the order clubs appear in base.json. Chemistry and every same-club /
club-count constraint use this root, so a men's club and its linked women's
club count as one club.
"""


def link_root(clubs):
    """Return ``root(club_id)`` built from EasySBC ``managerData.clubs``."""
    parent = {}

    def root(v):
        parent.setdefault(v, v)
        if parent[v] != v:
            parent[v] = root(parent[v])
        return parent[v]

    for club in clubs or []:
        for linked in club.get("linkedClubIds", []) or []:
            parent[root(linked)] = root(club["id"])
    return root


def identity_root(value):
    return value
