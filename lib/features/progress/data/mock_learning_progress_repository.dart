import 'dart:async';
import '../domain/question_bookmark.dart';
import '../domain/resume_learning_state.dart';
import '../domain/student_learning_summary.dart';
import '../domain/student_question_progress.dart';
import 'learning_progress_repository.dart';

/// In-memory mock implementation of [LearningProgressRepository].
///
/// Used for:
/// - Offline demo mode (`isDemoModeProvider == true`)
/// - Unit and widget tests where Firebase is uninitialized
///
/// CRITICAL:
/// This repository operates exclusively in-memory and NEVER connects to or writes
/// any data to Cloud Firestore.
class MockLearningProgressRepository implements LearningProgressRepository {
  MockLearningProgressRepository({
    Map<String, StudentQuestionProgress>? initialProgress,
    List<QuestionBookmark>? initialBookmarks,
    ResumeLearningState? initialResumeState,
  }) {
    if (initialProgress != null) {
      _progressMap.addAll(initialProgress);
    }
    if (initialBookmarks != null) {
      for (final b in initialBookmarks) {
        _bookmarksMap[b.questionId] = b;
      }
    }
    _resumeState = initialResumeState;
  }

  final Map<String, StudentQuestionProgress> _progressMap = {};
  final Map<String, QuestionBookmark> _bookmarksMap = {};
  ResumeLearningState? _resumeState;

  final _progressStreamController =
      StreamController<Map<String, StudentQuestionProgress>>.broadcast();
  final _bookmarksStreamController =
      StreamController<List<QuestionBookmark>>.broadcast();
  final _resumeStreamController =
      StreamController<ResumeLearningState?>.broadcast();

  void _emitProgress() {
    _progressStreamController.add(Map.unmodifiable(_progressMap));
  }

  void _emitBookmarks() {
    _bookmarksStreamController.add(
      List.unmodifiable(_bookmarksMap.values.toList()),
    );
  }

  void _emitResume() {
    _resumeStreamController.add(_resumeState);
  }

  @override
  Stream<Map<String, StudentQuestionProgress>>
  watchQuestionProgressMap() async* {
    yield Map.unmodifiable(_progressMap);
    yield* _progressStreamController.stream;
  }

  @override
  Future<Map<String, StudentQuestionProgress>> getQuestionProgressMap() async {
    return Map.unmodifiable(_progressMap);
  }

  @override
  Future<void> recordQuestionViewed({
    required String questionId,
    required String moduleCode,
    String? topic,
    int? questionNumber,
    String languageCode = 'en',
  }) async {
    final existing = _progressMap[questionId];
    final now = DateTime.now();

    if (existing == null) {
      _progressMap[questionId] = StudentQuestionProgress(
        questionId: questionId,
        moduleCode: moduleCode,
        languageCode: languageCode,
        topic: topic,
        studyStatus: StudyStatus.viewed,
        firstViewedAt: now,
        lastViewedAt: now,
        updatedAt: now,
        questionNumber: questionNumber,
      );
    } else {
      _progressMap[questionId] = existing.copyWith(
        lastViewedAt: now,
        updatedAt: now,
        questionNumber: questionNumber ?? existing.questionNumber,
      );
    }
    _emitProgress();
  }

  @override
  Future<void> saveSelectedOptions({
    required String questionId,
    required String moduleCode,
    required List<String> optionIds,
    String? topic,
    int? questionNumber,
    String languageCode = 'en',
  }) async {
    final existing = _progressMap[questionId];
    final now = DateTime.now();
    final newStatus = optionIds.isEmpty
        ? (existing?.studyStatus == StudyStatus.reviewed
              ? StudyStatus.reviewed
              : StudyStatus.viewed)
        : (existing?.studyStatus == StudyStatus.reviewed
              ? StudyStatus.reviewed
              : StudyStatus.inProgress);

    _progressMap[questionId] = StudentQuestionProgress(
      questionId: questionId,
      moduleCode: moduleCode,
      languageCode: languageCode,
      topic: topic ?? existing?.topic,
      selectedOptionIds: List.unmodifiable(optionIds),
      studyStatus: newStatus,
      firstViewedAt: existing?.firstViewedAt ?? now,
      lastViewedAt: now,
      updatedAt: now,
      questionNumber: questionNumber ?? existing?.questionNumber,
    );
    _emitProgress();
  }

