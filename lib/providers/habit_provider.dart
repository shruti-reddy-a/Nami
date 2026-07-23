import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/local_database_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';

final localDbProvider = Provider((ref) => LocalDatabaseService());
final supabaseServiceProvider = Provider((ref) => SupabaseService());

final syncServiceProvider = Provider((ref) {
  final local = ref.read(localDbProvider);
  final remote = ref.read(supabaseServiceProvider);
  return SyncService(localDb: local, remoteDb: remote);
});

class HabitNotifier extends Notifier<List<Habit>> {
  @override
  List<Habit> build() {
    _loadHabits();
    return [];
  }

  Future<void> _loadHabits() async {
    final localDb = ref.read(localDbProvider);
    state = await localDb.getHabits();
  }

  Future<void> addHabit(Habit habit) async {
    final localDb = ref.read(localDbProvider);
    await localDb.insertHabit(habit);
    await _loadHabits();
    ref.read(syncServiceProvider).syncUp();
  }

  Future<void> updateHabit(Habit habit) async {
    final localDb = ref.read(localDbProvider);
    await localDb.updateHabit(habit);
    await _loadHabits();
    ref.read(syncServiceProvider).syncUp();
  }

  Future<void> deleteHabit(String id) async {
    final localDb = ref.read(localDbProvider);
    await localDb.deleteHabit(id);
    await _loadHabits();
    ref.read(syncServiceProvider).syncUp();
  }
}

final habitProvider = NotifierProvider<HabitNotifier, List<Habit>>(() => HabitNotifier());

class HabitLogNotifier extends Notifier<List<HabitLog>> {
  @override
  List<HabitLog> build() {
    _loadLogs();
    return [];
  }

  Future<void> _loadLogs() async {
    final localDb = ref.read(localDbProvider);
    state = await localDb.getAllHabitLogs();
  }

  Future<void> logHabit(String habitId) async {
    final localDb = ref.read(localDbProvider);
    final log = HabitLog(habitId: habitId);
    await localDb.insertHabitLog(log);
    await _loadLogs();
    ref.read(syncServiceProvider).syncUp();
  }
}

final habitLogProvider = NotifierProvider<HabitLogNotifier, List<HabitLog>>(() => HabitLogNotifier());
