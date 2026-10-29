import '../domain/learning_progress.dart';
import 'progress_repository.dart';

/// Explicitly labeled mock implementation of [ProgressRepository] for development and UI prototyping.
/// Pre-populated with the exact numbers visible in the dashboard and progress screenshots:
/// - 1426 questions in Box 0
/// - 2 questions in Subject 1
/// - 0 questions in Subject 2
/// - 0 questions in Subject 3
/// - 6 total questions answered
/// - Level: Beginner 🐣
class MockProgressRepository implements ProgressRepository {
  MockProgressRepository({LearningProgress? initialData})
    : _progress =
          initialData ??
          const LearningProgress(
            totalQuestionsAnswered: 6,
            currentLearningLevel: 'Beginner',
            currentLearningLevelIcon: '🐣',
            box0QuestionsCount: 1426,
            subject1QuestionsCount: 2,
            subject2QuestionsCount: 0,
            subject3QuestionsCount: 0,
            fach0Value: 60.0,
            fach1Value: 40.0,
            fach2Value: 0.0,
            fach3Value: 0.0,
            topicsProgress: [
              TopicProgress(
                topicName: 'General rules of the road, tunnel',
                totalQuestions: 92,
                answeredQuestions: 2,
                examReadyQuestions: 0,
                progressPercentage: 1.0,
              ),
              TopicProgress(
                topicName: 'Special traffic areas',
                totalQuestions: 56,
                answeredQuestions: 0,
                examReadyQuestions: 0,
                progressPercentage: 0.0,
              ),
              TopicProgress(
                topicName: 'Moving through traffic',
                totalQuestions: 46,
                answeredQuestions: 0,
                examReadyQuestions: 0,
                progressPercentage: 0.0,
              ),
            ],
          );

  final LearningProgress _progress;

  @override
  Future<LearningProgress> getLearningProgress() async {
    return _progress;
  }

  @override
  Future<LearningProgress> refreshProgress() async {
    return _progress;
  }
}
