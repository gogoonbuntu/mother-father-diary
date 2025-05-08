import 'dart:async';
import 'package:flutter/material.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:diary_app/services/diary_service.dart';
import 'package:diary_app/services/gemini_service.dart';
import 'package:diary_app/services/gemini_api_key.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as Math; 
import 'confetti_themes.dart';

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

  String? _positiveVersion;
  bool _isLoadingPositive = false;
  bool _showSavedNotification = false;

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
    });
    if (result != null) {
      _confettiController.play();
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
        });
      } else {
        setState(() {
          _controller.clear();
          _selectedMood = 'Happy';
        });
      }
    }
  }

  @override
  void initState() {
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    super.initState();
    _selectedDate = widget.diaryEntry?.date ?? DateTime.now();
    _selectedMood = widget.diaryEntry?.mood ?? 'Happy';
    _controller.text = widget.diaryEntry?.content ?? '';

    if (_controller.text.isEmpty) {
      // initState에서는 async를 직접 사용할 수 없으므로 별도 메서드로 추출
      _loadExistingEntry();
    }

    _controller.addListener(_saveDiaryEntry);
    _controller.addListener(() {
      setState(() {}); // 입력값 변경 시 버튼 상태 갱신
    });
  }

  Timer? _debounceTimer;
  
  // 기존 일기 데이터 로드하는 메서드
  Future<void> _loadExistingEntry() async {
    final existingEntry = await DiaryService().getDiaryEntryForDate(_selectedDate);
    if (existingEntry != null && mounted) {
      setState(() {
        _controller.text = existingEntry.content;
        _selectedMood = existingEntry.mood;
      });
    }
  }

  void _saveDiaryEntry() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final content = _controller.text.trim();
      if (content.isEmpty) return;
      
      // 비동기로 기존 일기 확인
      final existingEntry = await DiaryService().getDiaryEntryForDate(_selectedDate);
      DiaryEntry entry;
      
      if (existingEntry != null) {
        entry = DiaryEntry(
          id: existingEntry.id,
          date: _selectedDate,
          mood: _selectedMood,
          content: content,
        );
        debugPrint('[DiaryService] updateDiaryEntry 호출');
        await DiaryService().updateDiaryEntry(existingEntry.id, entry);
      } else {
        entry = DiaryEntry.create(
          date: _selectedDate,
          mood: _selectedMood,
          content: content,
        );
        debugPrint('[DiaryService] addDiaryEntry 호출');
        await DiaryService().addDiaryEntry(entry);
      }
      setState(() {
        _showSavedNotification = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _showSavedNotification = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 저장 필요시만 저장, 중복 메서드 제거
        if (_controller.text.trim().isNotEmpty) {
          _saveDiaryEntry();
        }
        Navigator.pop(context, true); // Return true to indicate refresh is needed
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.diaryEntry != null ? AppLocalizations.of(context)!.editDiary : AppLocalizations.of(context)!.diaryEntry),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: widget.bgColor ?? Colors.white,
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  maxBlastForce: 20,
                  minBlastForce: 8,
                  emissionFrequency: 0.15,
                  numberOfParticles: 30,
                  gravity: 0.4,
                  colors: _selectedConfettiTheme.colors,
                  createParticlePath: _selectedConfettiTheme.particleShape,
                ),
              ),
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
                        items: <String>[
                            AppLocalizations.of(context)!.moodHappy,
                            AppLocalizations.of(context)!.moodSad,
                            AppLocalizations.of(context)!.moodNeutral,
                          ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isLoadingPositive || _controller.text.trim().isEmpty ? null : _convertToPositiveVersion,
                    child: _isLoadingPositive
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(AppLocalizations.of(context)!.convertToPositive),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CustomPaint(
                      painter: LinePainter(),
                      child: Container(
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
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontFamily: widget.fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_positiveVersion != null)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.positiveVersion, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(_positiveVersion!),
                            ],
                          ),
                        ),
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
}

class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += 24; // line spacing
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
