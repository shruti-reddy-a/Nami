import 'dart:convert';

enum RecurrenceFrequency { daily, weekly, monthly }

class HabitRecurrence {
  final RecurrenceFrequency frequency;
  final int interval; // e.g. 1 = every week, 2 = every 2 weeks
  final List<int> daysOfWeek; // 1 = Mon, ..., 7 = Sun (for weekly)
  final int? dayOfMonth; // 1-31 (for monthly)
  final DateTime? endDate; // null = never ends
  final int? endOccurrences; // null = never ends

  HabitRecurrence({
    this.frequency = RecurrenceFrequency.daily,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.dayOfMonth,
    this.endDate,
    this.endOccurrences,
  });

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'endDate': endDate?.toIso8601String(),
      'endOccurrences': endOccurrences,
    };
  }

  factory HabitRecurrence.fromMap(Map<String, dynamic> map) {
    return HabitRecurrence(
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurrenceFrequency.daily,
      ),
      interval: map['interval'] ?? 1,
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? []),
      dayOfMonth: map['dayOfMonth'],
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      endOccurrences: map['endOccurrences'],
    );
  }

  String toJson() => json.encode(toMap());

  factory HabitRecurrence.fromJson(String source) =>
      HabitRecurrence.fromMap(json.decode(source));

  // Helper to generate human readable string
  String toReadableString() {
    String base = '';
    if (frequency == RecurrenceFrequency.daily) {
      base = interval == 1 ? 'Daily' : 'Every $interval days';
    } else if (frequency == RecurrenceFrequency.weekly) {
      final days = daysOfWeek.map((d) => _dayName(d)).join(', ');
      final prefix = interval == 1 ? 'Weekly' : 'Every $interval weeks';
      if (daysOfWeek.length == 7) {
        base = interval == 1 ? 'Daily' : 'Every $interval weeks every day';
      } else if (daysOfWeek.length == 5 && daysOfWeek.every((d) => d <= 5)) {
        base = 'Every weekday';
      } else {
        base = daysOfWeek.isEmpty ? prefix : '$prefix on $days';
      }
    } else {
      final prefix = interval == 1 ? 'Monthly' : 'Every $interval months';
      base = dayOfMonth != null ? '$prefix on day $dayOfMonth' : prefix;
    }

    if (endDate != null) {
      base += ' until ${endDate!.month}/${endDate!.day}/${endDate!.year}';
    } else if (endOccurrences != null) {
      base += ' for $endOccurrences times';
    }
    return base;
  }

  String _dayName(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}
