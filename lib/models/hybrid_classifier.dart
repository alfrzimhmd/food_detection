// ============================================================================
// HYBRID CLASSIFIER - CNN + SQLite Cache + Validasi Gambar (FINAL)
// ============================================================================
// 
// Fitur:
// 1. Deteksi makanan dengan CNN (MobileNetV2, 18 kelas)
// 2. Cache koreksi user di SQLite (belajar dari kesalahan)
// 3. Validasi gambar ringan (keburaman sampling, ukuran, format)
// 4. Deteksi gambar bukan makanan (confidence threshold)
// 5. Timeout untuk mencegah freeze
// 6. Optimasi memory (resize gambar besar sebelum diproses)
// 7. Blur detection dengan sampling (tidak semua pixel)
//
// ============================================================================

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import '../data/knn_database.dart';

class HybridFoodClassifier {
  late Interpreter _cnnModel;
  late List<String> _labels;
  late SimpleCorrectionDatabase _db;
  
  // ==================== KONSTANTA ====================
  static const int numClasses = 18;
  
  // Threshold untuk validasi gambar
  static const double nonFoodThreshold = 0.53;      // < 53% = bukan makanan
  static const double lowConfidenceThreshold = 0.70; // < 70% = warning
  
  // Threshold untuk deteksi keburaman
  static const double blurThreshold = 300.0;         // < 300 = buram
  
  // Threshold ukuran file
  static const int minFileSize = 5000;               // minimal 5KB
  static const int maxFileSizeForProcessing = 3 * 1024 * 1024; // maksimal 3MB
  
  // Threshold dimensi gambar
  static const int minImageDimension = 50;           // minimal 50x50
  static const int maxImageDimensionForProcessing = 800; // maksimal 800x800
  
  // Timeout prediksi (detik)
  static const int predictionTimeoutSeconds = 5;
  
  // Sample rate untuk blur detection (1 dari setiap N pixel)
  static const int blurSampleRate = 20;
  
  // ==================== LOAD MODEL ====================
  
  Future<void> loadModel() async {
    try {
      _cnnModel = await Interpreter.fromAsset('assets/food_indonesia_model.tflite');
      debugPrint('CNN Model loaded!');
      
      String labelsData = await rootBundle.loadString('assets/labels_indonesia.txt');
      _labels = labelsData.split('\n');
      _labels = _labels.where((label) => label.trim().isNotEmpty).toList();
      debugPrint('Labels loaded: ${_labels.length} classes');
      
      _db = SimpleCorrectionDatabase();
      await _db.init();
      
      final count = await _db.getCount();
      debugPrint('Correction cache loaded: $count entries');
      
    } catch (e) {
      debugPrint('Error loading model: $e');
      rethrow;
    }
  }
  
  // ==================== HASH GAMBAR ====================
  
