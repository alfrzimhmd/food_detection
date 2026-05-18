import 'package:flutter/material.dart';

class NutritionData {
  static final Map<String, FoodData> foodDatabase = {    
    'ayam_goreng': FoodData(
      indonesianName: 'Ayam Goreng',
      calories: 290,
      protein: 18.0,
      carbs: 13.0,
      fat: 17.0,
      fiber: 0.5,
      sugar: 0.5,
      sodium: 380,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Siang atau malam',
      servingSuggestion: '1 potong (sekitar 150g)',
      healthTip: 'Hilangkan kulit ayam untuk mengurangi lemak',
      warning: 'Digoreng, tinggi lemak jenuh jika dikonsumsi berlebihan',
    ),
    
    'bakso': FoodData(
      indonesianName: 'Bakso',
      calories: 175,
      protein: 11.0,
      carbs: 18.0,
      fat: 7.0,
      fiber: 1.0,
      sugar: 2.0,
      sodium: 580,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Makan siang atau sore',
      servingSuggestion: '1 mangkok (5-6 bakso + kuah)',
      healthTip: 'Tambahkan sayuran seperti sawi untuk serat',
      warning: 'Tinggi sodium dari kuah dan pentol bakso',
    ),
    
    'burger': FoodData(
      indonesianName: 'Burger',
      calories: 350,
      protein: 15.0,
      carbs: 35.0,
      fat: 18.0,
      fiber: 2.0,
      sugar: 6.0,
      sodium: 520,
      healthLevel: HealthLevel.unhealthy,
      bestTimeToEat: 'Makan siang',
      servingSuggestion: '1 buah burger',
      healthTip: 'Pilih roti gandum dan tambahan sayuran segar',
      warning: 'Tinggi kalori, lemak jenuh, dan sodium',
    ),
    
    'french_fries': FoodData(
      indonesianName: 'Kentang Goreng',
      calories: 312,
      protein: 3.0,
      carbs: 41.0,
      fat: 15.0,
      fiber: 3.0,
      sugar: 0.5,
      sodium: 210,
      healthLevel: HealthLevel.unhealthy,
      bestTimeToEat: 'Camilan (tidak disarankan rutin)',
      servingSuggestion: 'Porsi kecil (100g)',
      healthTip: 'Pilih kentang panggang dengan sedikit minyak zaitun',
      warning: 'Tinggi lemak trans dan kalori kosong',
    ),
    
    'gado_gado': FoodData(
      indonesianName: 'Gado-Gado',
      calories: 320,
      protein: 9.0,
      carbs: 25.0,
      fat: 18.0,
      fiber: 6.0,
      sugar: 8.0,
      sodium: 420,
      healthLevel: HealthLevel.healthy,
      bestTimeToEat: 'Makan siang',
      servingSuggestion: '1 porsi sedang (sekitar 300g)',
      healthTip: 'Kaya serat dari sayuran seperti kangkung, tauge, dan kol',
      warning: 'Bumbu kacang cukup tinggi kalori dan lemak',
    ),
    
    'gudeg': FoodData(
      indonesianName: 'Gudeg',
      calories: 280,
      protein: 5.0,
      carbs: 35.0,
      fat: 12.0,
      fiber: 4.0,
      sugar: 15.0,
      sodium: 350,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Makan siang',
      servingSuggestion: '1 porsi dengan nasi (sekitar 250g)',
      healthTip: 'Nikmati dengan sayur lodeh untuk keseimbangan nutrisi',
      warning: 'Mengandung santan dan gula aren, cukup tinggi kalori',
    ),
    
    'gulai_ikan': FoodData(
      indonesianName: 'Gulai Ikan',
      calories: 340,
      protein: 22.0,
      carbs: 8.0,
      fat: 24.0,
      fiber: 1.0,
      sugar: 2.0,
      sodium: 480,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Makan siang',
      servingSuggestion: '1 porsi dengan nasi (sekitar 200g)',
      healthTip: 'Ikan kaya protein dan asam lemak omega-3',
      warning: 'Tinggi santan dan lemak jenuh, konsumsi secukupnya',
    ),
    
    'ikan_goreng': FoodData(
      indonesianName: 'Ikan Goreng',
      calories: 240,
      protein: 20.0,
      carbs: 2.0,
      fat: 16.0,
      fiber: 0.0,
      sugar: 0.0,
      sodium: 290,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Makan siang atau malam',
      servingSuggestion: '1 ekor ikan sedang (sekitar 150g)',
      healthTip: 'Kaya protein dan omega-3, lebih sehat jika dipanggang',
      warning: 'Digoreng, lebih sehat jika dibakar atau dikukus',
    ),
    
    'mie_goreng': FoodData(
      indonesianName: 'Mie Goreng',
      calories: 420,
      protein: 10.0,
      carbs: 55.0,
      fat: 18.0,
      fiber: 3.0,
      sugar: 5.0,
      sodium: 720,
      healthLevel: HealthLevel.unhealthy,
      bestTimeToEat: 'Makan siang',
      servingSuggestion: '1 porsi (sekitar 250g)',
      healthTip: 'Tambahkan sayuran seperti sawi dan wortel',
      warning: 'Tinggi karbohidrat sederhana dan sodium',
    ),
    
    'nasi_goreng': FoodData(
      indonesianName: 'Nasi Goreng',
      calories: 350,
      protein: 8.0,
      carbs: 45.0,
      fat: 14.0,
      fiber: 2.0,
      sugar: 4.0,
      sodium: 680,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Sarapan atau makan siang',
      servingSuggestion: '1 piring (sekitar 300g)',
      healthTip: 'Tambahkan sayuran seperti wortel, buncis, dan kol',
      warning: 'Tinggi karbohidrat dan sodium, perhatikan porsi',
    ),
    
    'pempek': FoodData(
      indonesianName: 'Pempek',
      calories: 220,
      protein: 6.0,
      carbs: 35.0,
      fat: 6.0,
      fiber: 1.0,
      sugar: 8.0,
      sodium: 450,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Camilan sore',
      servingSuggestion: '3-4 buah ukuran sedang',
      healthTip: 'Pilih pempek yang tidak terlalu berminyak',
      warning: 'Kuah cuko (cuka) cukup tinggi gula',
    ),
    
    'pizza': FoodData(
      indonesianName: 'Pizza',
      calories: 285,
      protein: 12.0,
      carbs: 36.0,
      fat: 10.0,
      fiber: 2.0,
      sugar: 4.0,
      sodium: 620,
      healthLevel: HealthLevel.unhealthy,
      bestTimeToEat: 'Makan malam',
      servingSuggestion: '2 slice ukuran sedang',
      healthTip: 'Pilih topping sayuran seperti jamur, paprika, dan bawang',
      warning: 'Konsumsi berlebihan dapat meningkatkan kolesterol',
    ),
    
    'rawon': FoodData(
      indonesianName: 'Rawon',
      calories: 310,
      protein: 18.0,
      carbs: 15.0,
      fat: 18.0,
      fiber: 2.0,
      sugar: 3.0,
      sodium: 520,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Makan siang',
      servingSuggestion: '1 mangkok dengan nasi (sekitar 300g)',
      healthTip: 'Kaya rempah seperti kluwek yang mengandung antioksidan',
      warning: 'Tinggi lemak dari daging sapi',
    ),
    
    'rendang': FoodData(
      indonesianName: 'Rendang',
      calories: 480,
      protein: 22.0,
      carbs: 10.0,
      fat: 38.0,
      fiber: 1.0,
      sugar: 3.0,
      sodium: 450,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Makan siang atau malam',
      servingSuggestion: '1 potong dengan nasi (sekitar 150g)',
      healthTip: 'Kaya protein dari daging sapi dan rempah-rempah',
      warning: 'Sangat tinggi lemak jenuh dari santan, konsumsi sesekali',
    ),
    
    'sate': FoodData(
      indonesianName: 'Sate',
      calories: 280,
      protein: 20.0,
      carbs: 12.0,
      fat: 16.0,
      fiber: 1.0,
      sugar: 6.0,
      sodium: 380,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Makan malam',
      servingSuggestion: '10 tusuk sate ayam',
      healthTip: 'Pilih sate ayam tanpa lemak dan kurangi bumbu kacang',
      warning: 'Bumbu kacang cukup tinggi kalori dan lemak',
    ),
    
    'soto': FoodData(
      indonesianName: 'Soto',
      calories: 250,
      protein: 15.0,
      carbs: 20.0,
      fat: 12.0,
      fiber: 2.0,
      sugar: 2.0,
      sodium: 550,
      healthLevel: HealthLevel.healthy,
      bestTimeToEat: 'Makan siang',
      servingSuggestion: '1 mangkok dengan nasi (sekitar 350g)',
      healthTip: 'Hangat dan menyegarkan, kaya rempah',
      warning: 'Perhatikan sodium dari kuah, kurangi garam jika perlu',
    ),
    
    'telur_balado': FoodData(
      indonesianName: 'Telur Balado',
      calories: 180,
      protein: 10.0,
      carbs: 5.0,
      fat: 14.0,
      fiber: 1.0,
      sugar: 3.0,
      sodium: 320,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Makan siang atau malam',
      servingSuggestion: '1-2 butir telur',
      healthTip: 'Kaya protein dari telur, cabai merah mengandung vitamin C',
      warning: 'Sambal balado cukup tinggi minyak goreng',
    ),
    
    'telur_dadar': FoodData(
      indonesianName: 'Telur Dadar',
      calories: 150,
      protein: 11.0,
      carbs: 2.0,
      fat: 11.0,
      fiber: 0.0,
      sugar: 1.0,
      sodium: 280,
      healthLevel: HealthLevel.healthy,
      bestTimeToEat: 'Sarapan atau makan malam',
      servingSuggestion: '1 butir telur dadar',
      healthTip: 'Sumber protein yang baik, bisa dicampur sayuran',
      warning: 'Hindari penggunaan minyak berlebih saat menggoreng',
    ),
    
    // Default untuk label yang tidak ditemukan
    'default': FoodData(
      indonesianName: 'Makanan',
      calories: 200,
      protein: 5.0,
      carbs: 20.0,
      fat: 10.0,
      fiber: 1.0,
      sugar: 5.0,
      sodium: 200,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Sesuai kebutuhan',
      servingSuggestion: 'Konsumsi secukupnya',
      healthTip: 'Perhatikan keseimbangan nutrisi dalam setiap makanan',
      warning: 'Informasi nutrisi bersifat estimasi, bisa berbeda dengan produk aktual',
    ),
  };

  // METHOD GETTER UNTUK MENGAMBIL DATA NUTRISI BERDASARKAN LABEL
  
  static FoodData getFoodData(String label) {
    return foodDatabase[label] ?? foodDatabase['default']!;
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
  
  static String getBestTimeToEat(String label) {
    return getFoodData(label).bestTimeToEat;
  }
  
  static String getServingSuggestion(String label) {
    return getFoodData(label).servingSuggestion;
  }
  
  static String getHealthTip(String label) {
    return getFoodData(label).healthTip;
  }
  
  static String getWarning(String label) {
    return getFoodData(label).warning;
  }
}

//  ENUM HEALTH LEVEL 
enum HealthLevel { healthy, medium, unhealthy }

//  CLASS FOOD DATA 
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
  final String bestTimeToEat;
  final String servingSuggestion;
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
    required this.bestTimeToEat,
    required this.servingSuggestion,
    required this.healthTip,
    required this.warning,
  });
}