import '../domain/driving_class.dart';
import '../domain/learning_unit.dart';
import '../domain/question.dart';
import 'learning_repository.dart';

/// Explicitly labeled mock implementation of [LearningRepository] for development and UI prototyping.
/// Pre-populated with driving classes (GW and B) and topic counts observed in the reference screenshots.
class MockLearningRepository implements LearningRepository {
  MockLearningRepository();

  // Known driving classes from screenshots
  final List<DrivingClass> _classes = const [
    DrivingClass(
      id: 'class_gw',
      code: 'GW',
      name: 'GW',
      preliminaryExamQuestionsCount: 40,
      description: 'Grundwissen (General Knowledge)',
    ),
    DrivingClass(
      id: 'class_b',
      code: 'B',
      name: 'B',
      preliminaryExamQuestionsCount: 40,
      description: 'Klasse B (Passenger Car)',
    ),
  ];

  // Learning units matching screenshot 2 & 5 (GW), plus representative units for B
  final List<LearningUnit> _units = const [
    LearningUnit(
      id: 'unit_gw_1',
      drivingClassId: 'GW',
      categoryName: 'General traffic regulations, tunnels',
      title: 'General rules of the road, tunnel',
      totalQuestions: 92,
      examReadyCount: 0,
      box0Count: 90,
      box1Count: 2,
      box2Count: 0,
      box3Count: 0,
      readinessPercentage: 1.0,
      phaseLabel: 'Start-up phase',
      phaseIcon: '🚦',
    ),
    LearningUnit(
      id: 'unit_gw_2',
      drivingClassId: 'GW',
      categoryName: 'Special traffic areas',
      title: 'Special traffic areas',
      totalQuestions: 56,
      examReadyCount: 0,
      box0Count: 56,
      box1Count: 0,
      box2Count: 0,
      box3Count: 0,
      readinessPercentage: 0.0,
      phaseLabel: 'Start-up phase',
      phaseIcon: '🚦',
    ),
    LearningUnit(
      id: 'unit_gw_3',
      drivingClassId: 'GW',
      categoryName: 'Moving around in traffic',
      title: 'Moving through traffic',
      totalQuestions: 46,
      examReadyCount: 0,
      box0Count: 46,
      box1Count: 0,
      box2Count: 0,
      box3Count: 0,
      readinessPercentage: 0.0,
      phaseLabel: 'Start-up phase',
      phaseIcon: '🚦',
    ),
    // Class B units
    LearningUnit(
      id: 'unit_b_1',
      drivingClassId: 'B',
      categoryName: 'Vehicle technology and equipment',
      title: 'Vehicle technology, tires & lighting',
      totalQuestions: 50,
      examReadyCount: 0,
      box0Count: 50,
      box1Count: 0,
      box2Count: 0,
      box3Count: 0,
      readinessPercentage: 0.0,
      phaseLabel: 'Start-up phase',
      phaseIcon: '🚦',
    ),
    LearningUnit(
      id: 'unit_b_2',
      drivingClassId: 'B',
      categoryName: 'Driving dynamics and safety',
      title: 'Braking distances and load securing',
      totalQuestions: 42,
      examReadyCount: 0,
      box0Count: 42,
      box1Count: 0,
      box2Count: 0,
      box3Count: 0,
      readinessPercentage: 0.0,
      phaseLabel: 'Start-up phase',
      phaseIcon: '🚦',
    ),
  ];

  // Sample questions including #1278 from reference search field
  final List<Question> _questions = const [
    Question(
      id: 'q_1278',
      questionNumber: 1278,
      drivingClassId: 'GW',
      learningUnitId: 'unit_gw_1',
      text:
          'What is the general speed limit on open country roads outside built-up areas in Austria?',
      options: [
        QuestionAnswerOption(id: 'opt_1', text: '80 km/h'),
        QuestionAnswerOption(id: 'opt_2', text: '100 km/h'),
        QuestionAnswerOption(id: 'opt_3', text: '130 km/h'),
      ],
    ),
    Question(
      id: 'q_1001',
      questionNumber: 1001,
      drivingClassId: 'GW',
      learningUnitId: 'unit_gw_1',
      text:
          'How should you behave when approaching a tunnel with red overhead signals?',
      options: [
        QuestionAnswerOption(
          id: 'opt_a',
          text: 'Stop before the entrance and turn on hazard warning lights',
        ),
        QuestionAnswerOption(
          id: 'opt_b',
          text: 'Continue driving slowly with dipped headlights',
        ),
        QuestionAnswerOption(
          id: 'opt_c',
          text: 'Accelerate through the tunnel quickly',
        ),
      ],
    ),
    Question(
      id: 'q_2001',
      questionNumber: 2001,
      drivingClassId: 'B',
      learningUnitId: 'unit_b_1',
      text:
          'What is the legally prescribed minimum tire tread depth for summer tires in Austria?',
      options: [
        QuestionAnswerOption(id: 'opt_b1', text: '1.6 mm'),
        QuestionAnswerOption(id: 'opt_b2', text: '4.0 mm'),
        QuestionAnswerOption(id: 'opt_b3', text: '2.5 mm'),
      ],
    ),
  ];

  @override
  Future<List<DrivingClass>> getDrivingClasses() async {
    return List.unmodifiable(_classes);
  }

  @override
  Future<List<LearningUnit>> getLearningUnits({String? drivingClassId}) async {
    if (drivingClassId == null) {
      return List.unmodifiable(_units);
    }
    return _units
        .where(
          (u) => u.drivingClassId.toUpperCase() == drivingClassId.toUpperCase(),
        )
        .toList();
  }

  @override
  Future<Question?> getQuestionByNumber(int questionNumber) async {
    try {
      return _questions.firstWhere((q) => q.questionNumber == questionNumber);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<LearningUnit>> searchLearningUnits(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return List.unmodifiable(_units);
    return _units
        .where(
          (u) =>
              u.title.toLowerCase().contains(trimmed) ||
              u.categoryName.toLowerCase().contains(trimmed),
        )
        .toList();
  }
}
