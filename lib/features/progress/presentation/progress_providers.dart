import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_progress_repository.dart';
import '../data/progress_repository.dart';
import '../domain/learning_progress.dart';

/// Provider exposing the active [ProgressRepository] implementation.
/// Defaults to [MockProgressRepository] during UI prototyping.
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return MockProgressRepository();
});

/// AsyncNotifier managing the user's aggregate learning progress state.
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

/// Provider exposing reactive learning progress.
final learningProgressProvider =
    AsyncNotifierProvider<ProgressNotifier, LearningProgress>(() {
      return ProgressNotifier();
    });
