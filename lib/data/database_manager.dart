// lib/data/database_manager.dart
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  static Database? _database;
  static bool _isInitializing = false;
  static final ChangeNotifier databaseUpdateNotifier = ChangeNotifier();

  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  DatabaseManager._internal();

  factory DatabaseManager() => _instance;

  // ─── Method init untuk inisialisasi awal ───────────────────
  Future<void> init() async {
    debugPrint('🔵 DatabaseManager.init() dipanggil');
    await _initDatabase();
    debugPrint('✅ DatabaseManager.init() selesai');
  }

  // ─── Getter database dengan thread safety ───────────────────
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    return await _initDatabase();
  }

  // ─── Inisialisasi database ──────────────────────────────────
  Future<Database> _initDatabase() async {
    if (_isInitializing) {
      debugPrint('⏳ Database sedang diinisialisasi, menunggu...');
      int waitCount = 0;
      while (_isInitializing && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 50));
        waitCount++;
      }
      if (_database != null && _database!.isOpen) {
        debugPrint('✅ Database sudah siap setelah menunggu');
        return _database!;
      }
    }

    _isInitializing = true;
    debugPrint('🔵 Memulai inisialisasi database...');

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, 'food_detection.db');
      debugPrint('📂 Path database: $path');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );

      debugPrint('✅ Database berhasil dibuka (versi 1)');
      return _database!;
      
    } catch (e) {
      debugPrint('❌ ERROR inisialisasi database: $e');
      _database = null;
      rethrow;
    } finally {
      _isInitializing = false;
      debugPrint('🔵 Inisialisasi database selesai');
    }
  }

  // ─── Membuat semua tabel dari awal (versi 1) ────────────────
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📦 Membuat database versi $version dari awal...');
    
    try {
      // 1. Tabel corrections untuk koreksi KNN
      await db.execute('''
        CREATE TABLE corrections(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_hash TEXT UNIQUE,
          label TEXT NOT NULL,
          original_prediction TEXT,
          created_at INTEGER,
          updated_at INTEGER
        )
      ''');
      debugPrint('✅ Tabel corrections dibuat');

      // 2. Tabel user_profile
      await db.execute('''
        CREATE TABLE user_profile(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target_calories INTEGER DEFAULT 2000,
          target_protein REAL DEFAULT 50,
          target_carbs REAL DEFAULT 250,
          target_fat REAL DEFAULT 65,
          total_points INTEGER DEFAULT 0,
          badges TEXT DEFAULT '[]',
          created_at INTEGER,
          updated_at INTEGER
        )
      ''');
      debugPrint('✅ Tabel user_profile dibuat');

      // 3. Tabel scan_history
      await db.execute('''
        CREATE TABLE scan_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_path TEXT NOT NULL,
          label TEXT NOT NULL,
          indonesian_name TEXT NOT NULL,
          calories INTEGER NOT NULL,
          protein REAL NOT NULL,
          carbs REAL NOT NULL,
          fat REAL NOT NULL,
          fiber REAL DEFAULT 0,
          sugar REAL DEFAULT 0,
          sodium REAL DEFAULT 0,
          health_level TEXT,
          health_tip TEXT,
          warning TEXT,
          scanned_at INTEGER NOT NULL
        )
      ''');
      debugPrint('✅ Tabel scan_history dibuat');

      // 4. Tabel daily_progress
      await db.execute('''
        CREATE TABLE daily_progress(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT UNIQUE,
          total_calories INTEGER DEFAULT 0,
          total_protein REAL DEFAULT 0,
          total_carbs REAL DEFAULT 0,
          total_fat REAL DEFAULT 0,
          updated_at INTEGER
        )
      ''');
      debugPrint('✅ Tabel daily_progress dibuat');

      // 5. Tabel missions (master data misi dari JSON)
      await db.execute('''
        CREATE TABLE missions(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          mission_type TEXT NOT NULL,
          target_field TEXT NOT NULL,
          condition TEXT NOT NULL,
          condition_value REAL,
          target_count INTEGER NOT NULL,
          reward_points INTEGER NOT NULL,
          badge_name TEXT,
          difficulty TEXT NOT NULL,
          is_active INTEGER DEFAULT 1
        )
      ''');
      debugPrint('✅ Tabel missions dibuat');

      // 6. Tabel user_mission_progress (progress misi user)
      await db.execute('''
        CREATE TABLE user_mission_progress(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mission_id TEXT NOT NULL,
          current_value INTEGER DEFAULT 0,
          status TEXT DEFAULT 'in_progress',
          assigned_date TEXT NOT NULL,
          completed_date TEXT,
          claimed_date TEXT,
          FOREIGN KEY (mission_id) REFERENCES missions(id)
        )
      ''');
      debugPrint('✅ Tabel user_mission_progress dibuat');

      // 7. Tabel completed_missions_history (riwayat misi selesai)
      await db.execute('''
        CREATE TABLE completed_missions_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mission_id TEXT NOT NULL,
          completed_date TEXT NOT NULL,
          points_earned INTEGER NOT NULL
        )
      ''');
      debugPrint('✅ Tabel completed_missions_history dibuat');

      // 8. Tabel badges (lencana yang sudah dimiliki user)
      await db.execute('''
        CREATE TABLE user_badges(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          badge_name TEXT NOT NULL UNIQUE,
          earned_date TEXT NOT NULL
        )
      ''');
      debugPrint('✅ Tabel user_badges dibuat');

      // Index untuk performa query
      await db.execute('CREATE INDEX idx_corrections_hash ON corrections(image_hash)');
      await db.execute('CREATE INDEX idx_scan_history_date ON scan_history(scanned_at)');
      await db.execute('CREATE INDEX idx_mission_progress_mission ON user_mission_progress(mission_id)');
      await db.execute('CREATE INDEX idx_mission_progress_date ON user_mission_progress(assigned_date)');
      await db.execute('CREATE INDEX idx_mission_progress_status ON user_mission_progress(status)');
      debugPrint('✅ Index-index berhasil dibuat');

      debugPrint('⚠️ Tidak ada default user profile - onboarding akan muncul');

      debugPrint('🎉 Semua tabel berhasil dibuat!');
      
    } catch (e) {
      debugPrint('❌ ERROR saat membuat tabel: $e');
      rethrow;
    }
  }

  // ─── Helper untuk safe data conversion ─────────────────────
  Map<String, dynamic> _safeRow(Map<String, dynamic> row) {
    final safe = <String, dynamic>{};
    for (final entry in row.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value == null) {
        if (key == 'calories' || key == 'id' || key == 'scanned_at' || 
            key == 'target_calories' || key == 'total_points' || 
            key == 'current_value' || key == 'target_count' || 
            key == 'reward_points') {
          safe[key] = 0;
        } else if (key == 'protein' || key == 'carbs' || key == 'fat' || 
                   key == 'fiber' || key == 'sugar' || key == 'sodium' ||
                   key == 'target_protein' || key == 'target_carbs' || 
                   key == 'target_fat' || key == 'condition_value') {
          safe[key] = 0.0;
        } else {
          safe[key] = '';
        }
      } else {
        safe[key] = value;
      }
    }
    return safe;
  }

  List<Map<String, dynamic>> _safeRows(List<Map<String, dynamic>> rows) {
    return rows.map(_safeRow).toList();
  }

  // ─── 1. KNN Corrections ────────────────────────────────────
  
  String computeConsistentHash(List<int> imageBytes) {
    debugPrint('🔵 Menghitung hash untuk ${imageBytes.length} bytes');
    var hash = 0;
    for (int i = 0; i < imageBytes.length; i++) {
      hash = (hash * 31 + imageBytes[i]) & 0xFFFFFFFF;
    }
    final result = hash.toRadixString(16).padLeft(8, '0');
    debugPrint('✅ Hash: $result');
    return result;
  }

  Future<int> insertOrUpdateCorrection({
    required String imageHash,
    required String label,
    required String originalPrediction,
  }) async {
    debugPrint('🔵 insertOrUpdateCorrection: hash=$imageHash, label=$label');
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await findByHash(imageHash);

    if (existing != null) {
      final result = await db.update(
        'corrections',
        {
          'label': label,
          'original_prediction': originalPrediction,
          'updated_at': now
        },
        where: 'image_hash = ?',
        whereArgs: [imageHash],
      );
      debugPrint('✅ Correction diUPDATE: $imageHash → $label');
      return result;
    } else {
      final result = await db.insert(
        'corrections',
        {
          'image_hash': imageHash,
          'label': label,
          'original_prediction': originalPrediction,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Correction diINSERT: $imageHash → $label');
      return result;
    }
  }

  Future<Map<String, dynamic>?> findByHash(String imageHash) async {
    debugPrint('🔵 findByHash: $imageHash');
    try {
      final db = await database;
      final results = await db.query(
        'corrections',
        where: 'image_hash = ?',
        whereArgs: [imageHash],
      );
      if (results.isNotEmpty) {
        debugPrint('✅ Ditemukan correction untuk hash $imageHash');
        return _safeRow(results.first);
      }
      debugPrint('⚠️ Tidak ditemukan correction untuk hash $imageHash');
      return null;
    } catch (e) {
      debugPrint('❌ findByHash error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllCorrections() async {
    debugPrint('🔵 getAllCorrections');
    try {
      final db = await database;
      final rows = await db.query('corrections', orderBy: 'created_at DESC');
      debugPrint('✅ Mendapatkan ${rows.length} corrections');
      return _safeRows(rows);
    } catch (e) {
      debugPrint('❌ getAllCorrections error: $e');
      return [];
    }
  }

  Future<int> getCorrectionsCount() async {
    debugPrint('🔵 getCorrectionsCount');
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM corrections');
      final count = result.first['count'] as int? ?? 0;
      debugPrint('✅ Total corrections: $count');
      return count;
    } catch (e) {
      debugPrint('❌ getCorrectionsCount error: $e');
      return 0;
    }
  }

  Future<void> deleteAllCorrections() async {
    debugPrint('🔵 deleteAllCorrections');
    try {
      final db = await database;
      await db.delete('corrections');
      debugPrint('✅ Semua corrections dihapus');
    } catch (e) {
      debugPrint('❌ deleteAllCorrections error: $e');
    }
  }

  Future<void> deleteCorrectionByHash(String imageHash) async {
    debugPrint('🔵 deleteCorrectionByHash: $imageHash');
    try {
      final db = await database;
      await db.delete('corrections', where: 'image_hash = ?', whereArgs: [imageHash]);
      debugPrint('✅ Correction dihapus: $imageHash');
    } catch (e) {
      debugPrint('❌ deleteCorrectionByHash error: $e');
    }
  }

  // ─── 2. User Profile ───────────────────────────────────────

  Future<void> saveUserProfile({
    required String name,
    required int targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
  }) async {
    debugPrint('🔵 saveUserProfile: name=$name, calories=$targetCalories');
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await getUserProfile();

    try {
      if (existing != null) {
        await db.update(
          'user_profile',
          {
            'name': name,
            'target_calories': targetCalories,
            'target_protein': targetProtein,
            'target_carbs': targetCarbs,
            'target_fat': targetFat,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [existing['id']],
        );
        debugPrint('✅ User profile diUPDATE: $name');
      } else {
        await db.insert('user_profile', {
          'name': name,
          'target_calories': targetCalories,
          'target_protein': targetProtein,
          'target_carbs': targetCarbs,
          'target_fat': targetFat,
          'total_points': 0,
          'badges': '[]',
          'created_at': now,
          'updated_at': now,
        });
        debugPrint('✅ User profile diINSERT: $name');
      }
      await setOnboardingCompleted(true);
    } catch (e) {
      debugPrint('❌ saveUserProfile error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    debugPrint('🔵 getUserProfile');
    try {
      final db = await database;
      final results = await db.query('user_profile', limit: 1);
      if (results.isNotEmpty) {
        debugPrint('✅ User profile ditemukan');
        return _safeRow(results.first);
      }
      debugPrint('⚠️ User profile tidak ditemukan');
      return null;
    } catch (e) {
      debugPrint('❌ getUserProfile error: $e');
      return null;
    }
  }

  Future<bool> hasUserProfile() async {
    final profile = await getUserProfile();
    final has = profile != null;
    debugPrint('🔵 hasUserProfile: $has');
    return has;
  }

  // ─── User Points & Badges ──────────────────────────────────

  Future<void> addUserPoints(int points) async {
    debugPrint('🔵 addUserPoints: +$points points');
    try {
      final db = await database;
      final profile = await getUserProfile();
      if (profile != null) {
        final currentPoints = profile['total_points'] as int? ?? 0;
        final newPoints = currentPoints + points;
        await db.update(
          'user_profile',
          {'total_points': newPoints, 'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [profile['id']],
        );
        debugPrint('✅ Poin ditambahkan: $currentPoints → $newPoints');
      }
    } catch (e) {
      debugPrint('❌ addUserPoints error: $e');
    }
  }

  Future<int> getUserTotalPoints() async {
    debugPrint('🔵 getUserTotalPoints');
    try {
      final profile = await getUserProfile();
      final points = profile?['total_points'] as int? ?? 0;
      debugPrint('✅ Total poin user: $points');
      return points;
    } catch (e) {
      debugPrint('❌ getUserTotalPoints error: $e');
      return 0;
    }
  }

  Future<void> addUserBadge(String badgeName) async {
    debugPrint('🔵 addUserBadge: $badgeName');
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      
      final existing = await db.query(
        'user_badges',
        where: 'badge_name = ?',
        whereArgs: [badgeName],
      );
      
      if (existing.isEmpty) {
        await db.insert('user_badges', {
          'badge_name': badgeName,
          'earned_date': now,
        });
        debugPrint('✅ Lencana baru ditambahkan: $badgeName');
        
        final allBadges = await getUserBadges();
        final badgesJson = allBadges.map((b) => b['badge_name']).toList();
        final profile = await getUserProfile();
        if (profile != null) {
          await db.update(
            'user_profile',
            {'badges': badgesJson.toString()},
            where: 'id = ?',
            whereArgs: [profile['id']],
          );
        }
      } else {
        debugPrint('⚠️ Lencana $badgeName sudah dimiliki');
      }
    } catch (e) {
      debugPrint('❌ addUserBadge error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserBadges() async {
    debugPrint('🔵 getUserBadges');
    try {
      final db = await database;
      final results = await db.query('user_badges', orderBy: 'earned_date DESC');
      debugPrint('✅ Mendapatkan ${results.length} lencana');
      return results;
    } catch (e) {
      debugPrint('❌ getUserBadges error: $e');
      return [];
    }
  }

  // ─── 3. Scan History ───────────────────────────────────────

  Future<int> saveScanHistory({
    required String imagePath,
    required String label,
    required String indonesianName,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sugar,
    double? sodium,
    String? healthLevel,
    String? healthTip,
    String? warning,
  }) async {
    debugPrint('🔵 saveScanHistory: $indonesianName, ${calories}kcal');
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final id = await db.insert('scan_history', {
        'image_path': imagePath,
        'label': label,
        'indonesian_name': indonesianName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber ?? 0,
        'sugar': sugar ?? 0,
        'sodium': sodium ?? 0,
        'health_level': healthLevel,
        'health_tip': healthTip,
        'warning': warning,
        'scanned_at': now,
      });
      
      debugPrint('✅ Scan history tersimpan dengan id=$id');
      return id;
      
    } catch (e) {
      debugPrint('❌ saveScanHistory error: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllScanHistory() async {
    debugPrint('🔵 getAllScanHistory - mulai mengambil data...');
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> rows = await db.rawQuery('''
        SELECT 
          id, image_path, label, indonesian_name, 
          calories, protein, carbs, fat, 
          fiber, sugar, sodium, 
          health_level, health_tip, warning, 
          scanned_at
        FROM scan_history 
        ORDER BY scanned_at DESC
      ''');
      
      debugPrint('✅ getAllScanHistory - berhasil mengambil ${rows.length} record');
      
      if (rows.isEmpty) return [];
      
      final List<Map<String, dynamic>> safeRows = [];
      for (var row in rows) {
        try {
          final safeRow = <String, dynamic>{};
          for (final entry in row.entries) {
            final key = entry.key;
            final value = entry.value;
            
            if (value == null) {
              if (key == 'calories' || key == 'id' || key == 'scanned_at') {
                safeRow[key] = 0;
              } else if (key == 'protein' || key == 'carbs' || key == 'fat' || 
                        key == 'fiber' || key == 'sugar' || key == 'sodium') {
                safeRow[key] = 0.0;
              } else {
                safeRow[key] = '';
              }
            } else {
              safeRow[key] = value;
            }
          }
          safeRows.add(safeRow);
        } catch (e) {
          debugPrint('⚠️ Error converting row: $e');
          continue;
        }
      }
      
      return safeRows;
      
    } catch (e) {
      debugPrint('❌ getAllScanHistory error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getScanHistoryByDate(DateTime date) async {
    debugPrint('🔵 getScanHistoryByDate: $date');
    try {
      final db = await database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final rows = await db.query(
        'scan_history',
        where: 'scanned_at >= ? AND scanned_at < ?',
        whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
        orderBy: 'scanned_at DESC',
      );
      
      debugPrint('✅ Ditemukan ${rows.length} record untuk tanggal $date');
      
      // Debug print setiap scan
      for (var row in rows) {
        debugPrint('   - ${row['indonesian_name']}: protein=${row['protein']}, fiber=${row['fiber']}, sodium=${row['sodium']}');
      }
      
      return _safeRows(rows);
      
    } catch (e) {
      debugPrint('❌ getScanHistoryByDate error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getScanHistoryLastNDays(int days) async {
    debugPrint('🔵 getScanHistoryLastNDays: $days hari');
    try {
      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final cutoffMillis = cutoffDate.millisecondsSinceEpoch;
      
      final rows = await db.query(
        'scan_history',
        where: 'scanned_at >= ?',
        whereArgs: [cutoffMillis],
        orderBy: 'scanned_at DESC',
      );
      
      debugPrint('✅ Ditemukan ${rows.length} record dalam $days hari terakhir');
      return _safeRows(rows);
      
    } catch (e) {
      debugPrint('❌ getScanHistoryLastNDays error: $e');
      return [];
    }
  }

  Future<int> getTodayTotalCalories() async {
    debugPrint('🔵 getTodayTotalCalories');
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(calories), 0) as total FROM scan_history WHERE scanned_at >= ? AND scanned_at < ?',
        [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      );
      
      final total = (result.first['total'] as num?)?.toInt() ?? 0;
      debugPrint('✅ Total kalori hari ini: $total kcal');
      return total;
      
    } catch (e) {
      debugPrint('❌ getTodayTotalCalories error: $e');
      return 0;
    }
  }

  Future<Map<String, double>> getTodayNutritionSummary() async {
    debugPrint('🔵 getTodayNutritionSummary');
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final db = await database;
      final result = await db.rawQuery('''
        SELECT
          COALESCE(SUM(calories), 0) as total_calories,
          COALESCE(SUM(protein), 0) as total_protein,
          COALESCE(SUM(carbs), 0) as total_carbs,
          COALESCE(SUM(fat), 0) as total_fat
        FROM scan_history
        WHERE scanned_at >= ? AND scanned_at < ?
      ''', [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);

      final summary = {
        'total_calories': (result.first['total_calories'] as num?)?.toDouble() ?? 0,
        'total_protein': (result.first['total_protein'] as num?)?.toDouble() ?? 0,
        'total_carbs': (result.first['total_carbs'] as num?)?.toDouble() ?? 0,
        'total_fat': (result.first['total_fat'] as num?)?.toDouble() ?? 0,
      };
      
      debugPrint('✅ Ringkasan nutrisi hari ini: $summary');
      return summary;
      
    } catch (e) {
      debugPrint('❌ getTodayNutritionSummary error: $e');
      return {'total_calories': 0, 'total_protein': 0, 'total_carbs': 0, 'total_fat': 0};
    }
  }

  Future<void> deleteScanHistory(int id) async {
    debugPrint('🔵 deleteScanHistory: $id');
    try {
      final db = await database;
      await db.delete('scan_history', where: 'id = ?', whereArgs: [id]);
      debugPrint('✅ Scan history dengan id=$id dihapus');
    } catch (e) {
      debugPrint('❌ deleteScanHistory error: $e');
    }
  }

  Future<void> deleteAllScanHistory() async {
    debugPrint('🔵 deleteAllScanHistory');
    try {
      final db = await database;
      final count = await db.delete('scan_history');
      debugPrint('✅ Semua scan history dihapus ($count record)');
    } catch (e) {
      debugPrint('❌ deleteAllScanHistory error: $e');
    }
  }

  // ─── 4. Daily Progress ─────────────────────────────────────

  Future<void> updateDailyProgress({
    required String date,
    required int totalCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
  }) async {
    debugPrint('🔵 updateDailyProgress: $date, calories=$totalCalories');
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final existing = await getDailyProgress(date);

      if (existing != null) {
        await db.update(
          'daily_progress',
          {
            'total_calories': totalCalories,
            'total_protein': totalProtein,
            'total_carbs': totalCarbs,
            'total_fat': totalFat,
            'updated_at': now,
          },
          where: 'date = ?',
          whereArgs: [date],
        );
        debugPrint('✅ Daily progress diUPDATE untuk $date');
      } else {
        await db.insert('daily_progress', {
          'date': date,
          'total_calories': totalCalories,
          'total_protein': totalProtein,
          'total_carbs': totalCarbs,
          'total_fat': totalFat,
          'updated_at': now,
        });
        debugPrint('✅ Daily progress diINSERT untuk $date');
      }
    } catch (e) {
      debugPrint('❌ updateDailyProgress error: $e');
    }
  }

  Future<Map<String, dynamic>?> getDailyProgress(String date) async {
    debugPrint('🔵 getDailyProgress: $date');
    try {
      final db = await database;
      final results = await db.query(
        'daily_progress',
        where: 'date = ?',
        whereArgs: [date],
      );
      
      if (results.isNotEmpty) {
        debugPrint('✅ Daily progress ditemukan untuk $date');
        return _safeRow(results.first);
      }
      debugPrint('⚠️ Daily progress tidak ditemukan untuk $date');
      return null;
      
    } catch (e) {
      debugPrint('❌ getDailyProgress error: $e');
      return null;
    }
  }

  // ─── 5. Missions ───────────────────────────────────────────

  /// Insert atau update master mission (dari JSON)
  Future<void> insertOrUpdateMission(Map<String, dynamic> mission) async {
    debugPrint('🔵 insertOrUpdateMission: ${mission['id']}');
    try {
      final db = await database;
      
      await db.insert(
        'missions',
        {
          'id': mission['id'],
          'name': mission['name'],
          'description': mission['description'],
          'mission_type': mission['mission_type'],
          'target_field': mission['target_field'],
          'condition': mission['condition'],
          'condition_value': mission['condition_value'],
          'target_count': mission['target_count'],
          'reward_points': mission['reward_points'],
          'badge_name': mission['badge_name'],
          'difficulty': mission['difficulty'],
          'is_active': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Mission ${mission['id']} tersimpan');
    } catch (e) {
      debugPrint('❌ insertOrUpdateMission error: $e');
    }
  }

  /// Ambil semua mission yang aktif
  Future<List<Map<String, dynamic>>> getAllMissions() async {
    debugPrint('🔵 getAllMissions');
    try {
      final db = await database;
      final results = await db.query(
        'missions',
        where: 'is_active = 1',
        orderBy: 'difficulty, name',
      );
      debugPrint('✅ Mendapatkan ${results.length} missions');
      return results;
    } catch (e) {
      debugPrint('❌ getAllMissions error: $e');
      return [];
    }
  }

  /// Ambil mission berdasarkan ID
  Future<Map<String, dynamic>?> getMissionById(String missionId) async {
    debugPrint('🔵 getMissionById: $missionId');
    try {
      final db = await database;
      final results = await db.query(
        'missions',
        where: 'id = ?',
        whereArgs: [missionId],
      );
      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    } catch (e) {
      debugPrint('❌ getMissionById error: $e');
      return null;
    }
  }

  /// Ambil misi berdasarkan level difficulty
  Future<List<Map<String, dynamic>>> getMissionsByDifficulty(String difficulty) async {
    debugPrint('🔵 getMissionsByDifficulty: $difficulty');
    try {
      final db = await database;
      final results = await db.query(
        'missions',
        where: 'difficulty = ? AND is_active = 1',
        whereArgs: [difficulty],
      );
      debugPrint('✅ Mendapatkan ${results.length} missions dengan difficulty $difficulty');
      return results;
    } catch (e) {
      debugPrint('❌ getMissionsByDifficulty error: $e');
      return [];
    }
  }

  /// Ambil misi yang belum pernah diselesaikan dalam N hari terakhir
  Future<List<String>> getRecentCompletedMissionIds(int days) async {
    debugPrint('🔵 getRecentCompletedMissionIds: $days hari');
    try {
      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      
      final results = await db.query(
        'completed_missions_history',
        where: 'completed_date >= ?',
        whereArgs: [cutoffDate],
      );
      
      final missionIds = results.map((row) => row['mission_id'] as String).toList();
      debugPrint('✅ Misi yang selesai dalam $days hari: $missionIds');
      return missionIds;
    } catch (e) {
      debugPrint('❌ getRecentCompletedMissionIds error: $e');
      return [];
    }
  }

  /// Generate misi harian untuk user (reset setiap hari)
  Future<List<Map<String, dynamic>>> generateDailyMissions(String userId) async {
    debugPrint('🔵 generateDailyMissions untuk user: $userId');
    try {
      final db = await database;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      // Hapus misi lama untuk hari ini
      await db.delete(
        'user_mission_progress',
        where: 'assigned_date = ?',
        whereArgs: [today],
      );
      
      // Dapatkan level user berdasarkan total scan
      final userLevel = await getUserLevel();
      debugPrint('📊 User level: $userLevel');
      
      // Dapatkan misi yang baru diselesaikan (7 hari terakhir)
      final recentCompleted = await getRecentCompletedMissionIds(7);
      debugPrint('📋 Recent completed missions: $recentCompleted');
      
      String difficultyFilter;
      switch (userLevel) {
        case 'beginner':
          difficultyFilter = 'easy';
          break;
        case 'intermediate':
          difficultyFilter = 'easy,medium';
          break;
        default:
          difficultyFilter = 'easy,medium,hard';
      }
      
      final difficultyList = difficultyFilter.split(',').map((d) => "'$d'").join(',');
      final excludeIds = recentCompleted.isEmpty ? "''" : recentCompleted.map((id) => "'$id'").join(',');
      
      debugPrint('🎯 Difficulty filter: $difficultyList');
      debugPrint('🎯 Exclude IDs: $excludeIds');
      
      final allMissions = await db.query(
        'missions',
        where: 'difficulty IN ($difficultyList) AND is_active = 1 AND id NOT IN ($excludeIds)',
      );
      
      debugPrint('📋 Total misi yang memenuhi kriteria: ${allMissions.length}');
      
      if (allMissions.isEmpty) {
        debugPrint('⚠️ Tidak ada misi dengan filter, ambil semua misi aktif');
        final fallbackMissions = await db.query(
          'missions',
          where: 'is_active = 1',
          limit: 4,
        );
        return await _assignMissionsToUser(db, userId, today, fallbackMissions);
      }
      
      final shuffled = List<Map<String, dynamic>>.from(allMissions);
      shuffled.shuffle();
      final selectedMissions = shuffled.take(4).toList();
      
      return await _assignMissionsToUser(db, userId, today, selectedMissions);
      
    } catch (e) {
      debugPrint('❌ generateDailyMissions error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _assignMissionsToUser(
    Database db,
    String userId,
    String today,
    List<Map<String, dynamic>> missions,
  ) async {
    final assignedMissions = <Map<String, dynamic>>[];
    
    for (final mission in missions) {
      final id = await db.insert('user_mission_progress', {
        'mission_id': mission['id'],
        'current_value': 0,
        'status': 'in_progress',
        'assigned_date': today,
        'completed_date': null,
        'claimed_date': null,
      });
      
      assignedMissions.add({
        ...mission,
        'current_value': 0,
        'status': 'in_progress',
        'id': id,
      });
    }
    
    debugPrint('✅ ${assignedMissions.length} misi harian digenerate');
    return assignedMissions;
  }

  /// Dapatkan level user berdasarkan total scan
  Future<String> getUserLevel() async {
    try {
      final history = await getAllScanHistory();
      final totalScans = history.length;
      
      if (totalScans < 10) return 'beginner';
      if (totalScans < 30) return 'intermediate';
      return 'advanced';
    } catch (e) {
      debugPrint('❌ getUserLevel error: $e');
      return 'beginner';
    }
    }
    
  /// Dapatkan streak harian user berdasarkan PENYELESAIAN MISI (bukan scan)
  Future<int> getUserStreak() async {
    debugPrint('🔵 getUserStreak (from completed missions)');
    try {
      final completedMissions = await getCompletedMissionsHistory();
      if (completedMissions.isEmpty) {
        debugPrint('📋 No completed missions yet, streak = 0');
        return 0;
      }
      
      debugPrint('📋 Total completed missions: ${completedMissions.length}');
      
      // Debug: cetak semua completed missions dengan tanggalnya
      for (var mission in completedMissions) {
        debugPrint('   - Mission: ${mission['mission_id']}, completed: ${mission['completed_date']}');
      }
      
      // Kelompokkan berdasarkan tanggal (hanya ambil unique date)
      final Set<String> uniqueDates = {};
      for (var mission in completedMissions) {
        final completedDateStr = mission['completed_date'] as String;
        // Ambil hanya bagian tanggal (YYYY-MM-DD)
        final dateOnly = completedDateStr.length >= 10 
            ? completedDateStr.substring(0, 10) 
            : completedDateStr;
        uniqueDates.add(dateOnly);
        debugPrint('📅 Unique date added: $dateOnly');
      }
      
      debugPrint('📅 Unique dates with completed missions: $uniqueDates');
      
      // Hitung streak dari hari ini kebelakang
      int streak = 0;
      final today = DateTime.now();
      
      for (int i = 0; i < 30; i++) {
        final checkDate = today.subtract(Duration(days: i));
        final dateKey = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        
        debugPrint('🔍 Checking date: $dateKey, i=$i');
        
        if (uniqueDates.contains(dateKey)) {
          streak++;
          debugPrint('   ✅ Streak increased to $streak');
        } else {
          if (i == 0) {
            debugPrint('   ⚠️ No mission completed today yet, streak = 0');
            return 0;
          }
          debugPrint('   ❌ Streak broken at day $i');
          break;
        }
      }
      
      debugPrint('✅ Final user mission streak: $streak hari');
      return streak;
      
    } catch (e) {
      debugPrint('❌ getUserStreak error: $e');
      return 0;
    }
  }

  /// Ambil semua misi aktif user untuk hari ini
  Future<List<Map<String, dynamic>>> getTodayActiveMissions() async {
    debugPrint('🔵 getTodayActiveMissions');
    try {
      final db = await database;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      final results = await db.rawQuery('''
        SELECT 
          ump.*, 
          m.name, m.description, m.target_field, m.condition, 
          m.condition_value, m.target_count, m.reward_points, m.badge_name, m.difficulty
        FROM user_mission_progress ump
        JOIN missions m ON ump.mission_id = m.id
        WHERE ump.assigned_date = ? AND ump.status != 'claimed'
        ORDER BY 
          CASE ump.status
            WHEN 'completed' THEN 0
            ELSE 1
          END,
          ump.id
      ''', [today]);
      
      debugPrint('✅ Mendapatkan ${results.length} misi aktif hari ini');
      return results;
    } catch (e) {
      debugPrint('❌ getTodayActiveMissions error: $e');
      return [];
    }
  }

  /// Update progress misi berdasarkan scan
  Future<void> updateMissionProgress(Map<String, dynamic> newScanData) async {
    debugPrint('🔵🔵🔵 updateMissionProgress CALLED 🔵🔵🔵');
    debugPrint('📊 Scan data: ${newScanData['indonesian_name']}');
    
    try {
      final db = await database;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      // Ambil semua scan hari ini (termasuk yang baru)
      final todayScans = await getScanHistoryByDate(DateTime.now());
      final allTodayScans = [...todayScans, newScanData];
      
      // Hitung unique labels
      final uniqueLabels = allTodayScans.map((s) => s['label'] as String).toSet().toList();
      
      // Hitung total akumulasi
      double totalProtein = 0;
      double totalCalories = 0;
      for (final scan in allTodayScans) {
        totalProtein += (scan['protein'] as num?)?.toDouble() ?? 0;
        totalCalories += (scan['calories'] as num?)?.toInt() ?? 0;
      }
      
      // Cek apakah semua scan healthy
      bool allHealthy = allTodayScans.isNotEmpty;
      if (allHealthy) {
        for (final scan in allTodayScans) {
          final healthLevel = scan['health_level'] as String?;
          if (healthLevel != 'healthy') {
            allHealthy = false;
            break;
          }
        }
      }
      
      // Cek apakah semua scan low sodium
      bool allLowSodium = allTodayScans.isNotEmpty;
      if (allLowSodium) {
        for (final scan in allTodayScans) {
          final sodiumValue = scan['sodium'] as num?;
          if ((sodiumValue?.toInt() ?? 0) > 200) {
            allLowSodium = false;
            break;
          }
        }
      }
      
      // Ambil misi yang sedang in_progress hari ini
      final activeMissions = await db.query(
        'user_mission_progress',
        where: 'assigned_date = ? AND status = ?',
        whereArgs: [today, 'in_progress'],
      );
      
      debugPrint('📋 Active missions today: ${activeMissions.length}');
      
      for (final missionProgress in activeMissions) {
        final mission = await getMissionById(missionProgress['mission_id'] as String);
        if (mission == null) continue;
        
        final targetField = mission['target_field'] as String;
        final condition = mission['condition'] as String;
        final conditionValue = mission['condition_value'] as num?;
        final targetCount = mission['target_count'] as int;
        int currentValue = missionProgress['current_value'] as int? ?? 0;
        
        bool shouldIncrement = false;
        int newValue = currentValue;
        switch (targetField) {
          case 'fiber':
            final val = _safeToDouble(newScanData['fiber']);
            final target = _safeToDouble(conditionValue);
            shouldIncrement = _checkCondition(val, condition, target);
            if (shouldIncrement) newValue = currentValue + 1;
            break;
            
          case 'sodium':
            final val = _safeToDouble(newScanData['sodium']);
            final target = _safeToDouble(conditionValue);
            shouldIncrement = _checkCondition(val, condition, target);
            if (shouldIncrement) newValue = currentValue + 1;
            break;
            
          case 'protein':
            final val = _safeToDouble(newScanData['protein']);
            final target = _safeToDouble(conditionValue);
            shouldIncrement = _checkCondition(val, condition, target);
            if (shouldIncrement) newValue = currentValue + 1;
            break;
            
          case 'sugar':
            final val = _safeToDouble(newScanData['sugar']);
            final target = _safeToDouble(conditionValue);
            shouldIncrement = _checkCondition(val, condition, target);
            if (shouldIncrement) newValue = currentValue + 1;
            break;
            
          case 'calories':
            final val = _safeToDouble(newScanData['calories']);
            final target = _safeToDouble(conditionValue);
            shouldIncrement = _checkCondition(val, condition, target);
            if (shouldIncrement) newValue = currentValue + 1;
            break;
            
          case 'health_level':
            final healthLevel = _safeToString(newScanData['health_level']);
            final targetValue = _safeToString(conditionValue);
            shouldIncrement = _checkStringCondition(
              healthLevel,
              condition,
              targetValue,
            );
            if (shouldIncrement) newValue = currentValue + 1;
            break;
            
          case 'label':
            final label = _safeToString(newScanData['label']);
            final excludeWord = _safeToString(conditionValue);
            shouldIncrement = !label.contains(excludeWord);
            if (shouldIncrement) newValue = currentValue + 1;
            break;
            
          case 'protein_sum':
            if (condition == '>=' && totalProtein >= (conditionValue?.toDouble() ?? 0)) {
              newValue = 1;
              shouldIncrement = currentValue < 1;
            }
            break;
            
          case 'calories_sum':
            if (condition == '<=' && totalCalories <= (conditionValue?.toInt() ?? 0)) {
              newValue = 1;
              shouldIncrement = currentValue < 1;
            }
            break;
            
          case 'unique_labels':
            final targetUnique = conditionValue?.toInt() ?? 0;
            if (uniqueLabels.length >= targetUnique) {
              newValue = 1;
              shouldIncrement = currentValue < 1;
            }
            break;
            
          case 'scan_count':
            if (allTodayScans.length >= (conditionValue?.toInt() ?? 0)) {
              newValue = 1;
              shouldIncrement = currentValue < 1;
            }
            break;
            
          case 'all_healthy':
            if (allHealthy && allTodayScans.length >= targetCount) {
              newValue = 1;
              shouldIncrement = currentValue < 1;
            }
            break;
            
          case 'all_low_sodium':
            if (allLowSodium && allTodayScans.length >= targetCount) {
              newValue = 1;
              shouldIncrement = currentValue < 1;
            }
            break;
            
          case 'streak':
            final streak = await getUserStreak();
            if (streak >= (conditionValue?.toInt() ?? 0)) {
              newValue = 1;
              shouldIncrement = currentValue < 1;
            }
            break;
            
          case 'week_streak':
            final weekDays = await _getConsecutiveWeekDays();
            if (weekDays >= (conditionValue?.toInt() ?? 0)) {
              newValue = 1;
              shouldIncrement = currentValue < 1;
            }
            break;
            
          default:
            debugPrint('⚠️ Unknown target_field: $targetField');
            continue;
        }
        
        if (shouldIncrement && newValue > currentValue) {
          await db.update(
            'user_mission_progress',
            {'current_value': newValue},
            where: 'id = ?',
            whereArgs: [missionProgress['id']],
          );
          
          debugPrint('✅ Progress misi ${mission['name']}: $newValue/$targetCount');
          
          if (newValue >= targetCount) {
            await db.update(
              'user_mission_progress',
              {
                'status': 'completed',
                'completed_date': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [missionProgress['id']],
            );
            debugPrint('🎉 Misi ${mission['name']} SELESAI!');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ updateMissionProgress error: $e');
    }
  }

  /// Helper untuk menghitung hari berturut-turut dalam seminggu (Senin-Jumat)
  Future<int> _getConsecutiveWeekDays() async {
    final history = await getAllScanHistory();
    if (history.isEmpty) return 0;
    
    final scanDates = <String>{};
    for (final scan in history) {
      final date = DateTime.fromMillisecondsSinceEpoch(scan['scanned_at'] as int);
      if (date.weekday >= 1 && date.weekday <= 5) {
        final dateKey = '${date.year}-${date.month}-${date.day}';
        scanDates.add(dateKey);
      }
    }
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (int i = 0; i < 10; i++) {
      if (checkDate.weekday == 6 || checkDate.weekday == 7) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }
      
      final dateKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (scanDates.contains(dateKey)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  bool _checkCondition(double value, String condition, double target) {
    switch (condition) {
      case '>=': return value >= target;
      case '<=': return value <= target;
      case '>': return value > target;
      case '<': return value < target;
      case '==': return value == target;
      default: return false;
    }
  }

  bool _checkStringCondition(String value, String condition, String target) {
    switch (condition) {
      case '==': return value == target;
      case '!=': return value != target;
      default: return false;
    }
  }

  /// Klaim hadiah misi
  Future<bool> claimMissionReward(int missionProgressId) async {
    debugPrint('🔵 claimMissionReward: id=$missionProgressId');
    try {
      final db = await database;
      
      final progressResult = await db.query(
        'user_mission_progress',
        where: 'id = ?',
        whereArgs: [missionProgressId],
      );
      
      if (progressResult.isEmpty) return false;
      
      final progress = progressResult.first;
      if (progress['status'] != 'completed') {
        debugPrint('⚠️ Misi belum selesai atau sudah diklaim');
        return false;
      }
      
      if (progress['claimed_date'] != null) {
        debugPrint('⚠️ Misi sudah pernah diklaim');
        return false;
      }
      
      final mission = await getMissionById(progress['mission_id'] as String);
      if (mission == null) return false;
      
      final rewardPoints = mission['reward_points'] as int;
      final badgeName = mission['badge_name'] as String?;
      
      await db.update(
        'user_mission_progress',
        {
          'status': 'claimed',
          'claimed_date': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [missionProgressId],
      );
      
      await addUserPoints(rewardPoints);
      
      if (badgeName != null && badgeName.isNotEmpty) {
        await addUserBadge(badgeName);
      }
      
      await db.insert('completed_missions_history', {
        'mission_id': mission['id'],
        'completed_date': DateTime.now().toIso8601String(),
        'points_earned': rewardPoints,
      });
      
      debugPrint('✅ Hadiah misi diklaim: +$rewardPoints poin');
      return true;
      
    } catch (e) {
      debugPrint('❌ claimMissionReward error: $e');
      return false;
    }
  }

  /// Dapatkan statistik misi user
  Future<Map<String, dynamic>> getMissionStats() async {
    debugPrint('🔵 getMissionStats');
    try {
      final db = await database;
      
      final completedCount = await db.rawQuery('SELECT COUNT(*) as count FROM completed_missions_history');
      final totalCompleted = completedCount.first['count'] as int? ?? 0;
      
      final totalPoints = await getUserTotalPoints();
      final badges = await getUserBadges();
      
      return {
        'total_missions_completed': totalCompleted,
        'total_points': totalPoints,
        'badges_count': badges.length,
        'badges': badges,
      };
    } catch (e) {
      debugPrint('❌ getMissionStats error: $e');
      return {
        'total_missions_completed': 0,
        'total_points': 0,
        'badges_count': 0,
        'badges': [],
      };
    }
  }

  // ─── DEBUG Methods ─────────────────────────────────────────

  /// DEBUG: Cek semua misi di database
  Future<void> debugPrintAllMissions() async {
    debugPrint('🔍 ===== DEBUG ALL MISSIONS =====');
    final missions = await getAllMissions();
    debugPrint('📋 Total missions in DB: ${missions.length}');
    for (var mission in missions) {
      debugPrint('   - ${mission['id']}: ${mission['name']} (${mission['difficulty']}) - target_field: ${mission['target_field']}');
    }
    debugPrint('🔍 ===== END DEBUG MISSIONS =====');
  }

  /// DEBUG: Cek misi aktif hari ini
  Future<void> debugPrintTodayMissions() async {
    debugPrint('🔍 ===== DEBUG TODAY MISSIONS =====');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final db = await database;
    final results = await db.query(
      'user_mission_progress',
      where: 'assigned_date = ?',
      whereArgs: [today],
    );
    debugPrint('📋 Total missions for today: ${results.length}');
    for (var mission in results) {
      final missionDetail = await getMissionById(mission['mission_id'] as String);
      debugPrint('   - ${missionDetail?['name']}: status=${mission['status']}, current=${mission['current_value']}/${missionDetail?['target_count']}');
    }
    debugPrint('🔍 ===== END DEBUG TODAY MISSIONS =====');
  }

  // Di database_manager.dart, tambahkan method ini:

  /// Ambil semua riwayat misi yang sudah selesai
  Future<List<Map<String, dynamic>>> getCompletedMissionsHistory() async {
    debugPrint('🔵 getCompletedMissionsHistory');
    try {
      final db = await database;
      final results = await db.query(
        'completed_missions_history',
        orderBy: 'completed_date DESC',
      );
      debugPrint('✅ Mendapatkan ${results.length} completed missions');
      return results;
    } catch (e) {
      debugPrint('❌ getCompletedMissionsHistory error: $e');
      return [];
    }
  }

  // ─── Utility & Maintenance ─────────────────────────────────

  Future<void> resetAllData() async {
    debugPrint('🔵 resetAllData - mereset semua data...');
    try {
      final db = await database;
      await db.delete('corrections');
      await db.delete('scan_history');
      await db.delete('daily_progress');
      await db.delete('user_mission_progress');
      await db.delete('completed_missions_history');
      await db.delete('user_badges');
      
      final profile = await getUserProfile();
      if (profile != null) {
        await db.update(
          'user_profile',
          {
            'total_points': 0,
            'badges': '[]',
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [profile['id']],
        );
      }
      
      debugPrint('✅ Reset selesai');
    } catch (e) {
      debugPrint('❌ resetAllData error: $e');
    }
  }

  Future<void> resetAllDataComplete() async {
    debugPrint('🔵 resetAllDataComplete - mereset SEMUA data...');
    try {
      final db = await database;
      await db.delete('corrections');
      await db.delete('scan_history');
      await db.delete('daily_progress');
      await db.delete('user_profile');
      await db.delete('missions');
      await db.delete('user_mission_progress');
      await db.delete('completed_missions_history');
      await db.delete('user_badges');
      
      debugPrint('✅ Complete reset selesai');
    } catch (e) {
      debugPrint('❌ resetAllDataComplete error: $e');
    }
  }

  Future<void> close() async {
    debugPrint('🔵 close - menutup database...');
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
        debugPrint('✅ Database ditutup');
      }
    } catch (e) {
      debugPrint('⚠️ Error saat menutup database: $e');
    }
  }

  Future<bool> isDatabaseOpen() async {
    final isOpen = _database != null && _database!.isOpen;
    debugPrint('🔵 isDatabaseOpen: $isOpen');
    return isOpen;
  }

  Future<void> debugPrintAllScanHistory() async {
    debugPrint('🔵 ========== DEBUG SCAN HISTORY ==========');
    final history = await getAllScanHistory();
    for (int i = 0; i < history.length; i++) {
      final item = history[i];
      debugPrint('📋 [$i] id=${item['id']}, name=${item['indonesian_name']}, calories=${item['calories']}, date=${DateTime.fromMillisecondsSinceEpoch(item['scanned_at'] as int)}');
    }
    debugPrint('🔵 ========== END DEBUG ==========');
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    debugPrint('🔵 setOnboardingCompleted: $completed');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', completed);
      debugPrint('✅ Onboarding status saved');
    } catch (e) {
      debugPrint('❌ setOnboardingCompleted error: $e');
    }
  }

  Future<bool> isOnboardingCompleted() async {
    debugPrint('🔵 isOnboardingCompleted');
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('onboarding_completed') ?? false;
      debugPrint('✅ Onboarding completed: $completed');
      return completed;
    } catch (e) {
      debugPrint('❌ isOnboardingCompleted error: $e');
      return false;
    }
  }
}