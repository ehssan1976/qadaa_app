import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  final Map<String, dynamic> _webPrayer = {
    'id': 1,
    'type': 'PRAYER',
    'total_required': 365,
    'completed_fajr': 0,
    'completed_dhuhr': 0,
    'completed_asr': 0,
    'completed_maghrib': 0,
    'completed_isha': 0,
    'completed_fasting': 0,
  };

  final Map<String, dynamic> _webFasting = {
    'id': 2,
    'type': 'FASTING',
    'total_required': 30,
    'completed_fajr': 0,
    'completed_dhuhr': 0,
    'completed_asr': 0,
    'completed_maghrib': 0,
    'completed_isha': 0,
    'completed_fasting': 0,
  };

  final List<Map<String, dynamic>> _webLogs = [];

  final List<Map<String, dynamic>> _webDebts = [];
  int _webDebtNextId = 1;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('qadaa.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await _ensureTablesExist(db);
      },
    );
  }

  final List<Map<String, dynamic>> _webWillAssets = [];
  Map<String, dynamic> _webWillInfo = {};
  int _webWillAssetNextId = 1;
  Map<String, dynamic>? _webUserProfile;
  Map<String, dynamic> _webKhumsInfo = {};
  final List<Map<String, dynamic>> _webKhumsRecords = [];
  int _webKhumsRecordNextId = 1;

  static Future<void> _ensureTablesExist(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_name TEXT NOT NULL,
        phone_number TEXT,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'د.ع',
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        due_date TEXT,
        notes TEXT,
        is_settled INTEGER DEFAULT 0,
        settled_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS will_info (
        id INTEGER PRIMARY KEY,
        testator_name TEXT,
        opening_preamble TEXT,
        executors TEXT,
        third_allocation TEXT,
        general_wishes TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS will_assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        estimated_value TEXT,
        location_or_details TEXT,
        beneficiary_notes TEXT,
        date_added TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        auth_method TEXT NOT NULL,
        gender TEXT,
        birth_date TEXT,
        country TEXT,
        city TEXT,
        profile_image TEXT,
        is_logged_in INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS khums_info (
        id INTEGER PRIMARY KEY,
        fiscal_year_date TEXT,
        notes TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS khums_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year_title TEXT NOT NULL,
        khums_date TEXT NOT NULL,
        taxed_capital REAL NOT NULL,
        assets_detail TEXT,
        currency TEXT DEFAULT 'د.ع',
        khums_paid REAL DEFAULT 0,
        notes TEXT,
        created_at TEXT
      )
    ''');

    try {
      await db.execute('ALTER TABLE user_profile ADD COLUMN profile_image TEXT;');
    } catch (_) {}
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

    await _ensureTablesExist(db);

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
    if (kIsWeb) {
      return type == 'PRAYER'
          ? Map<String, dynamic>.from(_webPrayer)
          : Map<String, dynamic>.from(_webFasting);
    }
    final db = await instance.database;
    if (db == null) return null;
    final res = await db.query(
      'obligations',
      where: 'type = ?',
      whereArgs: [type],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<void> logPrayer(String column, String actionName) async {
    if (kIsWeb) {
      _webPrayer[column] = (_webPrayer[column] as int? ?? 0) + 1;
      _webLogs.add({
        'type': 'PRAYER',
        'action': actionName,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return;
    }
    final db = await instance.database;
    if (db == null) return;
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
    if (kIsWeb) {
      final current = _webPrayer[column] as int? ?? 0;
      if (current > 0) {
        _webPrayer[column] = current - 1;
        _webLogs.add({
          'type': 'PRAYER',
          'action': 'DEC_$actionName',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      return;
    }
    final db = await instance.database;
    if (db == null) return;
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
    if (kIsWeb) {
      _webPrayer['completed_fajr'] = (_webPrayer['completed_fajr'] as int? ?? 0) + 1;
      _webPrayer['completed_dhuhr'] = (_webPrayer['completed_dhuhr'] as int? ?? 0) + 1;
      _webPrayer['completed_asr'] = (_webPrayer['completed_asr'] as int? ?? 0) + 1;
      _webPrayer['completed_maghrib'] = (_webPrayer['completed_maghrib'] as int? ?? 0) + 1;
      _webPrayer['completed_isha'] = (_webPrayer['completed_isha'] as int? ?? 0) + 1;
      _webLogs.add({
        'type': 'PRAYER',
        'action': 'FULL_DAY',
        'timestamp': DateTime.now().toIso8601String(),
      });
      return;
    }
    final db = await instance.database;
    if (db == null) return;
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
    if (kIsWeb) {
      _webFasting['completed_fasting'] = (_webFasting['completed_fasting'] as int? ?? 0) + 1;
      _webLogs.add({
        'type': 'FASTING',
        'action': 'FASTING_DAY',
        'timestamp': DateTime.now().toIso8601String(),
      });
      return;
    }
    final db = await instance.database;
    if (db == null) return;
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
    if (kIsWeb) {
      final current = _webFasting['completed_fasting'] as int? ?? 0;
      if (current > 0) {
        _webFasting['completed_fasting'] = current - 1;
        _webLogs.add({
          'type': 'FASTING',
          'action': 'DEC_FASTING_DAY',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      return;
    }
    final db = await instance.database;
    if (db == null) return;
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
    if (kIsWeb) {
      if (type == 'PRAYER') {
        _webPrayer['total_required'] = newTotal;
      } else {
        _webFasting['total_required'] = newTotal;
      }
      return;
    }
    final db = await instance.database;
    if (db == null) return;
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

  Future<Map<String, int>> getTodayActionCounts() async {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final Map<String, int> counts = {};

    if (kIsWeb) {
      for (final log in _webLogs) {
        final ts = log['timestamp'] as String? ?? '';
        if (ts.startsWith(todayStr)) {
          final act = log['action'] as String? ?? '';
          if (act == 'FULL_DAY') {
            for (final p in ['FAJR', 'DHUHR', 'ASR', 'MAGHRIB', 'ISHA']) {
              counts[p] = (counts[p] ?? 0) + 1;
            }
          } else if (!act.startsWith('DEC_')) {
            counts[act] = (counts[act] ?? 0) + 1;
          } else if (act.startsWith('DEC_')) {
            final targetAct = act.replaceFirst('DEC_', '');
            final current = counts[targetAct] ?? 0;
            if (current > 0) {
              counts[targetAct] = current - 1;
            }
          }
        }
      }
      return counts;
    }

    final db = await instance.database;
    if (db == null) return counts;

    final logs = await db.query(
      'logs',
      where: 'timestamp LIKE ?',
      whereArgs: ['$todayStr%'],
      orderBy: 'id ASC',
    );

    for (final log in logs) {
      final act = log['action'] as String? ?? '';
      if (act == 'FULL_DAY') {
        for (final p in ['FAJR', 'DHUHR', 'ASR', 'MAGHRIB', 'ISHA']) {
          counts[p] = (counts[p] ?? 0) + 1;
        }
      } else if (!act.startsWith('DEC_')) {
        counts[act] = (counts[act] ?? 0) + 1;
      } else if (act.startsWith('DEC_')) {
        final targetAct = act.replaceFirst('DEC_', '');
        final current = counts[targetAct] ?? 0;
        if (current > 0) {
          counts[targetAct] = current - 1;
        }
      }
    }

    return counts;
  }

  Future<Set<String>> getTodayCompletedActions() async {
    final counts = await getTodayActionCounts();
    return counts.entries.where((e) => e.value > 0).map((e) => e.key).toSet();
  }

  Future<File> createBackupFile() async {
    if (kIsWeb) {
      final backupData = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'obligations': [_webPrayer, _webFasting],
        'logs': _webLogs,
        'debts': _webDebts,
        'will_info': _webWillInfo,
        'will_assets': _webWillAssets,
        'khums_info': _webKhumsInfo,
        'khums_records': _webKhumsRecords,
      };
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/qadaa_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      return await file.writeAsString(jsonEncode(backupData));
    }

    final db = await instance.database;
    final obligations = await db?.query('obligations') ?? [];
    final logs = await db?.query('logs') ?? [];
    final debts = await db?.query('debts') ?? [];
    final willInfo = await db?.query('will_info') ?? [];
    final willAssets = await db?.query('will_assets') ?? [];
    final khumsInfo = await db?.query('khums_info') ?? [];
    final khumsRecords = await db?.query('khums_records') ?? [];

    final backupData = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'obligations': obligations,
      'logs': logs,
      'debts': debts,
      'will_info': willInfo,
      'will_assets': willAssets,
      'khums_info': khumsInfo,
      'khums_records': khumsRecords,
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
      final obligations = data['obligations'] as List<dynamic>?;
      final logs = data['logs'] as List<dynamic>?;
      final debts = data['debts'] as List<dynamic>?;
      final willInfo = data['will_info'];
      final willAssets = data['will_assets'] as List<dynamic>?;
      final khumsInfo = data['khums_info'];
      final khumsRecords = data['khums_records'] as List<dynamic>?;

      if (obligations == null) return false;

      if (kIsWeb) {
        for (final row in obligations) {
          final map = Map<String, dynamic>.from(row as Map);
          if (map['type'] == 'PRAYER') {
            _webPrayer.addAll(map);
          } else if (map['type'] == 'FASTING') {
            _webFasting.addAll(map);
          }
        }
        if (logs != null) {
          _webLogs.clear();
          for (final row in logs) {
            _webLogs.add(Map<String, dynamic>.from(row as Map));
          }
        }
        if (debts != null) {
          _webDebts.clear();
          for (final row in debts) {
            _webDebts.add(Map<String, dynamic>.from(row as Map));
          }
        }
        if (willInfo is Map) {
          _webWillInfo = Map<String, dynamic>.from(willInfo);
        } else if (willInfo is List && willInfo.isNotEmpty) {
          _webWillInfo = Map<String, dynamic>.from(willInfo.first as Map);
        }
        if (willAssets != null) {
          _webWillAssets.clear();
          for (final row in willAssets) {
            _webWillAssets.add(Map<String, dynamic>.from(row as Map));
          }
        }
        if (khumsInfo is Map) {
          _webKhumsInfo = Map<String, dynamic>.from(khumsInfo);
        } else if (khumsInfo is List && khumsInfo.isNotEmpty) {
          _webKhumsInfo = Map<String, dynamic>.from(khumsInfo.first as Map);
        }
        if (khumsRecords != null) {
          _webKhumsRecords.clear();
          for (final row in khumsRecords) {
            _webKhumsRecords.add(Map<String, dynamic>.from(row as Map));
          }
        }
        return true;
      }

      final db = await instance.database;
      if (db == null) return false;

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

        if (debts != null) {
          await txn.delete('debts');
          for (final row in debts) {
            await txn.insert('debts', Map<String, dynamic>.from(row as Map));
          }
        }

        if (willInfo != null) {
          await txn.delete('will_info');
          if (willInfo is List) {
            for (final row in willInfo) {
              await txn.insert('will_info', Map<String, dynamic>.from(row as Map));
            }
          } else if (willInfo is Map) {
            await txn.insert('will_info', Map<String, dynamic>.from(willInfo));
          }
        }

        if (willAssets != null) {
          await txn.delete('will_assets');
          for (final row in willAssets) {
            await txn.insert('will_assets', Map<String, dynamic>.from(row as Map));
          }
        }

        if (khumsInfo != null) {
          await txn.delete('khums_info');
          if (khumsInfo is List) {
            for (final row in khumsInfo) {
              await txn.insert('khums_info', Map<String, dynamic>.from(row as Map));
            }
          } else if (khumsInfo is Map) {
            await txn.insert('khums_info', Map<String, dynamic>.from(khumsInfo));
          }
        }

        if (khumsRecords != null) {
          await txn.delete('khums_records');
          for (final row in khumsRecords) {
            await txn.insert('khums_records', Map<String, dynamic>.from(row as Map));
          }
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  // ================= DEBTS OPERATIONS =================
  Future<List<Map<String, dynamic>>> getDebts() async {
    if (kIsWeb) {
      return List<Map<String, dynamic>>.from(_webDebts);
    }
    final db = await instance.database;
    if (db == null) return [];
    return await db.query('debts', orderBy: 'id DESC');
  }

  Future<int> insertDebt(Map<String, dynamic> debt) async {
    if (kIsWeb) {
      final newDebt = Map<String, dynamic>.from(debt);
      newDebt['id'] = _webDebtNextId++;
      _webDebts.add(newDebt);
      return newDebt['id'] as int;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.insert('debts', debt);
  }

  Future<int> updateDebt(int id, Map<String, dynamic> debt) async {
    if (kIsWeb) {
      final index = _webDebts.indexWhere((d) => d['id'] == id);
      if (index != -1) {
        _webDebts[index] = {...debt, 'id': id};
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.update('debts', debt, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDebt(int id) async {
    if (kIsWeb) {
      _webDebts.removeWhere((d) => d['id'] == id);
      return 1;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleDebtSettled(int id, bool isSettled) async {
    final settledDate = isSettled ? DateTime.now().toIso8601String().split('T').first : null;
    if (kIsWeb) {
      final index = _webDebts.indexWhere((d) => d['id'] == id);
      if (index != -1) {
        _webDebts[index]['is_settled'] = isSettled ? 1 : 0;
        _webDebts[index]['settled_date'] = settledDate;
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.update(
      'debts',
      {'is_settled': isSettled ? 1 : 0, 'settled_date': settledDate},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= WILL OPERATIONS =================
  Future<Map<String, dynamic>?> getWillInfo() async {
    if (kIsWeb) {
      return _webWillInfo.isNotEmpty ? Map<String, dynamic>.from(_webWillInfo) : null;
    }
    final db = await instance.database;
    if (db == null) return null;
    final res = await db.query('will_info', where: 'id = 1');
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<void> saveWillInfo(Map<String, dynamic> data) async {
    final infoData = {
      'id': 1,
      'testator_name': data['testator_name'],
      'opening_preamble': data['opening_preamble'],
      'executors': data['executors'],
      'third_allocation': data['third_allocation'],
      'general_wishes': data['general_wishes'],
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (kIsWeb) {
      _webWillInfo = Map<String, dynamic>.from(infoData);
      return;
    }
    final db = await instance.database;
    if (db == null) return;
    await db.insert('will_info', infoData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getWillAssets() async {
    if (kIsWeb) {
      return List<Map<String, dynamic>>.from(_webWillAssets);
    }
    final db = await instance.database;
    if (db == null) return [];
    return await db.query('will_assets', orderBy: 'id DESC');
  }

  Future<int> insertWillAsset(Map<String, dynamic> asset) async {
    if (kIsWeb) {
      final newAsset = Map<String, dynamic>.from(asset);
      newAsset['id'] = _webWillAssetNextId++;
      _webWillAssets.add(newAsset);
      return newAsset['id'] as int;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.insert('will_assets', asset);
  }

  Future<int> updateWillAsset(int id, Map<String, dynamic> asset) async {
    if (kIsWeb) {
      final index = _webWillAssets.indexWhere((a) => a['id'] == id);
      if (index != -1) {
        _webWillAssets[index] = {...asset, 'id': id};
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.update('will_assets', asset, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteWillAsset(int id) async {
    if (kIsWeb) {
      _webWillAssets.removeWhere((a) => a['id'] == id);
      return 1;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.delete('will_assets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveUserProfile(Map<String, dynamic> user) async {
    final data = {
      'name': user['name'] ?? '',
      'email': user['email'] ?? '',
      'phone': user['phone'] ?? '',
      'auth_method': user['auth_method'] ?? 'email',
      'gender': user['gender'] ?? 'ذكر',
      'birth_date': user['birth_date'] ?? '',
      'country': user['country'] ?? '',
      'city': user['city'] ?? '',
      'profile_image': user['profile_image'] ?? '',
      'is_logged_in': 1,
      'created_at': user['created_at'] ?? DateTime.now().toIso8601String(),
    };

    if (kIsWeb) {
      _webUserProfile = Map<String, dynamic>.from(data);
      _webUserProfile!['id'] = 1;
      return;
    }
    final db = await instance.database;
    if (db == null) return;
    await db.delete('user_profile');
    await db.insert('user_profile', data);
  }

  Future<void> updateUserProfileImage(String imagePath) async {
    if (kIsWeb) {
      if (_webUserProfile != null) {
        _webUserProfile!['profile_image'] = imagePath;
      }
      return;
    }
    final db = await instance.database;
    if (db == null) return;
    await db.update('user_profile', {'profile_image': imagePath}, where: 'is_logged_in = 1');
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (kIsWeb) {
      if (_webUserProfile != null && _webUserProfile!['is_logged_in'] == 1) {
        return Map<String, dynamic>.from(_webUserProfile!);
      }
      return null;
    }
    try {
      final db = await instance.database;
      if (db == null) return null;
      final res = await db.query('user_profile', where: 'is_logged_in = 1', limit: 1);
      if (res.isNotEmpty) {
        return res.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final profile = await getUserProfile();
    return profile != null;
  }

  Future<void> logoutUserProfile() async {
    if (kIsWeb) {
      _webUserProfile = null;
      return;
    }
    final db = await instance.database;
    if (db == null) return;
    await db.delete('user_profile');
  }

  // ================= KHUMS OPERATIONS =================
  Future<Map<String, dynamic>?> getKhumsInfo() async {
    if (kIsWeb) {
      return _webKhumsInfo.isNotEmpty ? Map<String, dynamic>.from(_webKhumsInfo) : null;
    }
    final db = await instance.database;
    if (db == null) return null;
    final res = await db.query('khums_info', where: 'id = 1');
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<void> saveKhumsInfo(Map<String, dynamic> data) async {
    final infoData = {
      'id': 1,
      'fiscal_year_date': data['fiscal_year_date'] ?? '',
      'notes': data['notes'] ?? '',
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (kIsWeb) {
      _webKhumsInfo = Map<String, dynamic>.from(infoData);
      return;
    }
    final db = await instance.database;
    if (db == null) return;
    await db.insert('khums_info', infoData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getKhumsRecords() async {
    if (kIsWeb) {
      return List<Map<String, dynamic>>.from(_webKhumsRecords);
    }
    final db = await instance.database;
    if (db == null) return [];
    return await db.query('khums_records', orderBy: 'id DESC');
  }

  Future<int> insertKhumsRecord(Map<String, dynamic> record) async {
    if (kIsWeb) {
      final newRec = Map<String, dynamic>.from(record);
      newRec['id'] = _webKhumsRecordNextId++;
      _webKhumsRecords.insert(0, newRec);
      return newRec['id'] as int;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.insert('khums_records', record);
  }

  Future<int> updateKhumsRecord(int id, Map<String, dynamic> record) async {
    if (kIsWeb) {
      final index = _webKhumsRecords.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        _webKhumsRecords[index] = {...record, 'id': id};
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.update('khums_records', record, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteKhumsRecord(int id) async {
    if (kIsWeb) {
      _webKhumsRecords.removeWhere((r) => r['id'] == id);
      return 1;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.delete('khums_records', where: 'id = ?', whereArgs: [id]);
  }
}
