import 'local_database_service.dart';
import 'supabase_service.dart';

class SyncService {
  final LocalDatabaseService localDb;
  final SupabaseService remoteDb;

  SyncService({required this.localDb, required this.remoteDb});

  /// Push local changes to Supabase
  Future<void> syncUp() async {
    if (!remoteDb.isInitialized) return;
    
    try {
      final habits = await localDb.getHabits();
      final logs = await localDb.getAllHabitLogs();

      await remoteDb.upsertHabits(habits.map((h) => h.toMap()).toList());
      await remoteDb.upsertHabitLogs(logs.map((l) => l.toMap()).toList());
    } catch (e) {
      // Handle network or sync errors gracefully (fail silently or log)
      // For production, use a logging framework
    }
  }

  /// Pull changes from Supabase to local
  Future<void> syncDown() async {
    if (!remoteDb.isInitialized) return;
    // Implement pull logic here when needed
  }
}
