import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, debugPrint;

/// Centralized API configuration for connecting the Flutter mobile app to the Node.js backend.
///
/// Supports:
/// - Environment override via `--dart-define=BACKEND_URL=...` (for physical devices or staging/production)
/// - Physical Android phone via USB `adb reverse tcp:5000 tcp:5000` (`http://127.0.0.1:5000`)
/// - Physical Android phone via Wi-Fi LAN (`http://10.10.26.95:5000`)
/// - Android emulator host alias (`http://10.0.2.2:5000`)
/// - iOS simulator / desktop localhost (`http://127.0.0.1:5000`)
/// - Automatic candidate failover in development
class ApiConfig {
  ApiConfig._();

  /// Default port for the local Node.js backend
  static const int defaultPort = 5000;

  /// Default production Vercel cloud backend endpoint
  static const String liveBackendUrl =
      'https://driving-school-app-backend.vercel.app';

  /// Compile-time environment override
  static const String _envBackendUrl = String.fromEnvironment('BACKEND_URL');

  static String? _customBaseUrl;
  static String? _resolvedWorkingBaseUrl;

  /// Optional runtime override (useful in integration/widget tests)
  static void setBaseUrl(String? url) {
    if (url != null) {
      _customBaseUrl = url.replaceAll(RegExp(r'/+$'), '');
      _resolvedWorkingBaseUrl = _customBaseUrl;
    } else {
      _customBaseUrl = null;
      _resolvedWorkingBaseUrl = null;
    }
  }

  /// Remembers the active, verified host when auto-failover succeeds
  static void markHostWorking(String workingBaseUrl) {
    _resolvedWorkingBaseUrl = workingBaseUrl.replaceAll(RegExp(r'/+$'), '');
    debugPrint('[ApiConfig] Active backend host set to: $_resolvedWorkingBaseUrl');
  }

  /// List of candidate base URLs to attempt in development and production
  static List<String> get candidateUrls {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return [_customBaseUrl!];
    }
    if (_envBackendUrl.isNotEmpty) {
      return [_envBackendUrl.replaceAll(RegExp(r'/+$'), '')];
    }
    if (kIsWeb) {
      return [
        liveBackendUrl,
        'http://127.0.0.1:$defaultPort',
      ];
    }
    try {
      if (Platform.isAndroid) {
        return [
          'http://127.0.0.1:$defaultPort',   // 1. USB with adb reverse (fastest for local dev)
          liveBackendUrl,                    // 2. Live Vercel cloud backend (automatic cloud fallback)
          'http://10.10.26.95:$defaultPort',  // 3. Local Wi-Fi LAN
          'http://10.0.2.2:$defaultPort',     // 4. Android Studio Emulator loopback
        ];
      }
    } catch (_) {}
    return [
      'http://127.0.0.1:$defaultPort',
      liveBackendUrl,
    ];
  }

  /// The active base URL for backend API requests
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (_envBackendUrl.isNotEmpty) {
      final sanitized = _envBackendUrl.replaceAll(RegExp(r'/+$'), '');
      if (kReleaseMode && sanitized.startsWith('http://')) {
        debugPrint(
          '[ApiConfig SECURITY WARNING] Production release builds require an encrypted HTTPS endpoint. Active URL: $sanitized',
        );
      }
      return sanitized;
    }
    if (_resolvedWorkingBaseUrl != null) {
      return _resolvedWorkingBaseUrl!;
    }
    return candidateUrls.first;
  }

  // Endpoints
  static String get healthUrl => '$baseUrl/api/health';
  static String get authMeUrl => '$baseUrl/api/auth/me';
  static String get questionsUrl => '$baseUrl/api/questions';
  static String questionByIdUrl(String id) => '$baseUrl/api/questions/$id';
  static String questionCheckUrl(String id) =>
      '$baseUrl/api/questions/$id/check';
  static String get examSubmitUrl => '$baseUrl/api/exams/submit';
  static String get examResultsUrl => '$baseUrl/api/exams/results';
  static String examResultByIdUrl(String attemptId) =>
      '$baseUrl/api/exams/results/$attemptId';
}
