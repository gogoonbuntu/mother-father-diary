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
다음 글을 긍정적으로 바꿔서, 바뀐 결과(변환된 문장)만 반환해줘. 설명이나 해설 없이 결과만 출력해.

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
