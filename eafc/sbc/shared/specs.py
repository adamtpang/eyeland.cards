"""Load committed SBC spec files and chemistry thresholds.

Specs are public challenge requirements. Personal club data does not belong
in them. A new daily SBC is a new JSON file, not a new script.
"""

import json
from pathlib import Path

# Position aliases applied to formation uniquePositions. This is the canonical
# map; side tags such as RDM are left unchanged unless a spec lists slots itself.
POSITION_ALIASES = {
    "RCB": "CB",
    "LCB": "CB",
    "RCM": "CM",
    "LCM": "CM",
    "RAM": "CAM",
    "LAM": "CAM",
    "RS": "ST",
    "LS": "ST",
}

# Canonical chemistry steps: a link of this size adds one chemistry point.
# Club is 2/4/7. The older FUTBIN checker in solve.py uses club 2/5/8; this
# solver does not.
DEFAULT_CHEMISTRY = {"club": (2, 4, 7), "league": (3, 5, 8), "nation": (2, 5, 8)}

SPEC_KEYS = {
    "id",
    "name",
    "formation",
    "slots",
    "n",
    "chem",
    "minr",
    "sequence",
    "anchor",
    "nation",
    "league",
    "clubs_min",
    "clubs_max",
    "leagues_min",
    "leagues_max",
    "nations_min",
    "nations_max",
    "same_club_min",
    "same_club_max",
    "same_league_min",
    "same_league_max",
    "same_nation_min",
    "same_nation_max",
    "gold_min",
    "rating_sum",
    "requirements_text",
    "source",
    "notes",
}


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def identity_root(value):
    return value


def load_chemistry(path=None):
    if path is None or not Path(path).is_file():
        return dict(DEFAULT_CHEMISTRY)
    raw = read_json(path)
    out = {}
    for key, default in DEFAULT_CHEMISTRY.items():
        values = raw.get(key, default)
        out[key] = tuple(int(v) for v in values)
    return out


def formation_slots(base, formation_id):
    formations = base["formations"]
    found = next(item for item in formations if item["id"] == formation_id)
    return [POSITION_ALIASES.get(pos, pos) for pos in found["uniquePositions"]]


def prepare_spec(spec, root=identity_root):
    """Normalize a spec into the shape the model checks.

    ``anchor``, ``nation`` and ``league`` become ``(ids or id, minimum)``
    tuples. Anchor club ids are passed through ``root`` so linked clubs match
    the pool.
    """
    missing = [key for key in ("id", "name", "slots") if key not in spec]
    if missing:
        raise ValueError(f"SBC spec {spec.get('id', spec.get('name'))} missing {missing}")
    prepared = dict(spec)
    prepared["id"] = int(spec["id"])
    prepared["slots"] = list(spec["slots"])
    prepared["n"] = int(spec.get("n", len(prepared["slots"])))
    prepared["chem"] = int(spec.get("chem", 0))
    prepared["minr"] = int(spec.get("minr", 0))
    prepared["sequence"] = int(spec.get("sequence", prepared["id"]))
    if "anchor" in spec and spec["anchor"]:
        anchor = spec["anchor"]
        clubs = anchor["clubs"] if isinstance(anchor, dict) else anchor[0]
        minimum = anchor["min"] if isinstance(anchor, dict) else anchor[1]
        prepared["anchor"] = ({root(int(club)) for club in clubs}, int(minimum))
    if "nation" in spec and isinstance(spec["nation"], dict):
        prepared["nation"] = (int(spec["nation"]["id"]), int(spec["nation"]["min"]))
    if "league" in spec and isinstance(spec["league"], dict):
        prepared["league"] = (int(spec["league"]["id"]), int(spec["league"]["min"]))
    return prepared


def load_spec_file(path, base=None, root=None):
    raw = read_json(path)
    if "id" not in raw:
        return None
    unknown = sorted(set(raw) - SPEC_KEYS)
    if unknown:
        raise ValueError(f"{path} has unknown spec keys: {', '.join(unknown)}")
    if "slots" not in raw:
        if not raw.get("formation"):
            raise ValueError(f"{path} needs slots or a formation id")
        if base is None:
            raise ValueError(f"{path} uses formation {raw['formation']} but no base.json was provided")
        raw = dict(raw)
        raw["slots"] = formation_slots(base, raw["formation"])
    return prepare_spec(raw, root or identity_root)


def load_specs(directory, base=None, root=None):
    paths = sorted(Path(directory).glob("*.json"))
    specs = []
    for path in paths:
        if path.name == "chemistry.json":
            continue
        spec = load_spec_file(path, base=base, root=root)
        if spec is not None:
            specs.append(spec)
    return specs
