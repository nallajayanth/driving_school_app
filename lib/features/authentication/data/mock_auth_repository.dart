import 'dart:async';
import '../domain/auth_failure.dart';
import '../domain/user.dart';
import 'auth_repository.dart';

/// Explicitly labeled mock implementation of [AuthRepository] for development,
/// automated testing, and offline prototyping.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({User? initialUser})
    : _currentUser =
          initialUser ??
          const User(
            id: 'dev_user_krishan',
            name: 'Krishan Patel',
            email: 'krishan.patel@example.com',
            preferredLanguage: 'DE',
          ) {
    if (_currentUser != null) {
      _authStreamController.add(_currentUser);
    }
  }

  MockAuthRepository.unauthenticated() : _currentUser = null;

  void enableMockUser([User? user]) {
    _currentUser =
        user ??
        const User(
          id: 'dev_user_krishan',
          name: 'Krishan Patel',
          email: 'krishan.patel@example.com',
          preferredLanguage: 'DE',
        );
    _authStreamController.add(_currentUser);
  }

  User? _currentUser;
  final StreamController<User?> _authStreamController =
      StreamController<User?>.broadcast();

  @override
  Stream<User?> authStateChanges() {
    late StreamController<User?> controller;
    StreamSubscription<User?>? sub;

    controller = StreamController<User?>.broadcast(
      onListen: () {
        controller.add(_currentUser);
        sub = _authStreamController.stream.listen(
          controller.add,
          onError: controller.addError,
        );
      },
      onCancel: () {
        sub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || password.isEmpty) {
      throw const InvalidCredentialsFailure();
    }
    // Simulate invalid password check for testing
    if (password == 'wrongpassword') {
      throw const InvalidCredentialsFailure();
    }

    final displayName = cleanEmail.split('@').first;
    final user = User(
      id: 'mock_${cleanEmail.hashCode.abs()}',
      name: displayName.isNotEmpty
          ? '${displayName[0].toUpperCase()}${displayName.substring(1)}'
          : 'Mock User',
      email: cleanEmail,
      preferredLanguage: _currentUser?.preferredLanguage ?? 'DE',
    );

    _currentUser = user;
    _authStreamController.add(user);
    return user;
  }

  @override
  Future<User> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw const InvalidCredentialsFailure(
        'Please enter a valid email address.',
      );
    }
    if (password.length < 6) {
      throw const WeakPasswordFailure();
    }
    if (cleanEmail == 'exists@example.com') {
      throw const EmailAlreadyInUseFailure();
    }

    final user = User(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isNotEmpty ? name.trim() : 'Learner',
      email: cleanEmail,
      preferredLanguage: 'DE',
    );

    _currentUser = user;
    _authStreamController.add(user);
    return user;
  }

  @override
  Future<User> signInWithGoogle() async {
    const user = User(
      id: 'mock_google_109678',
      name: 'Google Learner (Demo)',
      email: 'demo.google@powerdrive.at',
      preferredLanguage: 'DE',
    );

    _currentUser = user;
    _authStreamController.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw const InvalidCredentialsFailure(
        'Please enter a valid email address.',
      );
    }
    // Mock simulation: successful no-op
  }

  @override
  Future<void> updateLanguage(String languageCode) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(preferredLanguage: languageCode);
      _authStreamController.add(_currentUser);
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _authStreamController.add(null);
  }
}
