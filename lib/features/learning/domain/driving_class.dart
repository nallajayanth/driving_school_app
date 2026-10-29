/// Domain model representing a driving license class (e.g. GW, B).
class DrivingClass {
  const DrivingClass({
    required this.id,
    required this.code,
    required this.name,
    required this.preliminaryExamQuestionsCount,
    this.description,
  });

  final String id;
  final String code; // e.g. "GW", "B"
  final String name; // e.g. "GW", "B"
  final int
  preliminaryExamQuestionsCount; // e.g. 40 questions as seen in the screenshots
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'preliminaryExamQuestionsCount': preliminaryExamQuestionsCount,
      if (description != null) 'description': description,
    };
  }

  factory DrivingClass.fromJson(Map<String, dynamic> json) {
    return DrivingClass(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      preliminaryExamQuestionsCount:
          json['preliminaryExamQuestionsCount'] as int,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrivingClass &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name &&
          preliminaryExamQuestionsCount ==
              other.preliminaryExamQuestionsCount &&
          description == other.description;

  @override
  int get hashCode =>
      Object.hash(id, code, name, preliminaryExamQuestionsCount, description);
}
