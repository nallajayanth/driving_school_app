import '../../learning/domain/driving_class.dart';
import '../../learning/domain/question.dart';
import '../domain/exam_attempt.dart';
import 'exam_repository.dart';

/// Explicitly labeled mock implementation of [ExamRepository] for development and UI prototyping.
/// Pre-populated with preliminary exam class configurations and sample historical attempts.
class MockExamRepository implements ExamRepository {
  MockExamRepository();

  final List<DrivingClass> _eligibleClasses = const [
    DrivingClass(
      id: 'class_gw',
      code: 'GW',
      name: 'GW',
      preliminaryExamQuestionsCount: 40,
      description: 'Grundwissen',
    ),
    DrivingClass(
      id: 'class_b',
      code: 'B',
      name: 'B',
      preliminaryExamQuestionsCount: 40,
      description: 'Klasse B',
    ),
  ];

  final List<ExamAttempt> _history = [
    ExamAttempt(
      id: 'attempt_mock_1',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      selectedClasses: const ['GW'],
      totalQuestions: 40,
      pointsScored: 0,
      scorePercentage: 0.0,
      isPassed: false,
      statusLabel: 'Nicht bestanden',
    ),
  ];

  /// Realistic demonstration question bank for preliminary mock exams.
  final List<Question> _mockExamQuestions = const [
    // GW (Grundwissen) Questions
    Question(
      id: 'exam_gw_1',
      questionNumber: 1278,
      drivingClassId: 'GW',
      text:
          'What is the general speed limit on open country roads outside built-up areas in Austria?',
      options: [
        QuestionAnswerOption(id: 'gw_1_a', text: '80 km/h', isCorrect: false),
        QuestionAnswerOption(id: 'gw_1_b', text: '100 km/h', isCorrect: true),
        QuestionAnswerOption(id: 'gw_1_c', text: '130 km/h', isCorrect: false),
      ],
    ),
    Question(
      id: 'exam_gw_2',
      questionNumber: 1001,
      drivingClassId: 'GW',
      text:
          'How should you behave when approaching a tunnel with red overhead traffic lights?',
      options: [
        QuestionAnswerOption(
          id: 'gw_2_a',
          text:
              'Stop before the tunnel entrance and turn on hazard warning lights',
          isCorrect: true,
        ),
        QuestionAnswerOption(
          id: 'gw_2_b',
          text: 'Continue driving slowly through with dipped headlights',
          isCorrect: false,
        ),
        QuestionAnswerOption(
          id: 'gw_2_c',
          text: 'Accelerate through the tunnel to exit promptly',
          isCorrect: false,
        ),
      ],
    ),
    Question(
      id: 'exam_gw_3',
      questionNumber: 1042,
      drivingClassId: 'GW',
      text:
          'What is the purpose of the Rettungsgasse (emergency corridor) on Austrian motorways and expressways?',
      options: [
        QuestionAnswerOption(
          id: 'gw_3_a',
          text:
              'To allow emergency and recovery vehicles quick passage through traffic congestion',
          isCorrect: true,
        ),
        QuestionAnswerOption(
          id: 'gw_3_b',
          text: 'To allow faster vehicles to overtake during slow traffic',
          isCorrect: false,
        ),
        QuestionAnswerOption(
          id: 'gw_3_c',
          text: 'It serves as an extra driving lane for buses and motorcycles',
          isCorrect: false,
        ),
      ],
    ),
    Question(
      id: 'exam_gw_4',
      questionNumber: 1105,
      drivingClassId: 'GW',
      text: 'What does a flashing green traffic light indicate in Austria?',
      options: [
        QuestionAnswerOption(
          id: 'gw_4_a',
          text: 'The green phase is about to end and switch to amber',
          isCorrect: true,
        ),
        QuestionAnswerOption(
          id: 'gw_4_b',
          text: 'You have immediate right-of-way over all turning traffic',
          isCorrect: false,
        ),
        QuestionAnswerOption(
          id: 'gw_4_c',
          text: 'The traffic light system has failed',
          isCorrect: false,
        ),
      ],
    ),
    Question(
      id: 'exam_gw_5',
      questionNumber: 1150,
      drivingClassId: 'GW',
      text:
          'When are you allowed to use acoustic warning signals (the horn) within built-up areas in Austria?',
      options: [
        QuestionAnswerOption(
          id: 'gw_5_a',
          text:
              'Only when the traffic safety requires it to avoid an impending danger',
          isCorrect: true,
        ),
        QuestionAnswerOption(
          id: 'gw_5_b',
          text: 'To alert friends or greet other motorists',
          isCorrect: false,
        ),
        QuestionAnswerOption(
          id: 'gw_5_c',
          text: 'Before every overtaking maneuver',
          isCorrect: false,
        ),
      ],
    ),

    // Class B (Passenger Car) Questions
    Question(
      id: 'exam_b_1',
      questionNumber: 2001,
      drivingClassId: 'B',
      text:
          'What is the legally prescribed minimum tire tread depth for summer tires on passenger cars in Austria?',
      options: [
        QuestionAnswerOption(id: 'b_1_a', text: '1.6 mm', isCorrect: true),
        QuestionAnswerOption(id: 'b_1_b', text: '4.0 mm', isCorrect: false),
        QuestionAnswerOption(id: 'b_1_c', text: '2.5 mm', isCorrect: false),
      ],
    ),
    Question(
      id: 'exam_b_2',
      questionNumber: 2025,
      drivingClassId: 'B',
      text:
          'What is the legally required minimum tread depth for winter tires (radial) on cars in Austria?',
      options: [
        QuestionAnswerOption(id: 'b_2_a', text: '4.0 mm', isCorrect: true),
        QuestionAnswerOption(id: 'b_2_b', text: '1.6 mm', isCorrect: false),
        QuestionAnswerOption(id: 'b_2_c', text: '3.0 mm', isCorrect: false),
      ],
    ),
    Question(
      id: 'exam_b_3',
      questionNumber: 2060,
      drivingClassId: 'B',
      text:
          'When you double your driving speed, what happens to your braking distance?',
      options: [
        QuestionAnswerOption(
          id: 'b_3_a',
          text: 'It quadruples (increases fourfold)',
          isCorrect: true,
        ),
        QuestionAnswerOption(id: 'b_3_b', text: 'It doubles', isCorrect: false),
        QuestionAnswerOption(
          id: 'b_3_c',
          text: 'It increases by 50%',
          isCorrect: false,
        ),
      ],
    ),
    Question(
      id: 'exam_b_4',
      questionNumber: 2102,
      drivingClassId: 'B',
      text:
          'Which documents must a driver always carry while operating a passenger vehicle in Austria?',
      options: [
        QuestionAnswerOption(
          id: 'b_4_a',
          text:
              'Valid driving license and vehicle registration document (Zulassungsschein)',
          isCorrect: true,
        ),
        QuestionAnswerOption(
          id: 'b_4_b',
          text: 'Original vehicle purchase invoice and logbook',
          isCorrect: false,
        ),
        QuestionAnswerOption(
          id: 'b_4_c',
          text: 'Birth certificate and proof of address',
          isCorrect: false,
        ),
      ],
    ),
    Question(
      id: 'exam_b_5',
      questionNumber: 2140,
      drivingClassId: 'B',
      text:
          'How must a load protruding more than 1 meter beyond the rear of the car be marked in Austria?',
      options: [
        QuestionAnswerOption(
          id: 'b_5_a',
          text: 'With a 50x50 cm red-and-white reflective marker board',
          isCorrect: true,
        ),
        QuestionAnswerOption(
          id: 'b_5_b',
          text: 'With any piece of light-colored cloth',
          isCorrect: false,
        ),
        QuestionAnswerOption(
          id: 'b_5_c',
          text: 'No marking is needed during daylight hours',
          isCorrect: false,
        ),
      ],
    ),
  ];

