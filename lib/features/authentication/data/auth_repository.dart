import '../domain/user.dart';

/// Abstract contract for authentication and user session management.
/// Supports both real Firebase authentication and offline mock development.
abstract class AuthRepository {
  /// Stream of authentication state changes. Emits null when unauthenticated.
  Stream<User?> authStateChanges();

  /// Retrieves the currently authenticated user session, or null if not logged in.
  Future<User?> getCurrentUser();

  /// Signs in using email and password.
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registers a new user account with email, password, and display name.
  Future<User> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  });

  /// Initiates Google Sign-In authentication flow.
  Future<User> signInWithGoogle();

  /// Sends a password reset email to the provided address.
  Future<void> sendPasswordResetEmail(String email);

  /// Updates the preferred language for the current session.
  Future<void> updateLanguage(String languageCode);

  /// Terminates the current session according to the backend session-revocation policy.
  Future<void> logout();
}
