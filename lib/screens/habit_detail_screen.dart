import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../services/consistency_calculator.dart';
import '../constants/app_strings.dart';
import 'add_edit_habit_screen.dart';

class HabitDetailScreen extends ConsumerWidget {
  final Habit habit;
  
  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider);
    // Get the updated habit from state in case it was edited
    final currentHabit = habits.firstWhere((h) => h.id == habit.id, orElse: () => habit);
    
    final logs = ref.watch(habitLogProvider);
    final theme = Theme.of(context);

    final percent7 = ConsistencyCalculator.calculatePercentage(currentHabit, logs, 7);
    final percent30 = ConsistencyCalculator.calculatePercentage(currentHabit, logs, 30);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(currentHabit.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditHabitScreen(habit: currentHabit)),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLargeStat(theme, AppStrings.sevenDay, percent7),
                  _buildLargeStat(theme, AppStrings.thirtyDay, percent30),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(AppStrings.insights, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: theme.colorScheme.secondary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _getInsightMessage(percent7, currentHabit),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(AppStrings.recentLogs, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRecentLogs(logs, theme, currentHabit.id),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeStat(ThemeData theme, String label, double percentage) {
    return Column(
      children: [
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _getInsightMessage(double percent, Habit habit) {
    if (percent >= 80) {
      return AppStrings.insightGreat;
    } else if (percent >= 40) {
      return AppStrings.insightGood;
    } else {
      return AppStrings.insightSlow;
    }
  }

  Widget _buildRecentLogs(List<dynamic> allLogs, ThemeData theme, String habitId) {
    final habitLogs = allLogs.where((log) => log.habitId == habitId && !log.isDeleted).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
    if (habitLogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(AppStrings.noLogsYet, style: TextStyle(color: theme.colorScheme.outline)),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: habitLogs.length > 5 ? 5 : habitLogs.length, // Show up to 5
      itemBuilder: (context, index) {
        final log = habitLogs[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.check_circle, color: theme.colorScheme.primaryContainer),
          title: Text(
            '${log.timestamp.month}/${log.timestamp.day}/${log.timestamp.year}',
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
          ),
        );
      },
    );
  }
}
