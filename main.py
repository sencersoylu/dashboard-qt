"""Phase 1 bootstrap: AppState + async clients on the qasync loop.

Each launch reads `~/.config/rsp-qt/windows-config.json` to decide which
pages open on which displays — and only starts the backend clients that
those pages actually need.
"""

from __future__ import annotations

import asyncio
import logging
import sys
from pathlib import Path

import qasync
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from app import window_config
from app.bcontrol_client import BControlClient
from app.plc_client import PlcClient
from app.rest_client import RestClient
from app.state import AppState
from app.vitals_client import VitalsClient

ROOT = Path(__file__).resolve().parent
QML_DIR = ROOT / "qml"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
log = logging.getLogger("rsp-qt")


# engineio's reconnect loop emits a stream of
#   ERROR engineio.client: packet queue is empty, aborting
# every time the socket transport blips. The library reconnects on its own
# and the message is harmless noise — drop it so the operator-facing log
# stays readable. Real disconnects still surface via app.plc_client.
class _DropEngineIOQueueAbort(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        return "packet queue is empty" not in record.getMessage()


logging.getLogger("engineio.client").addFilter(_DropEngineIOQueueAbort())


def main() -> int:
    app = QGuiApplication(sys.argv)
    loop = qasync.QEventLoop(app)
    asyncio.set_event_loop(loop)

    cfg = window_config.load()
    needed = window_config.required_clients(cfg)
    log.info(
        "Windows: %s; clients needed: %s",
        [w.get("id") for w in cfg["windows"]],
        sorted(needed) or "(none)",
    )
    # Mirror the per-window display assignment into ~/.config/labwc/rc.xml
    # so the compositor pins each window to its requested output. labwc's
    # fullscreen heuristic ignores Qt's own position request when multiple
    # apps compete for the same monitor — the rc.xml rule wins.
    window_config.sync_labwc_rules(cfg)

    state = AppState()
    plc = PlcClient(state) if "plc" in needed else None
    bcontrol = BControlClient() if "bcontrol" in needed else None
    vitals = VitalsClient() if "vitals" in needed else None
    rest = RestClient()  # cheap, no socket — keep available for any page

    engine = QQmlApplicationEngine()
    engine.addImportPath(str(QML_DIR))
    ctx = engine.rootContext()
    ctx.setContextProperty("appState", state)
    ctx.setContextProperty("plcClient", plc)
    ctx.setContextProperty("bcontrolClient", bcontrol)
    ctx.setContextProperty("vitalsClient", vitals)
    ctx.setContextProperty("restClient", rest)
    ctx.setContextProperty("windowsConfig", cfg["windows"])
    engine.load(QML_DIR / "Main.qml")

    if not engine.rootObjects():
        log.error("QML failed to load")
        return 1

    if plc is not None:
        loop.create_task(plc.start())
    if bcontrol is not None:
        loop.create_task(bcontrol.start())
    if vitals is not None:
        loop.create_task(vitals.start())

    with loop:
        return loop.run_forever() or 0


if __name__ == "__main__":
    sys.exit(main())
