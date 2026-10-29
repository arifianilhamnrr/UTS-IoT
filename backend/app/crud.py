"""Operasi database: simpan data valid dengan deduplikasi (Challenge 3)."""
from datetime import datetime, timezone

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .models import Reading
from .schemas import ReadingIn


def as_utc(value: datetime) -> datetime:
    """SQLite mengembalikan datetime tanpa tzinfo; paksa dianggap UTC."""
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def create_reading(db: Session, data: ReadingIn) -> tuple[Reading, bool]:
    """Simpan satu pembacaan.

    Return (reading, is_duplicate). Jika reading_id sudah ada, record lama
    dikembalikan tanpa menambah baris baru. Unique index pada reading_id
    menjadi pengaman terakhir bila dua request identik datang bersamaan.
    """
    existing = db.query(Reading).filter(Reading.reading_id == data.reading_id).first()
    if existing is not None:
        return existing, True

    now = datetime.now(timezone.utc)
    reading = Reading(
        reading_id=data.reading_id,
        device_id=data.device_id,
        temperature=data.temperature,
        humidity=data.humidity,
        recorded_at=as_utc(data.recorded_at) if data.recorded_at else now,
        received_at=now,
    )
    db.add(reading)
    try:
        db.commit()
    except IntegrityError:
        # Race condition: request paralel dengan reading_id sama.
        db.rollback()
        existing = (
            db.query(Reading).filter(Reading.reading_id == data.reading_id).first()
        )
        if existing is None:
            raise
        return existing, True
    db.refresh(reading)
    return reading, False


def latest_reading(db: Session, device_id: str) -> Reading | None:
    return (
        db.query(Reading)
        .filter(Reading.device_id == device_id)
        .order_by(Reading.received_at.desc(), Reading.id.desc())
        .first()
    )


def recent_readings(db: Session, device_id: str, limit: int) -> list[Reading]:
    rows = (
        db.query(Reading)
        .filter(Reading.device_id == device_id)
        .order_by(Reading.received_at.desc(), Reading.id.desc())
        .limit(limit)
        .all()
    )
    return list(reversed(rows))  # urut kronologis untuk analisis tren
