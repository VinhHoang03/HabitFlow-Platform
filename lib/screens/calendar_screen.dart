import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/habit_completion_model.dart';
import '../models/habit_model.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Vui lòng đăng nhập để xem lịch.'));
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
            final completionsByDay = _groupCompletionsByDay(completions);
            final selectedDay = _selectedDay ?? DateTime.now();
            final selectedCompletions =
                completionsByDay[_dateOnly(selectedDay)] ?? [];
            final habitsById = {
              for (final habit in habitProvider.habits) habit.habitId: habit,
            };

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 110),
              children: [
                const Text(
                  'Lịch theo dõi',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 42,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171313),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Xem lại những ngày bạn đã hoàn thành thói quen.',
                  style: TextStyle(fontSize: 17, color: Color(0xFF4D4747)),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TableCalendar<HabitCompletionModel>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: (day) => completionsByDay[_dateOnly(day)] ?? [],
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFF9B7CF6),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF171313),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF9B7CF6).withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _SectionChip(
                  label: DateFormat.yMMMMd().format(selectedDay),
                  count: selectedCompletions.length,
                ),
                const SizedBox(height: 12),
                if (selectedCompletions.isEmpty)
                  const _EmptyDayCard()
                else
                  ...selectedCompletions.map((completion) {
                    final habit = habitsById[completion.habitId];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CompletionCard(
                        title: habit?.name ?? 'Thói quen đã hoàn thành',
                        subtitle: habit == null
                            ? completion.habitId
                            : _habitSubtitle(habit),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<DateTime, List<HabitCompletionModel>> _groupCompletionsByDay(
    List<HabitCompletionModel> completions,
  ) {
    final grouped = <DateTime, List<HabitCompletionModel>>{};
    for (final completion in completions) {
      final day = _dateOnly(completion.date);
      grouped.putIfAbsent(day, () => []).add(completion);
    }
    return grouped;
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _habitSubtitle(HabitModel habit) {
    final category = habit.category.isEmpty ? 'Chung' : habit.category;
    return '$category - ${_labelForValue(habit.frequency)} - ${_labelForValue(habit.priority)}';
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  final int count;

  const _SectionChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFF8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available_outlined, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label  •  $count hoàn thành',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CompletionCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFE5DBFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF6A6262)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Text(
        'Chưa có thói quen hoàn thành trong ngày này.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF6A6262)),
      ),
    );
  }
}

String _labelForValue(String value) {
  const labels = {
    HabitPriority.low: 'Thấp',
    HabitPriority.medium: 'Trung bình',
    HabitPriority.high: 'Cao',
    HabitFrequency.daily: 'Hằng ngày',
    HabitFrequency.weekly: 'Hằng tuần',
    HabitFrequency.custom: 'Tùy chỉnh',
  };
  return labels[value] ?? value;
}
