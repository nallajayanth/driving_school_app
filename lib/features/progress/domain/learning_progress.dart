/// Domain model representing progress per individual topic.
class TopicProgress {
  const TopicProgress({
    required this.topicName,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.examReadyQuestions,
    required this.progressPercentage,
  });

  final String topicName;
  final int totalQuestions;
  final int answeredQuestions;
  final int examReadyQuestions;
  final double progressPercentage;

  Map<String, dynamic> toJson() {
    return {
      'topicName': topicName,
      'totalQuestions': totalQuestions,
      'answeredQuestions': answeredQuestions,
      'examReadyQuestions': examReadyQuestions,
      'progressPercentage': progressPercentage,
    };
  }

  factory TopicProgress.fromJson(Map<String, dynamic> json) {
    return TopicProgress(
      topicName: json['topicName'] as String,
      totalQuestions: json['totalQuestions'] as int,
      answeredQuestions: json['answeredQuestions'] as int,
      examReadyQuestions: json['examReadyQuestions'] as int,
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicProgress &&
          runtimeType == other.runtimeType &&
          topicName == other.topicName &&
          totalQuestions == other.totalQuestions &&
          answeredQuestions == other.answeredQuestions &&
          examReadyQuestions == other.examReadyQuestions &&
          progressPercentage == other.progressPercentage;

  @override
  int get hashCode => Object.hash(
    topicName,
    totalQuestions,
    answeredQuestions,
    examReadyQuestions,
    progressPercentage,
  );
}

/// Domain model representing the aggregate learning progress of the user.
/// Explicitly preserves the distinction between Box 0 and Subject 1, 2, 3 cards,
/// as well as the German "Fach" distribution shown in the reference screens.
class LearningProgress {
  const LearningProgress({
    required this.totalQuestionsAnswered,
    required this.currentLearningLevel,
    this.currentLearningLevelIcon = '🐣',
    required this.box0QuestionsCount,
    required this.subject1QuestionsCount,
    required this.subject2QuestionsCount,
    required this.subject3QuestionsCount,
    this.fach0Value = 60,
    this.fach1Value = 40,
    this.fach2Value = 0,
    this.fach3Value = 0,
    this.topicsProgress = const [],
  });

  final int totalQuestionsAnswered; // e.g. 6 questions
  final String currentLearningLevel; // e.g. "Beginner"
  final String currentLearningLevelIcon; // e.g. "🐣"

  // Dashboard Leitner Status Cards
  final int box0QuestionsCount; // 1426 questions ("New or not correct 🔄")
  final int subject1QuestionsCount; // 2 questions ("1x correct 👍")
  final int subject2QuestionsCount; // 0 questions ("Correct twice in a row 💪")
  final int subject3QuestionsCount; // 0 questions ("Ready for the exam ✅")

  // Progress Screen: "Distribution by subject level" ("Verteilung nach Fachstufe")
  final double fach0Value;
  final double fach1Value;
  final double fach2Value;
  final double fach3Value;

  final List<TopicProgress> topicsProgress;

  Map<String, dynamic> toJson() {
    return {
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'currentLearningLevel': currentLearningLevel,
      'currentLearningLevelIcon': currentLearningLevelIcon,
      'box0QuestionsCount': box0QuestionsCount,
      'subject1QuestionsCount': subject1QuestionsCount,
      'subject2QuestionsCount': subject2QuestionsCount,
      'subject3QuestionsCount': subject3QuestionsCount,
      'fach0Value': fach0Value,
      'fach1Value': fach1Value,
      'fach2Value': fach2Value,
      'fach3Value': fach3Value,
      'topicsProgress': topicsProgress.map((t) => t.toJson()).toList(),
    };
  }

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      totalQuestionsAnswered: json['totalQuestionsAnswered'] as int,
      currentLearningLevel: json['currentLearningLevel'] as String,
      currentLearningLevelIcon:
          (json['currentLearningLevelIcon'] as String?) ?? '🐣',
      box0QuestionsCount: json['box0QuestionsCount'] as int,
      subject1QuestionsCount: json['subject1QuestionsCount'] as int,
      subject2QuestionsCount: json['subject2QuestionsCount'] as int,
      subject3QuestionsCount: json['subject3QuestionsCount'] as int,
      fach0Value: (json['fach0Value'] as num?)?.toDouble() ?? 0.0,
      fach1Value: (json['fach1Value'] as num?)?.toDouble() ?? 0.0,
      fach2Value: (json['fach2Value'] as num?)?.toDouble() ?? 0.0,
      fach3Value: (json['fach3Value'] as num?)?.toDouble() ?? 0.0,
      topicsProgress:
          (json['topicsProgress'] as List<dynamic>?)
              ?.map((t) => TopicProgress.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningProgress &&
          runtimeType == other.runtimeType &&
          totalQuestionsAnswered == other.totalQuestionsAnswered &&
          currentLearningLevel == other.currentLearningLevel &&
          box0QuestionsCount == other.box0QuestionsCount &&
          subject1QuestionsCount == other.subject1QuestionsCount &&
          subject2QuestionsCount == other.subject2QuestionsCount &&
          subject3QuestionsCount == other.subject3QuestionsCount;

  @override
  int get hashCode => Object.hash(
    totalQuestionsAnswered,
    currentLearningLevel,
    box0QuestionsCount,
    subject1QuestionsCount,
    subject2QuestionsCount,
    subject3QuestionsCount,
  );
}
