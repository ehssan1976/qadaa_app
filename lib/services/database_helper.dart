import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('qadaa.db');
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
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        total_required INTEGER NOT NULL,
        completed_fajr INTEGER DEFAULT 0,
        completed_dhuhr INTEGER DEFAULT 0,
        completed_asr INTEGER DEFAULT 0,
        completed_maghrib INTEGER DEFAULT 0,
        completed_isha INTEGER DEFAULT 0,
        completed_fasting INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.insert('obligations', {
      'type': 'PRAYER',
      'total_required': 365,
      'completed_fajr': 0,
      'completed_dhuhr': 0,
      'completed_asr': 0,
      'completed_maghrib': 0,
      'completed_isha': 0,
      'completed_fasting': 0,
    });

    await db.insert('obligations', {
      'type': 'FASTING',
      'total_required': 30,
      'completed_fajr': 0,
      'completed_dhuhr': 0,
      'completed_asr': 0,
      'completed_maghrib': 0,
      'completed_isha': 0,
      'completed_fasting': 0,
    });
  }

  Future<Map<String, dynamic>?> getObligation(String type) async {
    final db = await instance.database;
    final res = await db.query(
      'obligations',
      where: 'type = ?',
      whereArgs: [type],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<void> logPrayer(String column, String actionName) async {
    final db = await instance.database;
    await db.rawUpdate(
      'UPDATE obligations SET $column = $column + 1 WHERE type = ?',
      ['PRAYER'],
    );
    await db.insert('logs', {
      'type': 'PRAYER',
      'action': actionName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> decrementPrayer(String column, String actionName) async {
    final db = await instance.database;
    final current = await getObligation('PRAYER');
    if (current != null && (current[column] ?? 0) > 0) {
      await db.rawUpdate(
        'UPDATE obligations SET $column = $column - 1 WHERE type = ?',
        ['PRAYER'],
      );
      await db.insert('logs', {
        'type': 'PRAYER',
        'action': 'DEC_$actionName',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> logFullDayPrayer() async {
    final db = await instance.database;
    await db.rawUpdate(
      '''
      UPDATE obligations 
      SET completed_fajr = completed_fajr + 1,
          completed_dhuhr = completed_dhuhr + 1,
          completed_asr = completed_asr + 1,
          completed_maghrib = completed_maghrib + 1,
          completed_isha = completed_isha + 1
      WHERE type = ?
    ''',
      ['PRAYER'],
    );
    await db.insert('logs', {
      'type': 'PRAYER',
      'action': 'FULL_DAY',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logFastingDay() async {
    final db = await instance.database;
    await db.rawUpdate(
      'UPDATE obligations SET completed_fasting = completed_fasting + 1 WHERE type = ?',
      ['FASTING'],
    );
    await db.insert('logs', {
      'type': 'FASTING',
      'action': 'FASTING_DAY',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> decrementFastingDay() async {
    final db = await instance.database;
    final current = await getObligation('FASTING');
    if (current != null && (current['completed_fasting'] ?? 0) > 0) {
      await db.rawUpdate(
        'UPDATE obligations SET completed_fasting = completed_fasting - 1 WHERE type = ?',
        ['FASTING'],
      );
      await db.insert('logs', {
        'type': 'FASTING',
        'action': 'DEC_FASTING_DAY',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> updateTotalRequired(String type, int newTotal) async {
    final db = await instance.database;
    await db.update(
      'obligations',
      {'total_required': newTotal},
      where: 'type = ?',
      whereArgs: [type],
    );
  }

  Future<void> setTotalDays(String type, int totalDays) async {
    await updateTotalRequired(type, totalDays);
  }

  Future<File> createBackupFile() async {
    final db = await instance.database;
    final obligations = await db.query('obligations');
    final logs = await db.query('logs');

    final backupData = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'obligations': obligations,
      'logs': logs,
    };

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/qadaa_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    return await file.writeAsString(jsonEncode(backupData));
  }

  Future<bool> restoreDatabaseFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final db = await instance.database;

      final obligations = data['obligations'] as List<dynamic>?;
      final logs = data['logs'] as List<dynamic>?;

      if (obligations == null) return false;

      await db.transaction((txn) async {
        await txn.delete('obligations');
        for (final row in obligations) {
          await txn.insert(
            'obligations',
            Map<String, dynamic>.from(row as Map),
          );
        }

        if (logs != null) {
          await txn.delete('logs');
          for (final row in logs) {
            await txn.insert('logs', Map<String, dynamic>.from(row as Map));
          }
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}
