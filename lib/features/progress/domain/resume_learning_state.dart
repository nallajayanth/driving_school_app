import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model representing the student's active learning checkpoint in Firestore.
/// Stored under `users/{uid}/learning_state/current`.
class ResumeLearningState {
  const ResumeLearningState({
    required this.lastModuleCode,
    required this.lastQuestionId,
    this.lastQuestionNumber,
    this.lastQuestionText,
    this.updatedAt,
  });

  final String lastModuleCode;
  final String lastQuestionId;
  final int? lastQuestionNumber;
  final String? lastQuestionText;
  final DateTime? updatedAt;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'lastModuleCode': lastModuleCode,
      'lastQuestionId': lastQuestionId,
      if (lastQuestionNumber != null) 'lastQuestionNumber': lastQuestionNumber,
      if (lastQuestionText != null) 'lastQuestionText': lastQuestionText,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'lastModuleCode': lastModuleCode,
      'lastQuestionId': lastQuestionId,
      if (lastQuestionNumber != null) 'lastQuestionNumber': lastQuestionNumber,
      if (lastQuestionText != null) 'lastQuestionText': lastQuestionText,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory ResumeLearningState.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return ResumeLearningState(
      lastModuleCode: json['lastModuleCode'] as String? ?? 'GW',
      lastQuestionId: json['lastQuestionId'] as String? ?? '',
      lastQuestionNumber: json['lastQuestionNumber'] as int?,
      lastQuestionText: json['lastQuestionText'] as String?,
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResumeLearningState &&
          runtimeType == other.runtimeType &&
          lastModuleCode == other.lastModuleCode &&
          lastQuestionId == other.lastQuestionId;

  @override
  int get hashCode => Object.hash(lastModuleCode, lastQuestionId);
}
