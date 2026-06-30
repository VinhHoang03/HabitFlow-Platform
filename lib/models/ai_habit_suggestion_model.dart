import 'habit_model.dart';

class AiHabitSuggestionModel {
  final String name;
  final String description;
  final String category;
  final String frequency;
  final String priority;
  final String difficulty;
  final String reminderTime;
  final String reason;

  const AiHabitSuggestionModel({
    required this.name,
    required this.description,
    required this.category,
    required this.frequency,
    required this.priority,
    required this.difficulty,
    required this.reminderTime,
    required this.reason,
  });

  factory AiHabitSuggestionModel.fromMap(Map<String, dynamic> data) {
    return AiHabitSuggestionModel(
      name: _readText(data['name'], fallback: 'Thói quen mới'),
      description: _readText(data['description']),
      category: _readText(data['category'], fallback: 'Phát triển bản thân'),
      frequency: _readAllowed(
        data['frequency'],
        HabitFrequency.values,
        HabitFrequency.daily,
      ),
      priority: _readAllowed(
        data['priority'],
        HabitPriority.values,
        HabitPriority.medium,
      ),
      difficulty: _readAllowed(
        data['difficulty'],
        HabitDifficulty.values,
        HabitDifficulty.easy,
      ),
      reminderTime: _readText(data['reminderTime']),
      reason: _readText(data['reason']),
    );
  }

  HabitModel toHabit(String userId) {
    return HabitModel.create(
      userId: userId,
      name: name,
      description: description,
      category: category,
      frequency: frequency,
      reminderTime: reminderTime,
      priority: priority,
      difficulty: difficulty,
    );
  }

  static String _readText(dynamic value, {String fallback = ''}) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  static String _readAllowed(
    dynamic value,
    List<String> allowedValues,
    String fallback,
  ) {
    final text = value is String ? value.trim() : '';
    return allowedValues.contains(text) ? text : fallback;
  }
}
