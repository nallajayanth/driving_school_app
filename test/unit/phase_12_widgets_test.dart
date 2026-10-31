import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driving_school_mobile_app/core/theme/app_theme.dart';
import 'package:driving_school_mobile_app/features/authentication/data/firebase_auth_repository.dart';
import 'package:driving_school_mobile_app/features/authentication/domain/user.dart';
import 'package:driving_school_mobile_app/features/authentication/presentation/auth_providers.dart';
import 'package:driving_school_mobile_app/features/learning/domain/question.dart';
import 'package:driving_school_mobile_app/features/learning/presentation/learning_screen.dart';
import 'package:driving_school_mobile_app/features/learning/presentation/question_detail_screen.dart';
import 'package:driving_school_mobile_app/features/progress/data/mock_learning_progress_repository.dart';
import 'package:driving_school_mobile_app/features/progress/domain/question_bookmark.dart';
import 'package:driving_school_mobile_app/features/progress/domain/resume_learning_state.dart';
import 'package:driving_school_mobile_app/features/progress/domain/student_learning_summary.dart';
import 'package:driving_school_mobile_app/features/progress/domain/student_question_progress.dart';
import 'package:driving_school_mobile_app/features/progress/presentation/progress_providers.dart';
import 'package:driving_school_mobile_app/features/progress/presentation/progress_screen.dart';

// Dummy class mimicking FirebaseAuthRepository to trigger live view in widget test
class TestFirebaseAuthRepository extends Fake
    implements FirebaseAuthRepository {
  @override
  Stream<User?> authStateChanges() => Stream.value(
    const User(
      id: 'test_uid_123',
      name: 'Verified Student',
      email: 'student@example.com',
    ),
  );

  @override
  Future<User?> getCurrentUser() async => const User(
    id: 'test_uid_123',
    name: 'Verified Student',
    email: 'student@example.com',
  );
}

class _TrueDemoNotifier extends DemoModeNotifier {
  @override
  bool build() => true;
}

class _FalseDemoNotifier extends DemoModeNotifier {
  @override
  bool build() => false;
}

class _TestAuthNotifierWithUser extends AuthNotifier {
  @override
  Future<User?> build() async => const User(
    id: 'test_uid_123',
    name: 'Verified Student',
    email: 'student@example.com',
  );
}

