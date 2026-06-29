import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/habit_completion_model.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';

class HabitDetailScreen extends StatelessWidget {
  final HabitModel habit;
  final Future<void> Function(HabitModel habit)? onEditHabit;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    this.onEditHabit,
  });

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final currentHabit = _findCurrentHabit(habitProvider.habits);
    final visibleHabit = currentHabit ?? habit;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F7),
      body: SafeArea(
        child: StreamBuilder<List<HabitCompletionModel>>(
          stream: habitProvider.streamCompletions(
            userId: visibleHabit.userId,
            habitId: visibleHabit.habitId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final completions = snapshot.data ?? [];
            final completedItems = completions
                .where((completion) => completion.isCompleted)
                .toList();
            final isCompletedToday = completedItems.any(
              (completion) => DateUtils.isSameDay(
                completion.date,
                DateTime.now(),
              ),
            );
            final totalCompleted = completedItems.length;
            final currentStreak = _calculateCurrentStreak(completedItems);
            final completionRate = _calculateCompletionRate(
              startDate: visibleHabit.startDate,
              totalCompleted: totalCompleted,
            );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _CircleButton(
                              icon: Icons.arrow_back,
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            _CircleButton(
                              icon: Icons.edit_outlined,
                              onPressed: onEditHabit == null
                                  ? null
                                  : () => onEditHabit!(visibleHabit),
                            ),
                            const SizedBox(width: 10),
                            _CircleButton(
                              icon: Icons.delete_outline,
                              onPressed: () => _confirmDelete(
                                context,
                                habitProvider,
                                visibleHabit,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          visibleHabit.name,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 42,
                            height: 1.05,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171313),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          visibleHabit.description.isEmpty
                              ? 'Theo dõi tiến độ và xây dựng thói quen mỗi ngày.'
                              : visibleHabit.description,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.35,
                            color: Color(0xFF4D4747),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SoftPill(label: _labelForValue(visibleHabit.status)),
                            _SoftPill(label: _labelForValue(visibleHabit.frequency)),
                            _SoftPill(label: visibleHabit.category.isEmpty ? 'Chung' : visibleHabit.category),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Hoàn thành',
                                value: '$totalCompleted',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                label: 'Chuỗi ngày',
                                value: '$currentStreak',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                label: 'Tỷ lệ',
                                value: '$completionRate%',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _PrimaryAction(
                          enabled: visibleHabit.status == HabitStatus.active,
                          completed: isCompletedToday,
                          onPressed: () => _toggleToday(
                            context: context,
                            provider: habitProvider,
                            selectedHabit: visibleHabit,
                            completed: !isCompletedToday,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _StatusActions(
                          habit: visibleHabit,
                          onPause: () => _changeStatus(
                            context: context,
                            action: () => habitProvider.pauseHabit(visibleHabit.habitId),
                            successMessage: 'Đã tạm dừng thói quen.',
                          ),
                          onResume: () => _changeStatus(
                            context: context,
                            action: () => habitProvider.resumeHabit(visibleHabit.habitId),
                            successMessage: 'Đã tiếp tục thói quen.',
                          ),
                          onArchive: () => _confirmArchive(
                            context,
                            habitProvider,
                            visibleHabit,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _InfoSection(habit: visibleHabit),
                        const SizedBox(height: 20),
                        _HistorySection(completions: completions),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleToday({
    required BuildContext context,
    required HabitProvider provider,
    required HabitModel selectedHabit,
    required bool completed,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.markHabitCompleted(
      userId: selectedHabit.userId,
      habitId: selectedHabit.habitId,
      date: DateTime.now(),
      isCompleted: completed,
    );

    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? completed
                  ? 'Đã hoàn thành thói quen hôm nay.'
                  : 'Đã bỏ đánh dấu hôm nay.'
              : provider.errorMessage ?? 'Không thể cập nhật hoàn thành.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HabitProvider provider,
    HabitModel selectedHabit,
  ) async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Xóa thói quen?',
      message: 'Thói quen sẽ bị ẩn khỏi danh sách chính nhưng lịch sử vẫn được giữ lại.',
      actionText: 'Xóa',
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await provider.deleteHabit(selectedHabit.habitId);
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã xóa thói quen.'
              : provider.errorMessage ?? 'Không thể xóa thói quen.',
        ),
      ),
    );
    if (success) navigator.pop();
  }

  Future<void> _confirmArchive(
    BuildContext context,
    HabitProvider provider,
    HabitModel selectedHabit,
  ) async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Lưu trữ thói quen?',
      message: 'Thói quen sẽ rời khỏi danh sách đang theo dõi nhưng lịch sử vẫn được giữ lại.',
      actionText: 'Lưu trữ',
    );
    if (confirmed != true || !context.mounted) return;

    await _changeStatus(
      context: context,
      action: () => provider.archiveHabit(selectedHabit.habitId),
      successMessage: 'Đã lưu trữ thói quen.',
      popOnSuccess: true,
    );
  }

  Future<bool?> _confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    required String actionText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFBF8F7),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus({
    required BuildContext context,
    required Future<bool> Function() action,
    required String successMessage,
    bool popOnSuccess = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await action();
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? successMessage : 'Không thể cập nhật trạng thái.'),
      ),
    );
    if (success && popOnSuccess) navigator.pop();
  }

  int _calculateCurrentStreak(List<HabitCompletionModel> completions) {
    final completedDates = completions
        .map((completion) => _dateOnly(completion.date))
        .toSet();
    var day = _dateOnly(DateTime.now());
    var streak = 0;

    while (completedDates.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _calculateCompletionRate({
    required DateTime startDate,
    required int totalCompleted,
  }) {
    final firstDay = _dateOnly(startDate);
    final today = _dateOnly(DateTime.now());
    final trackedDays = today.difference(firstDay).inDays + 1;
    if (trackedDays <= 0) return 0;
    return ((totalCompleted / trackedDays) * 100).clamp(0, 100).round();
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  HabitModel? _findCurrentHabit(List<HabitModel> habits) {
    for (final item in habits) {
      if (item.habitId == habit.habitId) return item;
    }
    return null;
  }
}

class _PrimaryAction extends StatelessWidget {
  final bool enabled;
  final bool completed;
  final VoidCallback onPressed;

  const _PrimaryAction({
    required this.enabled,
    required this.completed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(completed ? Icons.undo_outlined : Icons.check_circle_outline),
        label: Text(
          enabled
              ? completed
                  ? 'Bỏ đánh dấu hôm nay'
                  : 'Hoàn thành hôm nay'
              : 'Tiếp tục thói quen để hoàn thành',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF171313),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onArchive;

  const _StatusActions({
    required this.habit,
    required this.onPause,
    required this.onResume,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    if (habit.status == HabitStatus.active) {
      actions.add(_PillButton(icon: Icons.pause_circle_outline, label: 'Tạm dừng', onPressed: onPause));
    } else if (habit.status == HabitStatus.paused || habit.status == HabitStatus.archived) {
      actions.add(_PillButton(icon: Icons.play_circle_outline, label: 'Tiếp tục', onPressed: onResume));
    }
    if (habit.status != HabitStatus.archived) {
      actions.add(_PillButton(icon: Icons.archive_outlined, label: 'Lưu trữ', onPressed: onArchive));
    }

    return Wrap(spacing: 8, runSpacing: 8, children: actions);
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PillButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF171313),
        side: const BorderSide(color: Color(0xFFD8D4D0), width: 2),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
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

class _InfoSection extends StatelessWidget {
  final HabitModel habit;

  const _InfoSection({required this.habit});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    return _Panel(
      title: 'Thông tin thói quen',
      child: Column(
        children: [
          _InfoRow(label: 'Danh mục', value: habit.category.isEmpty ? 'Chung' : habit.category),
          _InfoRow(label: 'Tần suất', value: _labelForValue(habit.frequency)),
          _InfoRow(label: 'Giờ nhắc', value: habit.reminderTime.isEmpty ? 'Bất kỳ lúc nào' : habit.reminderTime),
          _InfoRow(label: 'Ưu tiên', value: _labelForValue(habit.priority)),
          _InfoRow(label: 'Độ khó', value: _labelForValue(habit.difficulty)),
          _InfoRow(label: 'Trạng thái', value: _labelForValue(habit.status)),
          _InfoRow(label: 'Bắt đầu', value: dateFormat.format(habit.startDate)),
          _InfoRow(label: 'Cập nhật', value: dateFormat.format(habit.updatedAt)),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<HabitCompletionModel> completions;

  const _HistorySection({required this.completions});

  @override
  Widget build(BuildContext context) {
    final completedItems = completions.where((completion) => completion.isCompleted).toList();
    return _Panel(
      title: 'Lịch sử hoàn thành',
      child: completedItems.isEmpty
          ? const Text('Chưa có ngày hoàn thành.', style: TextStyle(color: Color(0xFF6A6262)))
          : Column(
              children: completedItems.take(30).map((completion) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(DateFormat.yMMMd().format(completion.date)),
                  subtitle: completion.note.isEmpty ? null : Text(completion.note),
                );
              }).toList(),
            ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Color(0xFF6A6262))),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String label;

  const _SoftPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFF8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF5D4E90),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CircleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(icon, color: const Color(0xFF171313)),
        ),
      ),
    );
  }
}

String _labelForValue(String value) {
  const labels = {
    HabitStatus.active: 'Đang hoạt động',
    HabitStatus.paused: 'Tạm dừng',
    HabitStatus.archived: 'Lưu trữ',
    HabitStatus.deleted: 'Đã xóa',
    HabitPriority.low: 'Thấp',
    HabitPriority.medium: 'Trung bình',
    HabitPriority.high: 'Cao',
    HabitDifficulty.easy: 'Dễ',
    HabitDifficulty.hard: 'Khó',
    HabitFrequency.daily: 'Hằng ngày',
    HabitFrequency.weekly: 'Hằng tuần',
    HabitFrequency.custom: 'Tùy chỉnh',
  };
  return labels[value] ?? value;
}
