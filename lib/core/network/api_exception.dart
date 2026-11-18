/// Custom exception thrown when API communication or responses fail.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errorType,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? errorType;
  final dynamic details;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isUnprocessable => statusCode == 422;
  bool get isNetworkError => statusCode == null;

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: [$statusCode $errorType] $message';
    }
    return 'ApiException: $message';
  }
}
