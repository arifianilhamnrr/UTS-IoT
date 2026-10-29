"""Model database.

readings          : hanya berisi data yang lolos validasi.
rejected_readings : log payload yang ditolak, dipakai sebagai bukti uji
                    Challenge 2 tanpa mengotori histori data valid.
"""
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Float, Integer, String, Text

from .database import Base


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class Reading(Base):
    __tablename__ = "readings"

    id = Column(Integer, primary_key=True, index=True)
    # reading_id dibuat sekali oleh perangkat dan dipakai ulang saat retry.
    # UNIQUE constraint inilah yang mencegah duplikasi di level penyimpanan.
    reading_id = Column(String(64), nullable=False, unique=True, index=True)
    device_id = Column(String(64), nullable=False, index=True)
    temperature = Column(Float, nullable=False)
    humidity = Column(Float, nullable=False)
    recorded_at = Column(DateTime(timezone=True), nullable=False)
    received_at = Column(DateTime(timezone=True), nullable=False, index=True)


class RejectedReading(Base):
    __tablename__ = "rejected_readings"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(64), nullable=True, index=True)
    payload = Column(Text, nullable=False)
    reason = Column(Text, nullable=False)
    received_at = Column(DateTime(timezone=True), nullable=False, default=utcnow)
