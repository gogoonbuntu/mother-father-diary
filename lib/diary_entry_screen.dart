import 'dart:async';
import 'package:flutter/material.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:diary_app/services/diary_service.dart';
import 'package:diary_app/services/gemini_service.dart';
import 'package:diary_app/services/gemini_api_key.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math; 
import 'confetti_themes.dart';
import 'package:google_fonts/google_fonts.dart'; // 한글 글씨체 사용을 위한 패키지 추가
import 'line_painter.dart'; // LinePainter 클래스 import

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

  // 긍정 버전 토글 및 생성 기능
  Future<void> _togglePositiveVersion() async {
    // 키보드 닫기
    FocusScope.of(context).unfocus();
    
    // 이미 긍정 버전이 있는 경우 토글
    if (_positiveVersion != null) {
      setState(() {
        _showPositiveVersion = !_showPositiveVersion;
      });
      return;
    }
    
    // 긍정 버전이 없는 경우 새로 생성
    await _convertToPositiveVersion();
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
    });
    debugPrint('[API] 긍정 버전 요청 시작: ${_controller.text}');
    final gemini = GeminiService(apiKey: geminiApiKey);
    final result = await gemini.getPositiveVersion(_controller.text);
    debugPrint('[API] 긍정 버전 응답: $result');
    setState(() {
      _positiveVersion = result;
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
    
    // 텍스트 변경 감지
    _controller.addListener(_saveDiaryEntry);
    _controller.addListener(() {
      setState(() {}); // 입력값 변경 시 버튼 상태 갱신
    });
    
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
    
    // 키보드 닫기
    FocusScope.of(context).unfocus();
    
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
    _confettiController.dispose();
    _controller.dispose();
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
              Column(
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
                  ElevatedButton(
                    onPressed: _isLoadingPositive || _controller.text.trim().isEmpty ? null : _togglePositiveVersion,
                    child: _isLoadingPositive
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_positiveVersion != null 
                            ? (_showPositiveVersion 
                                ? AppLocalizations.of(context)!.hidePositive 
                                : AppLocalizations.of(context)!.showPositive)
                            : AppLocalizations.of(context)!.convertToPositive),
                  ),
                  const SizedBox(height: 8),
                  // 일기 작성 영역 - Expanded 대신 특정 크기로 고정
                  Container(
                    height: MediaQuery.of(context).size.height * 0.4, // 화면 높이의 40%로 고정
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
                  if (_positiveVersion != null && _showPositiveVersion)
                    SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.positiveVersion,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.text_decrease),
                                    onPressed: () => _adjustPositiveTextSize(-1),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.text_increase),
                                    onPressed: () => _adjustPositiveTextSize(1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // 고정 높이로 설정하여 레이아웃 문제 해결
                          Container(
                            height: MediaQuery.of(context).size.height * 0.3,
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: _positiveVersion != null ? Text(
                              _positiveVersion!,
                              style: widget.fontFamily != null
                                ? _getFontStyle(widget.fontFamily!, _positiveTextSize, fontWeight: FontWeight.w500, color: Colors.black87)
                                : TextStyle(
                                    fontSize: _positiveTextSize,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                            ) : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                ],
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
