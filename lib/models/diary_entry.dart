import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String mood;
  final String content;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.content,
  });

  factory DiaryEntry.create({
    required DateTime date,
    required String mood,
    required String content,
  }) {
    return DiaryEntry(
      id: const Uuid().v4(),
      date: date,
      mood: mood,
      content: content,
    );
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      mood: json['mood'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'content': content,
    };
  }

  @override
  String toString() {
    return '${DateFormat('yyyy-MM-dd').format(date)} - $mood\n$content';
  }
}
