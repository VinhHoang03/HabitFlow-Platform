import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/habit_model.dart';

class HabitListTiimoView extends StatefulWidget {
  final List<HabitModel> habits;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onAddHabit;
  final VoidCallback onOpenTemplates;
  final ValueChanged<HabitModel> onOpenHabit;
  final ValueChanged<HabitModel> onEditHabit;

  const HabitListTiimoView({
    super.key,
    required this.habits,
    required this.isLoading,
    required this.errorMessage,
    required this.onAddHabit,
    required this.onOpenTemplates,
    required this.onOpenHabit,
    required this.onEditHabit,
  });

  @override
  State<HabitListTiimoView> createState() => _HabitListTiimoViewState();
}

class _HabitListTiimoViewState extends State<HabitListTiimoView> {
  final TextEditingController _searchController = TextEditingController();
  late DateTime _selectedDate = _dateOnly(DateTime.now());
  String _statusFilter = _TiimoFilters.main;
  String _categoryFilter = _TiimoFilters.all;
  String _priorityFilter = _TiimoFilters.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.habits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null && widget.habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(widget.errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    final habits = _filteredHabits(widget.habits);
    final groups = _groupHabitsByDayPart(habits);
    final timelineItems = _timelineItems(groups);
    final categories = widget.habits
        .map((habit) => habit.category.trim().isEmpty ? 'Chung' : habit.category)
        .toSet()
        .toList()
      ..sort();

    return Container(
      color: const Color(0xFFFBF8F7),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(onAddHabit: widget.onAddHabit),
                    const SizedBox(height: 34),
                    _DateHeader(date: _selectedDate),
                    const SizedBox(height: 24),
                    _WeekStrip(
                      selectedDate: _selectedDate,
                      onSelected: (date) {
                        setState(() => _selectedDate = _dateOnly(date));
                      },
                    ),
                    const SizedBox(height: 26),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _TemplateButton(
                            onPressed: widget.onOpenTemplates,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _FilterButton(
                            label: _filterSummary(),
                            onPressed: () => _showFilterSheet(categories),
                          ),
                        ),
                      ],
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SoftPill(label: _labelForValue(_statusFilter)),
                          if (_categoryFilter != _TiimoFilters.all)
                            _SoftPill(label: _categoryFilter),
                          if (_priorityFilter != _TiimoFilters.all)
                            _SoftPill(label: _labelForValue(_priorityFilter)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            if (widget.habits.isNotEmpty && habits.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'Không có thói quen phù hợp bộ lọc.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = timelineItems[index];
                      if (item is _DayPartHeaderItem) {
                        return Padding(
                          padding: EdgeInsets.only(
                            top: item.isFirst ? 0 : 24,
                            bottom: 12,
                          ),
                          child: Column(
                            children: [
                              _DayPartHeader(group: item.group),
                              if (item.group.habits.isEmpty) ...[
                                const SizedBox(height: 12),
                                _EmptyDayPartSlot(
                                  groupTitle: item.group.title,
                                  onAddHabit: widget.onAddHabit,
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      final habit = (item as _HabitItem).habit;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HabitCard(
                          habit: habit,
                          onTap: () => widget.onOpenHabit(habit),
                          onEdit: () => widget.onEditHabit(habit),
                        ),
                      );
                    },
                    childCount: timelineItems.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  List<HabitModel> _filteredHabits(List<HabitModel> habits) {
    final query = _searchController.text.trim().toLowerCase();

    return habits.where((habit) {
      final category = habit.category.trim().isEmpty ? 'Chung' : habit.category;
      final matchesSearch =
          query.isEmpty || habit.name.toLowerCase().contains(query);
      final matchesStatus = switch (_statusFilter) {
        _TiimoFilters.all => true,
        _TiimoFilters.main => habit.status != HabitStatus.archived,
        _ => habit.status == _statusFilter,
      };
      final matchesCategory =
          _categoryFilter == _TiimoFilters.all || category == _categoryFilter;
      final matchesPriority = _priorityFilter == _TiimoFilters.all ||
          habit.priority == _priorityFilter;

      return matchesSearch &&
          matchesStatus &&
          matchesCategory &&
          matchesPriority;
    }).toList();
  }

  List<_TimelineItem> _timelineItems(List<_HabitGroup> groups) {
    final items = <_TimelineItem>[];
    for (final group in groups) {
      items.add(_DayPartHeaderItem(group: group, isFirst: items.isEmpty));
      items.addAll(group.habits.map(_HabitItem.new));
    }
    return items;
  }

  List<_HabitGroup> _groupHabitsByDayPart(List<HabitModel> habits) {
    final groups = [
      _HabitGroup('BẤT CỨ LÚC NÀO', Icons.schedule, const Color(0xFFF1F0EE)),
      _HabitGroup('BUỔI SÁNG', Icons.wb_twilight_outlined, const Color(0xFFFBEDE7)),
      _HabitGroup('BUỔI TRƯA', Icons.wb_sunny_outlined, const Color(0xFFFFF3C9)),
      _HabitGroup('NGÀY', Icons.light_mode_outlined, const Color(0xFFEDEBFF)),
      _HabitGroup('BUỔI TỐI', Icons.nights_stay_outlined, const Color(0xFFE7E8F7)),
    ];

    for (final habit in habits) {
      final hour = _readReminderHour(habit.reminderTime);
      if (hour == null) {
        groups[0].habits.add(habit);
      } else if (hour < 12) {
        groups[1].habits.add(habit);
      } else if (hour < 14) {
        groups[2].habits.add(habit);
      } else if (hour < 18) {
        groups[3].habits.add(habit);
      } else {
        groups[4].habits.add(habit);
      }
    }

    for (final group in groups) {
      group.habits.sort((a, b) {
        final aHour = _readReminderHour(a.reminderTime) ?? 99;
        final bHour = _readReminderHour(b.reminderTime) ?? 99;
        return aHour.compareTo(bHour);
      });
    }

    return groups;
  }

  int? _readReminderHour(String reminderTime) {
    final trimmed = reminderTime.trim();
    if (trimmed.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2})').firstMatch(trimmed);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    if (hour == null || hour < 0 || hour > 23) return null;
    return hour;
  }

  String _filterSummary() {
    var count = 0;
    if (_statusFilter != _TiimoFilters.main) count++;
    if (_categoryFilter != _TiimoFilters.all) count++;
    if (_priorityFilter != _TiimoFilters.all) count++;
    return count == 0 ? 'Bộ lọc' : 'Bộ lọc ($count)';
  }

  bool get _hasActiveFilters =>
      _statusFilter != _TiimoFilters.main ||
      _categoryFilter != _TiimoFilters.all ||
      _priorityFilter != _TiimoFilters.all;

  Future<void> _showFilterSheet(List<String> categories) async {
    var selectedStatus = _statusFilter;
    var selectedCategory = _categoryFilter;
    var selectedPriority = _priorityFilter;

    final result = await showModalBottomSheet<
        ({String status, String category, String priority})>(
      context: context,
      backgroundColor: const Color(0xFFFBF8F7),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bộ lọc',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FilterGroup(
                      title: 'Trạng thái',
                      values: _TiimoFilters.statusValues,
                      selectedValue: selectedStatus,
                      onSelected: (value) {
                        setSheetState(() => selectedStatus = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    _DropdownFilter(
                      label: 'Danh mục',
                      value: selectedCategory,
                      values: [_TiimoFilters.all, ...categories],
                      onChanged: (value) {
                        setSheetState(() => selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _DropdownFilter(
                      label: 'Độ ưu tiên',
                      value: selectedPriority,
                      values: const [_TiimoFilters.all, ...HabitPriority.values],
                      onChanged: (value) {
                        setSheetState(() => selectedPriority = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                                (
                                  status: _TiimoFilters.main,
                                  category: _TiimoFilters.all,
                                  priority: _TiimoFilters.all,
                                ),
                              );
                            },
                            child: const Text('Xóa lọc'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                                (
                                  status: selectedStatus,
                                  category: selectedCategory,
                                  priority: selectedPriority,
                                ),
                              );
                            },
                            child: const Text('Áp dụng'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _statusFilter = result.status;
      _categoryFilter = result.category;
      _priorityFilter = result.priority;
    });
  }
}

class _HabitGroup {
  final String title;
  final IconData icon;
  final Color color;
  final List<HabitModel> habits = [];

  _HabitGroup(this.title, this.icon, this.color);
}

sealed class _TimelineItem {}

class _DayPartHeaderItem extends _TimelineItem {
  final _HabitGroup group;
  final bool isFirst;

  _DayPartHeaderItem({required this.group, required this.isFirst});
}

class _HabitItem extends _TimelineItem {
  final HabitModel habit;

  _HabitItem(this.habit);
}

class _DayPartHeader extends StatelessWidget {
  final _HabitGroup group;

  const _DayPartHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: group.color,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(group.icon, size: 20),
              const SizedBox(width: 8),
              Text(
                '${group.title} (${group.habits.length})',
                style: const TextStyle(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: Color(0xFFD4D0CC)),
        ),
      ],
    );
  }
}

class _EmptyDayPartSlot extends StatelessWidget {
  final String groupTitle;
  final VoidCallback onAddHabit;

  const _EmptyDayPartSlot({
    required this.groupTitle,
    required this.onAddHabit,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (groupTitle) {
      'BẤT CỨ LÚC NÀO' => 'Bất cứ lúc nào hôm nay hoạt động',
      'BUỔI SÁNG' => 'Có gì trong danh sách buổi sáng của bạn?',
      'BUỔI TRƯA' => 'Bạn muốn thêm gì cho buổi trưa?',
      'NGÀY' => 'Điều gì đang xảy ra hôm nay?',
      'BUỔI TỐI' => 'Kết thúc một ngày theo cách của bạn',
      _ => 'Thêm vào danh sách của bạn',
    };

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onAddHabit,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: const Color(0xFFE5E1DE),
          radius: 20,
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFA49D99),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F0ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Color(0xFFBDB6B0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onAddHabit;

  const _TopBar({required this.onAddHabit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundPill(
          child: const Text(
            'Hôm nay',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
          ),
        ),
        const Spacer(),
        const _ProPill(),
        const Spacer(),
        _CircleButton(icon: Icons.add, onPressed: onAddHabit),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final weekday = _capitalize(DateFormat.EEEE('vi').format(date));
    final monthYear = DateFormat("'THG' M yyyy", 'vi').format(date);
    final fullDate = DateFormat("d 'tháng' M", 'vi').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          weekday,
          softWrap: false,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 48,
            height: 0.98,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171313),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              fullDate,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF6F6965),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              monthYear.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                letterSpacing: 1.1,
                color: Color(0xFF312D2D),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 24),
          ],
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  const _WeekStrip({
    required this.selectedDate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final start = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = start.add(Duration(days: index));
        final selected = DateUtils.isSameDay(day, selectedDate);
        final label = _weekdayShortLabel(day.weekday);

        return Expanded(
          child: Material(
            color: selected ? const Color(0xFFF1F0EE) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelected(day),
              child: SizedBox(
                height: 76,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: index == 0
                            ? const Color(0xFF8F6EF8)
                            : const Color(0xFF918B87),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 30,
                        height: 1,
                        color: index == 0
                            ? const Color(0xFF8F6EF8)
                            : selected
                                ? const Color(0xFF171313)
                                : const Color(0xFF918B87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ProPill extends StatelessWidget {
  const _ProPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE5DBFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pro',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFF171313),
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.auto_awesome, size: 18, color: Color(0xFF8F6EF8)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Tìm thói quen',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TemplateButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _TemplateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF171313),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_outlined, color: Colors.white),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Mẫu thói quen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _FilterButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.tune),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF171313),
        side: const BorderSide(color: Color(0xFF171313), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _HabitCard({required this.habit, required this.onTap, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final category = habit.category.isEmpty ? 'Chung' : habit.category;
    final reminder = habit.reminderTime.trim().isEmpty ? 'Bất kỳ lúc nào' : habit.reminderTime.trim();

    final icon = _iconForHabit(habit);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _colorForStatus(habit.status),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 26, color: const Color(0xFF171313)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, height: 1.1, fontWeight: FontWeight.w800, color: Color(0xFF171313)),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.check_box_outlined, size: 17, color: Color(0xFF585151)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '$category • $reminder • ${_labelForValue(habit.frequency)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, color: Color(0xFF585151), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SoftPill(label: _labelForValue(habit.priority)),
                        _SoftPill(label: _labelForValue(habit.difficulty)),
                        _SoftPill(label: _labelForValue(habit.status)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Sửa thói quen',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF171313), width: 3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddHabit;

  const _EmptyState({required this.onAddHabit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(color: Color(0xFFE7D8FF), shape: BoxShape.circle),
            child: const Icon(Icons.waving_hand_outlined, size: 52),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hôm nay bạn muốn xây dựng điều gì?',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'serif', fontSize: 30, height: 1.1, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tạo thói quen đầu tiên để bắt đầu theo dõi tiến độ mỗi ngày.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF585151)),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddHabit,
            icon: const Icon(Icons.add),
            label: const Text('Thêm thói quen'),
          ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _FilterGroup({required this.title, required this.values, required this.selectedValue, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(_labelForValue(value)),
                selected: selectedValue == value,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({required this.label, required this.value, required this.values, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: values.map((item) => DropdownMenuItem(value: item, child: Text(_labelForValue(item)))).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _RoundPill extends StatelessWidget {
  final Widget child;

  const _RoundPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

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
          width: 52,
          height: 52,
          child: Icon(icon, size: 30, color: const Color(0xFF171313)),
        ),
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionChip({
    required this.label,
    required this.icon,
    this.color = const Color(0xFFF6ECE7),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 8).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _SoftPill extends StatelessWidget {
  final String label;

  const _SoftPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF2EFF8), borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5D4E90)),
      ),
    );
  }
}

class _TiimoFilters {
  static const all = 'Tất cả';
  static const main = 'Đang theo dõi';
  static const statusValues = [
    main,
    all,
    HabitStatus.active,
    HabitStatus.paused,
    HabitStatus.archived,
  ];
}

Color _colorForStatus(String status) {
  if (status == HabitStatus.paused) return const Color(0xFFFFEEE1);
  if (status == HabitStatus.archived) return const Color(0xFFE9E7E4);
  return const Color(0xFFE5DBFF);
}

IconData _iconForHabit(HabitModel habit) {
  final text = '${habit.name} ${habit.category}'.toLowerCase();
  if (text.contains('nước') || text.contains('water')) return Icons.water_drop_outlined;
  if (text.contains('sách') || text.contains('book') || text.contains('đọc')) return Icons.menu_book_outlined;
  if (text.contains('tập') || text.contains('exercise') || text.contains('gym')) return Icons.directions_run;
  if (text.contains('ngủ') || text.contains('sleep')) return Icons.bedtime_outlined;
  if (text.contains('thiền') || text.contains('meditat')) return Icons.self_improvement;
  if (text.contains('học') || text.contains('study')) return Icons.school_outlined;
  return Icons.check_box_outlined;
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value.substring(0, 1).toUpperCase() + value.substring(1);
}

String _weekdayShortLabel(int weekday) {
  const labels = {
    DateTime.monday: 'T2',
    DateTime.tuesday: 'T3',
    DateTime.wednesday: 'T4',
    DateTime.thursday: 'T5',
    DateTime.friday: 'T6',
    DateTime.saturday: 'T7',
    DateTime.sunday: 'CN',
  };
  return labels[weekday] ?? '';
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
    _TiimoFilters.all: _TiimoFilters.all,
    _TiimoFilters.main: _TiimoFilters.main,
  };

  return labels[value] ?? value;
}
