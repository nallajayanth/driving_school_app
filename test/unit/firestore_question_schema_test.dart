import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_test/flutter_test.dart';
import 'package:driving_school_mobile_app/features/learning/data/firestore_query_strategy.dart';
import 'package:driving_school_mobile_app/features/learning/data/models/firestore_question_dto.dart';
import 'package:driving_school_mobile_app/features/learning/data/models/firestore_question_source_dto.dart';
import 'package:driving_school_mobile_app/features/learning/data/question_mapper.dart';
import 'package:driving_school_mobile_app/features/learning/domain/question.dart';

void main() {
  group('FirestoreQuestionDto & Schema Serialization Tests', () {
    test('Parses full public question document matching Firestore schema', () {
      final sampleJson = {
        'id': 'AT_GW_021',
        'countryCode': 'AT',
        'countryName': 'Austria',
        'moduleCode': 'GW',
        'licenceCategory': 'GENERAL',
        'languageCode': 'en',
        'topic': 'hazard_awareness',
        'questionText':
            'You are driving in a rural area. A deer appears on the road ahead. What should you do?',
        'questionType': 'multi_select',
        'selectionMode': 'multiple',
        'options': [
          {'id': 'A', 'text': 'Brake firmly and keep your vehicle in lane.'},
          {'id': 'B', 'text': 'Swerve aggressively into oncoming traffic.'},
          {'id': 'C', 'text': 'Sound the horn and dim high beam lights.'},
          {'id': 'D', 'text': 'Accelerate to pass before the animal crosses.'},
        ],
        'difficulty': 'medium',
        'isActive': true,
        'contentType': 'original_practice_question',
        'requiresImage': false,
        'media': null,
        'sourceIds': ['AT_STVO_18'],
        'version': 1,
        'createdAt': '2026-10-30T10:00:00.000Z',
        'updatedAt': '2026-10-30T10:00:00.000Z',
      };

      final dto = FirestoreQuestionDto.fromJson(sampleJson);

      expect(dto.id, 'AT_GW_021');
      expect(dto.moduleCode, 'GW');
      expect(dto.licenceCategory, 'GENERAL');
      expect(dto.countryCode, 'AT');
      expect(dto.languageCode, 'en');
      expect(dto.topic, 'hazard_awareness');
      expect(dto.questionText, contains('deer appears'));
      expect(dto.selectionMode, 'multiple');
      expect(dto.difficulty, 'medium');
      expect(dto.isActive, isTrue);
      expect(dto.requiresImage, isFalse);
      expect(dto.media, isNull);
      expect(dto.options.length, 4);
      expect(dto.options.first.id, 'A');
      expect(
        dto.options.first.text,
        'Brake firmly and keep your vehicle in lane.',
      );
      expect(dto.sourceIds, equals(['AT_STVO_18']));
      expect(dto.version, 1);
      expect(dto.createdAt, isNotNull);
    });

    test('Serializes FirestoreQuestionDto back to JSON', () {
      const dto = FirestoreQuestionDto(
        id: 'AT_B_001',
        moduleCode: 'B',
        licenceCategory: 'B',
        questionText: 'What is the speed limit?',
        options: [
          FirestoreOptionDto(id: 'A', text: '50 km/h'),
          FirestoreOptionDto(id: 'B', text: '100 km/h'),
        ],
        selectionMode: 'single',
      );

      final json = dto.toJson();
      expect(json['id'], 'AT_B_001');
      expect(json['moduleCode'], 'B');
      expect(json['licenceCategory'], 'B');
      expect(json['questionText'], 'What is the speed limit?');
      expect((json['options'] as List).length, 2);
    });

    test('Handles missing, null, and fallback values gracefully', () {
      final minimalJson = <String, dynamic>{
        'questionText': 'Minimal question without metadata',
      };

      final dto = FirestoreQuestionDto.fromJson(
        minimalJson,
        'doc_fallback_123',
      );

      expect(dto.id, 'doc_fallback_123');
      expect(dto.questionText, 'Minimal question without metadata');
      expect(dto.countryCode, 'AT');
      expect(dto.languageCode, 'en');
      expect(dto.isActive, isTrue);
      expect(dto.requiresImage, isFalse);
      expect(dto.media, isNull);
      expect(dto.options, isEmpty);
      expect(dto.sourceIds, isEmpty);
      expect(dto.version, 1);
    });

    test('Preserves option IDs and option ordering strictly', () {
      final optionsJson = {
        'id': 'AT_ORDER_TEST',
        'questionText': 'Ordering test',
        'options': [
          {'id': 'D', 'text': 'Fourth'},
          {'id': 'B', 'text': 'Second'},
          {'id': 'A', 'text': 'First'},
          {'id': 'C', 'text': 'Third'},
        ],
      };

      final dto = FirestoreQuestionDto.fromJson(optionsJson);
      expect(dto.options.map((o) => o.id).toList(), ['D', 'B', 'A', 'C']);
      expect(dto.options.map((o) => o.text).toList(), [
        'Fourth',
        'Second',
        'First',
        'Third',
      ]);
    });
  });

  group('QuestionMapper Category & Code Resolution Tests', () {
    test(
      'Maps GW moduleCode and GENERAL licenceCategory to GW driving class',
      () {
        expect(
          QuestionMapper.resolveDrivingClassId(
            moduleCode: 'GW',
            licenceCategory: 'GENERAL',
            questionId: 'AT_GW_021',
          ),
          'GW',
        );

        expect(
          QuestionMapper.resolveDrivingClassId(licenceCategory: 'GENERAL'),
          'GW',
        );

        expect(
          QuestionMapper.resolveDrivingClassId(questionId: 'AT_GW_060'),
          'GW',
        );
      },
    );

    test('Maps B moduleCode and B licenceCategory to B driving class', () {
      expect(
        QuestionMapper.resolveDrivingClassId(
          moduleCode: 'B',
          licenceCategory: 'B',
          questionId: 'AT_B_001',
        ),
        'B',
      );

      expect(QuestionMapper.resolveDrivingClassId(moduleCode: 'B'), 'B');

      expect(QuestionMapper.resolveDrivingClassId(questionId: 'AT_B_032'), 'B');
    });

    test('Preserves unknown future categories without crashing', () {
      expect(QuestionMapper.resolveDrivingClassId(moduleCode: 'A'), 'A');
      expect(QuestionMapper.resolveDrivingClassId(moduleCode: 'C'), 'C');
      expect(QuestionMapper.resolveDrivingClassId(), 'UNKNOWN');
    });
  });

  group('QuestionMapper Question Number Extraction Tests', () {
    test(
      'Extracts integer question numbers from various document ID patterns',
      () {
        expect(QuestionMapper.extractQuestionNumber('AT_GW_021'), 21);
        expect(QuestionMapper.extractQuestionNumber('AT_B_001'), 1);
        expect(QuestionMapper.extractQuestionNumber('AT_B_032'), 32);
        expect(QuestionMapper.extractQuestionNumber('q_1278'), 1278);
      },
    );

    test('Respects explicit question numbers when provided', () {
      expect(QuestionMapper.extractQuestionNumber('AT_GW_021', 1278), 1278);
    });

    test('Falls back to 0 when no digits are found in document ID', () {
      expect(QuestionMapper.extractQuestionNumber('question_no_digits'), 0);
      expect(QuestionMapper.extractQuestionNumber(''), 0);
    });
  });

  group('QuestionMapper Selection Mode & Option Representation Tests', () {
    test('Maps multiple and single selection modes properly', () {
      expect(
        QuestionMapper.parseSelectionMode(selectionMode: 'multiple'),
        QuestionSelectionMode.multiple,
      );
      expect(
        QuestionMapper.parseSelectionMode(selectionMode: 'multi_select'),
        QuestionSelectionMode.multiple,
      );
      expect(
        QuestionMapper.parseSelectionMode(selectionMode: 'single'),
        QuestionSelectionMode.single,
      );
      expect(
        QuestionMapper.parseSelectionMode(questionType: 'single_select'),
        QuestionSelectionMode.single,
      );
    });

    test(
      'Represents unknown selection modes explicitly instead of guessing',
      () {
        expect(
          QuestionMapper.parseSelectionMode(
            selectionMode: 'unknown_future_mode',
          ),
          QuestionSelectionMode.unknown,
        );
        expect(
          QuestionMapper.parseSelectionMode(),
          QuestionSelectionMode.unknown,
        );
      },
    );
  });

  group('QuestionMapper Media & Timestamp Handling Tests', () {
    test('Handles null media without error', () {
      const dto = FirestoreQuestionDto(
        id: 'AT_NO_MEDIA',
        questionText: 'Text only question',
        media: null,
      );

      final domain = QuestionMapper.toDomain(dto);
      expect(domain.mediaUrl, isNull);
      expect(domain.requiresImage, isFalse);
    });

    test('Maps media storagePath or URL to domain mediaUrl', () {
      const dtoWithUrl = FirestoreQuestionDto(
        id: 'AT_WITH_URL',
        questionText: 'Image question',
        requiresImage: true,
        media: FirestoreMediaDto(
          url: 'https://storage.googleapis.com/test.png',
        ),
      );
      expect(
        QuestionMapper.toDomain(dtoWithUrl).mediaUrl,
        'https://storage.googleapis.com/test.png',
      );

      const dtoWithPath = FirestoreQuestionDto(
        id: 'AT_WITH_PATH',
        questionText: 'Image question 2',
        requiresImage: true,
        media: FirestoreMediaDto(storagePath: 'questions/images/AT_GW_021.png'),
      );
      expect(
        QuestionMapper.toDomain(dtoWithPath).mediaUrl,
        'questions/images/AT_GW_021.png',
      );
    });

    test('Parses cloud_firestore.Timestamp and other formats safely', () {
      final now = DateTime.now();
      final firestoreTimestamp = firestore.Timestamp.fromDate(now);

      final jsonWithTimestamp = {
        'id': 'AT_TS_TEST',
        'questionText': 'Timestamp test',
        'createdAt': firestoreTimestamp,
        'updatedAt': '2026-10-31T10:00:00Z',
      };

      final dto = FirestoreQuestionDto.fromJson(jsonWithTimestamp);
      expect(dto.createdAt?.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(dto.updatedAt, isNotNull);

      final jsonWithSeconds = {
        'id': 'AT_SEC_TEST',
        'questionText': 'Seconds map test',
        'createdAt': {'_seconds': 1730000000, '_nanoseconds': 500000000},
      };
      final dto2 = FirestoreQuestionDto.fromJson(jsonWithSeconds);
      expect(dto2.createdAt, isNotNull);
    });
  });

  group('Critical Security Requirement Tests', () {
    test('Domain questions mapped from Firestore NEVER expose answer keys', () {
      const dto = FirestoreQuestionDto(
        id: 'AT_SECURITY_CHECK',
        questionText: 'Verify no correct answer is leaked',
        options: [
          FirestoreOptionDto(id: 'A', text: 'Option A'),
          FirestoreOptionDto(id: 'B', text: 'Option B'),
        ],
      );

      final domain = QuestionMapper.toDomain(dto);

      for (final opt in domain.options) {
        expect(
          opt.isCorrect,
          isNull,
          reason:
              'Public question options must have null isCorrect to prevent client-side answer leakage',
        );
      }
    });

    test(
      'FirestoreQuestionDto does not have correctOptionIds or answers in its fields',
      () {
        // Intentionally verify that neither FirestoreQuestionDto nor FirestoreOptionDto
        // have any correctOptionIds, solution, or explanation fields.
        const opt = FirestoreOptionDto(id: 'A', text: 'Safe Option');
        final optJson = opt.toJson();
        expect(optJson.containsKey('isCorrect'), isFalse);
        expect(optJson.containsKey('correct'), isFalse);

        const dto = FirestoreQuestionDto(
          id: 'SEC_DOC',
          questionText: 'Question text',
        );
        final dtoJson = dto.toJson();
        expect(dtoJson.containsKey('correctOptionIds'), isFalse);
        expect(dtoJson.containsKey('answerKey'), isFalse);
        expect(dtoJson.containsKey('explanation'), isFalse);
      },
    );
  });

  group('FirestoreQuestionSourceDto Tests', () {
    test('Parses Austrian legal source document correctly', () {
      final sourceJson = {
        'id': 'AT_STVO_18',
        'authority': 'RIS – Austrian Legal Information System',
        'title': 'Straßenverkehrsordnung 1960, § 18 – following distance',
        'url': 'https://www.ris.bka.gv.at/NormDokument.wxe?Paragraf=18',
        'legalBasis': 'StVO § 18',
        'note':
            'Requires enough distance to stop if the vehicle ahead brakes suddenly.',
      };

      final source = FirestoreQuestionSourceDto.fromJson(sourceJson);

      expect(source.id, 'AT_STVO_18');
      expect(source.authority, contains('RIS'));
      expect(source.title, contains('following distance'));
      expect(source.legalBasis, 'StVO § 18');
      expect(source.note, contains('enough distance'));
    });
  });

  group('FirestoreQueryStrategy Tests', () {
    test('Builds valid query filter criteria for GW and B classes', () {
      final gwFilter = FirestoreQueryStrategy.buildQuestionsFilter(
        drivingClassId: 'GW',
      );
      expect(gwFilter['moduleCode'], 'GW');
      expect(gwFilter['languageCode'], 'en');
      expect(gwFilter['isActive'], isTrue);
      expect(gwFilter['countryCode'], 'AT');

      final bFilter = FirestoreQueryStrategy.buildQuestionsFilter(
        drivingClassId: 'B',
      );
      expect(bFilter['moduleCode'], 'B');
      expect(bFilter['languageCode'], 'en');
      expect(bFilter['isActive'], isTrue);
      expect(bFilter['countryCode'], 'AT');
    });
  });
}
