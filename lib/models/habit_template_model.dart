import 'package:cloud_firestore/cloud_firestore.dart';

import 'habit_model.dart';

class HabitTemplateModel {
  final String templateId;
  final String name;
  final String description;
  final String category;
  final String frequency;
  final String difficulty;
  final bool isActive;
  final DateTime? createdAt;

  const HabitTemplateModel({
    required this.templateId,
    required this.name,
    required this.description,
    required this.category,
    required this.frequency,
    required this.difficulty,
    required this.isActive,
    this.createdAt,
  });

  factory HabitTemplateModel.fromMap(Map<String, dynamic> data, String id) {
    return HabitTemplateModel(
      templateId: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      frequency: data['frequency'] as String? ?? HabitFrequency.daily,
      difficulty: data['difficulty'] as String? ?? HabitDifficulty.easy,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _readDate(data['createdAt']),
    );
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
