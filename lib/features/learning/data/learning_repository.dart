import '../domain/driving_class.dart';
import '../domain/learning_unit.dart';
import '../domain/question.dart';

/// Abstract contract for retrieving learning curriculum, units, and questions.
/// Production implementation will connect to the verified backend API.
abstract class LearningRepository {
  /// Fetches the supported driving license classes (e.g. GW, B).
  Future<List<DrivingClass>> getDrivingClasses();

  /// Fetches learning units overview, optionally filtered by a specific driving class code (e.g. "GW").
  Future<List<LearningUnit>> getLearningUnits({String? drivingClassId});

  /// Looks up an individual question using its public question number (e.g. 1278).
  /// Optionally scoped to a specific driving class code (e.g. "GW", "B").
  /// Returns null if no question matches the provided number.
  Future<Question?> getQuestionByNumber(
    int questionNumber, {
    String? drivingClassId,
  });

  /// Looks up an individual question using its document ID (e.g. "AT_GW_021").
  Future<Question?> getQuestionById(String id);

  /// Fetches all active questions for a driving class (e.g. "GW" -> 42 questions, "B" -> 32 questions).
  Future<List<Question>> getQuestions({String? drivingClassId});

  /// Searches learning units by title or category query string.
  Future<List<LearningUnit>> searchLearningUnits(String query);
}
