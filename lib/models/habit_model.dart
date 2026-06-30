import 'package:cloud_firestore/cloud_firestore.dart';

class HabitModel {
  final String habitId;
  final String userId;
  final String name;
  final String description;
  final String category;
  final String frequency;
  final String reminderTime;
  final String priority;
  final String difficulty;
  final String status;
  final DateTime startDate;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitModel({
    required this.habitId,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.frequency,
    required this.reminderTime,
    required this.priority,
    required this.difficulty,
    required this.status,
    required this.startDate,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HabitModel.create({
    required String userId,
    required String name,
    String description = '',
    String category = '',
    String frequency = HabitFrequency.daily,
    String reminderTime = '',
    String priority = HabitPriority.medium,
    String difficulty = HabitDifficulty.easy,
    DateTime? startDate,
  }) {
    final now = DateTime.now();
    return HabitModel(
      habitId: '',
      userId: userId,
      name: name,
      description: description,
      category: category,
      frequency: frequency,
      reminderTime: reminderTime,
      priority: priority,
      difficulty: difficulty,
      status: HabitStatus.active,
      startDate: startDate ?? DateTime(now.year, now.month, now.day),
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory HabitModel.fromMap(Map<String, dynamic> data, String id) {
    final now = DateTime.now();

    return HabitModel(
      habitId: id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      frequency: data['frequency'] as String? ?? HabitFrequency.daily,
      reminderTime: data['reminderTime'] as String? ?? '',
      priority: data['priority'] as String? ?? HabitPriority.medium,
      difficulty: data['difficulty'] as String? ?? HabitDifficulty.easy,
      status: data['status'] as String? ?? HabitStatus.active,
      startDate: _readDate(data['startDate']) ?? _readDate(data['createdAt']) ?? now,
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']) ?? now,
      updatedAt: _readDate(data['updatedAt']) ?? _readDate(data['createdAt']) ?? now,
    );
  }

  HabitModel copyWith({
    String? habitId,
    String? userId,
    String? name,
    String? description,
    String? category,
    String? frequency,
    String? reminderTime,
    String? priority,
    String? difficulty,
    String? status,
    DateTime? startDate,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitModel(
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      priority: priority ?? this.priority,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'category': category,
      'frequency': frequency,
      'reminderTime': reminderTime,
      'priority': priority,
      'difficulty': difficulty,
      'status': status,
      'startDate': Timestamp.fromDate(_dateOnly(startDate)),
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'frequency': frequency,
      'reminderTime': reminderTime,
      'priority': priority,
      'difficulty': difficulty,
      'status': status,
      'startDate': Timestamp.fromDate(_dateOnly(startDate)),
      'isDeleted': isDeleted,
      'updatedAt': Timestamp.fromDate(updatedAt),
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

class HabitStatus {
  static const active = 'Active';
  static const paused = 'Paused';
  static const archived = 'Archived';
  static const deleted = 'Deleted';

  static const values = [active, paused, archived, deleted];
}

class HabitPriority {
  static const low = 'Low';
  static const medium = 'Medium';
  static const high = 'High';

  static const values = [low, medium, high];
}

class HabitDifficulty {
  static const easy = 'Easy';
  static const medium = 'Medium';
  static const hard = 'Hard';

  static const values = [easy, medium, hard];
}

class HabitFrequency {
  static const daily = 'Daily';
  static const weekly = 'Weekly';
  static const custom = 'Custom';

  static const values = [daily, weekly, custom];
}
