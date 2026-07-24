import 'package:nami/features/habit/data/habit.dart';
import 'package:nami/features/habit/data/habit_log.dart';
import 'package:nami/features/habit/data/habit_recurrence.dart';

class ConsistencyCalculator {
  static double getTargetForPeriod(Habit habit, int effectiveDays) {
    if (effectiveDays <= 0) return 0.0;
    final now = DateTime.now();
    final rec = habit.recurrence;
    
    if (rec.frequency == RecurrenceFrequency.daily) {
      return effectiveDays / rec.interval.toDouble();
    } else if (rec.frequency == RecurrenceFrequency.weekly) {
      if (rec.daysOfWeek.isNotEmpty) {
        int target = 0;
        for (int i = 0; i < effectiveDays; i++) {
          final dayToCheck = now.subtract(Duration(days: i));
          if (rec.daysOfWeek.contains(dayToCheck.weekday)) {
            target++;
          }
        }
        return target / rec.interval.toDouble();
      } else {
        return (effectiveDays / 7.0) / rec.interval.toDouble();
      }
    } else {
      if (rec.dayOfMonth != null) {
        int target = 0;
        for (int i = 0; i < effectiveDays; i++) {
          final dayToCheck = now.subtract(Duration(days: i));
          if (dayToCheck.day == rec.dayOfMonth) {
            target++;
          }
        }
        return target / rec.interval.toDouble();
      } else {
        return (effectiveDays / 30.0) / rec.interval.toDouble();
      }
    }
  }

  static double calculatePercentage(Habit habit, List<HabitLog> allLogs, int days) {
    final now = DateTime.now();
    final periodStart = now.subtract(Duration(days: days));
    
    // Check habit creation date to cap the denominator if newly created.
    final habitAgeDays = now.difference(habit.createdAt).inDays + 1; // +1 to include today
    final effectiveDays = habitAgeDays < days ? habitAgeDays : days;
    
    if (effectiveDays <= 0) return 0.0;
    
    final target = getTargetForPeriod(habit, effectiveDays);
    
    if (target <= 0) return 0.0;

    final logsInPeriod = allLogs.where((log) => 
      log.habitId == habit.id && 
      log.timestamp.isAfter(periodStart) && 
      !log.isDeleted
    ).length;

    final percentage = (logsInPeriod / target) * 100;
    return percentage > 100 ? 100.0 : percentage;
  }
}
