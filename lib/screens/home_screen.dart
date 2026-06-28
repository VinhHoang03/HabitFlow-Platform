import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../utils/form_validators.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      Provider.of<HabitProvider>(
        context,
        listen: false,
      ).fetchHabits(authProvider.user!.uid);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
      appBar: AppBar(
        title: const Text('HabitFlow'),
        actions: [
          PopupMenuButton<_AccountAction>(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Tài khoản',
            onSelected: (value) {
              switch (value) {
                case _AccountAction.profile:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                  break;
                case _AccountAction.changePassword:
                  _showChangePasswordDialog(context);
                  break;
                case _AccountAction.logout:
                  authProvider.logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  authProvider.user?.email ?? 'Tài khoản',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _AccountAction.profile,
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _AccountAction.changePassword,
                child: ListTile(
                  leading: Icon(Icons.password_outlined),
                  title: Text('Đổi mật khẩu'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _AccountAction.logout,
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Đăng xuất'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Calendar',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _showAddHabitDialog(context, authProvider.user!.uid),
              icon: const Icon(Icons.add),
              label: const Text('Thói quen'),
            )
          : null,
    );
  }

  Widget _buildHabitList(HabitProvider habitProvider) {
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: habitProvider.habits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final habit = habitProvider.habits[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                habit.title.isEmpty ? '?' : habit.title[0].toUpperCase(),
              ),
            ),
            title: Text(habit.title),
            subtitle: Text(habit.category),
            trailing: Checkbox(
              value: false,
              onChanged: (val) {
                habitProvider.completeHabit(
                  habit.habitId,
                  DateTime.now(),
                  val ?? false,
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddHabitDialog(BuildContext context, String userId) {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thói quen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tên thói quen'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Danh mục'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final habit = HabitModel(
                habitId: '',
                userId: userId,
                title: titleController.text.trim(),
                description: '',
                category: categoryController.text.trim(),
                targetPerDay: 1,
                createdAt: DateTime.now(),
              );
              Provider.of<HabitProvider>(
                context,
                listen: false,
              ).addHabit(habit);
              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      categoryController.dispose();
    });
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
              title: const Text('Đổi mật khẩu'),
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
                          labelText: 'Mật khẩu hiện tại',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: obscureCurrent
                                ? 'Hiện mật khẩu'
                                : 'Ẩn mật khẩu',
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
                          labelText: 'Mật khẩu mới',
                          prefixIcon: const Icon(Icons.password_outlined),
                          suffixIcon: IconButton(
                            tooltip: obscureNew
                                ? 'Hiện mật khẩu'
                                : 'Ẩn mật khẩu',
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
                          labelText: 'Nhập lại mật khẩu mới',
                          prefixIcon: const Icon(Icons.verified_user_outlined),
                          suffixIcon: IconButton(
                            tooltip: obscureConfirm
                                ? 'Hiện mật khẩu'
                                : 'Ẩn mật khẩu',
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
                  child: const Text('Hủy'),
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
                          content: Text('Đổi mật khẩu thành công.'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.errorMessage ??
                                'Không thể đổi mật khẩu.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Cập nhật'),
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

enum _AccountAction { profile, changePassword, logout }
