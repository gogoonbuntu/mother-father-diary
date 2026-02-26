import 'dart:async';
import 'package:flutter/material.dart';
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

class DiaryEntryScreen extends StatefulWidget {
  final DiaryEntry? diaryEntry;
  final Color? bgColor;
  final String? fontFamily;

  const DiaryEntryScreen({super.key, this.diaryEntry, this.bgColor, this.fontFamily});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  late ConfettiController _confettiController;
  late ConfettiTheme _selectedConfettiTheme = confettiThemes[0];
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
  bool _isLoadingPositive = false;
  bool _showSavedNotification = false;
  double _positiveTextSize = 18.0; // 긍정 버전 텍스트 크기
  bool _showPositiveVersion = false; // 긍정 버전 표시 여부
  String _aiProvider = ''; // 어떤 AI가 응답했는지 표시

  // 일일 생성 제한
  static const int _dailyFreeLimit = 3;
  int _todayCount = 0;
  bool _adGranted = false; // 광고 시청으로 1회 추가 허용
  RewardedAd? _rewardedAd;

  // 오늘 날짜 키
  String get _todayKey => 'positive_count_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';

  // 남은 무료 횟수
  int get _remainingFree => math.max(0, _dailyFreeLimit - _todayCount);

  // 일일 생성 횟수 로드
  Future<void> _loadDailyCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todayCount = prefs.getInt(_todayKey) ?? 0;
    });
  }

  // 일일 생성 횟수 증가
  Future<void> _incrementDailyCount() async {
    final prefs = await SharedPreferences.getInstance();
    _todayCount++;
    await prefs.setInt(_todayKey, _todayCount);
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
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        completer.complete(false);
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[광고] 리워드 획득: ${reward.amount} ${reward.type}');
        completer.complete(true);
      },
    );
    return completer.future;
  }

  // 생성 가능 여부 확인 후 생성
  Future<void> _tryGenerate({bool isRegenerate = false}) async {
    FocusScope.of(context).unfocus();

    // 이미 긍정 버전이 있고, 재생성이 아닌 경우 → 토글
    if (_positiveVersion != null && !isRegenerate) {
      setState(() {
        _showPositiveVersion = !_showPositiveVersion;
      });
      return;
    }

    // 광고 보너스가 있으면 사용
    if (_adGranted) {
      _adGranted = false;
      await _convertToPositiveVersion();
      return;
    }

    // 일일 한도 체크
    if (_remainingFree <= 0) {
      _showLimitDialog();
      return;
    }

    await _incrementDailyCount();
    await _convertToPositiveVersion();
  }

  // 한도 초과 다이얼로그
  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔒 오늘 무료 횟수 소진'),
        content: const Text('하루 3회 무료 생성이 가능합니다.\n광고를 시청하면 1회 추가 생성할 수 있어요!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final rewarded = await _showRewardedAd();
              if (rewarded) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 광고 시청 완료! 추가 생성이 가능합니다.')),
                  );
                }
              } else {
                // 광고 로드 실패 시에도 1회 허용 (테스트 환경 대응)
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('📢 광고 준비 중... 이번 한번은 무료로 생성해드릴게요!')),
                  );
                }
              }
              // 광고 성공/실패 무관하게 1회 추가 허용
              setState(() { _adGranted = true; });
              await _tryGenerate(isRegenerate: true);
            },
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('광고 보고 생성하기'),
          ),
        ],
      ),
    );
  }

  // 긍정 버전 생성 기능
  Future<void> _convertToPositiveVersion() async {
    // 랜덤 테마 선택
    setState(() {
      _selectedConfettiTheme = (confettiThemes..shuffle()).first;
    });
    setState(() {
      _isLoadingPositive = true;
      _positiveVersion = null;
      _aiProvider = '';
    });
    debugPrint('[API] 긍정 버전 요청 시작: ${_controller.text}');
    final gemini = GeminiService(apiKey: geminiApiKey, grokApiKey: grokApiKey);
    final result = await gemini.getPositiveVersion(_controller.text);
    debugPrint('[API] 긍정 버전 응답: ${result?.text} (provider: ${result?.provider})');
    setState(() {
      _positiveVersion = result?.text;
      _aiProvider = result?.provider ?? '';
      _isLoadingPositive = false;
      _showPositiveVersion = true; // 긍정 버전 생성 후 표시
    });
    if (result != null) {
      try {
        _confettiController.play();
      } catch (e) {
        print('컨페티 재생 오류: $e');
      }
      // 긍정 버전 생성 후 일기장 저장
      _saveDiaryEntryWithPositive();
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
          _selectedMood = _englishMoodToLocalized(existingEntry.mood);
          _positiveVersion = existingEntry.positiveVersion;
          _showPositiveVersion = _positiveVersion != null;
        });
      } else {
        setState(() {
          _controller.text = '';
          _positiveVersion = null;
          _showPositiveVersion = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _selectedDate = widget.diaryEntry?.date ?? DateTime.now();
    
    // 기본 기분 설정 - build 메서드에서 초기화
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
        _selectedMood = _englishMoodToLocalized(existingEntry.mood);
        _positiveVersion = existingEntry.positiveVersion;
        _showPositiveVersion = _positiveVersion != null;
      });
    }
  }

  Future<void> _saveDiaryEntryWithPositive() async {
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
  }

  // 긍정 버전 텍스트 크기 조절
  void _adjustPositiveTextSize(double change) {
    setState(() {
      _positiveTextSize = math.max(14.0, math.min(24.0, _positiveTextSize + change));
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
      // 초기 기분 설정
      if (_selectedMood == 'Happy') {
        _selectedMood = localizations.moodHappy;
      }
    }
    
    return WillPopScope(
      onWillPop: () async {
        await _saveDiaryEntry();
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        // 키보드가 나타날 때 화면 레이아웃 자동 조정
        resizeToAvoidBottomInset: true,
        backgroundColor: widget.bgColor ?? Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.diaryEntry == null ? AppLocalizations.of(context)!.diaryEntry : AppLocalizations.of(context)!.editDiary),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: widget.bgColor ?? Colors.white,
          ),
          child: Stack(
            children: [
              // 그래픽 버퍼 할당 문제 방지를 위해 최적화된 confetti 위젯
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  maxBlastForce: 15, // 낮춤
                  minBlastForce: 5,  // 낮춤
                  emissionFrequency: 0.1, // 낮춤
                  numberOfParticles: 20, // 줄임
                  gravity: 0.3, // 낮춤
                  minimumSize: const Size(5, 5), // 최소 크기 제한
                  maximumSize: const Size(10, 10), // 최대 크기 제한
                  colors: _selectedConfettiTheme.colors,
                  createParticlePath: _selectedConfettiTheme.particleShape,
                ),
              ),
              // 키보드 팝업시 스크롤 가능하게 하는 구조
              SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectDate(context),
                          child: Text('${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _selectedMood,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMood = newValue!;
                            });
                          },
                          items: <Map<String, String>>[
                              {'value': MOOD_HAPPY, 'label': AppLocalizations.of(context)!.moodHappy},
                              {'value': MOOD_SAD, 'label': AppLocalizations.of(context)!.moodSad},
                              {'value': MOOD_NEUTRAL, 'label': AppLocalizations.of(context)!.moodNeutral},
                            ].map<DropdownMenuItem<String>>((Map<String, String> item) {
                            return DropdownMenuItem<String>(
                              value: item['value'],
                              child: Text(item['label']!),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoadingPositive || _controller.text.trim().isEmpty ? null : () => _tryGenerate(),
                            child: _isLoadingPositive
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_positiveVersion != null 
                                    ? (_showPositiveVersion 
                                        ? AppLocalizations.of(context)!.hidePositive 
                                        : AppLocalizations.of(context)!.showPositive)
                                    : AppLocalizations.of(context)!.convertToPositive),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '🎫 $_remainingFree/$_dailyFreeLimit',
                          style: TextStyle(
                            fontSize: 13,
                            color: _remainingFree > 0 ? Colors.grey[600] : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 일기 작성 영역 - 키보드 여부에 따라 높이 조절
                    Container(
                      height: MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).size.height * 0.25
                          : MediaQuery.of(context).size.height * 0.4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                              contentPadding: const EdgeInsets.all(16.0),
                            ),
                            style: widget.fontFamily != null
                            ? _getFontStyle(widget.fontFamily!, 16)
                            : const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if ((_positiveVersion != null || _isLoadingPositive) && _showPositiveVersion)
                      SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${AppLocalizations.of(context)!.positiveVersion}${_aiProvider.isNotEmpty ? " ($_aiProvider)" : ""}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 🔄 새로 만들기 버튼 (눈에 띄게)
                                    SizedBox(
                                      height: 32,
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoadingPositive ? null : () => _tryGenerate(isRegenerate: true),
                                        icon: const Icon(Icons.refresh, size: 16),
                                        label: const Text('새로 만들기', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange.shade400,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.text_decrease, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => _adjustPositiveTextSize(-1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.text_increase, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => _adjustPositiveTextSize(1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // 긍정 버전 본문
                            Container(
                              height: MediaQuery.of(context).size.height * 0.3,
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: _isLoadingPositive
                                ? const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 12),
                                        Text('✨ 새로운 긍정 버전 생성 중...', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Text(
                                      _positiveVersion ?? '',
                                      style: widget.fontFamily != null
                                        ? _getFontStyle(widget.fontFamily!, _positiveTextSize, fontWeight: FontWeight.w500, color: Colors.black87)
                                        : TextStyle(
                                            fontSize: _positiveTextSize,
                                            height: 1.5,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
