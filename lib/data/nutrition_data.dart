// lib/data/nutrition_data.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Manajer data nutrisi untuk semua makanan.
/// Memuat data dari file JSON dan menyediakan akses ke informasi nutrisi setiap makanan.
class NutritionData {
  // Database makanan utama
  static late Map<String, FoodData> _foodDatabase;
  
  // Flag untuk menandakan apakah data sudah dimuat
  static bool _isInitialized = false;

  /// Memuat data nutrisi dari file JSON
  static Future<void> loadData() async {
    if (_isInitialized) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/nutrition_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> foods = jsonData['foods'];
      _foodDatabase = {};
      
      // Iterasi setiap makanan dan konversi ke FoodData
      for (var food in foods) {
        final label = food['label'] as String;
        final healthLevelStr = food['health_level'] as String;
        
        // Konversi string health_level ke enum
        HealthLevel healthLevel;
        switch (healthLevelStr) {
          case 'healthy':
            healthLevel = HealthLevel.healthy;
            break;
          case 'unhealthy':
            healthLevel = HealthLevel.unhealthy;
            break;
          default:
            healthLevel = HealthLevel.medium;
        }
        
        _foodDatabase[label] = FoodData(
          indonesianName: food['indonesian_name'],
          calories: food['calories'],
          protein: (food['protein'] as num).toDouble(),
          carbs: (food['carbs'] as num).toDouble(),
          fat: (food['fat'] as num).toDouble(),
          fiber: (food['fiber'] as num).toDouble(),
          sugar: (food['sugar'] as num).toDouble(),
          sodium: (food['sodium'] as num).toDouble(),
          healthLevel: healthLevel,
          healthTip: food['health_tip'],
          warning: food['warning'],
        );
      }
      
      // Tambahkan data default untuk fallback
      _foodDatabase['default'] = FoodData(
        indonesianName: 'Makanan',
        calories: 200,
        protein: 5.0,
        carbs: 20.0,
        fat: 10.0,
        fiber: 1.0,
        sugar: 5.0,
        sodium: 200,
        healthLevel: HealthLevel.medium,
        healthTip: 'Perhatikan keseimbangan nutrisi dalam setiap makanan.',
        warning: 'Informasi nutrisi bersifat estimasi.',
      );
      
      _isInitialized = true;
      debugPrint('Nutrition data loaded from JSON: ${_foodDatabase.length} foods');
      
    } catch (e) {
      debugPrint('Error loading nutrition data: $e');
      _loadDefaultData();
    }
  }
  
  /// Memuat data default jika file JSON gagal dimuat
  static void _loadDefaultData() {
    _foodDatabase = {};
    _foodDatabase['default'] = FoodData(
      indonesianName: 'Makanan',
      calories: 200,
      protein: 5.0,
      carbs: 20.0,
      fat: 10.0,
      fiber: 1.0,
      sugar: 5.0,
      sodium: 200,
      healthLevel: HealthLevel.medium,
      healthTip: 'Perhatikan keseimbangan nutrisi dalam setiap makanan.',
      warning: 'Informasi nutrisi bersifat estimasi.',
    );
    _isInitialized = true;
  }
  
  /// Mendapatkan data makanan berdasarkan label
  static FoodData getFoodData(String label) {
    if (!_isInitialized) {
      // Fallback jika belum load
      return _foodDatabase['default']!;
    }
    return _foodDatabase[label] ?? _foodDatabase['default']!;
  }
  
  // ==================== GETTER METHODS ====================
  
  /// Mendapatkan nama Indonesia dari makanan
  static String getIndonesianName(String label) {
    return getFoodData(label).indonesianName;
  }
  
  /// Mendapatkan kalori makanan
  static int getCalories(String label) {
    return getFoodData(label).calories;
  }
  
  /// Mendapatkan protein makanan
  static double getProtein(String label) {
    return getFoodData(label).protein;
  }
  
  /// Mendapatkan karbohidrat makanan
  static double getCarbs(String label) {
    return getFoodData(label).carbs;
  }
  
  /// Mendapatkan lemak makanan
  static double getFat(String label) {
    return getFoodData(label).fat;
  }
  
  /// Mendapatkan serat makanan
  static double getFiber(String label) {
    return getFoodData(label).fiber;
  }
  
  /// Mendapatkan gula makanan
  static double getSugar(String label) {
    return getFoodData(label).sugar;
  }
  
  /// Mendapatkan sodium makanan
  static double getSodium(String label) {
    return getFoodData(label).sodium;
  }
  
  /// Mendapatkan level kesehatan makanan
  static HealthLevel getHealthLevel(String label) {
    return getFoodData(label).healthLevel;
  }
  
  // ==================== UI HELPER METHODS ====================
  
  /// Mendapatkan warna berdasarkan level kesehatan
  static Color getHealthColor(HealthLevel level) {
    switch (level) {
      case HealthLevel.healthy:
        return Colors.green;
      case HealthLevel.medium:
        return Colors.orange;
      case HealthLevel.unhealthy:
        return Colors.red;
    }
  }
  
  /// Mendapatkan icon berdasarkan level kesehatan
  static IconData getHealthIcon(HealthLevel level) {
    switch (level) {
      case HealthLevel.healthy:
        return Icons.check_circle_rounded;
      case HealthLevel.medium:
        return Icons.warning_rounded;
      case HealthLevel.unhealthy:
        return Icons.cancel_rounded;
    }
  }
  
  /// Mendapatkan teks berdasarkan level kesehatan
  static String getHealthText(HealthLevel level) {
    switch (level) {
      case HealthLevel.healthy:
        return 'Sehat';
      case HealthLevel.medium:
        return 'Cukup Sehat';
      case HealthLevel.unhealthy:
        return 'Kurang Sehat';
    }
  }
  
  /// Mendapatkan tip kesehatan untuk makanan
  static String getHealthTip(String label) {
    return getFoodData(label).healthTip;
  }
  
  /// Mendapatkan peringatan untuk makanan
  static String getWarning(String label) {
    return getFoodData(label).warning;
  }
}

/// Enum untuk level kesehatan makanan
enum HealthLevel { healthy, medium, unhealthy }

/// Model data untuk informasi nutrisi makanan
class FoodData {
  final String indonesianName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final HealthLevel healthLevel;
  final String healthTip;
  final String warning;
  
  FoodData({
    required this.indonesianName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.healthLevel,
    required this.healthTip,
    required this.warning,
  });
}