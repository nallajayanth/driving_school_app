import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driving_school_mobile_app/app/app.dart';

void main() {
  testWidgets(
    'PowerdriveApp smoke test - verifies initial navigation shell and header',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: PowerdriveApp()));
      await tester.pumpAndSettle();

      // Verify brand header elements
      expect(find.textContaining('Powerdrive'), findsOneWidget);
      expect(find.text('DE DE'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);

      // Verify bottom navigation destinations
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Pre-Check'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
    },
  );

  testWidgets(
    'DashboardScreen renders all sections, status cards, and tip banner',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: PowerdriveApp()));
      await tester.pumpAndSettle();

      // Mock data indicator
      expect(find.text('Development Mode · Local Mock Data'), findsOneWidget);

      // Welcome Section
      expect(find.text('Welcome, Krishan Patel !'), findsOneWidget);
      expect(
        find.text(
          "It's great to have you here! Choose how you would like to continue:",
        ),
        findsOneWidget,
      );

      // Action Shortcuts
      expect(find.text('Practice exam questions'), findsOneWidget);
      expect(find.text('Start preliminary check'), findsOneWidget);
      expect(find.text('Preliminary audit statistics'), findsOneWidget);

      // Learning Progress Section
      expect(find.text('Your learning progress'), findsOneWidget);

      // 4 Leitner Status Cards
      expect(find.text('Box 0'), findsOneWidget);
      expect(find.text('1426'), findsOneWidget);
      expect(find.text('New or not correct 🔄'), findsOneWidget);

      expect(find.text('Subject 1'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('1x correct 👍'), findsOneWidget);

      expect(find.text('Subject 2'), findsOneWidget);
      expect(find.text('Correct twice in a row 💪'), findsOneWidget);

      expect(find.text('Subject 3'), findsOneWidget);
      expect(find.text('Ready for the exam ✅'), findsOneWidget);

      // Tip Banner
      expect(
        find.text(
          'Tip: You can switch to the pre-test at any time to test your progress!',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Dashboard action shortcuts navigate to respective routes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PowerdriveApp()));
    await tester.pumpAndSettle();

    // Tap "Start preliminary check" shortcut
    await tester.tap(find.text('Start preliminary check'));
    await tester.pumpAndSettle();

    // Verify Preliminary Check screen is visible
    expect(find.text('Available Driving Classes'), findsOneWidget);

    // Return to Dashboard tab
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    // Tap "Practice exam questions" shortcut
    await tester.tap(find.text('Practice exam questions'));
    await tester.pumpAndSettle();

    // Verify Learning screen is visible
    expect(find.text('Your learning units at a glance'), findsOneWidget);

    // Return to Dashboard tab
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    // Tap "Preliminary audit statistics" shortcut
    await tester.tap(find.text('Preliminary audit statistics'));
    await tester.pumpAndSettle();

    // Verify Exam History screen is pushed
    expect(find.text('Your preliminary exams'), findsOneWidget);
  });

  testWidgets(
    'PowerdriveApp renders cleanly without overflow on narrow width (320px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ProviderScope(child: PowerdriveApp()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Powerdrive'), findsOneWidget);
      expect(find.text('Welcome, Krishan Patel !'), findsOneWidget);
      expect(find.text('Box 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
