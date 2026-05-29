"""Multi-window configuration loader.

Mirrors the React app's `~/.config/MY APP/windows-config.json` pattern. The
file lives at `~/.config/rsp-qt/windows-config.json` and looks like:

    {
      "windows": [
        {"id": "main",   "page": "Dashboard",  "display": 0, "fullscreen": true},
        {"id": "vitals", "page": "VitalSigns", "display": 1, "fullscreen": true}
      ]
    }

`page` references a QML file under `qml/pages/<page>.qml`. Each page declares
which backend clients it actually needs via PAGE_CLIENTS; `main.py` starts
only the union of those — so a dashboard-only setup doesn't dial vitals or
B-Control.
"""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any

log = logging.getLogger(__name__)

CONFIG_DIR = Path.home() / ".config" / "rsp-qt"
CONFIG_FILE = CONFIG_DIR / "windows-config.json"

# Page → required client identifiers. Anything not listed here gets the
# empty set (i.e. no clients started for it). Keep this in sync as pages
# get ported.
PAGE_CLIENTS: dict[str, list[str]] = {
    "Dashboard": ["plc"],
    "VitalSigns": ["vitals"],
    "Compressor": ["bcontrol"],
    "TechnicalRoom": ["plc", "bcontrol"],
    # Splash + Showcase don't drive real backend traffic.
    "Splash": [],
    "Showcase": [],
}

_DEFAULT_CONFIG: dict[str, Any] = {
    "windows": [
        {"id": "main", "page": "Dashboard", "display": 0, "fullscreen": True},
    ],
}


def load() -> dict[str, Any]:
    """Read the windows config, writing a default file on first run."""
    if not CONFIG_FILE.exists():
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        CONFIG_FILE.write_text(json.dumps(_DEFAULT_CONFIG, indent=2) + "\n")
        log.info("Created default windows config at %s", CONFIG_FILE)
        return _DEFAULT_CONFIG
    try:
        cfg = json.loads(CONFIG_FILE.read_text())
    except (OSError, ValueError) as exc:
        log.warning("Failed to read %s (%s) — using default", CONFIG_FILE, exc)
        return _DEFAULT_CONFIG
    if not isinstance(cfg, dict) or not isinstance(cfg.get("windows"), list):
        log.warning("Malformed config at %s — using default", CONFIG_FILE)
        return _DEFAULT_CONFIG
    return cfg


def required_clients(cfg: dict[str, Any]) -> set[str]:
    """Return the union of client IDs required by every configured page."""
    needed: set[str] = set()
    for win in cfg.get("windows", []):
        page = win.get("page")
        for client_id in PAGE_CLIENTS.get(page, []):
            needed.add(client_id)
    return needed
