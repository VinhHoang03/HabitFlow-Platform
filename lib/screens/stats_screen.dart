import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_completion_model.dart';
import '../models/habit_model.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Vui lòng đăng nhập để xem thống kê.'));
    }

    return Container(
      color: const Color(0xFFFBF8F7),
      child: SafeArea(
        child: StreamBuilder<List<HabitCompletionModel>>(
          stream: habitProvider.streamUserCompletions(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final completions = (snapshot.data ?? [])
                .where((completion) => completion.isCompleted)
                .toList();
            final activeHabits = habitProvider.habits
                .where((habit) => habit.status == HabitStatus.active)
                .toList();
            final weekCounts = _weeklyCounts(completions);
            final totalCompleted = completions.length;
            final completedToday = completions
                .where((completion) => _isSameDay(completion.date, DateTime.now()))
                .length;
            final currentStreak = _currentUserStreak(completions);
            final completionRate = _completionRate(
              activeHabits: activeHabits,
              completions: completions,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 110),
              children: [
                const Text(
                  'Thống kê',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 44,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171313),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Theo dõi nhịp xây dựng thói quen của bạn.',
                  style: TextStyle(fontSize: 17, color: Color(0xFF4D4747)),
                ),
                const SizedBox(height: 22),
                _StreakHero(streak: currentStreak),
                const SizedBox(height: 18),
                _MetricSplitCard(
                  streak: currentStreak,
                  completedToday: completedToday,
                  activeHabits: activeHabits.length,
                ),
                const SizedBox(height: 18),
                _RatePanel(rate: completionRate),
                const SizedBox(height: 18),
                _StatStrip(
                  totalCompleted: totalCompleted,
                  activeHabits: activeHabits.length,
                ),
                const SizedBox(height: 18),
                _ChartPanel(counts: weekCounts),
              ],
            );
          },
        ),
      ),
    );
  }

  List<int> _weeklyCounts(List<HabitCompletionModel> completions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final counts = List<int>.filled(7, 0);

    for (final completion in completions) {
      final date = DateTime(
        completion.date.year,
        completion.date.month,
        completion.date.day,
      );
      final index = date.difference(monday).inDays;
      if (index >= 0 && index < counts.length) counts[index]++;
    }
    return counts;
  }

  int _currentUserStreak(List<HabitCompletionModel> completions) {
    final completedDates = completions
        .map((completion) => DateTime(
              completion.date.year,
              completion.date.month,
              completion.date.day,
            ))
        .toSet();
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    var streak = 0;

    while (completedDates.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _completionRate({
    required List<HabitModel> activeHabits,
    required List<HabitCompletionModel> completions,
  }) {
    if (activeHabits.isEmpty) return 0;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    var expected = 0;

    for (final habit in activeHabits) {
      final startDate = DateTime(
        habit.startDate.year,
        habit.startDate.month,
        habit.startDate.day,
      );
      expected += todayOnly.difference(startDate).inDays + 1;
    }
    if (expected <= 0) return 0;

    final activeHabitIds = activeHabits.map((habit) => habit.habitId).toSet();
    final completedCount = completions
        .where((completion) => activeHabitIds.contains(completion.habitId))
        .length;
    return ((completedCount / expected) * 100).clamp(0, 100).round();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFE5DBFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF6A6262), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  final int streak;

  const _StreakHero({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFF),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 118,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 118,
                  height: 118,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3DAFF),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBDD),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(Icons.local_fire_department, size: 52),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$streak',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 58,
              height: 0.95,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171313),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ngày chuỗi hiện tại',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Giao diện chuỗi mẫu, sẵn sàng gắn API streak ở bước sau.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6A6262)),
          ),
        ],
      ),
    );
  }
}

class _MetricSplitCard extends StatelessWidget {
  final int streak;
  final int completedToday;
  final int activeHabits;

  const _MetricSplitCard({
    required this.streak,
    required this.completedToday,
    required this.activeHabits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _SplitMetric(
                icon: Icons.local_fire_department,
                accent: const Color(0xFF8D6BF2),
                value: '$streak',
                label: 'CHUỖI NGÀY',
                footer: '$streak/7 ngày',
              ),
            ),
            Container(width: 1, color: const Color(0xFFEDEAE6)),
            Expanded(
              child: _SplitMetric(
                icon: Icons.check_circle,
                accent: const Color(0xFF4C9A9A),
                value: '$completedToday',
                label: 'ĐÃ HOÀN THÀNH',
                footer: '$completedToday/$activeHabits nhiệm vụ',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitMetric extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String value;
  final String label;
  final String footer;

  const _SplitMetric({
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 22),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 38),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 48,
              height: 0.98,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171313),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              letterSpacing: 1.2,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: value == '0' ? 0 : 0.34,
              backgroundColor: const Color(0xFFEDEBE8),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF6A6262)),
          ),
        ],
      ),
    );
  }
}

class _StatStrip extends StatelessWidget {
  final int totalCompleted;
  final int activeHabits;

  const _StatStrip({required this.totalCompleted, required this.activeHabits});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactMetric(
            label: 'Tổng hoàn thành',
            value: '$totalCompleted',
            color: const Color(0xFFE8F1FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CompactMetric(
            label: 'Đang hoạt động',
            value: '$activeHabits',
            color: const Color(0xFFFFF0DC),
          ),
        ),
      ],
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RatePanel extends StatelessWidget {
  final int rate;

  const _RatePanel({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tỷ lệ hoàn thành',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$rate%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: rate / 100,
              backgroundColor: const Color(0xFFE8E2FA),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF9B7CF6)),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dựa trên các thói quen đang hoạt động từ ngày bắt đầu.',
            style: TextStyle(color: Color(0xFF6A6262)),
          ),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  final List<int> counts;

  const _ChartPanel({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến độ tuần này',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.65,
            child: BarChart(
              BarChartData(
                maxY: _chartMaxY(counts),
                barGroups: [
                  for (var index = 0; index < counts.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: counts[index].toDouble(),
                          color: const Color(0xFF9B7CF6),
                          width: 20,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                ],
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            labels[index],
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _chartMaxY(List<int> counts) {
    final highest = counts.fold<int>(0, (max, value) => value > max ? value : max);
    return highest <= 0 ? 1 : highest + 1;
  }
}
