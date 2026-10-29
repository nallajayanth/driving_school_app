import '../../learning/domain/question.dart';
import 'exam_attempt.dart';

/// Pure domain service that calculates mock examination scores and attempts.
///
/// IMPORTANT:
/// Official passing thresholds (e.g. 80% vs 90%), question point weighting,
/// negative scoring, and bonus question rules have not yet been confirmed by
/// the Powerdrive backend API.
///
/// This service provides a deterministic, clearly documented demonstration-only
/// evaluation so the UI and results screens can be demonstrated safely.
class MockAssessmentService {
  const MockAssessmentService();

  /// Evaluates user responses against question answer options.
  /// Produces a domain [ExamAttempt] tagged with a demonstration status label.
  ExamAttempt evaluateMockExam({
    required List<Question> questions,
    required Map<String, String> selectedAnswers, // questionId -> optionId
    required List<String> selectedClasses,
  }) {
    int pointsScored = 0;

    for (final question in questions) {
      final selectedOptionId = selectedAnswers[question.id];
      if (selectedOptionId != null) {
        final option = question.options
            .where((opt) => opt.id == selectedOptionId)
            .firstOrNull;
        if (option?.isCorrect == true) {
          pointsScored++;
        }
      }
    }

    final totalQuestions = questions.length;
    final scorePercentage = totalQuestions > 0
        ? (pointsScored / totalQuestions) * 100.0
        : 0.0;

    // Demonstration-only threshold: 80% passing rule marked as demo
    final isPassed = scorePercentage >= 80.0;
    final statusLabel = isPassed
        ? 'Bestanden (Demo)'
        : 'Nicht bestanden (Demo)';

    return ExamAttempt(
      id: 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      dateTime: DateTime.now(),
      selectedClasses: selectedClasses,
      totalQuestions: totalQuestions,
      pointsScored: pointsScored,
      scorePercentage: scorePercentage,
      isPassed: isPassed,
      statusLabel: statusLabel,
    );
  }
}
