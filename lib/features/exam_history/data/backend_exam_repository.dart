import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../learning/data/backend_learning_repository.dart';
import '../../learning/domain/driving_class.dart';
import '../../learning/domain/question.dart';
import '../domain/exam_attempt.dart';
import 'exam_repository.dart';

/// Node.js Backend implementation of [ExamRepository].
///
/// Communicates with:
/// - `POST /api/exams/submit` (Authoritative server-side evaluation & persistence)
/// - `GET /api/exams/results` (Student attempt history)
/// - `GET /api/exams/results/:attemptId` (Detailed attempt result)
class BackendExamRepository implements ExamRepository {
  BackendExamRepository({
    required this.apiClient,
    required this.learningRepository,
  });

  final ApiClient apiClient;
  final BackendLearningRepository learningRepository;

  @override
  Future<List<DrivingClass>> getEligibleExamClasses() async {
    return learningRepository.getDrivingClasses();
  }

  @override
  int calculateTotalExamQuestions(
    List<String> selectedClassCodes,
    List<DrivingClass> availableClasses,
  ) {
    if (selectedClassCodes.isEmpty) return 0;

    int total = 0;
    for (final code in selectedClassCodes) {
      final match = availableClasses
          .where((c) => c.code.toUpperCase() == code.toUpperCase())
          .firstOrNull;
      if (match != null) {
        total += match.preliminaryExamQuestionsCount;
      }
    }
    return total;
  }

  @override
  Future<List<Question>> getExamQuestions({
    required List<String> selectedClassCodes,
  }) async {
    final List<Question> examQuestions = [];

    for (final code in selectedClassCodes) {
      final moduleQuestions = await learningRepository.getQuestions(
        drivingClassId: code,
      );
      examQuestions.addAll(moduleQuestions);
    }

    return examQuestions;
  }

  @override
  Future<List<ExamAttempt>> getExamHistory() async {
    try {
      final response = await apiClient.get(
        ApiConfig.examResultsUrl,
        queryParams: {'limit': '50'},
      );

      final rawList = response['data'] as List<dynamic>? ?? [];
      final List<ExamAttempt> attempts = [];

      for (final item in rawList) {
        if (item is Map) {
          final map = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item);
          attempts.add(_mapBackendResultToExamAttempt(map));
        }
      }

      // Sort newest first
      attempts.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return attempts;
    } catch (e) {
      debugPrint('[BackendExamRepository] Failed to fetch exam history: $e');
      rethrow;
    }
  }

  @override
  Future<int> getTotalExamsCount() async {
    final history = await getExamHistory();
    return history.length;
  }

  @override
  Future<void> saveExamAttempt(ExamAttempt attempt) async {
    // When using the backend API, attempts are automatically persisted
    // on the server during `submitExam`. This method is maintained for interface compatibility.
    debugPrint('[BackendExamRepository] Attempt ${attempt.id} logged locally');
  }

  @override
  Future<ExamAttempt> startPreliminaryExam(List<String> selectedClassCodes) async {
    final available = await getEligibleExamClasses();
    final totalQ = calculateTotalExamQuestions(selectedClassCodes, available);

    return ExamAttempt(
      id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
      dateTime: DateTime.now(),
      selectedClasses: selectedClassCodes,
      totalQuestions: totalQ,
      pointsScored: 0,
      scorePercentage: 0.0,
      isPassed: false,
      statusLabel: 'In Progress',
    );
  }

  /// Submits student answers to the backend evaluation engine and returns the authoritative [ExamAttempt].
  Future<ExamAttempt> submitExamAnswers({
    required String moduleCode,
    required Map<String, Set<String>> answers,
    String? submissionId,
  }) async {
    final uniqueSubmissionId = submissionId ?? _generateSubmissionId();

    final formattedAnswers = answers.entries.map((entry) {
      return {
        'questionId': entry.key,
        'selectedOptionIds': entry.value.toList(),
      };
    }).toList();

    debugPrint(
      '[BackendExamRepository] Submitting exam for module $moduleCode (${formattedAnswers.length} answers, id: $uniqueSubmissionId)',
    );

    final response = await apiClient.post(
      ApiConfig.examSubmitUrl,
      body: {
        'submissionId': uniqueSubmissionId,
        'moduleCode': moduleCode.toUpperCase(),
        'examMode': 'practice',
        'answers': formattedAnswers,
      },
    );

    final rawData = response['data'] as Map<String, dynamic>? ??
        Map<String, dynamic>.from(response['data'] as Map);

    return _mapBackendResultToExamAttempt(rawData);
  }

  ExamAttempt _mapBackendResultToExamAttempt(Map<String, dynamic> data) {
    final attemptId = (data['attemptId'] ?? data['id'] ?? '') as String;
    final submittedAtStr = data['submittedAt'] as String?;
    final dateTime = submittedAtStr != null
        ? DateTime.tryParse(submittedAtStr) ?? DateTime.now()
        : DateTime.now();

    final moduleCode = (data['moduleCode'] as String?)?.toUpperCase() ?? 'GW';
    final totalQuestions = (data['totalQuestions'] as num?)?.toInt() ?? 0;
    final awardedPoints = (data['awardedPoints'] as num?)?.toInt() ??
        (data['correctQuestions'] as num?)?.toInt() ??
        0;
    final scorePercentage = (data['percentage'] as num?)?.toDouble() ?? 0.0;
    final isPassed = (data['passed'] as bool?) ?? false;
    final statusLabel = (data['statusLabel'] as String?) ??
        (isPassed ? 'Bestanden' : 'Nicht bestanden');

    return ExamAttempt(
      id: attemptId,
      dateTime: dateTime,
      selectedClasses: [moduleCode],
      totalQuestions: totalQuestions,
      pointsScored: awardedPoints,
      scorePercentage: scorePercentage,
      isPassed: isPassed,
      statusLabel: statusLabel,
    );
  }

  String _generateSubmissionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'sub_${timestamp}_$randomPart';
  }
}
