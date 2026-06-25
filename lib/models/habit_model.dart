import 'package:cloud_firestore/cloud_firestore.dart';

class HabitModel {
  final String habitId;
  final String userId;
  final String title;
  final String description;
  final String category;
  final int targetPerDay;
  final DateTime createdAt;

  HabitModel({
    required this.habitId,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.targetPerDay,
    required this.createdAt,
  });

  factory HabitModel.fromMap(Map<String, dynamic> data, String id) {
    return HabitModel(
      habitId: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      targetPerDay: data['targetPerDay'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'targetPerDay': targetPerDay,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
