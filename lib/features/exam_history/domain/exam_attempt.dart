/// Domain model representing a completed or historical preliminary examination attempt.
class ExamAttempt {
  const ExamAttempt({
    required this.id,
    required this.dateTime,
    required this.selectedClasses,
    required this.totalQuestions,
    required this.pointsScored,
    required this.scorePercentage,
    required this.isPassed,
    this.statusLabel,
  });

  final String id;
  final DateTime dateTime;
  final List<String> selectedClasses; // e.g. ["GW"], ["B"], or ["GW", "B"]
  final int totalQuestions; // e.g. 40
  final int pointsScored; // e.g. 0
  final double scorePercentage; // e.g. 0.0 (%)
  final bool isPassed;
  final String? statusLabel; // e.g. "Bestanden" / "Nicht bestanden"

  String get formattedScore =>
      '${scorePercentage.toStringAsFixed(0)}% ($pointsScored/$totalQuestions)';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'selectedClasses': selectedClasses,
      'totalQuestions': totalQuestions,
      'pointsScored': pointsScored,
      'scorePercentage': scorePercentage,
      'isPassed': isPassed,
      if (statusLabel != null) 'statusLabel': statusLabel,
    };
  }

  factory ExamAttempt.fromJson(Map<String, dynamic> json) {
    return ExamAttempt(
      id: json['id'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      selectedClasses: (json['selectedClasses'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      totalQuestions: json['totalQuestions'] as int,
      pointsScored: json['pointsScored'] as int,
      scorePercentage: (json['scorePercentage'] as num).toDouble(),
      isPassed: json['isPassed'] as bool,
      statusLabel: json['statusLabel'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamAttempt &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dateTime == other.dateTime &&
          totalQuestions == other.totalQuestions &&
          pointsScored == other.pointsScored &&
          scorePercentage == other.scorePercentage &&
          isPassed == other.isPassed;

  @override
  int get hashCode => Object.hash(
    id,
    dateTime,
    totalQuestions,
    pointsScored,
    scorePercentage,
    isPassed,
  );
}
