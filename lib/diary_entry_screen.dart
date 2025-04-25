import 'dart:async';
import 'package:flutter/material.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/services/diary_service.dart';
import 'package:diary_app/services/gemini_service.dart';
import 'package:diary_app/services/gemini_api_key.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as Math; 
import 'confetti_themes.dart';

class DiaryEntryScreen extends StatefulWidget {
  final DiaryEntry? diaryEntry;

  const DiaryEntryScreen({super.key, this.diaryEntry});

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
        final existingEntry = DiaryService().getDiaryEntryForDate(_selectedDate);
        if (existingEntry != null) {
          _controller.text = existingEntry.content;
          _selectedMood = existingEntry.mood;
        } else {
          _controller.clear();
          _selectedMood = 'Happy';
        }
      });
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
      final existingEntry = DiaryService().getDiaryEntryForDate(_selectedDate);
      if (existingEntry != null) {
        _controller.text = existingEntry.content;
        _selectedMood = existingEntry.mood;
      }
    }

    _controller.addListener(_saveDiaryEntry);
  }

  Timer? _debounceTimer;

  void _saveDiaryEntry() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final content = _controller.text.trim();
      if (content.isEmpty) return;
      final existingEntry = DiaryService().getDiaryEntryForDate(_selectedDate);
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
          title: Text(widget.diaryEntry != null ? '일기 수정' : '일기 쓰기'),
        ),
        body: Stack(
          children: [
            // 샤랄라/별빛 효과 (confetti)
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
            // 기존 Column UI
            Column(
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                          '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedMood,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMood = newValue!;
                        });
                      },
                      items: <String>['Happy', 'Sad', 'Neutral']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isLoadingPositive ? null : _convertToPositiveVersion,
                  child: _isLoadingPositive
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('긍정 버전으로 변환'),
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
                          hintText: '일기를 입력하세요',
                          contentPadding: const EdgeInsets.all(16.0),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_positiveVersion != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('긍정 버전:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_positiveVersion!),
                      ],
                    ),
                  ),
              ],
            ),
          ],
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
