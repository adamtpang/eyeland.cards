"""Linked-club union-find, matching the canonical Marquee solver.

``parent[root(v)] = root(club id)`` is applied once per linkedClubIds entry,
in the order clubs appear in base.json. Chemistry, same-club constraints and
anchor clubs use this root.

EA's chemistry notes say affiliated men's and women's clubs link for
chemistry. They do not say whether a Clubs min/max requirement counts those
clubs as one. The default here stays the current behavior (one club). A spec
can set ``count_linked_clubs`` false to count raw club ids for clubs min/max
only.
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