void main() {
  const dummyQuestion = Question(
    id: 'AT_GW_021',
    questionNumber: 21,
    drivingClassId: 'GW',
    text:
        'You are driving in a rural area. A deer appears on the road ahead. What should you do?',
    topic: 'hazard_awareness',
    selectionMode: QuestionSelectionMode.multiple,
    options: [
      QuestionAnswerOption(
        id: 'A',
        text: 'Brake firmly and keep your vehicle in lane.',
      ),
      QuestionAnswerOption(
        id: 'B',
        text: 'Swerve aggressively into oncoming traffic.',
      ),
      QuestionAnswerOption(
        id: 'C',
        text: 'Sound the horn and dim high beam lights.',
      ),
      QuestionAnswerOption(
        id: 'D',
        text: 'Accelerate to pass before the animal crosses.',
      ),
    ],
  );

  group('Phase 12: QuestionDetailScreen Widget Tests', () {
    testWidgets('Renders bookmark and review actions and toggles bookmark', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockLearningProgressRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isDemoModeProvider.overrideWith(() => _TrueDemoNotifier()),
            learningProgressRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const QuestionDetailScreen(
              questionNumber: 21,
              questionId: 'AT_GW_021',
              initialQuestion: dummyQuestion,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and metadata
      expect(find.text('Question #21'), findsOneWidget);
      expect(find.text('Class GW'), findsOneWidget);
      expect(find.text('Mark as reviewed'), findsOneWidget);

      // Bookmark button exists and is initially outline
      final bookmarkFinder = find.byTooltip('Bookmark Question');
      expect(bookmarkFinder, findsOneWidget);

      // Tap bookmark
      await tester.tap(bookmarkFinder);
      await tester.pumpAndSettle();

      expect(await mockRepo.isBookmarked('AT_GW_021'), isTrue);

      // Tap "Mark as reviewed"
      await tester.tap(find.text('Mark as reviewed'));
      await tester.pumpAndSettle();

      final map = await mockRepo.getQuestionProgressMap();
      expect(map['AT_GW_021']?.studyStatus, StudyStatus.reviewed);
      expect(find.text('Reviewed ✓'), findsOneWidget);
    });

    testWidgets('Selects option and resets selections', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockLearningProgressRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isDemoModeProvider.overrideWith(() => _TrueDemoNotifier()),
            learningProgressRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const QuestionDetailScreen(
              questionNumber: 21,
              questionId: 'AT_GW_021',
              initialQuestion: dummyQuestion,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first option
      await tester.tap(
        find.text('Brake firmly and keep your vehicle in lane.'),
      );
      await tester.pumpAndSettle();

      // Reset button should appear
      expect(find.text('Reset'), findsOneWidget);

      // Tap Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Reset button disappears
      expect(find.text('Reset'), findsNothing);
    });
  });

  group('Phase 12: LearningScreen Bookmarks & Resume Tests', () {
    testWidgets(
      'View switcher includes Bookmarks tab and renders empty state',
      (WidgetTester tester) async {
        final mockRepo = MockLearningProgressRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isDemoModeProvider.overrideWith(() => _TrueDemoNotifier()),
              learningProgressRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: LearningScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check Bookmarks tab in switcher
        expect(find.text('Bookmarks (0)'), findsOneWidget);

        // Tap Bookmarks tab
        await tester.tap(find.text('Bookmarks (0)'));
        await tester.pumpAndSettle();

        // Shows empty bookmarks state
        expect(find.text('No bookmarked questions yet'), findsOneWidget);
        expect(
          find.textContaining(
            'Tap the bookmark icon on any question in GW or Category B',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Displays bookmarked question card and allows removal', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockLearningProgressRepository(
        initialBookmarks: [
          QuestionBookmark(
            questionId: 'AT_GW_021',
            moduleCode: 'GW',
            topic: 'hazard_awareness',
            questionNumber: 21,
            questionText:
                'You are driving in a rural area. A deer appears on the road ahead. What should you do?',
            createdAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isDemoModeProvider.overrideWith(() => _TrueDemoNotifier()),
            learningProgressRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: LearningScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Bookmarks tab
      await tester.tap(find.text('Bookmarks (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Bookmarked Questions (1)'), findsOneWidget);
      expect(find.text('#21'), findsOneWidget);
      expect(
        find.text(
          'You are driving in a rural area. A deer appears on the road ahead. What should you do?',
        ),
        findsOneWidget,
      );

      // Tap remove bookmark icon
      await tester.tap(find.byTooltip('Remove bookmark'));
      await tester.pumpAndSettle();

      expect(await mockRepo.isBookmarked('AT_GW_021'), isFalse);
    });

    testWidgets('Displays Continue Learning banner when resume state exists', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockLearningProgressRepository(
        initialResumeState: ResumeLearningState(
          lastModuleCode: 'GW',
          lastQuestionId: 'AT_GW_021',
          lastQuestionNumber: 21,
          lastQuestionText:
              'You are driving in a rural area. A deer appears on the road ahead. What should you do?',
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isDemoModeProvider.overrideWith(() => _TrueDemoNotifier()),
            learningProgressRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: LearningScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('Question #21 (GW)'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
    });
  });

  group('Phase 12: ProgressScreen Live Learning Activity Dashboard Tests', () {
    testWidgets(
      'Live Firebase student progress displays real metrics and omits grading',
      (WidgetTester tester) async {
        final fakeAuthRepo = TestFirebaseAuthRepository();
        const testSummary = StudentLearningSummary(
          totalAvailableQuestions: 74,
          viewedCount: 22,
          inProgressCount: 9,
          reviewedCount: 14,
          gwReviewedCount: 10,
          bReviewedCount: 4,
          totalBookmarks: 7,
          recentlyViewedQuestions: [
            StudentQuestionProgress(
              questionId: 'AT_GW_001',
              moduleCode: 'GW',
              questionNumber: 1,
              studyStatus: StudyStatus.reviewed,
              topic: 'general_rules',
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              isDemoModeProvider.overrideWith(() => _FalseDemoNotifier()),
              currentUserProvider.overrideWith(
                () => _TestAuthNotifierWithUser(),
              ),
              studentLearningSummaryProvider.overrideWith(
                (ref) => Stream.value(testSummary),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ProgressScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Cloud Firestore live badge is rendered
        expect(
          find.text('LIVE AUSTRIAN LEARNING ACTIVITY · CLOUD FIRESTORE'),
          findsOneWidget,
        );

        // Real calculated activity metrics are displayed
        expect(find.text('74'), findsOneWidget); // Total questions
        expect(find.text('22'), findsOneWidget); // Viewed
        expect(find.text('9'), findsOneWidget); // In progress
        expect(find.text('14'), findsOneWidget); // Reviewed

        // Category review metrics
        expect(find.textContaining('10 / 42'), findsOneWidget); // GW
        expect(find.textContaining('4 / 32'), findsOneWidget); // B
        expect(find.text('7 saved'), findsOneWidget); // Bookmarks

        // Recently viewed section
        expect(find.text('Recently viewed questions'), findsOneWidget);
        expect(find.text('#1'), findsOneWidget);

        // STRICT REQUIREMENT VERIFICATION:
        // None of the unverified grading metrics must appear in live Firebase mode!
        expect(find.text('Accuracy percentage'), findsNothing);
        expect(find.text('Exam score'), findsNothing);
        expect(find.text('Passing percentage'), findsNothing);
        expect(find.text('Correct answer count'), findsNothing);
        expect(find.text('Performance ranking'), findsNothing);
      },
    );
  });
}
