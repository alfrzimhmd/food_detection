import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SimpleCorrectionDatabase {
  static final SimpleCorrectionDatabase _instance = SimpleCorrectionDatabase._internal();
  static Database? _database;

  SimpleCorrectionDatabase._internal();

  factory SimpleCorrectionDatabase() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await init();
    return _database!;
  }

  Future<void> init() async {
    if (_database != null) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, 'corrections.db');

      _database = await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      debugPrint('Database initialized at: $path');
    } catch (e) {
      debugPrint('Database init error: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('CREATE INDEX IF NOT EXISTS idx_hash ON corrections(image_hash)');
    debugPrint('Database tables created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE corrections ADD COLUMN updated_at INTEGER');
        debugPrint('Database upgraded to version $newVersion');
      } catch (e) {
        debugPrint('Upgrade error (maybe column exists): $e');
      }
    }
  }

  // Compute hash konsisten
  String computeConsistentHash(List<int> imageBytes) {
    var hash = 0;
    for (int i = 0; i < imageBytes.length; i++) {
      hash = (hash * 31 + imageBytes[i]) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  // Insert or Update
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
      debugPrint('Updated: $imageHash → $label');
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
      debugPrint('Inserted: $imageHash → $label');
      return result;
    }
  }

  // Find by hash
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

  // Get all
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await database;
    return await db.query('corrections', orderBy: 'created_at DESC');
  }

  // Get count
  Future<int> getCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM corrections');
      return result.first['count'] as int;
    } catch (e) {
      debugPrint('getCount error: $e');
      return 0;
    }
  }

  // Delete all
  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('corrections');
    debugPrint('All corrections deleted');
  }

  // Delete by hash
  Future<void> deleteByHash(String imageHash) async {
    final db = await database;
    await db.delete('corrections', where: 'image_hash = ?', whereArgs: [imageHash]);
    debugPrint('Deleted: $imageHash');
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}