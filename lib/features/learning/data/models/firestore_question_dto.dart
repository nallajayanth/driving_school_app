import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

/// DTO representing media metadata in Firestore question documents.
class FirestoreMediaDto {
  const FirestoreMediaDto({
    this.storagePath,
    this.url,
    this.type,
    this.aspectRatio,
  });

  final String? storagePath;
  final String? url;
  final String? type;
  final double? aspectRatio;

  Map<String, dynamic> toJson() {
    return {
      if (storagePath != null) 'storagePath': storagePath,
      if (url != null) 'url': url,
      if (type != null) 'type': type,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
    };
  }

  factory FirestoreMediaDto.fromJson(dynamic json) {
    if (json == null) return const FirestoreMediaDto();
    if (json is String) {
      return FirestoreMediaDto(url: json);
    }
    if (json is Map<String, dynamic>) {
      return FirestoreMediaDto(
        storagePath: json['storagePath'] as String?,
        url: json['url'] as String?,
        type: json['type'] as String?,
        aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
      );
    }
    return const FirestoreMediaDto();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirestoreMediaDto &&
          runtimeType == other.runtimeType &&
          storagePath == other.storagePath &&
          url == other.url &&
          type == other.type &&
          aspectRatio == other.aspectRatio;

  @override
  int get hashCode => Object.hash(storagePath, url, type, aspectRatio);
}

/// DTO representing an answer option in public Firestore question documents.
///
/// SECURITY NOTICE:
/// This DTO intentionally DOES NOT include any answer key, correctness flag,
/// or explanation. Answer keys reside exclusively in the server-only
/// `question_answer_keys` collection and must never be loaded by the client.
class FirestoreOptionDto {
  const FirestoreOptionDto({required this.id, required this.text});

  final String id;
  final String text;

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text};
  }

  factory FirestoreOptionDto.fromJson(Map<String, dynamic> json) {
    return FirestoreOptionDto(
      id: (json['id'] as String?)?.trim() ?? '',
      text: (json['text'] as String?)?.trim() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirestoreOptionDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text;

  @override
  int get hashCode => Object.hash(id, text);
}

/// DTO representing a document from the public Firestore `questions` collection.
///
/// Follows the schema of Austrian driving theory questions imported from
/// `questions_public.json`.
class FirestoreQuestionDto {
  const FirestoreQuestionDto({
    required this.id,
    this.countryCode = 'AT',
    this.countryName = 'Austria',
    this.moduleCode,
    this.licenceCategory,
    this.languageCode = 'en',
    this.topic,
    required this.questionText,
    this.questionType,
    this.selectionMode,
    this.options = const [],
    this.difficulty,
    this.isActive = true,
    this.contentType,
    this.requiresImage = false,
    this.media,
    this.sourceIds = const [],
    this.version = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? countryCode;
  final String? countryName;
  final String? moduleCode; // e.g. "GW", "B"
  final String? licenceCategory; // e.g. "GENERAL", "B"
  final String? languageCode; // e.g. "en", "de"
  final String? topic; // e.g. "following_distance", "road_markings"
  final String questionText;
  final String? questionType; // e.g. "multi_select"
  final String? selectionMode; // e.g. "multiple", "single"
  final List<FirestoreOptionDto> options;
  final String? difficulty; // e.g. "easy", "medium", "hard"
  final bool isActive;
  final String? contentType;
  final bool requiresImage;
  final FirestoreMediaDto? media;
  final List<String> sourceIds;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (countryCode != null) 'countryCode': countryCode,
      if (countryName != null) 'countryName': countryName,
      if (moduleCode != null) 'moduleCode': moduleCode,
      if (licenceCategory != null) 'licenceCategory': licenceCategory,
      if (languageCode != null) 'languageCode': languageCode,
      if (topic != null) 'topic': topic,
      'questionText': questionText,
      if (questionType != null) 'questionType': questionType,
      if (selectionMode != null) 'selectionMode': selectionMode,
      'options': options.map((o) => o.toJson()).toList(),
      if (difficulty != null) 'difficulty': difficulty,
      'isActive': isActive,
      if (contentType != null) 'contentType': contentType,
      'requiresImage': requiresImage,
      'media': media?.toJson(),
      if (sourceIds.isNotEmpty) 'sourceIds': sourceIds,
      'version': version,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory FirestoreQuestionDto.fromJson(
    Map<String, dynamic> json, [
    String? docId,
  ]) {
    final id = (json['id'] as String?)?.trim() ?? docId ?? '';
    final rawOptions = json['options'];
    final List<FirestoreOptionDto> parsedOptions = [];

    if (rawOptions is List) {
      for (final item in rawOptions) {
        if (item is Map<String, dynamic>) {
          parsedOptions.add(FirestoreOptionDto.fromJson(item));
        } else if (item is Map) {
          parsedOptions.add(
            FirestoreOptionDto.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawSources = json['sourceIds'];
    final List<String> parsedSources = [];
    if (rawSources is List) {
      for (final src in rawSources) {
        if (src != null) {
          parsedSources.add(src.toString());
        }
      }
    }

    FirestoreMediaDto? parsedMedia;
    final rawMedia = json['media'];
    if (rawMedia != null) {
      parsedMedia = FirestoreMediaDto.fromJson(rawMedia);
    }

    return FirestoreQuestionDto(
      id: id,
      countryCode: json['countryCode'] as String? ?? 'AT',
      countryName: json['countryName'] as String? ?? 'Austria',
      moduleCode: json['moduleCode'] as String?,
      licenceCategory: json['licenceCategory'] as String?,
      languageCode: json['languageCode'] as String? ?? 'en',
      topic: json['topic'] as String?,
      questionText: json['questionText'] as String? ?? '',
      questionType: json['questionType'] as String?,
      selectionMode: json['selectionMode'] as String?,
      options: List.unmodifiable(parsedOptions),
      difficulty: json['difficulty'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      contentType: json['contentType'] as String?,
      requiresImage: (json['requiresImage'] as bool?) ?? false,
      media: parsedMedia,
      sourceIds: List.unmodifiable(parsedSources),
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is firestore.Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      if (seconds is int) {
        final nanos = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
        final millis =
            seconds * 1000 + (nanos is int ? (nanos / 1000000).round() : 0);
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirestoreQuestionDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          countryCode == other.countryCode &&
          countryName == other.countryName &&
          moduleCode == other.moduleCode &&
          licenceCategory == other.licenceCategory &&
          languageCode == other.languageCode &&
          topic == other.topic &&
          questionText == other.questionText &&
          questionType == other.questionType &&
          selectionMode == other.selectionMode &&
          difficulty == other.difficulty &&
          isActive == other.isActive &&
          contentType == other.contentType &&
          requiresImage == other.requiresImage &&
          media == other.media &&
          version == other.version;

  @override
  int get hashCode => Object.hash(
    id,
    countryCode,
    moduleCode,
    licenceCategory,
    languageCode,
    topic,
    questionText,
    questionType,
    selectionMode,
    difficulty,
    isActive,
    requiresImage,
    media,
    version,
  );
}
