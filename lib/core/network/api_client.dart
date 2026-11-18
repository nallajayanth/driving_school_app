import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

typedef TokenProvider = Future<String?> Function({bool forceRefresh});

/// Authenticated HTTP Client that connects to the Powerdrive Node.js backend.
/// Automatically attaches Firebase ID tokens to outgoing requests when authenticated.
/// Transparently handles ID token refresh, candidate host failover, and structured API exceptions.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenProvider? tokenProvider,
    this.timeout = const Duration(seconds: 15),
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider ?? _defaultTokenProvider;

  final http.Client _httpClient;
  final TokenProvider _tokenProvider;
  final Duration timeout;

  static Future<String?> _defaultTokenProvider({bool forceRefresh = false}) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken(forceRefresh);
      }
    } catch (e) {
      debugPrint('[ApiClient] Unable to obtain Firebase ID token: $e');
    }
    return null;
  }

  /// Sends a GET request to [url] with optional query parameters and headers.
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    return _executeWithFailover((activeUrl) async {
      final uri = _buildUri(activeUrl, queryParams);
      return _executeWithAuthRetry((token) async {
        final requestHeaders = _buildHeaders(headers, token);
        final response = await _httpClient
            .get(uri, headers: requestHeaders)
            .timeout(timeout);
        return _processResponse(response);
      });
    }, url);
  }

  /// Sends a POST request to [url] with json [body] and optional headers.
  Future<Map<String, dynamic>> post(
    String url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final encodedBody = body != null ? jsonEncode(body) : null;

    return _executeWithFailover((activeUrl) async {
      final uri = Uri.parse(activeUrl);
      return _executeWithAuthRetry((token) async {
        final requestHeaders = _buildHeaders(headers, token);
        final response = await _httpClient
            .post(uri, headers: requestHeaders, body: encodedBody)
            .timeout(timeout);
        return _processResponse(response);
      });
    }, url);
  }

  /// Verifies connectivity to the backend service.
  Future<bool> checkHealth() async {
    try {
      final data = await get(ApiConfig.healthUrl);
      return data['status'] == 'healthy' || data['success'] == true || data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Fetches the authenticated user's profile from the backend.
  Future<Map<String, dynamic>> getAuthMe() async {
    return await get(ApiConfig.authMeUrl);
  }

  /// Executes request with automatic host candidate failover if the default host is unreachable.
  Future<Map<String, dynamic>> _executeWithFailover(
    Future<Map<String, dynamic>> Function(String targetUrl) requestFn,
    String originalUrl,
  ) async {
    final candidates = ApiConfig.candidateUrls;

    if (candidates.length <= 1) {
      return await requestFn(originalUrl);
    }

    final currentBase = ApiConfig.baseUrl;

    try {
      final result = await requestFn(originalUrl);
      ApiConfig.markHostWorking(currentBase);
      return result;
    } on SocketException catch (_) {
      debugPrint('[ApiClient] SocketException connecting to $currentBase, testing candidate hosts...');
    } on TimeoutException catch (_) {
      debugPrint('[ApiClient] TimeoutException connecting to $currentBase, testing candidate hosts...');
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
      debugPrint('[ApiClient] Network error connecting to $currentBase, testing candidate hosts...');
    }

    // Attempt alternate candidates with quick 3s probe
    for (final candidate in candidates) {
      if (candidate == currentBase) continue;

      final switchedUrl = originalUrl.replaceFirst(currentBase, candidate);
      try {
        debugPrint('[ApiClient] Testing candidate backend: $candidate');
        final probeUri = Uri.parse('$candidate/api/health');
        final probe = await _httpClient.get(probeUri).timeout(const Duration(seconds: 3));
        if (probe.statusCode == 200) {
          ApiConfig.markHostWorking(candidate);
          debugPrint('[ApiClient] Failover succeeded. Connected to: $candidate');
          return await requestFn(switchedUrl);
        }
      } catch (e) {
        debugPrint('[ApiClient] Candidate $candidate failed: $e');
      }
    }

    throw ApiException(
      message: 'Could not connect to backend server at any candidate URL: ${candidates.join(', ')}.\n'
          'Please ensure the backend is running (`npm run dev`) and run `adb reverse tcp:5000 tcp:5000` for USB debugging.',
    );
  }

  /// Executes an HTTP action, retrying once with a refreshed token if an HTTP 401 is encountered.
  Future<Map<String, dynamic>> _executeWithAuthRetry(
    Future<Map<String, dynamic>> Function(String? token) action,
  ) async {
    String? token = await _tokenProvider(forceRefresh: false);

    try {
      return await action(token);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Attempt token refresh and retry request once
        debugPrint('[ApiClient] 401 received, attempting token refresh retry...');
        token = await _tokenProvider(forceRefresh: true);
        if (token != null) {
          try {
            return await action(token);
          } on ApiException {
            rethrow;
          }
        }
      }
      rethrow;
    } on SocketException catch (e) {
      throw ApiException(
        message: 'Could not connect to backend server at ${ApiConfig.baseUrl}. ($e)',
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'Request timed out waiting for backend server response.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(message: 'HTTP client error: ${e.message}');
    }
  }

  Uri _buildUri(String url, Map<String, String>? queryParams) {
    final baseUri = Uri.parse(url);
    if (queryParams == null || queryParams.isEmpty) {
      return baseUri;
    }

    final mergedParams = Map<String, dynamic>.from(baseUri.queryParameters)
      ..addAll(queryParams);

    return baseUri.replace(queryParameters: mergedParams);
  }

  Map<String, String> _buildHeaders(
    Map<String, String>? customHeaders,
    String? token,
  ) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    Map<String, dynamic> jsonBody;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        jsonBody = decoded;
      } else {
        jsonBody = {'data': decoded};
      }
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'raw': response.body};
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Server returned non-JSON response (${response.statusCode}): ${response.body}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    final errorMessage = jsonBody['message'] as String? ??
        jsonBody['error'] as String? ??
        'HTTP ${response.statusCode} error';
    final errorType = jsonBody['error'] as String?;

    throw ApiException(
      statusCode: response.statusCode,
      errorType: errorType,
      message: errorMessage,
      details: jsonBody,
    );
  }
}

/// Global provider for [ApiClient].
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
