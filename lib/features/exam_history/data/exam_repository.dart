import '../../learning/domain/driving_class.dart';
import '../../learning/domain/question.dart';
import '../domain/exam_attempt.dart';

/// Abstract contract for preliminary examinations and examination history.
/// Production implementation will connect to the verified backend API.
abstract class ExamRepository {
  /// Fetches the list of driving classes available for the preliminary check.
  Future<List<DrivingClass>> getEligibleExamClasses();

  /// Calculates the total number of examination questions for the selected class codes,
  /// including any bonus questions per the source platform's rules.
  int calculateTotalExamQuestions(
    List<String> selectedClassCodes,
    List<DrivingClass> availableClasses,
  );

  /// Retrieves the history of completed preliminary examinations.
  Future<List<ExamAttempt>> getExamHistory();

  /// Total count of completed preliminary exams.
  Future<int> getTotalExamsCount();

  /// Fetches mock questions for an examination session based on selected class codes.
  Future<List<Question>> getExamQuestions({
    required List<String> selectedClassCodes,
  });

  /// Saves a completed preliminary examination attempt to history.
  Future<void> saveExamAttempt(ExamAttempt attempt);

  /// Initiates a preliminary examination session with the chosen classes.
  /// Note: The actual exam runner workflow is marked pending backend API discovery.
  Future<ExamAttempt> startPreliminaryExam(List<String> selectedClassCodes);
}
