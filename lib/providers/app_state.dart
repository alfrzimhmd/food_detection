// lib/providers/app_state.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../data/database_manager.dart';
import '../data/nutrition_data.dart';

class AppState extends ChangeNotifier {
  final DatabaseManager _dbManager = DatabaseManager();
  
  // State variables
  bool _isLoading = false;
  bool _isOnboarded = false;
  Map<String, dynamic>? _userProfile;
  Map<String, double> _todayNutrition = {};
  int _todayCalories = 0;
  List<Map<String, dynamic>> _scanHistory = [];
  List<Map<String, dynamic>> _recentHistory = [];
  
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
  
  // Target getters with defaults
  int get targetCalories => _userProfile?['target_calories'] as int? ?? 2000;
  double get targetProtein => _userProfile?['target_protein'] as double? ?? 50.0;
  double get targetCarbs => _userProfile?['target_carbs'] as double? ?? 250.0;
  double get targetFat => _userProfile?['target_fat'] as double? ?? 65.0;
  
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
      await checkOnboardingStatus();
      if (_isOnboarded) {
        await loadHomeData();
      }
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
      // 🔥 JANGAN set _isLoading = true dulu, biar tidak rebuild terlalu sering
      // await loadHomeData();
      
      // 🔥 Load data dengan aman
      if (!_isOnboarded) return;
      
      final results = await Future.wait([
        _dbManager.getUserProfile(),
        _dbManager.getTodayNutritionSummary(),
        _dbManager.getTodayTotalCalories(),
        _dbManager.getAllScanHistory(),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ Database timeout, returning default values');
          return [null, {}, 0, []];
        },
      );
      
      _userProfile = results[0] as Map<String, dynamic>?;
      _todayNutrition = (results[1] as Map<String, double>?) ?? {};
      _todayCalories = (results[2] as int?) ?? 0;
      _scanHistory = (results[3] as List<Map<String, dynamic>>?) ?? [];
      _recentHistory = _scanHistory.take(5).toList();
      
      debugPrint('📊 AppState: Loaded ${_scanHistory.length} history items');
      
      // 🔥 Notify listeners ONLY after all data is loaded
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
    debugPrint('💾 AppState.saveScanHistory() called for: $indonesianName');
    
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
      debugPrint('✅ Scan saved with id=$id, calling refresh...');
      await refresh();
      debugPrint('✅ Refresh completed after scan');
    }
    
    return id;
  }
  
  // Reset all data
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get health level helper
  String getHealthLevel(String label) {
    return NutritionData.getHealthLevel(label).toString().split('.').last;
  }

  Future<void> deleteScanHistory(int id) async {
    debugPrint('🗑️ AppState.deleteScanHistory: $id');
    
    try {
      // 1. Hapus dari database
      await _dbManager.deleteScanHistory(id);
      debugPrint('✅ Database record deleted');
      
      // 2. Bersihkan cache gambar
      await _clearImageCache();
      
      // 3. 🔥 Hapus dari memory cache dulu (optimistic update)
      _scanHistory = _scanHistory.where((item) => item['id'] != id).toList();
      _recentHistory = _scanHistory.take(5).toList();
      notifyListeners(); // UI langsung update
      
      // 4. 🔥 Refresh di background (tanpa nunggu)
      // Gunakan unawaited agar tidak blocking
      unawaited(_backgroundRefresh());
      
    } catch (e) {
      debugPrint('❌ DeleteScanHistory error: $e');
      // Jika gagal, refresh ulang untuk sync
      await refresh();
      rethrow;
    }
  }

  Future<void> _backgroundRefresh() async {
    // Tunggu sebentar sebelum refresh
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      await refresh();
    } catch (e) {
      debugPrint('⚠️ Background refresh failed: $e');
    }
  }

  Future<void> _clearImageCache() async {
    // Bersihkan cache gambar dari memory
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      debugPrint('🖼️ Image cache cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear image cache: $e');
    }
  }

  // Delete all scan history (tanpa menghapus user profile)
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