import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/achievement_model.dart';
import '../models/habit_log_model.dart';
import '../models/habit_model.dart';

class StatisticsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<HabitLogModel>> streamUserHabitLogs(List<HabitModel> habits) {
    final habitIds = habits
        .map((habit) => habit.habitId)
        .where((id) => id.isNotEmpty)
        .toSet();

    if (habitIds.isEmpty) {
      return Stream.value([]);
    }

    return _db.collection('habit_logs').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HabitLogModel.fromMap(doc.data(), doc.id))
          .where((log) => habitIds.contains(log.habitId))
          .toList();
    });
  }

  Stream<List<AchievementModel>> streamAchievements() {
    return _db.collection('achievements').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return AchievementModel.defaultAchievements;
      }

      return snapshot.docs
          .map((doc) => AchievementModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> unlockAchievement({
    required String userId,
    required AchievementModel achievement,
  }) async {
    final documentId = '${userId}_${achievement.achievementId}';

    await _db.collection('user_achievements').doc(documentId).set({
      'userId': userId,
      'achievementId': achievement.achievementId,
      'title': achievement.title,
      'badge': achievement.badge,
      'description': achievement.description,
      'unlockedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Set<String>> streamUnlockedAchievementIds(String userId) {
    return _db
        .collection('user_achievements')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['achievementId'] as String?)
              .whereType<String>()
              .toSet(),
        );
  }
}
