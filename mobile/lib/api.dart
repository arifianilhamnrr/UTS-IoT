import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  final String message;
  final bool retryable;

  const ApiException(this.message, {this.retryable = false});

  @override
  String toString() => message;
}

/// Klien API dengan retry terbatas (maks. 3 percobaan, backoff 1s/2s).
/// Retry hanya untuk gangguan sementara (jaringan / 5xx); error 4xx tidak
/// diulang karena bersifat permanen.
class ApiClient {
  final String baseUrl;
  final http.Client _client;
  static const int maxAttempts = 3;

  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Future<Dashboard> fetchDashboard(String deviceId) async {
    final uri = Uri.parse('$baseUrl/api/devices/$deviceId/dashboard');

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final res = await _client.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          return Dashboard.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>,
          );
        }
        if (res.statusCode >= 400 && res.statusCode < 500) {
          throw ApiException('Permintaan ditolak (HTTP ${res.statusCode}).');
        }
        throw ApiException(
          'Server bermasalah (HTTP ${res.statusCode}).',
          retryable: true,
        );
      } on ApiException catch (e) {
        if (!e.retryable || attempt == maxAttempts) rethrow;
      } on TimeoutException {
        if (attempt == maxAttempts) {
          throw const ApiException('Koneksi timeout. Periksa jaringan.');
        }
      } on SocketException {
        if (attempt == maxAttempts) {
          throw const ApiException('Tidak dapat terhubung ke server.');
        }
      } on http.ClientException {
        if (attempt == maxAttempts) {
          throw const ApiException('Koneksi ke server terputus.');
        }
      }

      await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
    }
    throw const ApiException('Gagal memuat data.');
  }

  void dispose() => _client.close();
}
