import 'package:flutter_test/flutter_test.dart';
import 'package:driving_school_mobile_app/features/authentication/data/mock_auth_repository.dart';
import 'package:driving_school_mobile_app/features/learning/data/mock_learning_repository.dart';
import 'package:driving_school_mobile_app/features/exam_history/data/mock_exam_repository.dart';
import 'package:driving_school_mobile_app/features/exam_history/domain/exam_attempt.dart';
import 'package:driving_school_mobile_app/features/exam_history/domain/mock_assessment_service.dart';
import 'package:driving_school_mobile_app/features/progress/data/mock_progress_repository.dart';

void main() {
  group('Mock Repositories Tests', () {
    test(
      'MockAuthRepository loads user, updates language, and logs out',
      () async {
        final repo = MockAuthRepository();

        final user = await repo.getCurrentUser();
        expect(user, isNotNull);
        expect(user!.name, 'Krishan Patel');
        expect(user.preferredLanguage, 'DE');

        await repo.updateLanguage('EN');
        final updatedUser = await repo.getCurrentUser();
        expect(updatedUser!.preferredLanguage, 'EN');

        await repo.logout();
        final loggedOutUser = await repo.getCurrentUser();
        expect(loggedOutUser, isNull);
      },
    );

    test(
      'MockLearningRepository fetches classes, units and question by number',
      () async {
        final repo = MockLearningRepository();

        final classes = await repo.getDrivingClasses();
        expect(classes.length, 2);
        expect(classes.map((c) => c.code), containsAll(['GW', 'B']));

        final allUnits = await repo.getLearningUnits();
        expect(allUnits.length, 5);
        expect(allUnits.first.title, 'General rules of the road, tunnel');
        expect(allUnits.first.totalQuestions, 92);
        expect(allUnits.first.box0Count, 90);
        expect(allUnits.first.box1Count, 2);

        final gwUnits = await repo.getLearningUnits(drivingClassId: 'GW');
        expect(gwUnits.length, 3);

        // Question search by number
        final question1278 = await repo.getQuestionByNumber(1278);
        expect(question1278, isNotNull);
        expect(question1278!.questionNumber, 1278);

        final unknownQuestion = await repo.getQuestionByNumber(99999);
        expect(unknownQuestion, isNull);

        // Search by text query
        final searchResults = await repo.searchLearningUnits('Tunnel');
        expect(searchResults.length, 1);
        expect(searchResults.first.title, contains('tunnel'));
      },
    );

    test(
      'MockExamRepository calculates question totals accurately and fetches history',
      () async {
        final repo = MockExamRepository();

        final classes = await repo.getEligibleExamClasses();
        expect(classes.length, 2);

        // Calculation tests based on visible class specifications
        expect(repo.calculateTotalExamQuestions([], classes), 0);
        expect(repo.calculateTotalExamQuestions(['GW'], classes), 40);
        expect(repo.calculateTotalExamQuestions(['B'], classes), 40);
        expect(repo.calculateTotalExamQuestions(['GW', 'B'], classes), 80);

        final history = await repo.getExamHistory();
        expect(history.length, 1);
        expect(history.first.selectedClasses, ['GW']);
        expect(history.first.scorePercentage, 0.0);
        expect(history.first.isPassed, isFalse);

        final count = await repo.getTotalExamsCount();
        expect(count, 1);

        // Fetch questions for GW
        final gwQuestions = await repo.getExamQuestions(
          selectedClassCodes: ['GW'],
        );
        expect(gwQuestions.isNotEmpty, isTrue);
        expect(gwQuestions.every((q) => q.drivingClassId == 'GW'), isTrue);

        // Fetch questions for B
        final bQuestions = await repo.getExamQuestions(
          selectedClassCodes: ['B'],
        );
        expect(bQuestions.isNotEmpty, isTrue);
        expect(bQuestions.every((q) => q.drivingClassId == 'B'), isTrue);

        // Save new attempt
        final newAttempt = ExamAttempt(
          id: 'new_attempt_1',
          dateTime: DateTime.now(),
          selectedClasses: const ['GW', 'B'],
          totalQuestions: 10,
          pointsScored: 8,
          scorePercentage: 80.0,
          isPassed: true,
          statusLabel: 'Bestanden (Demo)',
        );
        await repo.saveExamAttempt(newAttempt);

        final updatedHistory = await repo.getExamHistory();
        expect(updatedHistory.length, 2);
        expect(updatedHistory.first.id, 'new_attempt_1');
        expect(await repo.getTotalExamsCount(), 2);
      },
    );

    test(
      'MockProgressRepository returns verified progress metrics matching screenshots',
      () async {
        final repo = MockProgressRepository();

        final progress = await repo.getLearningProgress();
        expect(progress.totalQuestionsAnswered, 6);
        expect(progress.currentLearningLevel, 'Beginner');
        expect(progress.box0QuestionsCount, 1426);
        expect(progress.subject1QuestionsCount, 2);
        expect(progress.subject2QuestionsCount, 0);
        expect(progress.subject3QuestionsCount, 0);
        expect(progress.fach0Value, 60.0);
        expect(progress.fach1Value, 40.0);
        expect(progress.topicsProgress.length, 3);
      },
    );

    test(
      'MockAssessmentService calculates demo score and assigns demo status',
      () async {
        final repo = MockExamRepository();
        final questions = await repo.getExamQuestions(
          selectedClassCodes: ['GW'],
        );
        const service = MockAssessmentService();

        // All wrong / unanswered
        final failedAttempt = service.evaluateMockExam(
          questions: questions,
          selectedAnswers: {},
          selectedClasses: ['GW'],
        );
        expect(failedAttempt.pointsScored, 0);
        expect(failedAttempt.scorePercentage, 0.0);
        expect(failedAttempt.isPassed, isFalse);
        expect(failedAttempt.statusLabel, contains('Demo'));

        // All correct
        final allCorrectAnswers = <String, String>{};
        for (final q in questions) {
          final correctOption = q.options.firstWhere(
            (o) => o.isCorrect == true,
          );
          allCorrectAnswers[q.id] = correctOption.id;
        }

        final passedAttempt = service.evaluateMockExam(
          questions: questions,
          selectedAnswers: allCorrectAnswers,
          selectedClasses: ['GW'],
        );
        expect(passedAttempt.pointsScored, questions.length);
        expect(passedAttempt.scorePercentage, 100.0);
        expect(passedAttempt.isPassed, isTrue);
        expect(passedAttempt.statusLabel, contains('Demo'));
      },
    );
  });
}
