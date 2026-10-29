import 'package:flutter_test/flutter_test.dart';
import 'package:driving_school_mobile_app/features/authentication/domain/user.dart';
import 'package:driving_school_mobile_app/features/learning/domain/driving_class.dart';
import 'package:driving_school_mobile_app/features/learning/domain/learning_unit.dart';
import 'package:driving_school_mobile_app/features/learning/domain/question.dart';
import 'package:driving_school_mobile_app/features/learning/domain/question_progress.dart';
import 'package:driving_school_mobile_app/features/exam_history/domain/exam_attempt.dart';
import 'package:driving_school_mobile_app/features/progress/domain/learning_progress.dart';

void main() {
  group('Domain Models Serialization Tests', () {
    test('User serialization round-trip', () {
      const user = User(
        id: 'usr_1',
        name: 'Krishan Patel',
        email: 'krishan@example.com',
        preferredLanguage: 'DE',
      );

      final json = user.toJson();
      final fromJson = User.fromJson(json);

      expect(fromJson, equals(user));
      expect(fromJson.name, 'Krishan Patel');
      expect(fromJson.preferredLanguage, 'DE');
    });

    test('DrivingClass serialization round-trip', () {
      const drivingClass = DrivingClass(
        id: 'class_gw',
        code: 'GW',
        name: 'GW',
        preliminaryExamQuestionsCount: 40,
        description: 'Grundwissen',
      );

      final json = drivingClass.toJson();
      final fromJson = DrivingClass.fromJson(json);

      expect(fromJson, equals(drivingClass));
      expect(fromJson.code, 'GW');
      expect(fromJson.preliminaryExamQuestionsCount, 40);
    });

    test('LearningUnit serialization round-trip', () {
      const unit = LearningUnit(
        id: 'u_1',
        drivingClassId: 'GW',
        categoryName: 'General traffic regulations, tunnels',
        title: 'General rules of the road, tunnel',
        totalQuestions: 92,
        examReadyCount: 0,
        box0Count: 90,
        box1Count: 2,
        box2Count: 0,
        box3Count: 0,
        readinessPercentage: 1.0,
        phaseLabel: 'Start-up phase',
        phaseIcon: '🚦',
      );

      final json = unit.toJson();
      final fromJson = LearningUnit.fromJson(json);

      expect(fromJson, equals(unit));
      expect(fromJson.totalQuestions, 92);
      expect(fromJson.box0Count, 90);
      expect(fromJson.box1Count, 2);
      expect(fromJson.readinessPercentage, 1.0);
    });

    test('Question and QuestionAnswerOption serialization round-trip', () {
      const question = Question(
        id: 'q_1278',
        questionNumber: 1278,
        drivingClassId: 'GW',
        text: 'What is the speed limit?',
        options: [
          QuestionAnswerOption(id: 'opt_1', text: '80 km/h', isCorrect: false),
          QuestionAnswerOption(id: 'opt_2', text: '100 km/h', isCorrect: true),
        ],
      );

      final json = question.toJson();
      final fromJson = Question.fromJson(json);

      expect(fromJson, equals(question));
      expect(fromJson.questionNumber, 1278);
      expect(fromJson.options.length, 2);
      expect(fromJson.options.first.text, '80 km/h');
    });

    test('QuestionProgress serialization round-trip', () {
      final now = DateTime.now();
      final progress = QuestionProgress(
        questionId: 'q_1278',
        questionNumber: 1278,
        boxLevel: 1,
        timesAnswered: 2,
        lastAnsweredAt: now,
      );

      final json = progress.toJson();
      final fromJson = QuestionProgress.fromJson(json);

      expect(fromJson.questionNumber, 1278);
      expect(fromJson.boxLevel, 1);
      expect(fromJson.timesAnswered, 2);
    });

    test('ExamAttempt serialization and formatted score test', () {
      final now = DateTime.now();
      final attempt = ExamAttempt(
        id: 'atm_1',
        dateTime: now,
        selectedClasses: const ['GW'],
        totalQuestions: 40,
        pointsScored: 0,
        scorePercentage: 0.0,
        isPassed: false,
        statusLabel: 'Nicht bestanden',
      );

      final json = attempt.toJson();
      final fromJson = ExamAttempt.fromJson(json);

      expect(fromJson.selectedClasses, ['GW']);
      expect(fromJson.formattedScore, '0% (0/40)');
      expect(fromJson.isPassed, isFalse);
    });

    test('LearningProgress serialization preserving box distinction', () {
      const progress = LearningProgress(
        totalQuestionsAnswered: 6,
        currentLearningLevel: 'Beginner',
        currentLearningLevelIcon: '🐣',
        box0QuestionsCount: 1426,
        subject1QuestionsCount: 2,
        subject2QuestionsCount: 0,
        subject3QuestionsCount: 0,
        fach0Value: 60.0,
        fach1Value: 40.0,
        topicsProgress: [
          TopicProgress(
            topicName: 'General rules of the road, tunnel',
            totalQuestions: 92,
            answeredQuestions: 2,
            examReadyQuestions: 0,
            progressPercentage: 1.0,
          ),
        ],
      );

      final json = progress.toJson();
      final fromJson = LearningProgress.fromJson(json);

      expect(fromJson.totalQuestionsAnswered, 6);
      expect(fromJson.currentLearningLevel, 'Beginner');
      expect(fromJson.box0QuestionsCount, 1426);
      expect(fromJson.subject1QuestionsCount, 2);
      expect(fromJson.subject2QuestionsCount, 0);
      expect(fromJson.subject3QuestionsCount, 0);
      expect(fromJson.topicsProgress.length, 1);
    });
  });
}
