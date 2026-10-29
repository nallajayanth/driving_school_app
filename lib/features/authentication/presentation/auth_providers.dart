import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/mock_auth_repository.dart';
import '../domain/user.dart';

/// Provider exposing the active [AuthRepository] implementation.
/// Defaults to [MockAuthRepository] during UI prototyping.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

/// AsyncNotifier managing the authenticated user session state.
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    return repo.getCurrentUser();
  }

  Future<void> changeLanguage(String languageCode) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.updateLanguage(languageCode);
      return repo.getCurrentUser();
    });
  }

  Future<void> logout() async {
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
