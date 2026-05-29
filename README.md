# MY_APP_QT

PySide6 + QML port of the Nextron hyperbaric chamber HMI in `../MY_APP/`.

## Run (dev)

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
python main.py
```

## Test

```bash
pytest
```

## Status

Phase 0–1: bootstrap + state + network clients. No UI panels yet.
See `../MY_APP/docs/superpowers/specs/2026-05-29-qt-migration-design.md`.
