import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:nami/features/habit/data/habit.dart';
import 'package:nami/features/habit/data/habit_recurrence.dart';
import 'package:nami/features/habit/providers/habit_provider.dart';
import 'package:nami/features/habit/presentation/screens/habit_detail_screen.dart';
import 'package:nami/core/presentation/widgets/common_app_bar_actions.dart';
import 'package:nami/core/utils/string_extensions.dart';
import 'package:nami/features/habit/presentation/utils/habit_ui_helper.dart';
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

enum ViewType { month, week, day }

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  ViewType _currentView = ViewType.day;
  final EventController<Object?> _eventController = EventController<Object?>();
  DateTime _selectedDate = DateTime.now();
  final GlobalKey<DayViewState> _dayViewStateKey = GlobalKey<DayViewState>();
  final GlobalKey<WeekViewState> _weekViewStateKey = GlobalKey<WeekViewState>();
  final GlobalKey<MonthViewState> _monthViewStateKey = GlobalKey<MonthViewState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habits = ref.read(habitProvider);
      _updateEvents(habits);
    });
  }

  void _updateEvents(List<Habit> habits) {
    _eventController.removeWhere((_) => true);
    _eventController.addAll(_generateEvents(habits));
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
    final start = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
    final target = DateTime(date.year, date.month, date.day);
    
    if (target.isBefore(start)) return false;
    
    if (habit.recurrence.endDate != null) {
      final end = DateTime(habit.recurrence.endDate!.year, habit.recurrence.endDate!.month, habit.recurrence.endDate!.day);
      if (target.isAfter(end)) return false;
    }

    if (!_checkOccurs(habit, start, target)) return false;

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

  List<CalendarEventData<Object?>> _generateEvents(List<Habit> habits) {
    
    // Generate events for +/- 6 months
    final now = DateTime.now();
    final startRange = DateTime(now.year, now.month - 6, 1);
    final endRange = DateTime(now.year, now.month + 6, 28);
    
    List<CalendarEventData<Object?>> events = [];
    
    for (final habit in habits) {
      DateTime current = startRange;
      while (current.isBefore(endRange)) {
        if (_isHabitScheduledOnDate(habit, current)) {
          
          DateTime startTime;
          DateTime endTime;
          
          if (habit.timeOfDay != null && habit.timeOfDay != 'Anytime') {
            int hour = 0;
            int minute = 0;
            final timeLower = habit.timeOfDay!.toLowerCase();
            if (timeLower.contains('morning')) {
              hour = 8;
            } else if (timeLower.contains('afternoon') || timeLower.contains('noon')) {
              hour = 12;
            } else if (timeLower.contains('evening')) {
              hour = 16;
            } else {
              final parts = habit.timeOfDay!.split(':');
              if (parts.length >= 2) {
                hour = int.tryParse(parts[0]) ?? 0;
                minute = int.tryParse(parts[1]) ?? 0;
              }
            }
            startTime = DateTime(current.year, current.month, current.day, hour, minute);
            endTime = startTime.add(const Duration(hours: 1));
          } else {
            startTime = DateTime(current.year, current.month, current.day, 0, 0);
            endTime = DateTime(current.year, current.month, current.day, 23, 59);
          }
          
          events.add(CalendarEventData<Object?>(
            title: habit.title,
            date: current,
            startTime: startTime,
            endTime: endTime,
            event: habit,
            color: const Color(0xFF006D77), // Teal
          ));
        }
        current = current.add(const Duration(days: 1));
      }
    }
    
    return events;
  }

  double _calculateInitialScrollOffset(DateTime date, ViewType type) {
    const double hourHeight = 42.0; 
    
    DateTime? earliest;
    
    final daysToCheck = <DateTime>[];
    if (type == ViewType.week) {
      final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      for (int i = 0; i < 7; i++) {
        daysToCheck.add(startOfWeek.add(Duration(days: i)));
      }
    } else {
      daysToCheck.add(date);
    }
    
    for (final day in daysToCheck) {
      final eventsOnDate = _eventController.getEventsOnDay(day);
      for (final e in eventsOnDate) {
        if (e.startTime != null) {
          if (earliest == null || e.startTime!.isBefore(earliest)) {
            earliest = e.startTime;
          }
        }
      }
    }
    
    if (earliest == null) return 0.0;
    return earliest.hour * hourHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    ref.listen<List<Habit>>(habitProvider, (previous, next) {
      _updateEvents(next);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'NAMI',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        actions: const [CommonAppBarActions()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              SegmentedButton<ViewType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<ViewType>(value: ViewType.day, label: Text('Day', style: TextStyle(fontSize: 12))),
                  ButtonSegment<ViewType>(value: ViewType.week, label: Text('Week', style: TextStyle(fontSize: 12))),
                  ButtonSegment<ViewType>(value: ViewType.month, label: Text('Month', style: TextStyle(fontSize: 12))),
                ],
                selected: {_currentView},
                onSelectionChanged: (Set<ViewType> newSelection) {
                  setState(() {
                    _currentView = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                  child: _buildCalendarView(theme, _eventController),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }


  Widget _buildHabitCard(DateTime date, List<CalendarEventData<Object?>> events, Rect boundary, DateTime startDuration, DateTime endDuration, ThemeData theme) {
    if (events.isEmpty) return const SizedBox.shrink();
    final event = events.first;
    final habit = event.event as Habit;

    return Consumer(
      builder: (context, ref, child) {
        final logs = ref.watch(habitLogProvider);
        final logList = logs.where((l) => l.habitId == habit.id && l.timestamp.year == date.year && l.timestamp.month == date.month && l.timestamp.day == date.day).toList();
        final isLogged = logList.isNotEmpty;

    final durationString = '${event.startTime!.hour.toString().padLeft(2, '0')}:${event.startTime!.minute.toString().padLeft(2, '0')} • 60 mins';
    
    final primaryTeal = const Color(0xFF00696F);
    final lightTeal = const Color(0xFF90C2C6);
    
    final habitIcon = HabitUIHelper.getIconForHabit(habit.title);
    
    String? description;
    if (habit.title.toLowerCase().contains('meditation')) {
      description = "Mindful breathing session for mental clarity.";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)));
      },
      child: Material(
        elevation: isLogged ? 0 : 2,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
        color: isLogged 
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) 
            : (theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surfaceContainerHigh),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isLogged ? Colors.transparent : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.hardEdge,
        child: OverflowBox(
          minHeight: 0,
          maxHeight: double.infinity,
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Left Indicator (only for pending)
            if (!isLogged)
              Container(
                margin: const EdgeInsets.only(right: 8, top: 2),
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: lightTeal,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            if (isLogged) const SizedBox(width: 12),
            
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.mediumImpact();
                if (!isLogged) {
                  ref.read(habitLogProvider.notifier).logHabit(habit.id);
                } else {
                  ref.read(habitLogProvider.notifier).removeLog(logList.first.id);
                }
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isLogged ? primaryTeal : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: isLogged ? null : Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Icon(
                  isLogged ? Icons.check : Icons.add,
                  color: isLogged ? Colors.white : theme.colorScheme.primary,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Optional Icon next to circle
            if (!isLogged) ...[
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Icon(habitIcon, color: primaryTeal, size: 18),
              ),
              const SizedBox(width: 8),
            ],
            
            // Details
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    habit.title.capitalizeAllWords(),
                    style: TextStyle(
                      color: isLogged ? primaryTeal : theme.colorScheme.onSurface, 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (boundary.height > 40)
                    Text(
                      durationString,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  if (description != null && boundary.height > 50)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        description,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
          ],
        ),
        ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildCalendarView(ThemeData theme, EventController<Object?> controller) {
    switch (_currentView) {
      case ViewType.month:
        return MonthView<Object?>(
          key: _monthViewStateKey,
          controller: controller,
          monthViewStyle: MonthViewStyle(initialMonth: _selectedDate),
          monthViewBuilders: MonthViewBuilders<Object?>(
            headerBuilder: (date) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _monthViewStateKey.currentState?.previousPage(),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDatePickerMode: DatePickerMode.year,
                            helpText: 'Select a Month (Pick any day)',
                          );
                          if (selectedDate != null) {
                            setState(() => _selectedDate = selectedDate);
                            _monthViewStateKey.currentState?.jumpToMonth(selectedDate);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(DateFormat('MMMM yyyy').format(date), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _monthViewStateKey.currentState?.nextPage(),
                    ),
                  ],
                ),
              );
            },
            onPageChange: (date, pageIndex) {
              setState(() => _selectedDate = date);
            },
            onCellTap: (events, date) {
              if (events.isNotEmpty && events.first.event is Habit) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: events.first.event as Habit)));
              }
            },
            cellBuilder: (DateTime date, List<CalendarEventData<Object?>> events, bool isToday, bool isInMonth, bool hideDaysNotInMonth) {
              if (hideDaysNotInMonth && !isInMonth) {
                return const SizedBox.shrink();
              }
              return Container(
                decoration: BoxDecoration(
                  color: isToday ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxHeight < 24) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        const SizedBox(height: 2),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isToday 
                            ? theme.colorScheme.primary 
                            : (isInMonth ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant),
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return GestureDetector(
                            onTap: () {
                              if (event.event is Habit) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: event.event as Habit)));
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: event.color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                event.title,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
                  },
                ),
              );
            },
          ),
        );
      case ViewType.week:
        return WeekView<Object?>(
          key: _weekViewStateKey,
          controller: controller,
          initialDay: _selectedDate,
          scrollOffset: _calculateInitialScrollOffset(_selectedDate, ViewType.week),
          weekPageHeaderBuilder: (startDate, endDate) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _weekViewStateKey.currentState?.previousPage(),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: startDate, 
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          helpText: 'Select a Week (Pick a Monday)',
                          selectableDayPredicate: (day) => day.weekday == DateTime.monday,
                        );
                        if (selectedDate != null) {
                          setState(() => _selectedDate = selectedDate);
                          _weekViewStateKey.currentState?.jumpToWeek(selectedDate);
                          final newOffset = _calculateInitialScrollOffset(selectedDate, ViewType.week);
                          if (_weekViewStateKey.currentState?.scrollController.hasClients == true) {
                            _weekViewStateKey.currentState?.scrollController.animateTo(newOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${DateFormat('MMMM d, yyyy').format(startDate)} - ${DateFormat('MMMM d, yyyy').format(endDate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Icon(Icons.edit, size: 16, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _weekViewStateKey.currentState?.nextPage(),
                  ),
                ],
              ),
            );
          },
          onPageChange: (date, pageIndex) {
            setState(() => _selectedDate = date);
            final newOffset = _calculateInitialScrollOffset(date, ViewType.week);
            if (_weekViewStateKey.currentState?.scrollController.hasClients == true) {
              _weekViewStateKey.currentState?.scrollController.animateTo(
                newOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          eventTileBuilder: (date, events, boundary, startDuration, endDuration) {
            return _buildHabitCard(date, events, boundary, startDuration, endDuration, theme);
          },
        );
      case ViewType.day:
        return DayView<Object?>(
          key: _dayViewStateKey,
          controller: controller,
          initialDay: _selectedDate,
          scrollOffset: _calculateInitialScrollOffset(_selectedDate, ViewType.day),
          dayTitleBuilder: (date) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _dayViewStateKey.currentState?.previousPage(),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          setState(() => _selectedDate = selectedDate);
                          _dayViewStateKey.currentState?.jumpToDate(selectedDate);
                          final newOffset = _calculateInitialScrollOffset(selectedDate, ViewType.day);
                          if (_dayViewStateKey.currentState?.scrollController.hasClients == true) {
                            _dayViewStateKey.currentState?.scrollController.animateTo(newOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('MMMM d, yyyy').format(date), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _dayViewStateKey.currentState?.nextPage(),
                  ),
                ],
              ),
            );
          },
          onPageChange: (date, pageIndex) {
            setState(() => _selectedDate = date);
            final newOffset = _calculateInitialScrollOffset(date, ViewType.day);
            if (_dayViewStateKey.currentState?.scrollController.hasClients == true) {
              _dayViewStateKey.currentState?.scrollController.animateTo(
                newOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          eventTileBuilder: (date, events, boundary, startDuration, endDuration) {
            return _buildHabitCard(date, events, boundary, startDuration, endDuration, theme);
          },
        );
    }
  }
}
