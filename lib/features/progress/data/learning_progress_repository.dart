import '../domain/question_bookmark.dart';
import '../domain/resume_learning_state.dart';
import '../domain/student_learning_summary.dart';
import '../domain/student_question_progress.dart';

/// Abstract repository defining contracts for student question progress,
/// question bookmarks, active resume learning state, and aggregate activity summaries.
abstract class LearningProgressRepository {
  /// Stream emitting a map of all question progress entries (questionId -> progress)
  /// for the current student.
  Stream<Map<String, StudentQuestionProgress>> watchQuestionProgressMap();

  /// Retrieves the current map of question progress entries for the current student.
  Future<Map<String, StudentQuestionProgress>> getQuestionProgressMap();

  /// Records that the student has viewed a specific question.
  /// If the document does not exist, it is created with status [StudyStatus.viewed].
  /// If it already exists, [lastViewedAt] and [updatedAt] are refreshed without
  /// demoting an [in_progress] or [reviewed] status.
  Future<void> recordQuestionViewed({
    required String questionId,
    required String moduleCode,
    String? topic,
    int? questionNumber,
    String languageCode = 'en',
  });

  /// Saves the student's selected answer options for a question.
  /// Sets [studyStatus] to [StudyStatus.inProgress] if options are not empty.
  Future<void> saveSelectedOptions({
    required String questionId,
    required String moduleCode,
    required List<String> optionIds,
    String? topic,
    int? questionNumber,
    String languageCode = 'en',
  });

  /// Manually marks (or unmarks) a question as [StudyStatus.reviewed].
  Future<void> markQuestionReviewed({
    required String questionId,
    required String moduleCode,
    required bool reviewed,
    String? topic,
    int? questionNumber,
    String languageCode = 'en',
  });

  /// Resets student's selected options for a question.
  Future<void> resetQuestionSelection({
    required String questionId,
    required String moduleCode,
    String? topic,
    int? questionNumber,
    String languageCode = 'en',
  });

  /// Stream emitting the list of all bookmarks saved by the student.
  Stream<List<QuestionBookmark>> watchBookmarks();

  /// Fetches all bookmarks for the current student.
  Future<List<QuestionBookmark>> getBookmarks();

  /// Toggles bookmark state for a question. Returns `true` if now bookmarked, `false` if removed.
  Future<bool> toggleBookmark({
    required String questionId,
    required String moduleCode,
    String? topic,
    int? questionNumber,
    String? questionText,
  });

  /// Checks if a question is currently bookmarked.
  Future<bool> isBookmarked(String questionId);

  /// Stream emitting the student's last active learning checkpoint.
  Stream<ResumeLearningState?> watchResumeLearningState();

  /// Fetches the student's current resume checkpoint.
  Future<ResumeLearningState?> getResumeLearningState();

  /// Updates the active resume learning checkpoint when student navigates to a question.
  Future<void> updateResumeLearningState({
    required String moduleCode,
    required String questionId,
    int? questionNumber,
    String? questionText,
  });

  /// Computes the aggregate activity summary for the progress screen.
  Future<StudentLearningSummary> getLearningSummary({
    int totalCatalogQuestions = 74,
  });

  /// Stream emitting real-time aggregate activity summary updates.
  Stream<StudentLearningSummary> watchLearningSummary({
    int totalCatalogQuestions = 74,
  });

  /// Invalidates and clears any local memory caches (e.g. on logout or user switch).
  void clearCache();
}
