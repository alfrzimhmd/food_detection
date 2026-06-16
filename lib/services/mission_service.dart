// lib/services/mission_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../data/database_manager.dart';

class MissionService {
  final DatabaseManager _db = DatabaseManager();

  /// Load misi dari JSON dan simpan ke database
  Future<void> loadMissionsFromJson() async {
    debugPrint('🔵 loadMissionsFromJson - mulai load misi dari JSON');
    
    try {
      // Baca file JSON dari assets
      final jsonString = await rootBundle.loadString('assets/data/missions.json');
      final jsonData = json.decode(jsonString);
      final missions = jsonData['missions'] as List<dynamic>;
      
      debugPrint('📦 Mendapatkan ${missions.length} misi dari JSON');
      
      // Simpan setiap misi ke database
      for (var mission in missions) {
        await _db.insertOrUpdateMission(mission as Map<String, dynamic>);
      }
      
      debugPrint('✅ Semua misi berhasil disimpan ke database');
      
    } catch (e) {
      debugPrint('❌ loadMissionsFromJson error: $e');
      rethrow;
    }
  }

  /// Generate misi harian untuk user
  Future<List<Map<String, dynamic>>> generateDailyMissions() async {
    debugPrint('🔵 generateDailyMissions - membuat misi harian baru');
    
    try {
      final missions = await _db.generateDailyMissions('default_user');
      debugPrint('✅ ${missions.length} misi harian berhasil dibuat');
      return missions;
      
    } catch (e) {
      debugPrint('❌ generateDailyMissions error: $e');
      return [];
    }
  }

  /// Cek dan reset misi harian jika perlu
  Future<void> checkAndResetDailyMissions() async {
    debugPrint('🔵 checkAndResetDailyMissions');
    
    try {
      final activeMissions = await _db.getTodayActiveMissions();
      
      // Jika tidak ada misi untuk hari ini, generate baru
      if (activeMissions.isEmpty) {
        debugPrint('⚠️ Tidak ada misi untuk hari ini, generating...');
        await generateDailyMissions();
      }
      
    } catch (e) {
      debugPrint('❌ checkAndResetDailyMissions error: $e');
    }
  }

  /// Update progress misi setelah scan
  // lib/services/mission_service.dart

  Future<void> updateMissionProgressAfterScan(Map<String, dynamic> scanData) async {
    debugPrint('🔴🔴🔴🔴🔴 MISSION SERVICE: updateMissionProgressAfterScan START 🔴🔴🔴🔴🔴');
    debugPrint('📊 scanData received:');
    debugPrint('   - name: ${scanData['indonesian_name']}');
    debugPrint('   - protein: ${scanData['protein']}');
    debugPrint('   - fiber: ${scanData['fiber']}');
    debugPrint('   - sodium: ${scanData['sodium']}');
    debugPrint('   - health_level: ${scanData['health_level']}');
    
    try {
      debugPrint('🔄 Calling _db.updateMissionProgress...');
      await _db.updateMissionProgress(scanData);
      debugPrint('✅ _db.updateMissionProgress completed successfully');
    } catch (e) {
      debugPrint('❌ _db.updateMissionProgress error: $e');
      debugPrint('📚 Stacktrace: ${StackTrace.current}');
    }
    
    debugPrint('🔴🔴🔴🔴🔴 MISSION SERVICE: updateMissionProgressAfterScan END 🔴🔴🔴🔴🔴');
  }

  /// Klaim hadiah misi
  Future<bool> claimMissionReward(int missionProgressId) async {
    debugPrint('🔵 claimMissionReward: $missionProgressId');
    
    try {
      final result = await _db.claimMissionReward(missionProgressId);
      debugPrint('✅ Klaim hadiah ${result ? "berhasil" : "gagal"}');
      return result;
      
    } catch (e) {
      debugPrint('❌ claimMissionReward error: $e');
      return false;
    }
  }

  /// Dapatkan semua misi aktif hari ini
  Future<List<Map<String, dynamic>>> getTodayActiveMissions() async {
    debugPrint('🔵 getTodayActiveMissions');
    
    try {
      final missions = await _db.getTodayActiveMissions();
      debugPrint('✅ Mendapatkan ${missions.length} misi aktif');
      return missions;
      
    } catch (e) {
      debugPrint('❌ getTodayActiveMissions error: $e');
      return [];
    }
  }

  /// Dapatkan statistik misi user
  Future<Map<String, dynamic>> getMissionStats() async {
    debugPrint('🔵 getMissionStats');
    
    try {
      final stats = await _db.getMissionStats();
      debugPrint('✅ Statistik misi: $stats');
      return stats;
      
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

  /// Dapatkan streak user
  Future<int> getUserStreak() async {
    debugPrint('🔵 getUserStreak from mission service');
    try {
      final streak = await _db.getUserStreak(); // 🔥 Pastikan ini memanggil method yang benar
      debugPrint('✅ User mission streak: $streak hari');
      return streak;
    } catch (e) {
      debugPrint('❌ getUserStreak error: $e');
      return 0;
    }
  }
}