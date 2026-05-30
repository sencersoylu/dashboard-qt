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
import re
import subprocess
import sys
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


# ---- labwc integration ---------------------------------------------------
#
# labwc's compositor moves fullscreen surfaces around based on its own
# heuristics — Qt's position request gets ignored once a second fullscreen
# app shows up. The reliable fix is a windowRule in ~/.config/labwc/rc.xml
# that pins each window title to a specific output. We auto-generate that
# block from windows-config.json so JSON stays the single source of truth.

_RC_PATH = Path.home() / ".config" / "labwc" / "rc.xml"
_BEGIN = "<!-- rsp-qt:BEGIN auto-generated, do not edit by hand -->"
_END = "<!-- rsp-qt:END -->"


def _build_rules_block(cfg: dict[str, Any]) -> str:
    """Render the <windowRules> block from windows-config entries that
    declare a string display (i.e. an output name). Numeric displays can't
    be expressed as a labwc output rule and are skipped."""
    lines: list[str] = []
    for win in cfg.get("windows", []):
        wid = win.get("id")
        disp = win.get("display")
        if not wid or not isinstance(disp, str):
            continue
        # ApplicationWindow.title in Main.qml is "RSP — <id>" — pin exact.
        lines.append(f'    <windowRule title="^RSP — {wid}$" output="{disp}"/>')
    if not lines:
        return ""
    return (
        f"  {_BEGIN}\n"
        "  <windowRules>\n"
        + "\n".join(lines) + "\n"
        "  </windowRules>\n"
        f"  {_END}"
    )


def sync_labwc_rules(cfg: dict[str, Any]) -> None:
    """Update ~/.config/labwc/rc.xml so its windowRules section mirrors the
    current windows-config. Idempotent — no-op when already in sync. Calls
    `labwc --reconfigure` after a write so the new rules apply without
    needing a session restart. Silent no-op on non-Linux (dev macOS)."""
    if sys.platform != "linux":
        return

    block = _build_rules_block(cfg)
    if not block:
        return

    if _RC_PATH.exists():
        text = _RC_PATH.read_text()
        if _BEGIN in text and _END in text:
            new_text = re.sub(
                re.escape(_BEGIN) + r".*?" + re.escape(_END),
                block,
                text,
                flags=re.DOTALL,
            )
        elif "</labwc_config>" in text:
            new_text = text.replace("</labwc_config>", block + "\n</labwc_config>")
        else:
            # Malformed or wrapper-less — just append.
            new_text = text.rstrip() + "\n" + block + "\n"
    else:
        _RC_PATH.parent.mkdir(parents=True, exist_ok=True)
        new_text = (
            '<?xml version="1.0"?>\n'
            "<labwc_config>\n"
            + block + "\n"
            "</labwc_config>\n"
        )
        text = ""

    if new_text == text:
        log.info("labwc rc.xml already in sync")
        return

    _RC_PATH.write_text(new_text)
    log.info("Updated labwc rc.xml windowRules at %s", _RC_PATH)
    # `labwc --reconfigure` needs LABWC_PID env var (set automatically when
    # labwc spawns the process). Outside a labwc-launched session (e.g. SSH)
    # it falls back to a useless no-op. Sending SIGHUP to the running labwc
    # process triggers the same reload and works in any context.
    try:
        subprocess.run(["pkill", "-HUP", "-x", "labwc"], check=False, timeout=2)
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        log.warning("Could not signal labwc to reload (%s); new rules apply next session", exc)
