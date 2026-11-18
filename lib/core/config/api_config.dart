import 'package:flutter/foundation.dart' show kReleaseMode, debugPrint;

/// Centralized API configuration for connecting the Flutter mobile app to the Node.js backend.
///
/// Supports:
/// - Primary production Vercel cloud backend: https://driving-school-app-backend.vercel.app
/// - Environment override via `--dart-define=BACKEND_URL=...`
/// - Physical Android phone via USB `adb reverse tcp:5000 tcp:5000` (`http://127.0.0.1:5000`)
/// - Physical Android phone via Wi-Fi LAN (`http://10.10.26.95:5000`)
/// - Android emulator host alias (`http://10.0.2.2:5000`)
/// - Automatic candidate failover in development and production
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
    return [
      liveBackendUrl,                    // 1. Live Vercel cloud backend (Primary)
      'http://127.0.0.1:$defaultPort',   // 2. Local USB with adb reverse
      'http://10.10.26.95:$defaultPort',  // 3. Local Wi-Fi LAN
      'http://10.0.2.2:$defaultPort',     // 4. Android Studio Emulator loopback
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
