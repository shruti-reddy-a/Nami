import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class LocalDatabaseService {
  static const String dbName = 'nami_local.db';
  static const int dbVersion = 4; // Incremented for schema change

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT,
        time_of_day TEXT,
        recurrence_json TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_deleted INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_logs (
        id TEXT PRIMARY KEY,
        habit_id TEXT,
        timestamp TEXT,
        is_deleted INTEGER,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS habit_logs');
    await db.execute('DROP TABLE IF EXISTS habits');
    await _onCreate(db, newVersion);
  }

  // Habits
  Future<void> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final maps = await db.query('habits', where: 'is_deleted = ?', whereArgs: [0]);
    return maps.map((e) => Habit.fromMap(e)).toList();
  }

  Future<void> deleteHabit(String id) async {
    final db = await database;
    await db.update('habits', {'is_deleted': 1, 'updated_at': DateTime.now().toUtc().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
  }

  // Habit Logs
  Future<void> insertHabitLog(HabitLog log) async {
    final db = await database;
    await db.insert('habit_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HabitLog>> getHabitLogs(String habitId) async {
    final db = await database;
    final maps = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND is_deleted = ?',
      whereArgs: [habitId, 0],
      orderBy: 'timestamp DESC',
    );
    return maps.map((e) => HabitLog.fromMap(e)).toList();
  }

  Future<List<HabitLog>> getAllHabitLogs() async {
    final db = await database;
    final maps = await db.query(
      'habit_logs',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
    return maps.map((e) => HabitLog.fromMap(e)).toList();
  }

  Future<void> deleteHabitLog(String id) async {
    final db = await database;
    await db.update('habit_logs', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
