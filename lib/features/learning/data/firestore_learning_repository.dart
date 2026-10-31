import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../domain/driving_class.dart';
import '../domain/learning_unit.dart';
import '../domain/question.dart';
import 'firestore_query_strategy.dart';
import 'learning_repository.dart';
import 'question_mapper.dart';

/// Firebase Cloud Firestore implementation of [LearningRepository].
///
/// Communicates with the live Austrian driving theory question bank in
/// Cloud Firestore (`questions` collection).
///
/// CRITICAL SECURITY ENFORCEMENT:
/// Queries only the public `questions` collection. The private
/// `question_answer_keys` collection is never accessed or queried by the client.
class FirestoreLearningRepository implements LearningRepository {
  FirestoreLearningRepository({firestore.FirebaseFirestore? firestoreInstance})
    : _firestore = firestoreInstance ?? firestore.FirebaseFirestore.instance;

  final firestore.FirebaseFirestore _firestore;

  /// In-memory cache by module code (e.g. "GW", "B") to prevent redundant
  /// network requests while navigating within the app.
  final Map<String, List<Question>> _cachedQuestionsByClass = {};

  /// In-memory individual question cache by document ID.
  final Map<String, Question> _cachedQuestionsById = {};

  @override
  Future<List<DrivingClass>> getDrivingClasses() async {
    // Austrian license classes supported in the catalog
    return const [
      DrivingClass(
        id: 'class_gw',
        code: 'GW',
        name: 'GW',
        preliminaryExamQuestionsCount: 42,
        description: 'Grundwissen (General Knowledge)',
      ),
      DrivingClass(
        id: 'class_b',
        code: 'B',
        name: 'B',
        preliminaryExamQuestionsCount: 32,
        description: 'Klasse B (Passenger Car)',
      ),
    ];
  }

