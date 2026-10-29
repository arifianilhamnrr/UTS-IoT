import os
import tempfile

# DB terpisah untuk pengujian, harus di-set SEBELUM import app.
TEST_DB = os.path.join(tempfile.mkdtemp(prefix="iot-uts-"), "test.db")
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB}"
os.environ["STALE_AFTER_SECONDS"] = "60"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.database import Base, engine  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture()
def client():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as c:
        yield c
