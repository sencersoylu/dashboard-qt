"""Phase 0 bootstrap: open a themed window. AppState is a temporary stub."""

import sys
from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

ROOT = Path(__file__).resolve().parent
QML_DIR = ROOT / "qml"


class _Phase0AppState(QObject):
    """Tiny stand-in so Main.qml can read/write darkMode in Phase 0.

    Replaced by app.state.AppState in Phase 1.
    """

    darkModeChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._dark = True

    @Property(bool, notify=darkModeChanged)
    def darkMode(self) -> bool:
        return self._dark

    @darkMode.setter
    def darkMode(self, v: bool) -> None:
        if self._dark != v:
            self._dark = v
            self.darkModeChanged.emit()


def main() -> int:
    app = QGuiApplication(sys.argv)
    state = _Phase0AppState()

    engine = QQmlApplicationEngine()
    engine.addImportPath(str(QML_DIR))
    engine.rootContext().setContextProperty("appState", state)
    engine.load(QML_DIR / "Main.qml")

    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
