import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../learning/domain/driving_class.dart';
import '../../learning/domain/question.dart';
import '../../learning/presentation/learning_providers.dart';
import '../data/backend_exam_repository.dart';
import '../data/exam_repository.dart';
import '../data/mock_exam_repository.dart';
import '../domain/exam_attempt.dart';
import '../domain/mock_assessment_service.dart';

/// Provider exposing the mock exam repository instance.
final mockExamRepositoryProvider = Provider<MockExamRepository>((ref) {
  return MockExamRepository();
});

/// Provider exposing the backend exam repository instance.
final backendExamRepositoryProvider = Provider<BackendExamRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final learningRepo = ref.watch(backendLearningRepositoryProvider);
  return BackendExamRepository(
    apiClient: client,
    learningRepository: learningRepo,
  );
});

/// Provider exposing the active [ExamRepository] implementation.
/// Defaults to [MockExamRepository] during demo mode or uninitialized environments.
final examRepositoryProvider = Provider<ExamRepository>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  if (isDemoMode) {
    return ref.watch(mockExamRepositoryProvider);
  }

  try {
    if (Firebase.apps.isNotEmpty) {
      return ref.watch(backendExamRepositoryProvider);
    }
  } catch (_) {
    // Firebase uninitialized in test runner environment
  }

  return ref.watch(mockExamRepositoryProvider);
});

/// FutureProvider querying eligible classes for the preliminary check.
final eligibleExamClassesProvider = FutureProvider<List<DrivingClass>>((
  ref,
) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.getEligibleExamClasses();
});

/// FutureProvider querying preliminary exam attempts history.
final examHistoryProvider = FutureProvider<List<ExamAttempt>>((ref) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.getExamHistory();
});

/// FutureProvider querying the total number of taken preliminary exams.
final totalExamsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.getTotalExamsCount();
});

/// Provider for the mock assessment scoring service.
final mockAssessmentServiceProvider = Provider<MockAssessmentService>((ref) {
  return const MockAssessmentService();
});

/// State of the preliminary check class selection screen.
class PreliminarySelectionState {
  const PreliminarySelectionState({
    this.selectedClassCodes = const {},
    this.totalQuestions = 0,
    this.isStarting = false,
  });

  final Set<String> selectedClassCodes;
  final int totalQuestions;
  final bool isStarting;

  bool get canStart =>
      selectedClassCodes.isNotEmpty && totalQuestions > 0 && !isStarting;

  PreliminarySelectionState copyWith({
    Set<String>? selectedClassCodes,
    int? totalQuestions,
    bool? isStarting,
  }) {
    return PreliminarySelectionState(
      selectedClassCodes: selectedClassCodes ?? this.selectedClassCodes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      isStarting: isStarting ?? this.isStarting,
    );
  }
}

/// Notifier managing class selection and dynamic question count calculation.
class PreliminarySelectionNotifier extends Notifier<PreliminarySelectionState> {
  @override
  PreliminarySelectionState build() {
    return const PreliminarySelectionState();
  }

  void toggleClass(String classCode, List<DrivingClass> availableClasses) {
    final updated = Set<String>.from(state.selectedClassCodes);
    if (updated.contains(classCode)) {
      updated.remove(classCode);
    } else {
      updated.add(classCode);
    }

    final repo = ref.read(examRepositoryProvider);
    final calculatedTotal = repo.calculateTotalExamQuestions(
      updated.toList(),
      availableClasses,
    );

    state = state.copyWith(
      selectedClassCodes: updated,
      totalQuestions: calculatedTotal,
    );
  }

  void clearSelection() {
    state = const PreliminarySelectionState();
  }
}

final preliminarySelectionProvider =
    NotifierProvider<PreliminarySelectionNotifier, PreliminarySelectionState>(
      () {
        return PreliminarySelectionNotifier();
      },
    );

