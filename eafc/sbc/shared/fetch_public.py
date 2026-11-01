"""Read-only fetch of public EasySBC data.

Mirrors the canonical client's endpoints. Nothing here buys, submits, or
sends a club export. Inventory still has to be saved locally by hand.
"""

import json
from pathlib import Path
from urllib import request

API_ROOT = "https://api-fc27.easysbc.io/"


def api_url(path):
    return API_ROOT + path.lstrip("/")


def fetch_json(path, payload=None, timeout=40):
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    req = request.Request(
        api_url(path),
        data=body,
        headers={
            "Platform": "PC",
            "User-Agent": "Mozilla/5.0",
            "Content-Type": "application/json",
        },
    )
    with request.urlopen(req, timeout=timeout) as response:
        return json.load(response)


def write_json(path, document):
    file = Path(path)
    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_text(json.dumps(document, ensure_ascii=False), encoding="utf-8")
    return file


def fetch_base(dest):
    return write_json(dest, fetch_json("base-data"))


def fetch_challenges(set_id, dest):
    return write_json(dest, fetch_json(f"sbcs?setId={int(set_id)}"))


def fetch_player(resource_id, dest):
    return write_json(dest, fetch_json(f"players/{int(resource_id)}"))


def fetch_solutions(challenge_id, dest):
    """Public solution sample for one challenge. Failures are the caller's to catch."""
    payload = {
        "excludeGoldPlayers": False,
        "excludeSilverPlayers": False,
        "excludeBronzePlayers": False,
        "excludeSpecialPlayers": True,
    }
    return write_json(dest, fetch_json(f"sbcs/{int(challenge_id)}/solutions", payload))
