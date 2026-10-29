import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/learning_repository.dart';
import '../data/mock_learning_repository.dart';
import '../domain/driving_class.dart';
import '../domain/learning_unit.dart';
import '../domain/question.dart';

/// Provider exposing the active [LearningRepository] implementation.
/// Defaults to [MockLearningRepository] during UI prototyping.
final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return MockLearningRepository();
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

/// FutureProvider looking up a single question by its public question number (e.g. 1278).
final questionLookupProvider = FutureProvider.family<Question?, int>((
  ref,
  questionNumber,
) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getQuestionByNumber(questionNumber);
});
