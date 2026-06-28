import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/providers/statistics_provider.dart';
import 'package:habitflow/screens/achievement_screen.dart';
import 'package:habitflow/screens/stats_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Statistics screen displays empty progress state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => StatisticsProvider(),
        child: const MaterialApp(home: StatsScreen()),
      ),
    );

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Completion'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Weekly Statistics'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    expect(find.text('Monthly Statistics'), findsOneWidget);
  });

  testWidgets('Achievement screen displays default badges', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => StatisticsProvider(),
        child: const MaterialApp(home: AchievementScreen()),
      ),
    );

    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('First Win'), findsOneWidget);
    expect(find.text('3-Day Streak'), findsOneWidget);
    expect(find.text('7-Day Streak'), findsOneWidget);
    expect(find.text('10 Check-ins'), findsOneWidget);
  });
}
