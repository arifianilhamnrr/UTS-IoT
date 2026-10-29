"""FastAPI app: endpoint monitoring suhu & kelembapan.

Peta fitur -> endpoint
----------------------
Challenge 1 (offline)   : GET /api/devices/{device_id}/status
Challenge 2 (validasi)  : POST /api/readings  (422 + log rejected_readings)
Challenge 3 (dedupe)    : POST /api/readings  (unique reading_id)
Challenge 4 (tren)      : GET /api/devices/{device_id}/trend
Gabungan untuk Flutter  : GET /api/devices/{device_id}/dashboard
"""
import json
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import Body, Depends, FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import ValidationError
from sqlalchemy.orm import Session

from . import crud
from .config import STALE_AFTER_SECONDS, TREND_WINDOW
from .database import Base, engine, get_db
from .models import RejectedReading, utcnow
from .schemas import (
    DashboardOut,
    DeviceStatusOut,
    ReadingIn,
    ReadingOut,
    TrendOut,
)
from .trend import classify_trend


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="IoT Reliability & Intelligent Monitoring API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "server_time": utcnow()}


# --------------------------------------------------------------------------
# Challenge 2 + 3: terima data, validasi, deduplikasi
# --------------------------------------------------------------------------
@app.post("/api/readings", status_code=201)
def post_reading(payload: dict = Body(...), db: Session = Depends(get_db)):
    # Validasi dilakukan di layer API (bukan di perangkat) supaya aturan
    # tetap berlaku walau firmware dimodifikasi.
    try:
        data = ReadingIn.model_validate(payload)
    except ValidationError as exc:
        errors = [
            {
                "field": ".".join(str(p) for p in err["loc"]),
                "message": err["msg"],
            }
            for err in exc.errors()
        ]
        reason = "; ".join(f"{e['field']}: {e['message']}" for e in errors)
        db.add(
            RejectedReading(
                device_id=str(payload.get("device_id"))[:64] if payload.get("device_id") else None,
                payload=json.dumps(payload, default=str),
                reason=reason,
                received_at=utcnow(),
            )
        )
        db.commit()
        return JSONResponse(
            status_code=422,
            content={
                "status": "rejected",
                "message": "Payload tidak valid, data tidak disimpan.",
                "errors": errors,
            },
        )

    reading, duplicate = crud.create_reading(db, data)
    body = ReadingOut.model_validate(reading).model_dump(mode="json")
    body.update(
        {
            "status": "duplicate" if duplicate else "created",
            "duplicate": duplicate,
            "message": (
                "reading_id sudah ada, record lama dikembalikan (tidak digandakan)."
                if duplicate
                else "Data valid tersimpan."
            ),
        }
    )
    return JSONResponse(status_code=200 if duplicate else 201, content=body)


@app.get("/api/readings", response_model=list[ReadingOut])
def list_readings(
    device_id: str = Query(...),
    limit: int = Query(50, ge=1, le=500),
    db: Session = Depends(get_db),
):
    rows = crud.recent_readings(db, device_id, limit)
    return [ReadingOut.model_validate(r) for r in rows]


@app.get("/api/rejected")
def list_rejected(limit: int = Query(20, ge=1, le=200), db: Session = Depends(get_db)):
    rows = (
        db.query(RejectedReading)
        .order_by(RejectedReading.id.desc())
        .limit(limit)
        .all()
    )
    return [
        {
            "id": r.id,
            "device_id": r.device_id,
            "payload": json.loads(r.payload),
            "reason": r.reason,
            "received_at": r.received_at,
        }
        for r in rows
    ]


# --------------------------------------------------------------------------
# Challenge 1: status online/offline berbasis waktu data terakhir
# --------------------------------------------------------------------------
def build_status(db: Session, device_id: str) -> DeviceStatusOut:
    last = crud.latest_reading(db, device_id)
    if last is None:
        return DeviceStatusOut(
            device_id=device_id,
            status="offline",
            stale_after_seconds=STALE_AFTER_SECONDS,
            age_seconds=None,
            last_seen=None,
            last_reading=None,
        )

    age = (datetime.now(timezone.utc) - crud.as_utc(last.received_at)).total_seconds()
    return DeviceStatusOut(
        device_id=device_id,
        status="online" if age <= STALE_AFTER_SECONDS else "offline",
        stale_after_seconds=STALE_AFTER_SECONDS,
        age_seconds=round(age, 1),
        last_seen=crud.as_utc(last.received_at),
        last_reading=ReadingOut.model_validate(last),
    )


@app.get("/api/devices/{device_id}/status", response_model=DeviceStatusOut)
def device_status(device_id: str, db: Session = Depends(get_db)):
    return build_status(db, device_id)


# --------------------------------------------------------------------------
# Challenge 4: tren suhu dari N pembacaan terakhir
# --------------------------------------------------------------------------
def build_trend(db: Session, device_id: str, window: int) -> TrendOut:
    rows = crud.recent_readings(db, device_id, window)
    result = classify_trend([r.temperature for r in rows], window=window)
    return TrendOut(device_id=device_id, **result)


@app.get("/api/devices/{device_id}/trend", response_model=TrendOut)
def device_trend(
    device_id: str,
    window: int = Query(TREND_WINDOW, ge=2, le=50),
    db: Session = Depends(get_db),
):
    return build_trend(db, device_id, window)


@app.get("/api/devices/{device_id}/dashboard", response_model=DashboardOut)
def dashboard(
    device_id: str,
    window: int = Query(TREND_WINDOW, ge=2, le=50),
    db: Session = Depends(get_db),
):
    """Satu request untuk Flutter: status + data terakhir + tren."""
    return DashboardOut(
        status=build_status(db, device_id),
        trend=build_trend(db, device_id, window),
    )
