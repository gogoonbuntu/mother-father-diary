import 'dart:async';
import 'package:flutter/material.dart';
import 'package:diary_app/main.dart' show kSupportedFonts;
import 'package:flutter/services.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/generated/app_localizations.dart';
import 'package:diary_app/services/diary_service.dart';
import 'package:diary_app/services/gemini_service.dart';
import 'package:diary_app/services/gemini_api_key.dart';
import 'package:diary_app/services/share_service.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math; 
import 'confetti_themes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'line_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:diary_app/services/purchase_service.dart';
import 'package:diary_app/premium_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DiaryEntryScreen extends StatefulWidget {
  final DiaryEntry? diaryEntry;
  final Color? bgColor;
  final String? fontFamily;
  final ScrollController? scrollController;

  const DiaryEntryScreen({super.key, this.diaryEntry, this.bgColor, this.fontFamily, this.scrollController});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late ConfettiTheme _selectedConfettiTheme = confettiThemes[0];

  // 화면 플래시 애니메이션
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  // 악마 이펙트: 빨간 플래시 + 흔들림
  late AnimationController _devilFlashController;
  late Animation<double> _devilFlashAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final TextEditingController _controller = TextEditingController();
  Timer? _saveDebounceTimer;
  late DateTime _selectedDate;
  late String _selectedMood;
  // 기분 상태에 대한 상수 정의
  static const String MOOD_HAPPY = 'Happy';
  static const String MOOD_SAD = 'Sad';
  static const String MOOD_NEUTRAL = 'Neutral';

  List<String> _moodOptions = [];

  String? _positiveVersion;
  String? _devilVersion;
  bool _isLoadingPositive = false;
  bool _isLoadingDevil = false;
  bool _showSavedNotification = false;
  double _positiveTextSize = 18.0;
  double _devilTextSize = 18.0;
  String _activeResultMode = ''; // 'angel' or 'devil' — 하단에 어떤 결과를 표시할지
  String _aiProvider = '';
  int _angelRating = 0;  // 천사 버전 별점 (0=미평가, 1~5)
  int _devilRating = 0;  // 악마 버전 별점

  // 생성 제한
  static const int _dailyFreeLimit = 3;
  static const int _monthlyPremiumLimit = 300;
  int _todayCount = 0;
  int _monthCount = 0;
  bool _adGranted = false; // 광고 시청으로 1회 추가 허용
  bool _ratingGranted = false; // 별점 평가로 1회 추가 허용
  bool _hasRatedForCreditToday = false; // 오늘 이미 별점 크레딧 사용 여부
  RewardedAd? _rewardedAd;
  final _purchaseService = PurchaseService();

  // 음성 인식
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  // 날짜 키
  String get _todayKey => 'positive_count_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
  String get _monthKey => 'premium_month_count_${DateTime.now().year}-${DateTime.now().month}';
  String get _ratingCreditKey => 'rating_credit_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';

  // 남은 횟수
  int get _remainingFree => math.max(0, _dailyFreeLimit - _todayCount);
  int get _remainingPremium => math.max(0, _monthlyPremiumLimit - _monthCount);
  int get _remainingCredits => _purchaseService.isPremium ? _remainingPremium : _remainingFree;
  bool get _hasCredits => _remainingCredits > 0;

  // 생성 횟수 로드
  Future<void> _loadDailyCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todayCount = prefs.getInt(_todayKey) ?? 0;
      _monthCount = prefs.getInt(_monthKey) ?? 0;
      _hasRatedForCreditToday = prefs.getBool(_ratingCreditKey) ?? false;
    });
  }

  // 생성 횟수 증가
  Future<void> _incrementDailyCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (_purchaseService.isPremium) {
      _monthCount++;
      await prefs.setInt(_monthKey, _monthCount);
    } else {
      _todayCount++;
      await prefs.setInt(_todayKey, _todayCount);
    }
  }

  // 리워드 광고 로드
  void _loadRewardedAd() {
    RewardedAd.load(
      // 테스트 광고 ID (프로덕션에서는 실제 ID로 교체)
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[광고] 리워드 광고 로드 완료');
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[광고] 리워드 광고 로드 실패: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  // 광고 보고 추가 생성
  Future<bool> _showRewardedAd() async {
    if (_rewardedAd == null) {
      _loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();
    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // 다음 광고 미리 로드
        // 광고 닫힐 때 최종 결과 전달 (reward 콜백이 먼저 호출됨)
        if (!completer.isCompleted) {
          completer.complete(rewarded);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[광고] 리워드 획득: ${reward.amount} ${reward.type}');
        rewarded = true;
      },
    );
    return completer.future;
  }

  // 버튼 클릭 핸들러
  void _onModeButtonPressed(String mode) {
    FocusScope.of(context).unfocus();

    final hasVersion = (mode == 'angel' && _positiveVersion != null) ||
                       (mode == 'devil' && _devilVersion != null);

    // 해당 버전이 이미 있는데, 현재 다른 모드를 보고 있으면 → 보기 전환만
    if (hasVersion && _activeResultMode != mode) {
      setState(() { _activeResultMode = mode; });
      return;
    }

    // 해당 버전이 이미 있고, 현재 그 모드를 보고 있으면 → 재생성 확인
    if (hasVersion && _activeResultMode == mode) {
      _showRegenerateConfirm(mode);
      return;
    }

    // 첫 생성
    _tryGenerate(mode: mode);
  }

  // 재생성 확인 팝업
  void _showRegenerateConfirm(String mode) {
    final l10n = AppLocalizations.of(context)!;
    final label = mode == 'angel' ? l10n.angel : l10n.devil;
    final remaining = _purchaseService.isPremium
        ? l10n.remainingCountPremium(_remainingPremium, _monthlyPremiumLimit)
        : l10n.remainingCountFree(_remainingFree, _dailyFreeLimit);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🔄 $label'),
        content: Text(l10n.regenerateConfirm(label, remaining)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _tryGenerate(mode: mode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: mode == 'angel' ? Colors.teal : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.regenerateButton),
          ),
        ],
      ),
    );
  }

  // 실제 생성 실행
  Future<void> _tryGenerate({String mode = 'angel'}) async {
    // 광고 보너스가 있으면 사용
    if (_adGranted) {
      _adGranted = false;
      mode == 'angel' ? await _convertToAngelVersion() : await _convertToDevilVersion();
      return;
    }

    // 별점 평가 보너스가 있으면 사용
    if (_ratingGranted) {
      _ratingGranted = false;
      mode == 'angel' ? await _convertToAngelVersion() : await _convertToDevilVersion();
      return;
    }

    // 한도 체크 (프리미엄: 50/월, 무료: 3/일)
    if (!_hasCredits) {
      _showLimitDialog(mode: mode);
      return;
    }

    await _incrementDailyCount();
    mode == 'angel' ? await _convertToAngelVersion() : await _convertToDevilVersion();
  }

  // 한도 초과 다이얼로그 — 광고 OR 프리미엄 선택
  void _showLimitDialog({String mode = 'angel'}) {
    final isPremium = _purchaseService.isPremium;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isPremium ? '🔒 이번 달 횟수 소진' : '🔒 오늘 무료 횟수 소진',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPremium
                  ? AppLocalizations.of(context)!.premiumLimitReached(_monthlyPremiumLimit)
                  : AppLocalizations.of(context)!.freeLimitReached(_dailyFreeLimit),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // ⭐ 별점 평가로 1회 추가 (하루 1회, 기존 AI 결과가 있을 때만)
            if (!_hasRatedForCreditToday && (_positiveVersion != null || _devilVersion != null)) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showRatingForCreditDialog(mode: mode);
                  },
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('⭐ AI 결과 평가하고 1회 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            // 광고 보기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final rewarded = await _showRewardedAd();
                  if (rewarded) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('🎉 광고 시청 완료! 추가 생성이 가능합니다.'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFF7C5CFC),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('📢 광고 준비 중... 이번 한번은 무료로 생성해드릴게요!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFF7C5CFC),
                        ),
                      );
                    }
                  }
                  setState(() { _adGranted = true; });
                  await _tryGenerate(mode: mode);
                },
                icon: const Icon(Icons.play_circle_outline),
                label: Text(AppLocalizations.of(context)!.watchAdToGenerate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C5CFC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            // 무료 사용자만 프리미엄 구독 버튼 표시
            if (!isPremium) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    ).then((purchased) {
                      if (purchased == true && mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('🎉 프리미엄 활성화! 월 300회까지 사용하세요!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: const Color(0xFF7C5CFC),
                          ),
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.diamond_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.premiumSubscription),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE8577E),
                    side: const BorderSide(color: Color(0xFFE8577E), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // ⭐ 별점 평가로 크레딧 받기 다이얼로그
  void _showRatingForCreditDialog({String mode = 'angel'}) {
    int tempRating = 0;
    final hasAngel = _positiveVersion != null;
    final hasDevil = _devilVersion != null;
    // 가장 최근 결과를 평가 대상으로
    final targetMode = _activeResultMode.isNotEmpty 
        ? _activeResultMode 
        : (hasDevil ? 'devil' : 'angel');
    final targetText = targetMode == 'angel' ? _positiveVersion : _devilVersion;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            targetMode == 'angel' ? '😇 천사 버전 평가' : '😈 악마 버전 평가',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 결과 미리보기
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Text(
                    targetText ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.ratingQuestion, 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              // 별점 선택
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => tempRating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        star <= tempRating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 36,
                        color: star <= tempRating ? const Color(0xFFFF9800) : Colors.grey.shade300,
                      ),
                    ),
                  );
                }),
              ),
              if (tempRating > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    ['' , AppLocalizations.of(context)!.ratingBad, AppLocalizations.of(context)!.ratingPoor, AppLocalizations.of(context)!.ratingOk, AppLocalizations.of(context)!.ratingGood, AppLocalizations.of(context)!.ratingExcellent][tempRating],
                    style: const TextStyle(fontSize: 13, color: Color(0xFFFF9800), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: tempRating > 0 ? () async {
                Navigator.pop(ctx);
                // 별점 저장 (Firebase)
                _submitRating(targetMode, tempRating);
                // 오늘 별점 크레딧 사용 완료 표시
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_ratingCreditKey, true);
                setState(() {
                  _hasRatedForCreditToday = true;
                  _ratingGranted = true;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('⭐ 평가 감사합니다! 1회 추가 생성이 가능합니다.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFFFF9800),
                    ),
                  );
                }
                await _tryGenerate(mode: mode);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(AppLocalizations.of(context)!.rateAndGet),
            ),
          ],
        ),
      ),
    );
  }

  // 😇 천사 버전 생성
  Future<void> _convertToAngelVersion() async {
    setState(() {
      _selectedConfettiTheme = (confettiThemes..shuffle()).first;
      _isLoadingPositive = true;
      _positiveVersion = null;
      _aiProvider = '';
      _angelRating = 0;
    });
    final gemini = GeminiService(apiKey: geminiApiKey, grokApiKey: grokApiKey);
    final result = await gemini.getAngelVersion(_controller.text);
    setState(() {
      _positiveVersion = result?.text;
      _aiProvider = result?.provider ?? '';
      _isLoadingPositive = false;
      _activeResultMode = 'angel';
    });
    if (result != null) {
      _playCelebration();
      _saveDiaryEntryWithVersions();
    }
  }

  // 😈 악마 버전 생성
  Future<void> _convertToDevilVersion() async {
    setState(() {
      _isLoadingDevil = true;
      _devilVersion = null;
      _aiProvider = '';
      _devilRating = 0;
    });
    final gemini = GeminiService(apiKey: geminiApiKey, grokApiKey: grokApiKey);
    final result = await gemini.getDevilVersion(_controller.text);
    setState(() {
      _devilVersion = result?.text;
      _aiProvider = result?.provider ?? '';
      _isLoadingDevil = false;
      _activeResultMode = 'devil';
    });
    if (result != null) {
      HapticFeedback.heavyImpact();
      _playDevilCelebration();
      _saveDiaryEntryWithVersions();
    }
  }

  // 😈 악마 축하 이펙트: 빨간 플래시 + 화면 흔들림 + 연속 햅틱
  void _playDevilCelebration() {
    // 빨간 플래시
    _devilFlashController.forward(from: 0.0);

    // 화면 흔들림
    _shakeController.forward(from: 0.0);

    // 1차 햅틱
    HapticFeedback.heavyImpact();

    // 2차 햅틱 (200ms 후)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) HapticFeedback.heavyImpact();
    });

    // 3차 햅틱 (400ms 후)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) HapticFeedback.mediumImpact();
    });

    // 4차 햅틱 (600ms 후)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  /// ⭐ 별점 평가 위젯 (1~5, 한번 터치)
  Widget _buildStarRating({
    required int currentRating,
    required Color accentColor,
    required Function(int) onRate,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currentRating > 0 ? AppLocalizations.of(context)!.ratingComplete : AppLocalizations.of(context)!.ratingPrompt,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 6),
          ...List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => onRate(star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  star <= currentRating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 22,
                  color: star <= currentRating ? accentColor : Colors.grey.shade300,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// ⭐ 별점 Firebase 저장
  void _submitRating(String mode, int stars) {
    if (_aiProvider.isEmpty) return;
    
    setState(() {
      if (mode == 'angel') _angelRating = stars;
      else _devilRating = stars;
    });
    HapticFeedback.lightImpact();

    // Firebase에 모델별 통계 저장
    final modelKey = _aiProvider.replaceAll(' ', '_').replaceAll('.', '_');
    final ref = FirebaseDatabase.instance.ref('model_ratings/$modelKey');
    ref.child('total_stars').set(ServerValue.increment(stars));
    ref.child('total_count').set(ServerValue.increment(1));
    ref.child('star_$stars').set(ServerValue.increment(1));
    ref.child('${mode}_count').set(ServerValue.increment(1));
    ref.child('last_rated').set(DateTime.now().toIso8601String());

    debugPrint('[Rating] ⭐ $mode $_aiProvider: $stars/5');
  }

  /// 📤 공유 바텀 시트
  void _showShareBottomSheet() {
    bool includeOriginal = true;
    bool includeAngel = _positiveVersion != null;
    bool includeDevil = _devilVersion != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 핸들
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text('📤 일기 공유하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2D2D3A)),
                ),
                const SizedBox(height: 16),

                // 체크박스 옵션
                _shareCheckTile(
                  icon: '📝',
                  title: AppLocalizations.of(context)!.originalDiary,
                  subtitle: _controller.text.length > 30
                      ? '${_controller.text.substring(0, 30)}...'
                      : _controller.text,
                  value: includeOriginal,
                  enabled: _controller.text.trim().isNotEmpty,
                  onChanged: (v) => setSheetState(() => includeOriginal = v ?? false),
                ),
                if (_positiveVersion != null)
                  _shareCheckTile(
                    icon: '😇',
                    title: AppLocalizations.of(context)!.angelComfort,
                    subtitle: _positiveVersion!.length > 30
                        ? '${_positiveVersion!.substring(0, 30)}...'
                        : _positiveVersion!,
                    value: includeAngel,
                    onChanged: (v) => setSheetState(() => includeAngel = v ?? false),
                  ),
                if (_devilVersion != null)
                  _shareCheckTile(
                    icon: '😈',
                    title: AppLocalizations.of(context)!.devilEmpathy,
                    subtitle: _devilVersion!.length > 30
                        ? '${_devilVersion!.substring(0, 30)}...'
                        : _devilVersion!,
                    value: includeDevil,
                    onChanged: (v) => setSheetState(() => includeDevil = v ?? false),
                  ),

                const SizedBox(height: 16),

                // 공유 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (includeOriginal || includeAngel || includeDevil)
                        ? () {
                            Navigator.pop(ctx);
                            ShareService.shareAsImage(
                              context,
                              date: _selectedDate,
                              mood: _selectedMood,
                              originalContent: includeOriginal ? _controller.text : null,
                              angelVersion: includeAngel ? _positiveVersion : null,
                              devilVersion: includeDevil ? _devilVersion : null,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.image_rounded, size: 20),
                    label: Text(AppLocalizations.of(context)!.shareAsImageCard, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C5CFC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 공유 체크 타일 위젯
  Widget _shareCheckTile({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    bool enabled = true,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFF3EEFF) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFF7C5CFC).withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
        subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: const Color(0xFF7C5CFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;

      });
      
      // 비동기로 일기 데이터 가져오기
      final existingEntry = await DiaryService().getDiaryEntryForDate(_selectedDate);
      if (existingEntry != null) {
        setState(() {
          _controller.text = existingEntry.content;
          _selectedMood = existingEntry.mood;
          _positiveVersion = existingEntry.positiveVersion;
          _devilVersion = existingEntry.devilVersion;
          if (_devilVersion != null) {
            _activeResultMode = 'devil';
          } else if (_positiveVersion != null) {
            _activeResultMode = 'angel';
          }
        });
      } else {
        setState(() {
          _controller.text = '';
          _positiveVersion = null;
          _devilVersion = null;
          _activeResultMode = '';
        });
      }
    }
  }

  // 🎉 프리미엄 축하 이펙트
  void _playCelebration() {
    // 햅틱 피드백
    HapticFeedback.heavyImpact();

    // 흰색 플래시
    _flashController.forward(from: 0.0);

    // 1차 폭발
    try { _confettiController.play(); } catch (_) {}

    // 2차 폭발 (0.4초 후)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        HapticFeedback.mediumImpact();
        try { _confettiController.play(); } catch (_) {}
      }
    });

    // 3차 폭발 (0.9초 후)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        HapticFeedback.lightImpact();
        try { _confettiController.play(); } catch (_) {}
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    // 플래시 애니메이션 (0 → 0.7 → 0, 600ms)
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));

    // 악마 빨간 플래시 (0 → 0.5 → 0, 500ms)
    _devilFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _devilFlashAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 75),
    ]).animate(CurvedAnimation(parent: _devilFlashController, curve: Curves.easeOut));

    // 화면 흔들림 (좌우 진동, 500ms)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 4.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -2.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -2.0, end: 0.0), weight: 15),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
    _selectedDate = widget.diaryEntry?.date ?? DateTime.now();
    
    // 기본 기분 설정 - 영어 상수 사용
    _selectedMood = MOOD_HAPPY; // 기본값으로 설정
    
    // 텍스트 변경 감지 (디바운스 적용)
    _controller.addListener(() {
      setState(() {}); // 입력값 변경 시 버튼 상태 갱신
      // 2초 디바운스로 자동 저장
      _saveDebounceTimer?.cancel();
      _saveDebounceTimer = Timer(const Duration(seconds: 2), _saveDiaryEntry);
    });
    
    // 일일 생성 횟수 로드 & 리워드 광고 미리 로드
    _loadDailyCount();
    _loadRewardedAd();

    // 음성 인식 초기화
    _initSpeech();
    
    // 지연된 초기화를 위해 다음 프레임에서 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingEntry();
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        debugPrint('[음성인식] 오류: ${error.errorMsg}');
        if (mounted) setState(() { _isListening = false; });
      },
      onStatus: (status) {
        debugPrint('[음성인식] 상태: $status');
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() { _isListening = false; });
        }
      },
    );
    debugPrint('[음성인식] 초기화: $_speechAvailable');
  }

  void _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎙️ 음성 인식을 사용할 수 없습니다. 마이크 권한을 확인해주세요.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFFE8577E),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() { _isListening = false; });
    } else {
      // 녹음 시작 전 텍스트 저장 (partial result가 전체 인식 텍스트를 반환하므로)
      final textBeforeListening = _controller.text;
      final needsSpace = textBeforeListening.isNotEmpty &&
          !textBeforeListening.endsWith(' ') &&
          !textBeforeListening.endsWith('\n');

      setState(() { _isListening = true; });
      HapticFeedback.mediumImpact();

      // 기기 로케일 사용 (한국어 고정 대신)
      final locale = Localizations.localeOf(context);
      final localeId = '${locale.languageCode}_${locale.countryCode ?? locale.languageCode.toUpperCase()}';
      debugPrint('[음성인식] 로케일: $localeId');

      await _speech.listen(
        onResult: (result) {
          setState(() {
            // 기존 텍스트 + 공백 + 인식된 전체 텍스트 (매번 교체)
            final separator = needsSpace ? ' ' : '';
            _controller.text = '$textBeforeListening$separator${result.recognizedWords}';
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
        },
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  Future<void> _loadExistingEntry() async {
    final existingEntry = await DiaryService().getDiaryEntryForDate(_selectedDate);
    if (existingEntry != null && mounted) {
      setState(() {
        _controller.text = existingEntry.content;
        _selectedMood = existingEntry.mood;
        _positiveVersion = existingEntry.positiveVersion;
        _devilVersion = existingEntry.devilVersion;
        if (_devilVersion != null) {
          _activeResultMode = 'devil';
        } else if (_positiveVersion != null) {
          _activeResultMode = 'angel';
        }
      });
    }
  }

  Future<void> _saveDiaryEntryWithVersions() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    final existingEntry = await DiaryService().getDiaryEntryForDate(_selectedDate);
    DiaryEntry entry;
    if (existingEntry != null) {
      entry = DiaryEntry(
        id: existingEntry.id,
        date: _selectedDate,
        mood: _moodToEnglish(_selectedMood),
        content: content,
        positiveVersion: _positiveVersion,
        devilVersion: _devilVersion,
      );
      await DiaryService().updateDiaryEntry(existingEntry.id, entry);
    } else {
      entry = DiaryEntry.create(
        date: _selectedDate,
        mood: _moodToEnglish(_selectedMood),
        content: content,
        positiveVersion: _positiveVersion,
        devilVersion: _devilVersion,
      );
      await DiaryService().addDiaryEntry(entry);
    }
  }

  // 천사 버전 텍스트 크기 조절
  void _adjustPositiveTextSize(double change) {
    setState(() {
      _positiveTextSize = math.max(14.0, math.min(24.0, _positiveTextSize + change));
    });
  }

  // 악마 버전 텍스트 크기 조절
  void _adjustDevilTextSize(double change) {
    setState(() {
      _devilTextSize = math.max(14.0, math.min(24.0, _devilTextSize + change));
    });
  }

  Future<void> _saveDiaryEntry() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    
    final existingEntry = await DiaryService().getDiaryEntryForDate(_selectedDate);
    DiaryEntry entry;
    if (existingEntry != null) {
      entry = DiaryEntry(
        id: existingEntry.id,
        date: _selectedDate,
        mood: _moodToEnglish(_selectedMood),
        content: content,
        positiveVersion: _positiveVersion,
      );
      await DiaryService().updateDiaryEntry(existingEntry.id, entry);
    } else {
      entry = DiaryEntry.create(
        date: _selectedDate,
        mood: _moodToEnglish(_selectedMood),
        content: content,
        positiveVersion: _positiveVersion,
      );
      await DiaryService().addDiaryEntry(entry);
    }
    
    setState(() {
      _showSavedNotification = true;
    });
    
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSavedNotification = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _confettiController.dispose();
    _flashController.dispose();
    _devilFlashController.dispose();
    _shakeController.dispose();
    _controller.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 기분 옵션 초기화 - null 체크 추가
    final localizations = AppLocalizations.of(context);
    if (localizations != null && _moodOptions.isEmpty) {
      _moodOptions = [
        localizations.moodHappy,
        localizations.moodSad,
        localizations.moodNeutral,
      ];
    }
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3EEFF),
            Color(0xFFFFF0F5),
            Color(0xFFEEF7FF),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: SingleChildScrollView(
            controller: widget.scrollController,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 16,
                left: 16, right: 16, bottom: 24,
              ),
              child: Column(
                children: [
                  // 드래그 핸들
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      widget.diaryEntry == null ? AppLocalizations.of(context)!.diaryEntry : AppLocalizations.of(context)!.editDiary,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF2D2D3A)),
                    ),
                  ),
                    // 📅 날짜 & 기분 선택 카드
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C5CFC).withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // 날짜 버튼
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3EEFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF7C5CFC)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5A3ED9)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 기분 선택
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedMood,
                                isDense: true,
                                icon: const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFFE8577E)),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE8577E)),
                                onChanged: (String? newValue) {
                                  setState(() { _selectedMood = newValue!; });
                                },
                                items: <Map<String, String>>[
                                  {'value': MOOD_HAPPY, 'label': '😊 ${AppLocalizations.of(context)!.moodHappy}'},
                                  {'value': MOOD_SAD, 'label': '😢 ${AppLocalizations.of(context)!.moodSad}'},
                                  {'value': MOOD_NEUTRAL, 'label': '😐 ${AppLocalizations.of(context)!.moodNeutral}'},
                                ].map<DropdownMenuItem<String>>((Map<String, String> item) {
                                  return DropdownMenuItem<String>(
                                    value: item['value'],
                                    child: Text(item['label']!),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 천사/악마 버튼 영역
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C5CFC).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // 😇 천사 버전 버튼
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C5CFC), Color(0xFF9B7DFF)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C5CFC).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: (_isLoadingPositive || _isLoadingDevil || _controller.text.trim().isEmpty) ? null : () => _onModeButtonPressed('angel'),
                                icon: _isLoadingPositive
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('😇', style: TextStyle(fontSize: 16)),
                                label: Text(
                                  _positiveVersion != null
                                      ? (_activeResultMode == 'angel' ? AppLocalizations.of(context)!.regenerateAngel : AppLocalizations.of(context)!.viewAngel)
                                      : AppLocalizations.of(context)!.angelComfort,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 😈 악마 버전 버튼
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE8577E), Color(0xFFFF7E9D)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE8577E).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: (_isLoadingPositive || _isLoadingDevil || _controller.text.trim().isEmpty) ? null : () => _onModeButtonPressed('devil'),
                                icon: _isLoadingDevil
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('😈', style: TextStyle(fontSize: 16)),
                                label: Text(
                                  _devilVersion != null
                                      ? (_activeResultMode == 'devil' ? AppLocalizations.of(context)!.regenerateDevil : AppLocalizations.of(context)!.viewDevil)
                                      : AppLocalizations.of(context)!.devilEmpathy,

                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 잔여 횟수 (길게 누르면 디버그 프리미엄 토글)
                          GestureDetector(
                            onTap: () {
                              if (!_purchaseService.isPremium) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                                ).then((purchased) {
                                  if (purchased == true && mounted) setState(() {});
                                });
                              }
                            },
                            onLongPress: () async {
                              // 디버그: 프리미엄 상태 토글
                              final newState = !_purchaseService.isPremium;
                              await _purchaseService.debugSetPremium(newState);
                              await _loadDailyCount();
                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(newState ? '💎 디버그: 프리미엄 ON' : '🎫 디버그: 프리미엄 OFF'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: const Color(0xFF7C5CFC),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: _hasCredits ? const Color(0xFFF3EEFF) : const Color(0xFFFFEEF0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _purchaseService.isPremium
                                    ? '💎 $_remainingPremium/$_monthlyPremiumLimit월'
                                    : '🎫 $_remainingFree/$_dailyFreeLimit일',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _hasCredits ? const Color(0xFF7C5CFC) : const Color(0xFFE8577E),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 일기 작성 영역 + 마이크 버튼
                    Stack(
                      children: [
                    Container(
                      height: MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).size.height * 0.25
                          : MediaQuery.of(context).size.height * 0.35,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: _isListening ? Border.all(color: const Color(0xFFE8577E), width: 2) : null,
                        boxShadow: [
                          BoxShadow(
                            color: _isListening
                                ? const Color(0xFFE8577E).withValues(alpha: 0.15)
                                : const Color(0xFF7C5CFC).withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CustomPaint(
                          painter: LinePainter(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: _isListening ? '🎙️ 말해보세요...' : AppLocalizations.of(context)!.diaryHint,
                                hintStyle: TextStyle(
                                  color: _isListening ? const Color(0xFFE8577E) : Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                                contentPadding: const EdgeInsets.all(16.0),
                                filled: false,
                              ),
                              style: widget.fontFamily != null
                              ? _getFontStyle(widget.fontFamily!, 16)
                              : const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: Color(0xFF2D2D3A),
                                ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 🎙️ 마이크 버튼 (FAB)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: _toggleListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [const Color(0xFFE8577E), const Color(0xFFFF7E9D)]
                                  : [const Color(0xFF7C5CFC), const Color(0xFF9B7DFF)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? const Color(0xFFE8577E) : const Color(0xFF7C5CFC)).withValues(alpha: 0.4),
                                blurRadius: _isListening ? 16 : 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                      ],
                    ),
                    // 첫 사용자를 위한 안내 가이드
                    if (_controller.text.isEmpty && _positiveVersion == null && _devilVersion == null && widget.diaryEntry == null)
                      IgnorePointer(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF7C5CFC).withValues(alpha: 0.15), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C5CFC).withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📝 사용 방법', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF5A3ED9))),
                              const SizedBox(height: 8),
                              Text('Step 1️⃣  위 입력칸에 오늘의 일기를 자유롭게 적어보세요',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                              const SizedBox(height: 4),
                              Text('Step 2️⃣  원하는 버전을 선택하세요',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                              const SizedBox(height: 4),
                              const Text('      😇 천사: 긍정적이고 따뜻한 버전으로 변환',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF7C5CFC))),
                              const Text('      😈 악마: 함께 공감하고 통쾌하게 욕해주는 버전',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFE8577E))),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // 😇 천사 버전 결과 카드 (activeResultMode == 'angel'일 때만)
                    if ((_positiveVersion != null || _isLoadingPositive) && _activeResultMode == 'angel')
                      SafeArea(
                        child: Container(

                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF7C5CFC).withValues(alpha: 0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C5CFC).withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Flexible(
                                    child: Text('😇 천사 버전',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF5A3ED9)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.text_decrease, size: 18, color: Color(0xFF7C5CFC)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        onPressed: () => _adjustPositiveTextSize(-1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.text_increase, size: 18, color: Color(0xFF7C5CFC)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        onPressed: () => _adjustPositiveTextSize(1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF7C5CFC)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        tooltip: '공유하기',
                                        onPressed: _showShareBottomSheet,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: MediaQuery.of(context).size.height * 0.28,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFF5F0FF), Color(0xFFF0EBFF)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: _isLoadingPositive
                                  ? const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(color: Color(0xFF7C5CFC)),
                                          SizedBox(height: 12),
                                          Text('✨ 천사 버전 생성 중...', style: TextStyle(color: Color(0xFF7C5CFC))),
                                        ],
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: Text(
                                        _positiveVersion ?? '',
                                        style: widget.fontFamily != null
                                          ? _getFontStyle(widget.fontFamily!, _positiveTextSize, fontWeight: FontWeight.w500, color: const Color(0xFF2D2D3A))
                                          : TextStyle(
                                              fontSize: _positiveTextSize,
                                              height: 1.6,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF2D2D3A),
                                            ),
                                      ),
                                    ),
                              ),
                              if (_aiProvider.isNotEmpty && !_isLoadingPositive) ...[                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Powered by $_aiProvider · E2E 암호화 저장 🔑',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                _buildStarRating(
                                  currentRating: _angelRating,
                                  accentColor: const Color(0xFF7C5CFC),
                                  onRate: (stars) => _submitRating('angel', stars),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    // 😈 악마 버전 결과 카드 (activeResultMode == 'devil'일 때만)
                    if ((_devilVersion != null || _isLoadingDevil) && _activeResultMode == 'devil')
                      SafeArea(
                        child: Container(


                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE8577E).withValues(alpha: 0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE8577E).withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Flexible(
                                    child: Text('😈 악마 버전',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFE8577E)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.text_decrease, size: 18, color: Color(0xFFE8577E)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        onPressed: () => _adjustDevilTextSize(-1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.text_increase, size: 18, color: Color(0xFFE8577E)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        onPressed: () => _adjustDevilTextSize(1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFFE8577E)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        tooltip: '공유하기',
                                        onPressed: _showShareBottomSheet,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: MediaQuery.of(context).size.height * 0.28,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFFFF0F3), Color(0xFFFFE8ED)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: _isLoadingDevil
                                  ? const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(color: Color(0xFFE8577E)),
                                          SizedBox(height: 12),
                                          Text('🔥 악마 버전 생성 중...', style: TextStyle(color: Color(0xFFE8577E))),
                                        ],
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: Text(
                                        _devilVersion ?? '',
                                        style: widget.fontFamily != null
                                          ? _getFontStyle(widget.fontFamily!, _devilTextSize, fontWeight: FontWeight.w500, color: const Color(0xFF8B2252))
                                          : TextStyle(
                                              fontSize: _devilTextSize,
                                              height: 1.6,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF8B2252),
                                            ),
                                      ),
                                    ),
                              ),
                              if (_aiProvider.isNotEmpty && !_isLoadingDevil) ...[                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Powered by $_aiProvider · E2E 암호화 저장 🔑',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                _buildStarRating(
                                  currentRating: _devilRating,
                                  accentColor: const Color(0xFFE8577E),
                                  onRate: (stars) => _submitRating('devil', stars),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                  ),
                ),
              ),
              ), // AnimatedBuilder (shake)
              // 흰색 플래시 오버레이
              AnimatedBuilder(
                animation: _flashAnimation,
                builder: (context, child) {
                  if (_flashAnimation.value == 0) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.white.withValues(alpha: _flashAnimation.value),
                      ),
                    ),
                  );
                },
              ),
              // 빨간 플래시 오버레이 (악마 이펙트)
              AnimatedBuilder(
                animation: _devilFlashAnimation,
                builder: (context, child) {
                  if (_devilFlashAnimation.value == 0) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: const Color(0xFFE8577E).withValues(alpha: _devilFlashAnimation.value),
                      ),
                    ),
                  );
                },
              ),
              // confetti 위젯 — 전체 화면 덮어 콘텐츠 앞에 표시
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      maxBlastForce: 25,
                      minBlastForce: 8,
                      emissionFrequency: 0.05,
                      numberOfParticles: 40,
                      gravity: 0.15,
                      minimumSize: const Size(8, 8),
                      maximumSize: const Size(16, 16),
                      colors: _selectedConfettiTheme.colors,
                      createParticlePath: _selectedConfettiTheme.particleShape,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

  // 안전하게 폰트 스타일을 가져오는 헬퍼 메서드
  TextStyle _getFontStyle(String fontFamily, double fontSize, {FontWeight? fontWeight, Color? color}) {
    // 번들 폰트 직접 사용 (GoogleFonts 런타임 다운로드 대신)
    if (kSupportedFonts.contains(fontFamily)) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: 1.5,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? Colors.black,
      );
    } else {
      debugPrint('지원되지 않는 폰트: $fontFamily, 기본 폰트 사용');
      return TextStyle(
        fontSize: fontSize,
        height: 1.5,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? Colors.black,
      );
    }
  }


  // 기분을 영어로 변환
  String _moodToEnglish(String mood) {
    final localizations = AppLocalizations.of(context);
    
    if (localizations != null) {
      if (mood == localizations.moodHappy) return 'Happy';
      if (mood == localizations.moodSad) return 'Sad';
      if (mood == localizations.moodNeutral) return 'Neutral';
    }
    
    return 'Happy'; // 기본값
  }

  // 영어 기분을 현지화된 기분으로 변환
  String _englishMoodToLocalized(String mood) {
    final localizations = AppLocalizations.of(context);
    
    if (localizations != null) {
      if (mood == 'Happy') return localizations.moodHappy;
      if (mood == 'Sad') return localizations.moodSad;
      if (mood == 'Neutral') return localizations.moodNeutral;
    }
    
    return mood; // 매칭되지 않으면 그대로 반환
  }
}
