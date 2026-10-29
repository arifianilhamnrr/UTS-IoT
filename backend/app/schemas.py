"""Skema Pydantic + aturan validasi sensor (Challenge 2)."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from .config import HUMIDITY_MAX, HUMIDITY_MIN, TEMP_MAX, TEMP_MIN


class ReadingIn(BaseModel):
    """Payload yang dikirim ESP32 / simulator."""

    # reading_id wajib dan stabil: dipakai untuk deduplikasi saat retry.
    reading_id: str = Field(min_length=8, max_length=64)
    device_id: str = Field(min_length=1, max_length=64)
    temperature: float
    humidity: float
    # Waktu pembacaan di sisi perangkat (opsional; server memakai received_at
    # untuk menghitung staleness agar tidak bisa dimanipulasi perangkat).
    recorded_at: Optional[datetime] = None

    @field_validator("temperature")
    @classmethod
    def check_temperature(cls, value: float) -> float:
        if not (TEMP_MIN <= value <= TEMP_MAX):
            raise ValueError(
                f"Suhu {value} °C di luar rentang wajar {TEMP_MIN:g}-{TEMP_MAX:g} °C"
            )
        return value

    @field_validator("humidity")
    @classmethod
    def check_humidity(cls, value: float) -> float:
        if not (HUMIDITY_MIN <= value <= HUMIDITY_MAX):
            raise ValueError(
                f"Kelembapan {value}% di luar rentang {HUMIDITY_MIN:g}-{HUMIDITY_MAX:g}%"
            )
        return value


class ReadingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    reading_id: str
    device_id: str
    temperature: float
    humidity: float
    recorded_at: datetime
    received_at: datetime


class DeviceStatusOut(BaseModel):
    device_id: str
    status: str  # "online" | "offline"
    stale_after_seconds: int
    age_seconds: Optional[float]
    last_seen: Optional[datetime]
    last_reading: Optional[ReadingOut]


class TrendOut(BaseModel):
    device_id: str
    trend: str  # "naik" | "turun" | "stabil" | "insufficient_data"
    window: int
    slope_per_reading: Optional[float]
    delta: Optional[float]
    temperatures: list[float]
    explanation: str


class DashboardOut(BaseModel):
    status: DeviceStatusOut
    trend: TrendOut
