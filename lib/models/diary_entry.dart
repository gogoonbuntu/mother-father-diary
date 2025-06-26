import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String mood;
  final String content;
  final String? positiveVersion; // 긍정 버전 텍스트 저장 필드 추가

  DiaryEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.content,
    this.positiveVersion,
  });

  factory DiaryEntry.create({
    required DateTime date,
    required String mood,
    required String content,
    String? positiveVersion,
  }) {
    return DiaryEntry(
      id: const Uuid().v4(),
      date: date,
      mood: mood,
      content: content,
      positiveVersion: positiveVersion,
    );
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      mood: json['mood'],
      content: json['content'],
      positiveVersion: json['positiveVersion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'content': content,
      'positiveVersion': positiveVersion,
    };
  }

  @override
  String toString() {
    return '${DateFormat('yyyy-MM-dd').format(date)} - $mood\n$content';
  }
}
