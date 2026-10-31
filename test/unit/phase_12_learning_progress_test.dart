import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driving_school_mobile_app/features/authentication/presentation/auth_providers.dart';
import 'package:driving_school_mobile_app/features/learning/data/question_mapper.dart';
import 'package:driving_school_mobile_app/features/learning/domain/question.dart';
import 'package:driving_school_mobile_app/features/learning/presentation/learning_providers.dart';
import 'package:driving_school_mobile_app/features/progress/data/mock_learning_progress_repository.dart';
import 'package:driving_school_mobile_app/features/progress/domain/question_bookmark.dart';
import 'package:driving_school_mobile_app/features/progress/domain/resume_learning_state.dart';
import 'package:driving_school_mobile_app/features/progress/domain/student_learning_summary.dart';
import 'package:driving_school_mobile_app/features/progress/domain/student_question_progress.dart';
import 'package:driving_school_mobile_app/features/progress/presentation/progress_providers.dart';

class _TrueDemoNotifier extends DemoModeNotifier {
  @override
  bool build() => true;
}

void main() {
  group('Phase 12: Domain Model Serialization & Status Tests', () {
    test(
      'Verified canonical mapping: AT_GW_021 -> 21, AT_B_001 -> 1, AT_GW_062 -> 62, AT_B_032 -> 32',
      () {
        expect(QuestionMapper.extractQuestionNumber('AT_GW_021'), 21);
        expect(QuestionMapper.extractQuestionNumber('AT_B_001'), 1);
        expect(QuestionMapper.extractQuestionNumber('AT_GW_062'), 62);
        expect(QuestionMapper.extractQuestionNumber('AT_B_032'), 32);
      },
    );

    test('StudentQuestionProgress serializes and parses properly', () {
      final now = DateTime.now();
      final progress = StudentQuestionProgress(
        questionId: 'AT_GW_021',
        moduleCode: 'GW',
        languageCode: 'en',
        topic: 'hazard_awareness',
        selectedOptionIds: const ['A', 'C'],
        studyStatus: StudyStatus.inProgress,
        firstViewedAt: now,
        lastViewedAt: now,
        updatedAt: now,
        questionNumber: 21,
      );

      final json = progress.toJson();
      final deserialized = StudentQuestionProgress.fromJson(json);

      expect(deserialized.questionId, 'AT_GW_021');
      expect(deserialized.moduleCode, 'GW');
      expect(deserialized.topic, 'hazard_awareness');
      expect(deserialized.selectedOptionIds, ['A', 'C']);
      expect(deserialized.studyStatus, StudyStatus.inProgress);
      expect(deserialized.isInProgress, isTrue);
      expect(deserialized.isReviewed, isFalse);
      expect(deserialized.questionNumber, 21);
    });

    test('StudyStatus string values match requirements', () {
      expect(StudyStatus.viewed.toValue(), 'viewed');
      expect(StudyStatus.inProgress.toValue(), 'in_progress');
      expect(StudyStatus.reviewed.toValue(), 'reviewed');

      expect(StudyStatus.fromValue('viewed'), StudyStatus.viewed);
      expect(StudyStatus.fromValue('in_progress'), StudyStatus.inProgress);
      expect(StudyStatus.fromValue('reviewed'), StudyStatus.reviewed);
      expect(StudyStatus.fromValue('unknown'), StudyStatus.viewed);
    });

    test('QuestionBookmark serializes and parses properly', () {
      final now = DateTime.now();
      final bookmark = QuestionBookmark(
        questionId: 'AT_B_005',
        moduleCode: 'B',
        topic: 'speed_limits',
        createdAt: now,
        questionNumber: 5,
        questionText: 'What is the speed limit in urban areas?',
      );

      final json = bookmark.toJson();
      final deserialized = QuestionBookmark.fromJson(json);

      expect(deserialized.questionId, 'AT_B_005');
      expect(deserialized.moduleCode, 'B');
      expect(deserialized.topic, 'speed_limits');
      expect(deserialized.questionNumber, 5);
      expect(deserialized.questionText, contains('speed limit'));
    });

    test('ResumeLearningState serializes and parses properly', () {
      final now = DateTime.now();
      final state = ResumeLearningState(
        lastModuleCode: 'GW',
        lastQuestionId: 'AT_GW_042',
        lastQuestionNumber: 42,
        lastQuestionText: 'Right of way at roundabout',
        updatedAt: now,
      );

      final json = state.toJson();
      final deserialized = ResumeLearningState.fromJson(json);

      expect(deserialized.lastModuleCode, 'GW');
      expect(deserialized.lastQuestionId, 'AT_GW_042');
      expect(deserialized.lastQuestionNumber, 42);
    });

    test('StudentLearningSummary calculates metrics correctly', () {
      const summary = StudentLearningSummary(
        totalAvailableQuestions: 74,
        viewedCount: 15,
        inProgressCount: 8,
        reviewedCount: 6,
        gwReviewedCount: 4,
        bReviewedCount: 2,
        totalBookmarks: 5,
      );

      expect(summary.totalAvailableQuestions, 74);
      expect(summary.viewedCount, 15);
      expect(summary.inProgressCount, 8);
      expect(summary.reviewedCount, 6);
      expect(summary.gwReviewedCount, 4);
      expect(summary.bReviewedCount, 2);
      expect(summary.totalBookmarks, 5);
    });
  });

  group('Phase 12: MockLearningProgressRepository Behavior Tests', () {
    late MockLearningProgressRepository repo;

    setUp(() {
      repo = MockLearningProgressRepository();
    });

    test('1. Record question viewed creates viewed progress', () async {
      await repo.recordQuestionViewed(
        questionId: 'AT_GW_001',
        moduleCode: 'GW',
        topic: 'priority',
        questionNumber: 1,
      );

      final map = await repo.getQuestionProgressMap();
      expect(map.containsKey('AT_GW_001'), isTrue);
      final p = map['AT_GW_001']!;
      expect(p.studyStatus, StudyStatus.viewed);
      expect(p.isViewed, isTrue);
      expect(p.firstViewedAt, isNotNull);
      expect(p.lastViewedAt, isNotNull);
    });

    test(
      '2 & 3. Save single and multiple options sets status in_progress',
      () async {
        // Save single option
        await repo.saveSelectedOptions(
          questionId: 'AT_GW_001',
          moduleCode: 'GW',
          optionIds: ['A'],
          questionNumber: 1,
        );

        var map = await repo.getQuestionProgressMap();
        expect(map['AT_GW_001']!.selectedOptionIds, ['A']);
        expect(map['AT_GW_001']!.studyStatus, StudyStatus.inProgress);

        // Save multiple options
        await repo.saveSelectedOptions(
          questionId: 'AT_GW_001',
          moduleCode: 'GW',
          optionIds: ['A', 'C'],
          questionNumber: 1,
        );

        map = await repo.getQuestionProgressMap();
        expect(map['AT_GW_001']!.selectedOptionIds, ['A', 'C']);
        expect(map['AT_GW_001']!.studyStatus, StudyStatus.inProgress);
      },
    );

    test(
      '4. Reset selected options clears options and resets status to viewed',
      () async {
        await repo.saveSelectedOptions(
          questionId: 'AT_GW_002',
          moduleCode: 'GW',
          optionIds: ['B'],
          questionNumber: 2,
        );

        var map = await repo.getQuestionProgressMap();
        expect(map['AT_GW_002']!.studyStatus, StudyStatus.inProgress);

        await repo.resetQuestionSelection(
          questionId: 'AT_GW_002',
          moduleCode: 'GW',
        );

        map = await repo.getQuestionProgressMap();
        expect(map['AT_GW_002']!.selectedOptionIds, isEmpty);
        expect(map['AT_GW_002']!.studyStatus, StudyStatus.viewed);
      },
    );

    test('5. Manually mark question as reviewed and unmark back', () async {
      await repo.saveSelectedOptions(
        questionId: 'AT_B_010',
        moduleCode: 'B',
        optionIds: ['A', 'D'],
        questionNumber: 10,
      );

      // Mark reviewed
      await repo.markQuestionReviewed(
        questionId: 'AT_B_010',
        moduleCode: 'B',
        reviewed: true,
      );

      var map = await repo.getQuestionProgressMap();
      expect(map['AT_B_010']!.studyStatus, StudyStatus.reviewed);
      expect(map['AT_B_010']!.isReviewed, isTrue);

      // Reset selection while reviewed does not clear reviewed status
      await repo.resetQuestionSelection(
        questionId: 'AT_B_010',
        moduleCode: 'B',
      );
      map = await repo.getQuestionProgressMap();
      expect(map['AT_B_010']!.studyStatus, StudyStatus.reviewed);

      // Unmark reviewed back to in_progress or viewed
      await repo.markQuestionReviewed(
        questionId: 'AT_B_010',
        moduleCode: 'B',
        reviewed: false,
      );
      map = await repo.getQuestionProgressMap();
      expect(map['AT_B_010']!.studyStatus, StudyStatus.viewed);
    });

    test(
      '6 & 7. Bookmark and unbookmark questions & prevent duplicates',
      () async {
        expect(await repo.isBookmarked('AT_GW_015'), isFalse);

        // Toggle ON
        final added = await repo.toggleBookmark(
          questionId: 'AT_GW_015',
          moduleCode: 'GW',
          questionNumber: 15,
          questionText: 'Overtaking rules',
        );
        expect(added, isTrue);
        expect(await repo.isBookmarked('AT_GW_015'), isTrue);

        final list = await repo.getBookmarks();
        expect(list.length, 1);
        expect(list.first.questionId, 'AT_GW_015');

        // Toggle again to remove
        final removed = await repo.toggleBookmark(
          questionId: 'AT_GW_015',
          moduleCode: 'GW',
        );
        expect(removed, isFalse);
        expect(await repo.isBookmarked('AT_GW_015'), isFalse);
        expect((await repo.getBookmarks()).isEmpty, isTrue);
      },
    );

    test('8 & 9. Progress count calculation and GW vs B separation', () async {
      // 2 viewed questions (GW)
      await repo.recordQuestionViewed(
        questionId: 'AT_GW_001',
        moduleCode: 'GW',
      );
      await repo.recordQuestionViewed(
        questionId: 'AT_GW_002',
        moduleCode: 'GW',
      );

      // 1 in_progress question (B)
      await repo.saveSelectedOptions(
        questionId: 'AT_B_001',
        moduleCode: 'B',
        optionIds: ['A'],
      );

      // 2 reviewed GW questions
      await repo.markQuestionReviewed(
        questionId: 'AT_GW_003',
        moduleCode: 'GW',
        reviewed: true,
      );
      await repo.markQuestionReviewed(
        questionId: 'AT_GW_004',
        moduleCode: 'GW',
        reviewed: true,
      );

      // 1 reviewed B question
      await repo.markQuestionReviewed(
        questionId: 'AT_B_002',
        moduleCode: 'B',
        reviewed: true,
      );

      // 2 bookmarks
      await repo.toggleBookmark(questionId: 'AT_GW_001', moduleCode: 'GW');
      await repo.toggleBookmark(questionId: 'AT_B_001', moduleCode: 'B');

      final summary = await repo.getLearningSummary(totalCatalogQuestions: 74);

      expect(summary.totalAvailableQuestions, 74);
      expect(summary.viewedCount, 2);
      expect(summary.inProgressCount, 1);
      expect(summary.reviewedCount, 3);
      expect(summary.gwReviewedCount, 2);
      expect(summary.bReviewedCount, 1);
      expect(summary.totalBookmarks, 2);
      expect(summary.recentlyViewedQuestions.isNotEmpty, isTrue);
    });

    test(
      '10. Resume learning checkpoint updates and retrieves correctly',
      () async {
        expect(await repo.getResumeLearningState(), isNull);

        await repo.updateResumeLearningState(
          moduleCode: 'GW',
          questionId: 'AT_GW_025',
          questionNumber: 25,
          questionText: 'Tram right of way',
        );

        final state = await repo.getResumeLearningState();
        expect(state, isNotNull);
        expect(state!.lastModuleCode, 'GW');
        expect(state.lastQuestionId, 'AT_GW_025');
        expect(state.lastQuestionNumber, 25);
        expect(state.lastQuestionText, 'Tram right of way');
      },
    );

    test('11 & 13. Cache isolation on clearCache resets all state', () async {
      await repo.recordQuestionViewed(
        questionId: 'AT_GW_001',
        moduleCode: 'GW',
      );
      await repo.toggleBookmark(questionId: 'AT_GW_001', moduleCode: 'GW');
      await repo.updateResumeLearningState(
        moduleCode: 'GW',
        questionId: 'AT_GW_001',
      );

      expect((await repo.getQuestionProgressMap()).isNotEmpty, isTrue);
      expect((await repo.getBookmarks()).isNotEmpty, isTrue);
      expect(await repo.getResumeLearningState(), isNotNull);

      repo.clearCache();

      expect((await repo.getQuestionProgressMap()).isEmpty, isTrue);
      expect((await repo.getBookmarks()).isEmpty, isTrue);
      expect(await repo.getResumeLearningState(), isNull);
    });
  });

  group('Phase 12: Riverpod Provider & State Synchronization Tests', () {
    test('QuestionStudySelectionNotifier synchronizes and toggles options', () {
      final container = ProviderContainer(
        overrides: [isDemoModeProvider.overrideWith(() => _TrueDemoNotifier())],
      );
      addTearDown(container.dispose);

      final notifier = container.read(questionStudySelectionProvider.notifier);

      // Initial state is empty
      expect(
        container.read(questionSelectedOptionsProvider('AT_GW_001')),
        isEmpty,
      );

      // Select option A (single mode)
      notifier.toggleOption(
        'AT_GW_001',
        'A',
        QuestionSelectionMode.single,
        moduleCode: 'GW',
        questionNumber: 1,
      );

      expect(container.read(questionSelectedOptionsProvider('AT_GW_001')), {
        'A',
      });

      // Select option B (single mode switches)
      notifier.toggleOption(
        'AT_GW_001',
        'B',
        QuestionSelectionMode.single,
        moduleCode: 'GW',
        questionNumber: 1,
      );

      expect(container.read(questionSelectedOptionsProvider('AT_GW_001')), {
        'B',
      });

      // Multiple selection mode allows multiple
      notifier.toggleOption(
        'AT_GW_002',
        'A',
        QuestionSelectionMode.multiple,
        moduleCode: 'GW',
        questionNumber: 2,
      );
      notifier.toggleOption(
        'AT_GW_002',
        'C',
        QuestionSelectionMode.multiple,
        moduleCode: 'GW',
        questionNumber: 2,
      );

      expect(container.read(questionSelectedOptionsProvider('AT_GW_002')), {
        'A',
        'C',
      });

      // Clear selections
      notifier.clearQuestion('AT_GW_002');
      expect(
        container.read(questionSelectedOptionsProvider('AT_GW_002')),
        isEmpty,
      );
    });

    test('Demo mode forces MockLearningProgressRepository', () {
      final container = ProviderContainer(
        overrides: [isDemoModeProvider.overrideWith(() => _TrueDemoNotifier())],
      );
      addTearDown(container.dispose);

      final repo = container.read(learningProgressRepositoryProvider);
      expect(repo, isA<MockLearningProgressRepository>());
    });
  });
}
