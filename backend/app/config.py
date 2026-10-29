"""Konfigurasi terpusat untuk backend monitoring IoT.

Semua ambang batas pengujian diletakkan di satu tempat agar mudah diubah
dan mudah dijelaskan saat engineering defense.
"""
import os

# --- Database -------------------------------------------------------------
# Default SQLite agar project bisa langsung dijalankan tanpa server MySQL.
# Untuk MySQL cukup set DATABASE_URL, contoh:
#   mysql+pymysql://user:pass@localhost:3306/iot_monitor
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./iot_monitor.db")

# --- Challenge 1: Offline detection ---------------------------------------
# Data dianggap stale/offline bila tidak ada data baru selama 60 detik.
STALE_AFTER_SECONDS = int(os.getenv("STALE_AFTER_SECONDS", "60"))

# --- Challenge 2: Validasi sensor -----------------------------------------
TEMP_MIN = float(os.getenv("TEMP_MIN", "20"))
TEMP_MAX = float(os.getenv("TEMP_MAX", "30"))
HUMIDITY_MIN = float(os.getenv("HUMIDITY_MIN", "0"))
HUMIDITY_MAX = float(os.getenv("HUMIDITY_MAX", "100"))

# --- Challenge 3: Retry & deduplikasi -------------------------------------
# Batas percobaan kirim di sisi perangkat (dipakai juga oleh simulator).
MAX_SEND_ATTEMPTS = int(os.getenv("MAX_SEND_ATTEMPTS", "3"))
RETRY_BASE_DELAY_SECONDS = float(os.getenv("RETRY_BASE_DELAY_SECONDS", "1"))

# --- Challenge 4: Analisis tren -------------------------------------------
TREND_WINDOW = int(os.getenv("TREND_WINDOW", "5"))
# Kemiringan (slope) minimal dalam °C per pembacaan agar dianggap naik/turun.
TREND_SLOPE_THRESHOLD = float(os.getenv("TREND_SLOPE_THRESHOLD", "0.1"))
