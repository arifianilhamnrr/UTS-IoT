import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iot_monitor/models.dart';
import 'package:iot_monitor/theme/brutal.dart';
import 'package:iot_monitor/widgets/status_card.dart';
import 'package:iot_monitor/widgets/trend_card.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('status card menampilkan ONLINE saat data masih segar',
      (tester) async {
    final status = DeviceStatus(
      status: 'online',
      staleAfterSeconds: 60,
      ageSeconds: 3,
      lastSeen: DateTime.now().subtract(const Duration(seconds: 3)),
      lastReading: null,
    );

    await tester.pumpWidget(wrap(StatusCard(status: status)));

    expect(find.text('ONLINE / UPDATED'), findsOneWidget);
    expect(find.textContaining('BATAS STALE 60 DETIK'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('status card menampilkan OFFLINE saat data basi', (tester) async {
    final status = DeviceStatus(
      status: 'offline',
      staleAfterSeconds: 60,
      ageSeconds: 120,
      lastSeen: DateTime.now().subtract(const Duration(seconds: 120)),
      lastReading: null,
    );

    await tester.pumpWidget(wrap(StatusCard(status: status)));

    expect(find.text('OFFLINE / STALE'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('trend card menampilkan NAIK untuk lima data menanjak',
      (tester) async {
    const Trend trend = Trend(
      trend: 'naik',
      window: 5,
      slope: 0.69,
      delta: 2.8,
      temperatures: [24.0, 24.6, 25.2, 25.9, 26.8],
      explanation: 'Slope +0.690 °C/pembacaan (ambang ±0.1).',
    );

    await tester.pumpWidget(wrap(const TrendCard(trend: trend)));

    expect(find.text('NAIK'), findsOneWidget);
    expect(find.textContaining('SLOPE +0.69'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('token warna neobrutalism tetap konsisten', () {
    expect(Brutal.ink, const Color(0xFF111111));
    expect(Brutal.border, 3);
  });
}
