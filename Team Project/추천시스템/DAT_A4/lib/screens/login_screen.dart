import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/selection'); // 선택 페이지로 이동
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("로그인 실패: ${e.toString()}"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이메일 입력 필드
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "email"),
            ),

            // 비밀번호 입력 필드
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "password"),
              obscureText: true,
            ),
            SizedBox(height: 30),

            // 버튼을 좌우로 배치
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 로그인 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _login(context),
                    child: Text("로그인"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 85, 145, 241), // 배경색 (로그인 전용)
                      textStyle:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 20), // 버튼 간 간격

                // 회원가입 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup'); // 회원가입 화면으로 이동
                    },
                    child: Text("회원가입"),
                    style: OutlinedButton.styleFrom(
                      textStyle:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
