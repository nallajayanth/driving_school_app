import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../data/mock_auth_repository.dart';
import '../domain/user.dart';

/// Notifier managing whether the application is running in local Demo/Mock mode.
class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setDemoMode(bool enabled) {
    state = enabled;
  }
}

/// Provider exposing whether local mock demo mode is active.
final isDemoModeProvider = NotifierProvider<DemoModeNotifier, bool>(() {
  return DemoModeNotifier();
});

/// Provider exposing the mock auth repository instance.
final mockAuthRepositoryProvider = Provider<MockAuthRepository>((ref) {
  return MockAuthRepository();
});

/// Provider exposing the Firebase auth repository instance.
final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Provider exposing the active [AuthRepository] implementation.
/// Uses [FirebaseAuthRepository] when Firebase is configured and initialized,
/// or [MockAuthRepository] during local demo mode or widget tests where Firebase is uninitialized.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  if (isDemoMode) {
    return ref.watch(mockAuthRepositoryProvider);
  }

  try {
    if (Firebase.apps.isNotEmpty) {
      return ref.watch(firebaseAuthRepositoryProvider);
    }
  } catch (_) {
    // Firebase not initialized (e.g. unit test environment)
  }

  return ref.watch(mockAuthRepositoryProvider);
});

/// Stream provider listening to reactive auth-state changes.
final authStateStreamProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// AsyncNotifier managing the authenticated user session state.
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.watch(authRepositoryProvider);

    // Synchronize state when the repository emits auth changes
    ref.listen(authStateStreamProvider, (previous, next) {
      if (next.hasValue) {
        state = AsyncData(next.value);
        if (next.value != null && repo is FirebaseAuthRepository) {
          ref.read(isDemoModeProvider.notifier).setDemoMode(false);
        }
      }
    });

    final currentUser = await repo.getCurrentUser();
    if (currentUser != null && repo is FirebaseAuthRepository) {
      ref.read(isDemoModeProvider.notifier).setDemoMode(false);
    }
    return currentUser;
  }

  /// Authenticates using email and password.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    ref.read(isDemoModeProvider.notifier).setDemoMode(false);
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await repo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user;
    });
  }

  /// Registers a new account with email, password, and learner name.
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    ref.read(isDemoModeProvider.notifier).setDemoMode(false);
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await repo.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      return user;
    });
  }

  /// Authenticates using Google Sign-In.
  Future<void> signInWithGoogle() async {
    ref.read(isDemoModeProvider.notifier).setDemoMode(false);
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await repo.signInWithGoogle();
      return user;
    });
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.sendPasswordResetEmail(email);
  }

  /// Updates preferred application language.
  Future<void> changeLanguage(String languageCode) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.updateLanguage(languageCode);
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(preferredLanguage: languageCode));
    }
  }

  /// Enables offline demo mode with mock learner data.
  Future<void> enableDemoMode() async {
    ref.read(isDemoModeProvider.notifier).setDemoMode(true);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      if (repo is MockAuthRepository) {
        repo.enableMockUser();
        return repo.getCurrentUser();
      }
      ref.invalidate(authRepositoryProvider);
      final newRepo = ref.read(authRepositoryProvider);
      if (newRepo is MockAuthRepository) {
        newRepo.enableMockUser();
      }
      return newRepo.getCurrentUser();
    });
  }

  /// Terminates the active session.
  Future<void> logout() async {
    ref.read(isDemoModeProvider.notifier).setDemoMode(false);
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.logout();
      return null;
    });
  }
}

/// Provider exposing the current user session.
final currentUserProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});
