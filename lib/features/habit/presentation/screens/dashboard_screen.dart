import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nami/core/utils/string_extensions.dart';
import 'package:nami/features/habit/presentation/utils/habit_ui_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nami/core/constants/app_strings.dart';
import 'package:nami/features/habit/data/habit.dart';
import 'package:nami/features/habit/presentation/screens/add_edit_habit_screen.dart';
import 'package:nami/core/presentation/widgets/common_app_bar_actions.dart';
import 'package:nami/features/habit/providers/habit_provider.dart';
import 'package:nami/features/profile/providers/profile_provider.dart';
import 'dart:math';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getRandomQuote() {
    const quotes = [
      "Small disciplines repeated with consistency every day lead to great achievements.",
      "Success is the product of daily habits—not once-in-a-lifetime transformations.",
      "You do not rise to the level of your goals. You fall to the level of your systems.",
      "Motivation is what gets you started. Habit is what keeps you going."
    ];
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return quotes[Random(seed).nextInt(quotes.length)];
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allHabits = ref.watch(habitProvider);
    final logs = ref.watch(habitLogProvider);
    final profile = ref.watch(userProfileProvider).value;
    
    String userName = profile?.displayName ?? '';
    if (userName.trim().isEmpty) {
      userName = 'there';
    } else {
      userName = userName.split(' ').first;
    }

    final today = DateTime.now();
    final todayHabits = allHabits.where((h) => !h.isDeleted && h.isScheduledOnDate(today)).toList();

    // Grouping
    final morning = <Habit>[];
    final afternoon = <Habit>[];
    final evening = <Habit>[];
    final night = <Habit>[];
    final anytime = <Habit>[];

    for (final h in todayHabits) {
      final hour = _getHourForHabit(h);
      if (hour == -1) {
        anytime.add(h);
      } else if (hour >= 5 && hour < 12) {
        morning.add(h);
      } else if (hour >= 12 && hour < 17) {
        afternoon.add(h);
      } else if (hour >= 17 && hour < 21) {
        evening.add(h);
      } else {
        night.add(h);
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(AppStrings.appName, style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary, letterSpacing: 1)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [CommonAppBarActions()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Greeting
                  Text(
                    '${_getGreeting()}, $userName',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Motivational Quote Box
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _getRandomQuote(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 12,
                        child: Icon(Icons.format_quote, color: theme.colorScheme.primary.withValues(alpha: 0.2), size: 40),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 12,
                        child: RotatedBox(
                          quarterTurns: 2,
                          child: Icon(Icons.format_quote, color: theme.colorScheme.primary.withValues(alpha: 0.2), size: 40),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text(
              "Today in a Glimpse",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (todayHabits.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.waves, size: 48, color: theme.colorScheme.primaryContainer),
                      const SizedBox(height: 16),
                      Text("You have no habits scheduled for today.", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditHabitScreen())),
                        child: const Text(AppStrings.createFirstHabit),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildTimeSection(context, ref, "Morning", Icons.wb_twilight, morning, logs, theme),
              _buildTimeSection(context, ref, "Afternoon", Icons.wb_sunny, afternoon, logs, theme),
              _buildTimeSection(context, ref, "Evening", Icons.nights_stay, evening, logs, theme),
              _buildTimeSection(context, ref, "Night", Icons.bedtime, night, logs, theme),
              _buildTimeSection(context, ref, "Anytime", Icons.all_inclusive, anytime, logs, theme),
            ]
          ],
        ),
      ),
    )));
  }

  Widget _buildTimeSection(BuildContext context, WidgetRef ref, String title, IconData icon, List<Habit> habits, List<dynamic> logs, ThemeData theme) {
    if (habits.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...habits.map((h) => _buildHabitTile(context, ref, h, logs, theme)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHabitTile(BuildContext context, WidgetRef ref, Habit habit, List<dynamic> logs, ThemeData theme) {
    final now = DateTime.now();
    final logList = logs.where((l) => l.habitId == habit.id && !l.isDeleted && l.timestamp.year == now.year && l.timestamp.month == now.month && l.timestamp.day == now.day).toList();
    final isLogged = logList.isNotEmpty;
    final isMissed = HabitUIHelper.isMissed(habit, isLogged);
    
    final habitIcon = HabitUIHelper.getIconForHabit(habit.title);
    final habitColor = HabitUIHelper.getColorForHabit(habit.title);
    final frequencyText = HabitUIHelper.getFrequencyText(habit);

    return Opacity(
      opacity: isMissed ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          elevation: isLogged ? 0 : 3,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.15),
          color: isLogged 
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) 
              : (theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surfaceContainerHigh),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isLogged ? Colors.transparent : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLogged ? theme.colorScheme.surfaceContainerHighest : habitColor,
                shape: BoxShape.circle,
              ),
              child: Icon(habitIcon, color: isLogged ? theme.colorScheme.onSurfaceVariant : Colors.black87, size: 20),
            ),
            title: Text(
              habit.title.capitalizeAllWords(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: isLogged ? TextDecoration.lineThrough : null,
                color: isLogged ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              isMissed ? 'Missed' : frequencyText,
              style: TextStyle(
                fontSize: 12,
                color: isMissed ? Colors.redAccent.withValues(alpha: 0.8) : theme.colorScheme.onSurfaceVariant,
                fontStyle: isMissed ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            trailing: isMissed 
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('—', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 18, fontWeight: FontWeight.bold)),
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      if (!isLogged) {
                        ref.read(habitLogProvider.notifier).logHabit(habit.id);
                      } else {
                        ref.read(habitLogProvider.notifier).removeLog(logList.first.id);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isLogged ? const Color(0xFF00696F) : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: isLogged ? null : Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: Icon(
                        isLogged ? Icons.check : Icons.add,
                        color: isLogged ? Colors.white : theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
