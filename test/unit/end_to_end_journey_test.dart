import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driving_school_mobile_app/app/app.dart';
import 'package:driving_school_mobile_app/core/widgets/app_button.dart';
import 'package:driving_school_mobile_app/features/authentication/presentation/auth_providers.dart';
import 'package:driving_school_mobile_app/features/exam_history/presentation/exam_providers.dart';

void main() {
  group('Phase 7 — End-to-End User Journey & Comprehensive Lifecycle Tests', () {
    testWidgets(
      'Full End-to-End Navigation Journey: Tabs, Examination Lifecycle, History Sync & Logout',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const PowerdriveApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial Launch at Dashboard
        expect(find.text('Welcome, Krishan Patel !'), findsOneWidget);
        expect(find.text('Box 0'), findsOneWidget);
        expect(find.text('1426'), findsOneWidget);

        // 2. Bottom Navigation: Switch through all 4 primary tabs
        // Tab 1: Learning
        await tester.tap(find.text('Learning'));
        await tester.pumpAndSettle();
        expect(find.text('Your learning units at a glance'), findsOneWidget);
        expect(find.text('Call'), findsOneWidget);

        // Tab 2: Pre-Check
        await tester.tap(find.text('Pre-Check'));
        await tester.pumpAndSettle();
        expect(find.text('Available Driving Classes'), findsOneWidget);
        expect(find.text('GW — 40 questions'), findsOneWidget);

        // Tab 3: Progress
        await tester.tap(find.text('Progress'));
        await tester.pumpAndSettle();
        expect(find.text('Learning progress'), findsOneWidget);
        expect(find.text('Overall Learning Statistics'), findsOneWidget);
        expect(find.text('Beginner'), findsOneWidget);

        // Tab 0: Return to Dashboard
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
        expect(find.text('Welcome, Krishan Patel !'), findsOneWidget);

        // 3. Complete Examination Lifecycle via Shortcut
        await tester.tap(find.text('Start preliminary check'));
        await tester.pumpAndSettle();

        // Select GW class
        await tester.tap(find.text('GW — 40 questions'));
        await tester.pumpAndSettle();
        expect(
          find.text('Total: 40 questions including bonus questions'),
          findsOneWidget,
        );

        // Start exam
        final startExamBtn = find.widgetWithText(
          AppButton,
          'Start preliminary check',
        );
        await tester.ensureVisible(startExamBtn);
        await tester.tap(startExamBtn);
        await tester.pumpAndSettle();

        // On ExamSessionScreen
        expect(find.text('Mock Examination'), findsOneWidget);
        expect(find.text('Question 1 of 5'), findsOneWidget);

        // Answer question 1
        final session = container.read(examSessionProvider);
        final firstOption = session.currentQuestion!.options.first.text;
        await tester.tap(find.text(firstOption));
        await tester.pumpAndSettle();

        // Advance to Question 2
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text('Question 2 of 5'), findsOneWidget);

        // Return to Question 1 to verify answer persistence
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();
        expect(find.text('Question 1 of 5'), findsOneWidget);

        // Finish examination from app bar action
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();

        // Confirm dialog
        expect(find.text('Finish Examination'), findsOneWidget);
        await tester.tap(find.text('Finish & Submit'));
        await tester.pumpAndSettle();

        // 4. On ExamResultScreen
        expect(find.text('Preliminary Check Completed!'), findsOneWidget);
        expect(
          find.textContaining('DEMONSTRATION ASSESSMENT ONLY'),
          findsOneWidget,
        );

        // 5. Navigate to Exam History from Result screen
        final viewHistoryBtn = find.text('View Exam History');
        await tester.ensureVisible(viewHistoryBtn);
        await tester.tap(viewHistoryBtn);
        await tester.pumpAndSettle();

        // Verify newly added attempt exists in History
        expect(find.text('Your preliminary exams'), findsOneWidget);
        expect(find.text('Total examinations taken: 2'), findsOneWidget);
        expect(find.text('Examination History'), findsOneWidget);

        // Tap "Start new preliminary check" button on Exam History screen!
        final startNewCheckBtn = find.widgetWithText(
          AppButton,
          'Start new preliminary check',
        );
        await tester.ensureVisible(startNewCheckBtn);
        await tester.tap(startNewCheckBtn);
        await tester.pumpAndSettle();
        expect(find.text('Available Driving Classes'), findsOneWidget);

        // Return to Dashboard tab
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
        expect(find.text('Welcome, Krishan Patel !'), findsOneWidget);

        // 6. Header Language Switch & Logout Dialog
        await tester.tap(find.text('DE DE'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('EN EN').last);
        await tester.pumpAndSettle();

        // Trigger Logout Dialog
        await tester.tap(find.text('Log out'));
        await tester.pumpAndSettle();
        expect(
          find.text('Are you sure you want to log out of your session?'),
          findsOneWidget,
        );

        // Cancel logout
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(container.read(currentUserProvider).asData?.value, isNotNull);

        // Confirm logout
        await tester.tap(find.text('Log out'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Log out'));
        await tester.pumpAndSettle();
        expect(container.read(currentUserProvider).asData?.value, isNull);
      },
    );
  });
}
