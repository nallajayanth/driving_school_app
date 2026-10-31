import '../domain/question.dart';
import 'models/firestore_question_dto.dart';

/// Mapper responsible for bidirectional conversion and normalization between
/// Cloud Firestore question representations and Flutter domain models.
///
/// CRITICAL SECURITY ENFORCEMENT:
/// This mapper guarantees that client-side domain questions never receive,
/// store, or expose verified answer keys or correct option indicators.
class QuestionMapper {
  QuestionMapper._();

  /// Converts a [FirestoreQuestionDto] into a domain [Question] object.
  static Question toDomain(FirestoreQuestionDto dto) {
    final drivingClass = resolveDrivingClassId(
      moduleCode: dto.moduleCode,
      licenceCategory: dto.licenceCategory,
      questionId: dto.id,
    );

    final questionNum = extractQuestionNumber(dto.id);

    final domainOptions = dto.options
        .map(
          (opt) => QuestionAnswerOption(
            id: opt.id,
            text: opt.text,
            isCorrect:
                null, // Public questions must never reveal the answer key
          ),
        )
        .toList(growable: false);

    final resolvedMediaUrl = dto.media?.url ?? dto.media?.storagePath;

    final mode = parseSelectionMode(
      selectionMode: dto.selectionMode,
      questionType: dto.questionType,
    );

    return Question(
      id: dto.id,
      questionNumber: questionNum,
      drivingClassId: drivingClass,
      learningUnitId: dto.topic != null && dto.topic!.isNotEmpty
          ? 'topic_${dto.topic}'
          : null,
      text: dto.questionText,
      mediaUrl: resolvedMediaUrl,
      options: domainOptions,
      selectionMode: mode,
      difficulty: dto.difficulty,
      topic: dto.topic,
      sourceIds: dto.sourceIds,
      requiresImage: dto.requiresImage,
      countryCode: dto.countryCode,
      languageCode: dto.languageCode,
    );
  }

  /// Parses raw Firestore document data and returns a domain [Question].
  static Question fromFirestore(Map<String, dynamic> data, [String? docId]) {
    final dto = FirestoreQuestionDto.fromJson(data, docId);
    return toDomain(dto);
  }

  /// Parses raw Firestore document data into a [FirestoreQuestionDto].
  static FirestoreQuestionDto toDto(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    return FirestoreQuestionDto.fromJson(data, docId);
  }

  /// Resolves the app's normalized driving license class code ("GW" or "B")
  /// from Firestore's `moduleCode`, `licenceCategory`, or question ID.
  ///
  /// Context & Discovery:
  /// - Firestore GW documents have `moduleCode: "GW"` and `licenceCategory: "GENERAL"`.
  /// - Firestore B documents have `moduleCode: "B"` and `licenceCategory: "B"`.
  /// - Document IDs start with `AT_GW_` or `AT_B_`.
  static String resolveDrivingClassId({
    String? moduleCode,
    String? licenceCategory,
    String? questionId,
  }) {
    final cleanModule = moduleCode?.trim().toUpperCase();
    final cleanCategory = licenceCategory?.trim().toUpperCase();
    final cleanId = questionId?.trim().toUpperCase();

    // Check GW indicators (General Knowledge / Grundwissen)
    if (cleanModule == 'GW' ||
        cleanCategory == 'GENERAL' ||
        cleanCategory == 'GW' ||
        (cleanId?.contains('_GW_') ?? false)) {
      return 'GW';
    }

    // Check B indicators (Category B / Klasse B Passenger Car)
    if (cleanModule == 'B' ||
        cleanCategory == 'B' ||
        (cleanId?.contains('_B_') ?? false)) {
      return 'B';
    }

    // Preserve unknown / new driving category codes if present
    if (cleanModule != null && cleanModule.isNotEmpty) {
      return cleanModule;
    }
    if (cleanCategory != null && cleanCategory.isNotEmpty) {
      return cleanCategory;
    }

    return 'UNKNOWN';
  }

  /// Extracts or parses a question number integer from a question ID.
  ///
  /// Examples:
  /// - "AT_GW_021" -> 21
  /// - "AT_B_001" -> 1
  /// - "q_1278" -> 1278
  /// - "no_digits" -> 0
  static int extractQuestionNumber(String id, [int? explicitNumber]) {
    if (explicitNumber != null && explicitNumber > 0) {
      return explicitNumber;
    }

    final match = RegExp(r'\d+').firstMatch(id);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }

    return 0;
  }

  /// Maps Firestore question type and selection mode strings into
  /// a verified [QuestionSelectionMode].
  ///
  /// If unknown or unrecognized, represents it explicitly as [QuestionSelectionMode.unknown]
  /// instead of guessing.
  static QuestionSelectionMode parseSelectionMode({
    String? selectionMode,
    String? questionType,
  }) {
    if (selectionMode != null && selectionMode.trim().isNotEmpty) {
      return QuestionSelectionMode.fromString(selectionMode);
    }
    if (questionType != null && questionType.trim().isNotEmpty) {
      return QuestionSelectionMode.fromString(questionType);
    }
    return QuestionSelectionMode.unknown;
  }
}
