import 'dart:async';

import 'package:flutter/material.dart';

import '../models/habit_completion_model.dart';
import '../models/habit_model.dart';
import '../models/habit_template_model.dart';
import '../repositories/habit_repository.dart';

class HabitProvider with ChangeNotifier {
  final HabitRepository _repository = HabitRepository();
  StreamSubscription<List<HabitModel>>? _habitSubscription;
  List<HabitModel> _habits = [];
  List<HabitTemplateModel> _templates = _defaultTemplates;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  List<HabitModel> get habits => _habits;
  List<HabitTemplateModel> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void fetchHabits(String userId) {
    if (_currentUserId == userId && _habitSubscription != null) {
      return;
    }

    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _habitSubscription?.cancel();
    _habitSubscription = _repository.streamHabits(userId).listen(
      (habits) {
        _habits = habits;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách thói quen. Vui lòng thử lại.';
        notifyListeners();
      },
    );
  }

  Future<bool> addHabit(HabitModel habit) async {
    return _runAction(() async {
      await _repository.createHabit(habit);
    });
  }

  Future<void> fetchHabitTemplates() async {
    try {
      final templates = await _repository.getHabitTemplates();
      if (templates.isNotEmpty && !_hasBrokenTemplateText(templates)) {
        _templates = templates;
        notifyListeners();
      } else {
        _templates = _defaultTemplates;
        notifyListeners();
      }
    } catch (_) {
      _templates = _defaultTemplates;
    }
  }

  Future<bool> updateHabit(HabitModel habit) async {
    return _runAction(() => _repository.updateHabit(habit));
  }

  Future<bool> deleteHabit(String habitId) async {
    return _runAction(() => _repository.softDeleteHabit(habitId));
  }

  Future<bool> pauseHabit(String habitId) async {
    return _runAction(() => _repository.pauseHabit(habitId));
  }

  Future<bool> resumeHabit(String habitId) async {
    return _runAction(() => _repository.resumeHabit(habitId));
  }

  Future<bool> archiveHabit(String habitId) async {
    return _runAction(() => _repository.archiveHabit(habitId));
  }

  Future<bool> markHabitCompleted({
    required String userId,
    required String habitId,
    required DateTime date,
    required bool isCompleted,
    String note = '',
  }) async {
    return _runAction(
      () => _repository.markHabitCompleted(
        userId: userId,
        habitId: habitId,
        date: date,
        isCompleted: isCompleted,
        note: note,
      ),
    );
  }

  Stream<List<HabitCompletionModel>> streamCompletions({
    required String userId,
    required String habitId,
  }) {
    return _repository.streamCompletions(userId: userId, habitId: habitId);
  }

  Stream<List<HabitCompletionModel>> streamUserCompletions(String userId) {
    return _repository.streamUserCompletions(userId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    _errorMessage = null;

    try {
      await action();
      return true;
    } catch (_) {
      _errorMessage = 'Không thể lưu thói quen. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _habitSubscription?.cancel();
    super.dispose();
  }
}

bool _hasBrokenTemplateText(List<HabitTemplateModel> templates) {
  return templates.any(
    (template) =>
        _hasMojibake(template.name) ||
        _hasMojibake(template.description) ||
        _hasMojibake(template.category),
  );
}

bool _hasMojibake(String value) {
  return value.contains('á»') ||
      value.contains('áº') ||
      value.contains('Ă') ||
      value.contains('Ä') ||
      value.contains('Æ') ||
      value.contains('Â') ||
      value.contains('�');
}

const _defaultTemplates = [
  HabitTemplateModel(
    templateId: 'drink_water',
    name: 'Uống nước',
    description: 'Uống đủ nước mỗi ngày để duy trì sức khỏe.',
    category: 'Sức khỏe',
    frequency: HabitFrequency.daily,
    difficulty: HabitDifficulty.easy,
    isActive: true,
  ),
  HabitTemplateModel(
    templateId: 'read_book',
    name: 'Đọc sách',
    description: 'Đọc sách 20-30 phút mỗi ngày.',
    category: 'Học tập',
    frequency: HabitFrequency.daily,
    difficulty: HabitDifficulty.easy,
    isActive: true,
  ),
  HabitTemplateModel(
    templateId: 'exercise',
    name: 'Tập thể dục',
    description: 'Vận động hoặc tập luyện ít nhất 20 phút.',
    category: 'Sức khỏe',
    frequency: HabitFrequency.weekly,
    difficulty: HabitDifficulty.medium,
    isActive: true,
  ),
  HabitTemplateModel(
    templateId: 'meditation',
    name: 'Thiền',
    description: 'Dành vài phút để thở sâu và tập trung.',
    category: 'Tinh thần',
    frequency: HabitFrequency.daily,
    difficulty: HabitDifficulty.easy,
    isActive: true,
  ),
  HabitTemplateModel(
    templateId: 'learn_english',
    name: 'Học tiếng Anh',
    description: 'Học từ vựng hoặc luyện nghe tiếng Anh mỗi ngày.',
    category: 'Học tập',
    frequency: HabitFrequency.daily,
    difficulty: HabitDifficulty.medium,
    isActive: true,
  ),
  HabitTemplateModel(
    templateId: 'sleep_early',
    name: 'Ngủ sớm',
    description: 'Đi ngủ đúng giờ để cải thiện năng lượng ngày hôm sau.',
    category: 'Sức khỏe',
    frequency: HabitFrequency.daily,
    difficulty: HabitDifficulty.medium,
    isActive: true,
  ),
];
