import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb 사용
import 'image_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import '../services/api_service.dart';

class QuestionMode extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;
  final List<Map<String, dynamic>> messages;

  QuestionMode({required this.onComplete, required this.messages});

  @override
  _QuestionModeState createState() => _QuestionModeState();
}

class _QuestionModeState extends State<QuestionMode> {
  final List<Map<String, dynamic>> _questions = [
    {
      "type": "text",
      "question": "주 식재료를 입력해주세요.",
      "key": "mainIngredient",
    },
    {
      "type": "text",
      "question": "알러지가 있는 재료를 입력해주세요.",
      "key": "allergy",
    },
    {
      "type": "choice",
      "question": "매운 정도를 선택해주세요.",
      "choices": ["매운거", "안매운거", "상관없음"],
      "key": "spiciness",
    },
    {
      "type": "choice",
      "question": "온도를 선택해주세요.",
      "choices": ["차가운거", "뜨거운거", "상관없음"],
      "key": "temperature",
    },
    {
      "type": "choice",
      "question": "요리 시간을 선택해주세요.",
      "choices": ["30분 이내", "1시간 이후"],
      "key": "cookingTime",
    },
    {
      "type": "choice",
      "question": "언제 드시는지 선택해주세요.",
      "choices": ["아침", "점심", "저녁", "야식"],
      "key": "mealType",
    },
    {
      "type": "image",
      "question": "맛있게 드셨던 음식 이미지를 5장 업로드해주세요.",
      "key": "images",
    },
  ];

  final Map<String, dynamic> _answers = {};
  final TextEditingController _controller = TextEditingController();
  int _currentQuestionIndex = 0;
  bool _readyToSend = false; // 전송 버튼 활성화 상태

  final ImageHandler _imageHandler = ImageHandler(); // 이미지 처리 클래스 인스턴스 생성

  void _showNextQuestion() {
    if (_currentQuestionIndex >= _questions.length) {
      widget.onComplete(_answers);
      return;
    }

    final question = _questions[_currentQuestionIndex];
    widget.messages.add({
      "role": "bot",
      "text": question["question"],
    });
    setState(() {});
  }

  void _handleAnswer(String key, dynamic answer) {
    _answers[key] = answer;
    widget.messages.add({
      "role": "user",
      "text": answer.toString(),
    });
    _controller.clear();
    _currentQuestionIndex++;
    _showNextQuestion();
  }

  Future<void> _pickImage(String key) async {
    final bool success = await _imageHandler.pickImages();
    if (success) {
      setState(() {
        _readyToSend = true; // 전송 버튼 활성화
      });
    } else {
      widget.messages.add({
        "role": "bot",
        "text": "5장의 이미지를 한 번에 선택해주세요.",
      });
      setState(() {}); // 채팅 메시지 갱신
    }
  }

  Future<void> _sendImages(String key) async {
    if (_readyToSend) {
      try {
        // 선택된 이미지를 Base64로 변환
        final List<String> base64Images =
            await _imageHandler.resizeAndConvertToBase64();

        List<String> dishNames = [];
        for (final base64Image in base64Images) {
          if (base64Image.isEmpty) {
            dishNames.add("분석 실패");
            continue;
          }

          // api_service의 analyzeImage 호출
          final dishName = await analyzeImage(base64Image);
          dishNames.add(dishName);
        }

        widget.messages.add({
          "role": "bot",
          "text": "이런 음식을 맛있게 드셨군요? :\n${dishNames.join("\n")}",
        });

        _answers[key] = dishNames;

        // 이미지 초기화 및 상태 갱신
        _imageHandler.clearImages();
        _readyToSend = false;
        _currentQuestionIndex++;
        _showNextQuestion();
      } catch (e) {
        widget.messages.add({
          "role": "bot",
          "text": "이미지 분석 중 오류 발생: $e",
        });
        setState(() {});
      }
    }
  }

  Widget _buildQuestionUI() {
    final currentQuestion = _currentQuestionIndex < _questions.length
        ? _questions[_currentQuestionIndex]
        : null;

    if (currentQuestion == null) return SizedBox.shrink();

    if (currentQuestion["type"] == "choice") {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentQuestion["question"],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: currentQuestion["choices"]
                  .map<Widget>(
                    (choice) => ElevatedButton(
                      onPressed: () {
                        _handleAnswer(currentQuestion["key"], choice);
                      },
                      child: Text(choice),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    } else if (currentQuestion["type"] == "image") {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentQuestion["question"],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _pickImage(currentQuestion["key"]);
              },
              child: Text("이미지 선택"),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: _imageHandler.selectedImages
                  .map(_imageHandler.buildImagePreview)
                  .toList(),
            ),
            if (_readyToSend)
              ElevatedButton(
                onPressed: () => _sendImages(currentQuestion["key"]),
                child: Text("전송"),
              ),
          ],
        ),
      );
    }

    // 텍스트 입력 질문
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        currentQuestion["question"],
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  bool _isTextInputAllowed() {
    final currentQuestion = _questions[_currentQuestionIndex];
    return currentQuestion["type"] == "text";
  }

  Widget _buildMessageWidget(Map<String, dynamic> message) {
    // 기본 텍스트 메시지 렌더링
    final isUser = message["role"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(message["text"] ?? ""),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _showNextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 채팅 메시지 표시
          Expanded(
            child: ListView.builder(
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                return _buildMessageWidget(widget.messages[index]);
              },
            ),
          ),
          // 질문 UI 표시
          _buildQuestionUI(),
          // 채팅 입력창
          if (_isTextInputAllowed())
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          final currentQuestion =
                              _questions[_currentQuestionIndex];
                          _handleAnswer(currentQuestion["key"], value);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "답변을 입력하세요...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        final currentQuestion =
                            _questions[_currentQuestionIndex];
                        _handleAnswer(currentQuestion["key"], _controller.text);
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
