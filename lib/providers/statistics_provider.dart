import 'dart:async';

import 'package:flutter/material.dart';

import '../models/achievement_model.dart';
import '../models/habit_log_model.dart';
import '../models/habit_model.dart';
import '../repositories/statistics_repository.dart';

class StatisticsProvider with ChangeNotifier {
  StatisticsRepository? _repository;
  StatisticsRepository get repository => _repository ??= StatisticsRepository();

  StreamSubscription<List<HabitLogModel>>? _logsSubscription;
  StreamSubscription<List<AchievementModel>>? _achievementsSubscription;
  StreamSubscription<Set<String>>? _unlockedSubscription;

  List<HabitModel> _habits = [];
  List<HabitLogModel> _logs = [];
  List<AchievementModel> _achievements = AchievementModel.defaultAchievements;
  Set<String> _unlockedAchievementIds = {};
  String? _userId;
  String _habitKey = '';

  List<HabitLogModel> get completedLogs =>
      _logs.where((log) => log.completed).toList();
  List<AchievementModel> get achievements => _achievements;
  Set<String> get unlockedAchievementIds => _unlockedAchievementIds;

  int get completedCount => completedLogs.length;
  int get currentStreak => _calculateCurrentStreak(completedLogs);
  int get bestStreak => _calculateBestStreak(completedLogs);

  double get completionRate {
    if (_habits.isEmpty) {
      return 0;
    }

    final totalExpected = _habits.length * 7;
    final completedThisWeek = weeklyCompletedCounts.fold<int>(
      0,
      (total, value) => total + value,
    );

    return (completedThisWeek / totalExpected).clamp(0, 1);
  }

  List<int> get weeklyCompletedCounts {
    final now = DateTime.now();
    final monday = _startOfDay(now).subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      return completedLogs.where((log) => _isSameDay(log.date, day)).length;
    });
  }

  List<int> get monthlyCompletedCounts {
    final now = DateTime.now();
    final weeks = List<int>.filled(5, 0);

    for (final log in completedLogs) {
      if (log.date.year == now.year && log.date.month == now.month) {
        final weekIndex = ((log.date.day - 1) / 7).floor().clamp(0, 4);
        weeks[weekIndex]++;
      }
    }

    return weeks;
  }

  void watchUserStats(String userId, List<HabitModel> habits) {
    final nextHabitKey = habits.map((habit) => habit.habitId).toList()..sort();
    final joinedHabitKey = nextHabitKey.join('|');

    if (_userId == userId && _habitKey == joinedHabitKey) {
      return;
    }

    _userId = userId;
    _habitKey = joinedHabitKey;
    _habits = habits;

    _logsSubscription?.cancel();
    _logsSubscription = repository.streamUserHabitLogs(habits).listen((logs) {
      _logs = logs;
      _syncUnlockedAchievements();
      notifyListeners();
    });

    _achievementsSubscription ??= repository.streamAchievements().listen((
      achievements,
    ) {
      _achievements = achievements;
      _syncUnlockedAchievements();
      notifyListeners();
    });

    _unlockedSubscription ??= repository
        .streamUnlockedAchievementIds(userId)
        .listen((ids) {
          _unlockedAchievementIds = ids;
          notifyListeners();
        });
  }

  bool isUnlocked(AchievementModel achievement) {
    return _unlockedAchievementIds.contains(achievement.achievementId) ||
        _meetsRequirement(achievement);
  }

  int progressFor(AchievementModel achievement) {
    return switch (achievement.metric) {
      'streak' => currentStreak,
      _ => completedCount,
    };
  }

  Future<void> _syncUnlockedAchievements() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    for (final achievement in _achievements) {
      if (!_unlockedAchievementIds.contains(achievement.achievementId) &&
          _meetsRequirement(achievement)) {
        await repository.unlockAchievement(
          userId: userId,
          achievement: achievement,
        );
      }
    }
  }

  bool _meetsRequirement(AchievementModel achievement) {
    return progressFor(achievement) >= achievement.target;
  }

  int _calculateCurrentStreak(List<HabitLogModel> logs) {
    final completedDays = _completedDays(logs);
    if (completedDays.isEmpty) {
      return 0;
    }

    var cursor = _startOfDay(DateTime.now());
    if (!completedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (completedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _calculateBestStreak(List<HabitLogModel> logs) {
    final days = _completedDays(logs).toList()..sort();
    if (days.isEmpty) {
      return 0;
    }

    var best = 1;
    var current = 1;

    for (var i = 1; i < days.length; i++) {
      final difference = days[i].difference(days[i - 1]).inDays;
      if (difference == 1) {
        current++;
      } else if (difference > 1) {
        current = 1;
      }

      if (current > best) {
        best = current;
      }
    }

    return best;
  }

  Set<DateTime> _completedDays(List<HabitLogModel> logs) {
    return logs.map((log) => _startOfDay(log.date)).toSet();
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    _achievementsSubscription?.cancel();
    _unlockedSubscription?.cancel();
    super.dispose();
  }
}
