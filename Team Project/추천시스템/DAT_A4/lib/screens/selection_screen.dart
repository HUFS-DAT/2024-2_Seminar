import 'package:flutter/material.dart';

class SelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("오늘은 어떤 요리를 먹을까?"),
      ),
      body: Center(
        // 전체 내용을 중앙에 배치
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center, // 가로 중앙 정렬
            children: [
              Text(
                "새로운 요리를 도전해볼까?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center, // 텍스트 중앙 정렬
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/chat'); // 음식 추천 페이지로 이동
                },
                child: Text("음식 추천받기"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/history'); // 이전 음식 확인 페이지로 이동
                },
                child: Text("이전 추천 음식"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
