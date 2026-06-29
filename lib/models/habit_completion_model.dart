import 'package:cloud_firestore/cloud_firestore.dart';

class HabitCompletionModel {
  final String completionId;
  final String habitId;
  final String userId;
  final DateTime date;
  final bool isCompleted;
  final String note;
  final DateTime createdAt;

  const HabitCompletionModel({
    required this.completionId,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.isCompleted,
    required this.note,
    required this.createdAt,
  });

  factory HabitCompletionModel.create({
    required String habitId,
    required String userId,
    required DateTime date,
    bool isCompleted = true,
    String note = '',
  }) {
    return HabitCompletionModel(
      completionId: '',
      habitId: habitId,
      userId: userId,
      date: _dateOnly(date),
      isCompleted: isCompleted,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  factory HabitCompletionModel.fromMap(Map<String, dynamic> data, String id) {
    final now = DateTime.now();

    return HabitCompletionModel(
      completionId: id,
      habitId: data['habitId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      date: _readDate(data['date']) ?? now,
      isCompleted:
          data['isCompleted'] as bool? ?? data['completed'] as bool? ?? false,
      note: data['note'] as String? ?? '',
      createdAt: _readDate(data['createdAt']) ?? now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'userId': userId,
      'date': Timestamp.fromDate(_dateOnly(date)),
      'isCompleted': isCompleted,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