  @override
  Future<List<Question>> getQuestions({
    String? drivingClassId,
    bool forceRefresh = false,
  }) async {
    final targetModule = FirestoreQueryStrategy.resolveModuleCodeForClass(
      drivingClassId ?? 'GW',
    );

    if (!forceRefresh && _cachedQuestionsByClass.containsKey(targetModule)) {
      return List.unmodifiable(_cachedQuestionsByClass[targetModule]!);
    }

    String projectId = 'unknown';
    try {
      projectId = _firestore.app.options.projectId;
    } catch (_) {}

    String authUserId = 'none';
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        authUserId =
            'UID(${user.uid.length >= 6 ? user.uid.substring(0, 6) : user.uid}...)';
      }
    } catch (_) {}

    debugPrint(
      '[FirestoreLearningRepository] Project: $projectId | User: $authUserId | '
      'Querying module $targetModule (language: ${FirestoreQueryStrategy.defaultLanguageCode}, active: true)',
    );

    // Query active questions in English for the target module
    final snapshot = await _firestore
        .collection(FirestoreQueryStrategy.questionsCollection)
        .where('moduleCode', isEqualTo: targetModule)
        .where('isActive', isEqualTo: true)
        .where(
          'languageCode',
          isEqualTo: FirestoreQueryStrategy.defaultLanguageCode,
        )
        .get();

    final questions =
        snapshot.docs
            .map((doc) => QuestionMapper.fromFirestore(doc.data(), doc.id))
            .toList(growable: true)
          ..sort((a, b) => a.questionNumber.compareTo(b.questionNumber));

    debugPrint(
      '[FirestoreLearningRepository] Project: $projectId | '
      'Successfully retrieved ${questions.length} documents for module $targetModule',
    );

    _cachedQuestionsByClass[targetModule] = questions;

    for (final q in questions) {
      _cachedQuestionsById[q.id] = q;
    }

    return List.unmodifiable(questions);
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    if (_cachedQuestionsById.containsKey(id)) {
      return _cachedQuestionsById[id];
    }

    final doc = await _firestore
        .collection(FirestoreQueryStrategy.questionsCollection)
        .doc(id)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final question = QuestionMapper.fromFirestore(doc.data()!, doc.id);
    _cachedQuestionsById[question.id] = question;
    return question;
  }

  @override
  Future<Question?> getQuestionByNumber(
    int questionNumber, {
    String? drivingClassId,
  }) async {
    // 1. Check in-memory cache first
    if (drivingClassId != null &&
        _cachedQuestionsByClass.containsKey(drivingClassId)) {
      final match = _cachedQuestionsByClass[drivingClassId]!
          .where((q) => q.questionNumber == questionNumber)
          .firstOrNull;
      if (match != null) return match;
    }

    for (final cachedList in _cachedQuestionsByClass.values) {
      for (final q in cachedList) {
        if (q.questionNumber == questionNumber) {
          if (drivingClassId == null ||
              q.drivingClassId.toUpperCase() == drivingClassId.toUpperCase()) {
            return q;
          }
        }
      }
    }

    // 2. Try direct document lookups using standard Austrian document ID conventions
    final numPadded = questionNumber.toString().padLeft(3, '0');
    if (drivingClassId != null) {
      final directCandidate = await getQuestionById(
        'AT_${drivingClassId.toUpperCase()}_$numPadded',
      );
      if (directCandidate != null &&
          directCandidate.questionNumber == questionNumber) {
        return directCandidate;
      }
    }

    final gwCandidate = await getQuestionById('AT_GW_$numPadded');
    if (gwCandidate != null && gwCandidate.questionNumber == questionNumber) {
      return gwCandidate;
    }

    final bCandidate = await getQuestionById('AT_B_$numPadded');
    if (bCandidate != null && bCandidate.questionNumber == questionNumber) {
      return bCandidate;
    }

    // 3. Fallback: load full catalogs if not yet cached and search
    if (drivingClassId != null) {
      final scopedQuestions = await getQuestions(
        drivingClassId: drivingClassId,
      );
      final found = scopedQuestions
          .where((q) => q.questionNumber == questionNumber)
          .firstOrNull;
      if (found != null) return found;
    }

    final gwQuestions = await getQuestions(drivingClassId: 'GW');
    final foundGw = gwQuestions
        .where((q) => q.questionNumber == questionNumber)
        .firstOrNull;
    if (foundGw != null) return foundGw;

    final bQuestions = await getQuestions(drivingClassId: 'B');
    return bQuestions
        .where((q) => q.questionNumber == questionNumber)
        .firstOrNull;
  }

  @override
  Future<List<LearningUnit>> getLearningUnits({String? drivingClassId}) async {
    final targetClass = drivingClassId ?? 'GW';
    final questions = await getQuestions(drivingClassId: targetClass);

    if (questions.isEmpty) {
      return const [];
    }

    // Group questions dynamically by topic to form verified learning units
    final Map<String, List<Question>> topicGroups = {};
    for (final q in questions) {
      final topicKey = q.topic ?? 'general';
      topicGroups.putIfAbsent(topicKey, () => []).add(q);
    }

    final List<LearningUnit> units = [];
    int unitIndex = 1;

    for (final entry in topicGroups.entries) {
      final topicKey = entry.key;
      final topicQuestions = entry.value;
      final formattedTitle = _formatTopicTitle(topicKey);

      units.add(
        LearningUnit(
          id: 'unit_${targetClass.toLowerCase()}_$unitIndex',
          drivingClassId: targetClass,
          categoryName: formattedTitle,
          title: formattedTitle,
          totalQuestions: topicQuestions.length,
          examReadyCount: 0,
          box0Count: topicQuestions.length,
          box1Count: 0,
          box2Count: 0,
          box3Count: 0,
          readinessPercentage: 0.0,
          phaseLabel: 'Start-up phase',
          phaseIcon: '🚦',
        ),
      );
      unitIndex++;
    }

    return List.unmodifiable(units);
  }

  @override
  Future<List<LearningUnit>> searchLearningUnits(String query) async {
    final trimmed = query.trim().toLowerCase();
    final allGwUnits = await getLearningUnits(drivingClassId: 'GW');
    final allBUnits = await getLearningUnits(drivingClassId: 'B');
    final combined = [...allGwUnits, ...allBUnits];

    if (trimmed.isEmpty) return combined;

    return combined
        .where(
          (u) =>
              u.title.toLowerCase().contains(trimmed) ||
              u.categoryName.toLowerCase().contains(trimmed),
        )
        .toList();
  }

  /// Clears in-memory caches.
  void clearCache() {
    _cachedQuestionsByClass.clear();
    _cachedQuestionsById.clear();
  }

  static String _formatTopicTitle(String topicKey) {
    return topicKey
        .split('_')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
