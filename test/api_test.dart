import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartquiz/data/dto_mappers.dart';
import 'package:smartquiz/models/quiz_set.dart';
import 'package:smartquiz/providers/library_provider.dart';
import 'package:smartquiz/services/api_client.dart';
import 'package:smartquiz/services/auth_service.dart';
import 'package:smartquiz/services/quiz_repository.dart';
import 'package:smartquiz/services/remote_auth_service.dart';

ApiClient _api(Object body, {int status = 200, void Function(http.Request)? onRequest}) =>
    ApiClient(
      baseUrl: 'http://test',
      client: MockClient((req) async {
        onRequest?.call(req);
        return http.Response(jsonEncode(body), status,
            headers: {'content-type': 'application/json'});
      }),
    );

Map<String, dynamic> _ok(Object? data) =>
    {'success': true, 'message': 'ok', 'data': data};

class _FailingRepo extends FakeQuizRepository {
  @override
  Future<List<QuizSet>> fetchQuizzes() async =>
      throw const ApiException('Khong ket noi duoc');
}

void main() {
  group('ApiClient', () {
    test('trả về phần data', () async {
      final api = _api(_ok({'x': 1}));
      expect(await api.get('/a'), {'x': 1});
    });

    test('success=false -> ApiException mang message của server', () async {
      final api = _api({'success': false, 'message': 'Bad thing'});
      await expectLater(() => api.get('/a'),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bad thing')));
    });

    test('HTTP 400 -> ApiException', () async {
      final api = _api({'success': false, 'message': 'Invalid'}, status: 400);
      await expectLater(() => api.post('/a', body: {}),
          throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)));
    });

    test('gắn Bearer token khi đã đăng nhập', () async {
      String? auth;
      final api = _api(_ok(null), onRequest: (r) => auth = r.headers['Authorization']);
      api.token = 'abc';
      await api.get('/a');
      expect(auth, 'Bearer abc');
    });
  });

  group('Mapper DTO -> model', () {
    final dto = {
      'id': 'q1',
      'questionText': 'What is Dart?',
      'optionA': 'A language',
      'optionB': 'A bird',
      'optionC': 'A fruit',
      'optionD': 'A city',
      'correctAnswer': 'C',
      'correctAnswerText': 'A fruit',
      'explanation': '  ',
    };

    test('đáp án đúng theo chữ cái', () {
      final q = questionFromDto(dto, category: 'Flutter');
      expect(q.options.length, 4);
      expect(q.correctIndex, 2);
      expect(q.explanation, isNull); // chuỗi rỗng -> null
      expect(q.category, 'Flutter');
    });

    test('thiếu chữ cái thì dò theo correctAnswerText', () {
      final q = questionFromDto({...dto, 'correctAnswer': null, 'correctAnswerText': 'a bird'});
      expect(q.correctIndex, 1);
    });

    test('danh sách (không có câu hỏi) dùng totalQuestions', () {
      final set = quizSetFromDto({
        'id': 's1',
        'title': 'T',
        'category': 'C',
        'totalQuestions': 7,
        'timeLimitMinutes': 10,
        'questions': [],
      });
      expect(set.hasQuestions, isFalse);
      expect(set.length, 7);
      expect(set.timeLimit, const Duration(minutes: 10));
    });

    test('chi tiết có câu hỏi, bỏ câu không hợp lệ', () {
      final set = quizSetFromDto({
        'id': 's1',
        'title': 'T',
        'category': 'C',
        'questions': [dto, {'id': 'bad', 'questionText': 'x', 'optionA': 'only one'}],
      });
      expect(set.length, 1);
    });
  });

  group('RemoteAuthService', () {
    test('login thành công -> AppUser + lưu token', () async {
      final api = _api(_ok({
        'token': 'jwt',
        'id': 'u1',
        'fullName': 'Alex',
        'email': 'a@b.com',
        'currentStreak': 5,
      }));
      final user = await RemoteAuthService(api).signIn(email: 'a@b.com', password: '123456');
      expect(user.id, 'u1');
      expect(user.streak, 5);
      expect(api.token, 'jwt');
    });

    test('lỗi server -> AuthException', () async {
      final api = _api({'success': false, 'message': 'Invalid credentials'}, status: 401);
      await expectLater(() => RemoteAuthService(api).signIn(email: 'a@b.com', password: 'x'),
          throwsA(isA<AuthException>()));
    });
  });

  group('RemoteQuizRepository / LibraryProvider', () {
    test('submit trả về streak mới', () async {
      final api = _api(_ok({'updatedStreak': 6, 'scorePercentage': 80.0}));
      final ack = await RemoteQuizRepository(api)
          .submit(quizId: 'q', userId: 'u', answers: {'1': 'A'});
      expect(ack?.updatedStreak, 6);
    });

    test('load thành công', () async {
      final lib = LibraryProvider(repository: FakeQuizRepository());
      expect(lib.state, LoadState.idle);
      await lib.load();
      expect(lib.state, LoadState.loaded);
      expect(lib.totalQuizzes, greaterThan(0));
    });

    test('load lỗi -> state error + thông báo', () async {
      final lib = LibraryProvider(repository: _FailingRepo());
      await lib.load();
      expect(lib.state, LoadState.error);
      expect(lib.error, 'Khong ket noi duoc');
    });
  });
}
