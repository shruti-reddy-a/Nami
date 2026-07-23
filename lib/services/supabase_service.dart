import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseClient? _client;

  SupabaseClient get client {
    try {
      _client ??= Supabase.instance.client;
      return _client!;
    } catch (e) {
      // If Supabase is not initialized (e.g. no URL/Key provided), throw or handle
      throw Exception('Supabase not initialized');
    }
  }

  bool get isInitialized {
    try {
      final _ = Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get isAuthenticated => isInitialized && client.auth.currentSession != null;
  String? get currentUserId => isInitialized ? client.auth.currentUser?.id : null;

  Future<void> signInAnonymously() async {
    if (!isInitialized) return;
    await client.auth.signInAnonymously();
  }

  // Habit Sync Methods
  Future<void> upsertHabits(List<Map<String, dynamic>> habits) async {
    if (!isInitialized || habits.isEmpty) return;
    await client.from('habits').upsert(habits);
  }

  Future<void> upsertHabitLogs(List<Map<String, dynamic>> logs) async {
    if (!isInitialized || logs.isEmpty) return;
    await client.from('habit_logs').upsert(logs);
  }
}
