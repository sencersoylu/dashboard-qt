import pytest
from PySide6.QtCore import QCoreApplication, QSettings


@pytest.fixture(autouse=True)
def isolated_qsettings(tmp_path, monkeypatch):
    """Every test gets its own QSettings file under tmp_path."""
    QSettings.setDefaultFormat(QSettings.IniFormat)
    QSettings.setPath(QSettings.IniFormat, QSettings.UserScope, str(tmp_path))
    yield


@pytest.fixture(scope="session")
def qapp():
    """A single QCoreApplication for the whole test session."""
    app = QCoreApplication.instance() or QCoreApplication([])
    yield app
