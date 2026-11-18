import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:driving_school_mobile_app/core/config/api_config.dart';
import 'package:driving_school_mobile_app/core/network/api_client.dart';
import 'package:driving_school_mobile_app/core/network/api_exception.dart';
import 'package:driving_school_mobile_app/features/exam_history/data/backend_exam_repository.dart';
import 'package:driving_school_mobile_app/features/learning/data/backend_learning_repository.dart';

void main() {
  group('ApiConfig Tests', () {
    tearDown(() {
      ApiConfig.setBaseUrl(null);
    });

    test('Default baseUrl uses valid URL', () {
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.baseUrl, startsWith('http'));
      expect(ApiConfig.healthUrl, contains('/api/health'));
      expect(ApiConfig.questionsUrl, contains('/api/questions'));
      expect(ApiConfig.examSubmitUrl, contains('/api/exams/submit'));
      expect(ApiConfig.examResultsUrl, contains('/api/exams/results'));
    });

    test('Custom baseUrl override cleans trailing slashes', () {
      ApiConfig.setBaseUrl('http://192.168.1.100:5000///');
      expect(ApiConfig.baseUrl, equals('http://192.168.1.100:5000'));
      expect(
        ApiConfig.questionByIdUrl('AT_GW_021'),
        equals('http://192.168.1.100:5000/api/questions/AT_GW_021'),
      );
      expect(
        ApiConfig.examResultByIdUrl('att_123'),
        equals('http://192.168.1.100:5000/api/exams/results/att_123'),
      );
    });
  });

  group('ApiClient Tests', () {
    test('Injects Authorization Bearer token when token provider supplies one', () async {
      String? capturedAuthHeader;

      final mockHttp = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response(
          jsonEncode({'status': 'healthy', 'success': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        httpClient: mockHttp,
        tokenProvider: ({bool forceRefresh = false}) async => 'mock-jwt-token-12345',
      );

      final isHealthy = await client.checkHealth();
      expect(isHealthy, isTrue);
      expect(capturedAuthHeader, equals('Bearer mock-jwt-token-12345'));
    });

    test('Omits Authorization Bearer token when unauthenticated', () async {
      String? capturedAuthHeader;

      final mockHttp = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response(
          jsonEncode({'status': 'healthy'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        httpClient: mockHttp,
        tokenProvider: ({bool forceRefresh = false}) async => null,
      );

      await client.checkHealth();
      expect(capturedAuthHeader, isNull);
    });

    test('Refreshes token on 401 and succeeds if refreshed token is accepted', () async {
      int requestCount = 0;
      final tokensSupplied = <String>[];

      final mockHttp = MockClient((request) async {
        requestCount++;
        final auth = request.headers['Authorization'];
        if (auth == 'Bearer old-token') {
          return http.Response(
            jsonEncode({'success': false, 'error': 'Unauthorized', 'message': 'Token expired'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'data': {'user': 'verified'}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        httpClient: mockHttp,
        tokenProvider: ({bool forceRefresh = false}) async {
          final t = forceRefresh ? 'fresh-refreshed-token' : 'old-token';
          tokensSupplied.add(t);
          return t;
        },
      );

      final res = await client.get('http://test/api/auth/me');
      expect(requestCount, equals(2));
      expect(tokensSupplied, equals(['old-token', 'fresh-refreshed-token']));
      expect(res['success'], isTrue);
    });

    test('Throws ApiException with status code and details if 401 persists after refresh', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'Unauthorized',
            'message': 'Invalid Firebase ID token',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        httpClient: mockHttp,
        tokenProvider: ({bool forceRefresh = false}) async => 'bad-token',
      );

      expect(
        () => client.get('http://test/api/auth/me'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)
              .having((e) => e.message, 'message', contains('Invalid Firebase ID token')),
        ),
      );
    });

    test('Throws ApiException on 422 Unprocessable Entity (e.g. invalid exam mode)', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'Unprocessable Entity',
            'message': 'Official exam mode cannot be scored with incomplete metadata',
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(httpClient: mockHttp);

      expect(
        () => client.post('http://test/api/exams/submit', body: {'examMode': 'official'}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.isUnprocessable, 'isUnprocessable', isTrue),
        ),
      );
    });
  });

  group('BackendLearningRepository Pagination & Question Loading Tests', () {
    test('Respects backend max limit 50 and handles multi-page cursor pagination', () async {
      int pageCount = 0;

      final mockHttp = MockClient((request) async {
        pageCount++;
        final limit = request.url.queryParameters['limit'];
        expect(int.parse(limit!), lessThanOrEqualTo(50));
        expect(request.url.queryParameters['moduleCode'], equals('GW'));

        final cursor = request.url.queryParameters['cursor'];

        if (cursor == null) {
          // Page 1: returns first 2 questions, indicates hasMore=true, nextCursor='AT_GW_022'
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'AT_GW_021',
                  'questionText': 'Question 1',
                  'moduleCode': 'GW',
                  'licenceCategory': 'GENERAL',
                  'languageCode': 'en',
                  'topic': 'general',
                  'options': [{'id': 'opt_1', 'text': 'Option 1'}],
                  'requiresImage': false,
                },
                {
                  'id': 'AT_GW_022',
                  'questionText': 'Question 2',
                  'moduleCode': 'GW',
                  'licenceCategory': 'GENERAL',
                  'languageCode': 'en',
                  'topic': 'general',
                  'options': [{'id': 'opt_1', 'text': 'Option 1'}],
                  'requiresImage': false,
                },
              ],
              'pagination': {
                'limit': 50,
                'totalReturned': 2,
                'hasMore': true,
                'nextCursor': 'AT_GW_022',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          // Page 2: returns third question, indicates hasMore=false
          expect(cursor, equals('AT_GW_022'));
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'AT_GW_023',
                  'questionText': 'Question 3',
                  'moduleCode': 'GW',
                  'licenceCategory': 'GENERAL',
                  'languageCode': 'en',
                  'topic': 'general',
                  'options': [{'id': 'opt_1', 'text': 'Option 1'}],
                  'requiresImage': false,
                },
              ],
              'pagination': {
                'limit': 50,
                'totalReturned': 1,
                'hasMore': false,
                'nextCursor': null,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = BackendLearningRepository(apiClient: apiClient);

      final questions = await repo.getQuestions(drivingClassId: 'GW');
      expect(pageCount, equals(2));
      expect(questions.length, equals(3));
      expect(questions.map((q) => q.id).toList(), equals(['AT_GW_021', 'AT_GW_022', 'AT_GW_023']));
      // Verify public questions do NOT have answer keys
      expect(questions.every((q) => q.options.every((o) => o.isCorrect == null)), isTrue);
    });

    test('getLearningUnits groups questions by topic correctly', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'AT_GW_021',
                'questionText': 'Q1',
                'moduleCode': 'GW',
                'topic': 'speed_limits',
                'options': [{'id': '1', 'text': 'A'}],
              },
              {
                'id': 'AT_GW_022',
                'questionText': 'Q2',
                'moduleCode': 'GW',
                'topic': 'speed_limits',
                'options': [{'id': '1', 'text': 'A'}],
              },
              {
                'id': 'AT_GW_023',
                'questionText': 'Q3',
                'moduleCode': 'GW',
                'topic': 'right_of_way',
                'options': [{'id': '1', 'text': 'A'}],
              },
            ],
            'pagination': {'hasMore': false},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repo = BackendLearningRepository(apiClient: apiClient);

      final units = await repo.getLearningUnits(drivingClassId: 'GW');
      expect(units.length, equals(2));
      expect(units.any((u) => u.title == 'Speed Limits' && u.totalQuestions == 2), isTrue);
      expect(units.any((u) => u.title == 'Right Of Way' && u.totalQuestions == 1), isTrue);
    });
  });

  group('BackendExamRepository Tests', () {
    test('submitExamAnswers sends practice payload with idempotent submissionId', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/api/exams/submit')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['moduleCode'], equals('GW'));
          expect(body['examMode'], equals('practice'));
          expect(body['submissionId'], equals('custom_sub_id_100'));

          return http.Response(
            jsonEncode({
              'success': true,
              'isDuplicate': false,
              'data': {
                'attemptId': 'att_backend_999',
                'submissionId': 'custom_sub_id_100',
                'moduleCode': 'GW',
                'examMode': 'practice',
                'status': 'completed',
                'totalQuestions': 42,
                'correctQuestions': 40,
                'awardedPoints': 40,
                'maxPoints': 42,
                'percentage': 95.24,
                'passed': true,
                'scoringModeLabel': 'Practice Mode',
                'submittedAt': '2026-11-17T12:00:00.000Z',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final learningRepo = BackendLearningRepository(apiClient: apiClient);
      final examRepo = BackendExamRepository(
        apiClient: apiClient,
        learningRepository: learningRepo,
      );

      final attempt = await examRepo.submitExamAnswers(
        moduleCode: 'GW',
        submissionId: 'custom_sub_id_100',
        answers: {
          'AT_GW_021': {'opt_1', 'opt_2'},
        },
      );

      expect(attempt.id, equals('att_backend_999'));
      expect(attempt.totalQuestions, equals(42));
      expect(attempt.pointsScored, equals(40));
      expect(attempt.scorePercentage, closeTo(95.24, 0.01));
      expect(attempt.isPassed, isTrue);
      expect(attempt.selectedClasses, equals(['GW']));
    });

    test('getExamHistory propagates API failure rather than silently swallowing', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'error': 'Server Error', 'message': 'Internal database issue'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final learningRepo = BackendLearningRepository(apiClient: apiClient);
      final examRepo = BackendExamRepository(
        apiClient: apiClient,
        learningRepository: learningRepo,
      );

      expect(
        () => examRepo.getExamHistory(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('getExamHistory parses attempt list from backend and sorts newest first', () async {
      final mockHttp = MockClient((request) async {
        expect(request.url.path, contains('/api/exams/results'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'attemptId': 'att_1',
                'moduleCode': 'GW',
                'totalQuestions': 42,
                'correctQuestions': 35,
                'awardedPoints': 35,
                'percentage': 83.3,
                'passed': true,
                'submittedAt': '2026-11-17T10:00:00.000Z',
              },
              {
                'attemptId': 'att_2',
                'moduleCode': 'B',
                'totalQuestions': 32,
                'correctQuestions': 20,
                'awardedPoints': 20,
                'percentage': 62.5,
                'passed': false,
                'submittedAt': '2026-11-17T11:00:00.000Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final learningRepo = BackendLearningRepository(apiClient: apiClient);
      final examRepo = BackendExamRepository(
        apiClient: apiClient,
        learningRepository: learningRepo,
      );

      final history = await examRepo.getExamHistory();
      expect(history.length, equals(2));
      expect(history.first.id, equals('att_2'));
      expect(history.first.selectedClasses, equals(['B']));
      expect(history.first.isPassed, isFalse);

      expect(history.last.id, equals('att_1'));
      expect(history.last.isPassed, isTrue);
    });

    test('checkQuestionAnswer sends selected option IDs to backend and returns verification result', () async {
      final mockHttp = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, contains('/api/questions/AT_GW_021/check'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['selectedOptionIds'], equals(['opt_1']));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'questionId': 'AT_GW_021',
              'isCorrect': true,
              'correctOptionIds': ['opt_1'],
              'explanation': 'Correct speed limit in urban areas.',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final learningRepo = BackendLearningRepository(apiClient: apiClient);

      final result = await learningRepo.checkQuestionAnswer(
        questionId: 'AT_GW_021',
        selectedOptionIds: ['opt_1'],
      );

      expect(result.questionId, equals('AT_GW_021'));
      expect(result.isCorrect, isTrue);
      expect(result.correctOptionIds, equals(['opt_1']));
      expect(result.explanation, equals('Correct speed limit in urban areas.'));
    });
  });
}
