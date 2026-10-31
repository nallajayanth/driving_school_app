import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/firestore_learning_progress_repository.dart';
import '../data/learning_progress_repository.dart';
import '../data/mock_learning_progress_repository.dart';
import '../data/mock_progress_repository.dart';
import '../data/progress_repository.dart';
import '../domain/learning_progress.dart';
import '../domain/question_bookmark.dart';
import '../domain/resume_learning_state.dart';
import '../domain/student_learning_summary.dart';
import '../domain/student_question_progress.dart';

// =============================================================================
// PHASE 12: LEARNING PROGRESS REPOSITORY PROVIDERS
// =============================================================================

/// Provider exposing the mock in-memory progress repository.
final mockLearningProgressRepositoryProvider =
    Provider<MockLearningProgressRepository>((ref) {
      return MockLearningProgressRepository();
    });

/// Provider exposing the Cloud Firestore progress repository.
final firestoreLearningProgressRepositoryProvider =
    Provider<FirestoreLearningProgressRepository>((ref) {
      return FirestoreLearningProgressRepository();
    });

/// Provider exposing the active [LearningProgressRepository] implementation.
///
/// SELECTION POLICY:
/// - Offline demo mode (`isDemoModeProvider == true`): returns [MockLearningProgressRepository].
/// - Authenticated Live Firebase mode (`Firebase.apps.isNotEmpty`): returns [FirestoreLearningProgressRepository].
/// - Fallback (unit tests with uninitialized Firebase): returns [MockLearningProgressRepository].
final learningProgressRepositoryProvider = Provider<LearningProgressRepository>(
  (ref) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    if (isDemoMode) {
      return ref.watch(mockLearningProgressRepositoryProvider);
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        return ref.watch(firestoreLearningProgressRepositoryProvider);
      }
    } catch (_) {
      // Firebase uninitialized in unit test environment
    }

    return ref.watch(mockLearningProgressRepositoryProvider);
  },
);

/// StreamProvider exposing the current student's map of question progress (questionId -> progress).
final studentProgressMapProvider =
    StreamProvider<Map<String, StudentQuestionProgress>>((ref) {
      final repo = ref.watch(learningProgressRepositoryProvider);
      return repo.watchQuestionProgressMap();
    });

/// Family provider returning progress for a specific question ID.
final singleQuestionProgressProvider =
    Provider.family<StudentQuestionProgress?, String>((ref, questionId) {
      final progressMap =
          ref.watch(studentProgressMapProvider).value ?? const {};
      return progressMap[questionId];
    });

/// StreamProvider exposing all bookmarked questions for the current student.
final bookmarksListProvider = StreamProvider<List<QuestionBookmark>>((ref) {
  final repo = ref.watch(learningProgressRepositoryProvider);
  return repo.watchBookmarks();
});

/// Family provider returning whether a specific question is currently bookmarked.
final isQuestionBookmarkedProvider = Provider.family<bool, String>((
  ref,
  questionId,
) {
  final bookmarks = ref.watch(bookmarksListProvider).value ?? const [];
  return bookmarks.any((b) => b.questionId == questionId);
});

/// StreamProvider exposing the active resume learning checkpoint.
final resumeLearningStateProvider = StreamProvider<ResumeLearningState?>((ref) {
  final repo = ref.watch(learningProgressRepositoryProvider);
  return repo.watchResumeLearningState();
});

/// StreamProvider exposing the aggregate learning summary for the progress screen.
final studentLearningSummaryProvider = StreamProvider<StudentLearningSummary>((
  ref,
) {
  final repo = ref.watch(learningProgressRepositoryProvider);
  return repo.watchLearningSummary();
});

// =============================================================================
// BACKWARD COMPATIBILITY: LEITNER / MOCK REPOSITORY PROVIDERS
// =============================================================================

/// Legacy Provider exposing [ProgressRepository] for mock Leitner box visualization.
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return MockProgressRepository();
});

/// Legacy AsyncNotifier managing mock Leitner progress state.
class ProgressNotifier extends AsyncNotifier<LearningProgress> {
  @override
  Future<LearningProgress> build() async {
    final repo = ref.watch(progressRepositoryProvider);
    return repo.getLearningProgress();
  }

  Future<void> refresh() async {
    final repo = ref.read(progressRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return repo.refreshProgress();
    });
  }
}

/// Legacy Provider exposing reactive mock Leitner progress.
final learningProgressProvider =
    AsyncNotifierProvider<ProgressNotifier, LearningProgress>(() {
      return ProgressNotifier();
    });
