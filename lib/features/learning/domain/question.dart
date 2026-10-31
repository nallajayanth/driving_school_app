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

/// Selection mode indicating whether one or multiple answers may be chosen.
enum QuestionSelectionMode {
  single,
  multiple,
  unknown;

  static QuestionSelectionMode fromString(String? value) {
    if (value == null) return QuestionSelectionMode.unknown;
    switch (value.trim().toLowerCase()) {
      case 'single':
      case 'single_select':
      case 'single_choice':
        return QuestionSelectionMode.single;
      case 'multiple':
      case 'multi_select':
      case 'multiple_choice':
        return QuestionSelectionMode.multiple;
      default:
        return QuestionSelectionMode.unknown;
    }
  }

  String toJson() => name;
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
    this.selectionMode = QuestionSelectionMode.unknown,
    this.difficulty,
    this.topic,
    this.sourceIds = const [],
    this.requiresImage = false,
    this.countryCode,
    this.languageCode,
  });

  final String id;
  final int questionNumber; // e.g. 1278 as seen in question lookup
  final String drivingClassId; // e.g. "GW", "B"
  final String? learningUnitId;
  final String text;
  final String? mediaUrl;
  final List<QuestionAnswerOption> options;
  final QuestionSelectionMode selectionMode;
  final String? difficulty;
  final String? topic;
  final List<String> sourceIds;
  final bool requiresImage;
  final String? countryCode;
  final String? languageCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionNumber': questionNumber,
      'drivingClassId': drivingClassId,
      if (learningUnitId != null) 'learningUnitId': learningUnitId,
      'text': text,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      'options': options.map((o) => o.toJson()).toList(),
      if (selectionMode != QuestionSelectionMode.unknown)
        'selectionMode': selectionMode.name,
      if (difficulty != null) 'difficulty': difficulty,
      if (topic != null) 'topic': topic,
      if (sourceIds.isNotEmpty) 'sourceIds': sourceIds,
      if (requiresImage) 'requiresImage': requiresImage,
      if (countryCode != null) 'countryCode': countryCode,
      if (languageCode != null) 'languageCode': languageCode,
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
      selectionMode: QuestionSelectionMode.fromString(
        json['selectionMode'] as String?,
      ),
      difficulty: json['difficulty'] as String?,
      topic: json['topic'] as String?,
      sourceIds:
          (json['sourceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      requiresImage: json['requiresImage'] as bool? ?? false,
      countryCode: json['countryCode'] as String?,
      languageCode: json['languageCode'] as String?,
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
          mediaUrl == other.mediaUrl &&
          selectionMode == other.selectionMode &&
          difficulty == other.difficulty &&
          topic == other.topic &&
          requiresImage == other.requiresImage &&
          countryCode == other.countryCode &&
          languageCode == other.languageCode;

  @override
  int get hashCode => Object.hash(
    id,
    questionNumber,
    drivingClassId,
    learningUnitId,
    text,
    mediaUrl,
    selectionMode,
    difficulty,
    topic,
    requiresImage,
    countryCode,
    languageCode,
  );
}
