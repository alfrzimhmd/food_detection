// HYBRID CLASSIFIER - CNN + SQLite Cache + Validasi Gambar :
// 1. Deteksi makanan dengan CNN (MobileNetV2, 19 kelas)
// 2. Cache koreksi user di SQLite (belajar dari kesalahan)
// 3. Validasi gambar ringan (keburaman sampling, ukuran, format)
// 4. Deteksi gambar bukan makanan (confidence threshold)
// 5. Timeout untuk mencegah freeze
// 6. Optimasi memory (resize gambar besar sebelum diproses di Isolate)
// 7. Blur detection dengan sampling (efisien & cepat di Isolate)

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import '../data/database_manager.dart';

class HybridFoodClassifier {
  late Interpreter _cnnModel;
  late List<String> _labels;
  late DatabaseManager _db;
  
  static const int numClasses = 19;
  static const double nonFoodThreshold = 0.50;      // < 50% = bukan makanan
  static const double lowConfidenceThreshold = 0.70; // < 70% = warning
  static const int predictionTimeoutSeconds = 8;     // Toleransi sedikit lebih longgar untuk Isolate
  
  Future<void> loadModel() async {
    try {
      _cnnModel = await Interpreter.fromAsset('assets/food_indonesia_model.tflite');
      debugPrint('CNN Model loaded!');
      
      String labelsData = await rootBundle.loadString('assets/labels_indonesia.txt');
      _labels = labelsData.split('\n');
      _labels = _labels.where((label) => label.trim().isNotEmpty).toList();
      debugPrint('Labels loaded: ${_labels.length} classes');
      
      _db = DatabaseManager();
      await _db.init();
      
      final count = await _db.getCorrectionsCount();
      debugPrint('Correction cache loaded: $count entries');
    } catch (e) {
      debugPrint('Error loading model: $e');
      rethrow;
    }
  }
  
  String _computeImageHash(List<int> imageBytes) {
    var hash = 0;
    for (int i = 0; i < imageBytes.length; i++) {
      hash = (hash * 31 + imageBytes[i]) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  // ===========================================================================
  // BACKGROUND ISOLATE PIPELINE (Dijalankan di luar Isolate Utama)
  // ===========================================================================
  
  /// Fungsi tingkat atas / statis untuk menangani preprocessing gambar di thread terpisah.
  /// Ini membebaskan Isolate Utama dari proses decoding & manipulasi piksel yang lambat.
  static Map<String, dynamic> _preprocessImageTask(List<int> imageBytes) {
    const int minFileSize = 5000; // 5KB
    const int maxFileSizeForProcessing = 3 * 1024 * 1024; // 3MB
    const int minImageDimension = 50;
    const int maxImageDimensionForProcessing = 800;
    const double blurThreshold = 250.0;
    const int blurSampleRate = 20;

    // 1. Cek ukuran file
    if (imageBytes.length < minFileSize) {
      return {
        'isValid': false,
        'errorCode': 'FILE_TOO_SMALL',
        'message': 'File gambar terlalu kecil atau mungkin rusak.',
      };
    }
    
    if (imageBytes.length > maxFileSizeForProcessing) {
      return {
        'isValid': false,
        'errorCode': 'FILE_TOO_LARGE',
        'message': 'File gambar terlalu besar (maksimal 3MB). Silakan pilih gambar dengan resolusi lebih rendah.',
      };
    }

    // 2. Decode Gambar
    final uint8list = Uint8List.fromList(imageBytes);
    final image = img.decodeImage(uint8list);
    if (image == null) {
      return {
        'isValid': false,
        'errorCode': 'INVALID_IMAGE',
        'message': 'File tidak dapat dibaca sebagai gambar. Pastikan format file JPG/PNG.',
      };
    }

    // 3. Resize jika melebihi batas resolusi pengolahan
    img.Image processedImage = image;
    if (image.width > maxImageDimensionForProcessing || image.height > maxImageDimensionForProcessing) {
      double scale = maxImageDimensionForProcessing / max(image.width, image.height);
      int targetWidth = (image.width * scale).toInt();
      int targetHeight = (image.height * scale).toInt();
      processedImage = img.copyResize(image, width: targetWidth, height: targetHeight);
    }

    // 4. Validasi dimensi minimum
    if (processedImage.width < minImageDimension || processedImage.height < minImageDimension) {
      return {
        'isValid': false,
        'errorCode': 'IMAGE_TOO_SMALL',
        'message': 'Gambar terlalu kecil (minimal 50x50 piksel).',
      };
    }

    // 5. Hitung tingkat keburaman dengan Sampling grayscale
    final gray = img.grayscale(processedImage);
    double sum = 0;
    double sumSq = 0;
    int count = 0;
    
    for (int y = 0; y < gray.height; y += blurSampleRate) {
      for (int x = 0; x < gray.width; x += blurSampleRate) {
        final pixel = gray.getPixel(x, y);
        final intensity = pixel.r.toDouble();
        sum += intensity;
        sumSq += intensity * intensity;
        count++;
      }
    }
    
    double variance = 1000.0;
    if (count > 0) {
      final mean = sum / count;
      variance = (sumSq / count) - (mean * mean);
    }

    if (variance < blurThreshold) {
      return {
        'isValid': false,
        'errorCode': 'IMAGE_TOO_BLURRY',
        'message': 'Gambar terlalu buram. Pastikan fokus kamera tepat.',
      };
    }

    // 6. Siapkan Tensor Input MobileNetV2 (224x224x3) secara langsung
    final resized = img.copyResize(processedImage, width: 224, height: 224);
    final inputBuffer = Float32List(1 * 224 * 224 * 3);
    int index = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        inputBuffer[index++] = pixel.r / 255.0;
        inputBuffer[index++] = pixel.g / 255.0;
        inputBuffer[index++] = pixel.b / 255.0;
      }
    }

    return {
      'isValid': true,
      'inputBuffer': inputBuffer,
    };
  }

