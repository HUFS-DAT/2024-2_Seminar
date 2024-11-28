import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

const String apiKey =
    "your_api_keys";
final Uri url = Uri.https("api.openai.com", "/v1/chat/completions");

/// 텍스트 기반 ChatGPT 응답 가져오기
Future<String> fetchChatBotResponse(String userInput) async {
  final response = await http.post(
    url,
    headers: {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": userInput},
      ],
    }),
  );

  if (response.statusCode == 200) {
    final decodedBody = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decodedBody);
    return data['choices'][0]['message']['content'];
  } else {
    return "에러가 발생했습니다. 다시 시도해주세요.";
  }
}

/// 이미지 URL 기반 음식 설명 가져오기
Future<String> analyzeImage(String base64Image) async {
  log("API 요청 시작 - Base64 이미지 데이터 전송");
  try {
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a food expert. Based on the provided image, respond strictly with only the name of the dish."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "What is the name of the dish in this image?"
              },
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
              }
            ]
          }
        ],
        "max_tokens": 20,
      }),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      final dishName = data['choices'][0]['message']['content']?.trim();
      log("GPT API 응답 성공: $dishName");

      return dishName.isNotEmpty ? dishName : "Dish name unknown";
    } else {
      log("GPT API 응답 실패: ${response.body}");
      return "Dish name unknown";
    }
  } catch (e) {
    log("API 요청 중 오류 발생: $e");
    return "Dish name unknown";
  }
}

/// 음식 추천 요청
Future<List<String>> getFoodRecommendations(
    List<String> recentFoods, Map<String, dynamic> userPreferences) async {
  // 최근 먹은 음식 메시지 구성
  final String recentFoodMessage =
      "사용자가 최근에 즐겼던 음식: ${recentFoods.join(', ')}.";

  // 선택 정보 메시지 구성
  final String preferencesMessage = userPreferences.entries
      .map((entry) => "${entry.key}: ${entry.value}")
      .join(', ');

  final List<Map<String, String>> messages = [
    {
      "role": "system",
      "content": "당신은 사용자의 입맛, 선호도 및 상황을 기반으로 음식을 추천하는 전문가입니다."
    },
    {"role": "user", "content": recentFoodMessage},
    {"role": "user", "content": "현재 상태: $preferencesMessage."},
    {
      "role": "user",
      "content": "위 정보를 바탕으로 설명 없이 5가지 추천 요리를 제안해주세요. 각 요리의 이름만 한 줄로 작성하세요."
    }
  ];

  final response = await http.post(
    url,
    headers: {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": messages,
      "max_tokens": 150,
    }),
  );

  if (response.statusCode == 200) {
    final decodedBody = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decodedBody);
    final String content = data['choices'][0]['message']['content'];

    // 추천된 음식 리스트 반환
    return content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();
  } else {
    throw Exception("추천 요청 실패: ${response.body}");
  }
}

/// 음식 레시피 요청
Future<String> getRecipeForFood(
    String foodName, Map<String, dynamic> userPreferences) async {
  // 선택 정보 메시지 구성
  final String preferencesMessage = userPreferences.entries
      .map((entry) => "${entry.key}: ${entry.value}")
      .join(', ');

  final List<Map<String, String>> messages = [
    {"role": "system", "content": "당신은 사용자가 요청한 요리의 상세 레시피를 제공하는 음식 전문가입니다."},
    {"role": "user", "content": "현재 상태: $preferencesMessage."},
    {"role": "user", "content": "$foodName에 대한 자세한 레시피를 제공해주세요."}
  ];

  final response = await http.post(
    url,
    headers: {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": messages,
      "max_tokens": 800,
    }),
  );

  if (response.statusCode == 200) {
    final decodedBody = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decodedBody);
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception("레시피 요청 실패: ${response.body}");
  }
}
