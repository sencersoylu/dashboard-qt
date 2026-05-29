"""Network endpoints. Edit here, not in client code."""

from __future__ import annotations

import os

PLC_URL: str = os.environ.get("PLC_URL", "http://192.168.3.100:4000")
BCONTROL_URL: str = os.environ.get("BCONTROL_URL", "http://localhost:3001")
REST_BASE_URL: str = os.environ.get("REST_BASE_URL", "http://localhost:3001/api")
# Currently the ngrok endpoint hard-coded in renderer/pages/home.tsx.
# Replace with the production URL when known.
VITAL_SIGNS_URL: str = os.environ.get(
    "VITAL_SIGNS_URL", "https://6b07-83-111-109-94.ngrok-free.app"
)

REST_TIMEOUT_SECONDS: float = 10.0
