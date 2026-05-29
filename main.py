"""Phase 1 bootstrap: AppState + four async clients on the qasync loop."""

from __future__ import annotations

import asyncio
import logging
import sys
from pathlib import Path

import qasync
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

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


def main() -> int:
    app = QGuiApplication(sys.argv)
    loop = qasync.QEventLoop(app)
    asyncio.set_event_loop(loop)

    state = AppState()
    plc = PlcClient(state)
    bcontrol = BControlClient()
    vitals = VitalsClient()
    rest = RestClient()

    engine = QQmlApplicationEngine()
    engine.addImportPath(str(QML_DIR))
    ctx = engine.rootContext()
    ctx.setContextProperty("appState", state)
    ctx.setContextProperty("plcClient", plc)
    ctx.setContextProperty("bcontrolClient", bcontrol)
    ctx.setContextProperty("vitalsClient", vitals)
    ctx.setContextProperty("restClient", rest)
    engine.load(QML_DIR / "Main.qml")

    if not engine.rootObjects():
        log.error("QML failed to load")
        return 1

    loop.create_task(plc.start())
    loop.create_task(bcontrol.start())
    loop.create_task(vitals.start())

    with loop:
        return loop.run_forever() or 0


if __name__ == "__main__":
    sys.exit(main())
