#!/usr/bin/env python3
"""Simulator uji untuk empat tantangan UTS.

Menjalankan skenario end-to-end ke backend FastAPI dan mencetak log yang
bisa langsung dipakai sebagai bukti pengujian di laporan.

Contoh:
    python scripts/simulate.py
    python scripts/simulate.py --wait-offline   # ikut menunggu 65 detik
"""
from __future__ import annotations

import argparse
import time
import uuid
from datetime import datetime, timezone

import httpx

DEFAULT_BASE = "http://127.0.0.1:8000"


def log(tag: str, message: str) -> None:
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {tag:<10} {message}")


def post(client: httpx.Client, payload: dict) -> httpx.Response:
    return client.post("/api/readings", json=payload)


def base_payload(device: str, reading_id: str, temp: float, hum: float) -> dict:
    return {
        "reading_id": reading_id,
        "device_id": device,
        "temperature": temp,
        "humidity": hum,
        "recorded_at": datetime.now(timezone.utc).isoformat(),
    }


def send_with_retry(client, payload, max_attempts=3, fail_first=0):
    """Retry terbatas dengan reading_id yang sama (Challenge 3).

    fail_first mensimulasikan kegagalan jaringan sementara sebelum berhasil.
    """
    for attempt in range(1, max_attempts + 1):
        try:
            if attempt <= fail_first:
                raise httpx.ConnectError("simulasi jaringan putus")
            res = post(client, payload)
            if res.status_code in (200, 201):
                log("RETRY", f"percobaan {attempt} sukses -> HTTP {res.status_code} "
                             f"(duplicate={res.json().get('duplicate')})")
                return res
            if 400 <= res.status_code < 500 and res.status_code != 429:
                log("RETRY", f"HTTP {res.status_code} permanen, retry dihentikan")
                return res
            log("RETRY", f"percobaan {attempt} gagal HTTP {res.status_code}")
        except httpx.HTTPError as exc:
            log("RETRY", f"percobaan {attempt} gagal: {type(exc).__name__}")
        if attempt < max_attempts:
            delay = 2 ** (attempt - 1)
            log("RETRY", f"tunggu {delay}s lalu kirim ulang reading_id yang sama")
            time.sleep(delay)
    log("RETRY", "batas percobaan habis, data tidak terkirim")
    return None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default=DEFAULT_BASE)
    parser.add_argument("--device", default="wokwi-esp32-01")
    parser.add_argument("--wait-offline", action="store_true")
    args = parser.parse_args()

    run = uuid.uuid4().hex[:6]
    with httpx.Client(base_url=args.base_url, timeout=10) as client:
        log("HEALTH", str(client.get("/health").json()))

        # ---------------- Challenge 2: valid vs invalid ----------------
        log("VALID", "kirim payload valid (26.4 C, 61%)")
        rid = f"{args.device}-{run}-valid"
        res = post(client, base_payload(args.device, rid, 26.4, 61.0))
        log("VALID", f"HTTP {res.status_code} -> {res.json()['status']}")

        log("INVALID", "kirim suhu 35 C (di luar 20-30)")
        res = post(client, base_payload(args.device, f"{args.device}-{run}-bad-temp", 35.0, 61.0))
        log("INVALID", f"HTTP {res.status_code} -> {res.json()}")

        log("INVALID", "kirim kelembapan 120% (di luar 0-100)")
        res = post(client, base_payload(args.device, f"{args.device}-{run}-bad-hum", 26.0, 120.0))
        log("INVALID", f"HTTP {res.status_code} -> {res.json()}")

        # ---------------- Challenge 3: retry + dedupe ----------------
        log("RETRY", "simulasi 2x gagal jaringan lalu berhasil, reading_id tetap")
        rid_retry = f"{args.device}-{run}-retry"
        send_with_retry(client, base_payload(args.device, rid_retry, 27.1, 58.0), fail_first=2)

        log("DEDUPE", "kirim ulang payload yang sama (reading_id identik)")
        res = post(client, base_payload(args.device, rid_retry, 27.1, 58.0))
        log("DEDUPE", f"HTTP {res.status_code} duplicate={res.json()['duplicate']}")

        rows = client.get("/api/readings", params={"device_id": args.device, "limit": 100}).json()
        same = [r for r in rows if r["reading_id"] == rid_retry]
        log("DEDUPE", f"jumlah record dengan reading_id tsb = {len(same)} (harus 1)")

        # ---------------- Challenge 4: tren naik & turun ----------------
        log("TREND", "seed 5 data naik: 24.0 24.6 25.2 25.9 26.8")
        for i, t in enumerate([24.0, 24.6, 25.2, 25.9, 26.8]):
            post(client, base_payload(args.device, f"{args.device}-{run}-up-{i}", t, 60.0))
        log("TREND", f"-> {client.get(f'/api/devices/{args.device}/trend').json()}")

        log("TREND", "seed 5 data turun: 28.5 27.9 27.0 26.2 25.4")
        for i, t in enumerate([28.5, 27.9, 27.0, 26.2, 25.4]):
            post(client, base_payload(args.device, f"{args.device}-{run}-down-{i}", t, 62.0))
        log("TREND", f"-> {client.get(f'/api/devices/{args.device}/trend').json()}")

        # ---------------- Challenge 1: status online/offline ----------------
        status = client.get(f"/api/devices/{args.device}/status").json()
        log("STATUS", f"sekarang: {status['status']} (umur data {status['age_seconds']}s)")

        if args.wait_offline:
            log("STATUS", "menunggu 65 detik tanpa data baru ...")
            time.sleep(65)
            status = client.get(f"/api/devices/{args.device}/status").json()
            log("STATUS", f"setelah 65s: {status['status']} (umur data {status['age_seconds']}s)")
            log("STATUS", "kirim data baru untuk recovery ...")
            post(client, base_payload(args.device, f"{args.device}-{run}-recover", 26.0, 60.0))
            status = client.get(f"/api/devices/{args.device}/status").json()
            log("STATUS", f"setelah recovery: {status['status']} (umur data {status['age_seconds']}s)")


if __name__ == "__main__":
    main()