  @override
  Future<void> markQuestionReviewed({
    required String questionId,
    required String moduleCode,
    required bool reviewed,
    String? topic,
    int? questionNumber,
    String languageCode = 'en',
  }) async {
    final existing = _progressMap[questionId];
    final now = DateTime.now();
    final newStatus = reviewed
        ? StudyStatus.reviewed
        : ((existing?.selectedOptionIds.isNotEmpty ?? false)
              ? StudyStatus.inProgress
              : StudyStatus.viewed);

    _progressMap[questionId] = StudentQuestionProgress(
      questionId: questionId,
      moduleCode: moduleCode,
      languageCode: languageCode,
      topic: topic ?? existing?.topic,
      selectedOptionIds: existing?.selectedOptionIds ?? const [],
      studyStatus: newStatus,
      firstViewedAt: existing?.firstViewedAt ?? now,
      lastViewedAt: now,
      updatedAt: now,
      questionNumber: questionNumber ?? existing?.questionNumber,
    );
    _emitProgress();
  }

  @override
  Future<void> resetQuestionSelection({
    required String questionId,
    required String moduleCode,
    String? topic,
    int? questionNumber,
    String languageCode = 'en',
  }) async {
    final existing = _progressMap[questionId];
    final now = DateTime.now();

    if (existing != null) {
      _progressMap[questionId] = existing.copyWith(
        selectedOptionIds: const [],
        studyStatus: existing.studyStatus == StudyStatus.reviewed
            ? StudyStatus.reviewed
            : StudyStatus.viewed,
        updatedAt: now,
      );
      _emitProgress();
    }
  }

  @override
  Stream<List<QuestionBookmark>> watchBookmarks() async* {
    yield List.unmodifiable(_bookmarksMap.values.toList());
    yield* _bookmarksStreamController.stream;
  }

  @override
  Future<List<QuestionBookmark>> getBookmarks() async {
    return List.unmodifiable(_bookmarksMap.values.toList());
  }

  @override
  Future<bool> toggleBookmark({
    required String questionId,
    required String moduleCode,
    String? topic,
    int? questionNumber,
    String? questionText,
  }) async {
    if (_bookmarksMap.containsKey(questionId)) {
      _bookmarksMap.remove(questionId);
      _emitBookmarks();
      return false;
    } else {
      _bookmarksMap[questionId] = QuestionBookmark(
        questionId: questionId,
        moduleCode: moduleCode,
        topic: topic,
        createdAt: DateTime.now(),
        questionNumber: questionNumber,
        questionText: questionText,
      );
      _emitBookmarks();
      return true;
    }
  }

  @override
  Future<bool> isBookmarked(String questionId) async {
    return _bookmarksMap.containsKey(questionId);
  }

  @override
  Stream<ResumeLearningState?> watchResumeLearningState() async* {
    yield _resumeState;
    yield* _resumeStreamController.stream;
  }

  @override
  Future<ResumeLearningState?> getResumeLearningState() async {
    return _resumeState;
  }

  @override
  Future<void> updateResumeLearningState({
    required String moduleCode,
    required String questionId,
    int? questionNumber,
    String? questionText,
  }) async {
    _resumeState = ResumeLearningState(
      lastModuleCode: moduleCode,
      lastQuestionId: questionId,
      lastQuestionNumber: questionNumber,
      lastQuestionText: questionText,
      updatedAt: DateTime.now(),
    );
    _emitResume();
  }

  @override
  Future<StudentLearningSummary> getLearningSummary({
    int totalCatalogQuestions = 74,
  }) async {
    return _calculateSummary(totalCatalogQuestions);
  }

  @override
  Stream<StudentLearningSummary> watchLearningSummary({
    int totalCatalogQuestions = 74,
  }) {
    return watchQuestionProgressMap().map((_) {
      return _calculateSummary(totalCatalogQuestions);
    });
  }

  StudentLearningSummary _calculateSummary(int totalQuestions) {
    int viewed = 0;
    int inProgress = 0;
    int reviewed = 0;
    int gwReviewed = 0;
    int bReviewed = 0;

    final sortedList = _progressMap.values.toList()
      ..sort((a, b) {
        final aTime = a.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    for (final p in _progressMap.values) {
      if (p.studyStatus == StudyStatus.viewed) viewed++;
      if (p.studyStatus == StudyStatus.inProgress) inProgress++;
      if (p.studyStatus == StudyStatus.reviewed) {
        reviewed++;
        if (p.moduleCode == 'GW') {
          gwReviewed++;
        } else if (p.moduleCode == 'B') {
          bReviewed++;
        }
      }
    }

    return StudentLearningSummary(
      totalAvailableQuestions: totalQuestions,
      viewedCount: viewed,
      inProgressCount: inProgress,
      reviewedCount: reviewed,
      gwReviewedCount: gwReviewed,
      bReviewedCount: bReviewed,
      totalBookmarks: _bookmarksMap.length,
      recentlyViewedQuestions: sortedList.take(5).toList(),
    );
  }

  @override
  void clearCache() {
    _progressMap.clear();
    _bookmarksMap.clear();
    _resumeState = null;
    _emitProgress();
    _emitBookmarks();
    _emitResume();
  }
}