  // ===========================================================================
  // PREDIKSI DENGAN TIMEOUT & REAKTIVITAS
  // ===========================================================================
  
  Future<Prediction> predictWithTimeout(List<int> imageBytes) async {
    try {
      return await predict(imageBytes).timeout(
        const Duration(seconds: predictionTimeoutSeconds),
        onTimeout: () {
          debugPrint('Prediction timeout reached!');
          return const Prediction(
            label: 'error',
            probability: 0.0,
            allProbabilities: [],
            isFromCache: false,
            errorCode: 'TIMEOUT',
            errorMessage: 'Proses deteksi terlalu lama. Silakan coba gambar dengan resolusi lebih kecil (maksimal 3MB).',
          );
        },
      );
    } catch (e) {
      debugPrint('Prediction error: $e');
      return const Prediction(
        label: 'error',
        probability: 0.0,
        allProbabilities: [],
        isFromCache: false,
        errorCode: 'UNKNOWN_ERROR',
        errorMessage: 'Terjadi kesalahan sistem saat mendeteksi gambar.',
      );
    }
  }
  
  Future<Prediction> predict(List<int> imageBytes) async {
    // STEP 1: Hitung hash gambar asli (Sangat cepat di thread utama)
    final imageHash = _computeImageHash(imageBytes);
    debugPrint('Image Hash: ${imageHash.substring(0, 8)}...');
    
    // STEP 2: Periksa cache database terlebih dahulu
    try {
      final correction = await _db.findByHash(imageHash);
      if (correction != null) {
        final correctLabel = correction['label'] as String;
        debugPrint('[CACHE] Match found in SQLite: $correctLabel');
        return Prediction(
          label: correctLabel,
          probability: 0.95,
          allProbabilities: const [],
          isFromCache: true,
          isFromCorrection: true,
        );
      }
    } catch (dbError) {
      debugPrint('Database cache query error: $dbError');
    }
    
    // STEP 3: Delegasikan seluruh komputasi berat gambar ke Background Isolate (compute)
    debugPrint('[Isolate] Delegating preprocessing tasks...');
    final preprocessResult = await compute(_preprocessImageTask, imageBytes);
    
    if (!preprocessResult['isValid']) {
      final errorCode = preprocessResult['errorCode'] as String;
      final message = preprocessResult['message'] as String;
      debugPrint('[Isolate] Preprocessing validation failed: $errorCode');
      return Prediction(
        label: 'error',
        probability: 0.0,
        allProbabilities: const [],
        isFromCache: false,
        errorCode: errorCode,
        errorMessage: message,
      );
    }
    
    // STEP 4: Jalankan Inferensi Model AI (C++ native run, instan di thread utama)
    debugPrint('[CNN] Running TFLite inference...');
    final Float32List inputBuffer = preprocessResult['inputBuffer'];
    var inputTensor = inputBuffer.reshape([1, 224, 224, 3]);
    var output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);
    
