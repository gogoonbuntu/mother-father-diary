import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

/// AI 응답 결과 (텍스트 + 제공자 정보)
class AiResult {
  final String text;
  final String provider;

  AiResult({required this.text, required this.provider});
}

class GeminiService {
  final String apiKey;
  final String? grokApiKey; // 실제로는 Groq API 키
  late final GenerativeModel _primaryModel;
  late final GenerativeModel _fallbackModel;

  GeminiService({required this.apiKey, this.grokApiKey}) {
    _primaryModel = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );
    _fallbackModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  String _buildPrompt(String originalText) {
    return '''
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
  }

  /// Groq API 호출 (OpenAI-compatible, llama-3.3-70b-versatile)
  Future<AiResult?> _callGroq(String prompt) async {
    if (grokApiKey == null || grokApiKey!.isEmpty) return null;

    try {
      debugPrint('[AI] 🟢 Groq API 요청 시작 (llama-3.3-70b)...');
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $grokApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.8,
        }),
      );

      debugPrint('[AI] Groq 응답 코드: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] as String?;
        debugPrint('[AI] ✅ Groq 응답 성공: ${text?.substring(0, text.length > 50 ? 50 : text.length)}...');
        if (text != null) return AiResult(text: text, provider: 'Groq');
        return null;
      } else {
        debugPrint('[AI] ❌ Groq 에러 (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[AI] ❌ Groq 예외: $e');
      return null;
    }
  }

  /// Gemini API 호출
  Future<AiResult?> _callGemini(String prompt, GenerativeModel model, String modelName) async {
    try {
      debugPrint('[AI] 🟡 $modelName 요청 시작...');
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      debugPrint('[AI] ✅ $modelName 응답 성공!');
      if (response.text != null) return AiResult(text: response.text!, provider: modelName);
      return null;
    } catch (e) {
      debugPrint('[AI] ❌ $modelName 에러: $e');
      return null;
    }
  }

  /// 긍정 버전 변환 (Groq → Gemini Flash-Lite → Gemini Flash 순서로 시도)
  Future<AiResult?> getPositiveVersion(String originalText) async {
    final prompt = _buildPrompt(originalText);

    // 1차: Groq 시도 (가장 빠름)
    final groqResult = await _callGroq(prompt);
    if (groqResult != null) return groqResult;

    // 2차: Gemini 2.5 Flash-Lite
    final primaryResult = await _callGemini(prompt, _primaryModel, 'Gemini Flash-Lite');
    if (primaryResult != null) return primaryResult;

    // 3차: Gemini 2.5 Flash 폴백
    return await _callGemini(prompt, _fallbackModel, 'Gemini Flash');
  }
}
