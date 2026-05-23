import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  static Database? _database;
  static bool _isInitialized = false;  // ← Tambahkan flag

  DatabaseManager._internal();

  factory DatabaseManager() => _instance;

  Future<Database> get database async {
    // Cek apakah database valid dan terbuka
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    await init();
    return _database!;
  }

  Future<void> init() async {
    // Cek apakah sudah terinisialisasi dan database terbuka
    if (_isInitialized && _database != null && _database!.isOpen) {
      return;
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, 'food_detection.db');

      _database = await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      _isInitialized = true;
      debugPrint('DatabaseManager initialized at: $path');
    } catch (e) {
      debugPrint('DatabaseManager init error: $e');
      rethrow;
    }
  }

  // ============================================================
  // MEMBUAT SEMUA TABEL SAAT PERTAMA KALI
  // ============================================================
  
  Future<void> _onCreate(Database db, int version) async {
    // Tabel 1: KNN Corrections (untuk pembelajaran model)
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
    
    // Tabel 2: User Profile (target nutrisi user)
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
    
    // Tabel 3: Scan History (riwayat deteksi makanan)
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
        fiber REAL,
        sugar REAL,
        sodium REAL,
        health_level TEXT,
        health_tip TEXT,
        warning TEXT,
        scanned_at INTEGER NOT NULL
      )
    ''');
    
    // Tabel 4: Daily Progress (ringkasan harian, opsional)
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
    
    // Membuat index untuk mempercepat query
    await db.execute('CREATE INDEX IF NOT EXISTS idx_corrections_hash ON corrections(image_hash)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_scan_history_date ON scan_history(scanned_at)');
    
    debugPrint('All tables created successfully');
  }

  // Upgrade database jika ada perubahan struktur
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Upgrade untuk menambah kolom updated_at di corrections
      try {
        await db.execute('ALTER TABLE corrections ADD COLUMN updated_at INTEGER');
        debugPrint('Added updated_at column to corrections');
      } catch (e) {
        debugPrint('Upgrade error: $e');
      }
    }
    
    if (oldVersion < 3) {
      // Upgrade untuk menambah tabel baru
      // Tabel user_profile
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile(
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
      
      // Tabel scan_history
      await db.execute('''
        CREATE TABLE IF NOT EXISTS scan_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_path TEXT NOT NULL,
          label TEXT NOT NULL,
          indonesian_name TEXT NOT NULL,
          calories INTEGER NOT NULL,
          protein REAL NOT NULL,
          carbs REAL NOT NULL,
          fat REAL NOT NULL,
          fiber REAL,
          sugar REAL,
          sodium REAL,
          health_level TEXT,
          health_tip TEXT,
          warning TEXT,
          scanned_at INTEGER NOT NULL
        )
      ''');
      
      // Tabel daily_progress
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_progress(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT UNIQUE,
          total_calories INTEGER DEFAULT 0,
          total_protein REAL DEFAULT 0,
          total_carbs REAL DEFAULT 0,
          total_fat REAL DEFAULT 0,
          updated_at INTEGER
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_scan_history_date ON scan_history(scanned_at)');
      debugPrint('Tables created during upgrade');
    }
  }

  // ============================================================
  // 1. KNN CORRECTIONS (untuk pembelajaran model)
  // ============================================================

  // Compute hash konsisten
  String computeConsistentHash(List<int> imageBytes) {
    var hash = 0;
    for (int i = 0; i < imageBytes.length; i++) {
      hash = (hash * 31 + imageBytes[i]) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  // Insert or Update correction
  Future<int> insertOrUpdateCorrection({
    required String imageHash,
    required String label,
    required String originalPrediction,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final existing = await findByHash(imageHash);
    
    if (existing != null) {
      final result = await db.update(
        'corrections',
        {
          'label': label,
          'original_prediction': originalPrediction,
          'updated_at': now,
        },
        where: 'image_hash = ?',
        whereArgs: [imageHash],
      );
      debugPrint('Updated correction: $imageHash → $label');
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
      debugPrint('Inserted correction: $imageHash → $label');
      return result;
    }
  }

  // Find correction by hash
  Future<Map<String, dynamic>?> findByHash(String imageHash) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'corrections',
        where: 'image_hash = ?',
        whereArgs: [imageHash],
      );
      if (results.isNotEmpty) return results.first;
      return null;
    } catch (e) {
      debugPrint('findByHash error: $e');
      return null;
    }
  }

  // Get all corrections
  Future<List<Map<String, dynamic>>> getAllCorrections() async {
    final db = await database;
    return await db.query('corrections', orderBy: 'created_at DESC');
  }

  // Get corrections count
  Future<int> getCorrectionsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM corrections');
      return result.first['count'] as int;
    } catch (e) {
      debugPrint('getCorrectionsCount error: $e');
      return 0;
    }
  }

  // Delete all corrections
  Future<void> deleteAllCorrections() async {
    final db = await database;
    await db.delete('corrections');
    debugPrint('All corrections deleted');
  }

  // Delete correction by hash
  Future<void> deleteCorrectionByHash(String imageHash) async {
    final db = await database;
    await db.delete('corrections', where: 'image_hash = ?', whereArgs: [imageHash]);
    debugPrint('Deleted correction: $imageHash');
  }

  // ============================================================
  // 2. USER PROFILE (target nutrisi)
  // ============================================================

  Future<void> saveUserProfile({
    required String name,
    required int targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Cek apakah sudah ada profile
    final existing = await getUserProfile();
    
    try {
      if (existing != null) {
        // Update
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
        debugPrint('User profile updated: $name');
      } else {
        // Insert
        await db.insert(
          'user_profile',
          {
            'name': name,
            'target_calories': targetCalories,
            'target_protein': targetProtein,
            'target_carbs': targetCarbs,
            'target_fat': targetFat,
            'created_at': now,
            'updated_at': now,
          },
        );
        debugPrint('User profile created: $name');
      }
      
      // Set onboarding completed setelah save sukses
      await setOnboardingCompleted(true);
      
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query('user_profile');
      if (results.isNotEmpty) return results.first;
      return null;
    } catch (e) {
      debugPrint('getUserProfile error: $e');
      return null;
    }
  }

  // Check if user has profile
  Future<bool> hasUserProfile() async {
    final profile = await getUserProfile();
    return profile != null;
  }

  // ============================================================
  // 3. SCAN HISTORY (riwayat deteksi)
  // ============================================================

  // Save scan result to history
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
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (!db.isOpen) {
        debugPrint('Database is closed, reinitializing...');
        await init();
        return await saveScanHistory(
          imagePath: imagePath,
          label: label,
          indonesianName: indonesianName,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          fiber: fiber,
          sugar: sugar,
          sodium: sodium,
          healthLevel: healthLevel,
          healthTip: healthTip,
          warning: warning,
        );
      }
      
      return await db.insert(
        'scan_history',
        {
          'image_path': imagePath,
          'label': label,
          'indonesian_name': indonesianName,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
          'fiber': fiber,
          'sugar': sugar,
          'sodium': sodium,
          'health_level': healthLevel,
          'health_tip': healthTip,
          'warning': warning,
          'scanned_at': now,
        },
      );
    } catch (e) {
      debugPrint('saveScanHistory error: $e');
      return -1;
    }
  }

  // Get all scan history (latest first)
  Future<List<Map<String, dynamic>>> getAllScanHistory() async {
    try {
      final db = await database;
      
      if (!db.isOpen) {
        debugPrint('Database is closed, reinitializing...');
        await init();
        return getAllScanHistory();
      }
      
      return await db.query(
        'scan_history',
        orderBy: 'scanned_at DESC',
      );
    } catch (e) {
      debugPrint('getAllScanHistory error: $e');
      return [];
    }
  }

  // Get scan history by date
  Future<List<Map<String, dynamic>>> getScanHistoryByDate(DateTime date) async {
    try {
      final db = await database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return await db.query(
        'scan_history',
        where: 'scanned_at >= ? AND scanned_at < ?',
        whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
        orderBy: 'scanned_at DESC',
      );
    } catch (e) {
      debugPrint('getScanHistoryByDate error: $e');
      return [];
    }
  }

  // Get today's total calories
  Future<int> getTodayTotalCalories() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final db = await database;
      
      if (!db.isOpen) {
        debugPrint('Database is closed, reinitializing...');
        await init();
        return getTodayTotalCalories();
      }
      
      final result = await db.rawQuery('''
        SELECT SUM(calories) as total FROM scan_history
        WHERE scanned_at >= ? AND scanned_at < ?
      ''', [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);
      
      return result.first['total'] as int? ?? 0;
    } catch (e) {
      debugPrint('getTodayTotalCalories error: $e');
      return 0;
    }
  }

  // Get today's nutrition summary
  Future<Map<String, double>> getTodayNutritionSummary() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final db = await database;
      
      // Cek apakah database terbuka
      if (!db.isOpen) {
        debugPrint('Database is closed, reinitializing...');
        await init();
        return getTodayNutritionSummary(); // Retry
      }
      
      final result = await db.rawQuery('''
        SELECT 
          SUM(calories) as total_calories,
          SUM(protein) as total_protein,
          SUM(carbs) as total_carbs,
          SUM(fat) as total_fat
        FROM scan_history
        WHERE scanned_at >= ? AND scanned_at < ?
      ''', [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);
      
      return {
        'total_calories': (result.first['total_calories'] as num?)?.toDouble() ?? 0,
        'total_protein': (result.first['total_protein'] as num?)?.toDouble() ?? 0,
        'total_carbs': (result.first['total_carbs'] as num?)?.toDouble() ?? 0,
        'total_fat': (result.first['total_fat'] as num?)?.toDouble() ?? 0,
      };
    } catch (e) {
      debugPrint('getTodayNutritionSummary error: $e');
      // Return default values instead of crashing
      return {
        'total_calories': 0,
        'total_protein': 0,
        'total_carbs': 0,
        'total_fat': 0,
      };
    }
  }

  // Delete scan history by id
  Future<void> deleteScanHistory(int id) async {
    final db = await database;
    await db.delete('scan_history', where: 'id = ?', whereArgs: [id]);
    debugPrint('Scan history deleted: $id');
  }

  // Delete all scan history
  Future<void> deleteAllScanHistory() async {
    final db = await database;
    await db.delete('scan_history');
    debugPrint('All scan history deleted');
  }

  // ============================================================
  // 4. DAILY PROGRESS (ringkasan harian)
  // ============================================================

  // Update or create daily progress
  Future<void> updateDailyProgress({
    required String date,
    required int totalCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
  }) async {
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
    } else {
      await db.insert(
        'daily_progress',
        {
          'date': date,
          'total_calories': totalCalories,
          'total_protein': totalProtein,
          'total_carbs': totalCarbs,
          'total_fat': totalFat,
          'updated_at': now,
        },
      );
    }
  }

  // Get daily progress by date
  Future<Map<String, dynamic>?> getDailyProgress(String date) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'daily_progress',
        where: 'date = ?',
        whereArgs: [date],
      );
      if (results.isNotEmpty) return results.first;
      return null;
    } catch (e) {
      debugPrint('getDailyProgress error: $e');
      return null;
    }
  }

  // ============================================================
  // UTILITY
  // ============================================================

  // Reset all data (untuk debugging)
  Future<void> resetAllData() async {
    await deleteAllCorrections();
    await deleteAllScanHistory();
    debugPrint('All data reset');
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Untuk menyimpan status onboarding
  Future<void> setOnboardingCompleted(bool completed) async {
    // Gunakan SharedPreferences untuk flag sederhana
    // Atau bisa juga simpan di tabel user_profile
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', completed);
  }

  // Untuk mengecek apakah onboarding sudah selesai
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

}