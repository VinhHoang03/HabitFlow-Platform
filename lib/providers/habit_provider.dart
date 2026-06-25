import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';

class HabitProvider with ChangeNotifier {
  final HabitRepository _repository = HabitRepository();
  List<HabitModel> _habits = [];

  List<HabitModel> get habits => _habits;

  void fetchHabits(String userId) {
    _repository.streamHabits(userId).listen((habits) {
      _habits = habits;
      notifyListeners();
    });
  }

  Future<void> addHabit(HabitModel habit) async {
    await _repository.addHabit(habit);
  }

  Future<void> completeHabit(String habitId, DateTime date, bool completed) async {
    await _repository.completeHabit(habitId, date, completed);
  }
}
