import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

/// DTO representing a legal or governmental reference from the public
/// Firestore `question_sources` collection.
class FirestoreQuestionSourceDto {
  const FirestoreQuestionSourceDto({
    required this.id,
    this.authority,
    this.title,
    this.url,
    this.legalBasis,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? authority;
  final String? title;
  final String? url;
  final String? legalBasis;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (authority != null) 'authority': authority,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (legalBasis != null) 'legalBasis': legalBasis,
      if (note != null) 'note': note,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory FirestoreQuestionSourceDto.fromJson(
    Map<String, dynamic> json, [
    String? docId,
  ]) {
    final id = (json['id'] as String?)?.trim() ?? docId ?? '';
    return FirestoreQuestionSourceDto(
      id: id,
      authority: json['authority'] as String?,
      title: json['title'] as String?,
      url: json['url'] as String?,
      legalBasis: json['legalBasis'] as String?,
      note: json['note'] as String?,
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
      other is FirestoreQuestionSourceDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          authority == other.authority &&
          title == other.title &&
          url == other.url &&
          legalBasis == other.legalBasis &&
          note == other.note;

  @override
  int get hashCode => Object.hash(id, authority, title, url, legalBasis, note);
}
