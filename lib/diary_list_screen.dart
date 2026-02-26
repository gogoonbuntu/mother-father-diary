import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/generated/app_localizations.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/services/diary_service.dart';
// 클래스만 import하여 충돌 방지
import 'package:diary_app/diary_entry_screen.dart' show DiaryEntryScreen;

class DiaryListScreen extends StatefulWidget {
  final Color? bgColor;
  final String? fontFamily;
  const DiaryListScreen({super.key, this.bgColor, this.fontFamily});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  List<DiaryEntry> _diaryEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final entries = await DiaryService().getDiaryEntries();
      if (mounted) {
        setState(() {
          _diaryEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading diary entries: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.diaryList),
      ),
      body: Container(
        color: widget.bgColor ?? Colors.white,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDiaryEntries,
                child: _diaryEntries.isEmpty
                    ? Center(child: Text(AppLocalizations.of(context)!.noDiaries))
                    : ListView.builder(
                        itemCount: _diaryEntries.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                title: Text(
                                  DateFormat('yyyy-MM-dd').format(_diaryEntries[index].date),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  _diaryEntries[index].content.split('\n').take(3).join('\n'),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    bool confirm = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('삭제 확인'),
                                        content: const Text('이 일기를 삭제하시겠습니까?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
                                        ],
                                      ),
                                    );
                                    if (confirm) {
                                      await DiaryService().deleteDiaryEntry(_diaryEntries[index].id);
                                      _loadDiaryEntries();
                                    }
                                  },
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DiaryEntryScreen(
                                        diaryEntry: _diaryEntries[index],
                                        bgColor: widget.bgColor,
                                        fontFamily: widget.fontFamily,
                                      ),
                                    ),
                                  ).then((_) => _loadDiaryEntries());
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
