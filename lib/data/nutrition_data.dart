// lib/data/nutrition_data.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class NutritionData {
  static late Map<String, FoodData> _foodDatabase;
  static bool _isInitialized = false;

  static Future<void> loadData() async {
    if (_isInitialized) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/nutrition_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> foods = jsonData['foods'];
      _foodDatabase = {};
      
      for (var food in foods) {
        final label = food['label'] as String;
        final healthLevelStr = food['health_level'] as String;
        
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
      
      // Tambahkan default
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
  
  static FoodData getFoodData(String label) {
    if (!_isInitialized) {
      // Fallback jika belum load
      return _foodDatabase['default']!;
    }
    return _foodDatabase[label] ?? _foodDatabase['default']!;
  }
  
  static String getIndonesianName(String label) {
    return getFoodData(label).indonesianName;
  }
  
  static int getCalories(String label) {
    return getFoodData(label).calories;
  }
  
  static double getProtein(String label) {
    return getFoodData(label).protein;
  }
  
  static double getCarbs(String label) {
    return getFoodData(label).carbs;
  }
  
  static double getFat(String label) {
    return getFoodData(label).fat;
  }
  
  static double getFiber(String label) {
    return getFoodData(label).fiber;
  }
  
  static double getSugar(String label) {
    return getFoodData(label).sugar;
  }
  
  static double getSodium(String label) {
    return getFoodData(label).sodium;
  }
  
  static HealthLevel getHealthLevel(String label) {
    return getFoodData(label).healthLevel;
  }
  
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
  
  static String getHealthTip(String label) {
    return getFoodData(label).healthTip;
  }
  
  static String getWarning(String label) {
    return getFoodData(label).warning;
  }
}

enum HealthLevel { healthy, medium, unhealthy }

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