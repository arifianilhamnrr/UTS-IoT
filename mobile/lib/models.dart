/// Model data yang dipakai dashboard.
class Reading {
  final String readingId;
  final double temperature;
  final double humidity;
  final DateTime receivedAt;

  const Reading({
    required this.readingId,
    required this.temperature,
    required this.humidity,
    required this.receivedAt,
  });

  factory Reading.fromJson(Map<String, dynamic> json) => Reading(
        readingId: json['reading_id'] as String,
        temperature: (json['temperature'] as num).toDouble(),
        humidity: (json['humidity'] as num).toDouble(),
        receivedAt: DateTime.parse(json['received_at'] as String).toLocal(),
      );
}

class DeviceStatus {
  final String status;
  final int staleAfterSeconds;
  final double? ageSeconds;
  final DateTime? lastSeen;
  final Reading? lastReading;

  const DeviceStatus({
    required this.status,
    required this.staleAfterSeconds,
    this.ageSeconds,
    this.lastSeen,
    this.lastReading,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) => DeviceStatus(
        status: json['status'] as String,
        staleAfterSeconds: json['stale_after_seconds'] as int,
        ageSeconds: (json['age_seconds'] as num?)?.toDouble(),
        lastSeen: json['last_seen'] == null
            ? null
            : DateTime.parse(json['last_seen'] as String).toLocal(),
        lastReading: json['last_reading'] == null
            ? null
            : Reading.fromJson(json['last_reading'] as Map<String, dynamic>),
      );

  /// Status dihitung ulang di klien memakai waktu data terakhir, bukan
  /// sekadar "aplikasi sedang terbuka". Server tetap menjadi sumber utama.
  bool get isOnline {
    if (lastSeen == null) return false;
    final age = DateTime.now().difference(lastSeen!).inSeconds;
    return age <= staleAfterSeconds;
  }

  int get currentAgeSeconds => lastSeen == null
      ? 0
      : DateTime.now().difference(lastSeen!).inSeconds;
}

class Trend {
  final String trend;
  final int window;
  final double? slope;
  final double? delta;
  final List<double> temperatures;
  final String explanation;

  const Trend({
    required this.trend,
    required this.window,
    this.slope,
    this.delta,
    required this.temperatures,
    required this.explanation,
  });

  factory Trend.fromJson(Map<String, dynamic> json) => Trend(
        trend: json['trend'] as String,
        window: json['window'] as int,
        slope: (json['slope_per_reading'] as num?)?.toDouble(),
        delta: (json['delta'] as num?)?.toDouble(),
        temperatures: (json['temperatures'] as List)
            .map((e) => (e as num).toDouble())
            .toList(),
        explanation: json['explanation'] as String,
      );
}

class Dashboard {
  final DeviceStatus status;
  final Trend trend;

  const Dashboard({required this.status, required this.trend});

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
        status: DeviceStatus.fromJson(json['status'] as Map<String, dynamic>),
        trend: Trend.fromJson(json['trend'] as Map<String, dynamic>),
      );
}
