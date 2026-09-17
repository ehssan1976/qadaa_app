import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ibadah_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE obligations (
        id INTEGER PRIMARY KEY,
        type TEXT NOT NULL,
        total_required INTEGER NOT NULL DEFAULT 0,
        completed_fajr INTEGER NOT NULL DEFAULT 0,
        completed_dhuhr INTEGER NOT NULL DEFAULT 0,
        completed_asr INTEGER NOT NULL DEFAULT 0,
        completed_maghrib INTEGER NOT NULL DEFAULT 0,
        completed_isha INTEGER NOT NULL DEFAULT 0,
        completed_fasting INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 1,
        timestamp TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE devotions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_count INTEGER DEFAULT 100,
        current_count INTEGER DEFAULT 0,
        is_dedicated INTEGER DEFAULT 1
      )
    ''');

    await db.rawInsert('''
      INSERT INTO obligations (id, type, total_required)
      VALUES (1, 'PRAYER', 0), (2, 'FASTING', 0)
    ''');
  }

  Future<Map<String, dynamic>?> getObligation(String type) async {
    final db = await instance.database;
    final results = await db.query(
      'obligations',
      where: 'type = ?',
      whereArgs: [type],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> setTotalDays(String type, int totalDays) async {
    final db = await instance.database;
    await db.update(
      'obligations',
      {'total_required': totalDays},
      where: 'type = ?',
      whereArgs: [type],
    );
  }

  Future<void> logPrayer(String prayerColumn, String actionName) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE obligations SET $prayerColumn = $prayerColumn + 1 WHERE id = 1',
      );
      await txn.insert('daily_logs', {
        'action_type': actionName,
        'count': 1,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> logFullDayPrayer() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.rawUpdate('''
        UPDATE obligations 
        SET completed_fajr = completed_fajr + 1,
            completed_dhuhr = completed_dhuhr + 1,
            completed_asr = completed_asr + 1,
            completed_maghrib = completed_maghrib + 1,
            completed_isha = completed_isha + 1
        WHERE id = 1
      ''');
      await txn.insert('daily_logs', {
        'action_type': 'FULL_DAY_PRAYER',
        'count': 1,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> logFastingDay() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE obligations SET completed_fasting = completed_fasting + 1 WHERE id = 2',
      );
      await txn.insert('daily_logs', {
        'action_type': 'FASTING',
        'count': 1,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<String> exportDatabaseToJson() async {
    final db = await instance.database;
    final obligations = await db.query('obligations');
    final dailyLogs = await db.query('daily_logs');
    final devotions = await db.query('devotions');

    final backupData = {
      'version': 1,
      'export_date': DateTime.now().toIso8601String(),
      'obligations': obligations,
      'daily_logs': dailyLogs,
      'devotions': devotions,
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  Future<File> createBackupFile() async {
    final jsonString = await exportDatabaseToJson();
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'ibadah_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${tempDir.path}/$fileName');
    return await file.writeAsString(jsonString);
  }

  Future<bool> restoreDatabaseFromJson(String jsonContent) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonContent);
      final db = await instance.database;

      await db.transaction((txn) async {
        await txn.delete('obligations');
        await txn.delete('daily_logs');
        await txn.delete('devotions');

        if (data['obligations'] != null) {
          for (var row in data['obligations']) {
            await txn.insert('obligations', Map<String, dynamic>.from(row));
          }
        }
        if (data['daily_logs'] != null) {
          for (var row in data['daily_logs']) {
            await txn.insert('daily_logs', Map<String, dynamic>.from(row));
          }
        }
        if (data['devotions'] != null) {
          for (var row in data['devotions']) {
            await txn.insert('devotions', Map<String, dynamic>.from(row));
          }
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
