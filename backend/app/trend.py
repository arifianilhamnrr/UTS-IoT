"""Perhitungan tren suhu (Challenge 4).

Aturan klasifikasi
------------------
1. Ambil N pembacaan valid terakhir (default 5) milik satu device, urut waktu.
2. Hitung slope regresi linear sederhana (least squares) suhu terhadap urutan
   pembacaan: slope = Σ((x-x̄)(y-ȳ)) / Σ((x-x̄)²), x = 0..N-1.
3. Klasifikasi:
   - slope >  +0.1 °C/pembacaan  -> "naik"
   - slope <  -0.1 °C/pembacaan  -> "turun"
   - selain itu                  -> "stabil"
   Threshold 0.1 dipakai agar noise kecil DHT22 (±0.5 °C) tidak langsung
   dianggap tren.
"""
from __future__ import annotations

from .config import TREND_SLOPE_THRESHOLD


def linear_slope(values: list[float]) -> float:
    n = len(values)
    if n < 2:
        return 0.0
    mean_x = (n - 1) / 2
    mean_y = sum(values) / n
    numerator = sum((i - mean_x) * (v - mean_y) for i, v in enumerate(values))
    denominator = sum((i - mean_x) ** 2 for i in range(n))
    if denominator == 0:
        return 0.0
    return numerator / denominator


def classify_trend(
    temperatures: list[float],
    window: int = 5,
    threshold: float = TREND_SLOPE_THRESHOLD,
) -> dict:
    temps = [float(t) for t in temperatures][-window:]
    if len(temps) < window:
        return {
            "trend": "insufficient_data",
            "window": window,
            "slope_per_reading": None,
            "delta": None,
            "temperatures": temps,
            "explanation": (
                f"Butuh minimal {window} pembacaan, baru tersedia {len(temps)}."
            ),
        }

    slope = linear_slope(temps)
    delta = temps[-1] - temps[0]
    if slope > threshold:
        trend = "naik"
    elif slope < -threshold:
        trend = "turun"
    else:
        trend = "stabil"

    return {
        "trend": trend,
        "window": window,
        "slope_per_reading": round(slope, 4),
        "delta": round(delta, 2),
        "temperatures": [round(t, 2) for t in temps],
        "explanation": (
            f"Slope {slope:+.3f} °C/pembacaan (ambang ±{threshold:g}), "
            f"selisih awal-akhir {delta:+.2f} °C."
        ),
    }
