import 'package:cloud_firestore/cloud_firestore.dart';

/// Status indicating a student's learning stage for a specific question.
///
/// Supported values:
/// - [viewed]: Question was opened and viewed.
/// - [inProgress]: Student selected at least one answer option.
/// - [reviewed]: Student manually marked the question as reviewed.
enum StudyStatus {
  viewed,
  inProgress,
  reviewed;

  String toValue() {
    switch (this) {
      case StudyStatus.viewed:
        return 'viewed';
      case StudyStatus.inProgress:
        return 'in_progress';
      case StudyStatus.reviewed:
        return 'reviewed';
    }
  }

  static StudyStatus fromValue(String? value) {
    if (value == null) return StudyStatus.viewed;
    switch (value.trim().toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        return StudyStatus.inProgress;
      case 'reviewed':
        return StudyStatus.reviewed;
      case 'viewed':
      default:
        return StudyStatus.viewed;
    }
  }
}

/// Domain model representing an individual student's question progress in Firestore.
/// Stored under `users/{uid}/question_progress/{questionId}`.
class StudentQuestionProgress {
  const StudentQuestionProgress({
    required this.questionId,
    required this.moduleCode,
    this.languageCode = 'en',
    this.topic,
    this.selectedOptionIds = const [],
    this.studyStatus = StudyStatus.viewed,
    this.firstViewedAt,
    this.lastViewedAt,
    this.updatedAt,
    this.questionNumber,
  });

  final String questionId;
  final String moduleCode;
  final String languageCode;
  final String? topic;
  final List<String> selectedOptionIds;
  final StudyStatus studyStatus;
  final DateTime? firstViewedAt;
  final DateTime? lastViewedAt;
  final DateTime? updatedAt;
  final int? questionNumber;

  bool get isViewed => studyStatus == StudyStatus.viewed;
  bool get isInProgress => studyStatus == StudyStatus.inProgress;
  bool get isReviewed => studyStatus == StudyStatus.reviewed;

  StudentQuestionProgress copyWith({
    String? questionId,
    String? moduleCode,
    String? languageCode,
    String? topic,
    List<String>? selectedOptionIds,
    StudyStatus? studyStatus,
    DateTime? firstViewedAt,
    DateTime? lastViewedAt,
    DateTime? updatedAt,
    int? questionNumber,
  }) {
    return StudentQuestionProgress(
      questionId: questionId ?? this.questionId,
      moduleCode: moduleCode ?? this.moduleCode,
      languageCode: languageCode ?? this.languageCode,
      topic: topic ?? this.topic,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      studyStatus: studyStatus ?? this.studyStatus,
      firstViewedAt: firstViewedAt ?? this.firstViewedAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questionNumber: questionNumber ?? this.questionNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'moduleCode': moduleCode,
      'languageCode': languageCode,
      if (topic != null) 'topic': topic,
      'selectedOptionIds': selectedOptionIds,
      'studyStatus': studyStatus.toValue(),
      if (firstViewedAt != null)
        'firstViewedAt': firstViewedAt!.toIso8601String(),
      if (lastViewedAt != null) 'lastViewedAt': lastViewedAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (questionNumber != null) 'questionNumber': questionNumber,
    };
  }

  /// Map suitable for Firestore write operations using [FieldValue.serverTimestamp].
  Map<String, dynamic> toFirestoreMap({bool isFirstView = false}) {
    return {
      'questionId': questionId,
      'moduleCode': moduleCode,
      'languageCode': languageCode,
      if (topic != null) 'topic': topic,
      'selectedOptionIds': selectedOptionIds,
      'studyStatus': studyStatus.toValue(),
      if (questionNumber != null) 'questionNumber': questionNumber,
      if (isFirstView) 'firstViewedAt': FieldValue.serverTimestamp(),
      'lastViewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory StudentQuestionProgress.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final rawOptions = json['selectedOptionIds'];
    List<String> options = const [];
    if (rawOptions is List) {
      options = rawOptions.map((e) => e.toString()).toList();
    }

    return StudentQuestionProgress(
      questionId: json['questionId'] as String? ?? '',
      moduleCode: json['moduleCode'] as String? ?? 'GW',
      languageCode: json['languageCode'] as String? ?? 'en',
      topic: json['topic'] as String?,
      selectedOptionIds: options,
      studyStatus: StudyStatus.fromValue(json['studyStatus'] as String?),
      firstViewedAt: parseDate(json['firstViewedAt']),
      lastViewedAt: parseDate(json['lastViewedAt']),
      updatedAt: parseDate(json['updatedAt']),
      questionNumber: json['questionNumber'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentQuestionProgress &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          moduleCode == other.moduleCode &&
          studyStatus == other.studyStatus &&
          selectedOptionIds.length == other.selectedOptionIds.length &&
          selectedOptionIds.every((id) => other.selectedOptionIds.contains(id));

  @override
  int get hashCode => Object.hash(
    questionId,
    moduleCode,
    studyStatus,
    Object.hashAll(selectedOptionIds),
  );
}
