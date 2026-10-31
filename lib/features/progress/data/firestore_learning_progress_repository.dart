import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../domain/question_bookmark.dart';
import '../domain/resume_learning_state.dart';
import '../domain/student_learning_summary.dart';
import '../domain/student_question_progress.dart';
import 'learning_progress_repository.dart';

/// Cloud Firestore implementation of [LearningProgressRepository].
///
/// Implements Phase 12 Student Learning Progress, Bookmarks & Activity Tracking
/// under the Firebase SPARK plan (direct client SDK, zero Cloud Functions / Run).
///
/// Security:
/// - Strictly relies on [firebase_auth.FirebaseAuth.instance.currentUser?.uid].
/// - Enforces paths:
///     - `users/{uid}/question_progress/{questionId}`
///     - `users/{uid}/bookmarks/{questionId}`
///     - `users/{uid}/learning_state/current`
/// - Never accesses private `question_answer_keys` or makes unverified grading claims.
class FirestoreLearningProgressRepository
    implements LearningProgressRepository {
  FirestoreLearningProgressRepository({
    firestore.FirebaseFirestore? firestoreInstance,
    firebase_auth.FirebaseAuth? authInstance,
  }) : _firestore = firestoreInstance ?? firestore.FirebaseFirestore.instance,
       _auth = authInstance ?? firebase_auth.FirebaseAuth.instance;

  final firestore.FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  /// In-memory cache of question progress documents.
  final Map<String, StudentQuestionProgress> _cachedProgress = {};

  /// In-memory cache of bookmarks.
  final Map<String, QuestionBookmark> _cachedBookmarks = {};

  /// In-memory cache of resume state.
  ResumeLearningState? _cachedResumeState;

  /// Cache of last viewed question IDs within this session to prevent repeated writes.
  final Set<String> _recentlyRecordedViewIds = {};

  String _requireCurrentUid() {
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) {
      throw StateError(
        'Authentication required: no active Firebase user found.',
      );
    }
    return user.uid;
  }

  firestore.CollectionReference<Map<String, dynamic>> _progressCol(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('question_progress');
  }

  firestore.CollectionReference<Map<String, dynamic>> _bookmarksCol(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).collection('bookmarks');
  }

  firestore.DocumentReference<Map<String, dynamic>> _resumeDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('learning_state')
        .doc('current');
  }

  @override
  Stream<Map<String, StudentQuestionProgress>> watchQuestionProgressMap() {
    final uid = _requireCurrentUid();

    return _progressCol(uid)
        .snapshots()
        .map<Map<String, StudentQuestionProgress>>((snapshot) {
          final map = <String, StudentQuestionProgress>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            map[doc.id] = StudentQuestionProgress.fromJson({
              ...data,
              'questionId': doc.id,
            });
          }
          _cachedProgress
            ..clear()
            ..addAll(map);
          return Map.unmodifiable(map);
        })
        .handleError((error) {
          debugPrint('Error listening to question_progress: $error');
          throw error;
        });
  }

  @override
  Future<Map<String, StudentQuestionProgress>> getQuestionProgressMap() async {
    final uid = _requireCurrentUid();
    final snapshot = await _progressCol(uid).get();
    final map = <String, StudentQuestionProgress>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      map[doc.id] = StudentQuestionProgress.fromJson({
        ...data,
        'questionId': doc.id,
      });
    }
    _cachedProgress
      ..clear()
      ..addAll(map);
    return Map.unmodifiable(map);
  }

  @override
  Future<void> recordQuestionViewed({
    required String questionId,
    required String moduleCode,
    String? topic,
    int? questionNumber,
    String languageCode = 'en',
  }) async {
    final uid = _requireCurrentUid();

    // Debounce duplicate writes during same view session
    if (_recentlyRecordedViewIds.contains(questionId)) {
      return;
    }
    _recentlyRecordedViewIds.add(questionId);

    final docRef = _progressCol(uid).doc(questionId);
    final existing = _cachedProgress[questionId];

    if (existing == null) {
      // Check Firestore doc to ensure we don't overwrite if it exists on server
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        final newProgress = StudentQuestionProgress(
          questionId: questionId,
          moduleCode: moduleCode,
          languageCode: languageCode,
          topic: topic,
          studyStatus: StudyStatus.viewed,
          firstViewedAt: DateTime.now(),
          lastViewedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          questionNumber: questionNumber,
        );
        _cachedProgress[questionId] = newProgress;
        await docRef.set(newProgress.toFirestoreMap(isFirstView: true));
        return;
      } else {
        final fromServer = StudentQuestionProgress.fromJson({
          ...docSnap.data()!,
          'questionId': questionId,
        });
        _cachedProgress[questionId] = fromServer;
      }
    }

    // Doc exists: refresh lastViewedAt and updatedAt without demoting status
    final current = _cachedProgress[questionId]!;
    _cachedProgress[questionId] = current.copyWith(
      lastViewedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      questionNumber: questionNumber ?? current.questionNumber,
    );

    await docRef.set({
      'questionId': questionId,
      'moduleCode': moduleCode,
      'languageCode': languageCode,
      'topic': ?topic,
      'questionNumber': ?questionNumber,
      'lastViewedAt': firestore.FieldValue.serverTimestamp(),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    }, firestore.SetOptions(merge: true));
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
    final uid = _requireCurrentUid();
    final docRef = _progressCol(uid).doc(questionId);
    final existing = _cachedProgress[questionId];

    final newStatus = optionIds.isEmpty
        ? (existing?.studyStatus == StudyStatus.reviewed
              ? StudyStatus.reviewed
              : StudyStatus.viewed)
        : (existing?.studyStatus == StudyStatus.reviewed
              ? StudyStatus.reviewed
              : StudyStatus.inProgress);

    final updated = StudentQuestionProgress(
      questionId: questionId,
      moduleCode: moduleCode,
      languageCode: languageCode,
      topic: topic ?? existing?.topic,
      selectedOptionIds: List.unmodifiable(optionIds),
      studyStatus: newStatus,
      firstViewedAt: existing?.firstViewedAt ?? DateTime.now(),
      lastViewedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      questionNumber: questionNumber ?? existing?.questionNumber,
    );
    _cachedProgress[questionId] = updated;

    await docRef.set({
      'questionId': questionId,
      'moduleCode': moduleCode,
      'languageCode': languageCode,
      if (topic != null || existing?.topic != null)
        'topic': topic ?? existing?.topic,
      'selectedOptionIds': optionIds,
      'studyStatus': newStatus.toValue(),
      if (questionNumber != null || existing?.questionNumber != null)
        'questionNumber': questionNumber ?? existing?.questionNumber,
      if (existing == null)
        'firstViewedAt': firestore.FieldValue.serverTimestamp(),
      'lastViewedAt': firestore.FieldValue.serverTimestamp(),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    }, firestore.SetOptions(merge: true));
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
    final uid = _requireCurrentUid();
    final docRef = _progressCol(uid).doc(questionId);
    final existing = _cachedProgress[questionId];

    final newStatus = reviewed
        ? StudyStatus.reviewed
        : ((existing?.selectedOptionIds.isNotEmpty ?? false)
              ? StudyStatus.inProgress
              : StudyStatus.viewed);

    final updated = StudentQuestionProgress(
      questionId: questionId,
      moduleCode: moduleCode,
      languageCode: languageCode,
      topic: topic ?? existing?.topic,
      selectedOptionIds: existing?.selectedOptionIds ?? const [],
      studyStatus: newStatus,
      firstViewedAt: existing?.firstViewedAt ?? DateTime.now(),
      lastViewedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      questionNumber: questionNumber ?? existing?.questionNumber,
    );
    _cachedProgress[questionId] = updated;

    await docRef.set({
      'questionId': questionId,
      'moduleCode': moduleCode,
      'languageCode': languageCode,
      if (topic != null || existing?.topic != null)
        'topic': topic ?? existing?.topic,
      'studyStatus': newStatus.toValue(),
      if (questionNumber != null || existing?.questionNumber != null)
        'questionNumber': questionNumber ?? existing?.questionNumber,
      'lastViewedAt': firestore.FieldValue.serverTimestamp(),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    }, firestore.SetOptions(merge: true));
  }

  @override
  Future<void> resetQuestionSelection({
    required String questionId,
    required String moduleCode,
    String? topic,
    int? questionNumber,
    String languageCode = 'en',
  }) async {
    final uid = _requireCurrentUid();
    final docRef = _progressCol(uid).doc(questionId);
    final existing = _cachedProgress[questionId];

    final newStatus = existing?.studyStatus == StudyStatus.reviewed
        ? StudyStatus.reviewed
        : StudyStatus.viewed;

    if (existing != null) {
      _cachedProgress[questionId] = existing.copyWith(
        selectedOptionIds: const [],
        studyStatus: newStatus,
        updatedAt: DateTime.now(),
      );
    }

    await docRef.set({
      'questionId': questionId,
      'moduleCode': moduleCode,
      'selectedOptionIds': <String>[],
      'studyStatus': newStatus.toValue(),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    }, firestore.SetOptions(merge: true));
  }

  @override
  Stream<List<QuestionBookmark>> watchBookmarks() {
    final uid = _requireCurrentUid();
    return _bookmarksCol(uid).snapshots().map<List<QuestionBookmark>>((
      snapshot,
    ) {
      final list = <QuestionBookmark>[];
      _cachedBookmarks.clear();
      for (final doc in snapshot.docs) {
        final b = QuestionBookmark.fromJson({
          ...doc.data(),
          'questionId': doc.id,
        });
        list.add(b);
        _cachedBookmarks[doc.id] = b;
      }
      return List.unmodifiable(list);
    });
  }

  @override
  Future<List<QuestionBookmark>> getBookmarks() async {
    final uid = _requireCurrentUid();
    final snapshot = await _bookmarksCol(uid).get();
    final list = <QuestionBookmark>[];
    _cachedBookmarks.clear();
    for (final doc in snapshot.docs) {
      final b = QuestionBookmark.fromJson({
        ...doc.data(),
        'questionId': doc.id,
      });
      list.add(b);
      _cachedBookmarks[doc.id] = b;
    }
    return List.unmodifiable(list);
  }

  @override
  Future<bool> toggleBookmark({
    required String questionId,
    required String moduleCode,
    String? topic,
    int? questionNumber,
    String? questionText,
  }) async {
    final uid = _requireCurrentUid();
    final docRef = _bookmarksCol(uid).doc(questionId);

    // Check if bookmarked in cache or remote
    final isCurrentlyBookmarked =
        _cachedBookmarks.containsKey(questionId) || (await docRef.get()).exists;

    if (isCurrentlyBookmarked) {
      _cachedBookmarks.remove(questionId);
      await docRef.delete();
      return false;
    } else {
      final bookmark = QuestionBookmark(
        questionId: questionId,
        moduleCode: moduleCode,
        topic: topic,
        createdAt: DateTime.now(),
        questionNumber: questionNumber,
        questionText: questionText,
      );
      _cachedBookmarks[questionId] = bookmark;
      await docRef.set(bookmark.toFirestoreMap());
      return true;
    }
  }

  @override
  Future<bool> isBookmarked(String questionId) async {
    if (_cachedBookmarks.containsKey(questionId)) {
      return true;
    }
    final uid = _requireCurrentUid();
    final doc = await _bookmarksCol(uid).doc(questionId).get();
    return doc.exists;
  }

  @override
  Stream<ResumeLearningState?> watchResumeLearningState() {
    final uid = _requireCurrentUid();
    return _resumeDoc(uid).snapshots().map<ResumeLearningState?>((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        _cachedResumeState = null;
        return null;
      }
      final state = ResumeLearningState.fromJson(snapshot.data()!);
      _cachedResumeState = state;
      return state;
    });
  }

  @override
  Future<ResumeLearningState?> getResumeLearningState() async {
    if (_cachedResumeState != null) {
      return _cachedResumeState;
    }
    final uid = _requireCurrentUid();
    final snapshot = await _resumeDoc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      _cachedResumeState = null;
      return null;
    }
    final state = ResumeLearningState.fromJson(snapshot.data()!);
    _cachedResumeState = state;
    return state;
  }

  @override
  Future<void> updateResumeLearningState({
    required String moduleCode,
    required String questionId,
    int? questionNumber,
    String? questionText,
  }) async {
    final uid = _requireCurrentUid();
    final state = ResumeLearningState(
      lastModuleCode: moduleCode,
      lastQuestionId: questionId,
      lastQuestionNumber: questionNumber,
      lastQuestionText: questionText,
      updatedAt: DateTime.now(),
    );
    _cachedResumeState = state;

    await _resumeDoc(
      uid,
    ).set(state.toFirestoreMap(), firestore.SetOptions(merge: true));
  }

  @override
  Future<StudentLearningSummary> getLearningSummary({
    int totalCatalogQuestions = 74,
  }) async {
    final progressMap = await getQuestionProgressMap();
    final bookmarksList = await getBookmarks();
    return _calculateSummary(
      progressMap: progressMap,
      bookmarksCount: bookmarksList.length,
      totalQuestions: totalCatalogQuestions,
    );
  }

  @override
  Stream<StudentLearningSummary> watchLearningSummary({
    int totalCatalogQuestions = 74,
  }) {
    return watchQuestionProgressMap().asyncMap<StudentLearningSummary>((
      progressMap,
    ) async {
      int bookmarksCount = _cachedBookmarks.length;
      try {
        final bookmarks = await getBookmarks();
        bookmarksCount = bookmarks.length;
      } catch (_) {}
      return _calculateSummary(
        progressMap: progressMap,
        bookmarksCount: bookmarksCount,
        totalQuestions: totalCatalogQuestions,
      );
    });
  }

  StudentLearningSummary _calculateSummary({
    required Map<String, StudentQuestionProgress> progressMap,
    required int bookmarksCount,
    required int totalQuestions,
  }) {
    int viewed = 0;
    int inProgress = 0;
    int reviewed = 0;
    int gwReviewed = 0;
    int bReviewed = 0;

    final sortedList = progressMap.values.toList()
      ..sort((a, b) {
        final aTime = a.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    for (final p in progressMap.values) {
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
      totalBookmarks: bookmarksCount,
      recentlyViewedQuestions: sortedList.take(5).toList(),
    );
  }

  @override
  void clearCache() {
    _cachedProgress.clear();
    _cachedBookmarks.clear();
    _cachedResumeState = null;
    _recentlyRecordedViewIds.clear();
  }
}
