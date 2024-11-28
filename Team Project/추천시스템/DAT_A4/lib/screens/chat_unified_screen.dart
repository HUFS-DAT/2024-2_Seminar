import 'package:flutter/material.dart';
import 'question_mode.dart';
import 'chat_mode.dart';

class ChatUnifiedScreen extends StatefulWidget {
  @override
  _ChatUnifiedScreenState createState() => _ChatUnifiedScreenState();
}

class _ChatUnifiedScreenState extends State<ChatUnifiedScreen> {
  bool _isQuestionMode = true; // 현재 모드 상태
  final List<Map<String, dynamic>> _messages = []; // 공통 메시지 리스트
  final List<String> _recentFoodNames = []; // 최근 음식 정보 저장
  Map<String, dynamic> _userPreferences = {}; // 사용자 질문 응답 저장

  void _switchToChatMode(Map<String, dynamic> answers) {
    setState(() {
      _isQuestionMode = false; // 일반 채팅 모드로 전환
      _userPreferences = answers; // 유저 선택을 저장
    });

    // 최근 음식 정보 업데이트
    if (answers.containsKey("images")) {
      _recentFoodNames.addAll(List<String>.from(answers["images"]));
    }

    // Bot: 질문 완료 메시지 추가
    _messages.add({
      "role": "bot",
      "text": "질문이 완료되었습니다. 이제 자유롭게 대화하세요!",
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Recommend Cooking Recipe")),
      body: _isQuestionMode
          ? QuestionMode(
              onComplete: _switchToChatMode, // 질문 완료 시 실행
              messages: _messages,
            )
          : ChatMode(
              recentFoodNames: _recentFoodNames, // 최근 음식 이름 리스트
              onComplete: (result) {}, // 완료 콜백 처리
              messages: _messages, // 공통 메시지 전달
              userPreferences: _userPreferences, // 사용자 선택 전달
            ),
    );
  }
}
