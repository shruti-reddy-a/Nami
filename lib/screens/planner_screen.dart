import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../constants/app_strings.dart';
import '../models/habit.dart';
import '../models/habit_recurrence.dart';
import '../providers/habit_provider.dart';
import 'habit_detail_screen.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  bool _checkOccurs(Habit habit, DateTime start, DateTime d) {
    final freq = habit.recurrence.frequency;
    final interval = habit.recurrence.interval;
    
    if (freq == RecurrenceFrequency.daily) {
      final daysDiff = d.difference(start).inDays;
      return daysDiff % interval == 0;
    } else if (freq == RecurrenceFrequency.weekly) {
      final daysDiff = d.difference(start).inDays;
      final weeksDiff = daysDiff ~/ 7;
      return weeksDiff % interval == 0 && habit.recurrence.daysOfWeek.contains(d.weekday);
    } else if (freq == RecurrenceFrequency.monthly) {
      final monthsDiff = (d.year - start.year) * 12 + d.month - start.month;
      return monthsDiff % interval == 0 && d.day == (habit.recurrence.dayOfMonth ?? start.day);
    }
    return false;
  }

  bool _isHabitScheduledOnDate(Habit habit, DateTime date) {
    final start = DateTime.utc(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
    final target = DateTime.utc(date.year, date.month, date.day);
    
    if (target.isBefore(start)) return false;
    
    if (habit.recurrence.endDate != null) {
      final end = DateTime.utc(habit.recurrence.endDate!.year, habit.recurrence.endDate!.month, habit.recurrence.endDate!.day);
      if (target.isAfter(end)) return false;
    }

    if (!_checkOccurs(habit, start, target)) return false;

    // Check endOccurrences
    if (habit.recurrence.endOccurrences != null) {
      int count = 0;
      DateTime current = start;
      while (current.isBefore(target) || current.isAtSameMomentAs(target)) {
        if (_checkOccurs(habit, start, current)) {
          count++;
        }
        if (count > habit.recurrence.endOccurrences!) return false;
        current = current.add(const Duration(days: 1));
      }
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitProvider);
    
    final scheduledHabits = habits.where((h) => _selectedDay != null && _isHabitScheduledOnDate(h, _selectedDay!)).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.tabPlanner, style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
            eventLoader: (day) {
              return habits.where((h) => _isHabitScheduledOnDate(h, day)).toList();
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(3).map((e) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.secondary,
                      ),
                    )).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scheduled for ${_selectedDay?.month}/${_selectedDay?.day}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (scheduledHabits.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: Text(
                          'No habits scheduled for this day.',
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: scheduledHabits.length,
                        itemBuilder: (context, index) {
                          final habit = scheduledHabits[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            color: theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${habit.timeOfDay != null && habit.timeOfDay != 'Anytime' ? '${habit.timeOfDay} • ' : ''}${habit.recurrence.toReadableString()}',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)));
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
