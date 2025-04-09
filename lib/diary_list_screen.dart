import 'package:flutter/material.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/services/diary_service.dart';
import 'package:diary_app/diary_entry_screen.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  List<DiaryEntry> _diaryEntries = [];

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    setState(() {
      _diaryEntries = DiaryService().getDiaryEntries().reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 목록'),
      ),
      body: ListView.builder(
        itemCount: _diaryEntries.length,
        itemBuilder: (context, index) {
          int actualIndex = _diaryEntries.length - 1 - index; // Correct index for reversed list
          return ListTile(
            title: Text(_diaryEntries[index].toString()),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DiaryEntryScreen(diaryEntry: _diaryEntries[index])),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await DiaryService().deleteDiaryEntry(_diaryEntries[index].id);
                setState(() {
                  _diaryEntries = DiaryService().getDiaryEntries().reversed.toList();
                });
              },
            ),
          );
        },
      ),
    );
  }
}