  String _computeImageHash(List<int> imageBytes) {
    var hash = 0;
    for (int i = 0; i < imageBytes.length; i++) {
      hash = (hash * 31 + imageBytes[i]) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
  
  // ==================== OPTIMASI & RESIZE GAMBAR ====================
  
  /// Resize gambar jika terlalu besar (harus dilakukan SEBELUM apapun)
  img.Image _resizeIfNeeded(img.Image image) {
    int targetWidth = image.width;
    int targetHeight = image.height;
    
    // Cek dimensi
    if (image.width > maxImageDimensionForProcessing || 
        image.height > maxImageDimensionForProcessing) {
      double scale = maxImageDimensionForProcessing / max(image.width, image.height);
      targetWidth = (image.width * scale).toInt();
      targetHeight = (image.height * scale).toInt();
      debugPrint('Resize: ${image.width}x${image.height} → ${targetWidth}x${targetHeight}');
      return img.copyResize(image, width: targetWidth, height: targetHeight);
    }
    
    return image;
  }
  
  /// Decode dan resize gambar dari bytes
  img.Image? _decodeAndResize(List<int> imageBytes) {
    Uint8List uint8List = Uint8List.fromList(imageBytes);
    img.Image? image = img.decodeImage(uint8List);
    if (image == null) return null;
    return _resizeIfNeeded(image);
  }
  
  // ==================== VALIDASI GAMBAR (RINGAN) ====================
  
  /// Deteksi keburaman dengan SAMPLING (jauh lebih cepat)
  double _calculateBlurrinessLight(img.Image image) {
    img.Image gray = img.grayscale(image);
    
    double sum = 0;
    double sumSq = 0;
    int count = 0;
    
    // Sample setiap N pixel untuk efisiensi
    for (int y = 0; y < gray.height; y += blurSampleRate) {
      for (int x = 0; x < gray.width; x += blurSampleRate) {
        final pixel = gray.getPixel(x, y);
        final intensity = pixel.r.toDouble();
        sum += intensity;
        sumSq += intensity * intensity;
        count++;
      }
    }
    
    if (count == 0) return 1000.0;
    
    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    return variance;
  }
  
  /// Validasi gambar sebelum prediksi
  ValidationResult validateImage(List<int> imageBytes) {
    // 1. Cek ukuran file terlalu kecil
    if (imageBytes.length < minFileSize) {
      return ValidationResult(
        isValid: false,
        errorCode: 'FILE_TOO_SMALL',
        message: 'File gambar terlalu kecil atau mungkin rusak.',
      );
    }
    
    // 2. Cek ukuran file terlalu besar
    if (imageBytes.length > maxFileSizeForProcessing) {
      return ValidationResult(
        isValid: false,
        errorCode: 'FILE_TOO_LARGE',
        message: 'File gambar terlalu besar (maksimal 3MB). Silakan pilih gambar dengan resolusi lebih rendah.',
      );
    }
    
    // 3. Decode dan resize
    final image = _decodeAndResize(imageBytes);
    if (image == null) {
      return ValidationResult(
        isValid: false,
        errorCode: 'INVALID_IMAGE',
        message: 'File tidak dapat dibaca sebagai gambar. Pastikan format file JPG/PNG.',
      );
    }
    
    // 4. Cek dimensi minimal
    if (image.width < minImageDimension || image.height < minImageDimension) {
      return ValidationResult(
        isValid: false,
        errorCode: 'IMAGE_TOO_SMALL',
        message: 'Gambar terlalu kecil (minimal 50x50 piksel).',
      );
    }
    
    // 5. Cek keburaman
    final blurScore = _calculateBlurrinessLight(image);
    if (blurScore < blurThreshold) {
      return ValidationResult(
        isValid: false,
        errorCode: 'IMAGE_TOO_BLURRY',
        message: 'Gambar terlalu buram. Pastikan fokus kamera tepat.',
      );
    }
    
    return ValidationResult(
      isValid: true,
      errorCode: null,
      message: null,
      image: image,
    );
  }
  
  // ==================== PREDIKSI CNN ====================
  
  Future<CnnPredictionResult> _predictCnn(img.Image image) async {
    // Resize ke 224x224 (ukuran input MobileNetV2)
    img.Image resized = img.copyResize(image, width: 224, height: 224);
    
    // Konversi ke tensor
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
    
    // Top 3 predictions untuk alternatif
    List<MapEntry<int, double>> sortedProbs = [];
    for (int i = 0; i < output[0].length; i++) {
      sortedProbs.add(MapEntry(i, output[0][i]));
    }
    sortedProbs.sort((a, b) => b.value.compareTo(a.value));
    
    List<Map<String, dynamic>> topPredictions = [];
    for (int i = 0; i < 3 && i < sortedProbs.length; i++) {
      final idx = sortedProbs[i].key;
      topPredictions.add({
        'label': _labels[idx],
        'confidence': sortedProbs[i].value,
      });
    }
    
    return CnnPredictionResult(
      label: predictedLabel,
      confidence: maxProb,
      allProbabilities: output[0],
      topPredictions: topPredictions,
    );
  }
  
  // ==================== PREDIKSI DENGAN TIMEOUT ====================
  
  Future<Prediction> predictWithTimeout(List<int> imageBytes) async {
    try {
      return await predict(imageBytes).timeout(
        const Duration(seconds: predictionTimeoutSeconds),
        onTimeout: () {
          debugPrint('Prediction timeout!');
          return Prediction(
            label: 'error',
            probability: 0.0,
            allProbabilities: const [],
            isFromCache: false,
            errorCode: 'TIMEOUT',
            errorMessage: 'Proses deteksi terlalu lama. Silakan coba gambar dengan resolusi lebih kecil (maksimal 3MB).',
          );
        },
      );
    } catch (e) {
      debugPrint('Prediction error: $e');
      return Prediction(
        label: 'error',
        probability: 0.0,
        allProbabilities: const [],
        isFromCache: false,
        errorCode: 'UNKNOWN_ERROR',
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }
  
  // ==================== PREDIKSI UTAMA ====================
  
  Future<Prediction> predict(List<int> imageBytes) async {
    // STEP 1: Validasi gambar
    final validation = validateImage(imageBytes);
    if (!validation.isValid) {
      debugPrint('Validation failed: ${validation.errorCode}');
      return Prediction(
        label: 'error',
        probability: 0.0,
        allProbabilities: const [],
        isFromCache: false,
        errorCode: validation.errorCode,
        errorMessage: validation.message,
      );
    }
    
    // STEP 2: Hitung hash untuk cache (gunakan byte asli, bukan yang sudah di-resize)
    final imageHash = _computeImageHash(imageBytes);
    debugPrint('Hash: ${imageHash.substring(0, 8)}...');
    
    // STEP 3: Cek cache di database
    try {
      final correction = await _db.findByHash(imageHash);
      if (correction != null) {
        final correctLabel = correction['label'] as String;
        debugPrint('[CACHE] Found: $correctLabel');
        
        return Prediction(
          label: correctLabel,
          probability: 0.95,
          allProbabilities: const [],
          isFromCache: true,
          isFromCorrection: true,
        );
      }
    } catch (dbError) {
      debugPrint('Database error: $dbError');
    }
    
    // STEP 4: Prediksi dengan CNN (gunakan image yang sudah di-resize dari validasi)
    debugPrint('[CNN] No cache, predicting...');
    final cnnResult = await _predictCnn(validation.image!);
    
    // STEP 5: Cek gambar bukan makanan
    if (cnnResult.confidence < nonFoodThreshold) {
      debugPrint('[CNN] Not food detected (confidence: ${cnnResult.confidence.toStringAsFixed(2)})');
      return Prediction(
        label: 'not_food',
        probability: cnnResult.confidence,
        allProbabilities: cnnResult.allProbabilities,
        isFromCache: false,
        errorCode: 'NOT_FOOD',
        errorMessage: 'Gambar tidak dikenali sebagai makanan. Pastikan foto berisi makanan yang jelas.',
        topPredictions: cnnResult.topPredictions,
      );
    }
    
    // STEP 6: Return hasil normal
    final isLowConf = cnnResult.confidence < lowConfidenceThreshold;
    debugPrint('[CNN] Result: ${cnnResult.label} (${(cnnResult.confidence * 100).toStringAsFixed(1)}%)${isLowConf ? " ⚠️ low confidence" : ""}');
    
    return Prediction(
      label: cnnResult.label,
      probability: cnnResult.confidence,
      allProbabilities: cnnResult.allProbabilities,
      isFromCache: false,
      isLowConfidence: isLowConf,
      topPredictions: cnnResult.topPredictions,
    );
  }
  
  // ==================== BELAJAR DARI KESALAHAN ====================
  
  Future<void> learnFromFeedback({
    required List<int> imageBytes,
    required String originalPrediction,
    required String correctLabel,
  }) async {
    try {
      // Validasi sebelum menyimpan
      final validation = validateImage(imageBytes);
      if (!validation.isValid) {
        debugPrint('Cannot learn from invalid image: ${validation.errorCode}');
        return;
      }
      
      final imageHash = _computeImageHash(imageBytes);
      debugPrint('Learning hash: ${imageHash.substring(0, 8)}...');
      
      // Cek existing
      final existing = await _db.findByHash(imageHash);
      
      if (existing != null) {
        final existingLabel = existing['label'] as String;
        if (existingLabel == correctLabel) {
          debugPrint('Already correct, skipping...');
          return;
        }
        debugPrint('Updating: $existingLabel → $correctLabel');
      }
      
      // Simpan atau update
      await _db.insertOrUpdateCorrection(
        imageHash: imageHash,
        label: correctLabel,
        originalPrediction: originalPrediction,
      );
      
      final count = await _db.getCount();
      debugPrint('Learned! Cache size: $count');
      
    } catch (e) {
      debugPrint('Error learning: $e');
    }
  }
  
  // ==================== UTILITY ====================
  
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

// ==================== RESULT CLASSES ====================

class ValidationResult {
  final bool isValid;
  final String? errorCode;
  final String? message;
  final img.Image? image;
  
  ValidationResult({
    required this.isValid,
    this.errorCode,
    this.message,
    this.image,
  });
}

class CnnPredictionResult {
  final String label;
  final double confidence;
  final List<double> allProbabilities;
  final List<Map<String, dynamic>> topPredictions;
  
  CnnPredictionResult({
    required this.label,
    required this.confidence,
    required this.allProbabilities,
    required this.topPredictions,
  });
}

class Prediction {
  final String label;
  final double probability;
  final List<double> allProbabilities;
  final bool isFromCache;
  final bool isFromCorrection;
  final bool isLowConfidence;
  final String? errorCode;
  final String? errorMessage;
  final List<Map<String, dynamic>>? topPredictions;
  
  const Prediction({
    required this.label,
    required this.probability,
    required this.allProbabilities,
    this.isFromCache = false,
    this.isFromCorrection = false,
    this.isLowConfidence = false,
    this.errorCode,
    this.errorMessage,
    this.topPredictions,
  });
  
  bool get hasError => errorCode != null;
  bool get isNotFood => errorCode == 'NOT_FOOD';
}