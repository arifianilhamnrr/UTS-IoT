"""Pengujian integrasi empat tantangan UTS."""
from datetime import datetime, timedelta, timezone

from app.database import SessionLocal
from app.models import Reading


def payload(**over):
    data = {
        "reading_id": "dev-01-0001",
        "device_id": "dev-01",
        "temperature": 26.5,
        "humidity": 61.0,
        "recorded_at": datetime.now(timezone.utc).isoformat(),
    }
    data.update(over)
    return data


# ---------------------------------------------------------------- Challenge 2
def test_valid_payload_tersimpan(client):
    res = client.post("/api/readings", json=payload())
    assert res.status_code == 201
    assert res.json()["duplicate"] is False
    assert res.json()["temperature"] == 26.5


def test_suhu_di_luar_rentang_ditolak(client):
    res = client.post("/api/readings", json=payload(temperature=35.0))
    assert res.status_code == 422
    body = res.json()
    assert body["status"] == "rejected"
    assert "20-30" in body["errors"][0]["message"]

    # Histori tidak bertambah dan log penolakan tercatat.
    assert client.get("/api/readings", params={"device_id": "dev-01"}).json() == []
    rejected = client.get("/api/rejected").json()
    assert len(rejected) == 1
    assert rejected[0]["payload"]["temperature"] == 35.0


def test_kelembapan_di_luar_rentang_ditolak(client):
    res = client.post("/api/readings", json=payload(humidity=120))
    assert res.status_code == 422
    assert "0-100" in res.json()["errors"][0]["message"]


def test_data_invalid_tidak_mengganti_data_valid_terakhir(client):
    client.post("/api/readings", json=payload())
    client.post("/api/readings", json=payload(reading_id="dev-01-0002", temperature=10))
    status = client.get("/api/devices/dev-01/status").json()
    assert status["last_reading"]["temperature"] == 26.5
    assert status["last_reading"]["reading_id"] == "dev-01-0001"


# ---------------------------------------------------------------- Challenge 3
def test_reading_id_sama_tidak_menambah_record(client):
    first = client.post("/api/readings", json=payload())
    second = client.post("/api/readings", json=payload())
    assert first.status_code == 201
    assert second.status_code == 200
    assert second.json()["duplicate"] is True
    rows = client.get("/api/readings", params={"device_id": "dev-01"}).json()
    assert len(rows) == 1


# ---------------------------------------------------------------- Challenge 1
def test_status_online_lalu_offline_setelah_60_detik(client):
    client.post("/api/readings", json=payload())
    assert client.get("/api/devices/dev-01/status").json()["status"] == "online"

    # Simulasikan data terakhir diterima 2 menit lalu.
    db = SessionLocal()
    row = db.query(Reading).first()
    row.received_at = datetime.now(timezone.utc) - timedelta(seconds=120)
    db.commit()
    db.close()

    status = client.get("/api/devices/dev-01/status").json()
    assert status["status"] == "offline"
    assert status["age_seconds"] >= 60

    # Data baru masuk -> status kembali online.
    client.post("/api/readings", json=payload(reading_id="dev-01-0002"))
    assert client.get("/api/devices/dev-01/status").json()["status"] == "online"


def test_device_tanpa_data_dianggap_offline(client):
    status = client.get("/api/devices/dev-99/status").json()
    assert status["status"] == "offline"
    assert status["last_seen"] is None


# ---------------------------------------------------------------- Challenge 4
def _seed(client, temps):
    for i, t in enumerate(temps):
        res = client.post(
            "/api/readings",
            json=payload(reading_id=f"dev-01-{i:04d}", temperature=t),
        )
        assert res.status_code == 201


def test_tren_naik(client):
    _seed(client, [24.0, 24.6, 25.2, 25.9, 26.8])
    trend = client.get("/api/devices/dev-01/trend").json()
    assert trend["trend"] == "naik"
    assert len(trend["temperatures"]) == 5


def test_tren_turun(client):
    _seed(client, [28.5, 27.9, 27.0, 26.2, 25.4])
    assert client.get("/api/devices/dev-01/trend").json()["trend"] == "turun"


def test_tren_stabil(client):
    _seed(client, [26.0, 26.1, 25.9, 26.0, 26.05])
    assert client.get("/api/devices/dev-01/trend").json()["trend"] == "stabil"


def test_tren_kurang_data(client):
    _seed(client, [26.0, 26.2])
    assert client.get("/api/devices/dev-01/trend").json()["trend"] == "insufficient_data"


def test_dashboard_menggabungkan_status_dan_tren(client):
    _seed(client, [24.0, 24.5, 25.0, 25.5, 26.0])
    body = client.get("/api/devices/dev-01/dashboard").json()
    assert body["status"]["status"] == "online"
    assert body["trend"]["trend"] == "naik"
    assert body["status"]["last_reading"]["temperature"] == 26.0
