import 'package:cloud_firestore/cloud_firestore.dart';

class HabitLogModel {
  final String logId;
  final String habitId;
  final DateTime date;
  final bool completed;

  HabitLogModel({
    required this.logId,
    required this.habitId,
    required this.date,
    required this.completed,
  });

  factory HabitLogModel.fromMap(Map<String, dynamic> data, String id) {
    return HabitLogModel(
      logId: id,
      habitId: data['habitId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'date': Timestamp.fromDate(date),
      'completed': completed,
    };
  }
}