/// State of an active examination session.
class ExamSessionState {
  const ExamSessionState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedOptionSets = const {},
    this.selectedClasses = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.activeSubmissionId,
    this.completedAttempt,
    this.errorMessage,
  });

  final List<Question> questions;
  final int currentIndex;

  /// Multi-selection map: questionId -> Set of selected option IDs.
  final Map<String, Set<String>> selectedOptionSets;

  final List<String> selectedClasses;
  final bool isLoading;
  final bool isSubmitting;

  /// Unique idempotent submission identifier generated once per logical exam submission.
  /// Preserved across retries to prevent duplicate server attempts.
  final String? activeSubmissionId;

  final ExamAttempt? completedAttempt;
  final String? errorMessage;

  /// Backward-compatible view returning a `Map<String, String>` of selected answers.
  Map<String, String> get selectedAnswers => selectedOptionSets.map(
    (k, v) => MapEntry(k, v.isNotEmpty ? v.first : ''),
  );

  /// Returns the set of selected option IDs for a given question.
  Set<String> getSelectedOptionsFor(String questionId) =>
      selectedOptionSets[questionId] ?? const <String>{};

  /// Checks if a specific option is selected for a given question.
  bool isOptionSelected(String questionId, String optionId) =>
      selectedOptionSets[questionId]?.contains(optionId) ?? false;

  Question? get currentQuestion =>
      (questions.isNotEmpty &&
          currentIndex >= 0 &&
          currentIndex < questions.length)
      ? questions[currentIndex]
      : null;

  int get totalQuestions => questions.length;
  int get answeredCount =>
      selectedOptionSets.values.where((s) => s.isNotEmpty).length;
  bool get isFirstQuestion => currentIndex == 0;
  bool get isLastQuestion =>
      questions.isNotEmpty && currentIndex == questions.length - 1;
  bool get isFinished => completedAttempt != null;

  ExamSessionState copyWith({
    List<Question>? questions,
    int? currentIndex,
    Map<String, Set<String>>? selectedOptionSets,
    Map<String, String>? selectedAnswers,
    List<String>? selectedClasses,
    bool? isLoading,
    bool? isSubmitting,
    String? activeSubmissionId,
    ExamAttempt? completedAttempt,
    String? errorMessage,
  }) {
    Map<String, Set<String>>? resolvedSets = selectedOptionSets;
    if (resolvedSets == null && selectedAnswers != null) {
      resolvedSets = selectedAnswers.map((k, v) => MapEntry(k, {v}));
    }

    return ExamSessionState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionSets: resolvedSets ?? this.selectedOptionSets,
      selectedClasses: selectedClasses ?? this.selectedClasses,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      activeSubmissionId: activeSubmissionId ?? this.activeSubmissionId,
      completedAttempt: completedAttempt ?? this.completedAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier managing active examination session flow.
class ExamSessionNotifier extends Notifier<ExamSessionState> {
  @override
  ExamSessionState build() {
    return const ExamSessionState();
  }

  /// Initializes a new examination session with the chosen driving classes.
  Future<void> startSession(List<String> selectedClasses) async {
    state = ExamSessionState(
      isLoading: true,
      selectedClasses: selectedClasses,
      activeSubmissionId: null,
    );

    try {
      final repo = ref.read(examRepositoryProvider);
      final questions = await repo.getExamQuestions(
        selectedClassCodes: selectedClasses,
      );

      state = ExamSessionState(
        questions: questions,
        currentIndex: 0,
        selectedOptionSets: const {},
        selectedClasses: selectedClasses,
        isLoading: false,
        activeSubmissionId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load examination questions: $e',
      );
    }
  }

  /// Toggles an option selection for a question according to its [QuestionSelectionMode].
  void toggleOption(
    String questionId,
    String optionId, [
    QuestionSelectionMode? explicitMode,
  ]) {
    if (state.isSubmitting || state.isFinished) return;

    final question = state.questions
        .where((q) => q.id == questionId)
        .firstOrNull;
    final mode =
        explicitMode ??
        question?.selectionMode ??
        QuestionSelectionMode.unknown;

    final updated = Map<String, Set<String>>.from(
      state.selectedOptionSets.map((k, v) => MapEntry(k, Set<String>.from(v))),
    );

    final currentSet = updated[questionId] ?? <String>{};

    if (mode == QuestionSelectionMode.multiple) {
      if (currentSet.contains(optionId)) {
        currentSet.remove(optionId);
      } else {
        currentSet.add(optionId);
      }
      if (currentSet.isEmpty) {
        updated.remove(questionId);
      } else {
        updated[questionId] = currentSet;
      }
    } else {
      // Single selection mode or legacy mock unknown mode
      if (currentSet.contains(optionId)) {
        updated.remove(questionId);
      } else {
        updated[questionId] = {optionId};
      }
    }

    state = state.copyWith(selectedOptionSets: updated);
  }

  /// Selects or switches an answer choice for a question (backward-compatible).
  void selectAnswer(String questionId, String optionId) {
    toggleOption(questionId, optionId);
  }

  /// Advances to the next question within valid bounds.
  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// Returns to the previous question within valid bounds.
  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  /// Jumps to a specific question index.
  void goToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  /// Submits the examination, calculates scores, and saves to repository history.
  ///
  /// Guarantees:
  /// - Repeated taps during active submission return immediately without creating duplicate attempts.
  /// - A single unique submissionId is generated per exam attempt and reused across retries.
  /// - Logged-out users are prevented from submitting live exams.
  Future<ExamAttempt?> submitExam() async {
    // Prevent concurrent repeated button taps or submitting empty exams
    if (state.isSubmitting || state.questions.isEmpty) return null;
    if (state.isFinished) return state.completedAttempt;

    final repo = ref.read(examRepositoryProvider);

    // Authentication Guard: ensure student is signed in for live backend submissions
    if (repo is BackendExamRepository) {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'You must be signed in to submit an examination.',
        );
        return null;
      }
    }

    // Reuse existing submissionId if retrying, or generate a fresh unique one
    final submissionId = state.activeSubmissionId ?? _generateSubmissionId();

    state = state.copyWith(
      isSubmitting: true,
      activeSubmissionId: submissionId,
      errorMessage: null,
    );

    try {
      ExamAttempt attempt;

      if (repo is BackendExamRepository) {
        // Authenticated live mode: submit to backend evaluation engine
        final primaryModule = state.selectedClasses.isNotEmpty
            ? state.selectedClasses.first
            : 'GW';

        if (state.selectedClasses.length <= 1) {
          attempt = await repo.submitExamAnswers(
            moduleCode: primaryModule,
            answers: state.selectedOptionSets,
            submissionId: submissionId,
          );
        } else {
          // Multi-module session: submit for each module with module-specific suffix
          int totalQuestions = 0;
          int totalScored = 0;
          bool allPassed = true;

          for (final code in state.selectedClasses) {
            final moduleQuestions = state.questions
                .where((q) => q.drivingClassId.toUpperCase() == code.toUpperCase())
                .map((q) => q.id)
                .toSet();

            final moduleAnswers = <String, Set<String>>{};
            for (final entry in state.selectedOptionSets.entries) {
              if (moduleQuestions.contains(entry.key)) {
                moduleAnswers[entry.key] = entry.value;
              }
            }

            if (moduleAnswers.isNotEmpty) {
              final moduleAttempt = await repo.submitExamAnswers(
                moduleCode: code,
                answers: moduleAnswers,
                submissionId: '${submissionId}_$code',
              );
              totalQuestions += moduleAttempt.totalQuestions;
              totalScored += moduleAttempt.pointsScored;
              if (!moduleAttempt.isPassed) allPassed = false;
            }
          }

          final pct = totalQuestions > 0
              ? (totalScored / totalQuestions) * 100.0
              : 0.0;

          attempt = ExamAttempt(
            id: submissionId,
            dateTime: DateTime.now(),
            selectedClasses: state.selectedClasses,
            totalQuestions: totalQuestions,
            pointsScored: totalScored,
            scorePercentage: pct,
            isPassed: allPassed,
            statusLabel: allPassed ? 'Passed' : 'Failed',
          );
        }
      } else {
        // Demo mode or test runner mock assessment
        final assessmentService = ref.read(mockAssessmentServiceProvider);
        attempt = assessmentService.evaluateMockExam(
          questions: state.questions,
          selectedAnswers: state.selectedOptionSets,
          selectedClasses: state.selectedClasses,
        );
        await repo.saveExamAttempt(attempt);
      }

      // Invalidate history providers to refresh audit records
      ref.invalidate(examHistoryProvider);
      ref.invalidate(totalExamsCountProvider);

      state = state.copyWith(isSubmitting: false, completedAttempt: attempt);

      return attempt;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit examination: $e',
      );
      return null;
    }
  }

  /// Resets the current exam session.
  void resetSession() {
    state = const ExamSessionState();
  }

  String _generateSubmissionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'sub_${timestamp}_$randomPart';
  }
}

final examSessionProvider =
    NotifierProvider<ExamSessionNotifier, ExamSessionState>(() {
      return ExamSessionNotifier();
    });
