import '../domain/user.dart';

/// Abstract contract for authentication and user session management.
/// Production implementation will connect to the verified backend API.
abstract class AuthRepository {
  /// Retrieves the currently authenticated user session, or null if not logged in.
  Future<User?> getCurrentUser();

  /// Updates the preferred language for the current session.
  Future<void> updateLanguage(String languageCode);

  /// Terminates the current session according to the backend session-revocation policy.
  Future<void> logout();
}
