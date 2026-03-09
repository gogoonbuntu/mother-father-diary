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
  late final GenerativeModel _geminiFlashLite;
  late final GenerativeModel _geminiFlash;

  GeminiService({required this.apiKey, this.grokApiKey}) {
    _geminiFlashLite = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );
    _geminiFlash = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  // Groq 모델 목록 (한국어 성능 순, 모델별 독립 한도)
  static const List<Map<String, String>> _groqModels = [
    {'id': 'qwen/qwen3-32b', 'name': 'Qwen3 32B'},                    // 한국어 100+언어 최강
    {'id': 'openai/gpt-oss-120b', 'name': 'GPT-OSS 120B'},            // 범용 백업
  ];

  /// 천사 버전 프롬프트 (긍정적 변환)
  String _buildAngelPrompt(String originalText) {
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

  /// 악마 버전 프롬프트 (공감+분노)
  String _buildDevilPrompt(String originalText) {
    return '''
너는 사용자의 가장 친한 천구이자 편이야. 사용자가 힘들어하는 상황을 듣고, 100% 사용자 편에 서서 함께 분노하고, 사용자를 힘들게 한 대상을 욕해줘.

스타일)
- 사용자에게는 따뜻하고 공감하는 말투
- 힘들게 한 대상에게는 통쾌하고 시원한 욕 (단, 실제 욕설은 사용하지 마. 기발한 비꼬기, 재치있는 디스, 통쾌한 지적 위주)
- 유머와 위트를 섞어 상대를 우습게 까내려줘
- 사용자가 읽으면 통쾌하고 후련한 기분이 들게!

예시)
- "상사가 또 야근했어." → "와 그 상사 진짜 대단하다… 매일 야근하는 게 회사의 음향 시스템인 줄 알았나봐. 그렇게 에너지 넘치면 발전소로 가든가~ 니가 견딘주는 것만으로도 상 받아야 해 진짜로 🌟"
- "친구가 약속을 어겼어." → "그 친구 냘악기가 장착돼있나? 약속을 어기는게 특기인 사람이네~ 니가 훨씬 낫지 해 정말 👍"
- "오늘 비가 와서 우울해." → "비야 니가 왜 지금 와? 타이밍을 좀 가려서 와라 진짜. 하늘도 눈치가 없네~ 그래도 넌 집에서 편하게 쉬어, 넌 충분히 그럴 자격이 있어 ❤️"

반드시 입력 문장의 언어와 결과 문장의 언어가 같아야 해.
총 인풋과 아웃풋의 총 문장 길이도 대략 비슷해야해.
결과(변환된 문장)만 출력하고, 설명이나 해설은 절대 하지 마.

$originalText
''';
  }

  /// Groq API 호출 (OpenAI-compatible)
  /// 429(rate limit) / 5xx 에러 시 null 반환하여 다음 모델로 자동 폴백
  Future<AiResult?> _callGroq(String prompt, String modelId, String modelName) async {
    if (grokApiKey == null || grokApiKey!.isEmpty) return null;

    try {
      debugPrint('[AI] 🟢 Groq $modelName 요청 시작...');
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $grokApiKey',
        },
        body: jsonEncode({
          'model': modelId,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.8,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('[AI] Groq $modelName 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final text = data['choices']?[0]?['message']?['content'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          // Qwen3 등 추론 모델의 <think>...</think> 태그 제거
          final cleaned = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '').trim();
          if (cleaned.isNotEmpty) {
            debugPrint('[AI] ✅ Groq $modelName 성공: ${cleaned.substring(0, cleaned.length > 50 ? 50 : cleaned.length)}...');
            return AiResult(text: cleaned, provider: 'Groq $modelName');
          }
        }
        debugPrint('[AI] ⚠️ Groq $modelName 빈 응답');
        return null;
      } else if (response.statusCode == 429) {
        debugPrint('[AI] ⏳ Groq $modelName 무료 한도 초과 (429) → 다음 모델로 폴백');
        return null;
      } else {
        debugPrint('[AI] ❌ Groq $modelName 에러 (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
        return null;
      }
    } catch (e) {
      debugPrint('[AI] ❌ Groq $modelName 예외: $e');
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

  /// 천사 버전 변환 — 다단계 자동 폴백
  Future<AiResult?> getAngelVersion(String originalText) async {
    final prompt = _buildAngelPrompt(originalText);
    return _callWithFallback(prompt);
  }

  /// 악마 버전 변환 — 다단계 자동 폴백
  Future<AiResult?> getDevilVersion(String originalText) async {
    final prompt = _buildDevilPrompt(originalText);
    return _callWithFallback(prompt);
  }

  /// 공통 폴백 로직: Groq 모델들 → Gemini Flash-Lite → Gemini Flash
  Future<AiResult?> _callWithFallback(String prompt) async {
    // 1단계: Groq 모델들 순차 시도
    for (final model in _groqModels) {
      final result = await _callGroq(prompt, model['id']!, model['name']!);
      if (result != null) return result;
    }

    // 2단계: Gemini Flash-Lite
    debugPrint('[AI] 🔄 모든 Groq 모델 실패 → Gemini Flash-Lite 폴백');
    final primaryResult = await _callGemini(prompt, _geminiFlashLite, 'Gemini Flash-Lite');
    if (primaryResult != null) return primaryResult;

    // 3단계: Gemini Flash (최종 폴백)
    debugPrint('[AI] 🔄 Gemini Flash-Lite 실패 → Gemini Flash 최종 폴백');
    return await _callGemini(prompt, _geminiFlash, 'Gemini Flash');
  }
}
