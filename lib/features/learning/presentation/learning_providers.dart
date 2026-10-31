import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/firestore_learning_repository.dart';
import '../data/learning_repository.dart';
import '../data/mock_learning_repository.dart';
import '../domain/driving_class.dart';
import '../domain/learning_unit.dart';
import '../domain/question.dart';

/// Provider exposing the mock learning repository instance.
final mockLearningRepositoryProvider = Provider<MockLearningRepository>((ref) {
  return MockLearningRepository();
});

/// Provider exposing the Firestore learning repository instance.
final firestoreLearningRepositoryProvider =
    Provider<FirestoreLearningRepository>((ref) {
      return FirestoreLearningRepository();
    });

/// Provider exposing the active [LearningRepository] implementation.
///
/// SELECTION POLICY:
/// - Offline demo mode enabled (`isDemoModeProvider == true`): returns [MockLearningRepository].
/// - Authenticated / Live environment (Firebase initialized): returns [FirestoreLearningRepository].
/// - Uninitialized test environment: returns [MockLearningRepository].
///
/// IMPORTANT:
/// When an authenticated Firestore request fails, this provider DOES NOT silently
/// fall back to mock data. Errors are propagated to the UI to present a clear
/// retry dialog.
final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  if (isDemoMode) {
    return ref.watch(mockLearningRepositoryProvider);
  }

  try {
    if (Firebase.apps.isNotEmpty) {
      return ref.watch(firestoreLearningRepositoryProvider);
    }
  } catch (_) {
    // Firebase uninitialized in test runner environment
  }

  return ref.watch(mockLearningRepositoryProvider);
});

/// FutureProvider querying all supported driving license classes.
final drivingClassesProvider = FutureProvider<List<DrivingClass>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getDrivingClasses();
});

/// Provider for tracking currently selected driving class in the learning module (defaults to 'GW').
final selectedLearningClassProvider =
    NotifierProvider<SelectedLearningClassNotifier, String>(() {
      return SelectedLearningClassNotifier();
    });

class SelectedLearningClassNotifier extends Notifier<String> {
  @override
  String build() => 'GW';

  void selectClass(String code) {
    state = code;
  }
}

/// FutureProvider querying learning units, optionally filtered by driving class code (e.g. "GW").
final learningUnitsProvider =
    FutureProvider.family<List<LearningUnit>, String?>((ref, classCode) async {
      final repo = ref.watch(learningRepositoryProvider);
      return repo.getLearningUnits(drivingClassId: classCode);
    });

/// FutureProvider querying all questions for a specific driving class code (e.g. "GW" -> 42 questions, "B" -> 32 questions).
final classQuestionsProvider = FutureProvider.family<List<Question>, String>((
  ref,
  classCode,
) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getQuestions(drivingClassId: classCode);
});

/// FutureProvider looking up a single question by its public question number (e.g. 1278).
final questionLookupProvider = FutureProvider.family<Question?, int>((
  ref,
  questionNumber,
) async {
  final repo = ref.watch(learningRepositoryProvider);
  final currentClass = ref.watch(selectedLearningClassProvider);
  return repo.getQuestionByNumber(questionNumber, drivingClassId: currentClass);
});

/// Interactive study selection notifier managing option selections for questions.
///
/// Stores `Map<String, Set<String>>` (questionId -> Set of selected option IDs).
class QuestionStudySelectionNotifier
    extends Notifier<Map<String, Set<String>>> {
  @override
  Map<String, Set<String>> build() => const {};

  void toggleOption(
    String questionId,
    String optionId,
    QuestionSelectionMode mode,
  ) {
    final updated = Map<String, Set<String>>.from(
      state.map((k, v) => MapEntry(k, Set<String>.from(v))),
    );
    final current = updated[questionId] ?? <String>{};

    if (mode == QuestionSelectionMode.multiple) {
      if (current.contains(optionId)) {
        current.remove(optionId);
      } else {
        current.add(optionId);
      }
      if (current.isEmpty) {
        updated.remove(questionId);
      } else {
        updated[questionId] = current;
      }
    } else if (mode == QuestionSelectionMode.single) {
      if (current.contains(optionId)) {
        updated.remove(questionId);
      } else {
        updated[questionId] = {optionId};
      }
    }

    state = updated;
  }

  void clearQuestion(String questionId) {
    final updated = Map<String, Set<String>>.from(state);
    updated.remove(questionId);
    state = updated;
  }
}

final questionStudySelectionProvider =
    NotifierProvider<QuestionStudySelectionNotifier, Map<String, Set<String>>>(
      () {
        return QuestionStudySelectionNotifier();
      },
    );

/// Family provider returning the selected option IDs for a specific question.
final questionSelectedOptionsProvider = Provider.family<Set<String>, String>((
  ref,
  questionId,
) {
  final all = ref.watch(questionStudySelectionProvider);
  return all[questionId] ?? const <String>{};
});
