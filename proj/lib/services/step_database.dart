import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local step history. Everything stays on the device — no account, no cloud.
class StepDatabase {
  Database? _db;

  Future<void> init() async {
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      join(dir, 'stride.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE days('
          'date TEXT PRIMARY KEY, '
          'steps INTEGER NOT NULL, '
          'calories REAL NOT NULL, '
          'distance REAL NOT NULL, '
          'duration INTEGER NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE hours('
          'date TEXT NOT NULL, '
          'hour INTEGER NOT NULL, '
          'steps INTEGER NOT NULL, '
          'PRIMARY KEY (date, hour))',
        );
      },
    );
  }

  Future<void> upsertDay(
      String date, int steps, double calories, double distanceKm, double durationMin) async {
    await _db!.insert(
      'days',
      {
        'date': date,
        'steps': steps,
        'calories': calories,
        'distance': distanceKm,
        'duration': durationMin.round(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertHour(String date, int hour, int steps) async {
    await _db!.insert(
      'hours',
      {'date': date, 'hour': hour, 'steps': steps},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> daysBetween(String start, String end) async {
    return _db!.query(
      'days',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start, end],
      orderBy: 'date ASC',
    );
  }

  Future<List<Map<String, Object?>>> hoursOf(String date) async {
    return _db!.query(
      'hours',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'hour ASC',
    );
  }
}
