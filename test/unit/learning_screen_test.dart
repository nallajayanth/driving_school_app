import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driving_school_mobile_app/app/app.dart';

void main() {
  Future<void> settleApp(WidgetTester tester) async {
    // Advance frames boundedly so FutureProviders resolve without infinite animation loop
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('Learning Module Widget Tests', () {
    testWidgets(
      'Learning screen renders heading, search bar, class grouping and topic cards',
      (WidgetTester tester) async {
        await tester.pumpWidget(const ProviderScope(child: PowerdriveApp()));
        await settleApp(tester);

        // Navigate to Learning tab
        await tester.tap(find.text('Learning'));
        await settleApp(tester);

        // Heading and Search bar
        expect(find.text('Your learning units at a glance'), findsOneWidget);
        expect(find.text('Question number:'), findsOneWidget);
        expect(find.text('Call'), findsOneWidget);

        // Class grouping & prominent header
        expect(find.textContaining('Class GW'), findsOneWidget);
        expect(find.textContaining('Class B'), findsOneWidget);
        expect(find.text('GW'), findsWidgets);

        // Topic cards matching screenshots
        expect(
          find.text('General traffic regulations, tunnels'),
          findsOneWidget,
        );
        expect(find.text('General rules of the road, tunnel'), findsOneWidget);
        expect(find.text('0 / 92 Exam-ready'), findsOneWidget);

        expect(find.text('Special traffic areas'), findsWidgets);
        expect(find.text('0 / 56 Exam-ready'), findsOneWidget);

        expect(find.text('Moving through traffic'), findsOneWidget);
        expect(find.text('0 / 46 Exam-ready'), findsOneWidget);

        // Box counters and Phase
        expect(find.text('90'), findsOneWidget); // Box 0 count in unit 1
        expect(find.text('2'), findsWidgets); // Box 1 count in unit 1
        expect(find.textContaining('Start-up phase'), findsWidgets);
      },
    );

    testWidgets('Toggling driving class switches topics to Class B', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: PowerdriveApp()));
      await settleApp(tester);

      await tester.tap(find.text('Learning'));
      await settleApp(tester);

      // Tap Class B chip
      await tester.tap(find.textContaining('Class B'));
      await settleApp(tester);

      // Prominent B header
      expect(find.text('B'), findsWidgets);

      // Class B topic units
      expect(find.text('Vehicle technology, tires & lighting'), findsOneWidget);
      expect(find.text('Braking distances and load securing'), findsOneWidget);
    });

    testWidgets('Question search validates empty and non-numeric input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: PowerdriveApp()));
      await settleApp(tester);

      await tester.tap(find.text('Learning'));
      await settleApp(tester);

      // Tap Call with empty input
      await tester.tap(find.text('Call'));
      await settleApp(tester);

      expect(find.text('Please enter a question number'), findsOneWidget);

      // Enter non-numeric text
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.text('Call'));
      await settleApp(tester);

      expect(
        find.text('Please enter a valid numeric number (e.g. 1278)'),
        findsOneWidget,
      );
    });

    testWidgets('Successful question lookup navigates to QuestionDetailScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: PowerdriveApp()));
      await settleApp(tester);

      await tester.tap(find.text('Learning'));
      await settleApp(tester);

      // Enter valid question number 1278
      await tester.enterText(find.byType(TextField), '1278');
      await tester.tap(find.text('Call'));
      await settleApp(tester);

      // Verifies navigation to QuestionDetailScreen
      expect(find.text('Question #1278'), findsWidgets);
      expect(
        find.text(
          'What is the general speed limit on open country roads outside built-up areas in Austria?',
        ),
        findsOneWidget,
      );
      expect(find.text('80 km/h'), findsOneWidget);
      expect(find.text('100 km/h'), findsOneWidget);
      expect(find.text('130 km/h'), findsOneWidget);

      // Verify notice regarding pending backend rule verification
      expect(find.textContaining('Notice: Question answering'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settleApp(tester);

      expect(find.text('Your learning units at a glance'), findsOneWidget);
    });

    testWidgets('Unsuccessful question lookup displays not-found message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: PowerdriveApp()));
      await settleApp(tester);

      await tester.tap(find.text('Learning'));
      await settleApp(tester);

      // Enter non-existent question number
      await tester.enterText(find.byType(TextField), '99999');
      await tester.tap(find.text('Call'));
      await settleApp(tester);

      // Verifies not-found message
      expect(
        find.text('Question #99999 was not found in the catalog.'),
        findsOneWidget,
      );
    });

    testWidgets('Learning screen renders without overflow on 320px width', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ProviderScope(child: PowerdriveApp()));
      await settleApp(tester);

      await tester.tap(find.text('Learning'));
      await settleApp(tester);

      expect(find.text('Your learning units at a glance'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('General rules of the road, tunnel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
