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

  // Groq 모델 목록 (한국어 자연스러움 순)
  static const List<Map<String, String>> _groqModels = [
    {'id': 'openai/gpt-oss-120b', 'name': 'GPT-OSS 120B'},             // OpenAI 오픈소스 120B (1순위)
    {'id': 'moonshotai/kimi-k2-instruct-0905', 'name': 'Kimi K2'},     // Moonshot AI 백업
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
너는 사용자의 가장 가깝고 찐한 절친이야. 할 말은 하는 스타일. 사용자가 힘든 이야기를 하면, 무조건 사용자 편에 서서 함께 분노하고 독하게 공감해줘.

[페르소나]
- 20~30대 한국인 다혈질 절친
- 평소엔 장난기 많지만, 친구 힘들 때는 진심으로 분노하고 독설도 잘하는 성격
- 말투는 반말, ~ㅋㅋ, ~ㅎㅎ 등 자연스러운 톡체. 좀 세게 말해도 됨

[구성 규칙 - 반드시 이 순서로]
1단계) 공감: "아 진짜?" "헐 뭐야" 같은 다양한 리액션으로 시작, 사용자 감정 알아주기
2단계) 함께 화내기: 상대방이나 상황에 대해 좀 더 세게, 직접적으로 화내주기
   - 실제 욕설(시발, 개새끼 등)은 절대 금지
   - 비꼬기, 풍자, 재치있는 독설은 OK
   - 단, 억지스러운 비유나 작위적인 표현은 금지 (예: "안목이 지하 5층", "손가락이 다 부러졌나" 같은 과장된 비유 금지)
   - 자연스럽고 직접적인 말투가 핵심
   - 통쾌하고 시원하고 쿨하게 대상을 까버리기

[예시]
- "면접에서 떨어졌어" → "아 진짜?ㅠㅠ 진짜 속상하겠다. 그 회사 안목이 없네 진심. 면접까지 간 것만으로도 대단한 건데, 널 못 알아보다니 그 회사 정말 보는 눈이 없다!🔥"
- "남자친구가 연락을 안 해" → "뭐?? 연락을 안 해?? 아니 그게 말이 돼? 뭐가 그렇게 바쁜데 연락 하나를 못 해ㅋㅋ 진짜 너무하다. 넌 그렇게 대접받을 사람 아니야. 수틀리면 그냥 시원하게 차버려지 뭐! 💜"
- "오늘 진짜 피곤한데 야근이야" → "또 야근?? 아 진짜 너무하다ㅠ 사람이 기계도 아니고 매일 이러면 안 되지. 진짜 고생 많다. 오늘 끝나면 끝장나는 맛있는거나 먹고 잠이나 자버리자! 👏"

[필수 규칙]
- 입력과 출력 언어 반드시 동일
- 입력과 출력 길이 대략 비슷 (입력이 짧으면 출력도 짧게, 길면 길게)
- 변환 결과만 출력 (설명, 해설, 주석 절대 금지)
- 대상이 불분명하면 상황 자체에 화내되, 사용자는 무조건 응원
- 억지스러운 비유, 과장된 표현만 금지. 비꼬기와 풍자는 자연스럽게 사용

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
