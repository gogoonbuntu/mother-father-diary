import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:diary_app/models/diary_entry.dart';

class DiaryService {
  static final DiaryService _instance = DiaryService._internal();
  List<DiaryEntry> _diaryEntries = [];
  late File _diaryFile;

  factory DiaryService() => _instance;

  DiaryService._internal();

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _diaryFile = File('${directory.path}/diary_entries.json');
    await _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    try {
      final contents = await _diaryFile.readAsString();
      final jsonList = jsonDecode(contents);
      _diaryEntries = jsonList.map((json) => DiaryEntry.fromJson(json)).toList();
    } catch (e) {
      _diaryEntries = [];
    }
  }

  Future<void> _saveDiaryEntries() async {
    final jsonList = _diaryEntries.map((entry) => entry.toJson()).toList();
    await _diaryFile.writeAsString(jsonEncode(jsonList));
  }

  Future<void> addDiaryEntry(DiaryEntry entry) async {
    _diaryEntries.add(entry);
    await _saveDiaryEntries();
  }

  List<DiaryEntry> getDiaryEntries() {
    return _diaryEntries;
  }

  DiaryEntry? getDiaryEntryForDate(DateTime date) {
    try {
      return _diaryEntries.firstWhere(
        (entry) => isSameDate(entry.date, date),
      );
    } catch (e) {
      return null;
    }
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> updateDiaryEntry(String id, DiaryEntry entry) async {
    int index = _diaryEntries.indexWhere((element) => element.id == id);
    if (index != -1) {
      _diaryEntries[index] = entry;
      await _saveDiaryEntries();
    }
  }

  Future<void> deleteDiaryEntry(String id) async {
    _diaryEntries.removeWhere((entry) => entry.id == id);
    await _saveDiaryEntries();
  }
}
