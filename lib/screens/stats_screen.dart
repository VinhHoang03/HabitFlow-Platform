import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Weekly Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  // Dummy data for demo
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.teal)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: Colors.teal)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 10, color: Colors.teal)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 7, color: Colors.teal)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 6, color: Colors.teal)]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
