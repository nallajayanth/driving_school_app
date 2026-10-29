/// Domain model representing a learning unit / topic card within a driving class.
class LearningUnit {
  const LearningUnit({
    required this.id,
    required this.drivingClassId,
    required this.categoryName,
    required this.title,
    required this.totalQuestions,
    required this.examReadyCount,
    required this.box0Count,
    required this.box1Count,
    required this.box2Count,
    required this.box3Count,
    required this.readinessPercentage,
    required this.phaseLabel,
    this.phaseIcon = '🚦',
  });

  final String id;
  final String drivingClassId; // e.g. "GW"
  final String categoryName; // e.g. "General traffic regulations, tunnels"
  final String title; // e.g. "General rules of the road, tunnel"
  final int totalQuestions; // e.g. 92
  final int examReadyCount; // e.g. 0
  final int box0Count; // 🔄 New or not correct questions
  final int box1Count; // 👍 1x correct questions
  final int box2Count; // 💪 Correct twice in a row questions
  final int box3Count; // ✅ Ready for the exam questions
  final double readinessPercentage; // e.g. 1.0 (%)
  final String phaseLabel; // e.g. "Start-up phase"
  final String phaseIcon; // e.g. "🚦"

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'drivingClassId': drivingClassId,
      'categoryName': categoryName,
      'title': title,
      'totalQuestions': totalQuestions,
      'examReadyCount': examReadyCount,
      'box0Count': box0Count,
      'box1Count': box1Count,
      'box2Count': box2Count,
      'box3Count': box3Count,
      'readinessPercentage': readinessPercentage,
      'phaseLabel': phaseLabel,
      'phaseIcon': phaseIcon,
    };
  }

  factory LearningUnit.fromJson(Map<String, dynamic> json) {
    return LearningUnit(
      id: json['id'] as String,
      drivingClassId: json['drivingClassId'] as String,
      categoryName: json['categoryName'] as String,
      title: json['title'] as String,
      totalQuestions: json['totalQuestions'] as int,
      examReadyCount: json['examReadyCount'] as int,
      box0Count: json['box0Count'] as int,
      box1Count: json['box1Count'] as int,
      box2Count: json['box2Count'] as int,
      box3Count: json['box3Count'] as int,
      readinessPercentage: (json['readinessPercentage'] as num).toDouble(),
      phaseLabel: json['phaseLabel'] as String,
      phaseIcon: (json['phaseIcon'] as String?) ?? '🚦',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningUnit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          drivingClassId == other.drivingClassId &&
          categoryName == other.categoryName &&
          title == other.title &&
          totalQuestions == other.totalQuestions &&
          examReadyCount == other.examReadyCount &&
          box0Count == other.box0Count &&
          box1Count == other.box1Count &&
          box2Count == other.box2Count &&
          box3Count == other.box3Count &&
          readinessPercentage == other.readinessPercentage &&
          phaseLabel == other.phaseLabel &&
          phaseIcon == other.phaseIcon;

  @override
  int get hashCode => Object.hash(
    id,
    drivingClassId,
    categoryName,
    title,
    totalQuestions,
    examReadyCount,
    box0Count,
    box1Count,
    box2Count,
    box3Count,
    readinessPercentage,
    phaseLabel,
    phaseIcon,
  );
}
