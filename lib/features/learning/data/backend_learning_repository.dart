import 'package:flutter/foundation.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/driving_class.dart';
import '../domain/learning_unit.dart';
import '../domain/question.dart';
import '../domain/question_check_result.dart';
import 'firestore_query_strategy.dart';
import 'learning_repository.dart';
import 'models/firestore_question_dto.dart';
import 'question_mapper.dart';

/// Node.js Backend implementation of [LearningRepository].
///
/// Communicates with the Express backend REST APIs:
/// - `GET /api/questions?moduleCode=GW|B&limit=50&cursor=...`
/// - `GET /api/questions/:questionId`
///
/// CRITICAL SECURITY ENFORCEMENT:
/// Public questions served by the backend do not contain correct answers or answer keys.
class BackendLearningRepository implements LearningRepository {
  BackendLearningRepository({required this.apiClient});

  final ApiClient apiClient;

  /// In-memory cache by module code (e.g. "GW", "B") to optimize navigation.
  final Map<String, List<Question>> _cachedQuestionsByClass = {};

  /// In-memory individual question cache by document ID.
  final Map<String, Question> _cachedQuestionsById = {};

  @override
  Future<List<DrivingClass>> getDrivingClasses() async {
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

    debugPrint(
      '[BackendLearningRepository] Fetching questions for module $targetModule with pagination',
    );

    final List<Question> accumulatedQuestions = [];
    final Set<String> seenIds = {};
    String? currentCursor;
    bool hasMore = true;
    const int pageSize = 50; // Maximum allowed by backend Zod schema

    while (hasMore) {
      final queryParams = <String, String>{
        'moduleCode': targetModule,
        'languageCode': 'en',
        'limit': pageSize.toString(),
      };

      if (currentCursor != null && currentCursor.isNotEmpty) {
        queryParams['cursor'] = currentCursor;
      }

      final response = await apiClient.get(
        ApiConfig.questionsUrl,
        queryParams: queryParams,
      );

      final rawList = response['data'] as List<dynamic>? ?? [];

      for (final item in rawList) {
        if (item is Map) {
          final map = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item);
          final dto = FirestoreQuestionDto.fromJson(map, map['id'] as String?);
          final question = QuestionMapper.toDomain(dto);

          // Guarantee questions are not duplicated
          if (seenIds.add(question.id)) {
            accumulatedQuestions.add(question);
          }
        }
      }

      // Check pagination metadata from backend
      final pagination = response['pagination'];
      if (pagination is Map) {
        hasMore = pagination['hasMore'] as bool? ?? false;
        currentCursor = pagination['nextCursor'] as String?;
        if (currentCursor == null || currentCursor.isEmpty) {
          hasMore = false;
        }
      } else {
        hasMore = false;
      }
    }

    accumulatedQuestions.sort((a, b) => a.questionNumber.compareTo(b.questionNumber));

    debugPrint(
      '[BackendLearningRepository] Loaded ${accumulatedQuestions.length} questions for module $targetModule',
    );

    _cachedQuestionsByClass[targetModule] = accumulatedQuestions;
    for (final q in accumulatedQuestions) {
      _cachedQuestionsById[q.id] = q;
    }

    return List.unmodifiable(accumulatedQuestions);
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    if (_cachedQuestionsById.containsKey(id)) {
      return _cachedQuestionsById[id];
    }

    try {
      final response = await apiClient.get(ApiConfig.questionByIdUrl(id));
      final rawData = response['data'];
      if (rawData is Map) {
        final map = rawData is Map<String, dynamic>
            ? rawData
            : Map<String, dynamic>.from(rawData);
        final dto = FirestoreQuestionDto.fromJson(map, map['id'] as String?);
        final question = QuestionMapper.toDomain(dto);
        _cachedQuestionsById[question.id] = question;
        return question;
      }
    } catch (e) {
      debugPrint('[BackendLearningRepository] Question $id not found: $e');
    }

    return null;
  }

  @override
  Future<Question?> getQuestionByNumber(
    int questionNumber, {
    String? drivingClassId,
  }) async {
    // 1. Check in-memory cache
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

    // 2. Try direct document lookups via backend API
    final numPadded = questionNumber.toString().padLeft(3, '0');
    if (drivingClassId != null) {
      final candidate = await getQuestionById(
        'AT_${drivingClassId.toUpperCase()}_$numPadded',
      );
      if (candidate != null && candidate.questionNumber == questionNumber) {
        return candidate;
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

    // 3. Fallback: fetch questions for module and filter
    if (drivingClassId != null) {
      final scoped = await getQuestions(drivingClassId: drivingClassId);
      final found = scoped
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

    // Group questions dynamically by topic
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
    final allUnits = <LearningUnit>[];
    for (final code in ['GW', 'B']) {
      final units = await getLearningUnits(drivingClassId: code);
      allUnits.addAll(units);
    }

    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return allUnits;

    return allUnits
        .where(
          (u) =>
              u.title.toLowerCase().contains(clean) ||
              u.categoryName.toLowerCase().contains(clean),
        )
        .toList();
  }

  @override
  Future<QuestionCheckResult> checkQuestionAnswer({
    required String questionId,
    required List<String> selectedOptionIds,
  }) async {
    final response = await apiClient.post(
      ApiConfig.questionCheckUrl(questionId),
      body: {
        'selectedOptionIds': selectedOptionIds,
      },
    );

    final rawData = response['data'] as Map<String, dynamic>? ?? response;
    return QuestionCheckResult.fromJson(rawData);
  }

  String _formatTopicTitle(String topicKey) {
    return topicKey
        .split('_')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }
}
