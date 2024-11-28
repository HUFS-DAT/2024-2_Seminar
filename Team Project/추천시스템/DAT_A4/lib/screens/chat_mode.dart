import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import '../services/api_service.dart'; // API 요청 관련 코드
import 'dart:convert';

class ChatMode extends StatefulWidget {
  final List<String> recentFoodNames; // 이미지 분석 결과로 얻은 음식 이름 리스트
  final Function(Map<String, dynamic>) onComplete;
  final List<Map<String, dynamic>> messages; // 추가: 메시지 리스트
  final Map<String, dynamic> userPreferences; // 사용자 선택 정보
  ChatMode({
    required this.recentFoodNames,
    required this.onComplete,
    required this.messages, // 추가
    required this.userPreferences, // 사용자 선택 정보 추가
  });

  @override
  _ChatModeState createState() => _ChatModeState();
}

class _ChatModeState extends State<ChatMode> {
  List<String> _recommendedFoods = []; // 추천된 음식 리스트
  String _selectedRecipe = ""; // 선택된 음식의 레시피
  String _selectedFood = ""; // 사용자가 선택한 음식
  bool _loadingRecommendations = false;
  bool _loadingRecipe = false;

  late List<Map<String, dynamic>> _messages; // 메시지 리스트

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firebase에 추천 결과 저장
  Future<void> _saveToFirebase(List<String> recommendations,
      String selectedFood, String selectedRecipe) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .add({
        'recommendations': recommendations,
        'selectedFood': selectedFood,
        'selectedRecipe': selectedRecipe,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Firebase 저장 실패: $e");
    }
  }

  /// 음식 추천 요청
  Future<void> _fetchRecommendations() async {
    setState(() {
      _loadingRecommendations = true;
    });

    try {
      final recommendations = await getFoodRecommendations(
        widget.recentFoodNames,
        widget.userPreferences,
      );
      setState(() {
        _recommendedFoods = recommendations;
        _loadingRecommendations = false;
      });
    } catch (e) {
      print("음식 추천 요청 실패: $e");
      setState(() {
        _loadingRecommendations = false;
      });
    }
  }

  /// 음식 레시피 요청
  Future<void> _fetchRecipe(String foodName) async {
    setState(() {
      _loadingRecipe = true;
      _selectedFood = foodName; // 사용자가 선택한 음식 설정
    });

    try {
      final recipe = await getRecipeForFood(foodName, widget.userPreferences);
      setState(() {
        _selectedRecipe = recipe;
        _loadingRecipe = false;
      });

      // Firebase에 저장
      await _saveToFirebase(_recommendedFoods, foodName, recipe);
    } catch (e) {
      print("레시피 요청 실패: $e");
      setState(() {
        _loadingRecipe = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRecommendations(); // 컴포넌트 초기화 시 추천 요청
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("요리 추천")),
      body: Column(
        children: [
          if (_loadingRecommendations)
            Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView.builder(
                itemCount: _recommendedFoods.length,
                itemBuilder: (context, index) {
                  final food = _recommendedFoods[index];
                  return ListTile(
                    title: Text(food),
                    onTap: () => _fetchRecipe(food), // 음식 선택 시 레시피 요청
                  );
                },
              ),
            ),
          if (_loadingRecipe)
            Center(child: CircularProgressIndicator())
          else if (_selectedRecipe.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Text(
                    "--- 최종 추천 ---\n\n"
                    "추천 음식: $_selectedFood\n\n"
                    "$_selectedRecipe",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
