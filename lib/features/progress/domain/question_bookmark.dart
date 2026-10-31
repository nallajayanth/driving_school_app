import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model representing a bookmarked question in Firestore.
/// Stored under `users/{uid}/bookmarks/{questionId}`.
class QuestionBookmark {
  const QuestionBookmark({
    required this.questionId,
    required this.moduleCode,
    this.topic,
    this.createdAt,
    this.questionNumber,
    this.questionText,
  });

  final String questionId;
  final String moduleCode;
  final String? topic;
  final DateTime? createdAt;
  final int? questionNumber;
  final String? questionText;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'questionId': questionId,
      'moduleCode': moduleCode,
      if (topic != null) 'topic': topic,
      'createdAt': FieldValue.serverTimestamp(),
      if (questionNumber != null) 'questionNumber': questionNumber,
      if (questionText != null) 'questionText': questionText,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'moduleCode': moduleCode,
      if (topic != null) 'topic': topic,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (questionNumber != null) 'questionNumber': questionNumber,
      if (questionText != null) 'questionText': questionText,
    };
  }

  factory QuestionBookmark.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return QuestionBookmark(
      questionId: json['questionId'] as String? ?? '',
      moduleCode: json['moduleCode'] as String? ?? 'GW',
      topic: json['topic'] as String?,
      createdAt: parseDate(json['createdAt']),
      questionNumber: json['questionNumber'] as int?,
      questionText: json['questionText'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionBookmark &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          moduleCode == other.moduleCode;

  @override
  int get hashCode => Object.hash(questionId, moduleCode);
}
