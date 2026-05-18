// ============================================================================
// HYBRID CLASSIFIER - VERSI STABIL (TANPA HASH DEBUG)
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import '../data/knn_database.dart';

class HybridFoodClassifier {
  late Interpreter _cnnModel;
  late List<String> _labels;
  late SimpleCorrectionDatabase _db;
  
  static const int numClasses = 18;
  
  Future<void> loadModel() async {
    try {
      _cnnModel = await Interpreter.fromAsset('assets/food_indonesia_model.tflite');
      debugPrint('✅ CNN Model loaded!');
      
      String labelsData = await rootBundle.loadString('assets/labels_indonesia.txt');
      _labels = labelsData.split('\n');
      _labels = _labels.where((label) => label.trim().isNotEmpty).toList();
      debugPrint('📋 Labels loaded: ${_labels.length} classes');
      
      _db = SimpleCorrectionDatabase();
      await _db.init();
      
      final count = await _db.getCount();
      debugPrint('📊 Correction cache loaded: $count entries');
      
    } catch (e) {
      debugPrint('❌ Error loading model: $e');
      rethrow;
    }
  }
  
  // ==========================================================================
  // HASH SEDERHANA (AMAN)
  // ==========================================================================
  
  String _computeImageHash(List<int> imageBytes) {
    // Simple hash yang aman dan konsisten
    var hash = 0;
    for (int i = 0; i < imageBytes.length; i++) {
      hash = (hash * 31 + imageBytes[i]) & 0xFFFFFFFF;
    }
    // Konversi ke hex string dengan panjang tetap
    return hash.toRadixString(16).padLeft(8, '0');
  }
  
  // ==========================================================================
  // PREDIKSI CNN (Klasifikasi Langsung)
  // ==========================================================================
  
  Future<Map<String, dynamic>> _predictCnn(List<int> imageBytes) async {
    // Siapkan input tensor
    Uint8List uint8List = Uint8List.fromList(imageBytes);
    img.Image? image = img.decodeImage(uint8List);
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    img.Image resized = img.copyResize(image, width: 224, height: 224);
    
    var input = List.filled(1 * 224 * 224 * 3, 0.0);
    int index = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = pixel.r.toDouble() / 255.0;
        input[index++] = pixel.g.toDouble() / 255.0;
        input[index++] = pixel.b.toDouble() / 255.0;
      }
    }
    
    var inputTensor = input.reshape([1, 224, 224, 3]);
    var output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);
    
    // Run inference
    _cnnModel.run(inputTensor, output);
    
    // Cari probabilitas tertinggi (argmax)
    int predictedIndex = 0;
    double maxProb = output[0][0];
    for (int i = 1; i < output[0].length; i++) {
      if (output[0][i] > maxProb) {
        maxProb = output[0][i];
        predictedIndex = i;
      }
    }
    
    String predictedLabel = predictedIndex < _labels.length 
        ? _labels[predictedIndex] 
        : 'unknown';
    
    return {
      'label': predictedLabel,
      'confidence': maxProb,
      'allProbabilities': output[0],
    };
  }
  
  // ==========================================================================
  // PREDIKSI UTAMA (Dengan Cache)
  // ==========================================================================
  
  Future<Prediction> predict(List<int> imageBytes) async {
    try {
      // STEP 1: Hitung hash gambar
      final imageHash = _computeImageHash(imageBytes);
      debugPrint('🔑 Hash: ${imageHash.substring(0, 8)}...');
      
      // STEP 2: Cek di database (pakai try-catch untuk aman)
      Map<String, dynamic>? correction;
      try {
        correction = await _db.findByHash(imageHash);
      } catch (dbError) {
        debugPrint('⚠️ Database error: $dbError');
        correction = null;
      }
      
      if (correction != null) {
        final correctLabel = correction['label'] as String;
        debugPrint('🎯 [CACHE] Found: $correctLabel');
        
        return Prediction(
          label: correctLabel,
          probability: 0.95,
          allProbabilities: const [],
          isFromCache: true,
        );
      }
      
      // STEP 3: Prediksi dengan CNN
      debugPrint('🤖 [CNN] No cache, predicting...');
      final result = await _predictCnn(imageBytes);
      
      return Prediction(
        label: result['label'] as String,
        probability: result['confidence'] as double,
        allProbabilities: result['allProbabilities'] as List<double>,
        isFromCache: false,
      );
      
    } catch (e) {
      debugPrint('❌ Prediction error: $e');
      rethrow;
    }
  }
  
  // ==========================================================================
  // BELAJAR DARI KESALAHAN
  // ==========================================================================
  
  Future<void> learnFromFeedback({
    required List<int> imageBytes,
    required String originalPrediction,
    required String correctLabel,
  }) async {
    try {
      final imageHash = _computeImageHash(imageBytes);
      debugPrint('🔑 Learning hash: ${imageHash.substring(0, 8)}...');
      
      // Cek apakah sudah ada
      final existing = await _db.findByHash(imageHash);
      
      if (existing != null) {
        final existingLabel = existing['label'] as String;
        if (existingLabel == correctLabel) {
          debugPrint('⚠️ Already correct, skipping...');
          return;
        }
        debugPrint('🔄 Updating: $existingLabel → $correctLabel');
      }
      
      // Simpan atau update
      await _db.insertOrUpdateCorrection(
        imageHash: imageHash,
        label: correctLabel,
        originalPrediction: originalPrediction,
      );
      
      final count = await _db.getCount();
      debugPrint('✅ Learned! Cache size: $count');
      
    } catch (e) {
      debugPrint('❌ Error learning: $e');
    }
  }
  
  // ==========================================================================
  // UTILITY
  // ==========================================================================
  
  List<String> get labels => _labels;
  
  Future<int> getCacheSize() async {
    try {
      return await _db.getCount();
    } catch (e) {
      return 0;
    }
  }
  
  Future<void> resetCache() async {
    await _db.deleteAll();
  }
  
  void dispose() {
    _cnnModel.close();
    _db.close();
  }
}

class Prediction {
  final String label;
  final double probability;
  final List<double> allProbabilities;
  final bool isFromCache;
  
  const Prediction({
    required this.label,
    required this.probability,
    required this.allProbabilities,
    this.isFromCache = false,
  });
}