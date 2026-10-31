/// Sealed hierarchy of domain failure types for authentication.
sealed class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when email or password is wrong or user does not exist.
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([
    super.message = 'Invalid email or password. Please check your credentials.',
  ]);
}

/// Thrown when attempting to register with an email that is already registered.
class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([
    super.message = 'An account already exists for this email address.',
  ]);
}

/// Thrown when a chosen password does not meet minimum security requirements.
class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([
    super.message =
        'The password is too weak. Please use at least 6 characters.',
  ]);
}

/// Thrown when the user's account has been disabled by an administrator.
class UserDisabledFailure extends AuthFailure {
  const UserDisabledFailure([
    super.message =
        'This user account has been disabled. Please contact support.',
  ]);
}

/// Thrown when a network connectivity failure prevents completing authentication.
class NetworkFailure extends AuthFailure {
  const NetworkFailure([
    super.message =
        'Network connection error. Please check your internet connection.',
  ]);
}

/// Thrown when the user cancels the Google Sign-In sheet/picker.
class GoogleSignInCancelledFailure extends AuthFailure {
  const GoogleSignInCancelledFailure([
    super.message = 'Google sign-in was cancelled.',
  ]);
}

/// Thrown when Google Sign-In cannot complete due to missing OAuth / SHA-1 configuration.
class GoogleSignInConfigFailure extends AuthFailure {
  const GoogleSignInConfigFailure([
    super.message =
        'Google sign-in is not yet configured for this device (missing SHA-1 fingerprint in Firebase Console). Please use Email & Password or Demo Mode.',
  ]);
}

/// Generic server or unhandled failure.
class ServerFailure extends AuthFailure {
  const ServerFailure([
    super.message =
        'An unexpected authentication error occurred. Please try again.',
  ]);
}
