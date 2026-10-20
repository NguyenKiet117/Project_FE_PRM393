import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:smartquiz/models/app_notification.dart';
import 'package:smartquiz/models/quiz_result.dart';
import 'package:smartquiz/models/quiz_set.dart';
import 'package:smartquiz/providers/auth_provider.dart';
import 'package:smartquiz/providers/library_provider.dart';
import 'package:smartquiz/providers/notification_provider.dart';
import 'package:smartquiz/providers/quiz_provider.dart';
import 'package:smartquiz/providers/theme_provider.dart';
import 'package:smartquiz/screens/import_screen.dart';
import 'package:smartquiz/screens/notifications_screen.dart';
import 'package:smartquiz/screens/profile_screen.dart';
import 'package:smartquiz/services/api_client.dart';
import 'package:smartquiz/services/auth_service.dart';
import 'package:smartquiz/services/file_picker_service.dart';
import 'package:smartquiz/services/notification_repository.dart';
import 'package:smartquiz/services/quiz_repository.dart';

class _Picker implements FilePickerService {
  PickedFile? file;
  @override
  Future<PickedFile?> pickSpreadsheet() async => file;
}

class _ImportRepo extends FakeQuizRepository {
  @override
  Future<QuizSet> importQuiz({
    required List<int> bytes,
    required String filename,
    String? title,
    String? category,
  }) async =>
      QuizSet(
        id: 'new',
        title: title ?? 'Imported',
        category: category ?? 'General',
        totalQuestions: 2,
        questions: const [],
      );
}

