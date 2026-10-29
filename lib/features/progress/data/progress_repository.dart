import '../domain/learning_progress.dart';

/// Abstract contract for retrieving learning progress, level indicators, and Leitner box metrics.
/// Production implementation will connect to the verified backend API.
abstract class ProgressRepository {
  /// Fetches the user's aggregate learning progress.
  Future<LearningProgress> getLearningProgress();

  /// Forces a fresh recalculation or reload of learning progress from the data source.
  Future<LearningProgress> refreshProgress();
}
