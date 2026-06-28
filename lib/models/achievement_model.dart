class AchievementModel {
  final String achievementId;
  final String title;
  final String badge;
  final String description;
  final String metric;
  final int target;

  AchievementModel({
    required this.achievementId,
    required this.title,
    required this.badge,
    required this.description,
    required this.metric,
    required this.target,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> data, String id) {
    return AchievementModel(
      achievementId: id,
      title: data['title'] ?? '',
      badge: data['badge'] ?? '',
      description: data['description'] ?? '',
      metric: data['metric'] ?? 'completedLogs',
      target: data['target'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'badge': badge,
      'description': description,
      'metric': metric,
      'target': target,
    };
  }

  static List<AchievementModel> get defaultAchievements => [
    AchievementModel(
      achievementId: 'first_checkin',
      title: 'First Win',
      badge: 'star',
      description: 'Complete your first habit check-in.',
      metric: 'completedLogs',
      target: 1,
    ),
    AchievementModel(
      achievementId: 'three_day_streak',
      title: '3-Day Streak',
      badge: 'local_fire_department',
      description: 'Maintain a streak for 3 days.',
      metric: 'streak',
      target: 3,
    ),
    AchievementModel(
      achievementId: 'seven_day_streak',
      title: '7-Day Streak',
      badge: 'emoji_events',
      description: 'Maintain a streak for 7 days.',
      metric: 'streak',
      target: 7,
    ),
    AchievementModel(
      achievementId: 'ten_checkins',
      title: '10 Check-ins',
      badge: 'workspace_premium',
      description: 'Complete 10 habit check-ins.',
      metric: 'completedLogs',
      target: 10,
    ),
  ];
}
