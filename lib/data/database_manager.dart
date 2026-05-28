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
    // Cegah inisialisasi ganda
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

      // Buka database (tanpa PRAGMA yang bermasalah)
      _database = await openDatabase(
        path,
        version: 1, // Versi 1, tanpa upgrade complexity
        onCreate: _onCreate,
        // Tidak ada onUpgrade karena kita selalu fresh install
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
          created_at INTEGER,
          updated_at INTEGER
        )
      ''');
      debugPrint('✅ Tabel user_profile dibuat');

      // 3. Tabel scan_history (semua kolom lengkap)
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

      // Index untuk performa query
      await db.execute('CREATE INDEX idx_corrections_hash ON corrections(image_hash)');
      await db.execute('CREATE INDEX idx_scan_history_date ON scan_history(scanned_at)');
      debugPrint('✅ Index-index berhasil dibuat');

      // // Insert default user profile
      // final now = DateTime.now().millisecondsSinceEpoch;
      // await db.insert('user_profile', {
      //   'name': 'Pengguna',
      //   'target_calories': 2000,
      //   'target_protein': 50,
      //   'target_carbs': 250,
      //   'target_fat': 65,
      //   'created_at': now,
      //   'updated_at': now,
      // });
      // debugPrint('✅ Default user_profile ditambahkan');

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
        // Default values berdasarkan tipe data
        if (key == 'calories' || key == 'id' || key == 'scanned_at' || 
            key == 'target_calories') {
          safe[key] = 0;
        } else if (key == 'protein' || key == 'carbs' || key == 'fat' || 
                   key == 'fiber' || key == 'sugar' || key == 'sodium' ||
                   key == 'target_protein' || key == 'target_carbs' || key == 'target_fat') {
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

  // ─── 3. Scan History (Method paling penting) ───────────────

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
      
      // 🔥 Gunakan rawQuery untuk performa lebih baik
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
      
      // 🔥 Konversi manual dengan error handling
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
      return _safeRows(rows);
      
    } catch (e) {
      debugPrint('❌ getScanHistoryByDate error: $e');
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

  // ─── Utility & Maintenance ─────────────────────────────────

  /// Reset semua data (tanpa menghapus user profile)
  Future<void> resetAllData() async {
    debugPrint('🔵 resetAllData - mereset semua data...');
    try {
      final db = await database;
      final correctionsCount = await db.delete('corrections');
      final scanCount = await db.delete('scan_history');
      final progressCount = await db.delete('daily_progress');
      
      debugPrint('✅ Reset selesai - corrections: $correctionsCount, scan: $scanCount, progress: $progressCount');
    } catch (e) {
      debugPrint('❌ resetAllData error: $e');
    }
  }

  /// Reset total (termasuk user profile) - untuk fresh start
  Future<void> resetAllDataComplete() async {
    debugPrint('🔵 resetAllDataComplete - mereset SEMUA data...');
    try {
      final db = await database;
      await db.delete('corrections');
      await db.delete('scan_history');
      await db.delete('daily_progress');
      await db.delete('user_profile');
      
      // Insert default profile
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('user_profile', {
        'name': 'Pengguna',
        'target_calories': 2000,
        'target_protein': 50,
        'target_carbs': 250,
        'target_fat': 65,
        'created_at': now,
        'updated_at': now,
      });
      
      debugPrint('✅ Complete reset selesai, user profile default dibuat');
    } catch (e) {
      debugPrint('❌ resetAllDataComplete error: $e');
    }
  }

  /// Tutup koneksi database
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

  /// Cek apakah database terbuka
  Future<bool> isDatabaseOpen() async {
    final isOpen = _database != null && _database!.isOpen;
    debugPrint('🔵 isDatabaseOpen: $isOpen');
    return isOpen;
  }

  /// Debug: Cetak semua data scan history
  Future<void> debugPrintAllScanHistory() async {
    debugPrint('🔵 ========== DEBUG SCAN HISTORY ==========');
    final history = await getAllScanHistory();
    for (int i = 0; i < history.length; i++) {
      final item = history[i];
      debugPrint('📋 [$i] id=${item['id']}, name=${item['indonesian_name']}, calories=${item['calories']}, date=${DateTime.fromMillisecondsSinceEpoch(item['scanned_at'] as int)}');
    }
    debugPrint('🔵 ========== END DEBUG ==========');
  }

  // ─── Onboarding Status ─────────────────────────────────────

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