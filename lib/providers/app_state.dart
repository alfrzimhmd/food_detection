// lib/providers/app_state.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../data/database_manager.dart';
import '../data/nutrition_data.dart';
import '../services/mission_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseManager _dbManager = DatabaseManager();
  late final MissionService _missionService;
  
  // State variables
  bool _isLoading = false;
  bool _isOnboarded = false;
  Map<String, dynamic>? _userProfile;
  Map<String, double> _todayNutrition = {};
  int _todayCalories = 0;
  List<Map<String, dynamic>> _scanHistory = [];
  List<Map<String, dynamic>> _recentHistory = [];
  
  // 🎯 Mission state variables
  List<Map<String, dynamic>> _dailyMissions = [];
  Map<String, dynamic> _missionStats = {};
  int _userStreak = 0;
  bool _isMissionLoading = false;
  
  // 🔥 Flag untuk mencegah multiple refresh
  bool _isRefreshing = false;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isOnboarded => _isOnboarded;
  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, double> get todayNutrition => _todayNutrition;
  int get todayCalories => _todayCalories;
  List<Map<String, dynamic>> get scanHistory => _scanHistory;
  List<Map<String, dynamic>> get recentHistory => _recentHistory;
  
  // 🎯 Mission getters
  List<Map<String, dynamic>> get dailyMissions => _dailyMissions;
  Map<String, dynamic> get missionStats => _missionStats;
  int get userStreak => _userStreak;
  bool get isMissionLoading => _isMissionLoading;
  
  // Target getters with defaults
  int get targetCalories => _userProfile?['target_calories'] as int? ?? 2000;
  double get targetProtein => _userProfile?['target_protein'] as double? ?? 50.0;
  double get targetCarbs => _userProfile?['target_carbs'] as double? ?? 250.0;
  double get targetFat => _userProfile?['target_fat'] as double? ?? 65.0;
  
  // 🎯 Mission helper getters
  int get totalPoints => _missionStats['total_points'] as int? ?? 0;
  int get totalMissionsCompleted => _missionStats['total_missions_completed'] as int? ?? 0;
  int get badgesCount => _missionStats['badges_count'] as int? ?? 0;
  List<Map<String, dynamic>> get badges => _missionStats['badges'] as List<Map<String, dynamic>>? ?? [];
  
  // Progress percentage
  double get calorieProgress => (_todayCalories / targetCalories).clamp(0.0, 1.0);
  int get calorieProgressPercent => (calorieProgress * 100).toInt();
  
  double get proteinProgress => (_todayNutrition['total_protein'] ?? 0) / targetProtein;
  double get carbsProgress => (_todayNutrition['total_carbs'] ?? 0) / targetCarbs;
  double get fatProgress => (_todayNutrition['total_fat'] ?? 0) / targetFat;
  
  // Initialize - cek onboarding status
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dbManager.init();
      
      // Inisialisasi MissionService
      _missionService = MissionService();
      
      // Load missions dari JSON (hanya sekali)
      await _missionService.loadMissionsFromJson();
      
      // Cek dan reset misi harian
      await _missionService.checkAndResetDailyMissions();
      
      await checkOnboardingStatus();
      if (_isOnboarded) {
        await loadHomeData();
        await loadMissionData();
      }
    } catch (e) {
      debugPrint('❌ Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Check if user has profile
  Future<void> checkOnboardingStatus() async {
    _userProfile = await _dbManager.getUserProfile();
    _isOnboarded = _userProfile != null;
    notifyListeners();
  }
  
  // 🎯 Load mission data
  Future<void> loadMissionData() async {
    if (!_isOnboarded) return;
    
    _isMissionLoading = true;
    notifyListeners();
    
    try {
      final results = await Future.wait([
        _missionService.getTodayActiveMissions(),
        _missionService.getMissionStats(),
        _missionService.getUserStreak(),
      ]);
      
      _dailyMissions = results[0] as List<Map<String, dynamic>>;
      _missionStats = results[1] as Map<String, dynamic>;
      _userStreak = results[2] as int;
      
      debugPrint('🎯 Mission data loaded: ${_dailyMissions.length} missions, $_userStreak streak');
      
    } catch (e) {
      debugPrint('❌ Load mission data error: $e');
    } finally {
      _isMissionLoading = false;
      notifyListeners();
    }
  }
  
  // 🎯 Refresh mission data only
  Future<void> refreshMissionData() async {
    if (!_isOnboarded) return;
    
    try {
      final results = await Future.wait([
        _missionService.getTodayActiveMissions(),
        _missionService.getMissionStats(),
        _missionService.getUserStreak(),
      ]);
      
      _dailyMissions = results[0] as List<Map<String, dynamic>>;
      _missionStats = results[1] as Map<String, dynamic>;
      _userStreak = results[2] as int;
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Refresh mission data error: $e');
    }
  }
  
  // 🎯 Claim mission reward
  Future<bool> claimMissionReward(int missionProgressId) async {
    debugPrint('🎯 Claiming mission reward: $missionProgressId');
    
    try {
      final success = await _missionService.claimMissionReward(missionProgressId);
      
      if (success) {
        // Refresh mission data setelah claim
        await refreshMissionData();
        // Refresh user profile untuk update poin
        await loadHomeData();
        debugPrint('✅ Mission reward claimed successfully');
      }
      
      return success;
      
    } catch (e) {
      debugPrint('❌ Claim mission reward error: $e');
      return false;
    }
  }
  
  // 🎯 Update mission progress after scan (dipanggil setelah scan)
  Future<void> updateMissionProgressAfterScan(Map<String, dynamic> scanData) async {
    try {
      await _missionService.updateMissionProgressAfterScan(scanData);
      // Refresh mission data untuk update UI
      await refreshMissionData();
      debugPrint('✅ Mission progress updated after scan');
    } catch (e) {
      debugPrint('❌ Update mission progress error: $e');
    }
  }
  
  // Save user profile (onboarding)
  Future<bool> saveUserProfile({
    required String name,
    required int targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dbManager.saveUserProfile(
        name: name,
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        targetCarbs: targetCarbs,
        targetFat: targetFat,
      );
      
      _userProfile = await _dbManager.getUserProfile();
      _isOnboarded = true;
      await loadHomeData();
      await loadMissionData();
      
      return true;
    } catch (e) {
      debugPrint('Save profile error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load all home data
  Future<void> loadHomeData() async {
    if (!_isOnboarded) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final results = await Future.wait([
        _dbManager.getUserProfile(),
        _dbManager.getTodayNutritionSummary(),
        _dbManager.getTodayTotalCalories(),
        _dbManager.getAllScanHistory(),
      ]);
      
      _userProfile = results[0] as Map<String, dynamic>?;
      _todayNutrition = (results[1] as Map<String, double>?) ?? {};
      _todayCalories = (results[2] as int?) ?? 0;
      _scanHistory = (results[3] as List<Map<String, dynamic>>?) ?? [];
      _recentHistory = _scanHistory.take(5).toList();
      
      debugPrint('📊 AppState: Loaded ${_scanHistory.length} history items');
      debugPrint('📊 AppState: Recent history ${_recentHistory.length} items');
      
    } catch (e) {
      debugPrint('Load home data error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Refresh data dengan mencegah multiple refresh
  Future<void> refresh() async {
    if (_isRefreshing) {
      debugPrint('⚠️ Refresh already in progress, skipping...');
      return;
    }
    
    _isRefreshing = true;
    debugPrint('🔄 AppState.refresh() called - timestamp: ${DateTime.now()}');
    
    try {
      if (!_isOnboarded) return;
      
      final results = await Future.wait([
        _dbManager.getUserProfile(),
        _dbManager.getTodayNutritionSummary(),
        _dbManager.getTodayTotalCalories(),
        _dbManager.getAllScanHistory(),
        _missionService.getTodayActiveMissions(),
        _missionService.getMissionStats(),
        _missionService.getUserStreak(),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ Database timeout, returning default values');
          return [null, {}, 0, [], [], {}, 0];
        },
      );
      
      _userProfile = results[0] as Map<String, dynamic>?;
      _todayNutrition = (results[1] as Map<String, double>?) ?? {};
      _todayCalories = (results[2] as int?) ?? 0;
      _scanHistory = (results[3] as List<Map<String, dynamic>>?) ?? [];
      _recentHistory = _scanHistory.take(5).toList();
      _dailyMissions = results[4] as List<Map<String, dynamic>>;
      _missionStats = results[5] as Map<String, dynamic>;
      _userStreak = results[6] as int;
      
      debugPrint('📊 AppState: Loaded ${_scanHistory.length} history items');
      debugPrint('🎯 AppState: Loaded ${_dailyMissions.length} missions');
      
      notifyListeners();
      
    } catch (e, stacktrace) {
      debugPrint('❌ AppState.refresh() error: $e');
      debugPrint('📚 Stacktrace: $stacktrace');
    } finally {
      _isRefreshing = false;
    }
  }
  
  // Save scan history and auto refresh
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
    debugPrint('💾💾💾 AppState.saveScanHistory() START 💾💾💾');
    debugPrint('📊 Food: $indonesianName');
    debugPrint('📊 Protein: $protein, Fiber: ${fiber ?? 0}, Sodium: ${sodium ?? 0}');
    
    // Build scan data untuk update mission
    final scanData = {
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
    };
    
    debugPrint('📦 scanData: $scanData');
    
    final id = await _dbManager.saveScanHistory(
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
    
    if (id != -1) {
      debugPrint('✅ Scan saved with id=$id');
      
      debugPrint('🎯🎯🎯 CALLING updateMissionProgressAfterScan 🎯🎯🎯');
      await updateMissionProgressAfterScan(scanData);
      debugPrint('✅✅✅ updateMissionProgressAfterScan COMPLETED ✅✅✅');
      
      await refresh();
      debugPrint('✅ Refresh completed after scan');
    }
    
    debugPrint('💾💾💾 AppState.saveScanHistory() END 💾💾💾');
    return id;
  }
  
  // Reset all data (including missions)
  Future<void> resetAllData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dbManager.resetAllDataComplete();
      _userProfile = null;
      _isOnboarded = false;
      _todayNutrition = {};
      _todayCalories = 0;
      _scanHistory = [];
      _recentHistory = [];
      _dailyMissions = [];
      _missionStats = {};
      _userStreak = 0;
      
      // Regenerate missions setelah reset
      await _missionService.loadMissionsFromJson();
      await _missionService.checkAndResetDailyMissions();
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get health level helper
  String getHealthLevel(String label) {
    return NutritionData.getHealthLevel(label).toString().split('.').last;
  }

  /// Dapatkan streak penyelesaian misi harian
  Future<int> getMissionStreak() async {
    final completedMissions = await _dbManager.getCompletedMissionsHistory();
    if (completedMissions.isEmpty) return 0;
    
    // Kelompokkan berdasarkan tanggal
    final Map<String, int> missionsPerDay = {};
    for (var mission in completedMissions) {
      final date = mission['completed_date'].toString().substring(0, 10);
      missionsPerDay[date] = (missionsPerDay[date] ?? 0) + 1;
    }
    
    // Hitung streak hari dengan minimal 1 misi selesai per hari
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      
      if (missionsPerDay.containsKey(dateKey) && (missionsPerDay[dateKey] ?? 0) >= 1) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  Future<void> deleteScanHistory(int id) async {
    debugPrint('🗑️ AppState.deleteScanHistory: $id');
    
    try {
      await _dbManager.deleteScanHistory(id);
      debugPrint('✅ Database record deleted');
      
      await _clearImageCache();
      
      _scanHistory = _scanHistory.where((item) => item['id'] != id).toList();
      _recentHistory = _scanHistory.take(5).toList();
      notifyListeners();
      
      unawaited(_backgroundRefresh());
      
    } catch (e) {
      debugPrint('❌ DeleteScanHistory error: $e');
      await refresh();
      rethrow;
    }
  }

  Future<void> _backgroundRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      await refresh();
    } catch (e) {
      debugPrint('⚠️ Background refresh failed: $e');
    }
  }

  Future<void> _clearImageCache() async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      debugPrint('🖼️ Image cache cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear image cache: $e');
    }
  }

  Future<void> deleteAllScanHistory() async {
    debugPrint('🗑️ AppState.deleteAllScanHistory');
    
    try {
      await _dbManager.resetAllData();
      await _clearImageCache();
      await Future.delayed(const Duration(milliseconds: 100));
      await refresh();
    } catch (e) {
      debugPrint('❌ DeleteAllScanHistory error: $e');
      rethrow;
    }
  }
}