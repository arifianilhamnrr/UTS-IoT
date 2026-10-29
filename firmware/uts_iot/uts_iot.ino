/*
 * UTS Komputasi Mobile & IoT
 * ESP32 + DHT22 -> FastAPI (Wokwi)
 *
 * Fitur:
 *  - Challenge 3: reading_id stabil + retry terbatas (3x, backoff 1s/2s)
 *  - Kegagalan permanen (HTTP 4xx selain 429) tidak di-retry
 *  - Payload divalidasi juga di backend (Challenge 2)
 *
 * Board  : ESP32 DevKit V1
 * Sensor : DHT22 pada GPIO 15
 */
#include "secrets.h"  // Blynk + WiFi + API (tidak di-commit)

#define BLYNK_PRINT Serial
#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include <BlynkSimpleEsp32.h>

// ----------------------------- Konfigurasi --------------------------------
// Kredensial Blynk diambil dari project praktikum sebelumnya
// (arduino/include/secrets.h) dan disalin ke secrets.h lokal.
const char *API_HOST = API_BASE_URL;
const char *DEVICE_ID = API_DEVICE_ID;

const uint32_t SEND_INTERVAL_MS = 5000;   // kirim tiap 5 detik
const uint8_t  MAX_ATTEMPTS = 3;          // retry terbatas
const uint16_t HTTP_TIMEOUT_MS = 5000;

// Virtual pin Blynk
#define VPIN_TEMP     V0
#define VPIN_HUMIDITY V1
#define VPIN_STATUS   V2

#define DHTPIN 15
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);
uint32_t lastSend = 0;
uint32_t readingCounter = 0;
bool lastBlynkState = false;

// ------------------------------- Helpers ----------------------------------
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  Serial.printf("[WIFI] Menghubungkan ke %s\n", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  uint8_t tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 40) {
    delay(250);
    Serial.print(".");
    tries++;
  }
  Serial.println();
  Serial.printf("[WIFI] status=%d ip=%s\n", WiFi.status(), WiFi.localIP().toString().c_str());
}

/*
 * reading_id dibuat SEKALI per pembacaan dan dipakai ulang di semua percobaan.
 * Inilah kunci deduplikasi di backend (UNIQUE reading_id).
 */
String makeReadingId() {
  readingCounter++;
  return String(DEVICE_ID) + "-" + String((uint32_t)(millis() / 1000)) + "-" + String(readingCounter);
}

bool isPermanentFailure(int code) {
  // 400/422 = payload tidak valid -> jangan diulang tanpa perubahan data.
  // 429 = terlalu banyak request -> masih boleh dicoba lagi.
  return code >= 400 && code < 500 && code != 429;
}

bool sendReading(float temp, float hum) {
  String readingId = makeReadingId();
  String url = String(API_HOST) + "/api/readings";

  for (uint8_t attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    if (WiFi.status() != WL_CONNECTED) connectWiFi();

    HTTPClient http;
    http.setTimeout(HTTP_TIMEOUT_MS);
    http.begin(url);
    http.addHeader("Content-Type", "application/json");

    StaticJsonDocument<256> doc;
    doc["reading_id"] = readingId;
    doc["device_id"] = DEVICE_ID;
    doc["temperature"] = temp;
    doc["humidity"] = hum;

    String body;
    serializeJson(doc, body);

    Serial.printf("[POST] attempt=%u id=%s body=%s\n", attempt, readingId.c_str(), body.c_str());
    int code = http.POST(body);
    String response = http.getString();
    http.end();

    if (code == 201 || code == 200) {
      Serial.printf("[OK] HTTP %d %s\n", code, response.c_str());
      return true;
    }

    Serial.printf("[FAIL] HTTP %d %s\n", code, response.c_str());
    if (isPermanentFailure(code)) {
      Serial.println("[STOP] Kegagalan permanen, retry dihentikan.");
      return false;
    }
    if (attempt < MAX_ATTEMPTS) {
      uint32_t backoff = 1000UL * (1 << (attempt - 1)); // 1s, 2s
      Serial.printf("[RETRY] tunggu %lu ms\n", (unsigned long)backoff);
      delay(backoff);
    }
  }
  Serial.println("[STOP] Batas percobaan habis.");
  return false;
}

// --------------------------------- Setup ----------------------------------
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n=== UTS IoT: ESP32 + DHT22 + Blynk ===");
  dht.begin();
  connectWiFi();

  // Blynk tidak memblokir pengiriman HTTP bila server Blynk lambat.
  Blynk.config(BLYNK_AUTH_TOKEN);
  if (Blynk.connect(3000)) {
    Serial.println("[BLYNK] Terhubung.");
    Blynk.virtualWrite(VPIN_STATUS, "online");
  } else {
    Serial.println("[BLYNK] Belum terhubung, akan dicoba lagi di loop().");
  }
}

void loop() {
  // Jaga koneksi Blynk tanpa menghentikan pembacaan sensor.
  if (WiFi.status() == WL_CONNECTED) {
    if (!Blynk.connected()) {
      Blynk.connect(2000);
    } else {
      Blynk.run();
    }
    if (Blynk.connected() != lastBlynkState) {
      lastBlynkState = Blynk.connected();
      Blynk.virtualWrite(VPIN_STATUS, lastBlynkState ? "online" : "offline");
      Serial.printf("[BLYNK] status=%s\n", lastBlynkState ? "online" : "offline");
    }
  }

  if (millis() - lastSend < SEND_INTERVAL_MS) {
    delay(50);
    return;
  }
  lastSend = millis();

  float temp = dht.readTemperature();
  float hum = dht.readHumidity();

  if (isnan(temp) || isnan(hum)) {
    Serial.println("[SENSOR] Gagal membaca DHT22, data tidak dikirim.");
    return;
  }

  Serial.printf("[SENSOR] suhu=%.1f C kelembapan=%.1f %%\n", temp, hum);

  // Kirim ke Blynk (monitoring cloud) dan ke backend FastAPI.
  if (Blynk.connected()) {
    Blynk.virtualWrite(VPIN_TEMP, temp);
    Blynk.virtualWrite(VPIN_HUMIDITY, hum);
  }
  sendReading(temp, hum);
}