    try {
      _cnnModel.run(inputTensor, output);
    } catch (e) {
      debugPrint('[CNN] Inference runtime error: $e');
      return const Prediction(
        label: 'error',
        probability: 0.0,
        allProbabilities: [],
        isFromCache: false,
        errorCode: 'INFERENCE_ERROR',
        errorMessage: 'Model AI gagal memproses data gambar.',
      );
    }
    
    // STEP 5: Evaluasi Hasil Inferensi Logits
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
    
    // Ambil Top 3 alternatif prediksi
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
    
    // Evaluasi jika gambar bukan makanan
    if (maxProb < nonFoodThreshold) {
      debugPrint('[CNN] Confidence score low (${maxProb.toStringAsFixed(2)}). Not food detected.');
      return Prediction(
        label: 'not_food',
        probability: maxProb,
        allProbabilities: output[0],
        isFromCache: false,
        errorCode: 'NOT_FOOD',
        errorMessage: 'Gambar tidak dikenali sebagai makanan. Pastikan foto berisi makanan yang jelas.',
        topPredictions: topPredictions,
      );
    }
    
    final isLowConf = maxProb < lowConfidenceThreshold;
    debugPrint('[CNN] Result: $predictedLabel (${(maxProb * 100).toStringAsFixed(1)}%)${isLowConf ? " ⚠️ low confidence" : ""}');
    
    return Prediction(
      label: predictedLabel,
      probability: maxProb,
      allProbabilities: output[0],
      isFromCache: false,
      isLowConfidence: isLowConf,
      topPredictions: topPredictions,
    );
  }
  
  // ===========================================================================
  // BELAJAR DARI MASUKAN PENGGUNA (FEEDBACK)
  // ===========================================================================
  
  Future<void> learnFromFeedback({
    required List<int> imageBytes,
    required String originalPrediction,
    required String correctLabel,
  }) async {
    try {
      // Validasi gambar di tingkat Isolate sebelum dipelajari
      final preprocessResult = await compute(_preprocessImageTask, imageBytes);
      if (!preprocessResult['isValid']) {
        debugPrint('[Learning] Abandoned. Preprocessing failed.');
        return;
      }
      
      final imageHash = _computeImageHash(imageBytes);
      final existing = await _db.findByHash(imageHash);
      
      if (existing != null) {
        final existingLabel = existing['label'] as String;
        if (existingLabel == correctLabel) {
          return;
        }
        debugPrint('[Learning] Updating correction cache: $existingLabel → $correctLabel');
      }
      
      await _db.insertOrUpdateCorrection(
        imageHash: imageHash,
        label: correctLabel,
        originalPrediction: originalPrediction,
      );
      
      final count = await _db.getCorrectionsCount();
      debugPrint('[Learning] Feedback successfully saved! Cache size: $count');
    } catch (e) {
      debugPrint('Error learning from feedback: $e');
    }
  }
  
  // ===========================================================================
  // UTILITY
  // ===========================================================================
  
  List<String> get labels => _labels;
  
  Future<int> getCacheSize() async {
    try {
      return await _db.getCorrectionsCount();
    } catch (e) {
      return 0;
    }
  }
  
  Future<void> resetCache() async {
    await _db.deleteAllCorrections();
  }
  
  void dispose() {
    _cnnModel.close();
  }
}

// ===========================================================================
// DATA CLASSES
// ===========================================================================

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