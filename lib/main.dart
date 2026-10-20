import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/library_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/notification_repository.dart';
import 'services/quiz_repository.dart';
import 'services/remote_auth_service.dart';

void main() {
  final api = ApiClient(baseUrl: kApiBaseUrl);
  final AuthService auth = kUseMock ? MockAuthService() : RemoteAuthService(api);
  final QuizRepository quizzes = kUseMock ? FakeQuizRepository() : RemoteQuizRepository(api);
  final NotificationRepository notifs =
      kUseMock ? FakeNotificationRepository() : RemoteNotificationRepository(api);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(auth)),
        ChangeNotifierProvider(create: (_) => LibraryProvider(repository: quizzes)),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notifs)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const SmartQuizApp(),
    ),
  );
}

class SmartQuizApp extends StatelessWidget {
  const SmartQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartQuiz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: context.watch<ThemeProvider>().mode,
      home: Consumer<AuthProvider>(
        builder: (_, auth, _) =>
            auth.user == null ? const AuthScreen() : const MainShell(),
      ),
    );
  }
}
