import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/generated/app_localizations.dart';
import 'package:diary_app/services/diary_service.dart';
import 'package:diary_app/services/gemini_service.dart';
import 'package:diary_app/services/gemini_api_key.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math; 
import 'confetti_themes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'line_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:diary_app/services/purchase_service.dart';
import 'package:diary_app/premium_screen.dart';

class DiaryEntryScreen extends StatefulWidget {
  final DiaryEntry? diaryEntry;
  final Color? bgColor;
  final String? fontFamily;

  const DiaryEntryScreen({super.key, this.diaryEntry, this.bgColor, this.fontFamily});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late ConfettiTheme _selectedConfettiTheme = confettiThemes[0];

  // 화면 플래시 애니메이션
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
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

  // 생성 제한
  static const int _dailyFreeLimit = 3;
  static const int _monthlyPremiumLimit = 50;
  int _todayCount = 0;
  int _monthCount = 0;
  bool _adGranted = false; // 광고 시청으로 1회 추가 허용
  RewardedAd? _rewardedAd;
  final _purchaseService = PurchaseService();

  // 날짜 키
  String get _todayKey => 'positive_count_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
  String get _monthKey => 'premium_month_count_${DateTime.now().year}-${DateTime.now().month}';

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

    // 이미 해당 버전이 있으면 → 재생성 확인 팝업
    final hasVersion = (mode == 'angel' && _positiveVersion != null) ||
                       (mode == 'devil' && _devilVersion != null);
    if (hasVersion) {
      _showRegenerateConfirm(mode);
      return;
    }

    // 첫 생성
    _tryGenerate(mode: mode);
  }

  // 재생성 확인 팝업
  void _showRegenerateConfirm(String mode) {
    final label = mode == 'angel' ? '천사' : '악마';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🔄 $label 버전 재생성'),
        content: Text('새로운 $label 버전을 생성하시겠습니까?\n\n⚠️ 1회가 소모됩니다.\n(남은 횟수: ${_purchaseService.isPremium ? '$_remainingPremium/$_monthlyPremiumLimit 월' : '$_remainingFree/$_dailyFreeLimit 일'})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
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
            child: const Text('재생성'),
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
                  ? '월 $_monthlyPremiumLimit회 프리미엄 횟수를 모두 사용했습니다.\n광고를 보면 추가 생성할 수 있어요!'
                  : '하루 $_dailyFreeLimit회 무료 생성 횟수를 모두 사용했습니다.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
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
                label: const Text('광고 보고 1회 생성하기'),
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
                            content: const Text('🎉 프리미엄 활성화! 월 50회까지 사용하세요!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: const Color(0xFF7C5CFC),
                          ),
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.diamond_rounded, size: 18),
                  label: const Text('프리미엄 구독 (월 50회)'),
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
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
        ],
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
      _saveDiaryEntryWithVersions();
    }
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
    
    // 지연된 초기화를 위해 다음 프레임에서 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingEntry();
    });
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
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveDiaryEntry();
        if (context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            widget.diaryEntry == null ? AppLocalizations.of(context)!.diaryEntry : AppLocalizations.of(context)!.editDiary,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF3EEFF), // 연보라
                Color(0xFFFFF0F5), // 연핑크
                Color(0xFFEEF7FF), // 연하늘
              ],
            ),
          ),
          child: Stack(
            children: [
              // 키보드 팝업시 스크롤 가능하게 하는 구조
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    left: 16, right: 16, bottom: 24,
                  ),
                  child: Column(
                    children: [
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
                                  _positiveVersion != null ? '천사 재생성' : '천사 버전',
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
                                  _devilVersion != null ? '악마 재생성' : '악마 버전',
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
                          // 잔여 횟수
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
                    // 일기 작성 영역
                    Container(
                      height: MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).size.height * 0.25
                          : MediaQuery.of(context).size.height * 0.35,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C5CFC).withValues(alpha: 0.08),
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
                                hintText: AppLocalizations.of(context)!.diaryHint,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
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
                    const SizedBox(height: 16),
                    // 😇 천사 버전 결과 카드 (activeResultMode == 'angel'일 때만)
                    if ((_positiveVersion != null || _isLoadingPositive) && _activeResultMode == 'angel')
                      SafeArea(
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
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
                              if (_aiProvider.isNotEmpty && !_isLoadingPositive)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Powered by $_aiProvider · E2E 암호화 저장 🔑',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    // 😈 악마 버전 결과 카드 (activeResultMode == 'devil'일 때만)
                    if ((_devilVersion != null || _isLoadingDevil) && _activeResultMode == 'devil')
                      SafeArea(
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
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
                              if (_aiProvider.isNotEmpty && !_isLoadingDevil)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Powered by $_aiProvider · E2E 암호화 저장 🔑',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  ),
                ),
              ),
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
        ),
      ),
    );
  }
  
  // 안전하게 폰트 스타일을 가져오는 헬퍼 메서드
  TextStyle _getFontStyle(String fontFamily, double fontSize, {FontWeight? fontWeight, Color? color}) {
    // 지원되는 폰트 목록 - main.dart와 일치시킴
    final supportedFonts = [
      'Roboto',      // 기본 영문 폰트
      'NotoSansKR',  // 한글 기본 폰트
      'NanumGothic', // 한글 기본 폰트
      'NanumMyeongjo', // 한글 글씨체
      'Jua',         // 한글 글씨체
      'GamjaFlower', // 한글 글씨체
      'DoHyeon',     // 한글 글씨체
      'PoorStory',   // 한글 글씨체
    ];
    
    try {
      // 지원되는 폰트인지 확인
      if (supportedFonts.contains(fontFamily)) {
        return GoogleFonts.getFont(
          fontFamily,
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
    } catch (e) {
      debugPrint('폰트 로딩 오류: $e');
      // 폰트 로딩 실패 시 기본 폰트 사용
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