  @override
  Future<List<DrivingClass>> getEligibleExamClasses() async {
    return List.unmodifiable(_eligibleClasses);
  }

  @override
  int calculateTotalExamQuestions(
    List<String> selectedClassCodes,
    List<DrivingClass> availableClasses,
  ) {
    if (selectedClassCodes.isEmpty) return 0;
    int total = 0;
    for (final code in selectedClassCodes) {
      final matchingClass = availableClasses.where(
        (c) => c.code.toUpperCase() == code.toUpperCase(),
      );
      if (matchingClass.isNotEmpty) {
        total += matchingClass.first.preliminaryExamQuestionsCount;
      } else {
        // Fallback default per class
        total += 40;
      }
    }
    return total;
  }

  @override
  Future<List<ExamAttempt>> getExamHistory() async {
    return List.unmodifiable(_history);
  }

  @override
  Future<int> getTotalExamsCount() async {
    return _history.length;
  }

  @override
  Future<List<Question>> getExamQuestions({
    required List<String> selectedClassCodes,
  }) async {
    final upperCodes = selectedClassCodes.map((c) => c.toUpperCase()).toSet();
    final matchingQuestions = _mockExamQuestions
        .where((q) => upperCodes.contains(q.drivingClassId.toUpperCase()))
        .toList();

    // If no matching questions found, return all available mock questions
    return matchingQuestions.isNotEmpty
        ? List.unmodifiable(matchingQuestions)
        : List.unmodifiable(_mockExamQuestions);
  }

  @override
  Future<void> saveExamAttempt(ExamAttempt attempt) async {
    // Insert at front so latest attempts show first
    _history.insert(0, attempt);
  }

  @override
  Future<ExamAttempt> startPreliminaryExam(
    List<String> selectedClassCodes,
  ) async {
    // Note: Pending actual exam runner flow discovery
    final total = calculateTotalExamQuestions(
      selectedClassCodes,
      _eligibleClasses,
    );
    final newAttempt = ExamAttempt(
      id: 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      dateTime: DateTime.now(),
      selectedClasses: selectedClassCodes,
      totalQuestions: total,
      pointsScored: 0,
      scorePercentage: 0.0,
      isPassed: false,
      statusLabel: 'In Bearbeitung',
    );
    return newAttempt;
  }
}
