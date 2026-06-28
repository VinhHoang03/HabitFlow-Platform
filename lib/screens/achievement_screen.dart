import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/achievement_model.dart';
import '../providers/statistics_provider.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<StatisticsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: statsProvider.achievements.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final achievement = statsProvider.achievements[index];
          final progress = statsProvider.progressFor(achievement);
          final unlocked = statsProvider.isUnlocked(achievement);

          return _AchievementTile(
            achievement: achievement,
            progress: progress,
            unlocked: unlocked,
          );
        },
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementModel achievement;
  final int progress;
  final bool unlocked;

  const _AchievementTile({
    required this.achievement,
    required this.progress,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressValue = (progress / achievement.target)
        .clamp(0, 1)
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: unlocked
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              child: Icon(
                _iconFor(achievement.badge),
                color: unlocked
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(achievement.description),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progressValue),
                  const SizedBox(height: 6),
                  Text(
                    unlocked ? 'Unlocked' : '$progress / ${achievement.target}',
                    style: TextStyle(
                      color: unlocked
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String badge) {
    return switch (badge) {
      'local_fire_department' => Icons.local_fire_department,
      'emoji_events' => Icons.emoji_events,
      'workspace_premium' => Icons.workspace_premium,
      _ => Icons.star,
    };
  }
}
