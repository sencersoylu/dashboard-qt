"""Async REST client. Endpoint inventory matches renderer/api/*.ts."""

from __future__ import annotations

import logging
from typing import Any

import httpx
from PySide6.QtCore import QObject, Signal

from app import config

log = logging.getLogger(__name__)


def _translate(exc: Exception) -> str:
    """Turkish error message — mirrors handleApiError() in renderer/api/index.ts."""
    if isinstance(exc, httpx.TimeoutException):
        return "Sunucu zaman aşımı (10 sn)."
    if isinstance(exc, httpx.ConnectError) or isinstance(exc, ConnectionError):
        return "Sunucuya bağlanılamadı."
    if isinstance(exc, httpx.HTTPStatusError):
        code = exc.response.status_code
        if code == 404:
            return "İstek bulunamadı (404)."
        if code >= 500:
            return f"Sunucu hatası ({code})."
        return f"İstek başarısız ({code})."
    return f"Bilinmeyen hata: {exc.__class__.__name__}"


class RestClient(QObject):
    errorOccurred = Signal(str)

    def __init__(self) -> None:
        super().__init__()
        self._client = httpx.AsyncClient(
            base_url=config.REST_BASE_URL, timeout=config.REST_TIMEOUT_SECONDS
        )

    async def _get(self, path: str) -> Any | None:
        try:
            r = await self._client.get(path)
            r.raise_for_status()
            return r.json()
        except Exception as exc:
            log.warning("GET %s failed: %s", path, exc)
            self.errorOccurred.emit(_translate(exc))
            return None

    async def _post(self, path: str, json: Any | None = None) -> Any | None:
        try:
            r = await self._client.post(path, json=json)
            r.raise_for_status()
            return r.json()
        except Exception as exc:
            log.warning("POST %s failed: %s", path, exc)
            self.errorOccurred.emit(_translate(exc))
            return None

    async def _put(self, path: str, json: Any | None = None) -> Any | None:
        try:
            r = await self._client.put(path, json=json)
            r.raise_for_status()
            return r.json()
        except Exception as exc:
            log.warning("PUT %s failed: %s", path, exc)
            self.errorOccurred.emit(_translate(exc))
            return None

    async def _delete(self, path: str) -> Any | None:
        try:
            r = await self._client.delete(path)
            r.raise_for_status()
            return r.json() if r.content else {}
        except Exception as exc:
            log.warning("DELETE %s failed: %s", path, exc)
            self.errorOccurred.emit(_translate(exc))
            return None

    # ---------------- Chambers ----------------
    async def get_chambers(self) -> Any | None:
        return await self._get("/chambers")

    async def get_chamber(self, chamber_id: int) -> Any | None:
        return await self._get(f"/chambers/{chamber_id}")

    async def create_chamber(self, body: dict) -> Any | None:
        return await self._post("/chambers", json=body)

    async def update_chamber(self, chamber_id: int, body: dict) -> Any | None:
        return await self._put(f"/chambers/{chamber_id}", json=body)

    async def delete_chamber(self, chamber_id: int) -> Any | None:
        return await self._delete(f"/chambers/{chamber_id}")

    async def get_latest_reading(self, chamber_id: int) -> Any | None:
        return await self._get(f"/chambers/{chamber_id}/readings/latest")

    async def get_chamber_readings(self, chamber_id: int) -> Any | None:
        return await self._get(f"/chambers/{chamber_id}/readings")

    async def update_alarm_level(self, chamber_id: int, body: dict) -> Any | None:
        return await self._put(f"/chambers/{chamber_id}/alarm-level", json=body)

    # ---------------- Alarms ----------------
    async def get_active_alarms(self) -> Any | None:
        return await self._get("/alarms")

    async def get_alarm_history(self) -> Any | None:
        return await self._get("/alarms/history")

    async def get_alarm_stats(self) -> Any | None:
        return await self._get("/alarms/stats")

    async def get_alarm(self, alarm_id: int) -> Any | None:
        return await self._get(f"/alarms/{alarm_id}")

    async def mute_alarm(self, alarm_id: int) -> Any | None:
        return await self._post(f"/alarms/{alarm_id}/mute")

    async def resolve_alarm(self, alarm_id: int) -> Any | None:
        return await self._post(f"/alarms/{alarm_id}/resolve")

    # ---------------- Settings / Calibration ----------------
    async def get_chamber_settings(self, chamber_id: int) -> Any | None:
        return await self._get(f"/settings/{chamber_id}")

    async def update_chamber_settings(self, chamber_id: int, body: dict) -> Any | None:
        return await self._put(f"/settings/{chamber_id}", json=body)

    async def get_active_calibration_points(self, chamber_id: int) -> Any | None:
        return await self._get(f"/settings/{chamber_id}/calibration-points")

    async def calibrate_reading(self, chamber_id: int, body: dict) -> Any | None:
        return await self._post(f"/settings/{chamber_id}/calibrate-reading", json=body)

    async def get_calibration_status(self, chamber_id: int) -> Any | None:
        return await self._get(f"/settings/{chamber_id}/calibration-status")

    # ---------------- Analytics ----------------
    async def get_dashboard_data(self) -> Any | None:
        return await self._get("/analytics/dashboard")

    async def get_o2_trends(self) -> Any | None:
        return await self._get("/analytics/trends")

    async def get_calibration_reports(self) -> Any | None:
        return await self._get("/analytics/reports/calibration-history")

    async def get_alarm_summary(self) -> Any | None:
        return await self._get("/analytics/reports/alarm-summary")
