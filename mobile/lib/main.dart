import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'models.dart';
import 'theme/brutal.dart';
import 'widgets/reading_card.dart';
import 'widgets/status_card.dart';
import 'widgets/trend_card.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);
const String kDeviceId = String.fromEnvironment(
  'DEVICE_ID',
  defaultValue: 'wokwi-esp32-01',
);

void main() => runApp(const IotMonitorApp());

class IotMonitorApp extends StatelessWidget {
  const IotMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Brutal.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Brutal.yellow,
          primary: Brutal.ink,
          surface: Brutal.bg,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Brutal.ink),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiClient _api = ApiClient(baseUrl: kApiBaseUrl);
  Dashboard? _data;
  String? _error;
  bool _loading = true;
  DateTime? _lastFetch;
  Timer? _pollTimer;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetch() async {
    try {
      final data = await _api.fetchDashboard(kDeviceId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
        _lastFetch = DateTime.now();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: DotGridPainter()),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: Brutal.ink,
              backgroundColor: Brutal.yellow,
              onRefresh: _fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                children: [
                  _Header(deviceId: kDeviceId, online: data?.status.isOnline),
                  const SizedBox(height: 22),
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!, onRetry: _fetch),
                    const SizedBox(height: 18),
                  ],
                  if (data == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 90),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Brutal.ink,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  else ...[
                    StatusCard(status: data.status),
                    const SizedBox(height: 18),
                    ReadingCard(reading: data.status.lastReading),
                    const SizedBox(height: 18),
                    TrendCard(trend: data.trend),
                    const SizedBox(height: 20),
                    _Footer(
                      lastFetch: _lastFetch,
                      loading: _loading,
                      onRefresh: _fetch,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String deviceId;
  final bool? online;

  const _Header({required this.deviceId, required this.online});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BrutalCard(
              color: Brutal.yellow,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shadowOffset: 4,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 16, color: Brutal.ink),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: BrutalCard(
                  color: Brutal.paper,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shadowOffset: 4,
                  child: Text(
                    deviceId,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'IOT\nMONITOR',
          style: TextStyle(
            fontSize: 46,
            height: 0.92,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'SUHU & KELEMBAPAN · REAL-TIME',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return BrutalCard(
      color: Brutal.red,
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Brutal.ink, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Brutal.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          BrutalPressable(
            onTap: onRetry,
            semanticLabel: 'Coba lagi memuat data',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Brutal.ink,
                border: Border.all(color: Brutal.ink, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'COBA',
                style: TextStyle(
                  color: Brutal.paper,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final DateTime? lastFetch;
  final bool loading;
  final VoidCallback onRefresh;

  const _Footer({
    required this.lastFetch,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final text = lastFetch == null
        ? 'BELUM ADA DATA'
        : 'UPDATE ${lastFetch!.hour.toString().padLeft(2, '0')}:'
            '${lastFetch!.minute.toString().padLeft(2, '0')}:'
            '${lastFetch!.second.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        BrutalPressable(
          onTap: loading ? null : onRefresh,
          semanticLabel: 'Muat ulang data dashboard',
          child: BrutalCard(
            color: loading ? const Color(0xFFE5E5E5) : Brutal.yellow,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shadowOffset: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  loading ? Icons.hourglass_top : Icons.refresh,
                  size: 16,
                  color: Brutal.ink,
                ),
                const SizedBox(width: 6),
                const Text(
                  'MUAT ULANG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