class _BadMarkRepo extends FakeNotificationRepository {
  @override
  Future<void> markRead(String id) async => throw const ApiException('x');
}

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(1080, 2600);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  group('Thông báo (model + provider)', () {
    test('phân loại theo tiêu đề', () {
      AppNotification n(String title) => AppNotification(
          id: '1', title: title, message: '', userId: 'u', timestamp: DateTime.now());
      expect(n('Daily Goal Achieved! 🎯').kind, NotifKind.reminder);
      expect(n('Quiz Completed: Flutter').kind, NotifKind.achievement);
      expect(n('Excel Import Successful').kind, NotifKind.importDone);
      expect(n('New Quiz Available').kind, NotifKind.system);
    });

    test('parseServerTime: chuỗi ISO không múi giờ được coi là UTC', () {
      expect(parseServerTime('2026-10-16T17:34:24').toUtc(), DateTime.utc(2026, 10, 16, 17, 34, 24));
    });

    test('parseServerTime: dạng mảng [y,m,d,h,mi,s]', () {
      expect(parseServerTime([2026, 10, 16, 17, 34, 24]).toUtc(),
          DateTime.utc(2026, 10, 16, 17, 34, 24));
    });

    test('load, đếm chưa đọc, đánh dấu đã đọc', () async {
      final np = NotificationProvider(FakeNotificationRepository());
      await np.load('u');
      expect(np.items.length, 2);
      expect(np.unread, 1);
      expect(np.items.first.id, 'n1'); // mới nhất đứng đầu
      await np.markRead('n1');
      expect(np.unread, 0);
    });

    test('đánh dấu đã đọc thất bại thì hoàn lại', () async {
      final np = NotificationProvider(_BadMarkRepo());
      await np.load('u');
      await np.markRead('n1');
      expect(np.unread, 1);
    });

    test('bộ lọc Nhắc học / Hệ thống', () async {
      final np = NotificationProvider(FakeNotificationRepository());
      await np.load('u');
      np.setFilter(NotifFilter.system);
      expect(np.visible, isEmpty);
      np.setFilter(NotifFilter.study);
      expect(np.visible.length, 2);
    });
  });

  group('Thư viện (provider)', () {
    test('đã lưu, lịch sử và xóa bộ đề', () async {
      final lib = LibraryProvider(repository: FakeQuizRepository());
      await lib.load();
      final id = lib.visible.first.id;

      lib.toggleFavorite(id);
      expect(lib.favorites.map((e) => e.id), [id]);

      lib.recordResult(id, const QuizResult(quizTitle: 'x', items: [], elapsed: Duration.zero));
      expect(lib.history.map((e) => e.id), [id]);

      await lib.deleteQuiz(id);
      expect(lib.byId(id), isNull);
      expect(lib.history, isEmpty);
      expect(lib.favorites, isEmpty);
    });

    test('importQuiz thêm bộ đề mới lên đầu danh sách', () async {
      final lib = LibraryProvider(repository: _ImportRepo(), initial: const []);
      final created = await lib.importQuiz(PickedFile('a.csv', Uint8List.fromList([1])), title: 'Bộ mới');
      expect(created.title, 'Bộ mới');
      expect(lib.visible.first.id, 'new');
    });
  });

  test('ApiClient.postMultipart gửi multipart/form-data', () async {
    String? type;
    final api = ApiClient(
      baseUrl: 'http://test',
      client: MockClient((req) async {
        type = req.headers['content-type'];
        return http.Response(jsonEncode({'success': true, 'data': {'id': 'x'}}), 200,
            headers: {'content-type': 'application/json'});
      }),
    );
    final data = await api.postMultipart('/up',
        fileField: 'file', bytes: [1, 2, 3], filename: 'a.csv', fields: {'title': 't'});
    expect(type, startsWith('multipart/form-data'));
    expect(data, {'id': 'x'});
  });

  group('ImportScreen', () {
    Future<void> open(WidgetTester t, _Picker picker, QuizRepository repo) async {
      _phone(t);
      await t.pumpWidget(ChangeNotifierProvider(
        create: (_) => LibraryProvider(repository: repo, initial: const []),
        child: MaterialApp(home: Scaffold(body: ImportScreen(picker: picker))),
      ));
    }

    testWidgets('chưa chọn file thì nút phân tích bị khóa', (t) async {
      await open(t, _Picker(), _ImportRepo());
      final btn = t.widget<FilledButton>(find.byKey(const Key('btn_import')));
      expect(btn.onPressed, isNull);
    });

    testWidgets('chọn file rồi import thành công', (t) async {
      final picker = _Picker()..file = PickedFile('q.csv', Uint8List.fromList([1, 2, 3]));
      await open(t, picker, _ImportRepo());
      await t.tap(find.byKey(const Key('pick_file')));
      await t.pumpAndSettle();
      expect(find.text('q.csv'), findsOneWidget);

      await t.enterText(find.byKey(const Key('import_title')), 'Bài thử');
      await t.tap(find.byKey(const Key('btn_import')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('import_success')), findsOneWidget);
      expect(find.textContaining('Bài thử'), findsOneWidget);
    });

    testWidgets('chế độ offline: hiện lỗi thay vì treo', (t) async {
      final picker = _Picker()..file = PickedFile('q.csv', Uint8List.fromList([1]));
      await open(t, picker, FakeQuizRepository());
      await t.tap(find.byKey(const Key('pick_file')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('btn_import')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('import_error')), findsOneWidget);
    });
  });

  group('NotificationsScreen', () {
    testWidgets('bấm thông báo -> mất chấm chưa đọc', (t) async {
      _phone(t);
      final np = NotificationProvider(FakeNotificationRepository());
      await np.load('u');
      await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: np),
          ChangeNotifierProvider(create: (_) => AuthProvider(MockAuthService())),
        ],
        child: const MaterialApp(home: Scaffold(body: NotificationsScreen())),
      ));
      expect(find.byKey(const Key('unread_dot_n1')), findsOneWidget);
      await t.tap(find.byKey(const Key('notif_n1')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('unread_dot_n1')), findsNothing);
      expect(np.unread, 0);
    });
  });

  group('ProfileScreen', () {
    Future<(AuthProvider, ThemeProvider)> open(WidgetTester t) async {
      _phone(t);
      // Không gọi signIn(): MockAuthService chờ 800ms bằng Timer, trong testWidgets
      // đồng hồ giả không tự chạy nên sẽ treo mãi. Gán user trực tiếp cho nhanh.
      final auth = AuthProvider(MockAuthService())
        ..user = const AppUser(id: 'u1', name: 'Demo User', email: 'test@quiz.com');
      final theme = ThemeProvider();
      await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider(create: (_) => LibraryProvider(repository: FakeQuizRepository())),
          ChangeNotifierProvider(create: (_) => NotificationProvider(FakeNotificationRepository())),
          ChangeNotifierProvider(create: (_) => QuizProvider()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ));
      return (auth, theme);
    }

    testWidgets('hiện tên người dùng', (t) async {
      await open(t);
      expect(find.text('Demo User'), findsOneWidget);
    });

    testWidgets('bật chế độ tối', (t) async {
      final (_, theme) = await open(t);
      await t.tap(find.byKey(const Key('dark_switch')));
      await t.pump();
      expect(theme.mode, ThemeMode.dark);
    });

    testWidgets('đăng xuất cần xác nhận rồi xóa phiên', (t) async {
      final (auth, _) = await open(t);
      await t.ensureVisible(find.byKey(const Key('btn_logout')));
      await t.tap(find.byKey(const Key('btn_logout')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('logout_confirm')));
      await t.pumpAndSettle();
      expect(auth.user, isNull);
    });
  });
}
