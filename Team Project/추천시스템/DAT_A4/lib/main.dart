import 'package:flutter/material.dart';
import 'screens/chat_unified_screen.dart';
import 'screens/setting_screen.dart';
import 'screens/login_screen.dart'; // 로그인 화면
import 'screens/signup_screen.dart'; // 회원가입 화면
import 'screens/selection_screen.dart'; // 새로운 선택 페이지
import 'screens/history_screen.dart'; // 이전 음식 보기 페이지
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ChatBotApp());
}

class ChatBotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChatBot App',
      initialRoute: '/', // 초기 화면 경로 설정
      onGenerateRoute: (settings) {
        final user = FirebaseAuth.instance.currentUser;

        switch (settings.name) {
          case '/':
            // 로그인 여부에 따라 선택 페이지 또는 로그인 페이지로 이동
            return MaterialPageRoute(
              builder: (context) =>
                  user == null ? LoginScreen() : SelectionScreen(),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (context) => LoginScreen(),
            );
          case '/signup':
            return MaterialPageRoute(
              builder: (context) => SignUpScreen(),
            );
          case '/selection':
            return MaterialPageRoute(
              builder: (context) =>
                  user == null ? LoginScreen() : SelectionScreen(),
            );
          case '/chat':
            return MaterialPageRoute(
              builder: (context) =>
                  user == null ? LoginScreen() : ChatUnifiedScreen(),
            );
          case '/history':
            return MaterialPageRoute(
              builder: (context) =>
                  user == null ? LoginScreen() : HistoryScreen(),
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (context) =>
                  user == null ? LoginScreen() : SettingsScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => LoginScreen(), // 기본적으로 로그인 화면
            );
        }
      },
    );
  }
}
