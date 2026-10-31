/// Constants and query construction strategy for Cloud Firestore question queries.
///
/// Ensures consistent filtering according to Austrian theory catalogue conventions.
class FirestoreQueryStrategy {
  FirestoreQueryStrategy._();

  /// Primary public questions collection containing question text and options.
  static const String questionsCollection = 'questions';

  /// Legal and regulatory sources collection.
  static const String questionSourcesCollection = 'question_sources';

  /// Default jurisdiction code for Austria.
  static const String defaultCountryCode = 'AT';

  /// Initial catalog language code.
  static const String defaultLanguageCode = 'en';

  /// Resolves the Firestore `moduleCode` filter value for a driving license class.
  ///
  /// Maps app class "GW" -> "GW" and "B" -> "B".
  static String resolveModuleCodeForClass(String drivingClassId) {
    final clean = drivingClassId.trim().toUpperCase();
    if (clean == 'GW' || clean == 'GENERAL') {
      return 'GW';
    }
    if (clean == 'B') {
      return 'B';
    }
    return clean;
  }

  /// Builds standard Firestore filter parameters for catalogue queries.
  static Map<String, dynamic> buildQuestionsFilter({
    required String drivingClassId,
    String languageCode = defaultLanguageCode,
    bool activeOnly = true,
    String countryCode = defaultCountryCode,
  }) {
    return {
      'moduleCode': resolveModuleCodeForClass(drivingClassId),
      'languageCode': languageCode,
      if (activeOnly) 'isActive': true,
      'countryCode': countryCode,
    };
  }
}
