import 'dart:async';
import 'package:flutter/material.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/services/diary_service.dart';

class DiaryEntryScreen extends StatefulWidget {
  final DiaryEntry? diaryEntry;

  const DiaryEntryScreen({super.key, this.diaryEntry});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedMood;


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
    _debounceTimer = Timer(const Duration(seconds: 3), () async {
      if (_controller.text.isNotEmpty) {
        final existingEntry = DiaryService().getDiaryEntryForDate(_selectedDate);
        DiaryEntry entry = DiaryEntry.create(
          date: _selectedDate,
          mood: _selectedMood,
          content: _controller.text,
        );
        entry = DiaryEntry(
          id: existingEntry?.id ?? entry.id,
          date: entry.date,
          mood: entry.mood,
          content: entry.content,
        );
        if (existingEntry != null) {
          await DiaryService().updateDiaryEntry(existingEntry.id, entry);
        } else {
          await DiaryService().addDiaryEntry(entry);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일기가 저장되었습니다')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _saveDiaryEntryImmediately();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveDiaryEntryImmediately() async {
    _debounceTimer?.cancel();
    if (_controller.text.isNotEmpty) {
      DiaryEntry entry = DiaryEntry.create(
        date: _selectedDate,
        mood: _selectedMood,
        content: _controller.text,
      );
      if (widget.diaryEntry != null) {
        await DiaryService().updateDiaryEntry(widget.diaryEntry!.id, entry);
      } else {
        await DiaryService().addDiaryEntry(entry);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diaryEntry != null ? '일기 수정' : '일기 쓰기'),
      ),
      body: Column(
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
        ],
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
