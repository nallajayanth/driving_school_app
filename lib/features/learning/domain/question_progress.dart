/// Domain model representing the progress state of an individual question.
/// Reflects the question-level status counters observed on the platform:
/// - Box 0 (New or not correct)
/// - Subject 1 (1x correct)
/// - Subject 2 (Correct twice in a row)
/// - Subject 3 (Ready for the exam)
class QuestionProgress {
  const QuestionProgress({
    required this.questionId,
    required this.questionNumber,
    required this.boxLevel,
    this.timesAnswered = 0,
    this.lastAnsweredAt,
  });

  final String questionId;
  final int questionNumber;
  final int boxLevel; // 0, 1, 2, or 3
  final int timesAnswered;
  final DateTime? lastAnsweredAt;

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionNumber': questionNumber,
      'boxLevel': boxLevel,
      'timesAnswered': timesAnswered,
      if (lastAnsweredAt != null)
        'lastAnsweredAt': lastAnsweredAt!.toIso8601String(),
    };
  }

  factory QuestionProgress.fromJson(Map<String, dynamic> json) {
    return QuestionProgress(
      questionId: json['questionId'] as String,
      questionNumber: json['questionNumber'] as int,
      boxLevel: json['boxLevel'] as int,
      timesAnswered: (json['timesAnswered'] as int?) ?? 0,
      lastAnsweredAt: json['lastAnsweredAt'] != null
          ? DateTime.parse(json['lastAnsweredAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionProgress &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          questionNumber == other.questionNumber &&
          boxLevel == other.boxLevel &&
          timesAnswered == other.timesAnswered &&
          lastAnsweredAt == other.lastAnsweredAt;

  @override
  int get hashCode => Object.hash(
    questionId,
    questionNumber,
    boxLevel,
    timesAnswered,
    lastAnsweredAt,
  );
}
