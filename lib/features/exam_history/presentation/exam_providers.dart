import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../learning/domain/driving_class.dart';
import '../../learning/domain/question.dart';
import '../data/exam_repository.dart';
import '../data/mock_exam_repository.dart';
import '../domain/exam_attempt.dart';
import '../domain/mock_assessment_service.dart';

/// Provider exposing the active [ExamRepository] implementation.
/// Defaults to [MockExamRepository] during UI prototyping.
final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return MockExamRepository();
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

/// State of an active mock examination session.
class ExamSessionState {
  const ExamSessionState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedOptionSets = const {},
    this.selectedClasses = const [],
    this.isLoading = false,
    this.isSubmitting = false,
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
  final ExamAttempt? completedAttempt;
  final String? errorMessage;

  /// Backward-compatible view returning a `Map<String, String>` of selected answers.
  /// For single-select or questions with selected options, returns the first selected option ID.
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
      completedAttempt: completedAttempt ?? this.completedAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier managing active mock examination session flow.
class ExamSessionNotifier extends Notifier<ExamSessionState> {
  @override
  ExamSessionState build() {
    return const ExamSessionState();
  }

  /// Initializes a new mock examination session with the chosen driving classes.
  Future<void> startSession(List<String> selectedClasses) async {
    state = ExamSessionState(isLoading: true, selectedClasses: selectedClasses);

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
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load examination questions: $e',
      );
    }
  }

  /// Toggles an option selection for a question according to its [QuestionSelectionMode].
  ///
  /// - [QuestionSelectionMode.multiple]: toggles the option (adds if unselected, removes if already selected).
  /// - [QuestionSelectionMode.single]: replaces with new option, or deselects if tapped again.
  /// - [QuestionSelectionMode.unknown]: defaults to single replacement for legacy mock questions.
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

  /// Submits the mock examination, calculates scores, and saves to repository history.
  Future<ExamAttempt?> submitExam() async {
    if (state.isSubmitting || state.questions.isEmpty) return null;

    state = state.copyWith(isSubmitting: true);

    try {
      final assessmentService = ref.read(mockAssessmentServiceProvider);
      final attempt = assessmentService.evaluateMockExam(
        questions: state.questions,
        selectedAnswers: state.selectedOptionSets,
        selectedClasses: state.selectedClasses,
      );

      final repo = ref.read(examRepositoryProvider);
      await repo.saveExamAttempt(attempt);

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
}

final examSessionProvider =
    NotifierProvider<ExamSessionNotifier, ExamSessionState>(() {
      return ExamSessionNotifier();
    });
