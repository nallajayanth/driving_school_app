import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driving_school_mobile_app/core/theme/app_theme.dart';
import 'package:driving_school_mobile_app/features/exam_history/domain/exam_attempt.dart';
import 'package:driving_school_mobile_app/features/exam_history/presentation/exam_history_screen.dart';
import 'package:driving_school_mobile_app/features/exam_history/presentation/exam_providers.dart';
import 'package:driving_school_mobile_app/features/preliminary_check/presentation/exam_result_screen.dart';
import 'package:driving_school_mobile_app/features/preliminary_check/presentation/exam_session_screen.dart';
import 'package:driving_school_mobile_app/features/preliminary_check/presentation/preliminary_check_screen.dart';

void main() {
  group('Phase 5 — Preliminary Check & Exam Session Unit Tests', () {
    test(
      'PreliminarySelectionNotifier handles selection and count updates',
      () async {
        final ref = ProviderContainer();
        addTearDown(ref.dispose);

        final repo = ref.read(examRepositoryProvider);
        final classes = await repo.getEligibleExamClasses();

        // Initial state
        expect(ref.read(preliminarySelectionProvider).canStart, isFalse);
        expect(ref.read(preliminarySelectionProvider).totalQuestions, 0);

        // Select GW
        ref
            .read(preliminarySelectionProvider.notifier)
            .toggleClass('GW', classes);
        expect(ref.read(preliminarySelectionProvider).canStart, isTrue);
        expect(ref.read(preliminarySelectionProvider).totalQuestions, 40);
        expect(
          ref.read(preliminarySelectionProvider).selectedClassCodes,
          contains('GW'),
        );

        // Select B
        ref
            .read(preliminarySelectionProvider.notifier)
            .toggleClass('B', classes);
        expect(ref.read(preliminarySelectionProvider).canStart, isTrue);
        expect(ref.read(preliminarySelectionProvider).totalQuestions, 80);

        // Deselect GW
        ref
            .read(preliminarySelectionProvider.notifier)
            .toggleClass('GW', classes);
        expect(ref.read(preliminarySelectionProvider).canStart, isTrue);
        expect(ref.read(preliminarySelectionProvider).totalQuestions, 40);
        expect(
          ref.read(preliminarySelectionProvider).selectedClassCodes,
          isNot(contains('GW')),
        );

        // Clear selection
        ref.read(preliminarySelectionProvider.notifier).clearSelection();
        expect(ref.read(preliminarySelectionProvider).canStart, isFalse);
        expect(ref.read(preliminarySelectionProvider).totalQuestions, 0);
      },
    );

    test(
      'ExamSessionNotifier handles answering, bounds navigation, and persistence',
      () async {
        final ref = ProviderContainer();
        addTearDown(ref.dispose);

        // Start session with GW
        await ref.read(examSessionProvider.notifier).startSession(['GW']);

        final session = ref.read(examSessionProvider);
        expect(session.questions.isNotEmpty, isTrue);
        expect(session.currentIndex, 0);
        expect(session.isFirstQuestion, isTrue);

        final firstQ = session.currentQuestion!;
        final optionToSelect = firstQ.options.first.id;

        // Select answer
        ref
            .read(examSessionProvider.notifier)
            .selectAnswer(firstQ.id, optionToSelect);
        expect(
          ref.read(examSessionProvider).selectedAnswers[firstQ.id],
          optionToSelect,
        );

        // Navigate to next question
        ref.read(examSessionProvider.notifier).nextQuestion();
        expect(ref.read(examSessionProvider).currentIndex, 1);
        expect(ref.read(examSessionProvider).isFirstQuestion, isFalse);

        // Answer persisted when returning to first question
        ref.read(examSessionProvider.notifier).previousQuestion();
        expect(ref.read(examSessionProvider).currentIndex, 0);
        expect(
          ref.read(examSessionProvider).selectedAnswers[firstQ.id],
          optionToSelect,
        );

        // Previous on first question stays at 0
        ref.read(examSessionProvider.notifier).previousQuestion();
        expect(ref.read(examSessionProvider).currentIndex, 0);

        // Submit exam
        final attempt = await ref
            .read(examSessionProvider.notifier)
            .submitExam();
        expect(attempt, isNotNull);
        expect(attempt!.selectedClasses, contains('GW'));
        expect(ref.read(examSessionProvider).isFinished, isTrue);
      },
    );
  });

  group('Phase 5 — Widget Tests', () {
    testWidgets(
      'PreliminaryCheckScreen toggles classes and enables start button',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const PreliminaryCheckScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Start preliminary check'),
          findsNWidgets(2),
        ); // Title and Button
        expect(find.text('Available Driving Classes'), findsOneWidget);
        expect(find.text('GW — 40 questions'), findsOneWidget);
        expect(find.text('B — 40 questions'), findsOneWidget);

        // Initially disabled total
        expect(
          find.text('Total: 0 questions including bonus questions'),
          findsOneWidget,
        );

        // Tap GW
        await tester.tap(find.text('GW — 40 questions'));
        await tester.pumpAndSettle();

        expect(
          find.text('Total: 40 questions including bonus questions'),
          findsOneWidget,
        );

        // Tap B
        await tester.tap(find.text('B — 40 questions'));
        await tester.pumpAndSettle();

        expect(
          find.text('Total: 80 questions including bonus questions'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ExamSessionScreen renders question, selects answer and displays confirmation',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Initialize session
        await container.read(examSessionProvider.notifier).startSession(['GW']);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ExamSessionScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mock Examination'), findsOneWidget);
        expect(find.text('Question 1 of 5'), findsOneWidget);
        expect(find.text('Previous'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);

        // Tap an answer option
        final session = container.read(examSessionProvider);
        final firstOptionText = session.currentQuestion!.options.first.text;
        await tester.tap(find.text(firstOptionText));
        await tester.pumpAndSettle();

        // Tap Finish button in app bar
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();

        // Verify finish confirmation dialog
        expect(find.text('Finish Examination'), findsOneWidget);
        expect(find.text('Review Questions'), findsOneWidget);
        expect(find.text('Finish & Submit'), findsOneWidget);
      },
    );

    testWidgets(
      'ExamResultScreen displays score, mock disclaimer, and buttons',
      (WidgetTester tester) async {
        final attempt = ExamAttempt(
          id: 'test_attempt',
          dateTime: DateTime.now(),
          selectedClasses: const ['GW'],
          totalQuestions: 5,
          pointsScored: 4,
          scorePercentage: 80.0,
          isPassed: true,
          statusLabel: 'Bestanden (Demo)',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: ExamResultScreen(attempt: attempt),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Preliminary Check Completed!'), findsOneWidget);
        expect(find.text('80%'), findsOneWidget);
        expect(find.text('Bestanden (Demo)'), findsOneWidget);
        expect(find.text('Return to Dashboard'), findsOneWidget);
        expect(find.text('View Exam History'), findsOneWidget);
        expect(find.text('Start Another Preliminary Check'), findsOneWidget);
        expect(
          find.textContaining('DEMONSTRATION ASSESSMENT ONLY'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ExamHistoryScreen displays attempts list and performance chart',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ExamHistoryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Your preliminary exams'), findsOneWidget);
        expect(find.text('Start new preliminary check'), findsOneWidget);
        expect(find.text('Performance Trend'), findsOneWidget);
        expect(find.text('Examination History'), findsOneWidget);
        expect(find.text('0% (0/40)'), findsOneWidget);
        expect(find.text('Nicht bestanden'), findsOneWidget);
      },
    );

    testWidgets(
      'Phase 5 screens render cleanly on narrow 320px width without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const PreliminaryCheckScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Start preliminary check'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
