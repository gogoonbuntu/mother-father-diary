import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  final String apiKey;
  final String endpoint;

  GeminiService({required this.apiKey, this.endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'});

  Future<String?> getPositiveVersion(String originalText) async {
    final url = Uri.parse('$endpoint?key=$apiKey');

    final prompt = '''
아래의 문장을 '오히려 좋아', '이런 불행이 오히려 나에게 행운을 가져다줄 거야', '재치있고 새로운 발상', '유머러스', '감사' 등 다양한 시선으로 재치있고 기발하게 긍정적으로 바꿔줘. 단순히 긍정적으로만 바꾸지 말고, 예상치 못한 관점이나 유머, 감사, 반전, 위트 등을 적극 활용해서 창의적으로 바꿔줘.

예시)
- "머리가 아파." → "그래도 다른 곳은 멀쩡하니 얼마나 다행이야! 오늘은 뇌도 휴식이 필요했나봐."
- "비가 와서 우울해." → "비가 오니 공기가 깨끗해지고, 집에서 책 읽기 딱 좋은 날이네!"
- "실패했다." → "실패 덕분에 더 멋진 성공이 기다리고 있을 거야! 오히려 좋아!"

그리고 반드시 입력 문장의 언어와 결과 문장의 언어가 같아야 해.
그리고 총 인풋과 아웃풋의 총 문장 길이도 대략 비슷해야해. 
결과(변환된 문장)만 출력하고, 설명이나 해설은 절대 하지 마.

$originalText
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    debugPrint('[GeminiService] 요청 URL: $url');
    debugPrint('[GeminiService] 요청 바디: $body');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    debugPrint('[GeminiService] 응답 코드: ${response.statusCode}');
    debugPrint('[GeminiService] 응답 바디: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String?;
        }
      }
    }
    return null;
  }
}
