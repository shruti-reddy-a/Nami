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
