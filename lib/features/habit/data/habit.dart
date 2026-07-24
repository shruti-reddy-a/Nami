import 'package:uuid/uuid.dart';
import 'package:nami/features/habit/data/habit_recurrence.dart';

class Habit {
  final String id;
  final String userId; 
  final String title;
  final String? timeOfDay; // null = Anytime, 'morning', 'afternoon', 'evening', or 'HH:mm'
  final HabitRecurrence recurrence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Habit({
    String? id,
    this.userId = '',
    required this.title,
    this.timeOfDay,
    required this.recurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'time_of_day': timeOfDay,
      'recurrence_json': recurrence.toJson(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      userId: map['user_id'] ?? '',
      title: map['title'],
      timeOfDay: map['time_of_day'],
      recurrence: HabitRecurrence.fromJson(map['recurrence_json']),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']).toLocal() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']).toLocal() : DateTime.now(),
      isDeleted: map['is_deleted'] == 1 || map['is_deleted'] == true,
    );
  }

  bool isScheduledOnDate(DateTime date) {
    final start = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final target = DateTime(date.year, date.month, date.day);
    
    if (target.isBefore(start)) return false;
    
    if (recurrence.endDate != null) {
      final end = DateTime(recurrence.endDate!.year, recurrence.endDate!.month, recurrence.endDate!.day);
      if (target.isAfter(end)) return false;
    }

    if (!_checkOccurs(start, target)) return false;

    if (recurrence.endOccurrences != null) {
      int count = 0;
      DateTime current = start;
      while (current.isBefore(target) || current.isAtSameMomentAs(target)) {
        if (_checkOccurs(start, current)) {
          count++;
        }
        if (count > recurrence.endOccurrences!) return false;
        current = current.add(const Duration(days: 1));
      }
    }
    
    return true;
  }

  bool _checkOccurs(DateTime start, DateTime d) {
    final freq = recurrence.frequency;
    final interval = recurrence.interval;
    
    if (freq == RecurrenceFrequency.daily) {
      final daysDiff = d.difference(start).inDays;
      return daysDiff % interval == 0;
    } else if (freq == RecurrenceFrequency.weekly) {
      final daysDiff = d.difference(start).inDays;
      final weeksDiff = daysDiff ~/ 7;
      return weeksDiff % interval == 0 && recurrence.daysOfWeek.contains(d.weekday);
    } else if (freq == RecurrenceFrequency.monthly) {
      final monthsDiff = (d.year - start.year) * 12 + d.month - start.month;
      return monthsDiff % interval == 0 && d.day == (recurrence.dayOfMonth ?? start.day);
    }
    return false;
  }

  Habit copyWith({
    String? title,
    String? timeOfDay,
    HabitRecurrence? recurrence,
    bool? isDeleted,
    String? userId,
  }) {
    return Habit(
      id: id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
