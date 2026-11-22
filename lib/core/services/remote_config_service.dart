import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

/// Service responsible for fetching dynamic runtime configuration from Cloud Firestore.
///
/// Allows zero-downtime backend server URL migration (e.g. Vercel -> AWS / GCP)
/// directly from the Firebase Console without releasing an app update or submitting for review.
class RemoteConfigService {
  RemoteConfigService._();

  static const List<String> candidateCollections = ['app_config', 'api_config'];
  static const String documentId = 'backend';
  static const List<String> candidateFields = ['baseUrl', 'base_url', 'url'];

  /// Fetches the dynamic backend URL from Cloud Firestore.
  ///
  /// Safe for offline mode, slow networks, and unit test environments:
  /// - Exits immediately if Firebase is uninitialized.
  /// - Times out after 3 seconds so app launch is never delayed.
  /// - Checks both 'app_config' and 'api_config' collections.
  /// - Falls back smoothly to [ApiConfig.liveBackendUrl] if document is missing or on error.
  static Future<void> syncBackendUrl() async {
    try {
      if (Firebase.apps.isEmpty) {
        return;
      }

      for (final collection in candidateCollections) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection(collection)
              .doc(documentId)
              .get(const GetOptions(source: Source.serverAndCache))
              .timeout(const Duration(seconds: 3));

          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            for (final field in candidateFields) {
              final remoteUrl = data[field] as String?;
              if (remoteUrl != null && remoteUrl.trim().isNotEmpty) {
                final cleanUrl = remoteUrl.trim().replaceAll(RegExp(r'/+$'), '');
                ApiConfig.setBaseUrl(cleanUrl);
                debugPrint('[RemoteConfigService] Loaded dynamic backend URL from Firestore ($collection/$documentId.$field): $cleanUrl');
                return;
              }
            }
          }
        } catch (e) {
          debugPrint('[RemoteConfigService] Notice: Could not read from $collection ($e)');
        }
      }
      debugPrint('[RemoteConfigService] No remote baseUrl found. Using default: ${ApiConfig.liveBackendUrl}');
    } catch (e) {
      debugPrint('[RemoteConfigService] Notice: Could not sync remote config ($e). Using default: ${ApiConfig.liveBackendUrl}');
    }
  }
}
