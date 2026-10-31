import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driving_school_mobile_app/app/app.dart';
import 'package:driving_school_mobile_app/features/authentication/data/mock_auth_repository.dart';
import 'package:driving_school_mobile_app/features/authentication/presentation/auth_providers.dart';
import 'package:driving_school_mobile_app/features/authentication/presentation/forgot_password_screen.dart';
import 'package:driving_school_mobile_app/features/authentication/presentation/login_screen.dart';
import 'package:driving_school_mobile_app/features/authentication/presentation/register_screen.dart';

void main() {
  group('Authentication Presentation & Widget Tests', () {
    testWidgets(
      'LoginScreen renders branding, input fields, and action buttons',
      (WidgetTester tester) async {
        final unauthRepo = MockAuthRepository.unauthenticated();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(unauthRepo)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Check header and titles
        expect(find.text('Welcome back'), findsOneWidget);
        expect(
          find.text(
            'Sign in to continue your Austrian driving theory training',
          ),
          findsOneWidget,
        );

        // Check text fields
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Forgot password?'), findsOneWidget);

        // Check buttons
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Offline Demo Mode'), findsOneWidget);
        expect(find.text('Enter Demo'), findsOneWidget);
        expect(find.text('Register now'), findsOneWidget);
      },
    );

    testWidgets(
      'LoginScreen validates empty email and password on submission',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                MockAuthRepository.unauthenticated(),
              ),
            ],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Sign In without filling in fields
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your email address.'), findsOneWidget);
        expect(find.text('Please enter your password.'), findsOneWidget);
      },
    );

    testWidgets(
      'RegisterScreen validates field requirements and matching passwords',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                MockAuthRepository.unauthenticated(),
              ),
            ],
            child: const MaterialApp(home: RegisterScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create an account'), findsOneWidget);
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);

        // Trigger empty validation
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your name.'), findsOneWidget);
        expect(find.text('Please enter your email address.'), findsOneWidget);
        expect(find.text('Please enter a password.'), findsOneWidget);
      },
    );

    testWidgets('ForgotPasswordScreen renders reset interface', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              MockAuthRepository.unauthenticated(),
            ),
          ],
          child: const MaterialApp(home: ForgotPasswordScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset your password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });

    testWidgets(
      'Demo Mode button signs in as mock learner and navigates to Dashboard',
      (WidgetTester tester) async {
        // Pump the entire PowerdriveApp with an initially unauthenticated repository
        final unauthRepo = MockAuthRepository.unauthenticated();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(unauthRepo)],
            child: const PowerdriveApp(),
          ),
        );
        await tester.pumpAndSettle();

        // App redirects to /login because unauthenticated
        expect(find.text('Welcome back'), findsOneWidget);
        expect(find.text('Enter Demo'), findsOneWidget);

        // Tap Enter Demo
        await tester.tap(find.text('Enter Demo'));
        await tester.pumpAndSettle();

        // Verifies navigation to Dashboard
        expect(find.text('Welcome, Krishan Patel !'), findsOneWidget);
        expect(find.text('Box 0'), findsOneWidget);
        expect(find.text('Dashboard'), findsOneWidget);
      },
    );
  });
}
