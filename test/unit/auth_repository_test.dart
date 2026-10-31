import 'package:flutter_test/flutter_test.dart';
import 'package:driving_school_mobile_app/features/authentication/data/mock_auth_repository.dart';
import 'package:driving_school_mobile_app/features/authentication/domain/auth_failure.dart';
import 'package:driving_school_mobile_app/features/authentication/domain/user.dart';

void main() {
  group('AuthRepository & Mock Implementation Unit Tests', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    test('Initial user session matches development baseline', () async {
      final user = await repo.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.id, 'dev_user_krishan');
      expect(user.name, 'Krishan Patel');
      expect(user.email, 'krishan.patel@example.com');
      expect(user.preferredLanguage, 'DE');
    });

    test('authStateChanges stream emits current user and updates', () async {
      final emissions = <User?>[];
      final subscription = repo.authStateChanges().listen((u) {
        emissions.add(u);
      });

      await repo.updateLanguage('EN');
      await repo.logout();

      await Future.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last, isNull);
    });

    test(
      'Successful email/password sign-in returns user with matching email',
      () async {
        final user = await repo.signInWithEmailAndPassword(
          email: 'test.learner@powerdrive.at',
          password: 'securePassword123',
        );

        expect(user.email, 'test.learner@powerdrive.at');
        expect(await repo.getCurrentUser(), equals(user));
      },
    );

    test(
      'Invalid email or empty password throws InvalidCredentialsFailure',
      () async {
        expect(
          () => repo.signInWithEmailAndPassword(
            email: 'invalid-email',
            password: 'password123',
          ),
          throwsA(isA<InvalidCredentialsFailure>()),
        );

        expect(
          () => repo.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
          throwsA(isA<InvalidCredentialsFailure>()),
        );
      },
    );

    test('Registration enforces minimum 6 character password', () async {
      expect(
        () => repo.registerWithEmailAndPassword(
          email: 'newuser@example.com',
          password: '123',
          name: 'New User',
        ),
        throwsA(isA<WeakPasswordFailure>()),
      );
    });

    test('Registration detects duplicate email collision', () async {
      expect(
        () => repo.registerWithEmailAndPassword(
          email: 'exists@example.com',
          password: 'securePassword123',
          name: 'Existing User',
        ),
        throwsA(isA<EmailAlreadyInUseFailure>()),
      );
    });

    test('Successful registration creates user profile', () async {
      final user = await repo.registerWithEmailAndPassword(
        email: 'fresh@example.com',
        password: 'password123',
        name: 'Fresh Learner',
      );

      expect(user.name, 'Fresh Learner');
      expect(user.email, 'fresh@example.com');
      expect(await repo.getCurrentUser(), equals(user));
    });

    test('Google sign-in returns demo learner profile', () async {
      final user = await repo.signInWithGoogle();

      expect(user.id, 'mock_google_109678');
      expect(user.name, contains('Google'));
      expect(await repo.getCurrentUser(), equals(user));
    });

    test('Language preference update persists on session', () async {
      await repo.updateLanguage('EN');
      final updated = await repo.getCurrentUser();
      expect(updated?.preferredLanguage, 'EN');
    });

    test('Logout clears authenticated session to null', () async {
      await repo.logout();
      final user = await repo.getCurrentUser();
      expect(user, isNull);
    });
  });
}
