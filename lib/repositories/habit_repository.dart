import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/habit_completion_model.dart';
import '../models/habit_model.dart';
import '../models/habit_template_model.dart';

class HabitRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _habits =>
      _db.collection('habits');

  CollectionReference<Map<String, dynamic>> get _completions =>
      _db.collection('habit_completions');

  CollectionReference<Map<String, dynamic>> get _templates =>
      _db.collection('habit_templates');

  Future<String> createHabit(HabitModel habit) async {
    final doc = await _habits.add(habit.toMap());
    return doc.id;
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _habits.doc(habit.habitId).update(
          habit
              .copyWith(updatedAt: DateTime.now())
              .toUpdateMap(),
        );
  }

  Future<void> softDeleteHabit(String habitId) async {
    await _habits.doc(habitId).update({
      'status': HabitStatus.deleted,
      'isDeleted': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> pauseHabit(String habitId) {
    return _updateHabitStatus(habitId, HabitStatus.paused);
  }

  Future<void> resumeHabit(String habitId) {
    return _updateHabitStatus(habitId, HabitStatus.active);
  }

  Future<void> archiveHabit(String habitId) {
    return _updateHabitStatus(habitId, HabitStatus.archived);
  }

  Future<HabitModel?> getHabitById(String habitId) async {
    final doc = await _habits.doc(habitId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return HabitModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<HabitModel>> streamHabits(String userId) {
    return _habits
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final habits = snapshot.docs
          .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
          .where(
            (habit) =>
                !habit.isDeleted &&
                habit.status != HabitStatus.deleted,
          )
          .toList();

      habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return habits;
    });
  }

  Future<void> markHabitCompleted({
    required String userId,
    required String habitId,
    required DateTime date,
    required bool isCompleted,
    String note = '',
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final snapshot = await _completions
        .where('userId', isEqualTo: userId)
        .where('habitId', isEqualTo: habitId)
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    if (snapshot.docs.isNotEmpty) {
      await _completions.doc(snapshot.docs.first.id).update({
        'isCompleted': isCompleted,
        'note': note,
      });
    } else {
      final completion = HabitCompletionModel.create(
        userId: userId,
        habitId: habitId,
        date: startOfDay,
        isCompleted: isCompleted,
        note: note,
      );
      await _completions.add(completion.toMap());
    }
  }

  Stream<List<HabitCompletionModel>> streamCompletions({
    required String userId,
    required String habitId,
  }) {
    return _completions
        .where('userId', isEqualTo: userId)
        .where('habitId', isEqualTo: habitId)
        .snapshots()
        .map((snapshot) {
      final completions = snapshot.docs
          .map((doc) => HabitCompletionModel.fromMap(doc.data(), doc.id))
          .toList();
      completions.sort((a, b) => b.date.compareTo(a.date));
      return completions;
    });
  }

  Stream<List<HabitCompletionModel>> streamUserCompletions(String userId) {
    return _completions
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final completions = snapshot.docs
          .map((doc) => HabitCompletionModel.fromMap(doc.data(), doc.id))
          .toList();
      completions.sort((a, b) => b.date.compareTo(a.date));
      return completions;
    });
  }

  Future<List<HabitTemplateModel>> getHabitTemplates() async {
    final snapshot = await _templates.where('isActive', isEqualTo: true).get();
    final templates = snapshot.docs
        .map((doc) => HabitTemplateModel.fromMap(doc.data(), doc.id))
        .where((template) => template.name.trim().isNotEmpty)
        .toList();

    templates.sort((a, b) => a.name.compareTo(b.name));
    return templates;
  }

  Future<void> _updateHabitStatus(String habitId, String status) {
    return _habits.doc(habitId).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
