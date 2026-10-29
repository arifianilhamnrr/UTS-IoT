# UTS Komputasi Mobile & IoT — IoT Reliability & Intelligent Monitoring

Project baru (dibangun dari nol) yang mengimplementasikan empat tantangan UTS:
deteksi offline, validasi data sensor, retry + deduplikasi, dan analisis tren suhu.

| Bagian | Teknologi | Lokasi |
| --- | --- | --- |
| Backend API | FastAPI + SQLAlchemy (SQLite default, siap MySQL) | `backend/` |
| Perangkat | ESP32 + DHT22 (Wokwi) | `firmware/uts_iot/` |
| Aplikasi | Flutter (Material 3) | `mobile/` |
| Laporan | Markdown + bukti log | `report/` |

## 1. Menjalankan backend

```bash
cd backend
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Dokumentasi interaktif: <http://127.0.0.1:8000/docs>
- Jika port 8000 sudah dipakai, jalankan `--port 8100` dan sesuaikan
  `API_BASE_URL` di Flutter/Wokwi.
- Database default: `backend/iot_monitor.db` (SQLite).
- Untuk MySQL: `export DATABASE_URL="mysql+pymysql://user:pass@localhost:3306/iot_monitor"`
  lalu install `pymysql`. Unique constraint `reading_id` tetap sama.

### Endpoint

| Method | Path | Fungsi |
| --- | --- | --- |
| POST | `/api/readings` | Kirim data; 201 dibuat, 200 duplikat, 422 tidak valid |
| GET | `/api/readings?device_id=...` | Histori data valid |
| GET | `/api/rejected` | Log payload yang ditolak |
| GET | `/api/devices/{id}/status` | Status online/offline (stale 60 s) |
| GET | `/api/devices/{id}/trend?window=5` | Tren suhu |
| GET | `/api/devices/{id}/dashboard` | Gabungan status + tren untuk Flutter |

### Simulator pengujian

```bash
cd backend
.venv/bin/python scripts/simulate.py               # semua skenario
.venv/bin/python scripts/simulate.py --wait-offline # + bukti offline & recovery (65 s)
```

### Unit/integration test

```bash
cd backend
.venv/bin/python -m pytest
```

## 2. Menjalankan Wokwi

1. Buka <https://wokwi.com> → New Project → ESP32.
2. Salin `firmware/uts_iot/uts_iot.ino`, `diagram.json`, dan `libraries.txt`.
3. Jalankan backend di `0.0.0.0:8000` (Wokwi mengakses host lewat
   `host.wokwi.internal`).
4. Start simulation. Serial monitor akan menampilkan log POST/retry.

Untuk Wokwi CLI lokal:

```bash
cd firmware
~/.platformio/penv/bin/pio run   # hasil: .pio/build/esp32doit-devkit-v1/
```

`firmware/uts_iot/wokwi.toml` menunjuk ke `firmware/.pio/build/...`
sehingga simulasi Wokwi memakai firmware hasil build PlatformIO.

### Kredensial Blynk

Kredensial Blynk memakai project praktikum sebelumnya
(`arduino/include/secrets.h`) dan disalin ke
`firmware/uts_iot/secrets.h`:

- `BLYNK_TEMPLATE_ID`, `BLYNK_TEMPLATE_NAME`, `BLYNK_AUTH_TOKEN`
- Data dikirim ke virtual pin `V0` (suhu), `V1` (kelembapan),
  `V2` (status koneksi).
- `secrets.h` sudah masuk `.gitignore`; untuk repo baru salin
  `secrets.example.h` lalu isi nilainya.

## 3. Menjalankan Flutter

```bash
cd mobile
flutter pub get

# iOS Simulator
open -a Simulator
flutter run -d "iPhone 17 Pro Max" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Android emulator / perangkat
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

- Perangkat fisik: gunakan IP LAN laptop, mis. `http://192.168.1.10:8000`.
- `DEVICE_ID` dapat diubah: `--dart-define=DEVICE_ID=wokwi-esp32-01`.
- Tampilan memakai gaya **neobrutalism**; token ada di
  `mobile/lib/theme/brutal.dart` dan `design-system/iot-monitor/MASTER.md`.

## 4. Aturan yang diterapkan

| Fitur | Aturan |
| --- | --- |
| Offline detection | Data dianggap offline bila `now - received_at > 60 s`; status dihitung dari waktu data, bukan status buka aplikasi |
| Validasi | Suhu 20–30 °C, kelembapan 0–100 %; divalidasi di layer API; payload ditolak dicatat di `rejected_readings` |
| Retry & dedupe | Maks. 3 percobaan, backoff 1 s/2 s; `reading_id` unik dan dipakai ulang; HTTP 4xx (kecuali 429) tidak di-retry |
| Tren | 5 data valid terakhir; slope least squares; > +0.1 °C/pembacaan = naik, < −0.1 = turun, selain itu stabil |

## 5. Struktur

```
backend/
  app/            config, database, models, schemas, crud, trend, main
  scripts/        simulate.py (bukti uji end-to-end)
  tests/          pytest (12 test)
firmware/uts_iot/ uts_iot.ino, diagram.json, wokwi.toml, libraries.txt,
                  secrets.example.h (secrets.h bersifat lokal)
mobile/lib/       main.dart, api.dart, models.dart, theme/, widgets/
design-system/    MASTER.md (token neobrutalism)
report/           LAPORAN_UTS.md + evidence/
```

## 6. Bukti pengujian

- `report/evidence/simulation.log` — valid, invalid, retry, dedupe, tren.
- `report/evidence/offline_recovery.log` — transisi online → offline → online.
- `report/evidence/pytest.log` — hasil 12 test.
