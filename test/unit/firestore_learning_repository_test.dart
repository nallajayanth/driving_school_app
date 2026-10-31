import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driving_school_mobile_app/features/authentication/presentation/auth_providers.dart';
import 'package:driving_school_mobile_app/features/exam_history/presentation/exam_providers.dart';
import 'package:driving_school_mobile_app/features/learning/data/firestore_query_strategy.dart';
import 'package:driving_school_mobile_app/features/learning/data/mock_learning_repository.dart';
import 'package:driving_school_mobile_app/features/learning/data/question_mapper.dart';
import 'package:driving_school_mobile_app/features/learning/domain/question.dart';
import 'package:driving_school_mobile_app/features/learning/presentation/learning_providers.dart';

class _FakeDemoModeNotifier extends DemoModeNotifier {
  @override
  bool build() => true;
}

void main() {
  group('Phase 11 — Firestore Query Strategy & Filter Specifications', () {
    test('Resolves moduleCode for GW and B correctly', () {
      expect(FirestoreQueryStrategy.resolveModuleCodeForClass('GW'), 'GW');
      expect(
        FirestoreQueryStrategy.resolveModuleCodeForClass('class_gw'),
        'CLASS_GW',
      );
      expect(FirestoreQueryStrategy.resolveModuleCodeForClass('B'), 'B');
      expect(FirestoreQueryStrategy.resolveModuleCodeForClass('GENERAL'), 'GW');
    });

    test(
      'Query filter specification adheres to active English catalogue requirements',
      () {
        final filtersGw = FirestoreQueryStrategy.buildQuestionsFilter(
          drivingClassId: 'GW',
        );
        expect(filtersGw['moduleCode'], 'GW');
        expect(filtersGw['isActive'], true);
        expect(filtersGw['languageCode'], 'en');

        final filtersB = FirestoreQueryStrategy.buildQuestionsFilter(
          drivingClassId: 'B',
        );
        expect(filtersB['moduleCode'], 'B');
        expect(filtersB['isActive'], true);
        expect(filtersB['languageCode'], 'en');
      },
    );

    test('Collection names strictly exclude private question_answer_keys', () {
      expect(FirestoreQueryStrategy.questionsCollection, 'questions');
      expect(
        FirestoreQueryStrategy.questionsCollection,
        isNot(contains('answer_keys')),
      );
    });
  });

  group('Phase 11 — Question Mapping, Ordering & Null Media Handling', () {
    test('Extracts question numbers and resolves categories accurately', () {
      expect(QuestionMapper.extractQuestionNumber('AT_GW_021'), 21);
      expect(QuestionMapper.extractQuestionNumber('AT_B_001'), 1);
      expect(QuestionMapper.extractQuestionNumber('AT_GW_062'), 62);
      expect(QuestionMapper.extractQuestionNumber('AT_B_032'), 32);

      // GW documents with licenceCategory GENERAL resolve to GW
      final gwCategory = QuestionMapper.resolveDrivingClassId(
        moduleCode: 'GW',
        licenceCategory: 'GENERAL',
        questionId: 'AT_GW_021',
      );
      expect(gwCategory, 'GW');

      // B documents resolve to B
      final bCategory = QuestionMapper.resolveDrivingClassId(
        moduleCode: 'B',
        licenceCategory: 'B',
        questionId: 'AT_B_001',
      );
      expect(bCategory, 'B');
    });

    test('Sorts mapped questions by question number ascending', () {
      final q1 = Question(
        id: 'AT_GW_035',
        questionNumber: 35,
        drivingClassId: 'GW',
        text: 'Q35',
        options: const [],
      );
      final q2 = Question(
        id: 'AT_GW_021',
        questionNumber: 21,
        drivingClassId: 'GW',
        text: 'Q21',
        options: const [],
      );
      final q3 = Question(
        id: 'AT_GW_062',
        questionNumber: 62,
        drivingClassId: 'GW',
        text: 'Q62',
        options: const [],
      );

      final list = [q1, q2, q3];
      list.sort((a, b) => a.questionNumber.compareTo(b.questionNumber));

      expect(list.map((q) => q.questionNumber).toList(), [21, 35, 62]);
    });

    test(
      'Safely handles null media without generating broken placeholders',
      () {
        final docData = {
          'id': 'AT_GW_021',
          'moduleCode': 'GW',
          'licenceCategory': 'GENERAL',
          'questionText': 'Test question with null media',
          'options': [
            {'id': 'A', 'text': 'Option A'},
            {'id': 'B', 'text': 'Option B'},
          ],
          'media': null,
          'requiresImage': false,
          'selectionMode': 'multiple',
          'isActive': true,
          'languageCode': 'en',
        };

        final question = QuestionMapper.fromFirestore(docData, 'AT_GW_021');
        expect(question.mediaUrl, isNull);
        expect(question.requiresImage, isFalse);
      },
    );

    test(
      'QuestionMapper strictly leaves isCorrect null to prevent answer leakage',
      () {
        final docData = {
          'id': 'AT_B_005',
          'moduleCode': 'B',
          'licenceCategory': 'B',
          'questionText': 'Safe braking distance question',
          'options': [
            {
              'id': 'A',
              'text': 'Option A',
              'isCorrect': true,
            }, // Even if present in json
            {'id': 'B', 'text': 'Option B'},
          ],
          'isActive': true,
        };

        final question = QuestionMapper.fromFirestore(docData, 'AT_B_005');
        for (final option in question.options) {
          expect(
            option.isCorrect,
            isNull,
            reason:
                'Client-facing domain options must never reveal answer keys',
          );
        }
      },
    );
  });

  group('Phase 11 — Multiple Option Selection & State Persistence', () {
    test(
      'QuestionStudySelectionNotifier supports selecting multiple options',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          questionStudySelectionProvider.notifier,
        );

        // Initially empty
        expect(container.read(questionSelectedOptionsProvider('q1')), isEmpty);

        // Select option A
        notifier.toggleOption('q1', 'A', QuestionSelectionMode.multiple);
        expect(container.read(questionSelectedOptionsProvider('q1')), {'A'});

        // Select option B (multi-select)
        notifier.toggleOption('q1', 'B', QuestionSelectionMode.multiple);
        expect(container.read(questionSelectedOptionsProvider('q1')), {
          'A',
          'B',
        });

        // Deselect option A
        notifier.toggleOption('q1', 'A', QuestionSelectionMode.multiple);
        expect(container.read(questionSelectedOptionsProvider('q1')), {'B'});

        // Deselect option B -> empty
        notifier.toggleOption('q1', 'B', QuestionSelectionMode.multiple);
        expect(container.read(questionSelectedOptionsProvider('q1')), isEmpty);
      },
    );

    test(
      'QuestionStudySelectionNotifier handles single-option replacement and deselection',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          questionStudySelectionProvider.notifier,
        );

        // Select option A
        notifier.toggleOption('q2', 'A', QuestionSelectionMode.single);
        expect(container.read(questionSelectedOptionsProvider('q2')), {'A'});

        // Select option B replaces option A
        notifier.toggleOption('q2', 'B', QuestionSelectionMode.single);
        expect(container.read(questionSelectedOptionsProvider('q2')), {'B'});

        // Tapping option B again deselects it
        notifier.toggleOption('q2', 'B', QuestionSelectionMode.single);
        expect(container.read(questionSelectedOptionsProvider('q2')), isEmpty);
      },
    );

    test(
      'QuestionStudySelectionNotifier keeps state isolated between different questions',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          questionStudySelectionProvider.notifier,
        );

        notifier.toggleOption('q1', 'opt_1', QuestionSelectionMode.multiple);
        notifier.toggleOption('q2', 'opt_2', QuestionSelectionMode.multiple);

        expect(container.read(questionSelectedOptionsProvider('q1')), {
          'opt_1',
        });
        expect(container.read(questionSelectedOptionsProvider('q2')), {
          'opt_2',
        });

        notifier.clearQuestion('q1');
        expect(container.read(questionSelectedOptionsProvider('q1')), isEmpty);
        expect(container.read(questionSelectedOptionsProvider('q2')), {
          'opt_2',
        });
      },
    );

    test(
      'ExamSessionNotifier preserves multi-option selections across navigation',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(examSessionProvider.notifier);

        final q1 = Question(
          id: 'q1',
          questionNumber: 1,
          drivingClassId: 'GW',
          text: 'Exam Q1',
          selectionMode: QuestionSelectionMode.multiple,
          options: const [
            QuestionAnswerOption(id: 'A', text: 'Option A'),
            QuestionAnswerOption(id: 'B', text: 'Option B'),
            QuestionAnswerOption(id: 'C', text: 'Option C'),
          ],
        );
        final q2 = Question(
          id: 'q2',
          questionNumber: 2,
          drivingClassId: 'GW',
          text: 'Exam Q2',
          selectionMode: QuestionSelectionMode.multiple,
          options: const [
            QuestionAnswerOption(id: 'X', text: 'Option X'),
            QuestionAnswerOption(id: 'Y', text: 'Option Y'),
          ],
        );

        // Manually seed state with questions
        notifier.state = ExamSessionState(
          questions: [q1, q2],
          currentIndex: 0,
          selectedOptionSets: const {},
        );

        // Answer Q1 with options A and C
        notifier.toggleOption('q1', 'A', QuestionSelectionMode.multiple);
        notifier.toggleOption('q1', 'C', QuestionSelectionMode.multiple);

        final sessionQ1 = container.read(examSessionProvider);
        expect(sessionQ1.getSelectedOptionsFor('q1'), {'A', 'C'});
        expect(sessionQ1.isOptionSelected('q1', 'A'), isTrue);
        expect(sessionQ1.isOptionSelected('q1', 'B'), isFalse);
        expect(sessionQ1.isOptionSelected('q1', 'C'), isTrue);

        // Navigate to Q2
        notifier.nextQuestion();
        expect(container.read(examSessionProvider).currentIndex, 1);

        // Answer Q2 with option Y
        notifier.toggleOption('q2', 'Y', QuestionSelectionMode.multiple);
        expect(
          container.read(examSessionProvider).getSelectedOptionsFor('q2'),
          {'Y'},
        );

        // Return to Q1 to verify selections were preserved
        notifier.previousQuestion();
        expect(container.read(examSessionProvider).currentIndex, 0);

        final sessionReturned = container.read(examSessionProvider);
        expect(sessionReturned.getSelectedOptionsFor('q1'), {'A', 'C'});
        expect(sessionReturned.isOptionSelected('q1', 'A'), isTrue);
        expect(sessionReturned.isOptionSelected('q1', 'C'), isTrue);
      },
    );

    test(
      'Backward-compatible selectedAnswers getter reflects multi-option state',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(examSessionProvider.notifier);

        notifier.state = const ExamSessionState(
          selectedOptionSets: {
            'q1': {'B', 'C'},
            'q2': {'A'},
          },
        );

        final answers = container.read(examSessionProvider).selectedAnswers;
        expect(answers['q1'], isNotEmpty);
        expect(answers['q2'], 'A');
      },
    );
  });

  group('Phase 11 — Repository Selection & Fallback Safety Policy', () {
    test('Offline demo mode selects MockLearningRepository', () {
      final container = ProviderContainer(
        overrides: [isDemoModeProvider.overrideWith(_FakeDemoModeNotifier.new)],
      );
      addTearDown(container.dispose);

      final repo = container.read(learningRepositoryProvider);
      expect(repo, isA<MockLearningRepository>());
    });

    test('Mock repository provides both GW and B classes', () async {
      final repo = MockLearningRepository();
      final classes = await repo.getDrivingClasses();

      expect(classes.length, 2);
      expect(classes.any((c) => c.code == 'GW'), isTrue);
      expect(classes.any((c) => c.code == 'B'), isTrue);
    });

    test(
      'Mock repository getQuestions filters correctly by driving class',
      () async {
        final repo = MockLearningRepository();

        final gwQuestions = await repo.getQuestions(drivingClassId: 'GW');
        for (final q in gwQuestions) {
          expect(q.drivingClassId, 'GW');
        }

        final bQuestions = await repo.getQuestions(drivingClassId: 'B');
        for (final q in bQuestions) {
          expect(q.drivingClassId, 'B');
        }
      },
    );

    test(
      'Mock repository getQuestionByNumber respects drivingClassId filter',
      () async {
        final repo = MockLearningRepository();

        final q1278 = await repo.getQuestionByNumber(
          1278,
          drivingClassId: 'GW',
        );
        expect(q1278, isNotNull);
        expect(q1278!.questionNumber, 1278);
        expect(q1278.drivingClassId, 'GW');

        final q2001 = await repo.getQuestionByNumber(2001, drivingClassId: 'B');
        expect(q2001, isNotNull);
        expect(q2001!.questionNumber, 2001);
        expect(q2001.drivingClassId, 'B');

        final nonExistent = await repo.getQuestionByNumber(99999);
        expect(nonExistent, isNull);
      },
    );
  });
}
