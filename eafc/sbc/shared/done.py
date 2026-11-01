"""Local done-list of SBC set ids the solver should skip.

The public EasySBC sets feed sets ``solved`` false on every row. A logged-in
export is what carries ``solved: true`` for challenges already submitted.
"""

import json
from pathlib import Path


def load_done(path):
    """Return a set of integer SBC ids. Missing files mean nothing is done."""
    if not path:
        return set()
    file = Path(path)
    if not file.is_file():
        return set()
    raw = json.loads(file.read_text(encoding="utf-8-sig"))
    if isinstance(raw, list):
        return {int(item) for item in raw}
    return {int(item) for item in raw.get("ids", [])}


def write_done(path, ids):
    file = Path(path)
    file.parent.mkdir(parents=True, exist_ok=True)
    payload = {"ids": sorted(int(item) for item in ids)}
    file.write_text(json.dumps(payload, indent=1) + "\n", encoding="utf-8")
    return payload["ids"]


def sets_from_document(document):
    if isinstance(document, list):
        return document
    if isinstance(document, dict):
        for key in ("sets", "data", "items"):
            if isinstance(document.get(key), list):
                return document[key]
    raise ValueError("EasySBC sets document must be a list or an object with a sets list")


def solved_ids(document):
    """Ids whose ``solved`` field is exactly true.

    ``solvedCount`` and ``remainingCost`` are ignored. The public fetch leaves
    ``solved`` false even when those other fields are present.
    """
    found = set()
    for row in sets_from_document(document):
        if row.get("solved") is True and "id" in row:
            found.add(int(row["id"]))
    return found


def import_solved(document, existing=()):
    """Merge sets with ``solved: true`` into an existing done-list."""
    rows = sets_from_document(document)
    marked = solved_ids(rows)
    merged = set(int(item) for item in existing) | marked
    return merged, marked, len(rows)
