import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../models/habit_completion_model.dart';
import '../models/habit_model.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';

enum ReportFilter {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  last6Months('Last 6 Months'),
  thisYear('This Year'),
  lastYear('Last Year'),
  allTime('All Time'),
  customRange('Custom Range');

  final String label;
  const ReportFilter(this.label);
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFCF8FC),
        body: Center(child: Text('Vui lòng đăng nhập để xem thống kê.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF36345A)),
          onPressed: () {},
        ),
        title: const Text(
          'Report',
          style: TextStyle(
            color: Color(0xFF36345A),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF36345A)),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<HabitCompletionModel>>(
        stream: habitProvider.streamUserCompletions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final completions = snapshot.data ?? [];
          final completedOnly = completions
              .where((c) => c.isCompleted)
              .toList();
          final activeHabits = habitProvider.habits
              .where((habit) => habit.status == HabitStatus.active)
              .toList();

          final currentStreak = _currentUserStreak(completedOnly);
          final totalCompleted = completedOnly.length;
          final perfectDays = _totalPerfectDays(activeHabits, completions);
          final completionRate = _completionRate(
            activeHabits: activeHabits,
            completions: completedOnly,
          );

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _QuickStatsGrid(
                currentStreak: currentStreak,
                completionRate: completionRate,
                totalCompleted: totalCompleted,
                perfectDays: perfectDays,
              ),
              const SizedBox(height: 24),
              _HabitsCompletedSection(completions: completedOnly),
              const SizedBox(height: 24),
              _CompletionRateAreaSection(
                completions: completedOnly,
                activeHabits: activeHabits,
              ),
              const SizedBox(height: 24),
              _CalendarStatsSection(completions: completedOnly),
              const SizedBox(height: 24),
              _MoodChartSection(),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          );
        },
      ),
    );
  }

  int _currentUserStreak(List<HabitCompletionModel> completedOnly) {
    if (completedOnly.isEmpty) return 0;
    final completedDates = completedOnly
        .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
        .toSet();
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    var streak = 0;

    if (!completedDates.contains(day)) {
      day = day.subtract(const Duration(days: 1));
    }

    while (completedDates.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _totalPerfectDays(
    List<HabitModel> activeHabits,
    List<HabitCompletionModel> completions,
  ) {
    if (activeHabits.isEmpty) return 0;

    final completedByDate = <DateTime, Set<String>>{};
    for (final comp in completions) {
      if (!comp.isCompleted) continue;
      final d = DateTime(comp.date.year, comp.date.month, comp.date.day);
      completedByDate.putIfAbsent(d, () => {}).add(comp.habitId);
    }

    int perfectDays = 0;
    final startDate = activeHabits
        .map((h) => h.startDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    while (!current.isAfter(todayOnly)) {
      final habitsOnDay = activeHabits
          .where((h) => !h.startDate.isAfter(current))
          .toList();
      if (habitsOnDay.isNotEmpty) {
        final completedOnDay = completedByDate[current] ?? {};
        bool allDone = true;
        for (final h in habitsOnDay) {
          if (!completedOnDay.contains(h.habitId)) {
            allDone = false;
            break;
          }
        }
        if (allDone) perfectDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    return perfectDays;
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
      if (startDate.isAfter(todayOnly)) continue;
      expected += todayOnly.difference(startDate).inDays + 1;
    }
    if (expected <= 0) return 0;

    final activeHabitIds = activeHabits.map((habit) => habit.habitId).toSet();
    final completedCount = completions
        .where((completion) => activeHabitIds.contains(completion.habitId))
        .length;
    return ((completedCount / expected) * 100).clamp(0, 100).round();
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _SoftCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4D4B72).withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  final int currentStreak;
  final int completionRate;
  final int totalCompleted;
  final int perfectDays;

  const _QuickStatsGrid({
    required this.currentStreak,
    required this.completionRate,
    required this.totalCompleted,
    required this.perfectDays,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _StatItem(value: '$currentStreak days', label: 'Current streak'),
        _StatItem(value: '$completionRate%', label: 'Completion rate'),
        _StatItem(
          value: NumberFormat('#,###').format(totalCompleted),
          label: 'Habits completed',
        ),
        _StatItem(value: '$perfectDays', label: 'Total perfect days'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF36345A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF47464E),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ReportFilter selectedFilter;
  final ValueChanged<ReportFilter> onFilterChanged;

  const _SectionHeader({
    required this.title,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF36345A),
          ),
        ),
        PopupMenuButton<ReportFilter>(
          onSelected: (filter) async {
            if (filter == ReportFilter.customRange) {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF4D4B72),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Color(0xFF36345A),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (range != null) {
                onFilterChanged(filter);
              }
            } else {
              onFilterChanged(filter);
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder: (context) => ReportFilter.values.map((filter) {
            return PopupMenuItem(
              value: filter,
              child: Text(filter.label, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F2F6),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFC8C5CF).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Text(
                  selectedFilter.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF36345A),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more,
                  size: 16,
                  color: Color(0xFF36345A),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitsCompletedSection extends StatefulWidget {
  final List<HabitCompletionModel> completions;

  const _HabitsCompletedSection({required this.completions});

  @override
  State<_HabitsCompletedSection> createState() =>
      _HabitsCompletedSectionState();
}

class _HabitsCompletedSectionState extends State<_HabitsCompletedSection> {
  ReportFilter _currentFilter = ReportFilter.thisMonth;

  @override
  Widget build(BuildContext context) {
    final weekData = _getWeekData();
    final maxCount = weekData.values.fold(
      0,
      (max, val) => val > max ? val : max,
    );

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Habits Completed',
            selectedFilter: _currentFilter,
            onFilterChanged: (filter) =>
                setState(() => _currentFilter = filter),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.entries.map((entry) {
                final day = entry.key;
                final count = entry.value;
                final heightFactor = maxCount == 0 ? 0.0 : count / maxCount;
                final isToday = day == DateTime.now().day;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isToday && count > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF36345A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Container(
                        height: (120 * heightFactor).clamp(4, 120),
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF4D4B72)
                              : const Color(0xFFD3DDF6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$day',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF47464E),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, int> _getWeekData() {
    final now = DateTime.now();
    final weekDays = <int, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      weekDays[date.day] = 0;
    }

    for (final comp in widget.completions) {
      if (weekDays.containsKey(comp.date.day)) {
        weekDays[comp.date.day] = (weekDays[comp.date.day] ?? 0) + 1;
      }
    }
    return weekDays;
  }
}

class _CompletionRateAreaSection extends StatefulWidget {
  final List<HabitCompletionModel> completions;
  final List<HabitModel> activeHabits;

  const _CompletionRateAreaSection({
    required this.completions,
    required this.activeHabits,
  });

  @override
  State<_CompletionRateAreaSection> createState() =>
      _CompletionRateAreaSectionState();
}

class _CompletionRateAreaSectionState
    extends State<_CompletionRateAreaSection> {
  ReportFilter _currentFilter = ReportFilter.last6Months;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Habit Completion Rate',
            selectedFilter: _currentFilter,
            onFilterChanged: (filter) =>
                setState(() => _currentFilter = filter),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 2,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ];
                        if (value.toInt() < 0 || value.toInt() >= months.length)
                          return const SizedBox();
                        return Text(
                          months[value.toInt()],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF47464E),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 40),
                      FlSpot(1, 55),
                      FlSpot(2, 30),
                      FlSpot(3, 60),
                      FlSpot(4, 35),
                      FlSpot(5, 65),
                    ],
                    isCurved: true,
                    color: const Color(0xFF4D4B72),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4D4B72).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarStatsSection extends StatefulWidget {
  final List<HabitCompletionModel> completions;

  const _CalendarStatsSection({required this.completions});

  @override
  State<_CalendarStatsSection> createState() => _CalendarStatsSectionState();
}

class _CalendarStatsSectionState extends State<_CalendarStatsSection> {
  ReportFilter _currentFilter = ReportFilter.thisMonth;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Calendar Stats',
            selectedFilter: _currentFilter,
            onFilterChanged: (filter) =>
                setState(() => _currentFilter = filter),
          ),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Color(0xFF36345A),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Color(0xFF36345A),
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Color(0xFF36345A),
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Color(0xFF78767F),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              weekendStyle: TextStyle(
                color: Color(0xFF78767F),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: const CalendarStyle(
              defaultTextStyle: TextStyle(color: Color(0xFF47464E)),
              todayDecoration: BoxDecoration(
                color: Color(0xFFE7DBF1),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: Color(0xFF36345A),
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF4D4B72),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Color(0xFF4D4B72),
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final hasCompletion = widget.completions.any(
                  (c) => isSameDay(c.date, date),
                );
                if (hasCompletion) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF4D4B72),
                        width: 1,
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChartSection extends StatefulWidget {
  const _MoodChartSection();

  @override
  State<_MoodChartSection> createState() => _MoodChartSectionState();
}

class _MoodChartSectionState extends State<_MoodChartSection> {
  ReportFilter _currentFilter = ReportFilter.thisMonth;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Mood Chart',
            selectedFilter: _currentFilter,
            onFilterChanged: (filter) =>
                setState(() => _currentFilter = filter),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('😎', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 12),
                  Text('😊', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 12),
                  Text('😐', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 12),
                  Text('😔', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 12),
                  Text('😡', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = [
                                '16',
                                '17',
                                '18',
                                '19',
                                '20',
                                '21',
                                '22',
                              ];
                              if (value.toInt() < 0 ||
                                  value.toInt() >= days.length)
                                return const SizedBox();
                              return Text(
                                days[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF47464E),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 4),
                            FlSpot(1, 3),
                            FlSpot(2, 5),
                            FlSpot(3, 5),
                            FlSpot(4, 3),
                            FlSpot(5, 2),
                            FlSpot(6, 5),
                          ],
                          isCurved: true,
                          color: const Color(0xFF4D4B72),
                          barWidth: 2,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFD3DDF6).withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
