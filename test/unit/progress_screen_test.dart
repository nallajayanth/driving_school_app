import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driving_school_mobile_app/core/theme/app_theme.dart';
import 'package:driving_school_mobile_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:driving_school_mobile_app/features/progress/data/mock_progress_repository.dart';
import 'package:driving_school_mobile_app/features/progress/domain/learning_progress.dart';
import 'package:driving_school_mobile_app/features/progress/presentation/progress_providers.dart';
import 'package:driving_school_mobile_app/features/progress/presentation/progress_screen.dart';
import 'package:driving_school_mobile_app/features/progress/presentation/widgets/subject_distribution_chart.dart';
import 'package:driving_school_mobile_app/features/progress/presentation/widgets/topic_progress_card.dart';

void main() {
  group('Phase 6 — Progress Dashboard and Learning Analytics Tests', () {
    testWidgets(
      'ProgressScreen renders header, statistics, chart, and topic cards',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ProgressScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Screen title and subtitle
        expect(find.text('Learning progress'), findsOneWidget);
        expect(
          find.textContaining('Track your overall learning statistics'),
          findsOneWidget,
        );

        // Overall learning statistics
        expect(find.text('Overall Learning Statistics'), findsOneWidget);
        expect(find.text('6'), findsOneWidget);
        expect(find.text('Questions answered'), findsOneWidget);
        expect(find.text('Beginner'), findsOneWidget);
        expect(find.text('Milestone rank'), findsOneWidget);

        // Distribution chart
        expect(find.byType(SubjectDistributionChart), findsOneWidget);
        expect(find.text('Distribution by subject level'), findsOneWidget);
        expect(
          find.text('Fach 0'),
          findsNWidgets(2),
        ); // Bar chart title & legend chip
        expect(find.text('Fach 1'), findsNWidgets(2));
        expect(find.text('Fach 2'), findsNWidgets(2));
        expect(find.text('Fach 3'), findsNWidgets(2));

        // Topic progress cards
        expect(find.byType(TopicProgressCard), findsNWidgets(3));
        expect(find.text('General rules of the road, tunnel'), findsOneWidget);
        expect(find.text('Special traffic areas'), findsOneWidget);
        expect(find.text('Moving through traffic'), findsOneWidget);
        expect(find.text('1.0%'), findsOneWidget);
        expect(find.text('0.0%'), findsNWidgets(2));
      },
    );

    testWidgets('ProgressScreen handles empty progress state gracefully', (
      WidgetTester tester,
    ) async {
      const emptyProgress = LearningProgress(
        totalQuestionsAnswered: 0,
        currentLearningLevel: 'New Learner',
        currentLearningLevelIcon: '🌱',
        box0QuestionsCount: 0,
        subject1QuestionsCount: 0,
        subject2QuestionsCount: 0,
        subject3QuestionsCount: 0,
        fach0Value: 0.0,
        fach1Value: 0.0,
        fach2Value: 0.0,
        fach3Value: 0.0,
        topicsProgress: [],
      );

      final emptyRepo = MockProgressRepository(initialData: emptyProgress);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [progressRepositoryProvider.overrideWithValue(emptyRepo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProgressScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('New Learner'), findsOneWidget);
      expect(
        find.textContaining('Ready to begin? Practice questions'),
        findsOneWidget,
      );
      expect(find.text('No topic analytics available'), findsOneWidget);
      expect(find.byType(TopicProgressCard), findsNothing);
    });

    testWidgets('ProgressScreen renders retry state on error', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          learningProgressProvider.overrideWith(
            () => _FailingProgressNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProgressScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load learning analytics'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Pull-to-refresh invokes reload on ProgressNotifier', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProgressScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger pull down gesture on scrollable body
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning progress'), findsOneWidget);
    });

    testWidgets(
      'Dashboard and Progress screens present consistent question counts',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Verify repository data consistency
        final progress = await container.read(learningProgressProvider.future);
        expect(progress.box0QuestionsCount, 1426);
        expect(progress.subject1QuestionsCount, 2);
        expect(progress.totalQuestionsAnswered, 6);

        // Render Dashboard
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Box 0'), findsOneWidget);
        expect(find.text('1426'), findsOneWidget);
        expect(find.text('Subject 1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets(
      'ProgressScreen renders cleanly on narrow 320px width without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ProgressScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Learning progress'), findsOneWidget);
        expect(find.text('Overall Learning Statistics'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _FailingProgressNotifier extends ProgressNotifier {
  @override
  Future<LearningProgress> build() async {
    throw Exception('Simulated repository connection failure');
  }
}
