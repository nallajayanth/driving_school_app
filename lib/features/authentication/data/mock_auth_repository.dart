import '../domain/user.dart';
import 'auth_repository.dart';

/// Explicitly labeled mock implementation of [AuthRepository] for development and UI prototyping.
/// Not connected to production authentication servers.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({User? initialUser})
    : _currentUser =
          initialUser ??
          const User(
            id: 'dev_user_krishan',
            name: 'Krishan Patel',
            email: 'krishan.patel@example.com',
            preferredLanguage: 'DE',
          );

  User? _currentUser;

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> updateLanguage(String languageCode) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(preferredLanguage: languageCode);
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}
