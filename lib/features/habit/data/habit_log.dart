import 'package:uuid/uuid.dart';

class HabitLog {
  final String id;
  final String habitId;
  final DateTime timestamp;
  final bool isDeleted;

  HabitLog({
    String? id,
    required this.habitId,
    DateTime? timestamp,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'],
      habitId: map['habit_id'],
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']).toLocal() : DateTime.now(),
      isDeleted: map['is_deleted'] == 1 || map['is_deleted'] == true,
    );
  }

  HabitLog copyWith({
    bool? isDeleted,
  }) {
    return HabitLog(
      id: id,
      habitId: habitId,
      timestamp: timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
