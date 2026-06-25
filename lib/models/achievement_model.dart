class AchievementModel {
  final String achievementId;
  final String title;
  final String badge;
  final String description;

  AchievementModel({
    required this.achievementId,
    required this.title,
    required this.badge,
    required this.description,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> data, String id) {
    return AchievementModel(
      achievementId: id,
      title: data['title'] ?? '',
      badge: data['badge'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'badge': badge,
      'description': description,
    };
  }
}
