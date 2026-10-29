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
    this.selectedAnswers = const {},
    this.selectedClasses = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.completedAttempt,
    this.errorMessage,
  });

  final List<Question> questions;
  final int currentIndex;
  final Map<String, String> selectedAnswers; // questionId -> optionId
  final List<String> selectedClasses;
  final bool isLoading;
  final bool isSubmitting;
  final ExamAttempt? completedAttempt;
  final String? errorMessage;

  Question? get currentQuestion =>
      (questions.isNotEmpty &&
          currentIndex >= 0 &&
          currentIndex < questions.length)
      ? questions[currentIndex]
      : null;

  int get totalQuestions => questions.length;
  int get answeredCount => selectedAnswers.length;
  bool get isFirstQuestion => currentIndex == 0;
  bool get isLastQuestion =>
      questions.isNotEmpty && currentIndex == questions.length - 1;
  bool get isFinished => completedAttempt != null;

  ExamSessionState copyWith({
    List<Question>? questions,
    int? currentIndex,
    Map<String, String>? selectedAnswers,
    List<String>? selectedClasses,
    bool? isLoading,
    bool? isSubmitting,
    ExamAttempt? completedAttempt,
    String? errorMessage,
  }) {
    return ExamSessionState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
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
        selectedAnswers: const {},
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

  /// Selects or switches an answer choice for a question.
  void selectAnswer(String questionId, String optionId) {
    if (state.isSubmitting || state.isFinished) return;

    final updatedAnswers = Map<String, String>.from(state.selectedAnswers);
    updatedAnswers[questionId] = optionId;

    state = state.copyWith(selectedAnswers: updatedAnswers);
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
        selectedAnswers: state.selectedAnswers,
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
