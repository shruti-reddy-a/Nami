import 'package:nami/features/habit/data/habit_log.dart';
import 'package:nami/features/habit/data/habit.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nami/core/services/firebase_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

class HabitNotifier extends Notifier<List<Habit>> {
  StreamSubscription? _subscription;

  @override
  List<Habit> build() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToHabits();
      } else {
        _subscription?.cancel();
        state = [];
      }
    });
    return [];
  }

  void _subscribeToHabits() {
    final service = ref.read(firebaseServiceProvider);
    _subscription?.cancel();
    _subscription = service.getHabitsStream().listen((habits) {
      state = habits;
    });
  }

  Future<void> addHabit(Habit habit) async {
    final service = ref.read(firebaseServiceProvider);
    await service.insertHabit(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    final service = ref.read(firebaseServiceProvider);
    await service.updateHabit(habit);
  }

  Future<void> deleteHabit(String id) async {
    final service = ref.read(firebaseServiceProvider);
    await service.deleteHabit(id);
  }
}

final habitProvider = NotifierProvider<HabitNotifier, List<Habit>>(() => HabitNotifier());

class HabitLogNotifier extends Notifier<List<HabitLog>> {
  StreamSubscription? _subscription;

  @override
  List<HabitLog> build() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToLogs();
      } else {
        _subscription?.cancel();
        state = [];
      }
    });
    return [];
  }

  void _subscribeToLogs() {
    final service = ref.read(firebaseServiceProvider);
    _subscription?.cancel();
    _subscription = service.getHabitLogsStream().listen((logs) {
      state = logs;
    });
  }

  Future<void> logHabit(String habitId) async {
    final service = ref.read(firebaseServiceProvider);
    final log = HabitLog(habitId: habitId);
    await service.insertHabitLog(log);
  }

  Future<void> removeLog(String logId) async {
    final service = ref.read(firebaseServiceProvider);
    await service.deleteHabitLog(logId);
  }
}

final habitLogProvider = NotifierProvider<HabitLogNotifier, List<HabitLog>>(() => HabitLogNotifier());
