import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 임시 데이터
    final List<Map<String, String>> previousRecommendations = [
      {"food": "김치찌개", "date": "2024-11-25"},
      {"food": "된장찌개", "date": "2024-11-24"},
      {"food": "비빔밥", "date": "2024-11-23"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Best 추천 요리 List"),
      ),
      body: ListView.builder(
        itemCount: previousRecommendations.length,
        itemBuilder: (context, index) {
          final recommendation = previousRecommendations[index];
          return ListTile(
            title: Text(recommendation["food"]!),
            subtitle: Text("추천받은 날짜: ${recommendation["date"]}"),
          );
        },
      ),
    );
  }
}
