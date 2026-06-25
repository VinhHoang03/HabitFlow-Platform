import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';

class HabitRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addHabit(HabitModel habit) async {
    await _db.collection('habits').add(habit.toMap());
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _db.collection('habits').doc(habit.habitId).update(habit.toMap());
  }

  Future<void> deleteHabit(String habitId) async {
    await _db.collection('habits').doc(habitId).delete();
  }

  Stream<List<HabitModel>> streamHabits(String userId) {
    return _db
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> completeHabit(String habitId, DateTime date, bool completed) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final snapshot = await _db
        .collection('habit_logs')
        .where('habitId', isEqualTo: habitId)
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    if (snapshot.docs.isNotEmpty) {
      await _db
          .collection('habit_logs')
          .doc(snapshot.docs.first.id)
          .update({'completed': completed});
    } else {
      final log = HabitLogModel(
        logId: '',
        habitId: habitId,
        date: startOfDay,
        completed: completed,
      );
      await _db.collection('habit_logs').add(log.toMap());
    }
  }

  Stream<List<HabitLogModel>> streamLogs(String habitId) {
    return _db
        .collection('habit_logs')
        .where('habitId', isEqualTo: habitId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
