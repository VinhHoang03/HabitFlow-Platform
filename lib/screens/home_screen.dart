import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/statistics_provider.dart';
import '../models/habit_model.dart';
import 'stats_screen.dart';
import 'achievement_screen.dart';
import 'calendar_screen.dart';

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
    final user = authProvider.user;

    if (user != null) {
      Provider.of<StatisticsProvider>(
        context,
        listen: false,
      ).watchUserStats(user.uid, habitProvider.habits);
    }

    final List<Widget> pages = [
      _buildHabitList(habitProvider, authProvider),
      const StatsScreen(),
      const AchievementScreen(),
      const CalendarScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Badges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: user == null
                  ? null
                  : () => _showAddHabitDialog(context, user.uid),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHabitList(
    HabitProvider habitProvider,
    AuthProvider authProvider,
  ) {
    return habitProvider.habits.isEmpty
        ? const Center(child: Text('No habits yet. Add one!'))
        : ListView.builder(
            itemCount: habitProvider.habits.length,
            itemBuilder: (context, index) {
              final habit = habitProvider.habits[index];
              return ListTile(
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
              );
            },
          );
  }

  void _showAddHabitDialog(BuildContext context, String userId) {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final habit = HabitModel(
                habitId: '',
                userId: userId,
                title: titleController.text,
                description: '',
                category: categoryController.text,
                targetPerDay: 1,
                createdAt: DateTime.now(),
              );
              Provider.of<HabitProvider>(
                context,
                listen: false,
              ).addHabit(habit);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
