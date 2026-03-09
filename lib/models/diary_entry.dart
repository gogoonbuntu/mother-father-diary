import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String mood;
  final String content;
  final String? positiveVersion; // 천사 버전 (긍정)
  final String? devilVersion;    // 악마 버전 (공감+분노)

  DiaryEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.content,
    this.positiveVersion,
    this.devilVersion,
  });

  factory DiaryEntry.create({
    required DateTime date,
    required String mood,
    required String content,
    String? positiveVersion,
    String? devilVersion,
  }) {
    return DiaryEntry(
      id: const Uuid().v4(),
      date: date,
      mood: mood,
      content: content,
      positiveVersion: positiveVersion,
      devilVersion: devilVersion,
    );
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      mood: json['mood'],
      content: json['content'],
      positiveVersion: json['positiveVersion'],
      devilVersion: json['devilVersion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'content': content,
      'positiveVersion': positiveVersion,
      'devilVersion': devilVersion,
    };
  }

  @override
  String toString() {
    return '${DateFormat('yyyy-MM-dd').format(date)} - $mood\n$content';
  }
}
