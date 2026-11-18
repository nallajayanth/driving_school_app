/// Domain model representing the evaluation result of checking a question's selected answers in Learn mode.
class QuestionCheckResult {
  const QuestionCheckResult({
    required this.questionId,
    required this.isCorrect,
    required this.correctOptionIds,
    this.explanation,
  });

  final String questionId;
  final bool isCorrect;
  final List<String> correctOptionIds;
  final String? explanation;

  factory QuestionCheckResult.fromJson(Map<String, dynamic> json) {
    final rawCorrect = json['correctOptionIds'] as List<dynamic>? ?? [];
    return QuestionCheckResult(
      questionId: json['questionId'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      correctOptionIds: rawCorrect.map((e) => e.toString()).toList(),
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'isCorrect': isCorrect,
      'correctOptionIds': correctOptionIds,
      if (explanation != null) 'explanation': explanation,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionCheckResult &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          isCorrect == other.isCorrect &&
          explanation == other.explanation;

  @override
  int get hashCode => Object.hash(questionId, isCorrect, explanation);
}
