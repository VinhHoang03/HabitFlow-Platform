import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../models/habit_template_model.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../utils/form_validators.dart';
import 'calendar_screen.dart';
import 'habit_detail_screen.dart';
import 'habit_list_tiimo_view.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = _HabitListFilters.main;
  String _categoryFilter = _HabitListFilters.all;
  String _priorityFilter = _HabitListFilters.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final habitProvider = Provider.of<HabitProvider>(
          context,
          listen: false,
        );
        habitProvider.fetchHabits(authProvider.user!.uid);
        habitProvider.fetchHabitTemplates();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);

    final List<Widget> pages = [
      _buildHabitList(habitProvider),
      const StatsScreen(),
      const CalendarScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F7),
      body: Stack(
        children: [
          Positioned.fill(child: pages[_selectedIndex]),
          Positioned(
            left: 24,
            right: 24,
            bottom: 22,
            child: _TiimoBottomNav(
              selectedIndex: _selectedIndex,
              onSelected: _onItemTapped,
              onAccountPressed: () => _showAccountMenu(authProvider),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAccountMenu(AuthProvider authProvider) async {
    final action = await showModalBottomSheet<_AccountAction>(
      context: context,
      backgroundColor: const Color(0xFFFBF8F7),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.user?.email ?? 'Tài khoản',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _AccountActionTile(
                  icon: Icons.person_outline,
                  label: 'Hồ sơ',
                  onTap: () => Navigator.pop(sheetContext, _AccountAction.profile),
                ),
                _AccountActionTile(
                  icon: Icons.password_outlined,
                  label: 'Đổi mật khẩu',
                  onTap: () => Navigator.pop(sheetContext, _AccountAction.changePassword),
                ),
                _AccountActionTile(
                  icon: Icons.logout,
                  label: 'Đăng xuất',
                  onTap: () => Navigator.pop(sheetContext, _AccountAction.logout),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _AccountAction.profile:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
      case _AccountAction.changePassword:
        _showChangePasswordDialog(context);
        break;
      case _AccountAction.logout:
        authProvider.logout();
        break;
    }
  }

  Widget _buildHabitList(HabitProvider habitProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      return HabitListTiimoView(
        habits: habitProvider.habits,
        isLoading: habitProvider.isLoading,
        errorMessage: habitProvider.errorMessage,
        onAddHabit: () => _showHabitFormDialog(userId: userId),
        onOpenTemplates: () => _showTemplateSheet(userId),
        onEditHabit: (habit) => _showHabitFormDialog(
          userId: habit.userId,
          habit: habit,
        ),
        onOpenHabit: (habit) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => HabitDetailScreen(
                habit: habit,
                onEditHabit: (habit) => _showHabitFormDialog(
                  userId: habit.userId,
                  habit: habit,
                ),
              ),
            ),
          );
        },
      );
    }

    if (habitProvider.isLoading && habitProvider.habits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (habitProvider.errorMessage != null && habitProvider.habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            habitProvider.errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final filteredHabits = _filteredHabits(habitProvider.habits);
    final categories = habitProvider.habits
        .map(
          (habit) =>
              habit.category.trim().isEmpty ? 'Chung' : habit.category,
        )
        .toSet()
        .toList()
      ..sort();

    if (habitProvider.habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.task_alt,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có thói quen nào',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Tạo thói quen đầu tiên để bắt đầu theo dõi tiến độ mỗi ngày.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Tìm thói quen',
                  prefixIcon: Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 62,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _TemplateEntryButton(
                        onPressed: () {
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final userId = authProvider.user?.uid;
                          if (userId != null) {
                            _showTemplateSheet(userId);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _showFilterSheet(categories),
                        icon: const Icon(Icons.tune),
                        label: Text(_filterSummary()),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _FilterTag(label: _labelForFilter(_statusFilter)),
                      if (_categoryFilter != _HabitListFilters.all)
                        _FilterTag(label: _categoryFilter),
                      if (_priorityFilter != _HabitListFilters.all)
                        _FilterTag(label: _labelForFilter(_priorityFilter)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: filteredHabits.isEmpty
              ? const Center(
                  child: Text('Không có thói quen phù hợp bộ lọc.'),
                )
              : _HabitListView(
                  habits: filteredHabits,
                  onEditHabit: (habit) => _showHabitFormDialog(
                    userId: habit.userId,
                    habit: habit,
                  ),
                  onOpenHabit: (habit) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HabitDetailScreen(
                          habit: habit,
                          onEditHabit: (habit) => _showHabitFormDialog(
                            userId: habit.userId,
                            habit: habit,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<HabitModel> _filteredHabits(List<HabitModel> habits) {
    final query = _searchController.text.trim().toLowerCase();

    return habits.where((habit) {
      final category = habit.category.trim().isEmpty ? 'Chung' : habit.category;
      final matchesSearch =
          query.isEmpty || habit.name.toLowerCase().contains(query);
      final matchesStatus = switch (_statusFilter) {
        _HabitListFilters.all => true,
        _HabitListFilters.main => habit.status != HabitStatus.archived,
        _ => habit.status == _statusFilter,
      };
      final matchesCategory = _categoryFilter == _HabitListFilters.all ||
          category == _categoryFilter;
      final matchesPriority = _priorityFilter == _HabitListFilters.all ||
          habit.priority == _priorityFilter;

      return matchesSearch &&
          matchesStatus &&
          matchesCategory &&
          matchesPriority;
    }).toList();
  }

  String _filterSummary() {
    final filters = <String>[];
    if (_statusFilter != _HabitListFilters.main) {
      filters.add(_labelForFilter(_statusFilter));
    }
    if (_categoryFilter != _HabitListFilters.all) {
      filters.add(_categoryFilter);
    }
    if (_priorityFilter != _HabitListFilters.all) {
      filters.add(_labelForFilter(_priorityFilter));
    }
    return filters.isEmpty ? 'Bộ lọc' : 'Bộ lọc (${filters.length})';
  }

  bool get _hasActiveFilters =>
      _statusFilter != _HabitListFilters.main ||
      _categoryFilter != _HabitListFilters.all ||
      _priorityFilter != _HabitListFilters.all;

  Future<void> _showFilterSheet(List<String> categories) async {
    var selectedStatus = _statusFilter;
    var selectedCategory = _categoryFilter;
    var selectedPriority = _priorityFilter;

    final result = await showModalBottomSheet<
        ({String status, String category, String priority})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bộ lọc',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Chọn điều kiện để thu gọn danh sách thói quen.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Trạng thái',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final status in _HabitListFilters.statusValues)
                          ChoiceChip(
                            label: Text(_labelForFilter(status)),
                            selected: selectedStatus == status,
                            onSelected: (_) {
                              setSheetState(() => selectedStatus = status);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      items: [_HabitListFilters.all, ...categories]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_labelForFilter(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: 'Độ ưu tiên'),
                      items: const [
                        _HabitListFilters.all,
                        ...HabitPriority.values,
                      ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_labelForFilter(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedPriority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                                (
                                  status: _HabitListFilters.main,
                                  category: _HabitListFilters.all,
                                  priority: _HabitListFilters.all,
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

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _statusFilter = result.status;
      _categoryFilter = result.category;
      _priorityFilter = result.priority;
    });
  }
}

class _FilterTag extends StatelessWidget {
  final String label;

  const _FilterTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _TemplateEntryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _TemplateEntryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mẫu thói quen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tạo nhanh',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitListView extends StatelessWidget {
  final List<HabitModel> habits;
  final ValueChanged<HabitModel> onEditHabit;
  final ValueChanged<HabitModel> onOpenHabit;

  const _HabitListView({
    required this.habits,
    required this.onEditHabit,
    required this.onOpenHabit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: habits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final habit = habits[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            leading: CircleAvatar(
              child: Text(
                habit.name.isEmpty ? '?' : habit.name[0].toUpperCase(),
              ),
            ),
            title: Text(
              habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _HabitChip(
                    label: habit.category.isEmpty ? 'Chung' : habit.category,
                  ),
                  _HabitChip(label: _labelForFilter(habit.frequency)),
                  _HabitChip(label: _labelForFilter(habit.priority)),
                  _HabitChip(label: _labelForFilter(habit.difficulty)),
                  _HabitChip(label: _labelForFilter(habit.status)),
                ],
              ),
            ),
            trailing: IconButton(
              tooltip: 'Sửa thói quen',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => onEditHabit(habit),
            ),
            onTap: () => onOpenHabit(habit),
          ),
        );
      },
    );
  }
}

class _HabitListFilters {
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

String _labelForFilter(String value) {
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

extension on _HomeScreenState {
  Future<void> _showTemplateSheet(String userId) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    await habitProvider.fetchHabitTemplates();

    if (!mounted) {
      return;
    }

    final selectedTemplate = await showModalBottomSheet<HabitTemplateModel>(
      context: context,
      backgroundColor: const Color(0xFFFBF8F7),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final templates = habitProvider.templates;

        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
            shrinkWrap: true,
            itemCount: templates.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mẫu thói quen',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 34,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF171313),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Chọn một mẫu để điền nhanh thông tin thói quen.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5C5454),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final template = templates[index - 1];
              final templateName = _cleanTemplateText(template.name);
              final templateCategory = _cleanTemplateText(
                template.category.isEmpty ? 'Chung' : template.category,
              );
              return InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => Navigator.pop(sheetContext, template),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
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
                        child: const Icon(Icons.auto_awesome_outlined),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              templateName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$templateCategory • ${_labelForFilter(template.frequency)} • ${_labelForFilter(template.difficulty)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6A6262),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (selectedTemplate == null || !mounted) {
      return;
    }

    final initialHabit = HabitModel.create(
      userId: userId,
      name: _cleanTemplateText(selectedTemplate.name),
      description: _cleanTemplateText(selectedTemplate.description),
      category: _cleanTemplateText(selectedTemplate.category),
      frequency: selectedTemplate.frequency,
      difficulty: selectedTemplate.difficulty,
    );

    await _showHabitFormDialog(userId: userId, initialHabit: initialHabit);
  }

  Future<void> _showHabitFormDialog({
    required String userId,
    HabitModel? habit,
    HabitModel? initialHabit,
  }) async {
    final savedHabit = await showModalBottomSheet<HabitModel>(
      context: context,
      backgroundColor: const Color(0xFFFBF8F7),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _HabitFormDialog(
        userId: userId,
        habit: habit,
        initialHabit: initialHabit,
      ),
    );

    if (savedHabit == null || !mounted) {
      return;
    }

    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final success = habit == null
        ? await habitProvider.addHabit(savedHabit)
        : await habitProvider.updateHabit(savedHabit);

    if (!mounted) {
      return;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? habit == null
                  ? 'Đã tạo thói quen.'
                  : 'Đã cập nhật thói quen.'
              : habitProvider.errorMessage ??
                  'Không thể lưu thói quen. Vui lòng thử lại.',
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Äá»•i máº­t kháº©u'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Máº­t kháº©u hiá»‡n táº¡i',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: obscureCurrent
                                ? 'Hiá»‡n máº­t kháº©u'
                                : 'áº¨n máº­t kháº©u',
                            icon: Icon(
                              obscureCurrent
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setDialogState(
                              () => obscureCurrent = !obscureCurrent,
                            ),
                          ),
                        ),
                        validator: FormValidators.loginPassword,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Máº­t kháº©u má»›i',
                          prefixIcon: const Icon(Icons.password_outlined),
                          suffixIcon: IconButton(
                            tooltip: obscureNew
                                ? 'Hiá»‡n máº­t kháº©u'
                                : 'áº¨n máº­t kháº©u',
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setDialogState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: (value) => FormValidators.changedPassword(
                          value,
                          currentPasswordController.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Nháº­p láº¡i máº­t kháº©u má»›i',
                          prefixIcon: const Icon(Icons.verified_user_outlined),
                          suffixIcon: IconButton(
                            tooltip: obscureConfirm
                                ? 'Hiá»‡n máº­t kháº©u'
                                : 'áº¨n máº­t kháº©u',
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setDialogState(
                              () => obscureConfirm = !obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (value) => FormValidators.confirmPassword(
                          value,
                          newPasswordController.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Há»§y'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final success = await authProvider.changePassword(
                      currentPassword: currentPasswordController.text,
                      newPassword: newPasswordController.text,
                    );

                    if (!context.mounted || !dialogContext.mounted) {
                      return;
                    }

                    if (success) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Äá»•i máº­t kháº©u thĂ nh cĂ´ng.'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.errorMessage ??
                                'KhĂ´ng thá»ƒ Ä‘á»•i máº­t kháº©u.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Cáº­p nháº­t'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}

class _HabitChip extends StatelessWidget {
  final String label;

  const _HabitChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

enum _AccountAction { profile, changePassword, logout }

class _TiimoBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAccountPressed;

  const _TiimoBottomNav({
    required this.selectedIndex,
    required this.onSelected,
    required this.onAccountPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(
            icon: Icons.check_box_outlined,
            selectedIcon: Icons.check_box,
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _NavIcon(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today,
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          _NavIcon(
            icon: Icons.bar_chart_rounded,
            selectedIcon: Icons.bar_chart_rounded,
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          _NavIcon(
            icon: Icons.more_horiz,
            selectedIcon: Icons.more_horiz,
            selected: false,
            onTap: onAccountPressed,
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEDECEA) : Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(
            selected ? selectedIcon : icon,
            color: selected ? const Color(0xFF171313) : const Color(0xFF77716E),
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccountActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          trailing: const Icon(Icons.arrow_forward_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

String _cleanTemplateText(String value) {
  const replacements = {
    'Uá»‘ng nÆ°á»›c': 'Uống nước',
    'Uá»‘ng Ä‘á»§ nÆ°á»›c má»—i ngĂ y Ä‘á»ƒ duy trĂ¬ sá»©c khá»e.':
        'Uống đủ nước mỗi ngày để duy trì sức khỏe.',
    'Sá»©c khá»e': 'Sức khỏe',
    'Äá»c sĂ¡ch': 'Đọc sách',
    'Äá»c sĂ¡ch 20-30 phĂºt má»—i ngĂ y.':
        'Đọc sách 20-30 phút mỗi ngày.',
    'Há»c táº­p': 'Học tập',
    'Táº­p thá»ƒ dá»¥c': 'Tập thể dục',
    'Váº­n Ä‘á»™ng hoáº·c táº­p luyá»‡n Ă­t nháº¥t 20 phĂºt.':
        'Vận động hoặc tập luyện ít nhất 20 phút.',
    'Thiá»n': 'Thiền',
    'DĂ nh vĂ i phĂºt Ä‘á»ƒ thá»Ÿ sĂ¢u vĂ  táº­p trung.':
        'Dành vài phút để thở sâu và tập trung.',
    'Tinh tháº§n': 'Tinh thần',
    'Há»c tiáº¿ng Anh': 'Học tiếng Anh',
    'Há»c tá»« vá»±ng hoáº·c luyá»‡n nghe tiáº¿ng Anh má»—i ngĂ y.':
        'Học từ vựng hoặc luyện nghe tiếng Anh mỗi ngày.',
    'Ngá»§ sá»›m': 'Ngủ sớm',
    'Äi ngá»§ Ä‘Ăºng giá» Ä‘á»ƒ cáº£i thiá»‡n nÄƒng lÆ°á»£ng ngĂ y hĂ´m sau.':
        'Đi ngủ đúng giờ để cải thiện năng lượng ngày hôm sau.',
  };

  return replacements[value] ?? value;
}

class _HabitFormDialog extends StatefulWidget {
  final String userId;
  final HabitModel? habit;
  final HabitModel? initialHabit;

  const _HabitFormDialog({
    required this.userId,
    this.habit,
    this.initialHabit,
  });

  @override
  State<_HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<_HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _reminderController;
  late String _frequency;
  late String _priority;
  late String _difficulty;
  late String _status;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit ?? widget.initialHabit;
    _nameController = TextEditingController(text: habit?.name ?? '');
    _descriptionController = TextEditingController(
      text: habit?.description ?? '',
    );
    _categoryController = TextEditingController(text: habit?.category ?? '');
    _reminderController = TextEditingController(
      text: habit?.reminderTime ?? '',
    );
    _frequency = habit?.frequency ?? HabitFrequency.daily;
    _priority = habit?.priority ?? HabitPriority.medium;
    _difficulty = habit?.difficulty ?? HabitDifficulty.easy;
    _status = habit?.status ?? HabitStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            shrinkWrap: true,
            children: [
              Text(
                isEditing ? 'Sửa thói quen' : 'Thêm thói quen',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 34,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171313),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cài đặt nhịp lặp, mức ưu tiên và giờ nhắc để đưa thói quen vào lịch ngày.',
                style: TextStyle(fontSize: 16, color: Color(0xFF5C5454)),
              ),
              const SizedBox(height: 18),
              _HabitFormCard(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Tên thói quen'),
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Vui lòng nhập tên thói quen.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                    autocorrect: false,
                    enableSuggestions: false,
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reminderController,
                    decoration: const InputDecoration(
                      labelText: 'Giờ nhắc',
                      hintText: 'Ví dụ: 07:30',
                    ),
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _HabitFormCard(
                children: [
                  _HabitSelectField(
                    label: 'Tần suất',
                    child: DropdownButtonFormField<String>(
                      value: _frequency,
                      isExpanded: true,
                      menuMaxHeight: 320,
                      decoration: _habitFieldDecoration(),
                      items: _menuItems(HabitFrequency.values),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _frequency = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HabitSelectField(
                    label: 'Độ ưu tiên',
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      isExpanded: true,
                      menuMaxHeight: 320,
                      decoration: _habitFieldDecoration(),
                      items: _menuItems(HabitPriority.values),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _priority = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HabitSelectField(
                    label: 'Độ khó',
                    child: DropdownButtonFormField<String>(
                      value: _difficulty,
                      isExpanded: true,
                      menuMaxHeight: 320,
                      decoration: _habitFieldDecoration(),
                      items: _menuItems(HabitDifficulty.values),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _difficulty = value);
                        }
                      },
                    ),
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 12),
                    _HabitSelectField(
                      label: 'Trạng thái',
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        isExpanded: true,
                        menuMaxHeight: 320,
                        decoration: _habitFieldDecoration(),
                        items: _menuItems(
                          HabitStatus.values.where(
                            (value) => value != HabitStatus.deleted,
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF171313),
                        side: const BorderSide(color: Color(0xFF171313)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF171313),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(isEditing ? 'Cập nhật' : 'Lưu'),
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

  List<DropdownMenuItem<String>> _menuItems(Iterable<String> values) {
    return values
        .map(
          (value) => DropdownMenuItem(
            value: value,
            child: Text(_labelForFilter(value)),
          ),
        )
        .toList();
  }

  InputDecoration _habitFieldDecoration() {
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: const Color(0xFFFBF8F7),
      contentPadding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    final habit = widget.habit;
    final savedHabit = habit == null
        ? HabitModel.create(
            userId: widget.userId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _categoryController.text.trim(),
            frequency: _frequency,
            reminderTime: _reminderController.text.trim(),
            priority: _priority,
            difficulty: _difficulty,
          )
        : habit.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _categoryController.text.trim(),
            frequency: _frequency,
            reminderTime: _reminderController.text.trim(),
            priority: _priority,
            difficulty: _difficulty,
            status: _status,
          );

    Navigator.pop(context, savedHabit);
  }
}

class _HabitSelectField extends StatelessWidget {
  final String label;
  final Widget child;

  const _HabitSelectField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5C5454),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _HabitFormCard extends StatelessWidget {
  final List<Widget> children;

  const _HabitFormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(children: children),
    );
  }
}
