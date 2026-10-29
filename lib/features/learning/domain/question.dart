/// Domain model representing a single answer option for a driving theory question.
class QuestionAnswerOption {
  const QuestionAnswerOption({
    required this.id,
    required this.text,
    this.isCorrect, // Nullable pending verified answer disclosure rules
  });

  final String id;
  final String text;
  final bool? isCorrect;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      if (isCorrect != null) 'isCorrect': isCorrect,
    };
  }

  factory QuestionAnswerOption.fromJson(Map<String, dynamic> json) {
    return QuestionAnswerOption(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAnswerOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          isCorrect == other.isCorrect;

  @override
  int get hashCode => Object.hash(id, text, isCorrect);
}

/// Domain model representing a driving theory examination question.
class Question {
  const Question({
    required this.id,
    required this.questionNumber,
    required this.drivingClassId,
    this.learningUnitId,
    required this.text,
    this.mediaUrl,
    this.options = const [],
  });

  final String id;
  final int questionNumber; // e.g. 1278 as seen in question lookup
  final String drivingClassId; // e.g. "GW"
  final String? learningUnitId;
  final String text;
  final String? mediaUrl;
  final List<QuestionAnswerOption> options;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionNumber': questionNumber,
      'drivingClassId': drivingClassId,
      if (learningUnitId != null) 'learningUnitId': learningUnitId,
      'text': text,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      questionNumber: json['questionNumber'] as int,
      drivingClassId: json['drivingClassId'] as String,
      learningUnitId: json['learningUnitId'] as String?,
      text: json['text'] as String,
      mediaUrl: json['mediaUrl'] as String?,
      options:
          (json['options'] as List<dynamic>?)
              ?.map(
                (o) => QuestionAnswerOption.fromJson(o as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          questionNumber == other.questionNumber &&
          drivingClassId == other.drivingClassId &&
          learningUnitId == other.learningUnitId &&
          text == other.text &&
          mediaUrl == other.mediaUrl;

  @override
  int get hashCode => Object.hash(
    id,
    questionNumber,
    drivingClassId,
    learningUnitId,
    text,
    mediaUrl,
  );
}
