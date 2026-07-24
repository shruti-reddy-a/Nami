import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nami/core/utils/string_extensions.dart';
import 'package:nami/features/habit/presentation/utils/habit_ui_helper.dart';
import 'package:nami/features/habit/data/habit.dart';
import 'package:nami/features/habit/data/habit_log.dart';
import 'package:nami/features/habit/providers/habit_provider.dart';
import 'package:nami/features/habit/services/consistency_calculator.dart';
import 'package:nami/features/habit/presentation/screens/add_edit_habit_screen.dart';
import 'package:nami/features/habit/presentation/screens/habit_detail_screen.dart';
import 'package:nami/core/presentation/widgets/common_app_bar_actions.dart';

enum HabitSortOption {
  aToZ('A-Z'),
  zToA('Z-A'),
  latestAdded('Latest Added'),
  latestUpdated('Latest Updated'),
  chronological('Chronological');

  final String label;
  const HabitSortOption(this.label);
}

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  String _searchQuery = '';
  HabitSortOption _sortOption = HabitSortOption.aToZ;

  @override
  Widget build(BuildContext context) {
    final allHabits = ref.watch(habitProvider);
    final logs = ref.watch(habitLogProvider);
    final theme = Theme.of(context);
    
    final filteredHabits = _searchQuery.isEmpty 
        ? allHabits 
        : allHabits.where((h) => h.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final habits = List<Habit>.from(filteredHabits);
    switch (_sortOption) {
      case HabitSortOption.aToZ:
        habits.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case HabitSortOption.zToA:
        habits.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case HabitSortOption.latestAdded:
        habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case HabitSortOption.latestUpdated:
        habits.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case HabitSortOption.chronological:
        habits.sort((a, b) {
          final timeA = _getHourForHabit(a);
          final timeB = _getHourForHabit(b);
          if (timeA == timeB) return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          if (timeA == -1) return 1;
          if (timeB == -1) return -1;
          return timeA.compareTo(timeB);
        });
        break;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('NAMI', style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary, letterSpacing: 1.2)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: const [CommonAppBarActions()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search habits...',
                            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<HabitSortOption>(
                      initialValue: _sortOption,
                      icon: Icon(Icons.sort, color: theme.colorScheme.primary),
                      tooltip: 'Sort habits',
                      onSelected: (HabitSortOption option) {
                        setState(() {
                          _sortOption = option;
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return HabitSortOption.values.map((HabitSortOption option) {
                          return PopupMenuItem<HabitSortOption>(
                            value: option,
                            child: Text(option.label, style: TextStyle(
                              color: _sortOption == option ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              fontWeight: _sortOption == option ? FontWeight.bold : FontWeight.normal,
                            )),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: habits.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.style, size: 48, color: theme.colorScheme.primaryContainer),
                              const SizedBox(height: 16),
                              Text("No habits yet", style: theme.textTheme.headlineSmall),
                              const SizedBox(height: 8),
                              Text("Create your first habit and start building consistency.", textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditHabitScreen())),
                                child: const Text('Create Habit'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: habits.length,
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          return _buildHabitCard(context, habit, logs, theme);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
    );
  }



  int _getHourForHabit(Habit habit) {
    if (habit.timeOfDay == null || habit.timeOfDay == 'Anytime') return -1;
    final timeLower = habit.timeOfDay!.toLowerCase();
    if (timeLower.contains('morning')) return 8;
    if (timeLower.contains('afternoon') || timeLower.contains('noon')) return 12;
    if (timeLower.contains('evening')) return 16;
    if (timeLower.contains('night')) return 20;
    
    final parts = habit.timeOfDay!.split(':');
    if (parts.length >= 2) {
      return int.tryParse(parts[0]) ?? -1;
    }
    return -1;
  }

  Widget _buildHabitCard(BuildContext context, Habit habit, List<HabitLog> logs, ThemeData theme) {
    final percent30 = ConsistencyCalculator.calculatePercentage(habit, logs, 30);
    final habitIcon = HabitUIHelper.getIconForHabit(habit.title);
    final habitColor = HabitUIHelper.getColorForHabit(habit.title);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.15),
      color: theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: habitColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(habitIcon, color: Colors.black87),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      habit.title.capitalizeAllWords(),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${habit.timeOfDay != null && habit.timeOfDay != 'Anytime' ? '${habit.timeOfDay} • ' : ''}${habit.recurrence.toReadableString()}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent30 / 100.0,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percent30.toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddEditHabitScreen(habit: habit)),
                    );
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Habit'),
                        content: const Text('Are you sure you want to delete this habit?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(habitProvider.notifier).deleteHabit(habit.id);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
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
