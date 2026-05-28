// lib/screens/scan_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/hybrid_classifier.dart';
import '../data/database_manager.dart';
import '../data/nutrition_data.dart';
import '../providers/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/text_style_helper.dart';

// ─────────────────────────────────────────────
//  SCAN SCREEN
// ─────────────────────────────────────────────
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final HybridFoodClassifier _classifier = HybridFoodClassifier();
  final ImagePicker _picker = ImagePicker();

  bool _isLoadingModel = true;
  bool _isPredicting = false;
  File? _selectedImage;
  Prediction? _predictionResult;
  int _processingStep = 0;
  bool _showCatalogue = true;
  
  // 🔥 Untuk menyimpan data sementara
  List<int>? _pendingImageBytes;
  // ignore: unused_field
  String? _pendingImagePath;  // Digunakan untuk menyimpan path gambar sementara, akan digunakan saat update history
  int? _lastSavedHistoryId;

  // Result card animation
  late final AnimationController _resultCtrl;
  late final Animation<double> _resultFade;
  late final Animation<Offset> _resultSlide;

  // Scan animation controllers
  AnimationController? _scanLineCtrl;
  AnimationController? _pulseCtrl;
  AnimationController? _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _resultFade = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    _loadModel();
  }

  void _startScanAnimations() {
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  void _stopScanAnimations() {
    _scanLineCtrl?.dispose();
    _pulseCtrl?.dispose();
    _rotateCtrl?.dispose();
    _scanLineCtrl = null;
    _pulseCtrl = null;
    _rotateCtrl = null;
  }

  @override
  void dispose() {
    _resultCtrl.dispose();
    _stopScanAnimations();
    _classifier.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      await _classifier.loadModel();
    } catch (e) {
      debugPrint('Model load error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingModel = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      final size = await picked.length();
      if (size > 3 * 1024 * 1024) {
        if (mounted) {
          _showSnackBar('Gambar terlalu besar (maks 3 MB)', isError: true);
        }
        return;
      }

      _resultCtrl.reset();
      setState(() {
        _selectedImage = File(picked.path);
        _predictionResult = null;
        _processingStep = 0;
        _pendingImageBytes = null;
        _pendingImagePath = null;
        _lastSavedHistoryId = null;
      });
    } catch (e) {
      debugPrint('Pick image error: $e');
      if (mounted) {
        _showSnackBar('Gagal mengambil gambar', isError: true);
      }
    }
  }

  // 🔥 Method untuk menyimpan history dengan hasil prediksi awal
  Future<void> _saveInitialScanHistory({
    required String label,
    required String imagePath,
  }) async {
    final fd = NutritionData.getFoodData(label);
    final appState = Provider.of<AppState>(context, listen: false);
    
    debugPrint('💾 Saving initial scan history: label=$label');
    
    final id = await appState.saveScanHistory(
      imagePath: imagePath,
      label: label,
      indonesianName: fd.indonesianName,
      calories: fd.calories,
      protein: fd.protein,
      carbs: fd.carbs,
      fat: fd.fat,
      fiber: fd.fiber,
      sugar: fd.sugar,
      sodium: fd.sodium,
      healthLevel: fd.healthLevel.toString().split('.').last,
      healthTip: fd.healthTip,
      warning: fd.warning,
    );
    
    _lastSavedHistoryId = id;
    debugPrint('✅ Initial scan history saved with id=$id');
  }

  // 🔥 Method untuk mengupdate history dengan hasil koreksi
  Future<void> _updateHistoryWithCorrection({
    required String correctedLabel,
    required int historyId,
  }) async {
    final fd = NutritionData.getFoodData(correctedLabel);
    final dbManager = DatabaseManager();
    
    debugPrint('✏️ Updating history id=$historyId with correction: $correctedLabel');
    
    final db = await dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'scan_history',
      {
        'label': correctedLabel,
        'indonesian_name': fd.indonesianName,
        'calories': fd.calories,
        'protein': fd.protein,
        'carbs': fd.carbs,
        'fat': fd.fat,
        'fiber': fd.fiber,
        'sugar': fd.sugar,
        'sodium': fd.sodium,
        'health_level': fd.healthLevel.toString().split('.').last,
        'health_tip': fd.healthTip,
        'warning': fd.warning,
        'scanned_at': now,
      },
      where: 'id = ?',
      whereArgs: [historyId],
    );
    
    debugPrint('✅ History updated with correction');
    
    // Refresh AppState agar UI terupdate
    if (mounted) {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.refresh();
    }
  }

  Future<void> _predictImage() async {
    if (_selectedImage == null) {
      _showSnackBar('Pilih gambar terlebih dahulu', isError: true);
      return;
    }

    _startScanAnimations();
    setState(() {
      _isPredicting = true;
      _processingStep = 1;
      _pendingImageBytes = null;
      _pendingImagePath = null;
      _lastSavedHistoryId = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _processingStep = 2);

      final bytes = await _selectedImage!.readAsBytes();
      _pendingImageBytes = bytes;
      _pendingImagePath = _selectedImage!.path;

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _processingStep = 3);

      final prediction = await _classifier.predictWithTimeout(bytes);
      if (!mounted) return;

      // Simpan history dengan prediksi awal
      if (!prediction.hasError && !prediction.isNotFood) {
        await _saveInitialScanHistory(
          label: prediction.label,
          imagePath: _selectedImage!.path,
        );
      }

      _stopScanAnimations();
      setState(() {
        _predictionResult = prediction;
        _isPredicting = false;
        _processingStep = 0;
      });

      if (prediction.hasError) {
        if (prediction.isNotFood) {
          if (mounted) _showNotFoodDialog();
        } else {
          if (mounted) _showErrorDialogWithContext(context, prediction.errorMessage ?? 'Terjadi kesalahan.');
        }
        _resetAll();
      } else {
        _resultCtrl.forward();
      }
    } catch (e) {
      debugPrint('Predict error: $e');
      _stopScanAnimations();
      if (mounted) {
        setState(() {
          _isPredicting = false;
          _processingStep = 0;
        });
        _showErrorDialogWithContext(context, 'Terjadi kesalahan. Silakan coba lagi.');
      }
    }
  }

  void _resetAll() {
    _resultCtrl.reset();
    _stopScanAnimations();
    setState(() {
      _selectedImage = null;
      _predictionResult = null;
      _processingStep = 0;
      _isPredicting = false;
      _pendingImageBytes = null;
      _pendingImagePath = null;
      _lastSavedHistoryId = null;
    });
  }

  List<Map<String, String>> _getFoodCatalogue() {
    if (_classifier.labels.isEmpty) return [];
    
    final emojiMap = {
      'ayam_goreng': '🍗', 'bakso': '🍢', 'burger': '🍔',
      'gado_gado': '🥗', 'gudeg': '🍛', 'gulai_ikan': '🐟',
      'ikan_goreng': '🐠', 'kentang_goreng': '🍟', 'mie': '🍜',
      'nasi_goreng': '🍳', 'nasi_padang': '🍱', 'pempek': '🦑',
      'pizza': '🍕', 'rawon': '🥣', 'rendang': '🥩',
      'sate': '🍢', 'soto': '🍲', 'telur_balado': '🥚', 'telur_dadar': '🍳',
    };
    
    return _classifier.labels.map((label) {
      return {
        'label': label,
        'name': NutritionData.getFoodData(label).indonesianName,
        'emoji': emojiMap[label] ?? '🍽️',
      };
    }).toList();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: TextStyleHelper.bold(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showErrorDialogWithContext(BuildContext context, String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Gagal', style: TextStyleHelper.titleMedium),
        content: Text(msg, style: TextStyleHelper.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAll();
            },
            child: Text(
              'OK',
              style: TextStyleHelper.bold(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotFoodDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Bukan Makanan', style: TextStyleHelper.titleMedium),
        content: Text(
          'Gambar yang Anda unggah tidak dikenali sebagai makanan. Coba foto makanan dengan pencahayaan yang lebih baik.',
          style: TextStyleHelper.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyleHelper.bold(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showCorrectionDialog() {
    if (_predictionResult == null || _predictionResult!.hasError) {
      _showSnackBar('Tidak ada prediksi untuk dikoreksi.', isError: true);
      return;
    }

    final rootContext = context;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CorrectionSheet(
        classifier: _classifier,
        selectedImage: _selectedImage,
        prediction: _predictionResult!,
        onCorrected: (correctedLabel, sheetContext) async {
          debugPrint('✏️ Correction callback received: $correctedLabel');
          
          // 🔥 Tampilkan success dialog IMMEDIATELY (tanpa nunggu proses selesai)
          if (mounted) {
            _showSuccessCorrectionDialog(rootContext, correctedLabel);
          }
          
          // Jalankan proses penyimpanan di background (tanpa nunggu)
          // Gunakan unawaited agar tidak blocking UI
          unawaited(_processCorrectionInBackground(correctedLabel));
        },
      ),
    );
  }

  // 🔥 Method baru untuk proses background
  Future<void> _processCorrectionInBackground(String correctedLabel) async {
    try {
      // 1. Simpan koreksi ke database corrections
      if (_pendingImageBytes != null) {
        await _classifier.learnFromFeedback(
          imageBytes: _pendingImageBytes!,
          originalPrediction: _predictionResult!.label,
          correctLabel: correctedLabel,
        );
      }
      
      // 2. Update history yang sudah tersimpan
      if (_lastSavedHistoryId != null) {
        await _updateHistoryWithCorrection(
          correctedLabel: correctedLabel,
          historyId: _lastSavedHistoryId!,
        );
      }
      
      debugPrint('✅ Background correction process completed');
    } catch (e) {
      debugPrint('❌ Background correction error: $e');
      if (mounted) {
        _showSnackBar('Gagal menyimpan koreksi di background', isError: true);
      }
    }
  }

  void _showSuccessCorrectionDialog(BuildContext context, String correctedLabel) {
    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, cannot show dialog');
      return;
    }
    
    final correctedFood = NutritionData.getFoodData(correctedLabel);
    final originalLabel = _predictionResult!.label;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width - 40,
          constraints: const BoxConstraints(
            maxHeight: 500, // Batasi tinggi maksimal
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon sukses
                Container(
                  width: 72,
                  height: 72,
                  margin: const EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.success, AppColors.carbs],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Koreksi Tersimpan!',
                  style: TextStyleHelper.headline3.copyWith(
                    fontSize: 22,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Terima kasih atas koreksi Anda!',
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.titleMedium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Detail koreksi - PERBAIKAN UNTUK TEKS PANJANG
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Label Sebelum
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.fat.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: AppColors.fat, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sebelum',
                                  style: TextStyleHelper.captionSmall.copyWith(
                                    color: AppColors.textLight,
                                  ),
                                ),
                                Text(
                                  originalLabel,
                                  style: TextStyleHelper.bodySmall.copyWith(
                                    color: AppColors.textDark,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Panah
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Label Sesudah
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sesudah',
                                  style: TextStyleHelper.captionSmall.copyWith(
                                    color: AppColors.textLight,
                                  ),
                                ),
                                Text(
                                  correctedFood.indonesianName,
                                  style: TextStyleHelper.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Pesan pembelajaran
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.glow.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Model AI akan belajar dari koreksi ini untuk meningkatkan akurasi deteksi.',
                          style: TextStyleHelper.captionSmall.copyWith(
                            color: AppColors.textMedium,
                            height: 1.4,
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Tombol
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            if (mounted) _resetAll();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Kembali',
                            style: TextStyleHelper.labelMedium.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            if (mounted) _resetAll();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Scan Lagi',
                            style: TextStyleHelper.labelMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Coba scan ulang gambar yang sama untuk melihat hasilnya',
                    textAlign: TextAlign.center,
                    style: TextStyleHelper.captionSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                    maxLines: 2,
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_isLoadingModel)
                  _buildModelLoading()
                else ...[
                  const SizedBox(height: 20),
                  _buildCameraCard(),
                  const SizedBox(height: 16),
                  if (_predictionResult != null)
                    FadeTransition(
                      opacity: _resultFade,
                      child: SlideTransition(
                        position: _resultSlide,
                        child: _buildResultCard(_predictionResult!),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildCatalogueHeader(),
                  const SizedBox(height: 12),
                  if (_showCatalogue) _buildCatalogueSection(),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'Scan Makanan',
            style: TextStyleHelper.titleMedium.copyWith(
              color: Colors.white,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogueHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.glow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.restaurant_menu_rounded, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Makanan yang Dapat Dideteksi',
                style: TextStyleHelper.titleSmall.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${_classifier.labels.length} jenis makanan didukung',
                style: TextStyleHelper.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _showCatalogue = !_showCatalogue),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.glow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  _showCatalogue ? 'Sembunyikan' : 'Tampilkan',
                  style: TextStyleHelper.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showCatalogue ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelLoading() {
    return SizedBox(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.glow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.memory_rounded, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 20),
          Text(
            'Memuat Model AI...',
            style: TextStyleHelper.titleMedium.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mohon tunggu sebentar',
            style: TextStyleHelper.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.divider,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.glow,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Gambar',
                      style: TextStyleHelper.titleSmall.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      _selectedImage == null
                          ? 'Foto atau pilih dari galeri'
                          : _isPredicting ? 'Sedang menganalisa...' : 'Gambar siap dianalisa',
                      style: TextStyleHelper.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: double.infinity,
                height: 230,
                child: _isPredicting
                    ? _buildScanOverlay()
                    : _selectedImage != null
                        ? _buildImagePreview()
                        : _buildEmptyPlaceholder(),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Kamera',
                    icon: Icons.camera_alt_rounded,
                    isPrimary: true,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    label: 'Galeri',
                    icon: Icons.photo_library_rounded,
                    isPrimary: false,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_predictionResult == null)
              _buildAnalyzeButton()
            else
              _buildResetButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      color: AppColors.primaryExtraLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.glow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.add_photo_alternate_rounded, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada gambar',
            style: TextStyleHelper.titleMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ambil foto atau pilih dari galeri',
            style: TextStyleHelper.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(_selectedImage!, fit: BoxFit.cover),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF4ADE80)),
                const SizedBox(width: 5),
                Text(
                  'Gambar siap',
                  style: TextStyleHelper.captionSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_selectedImage != null)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              AppColors.primaryDark.withValues(alpha: 0.72),
              BlendMode.darken,
            ),
            child: Image.file(_selectedImage!, fit: BoxFit.cover),
          ),

        if (_scanLineCtrl != null)
          AnimatedBuilder(
            animation: _scanLineCtrl!,
            builder: (_, child) {
              final y = _scanLineCtrl!.value;
              return Positioned(
                top: 230 * y,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accent.withValues(alpha: 0.8),
                        AppColors.accent,
                        AppColors.accent.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: CustomPaint(
              painter: _BracketPainter(color: AppColors.accent),
            ),
          ),
        ),

        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_rotateCtrl != null)
                AnimatedBuilder(
                  animation: _rotateCtrl!,
                  builder: (_, child) => Transform.rotate(
                    angle: _rotateCtrl!.value * 2 * math.pi,
                    child: child,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.transparent),
                  ),
                ),

              if (_pulseCtrl != null)
                AnimatedBuilder(
                  animation: _pulseCtrl!,
                  builder: (_, child) => Transform.scale(
                    scale: 0.88 + 0.14 * _pulseCtrl!.value,
                    child: Opacity(
                      opacity: 0.7 + 0.3 * _pulseCtrl!.value,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 64, height: 64),

              const SizedBox(height: 20),

              _buildStepLabel(),
              const SizedBox(height: 16),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final active = i == (_processingStep - 1).clamp(0, 2);
                  final done = i < (_processingStep - 1).clamp(0, 2);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: done
                          ? AppColors.accent
                          : active
                              ? Colors.white
                              : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepLabel() {
    final steps = ['Membaca gambar...', 'Menganalisa fitur...', 'Mengidentifikasi makanan...'];
    final idx = (_processingStep - 1).clamp(0, 2);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        steps[idx],
        key: ValueKey(idx),
        style: TextStyleHelper.labelLarge.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isPredicting ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: AppColors.divider, width: 1.5),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyleHelper.labelLarge.copyWith(
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _isPredicting ? null : _predictImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E8B57), AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.38),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _isPredicting
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Analisa Sekarang',
                    style: TextStyleHelper.labelLarge.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                ],
              ),
      ),
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: _resetAll,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              'Reset & Scan Lagi',
              style: TextStyleHelper.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Prediction prediction) {
    final fd = NutritionData.getFoodData(prediction.label);
    final healthLevel = fd.healthLevel;
    final healthColor = NutritionData.getHealthColor(healthLevel);
    final healthIcon = NutritionData.getHealthIcon(healthLevel);
    final healthText = NutritionData.getHealthText(healthLevel);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: AppColors.resultHeaderGradient,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          prediction.isFromCache ? Icons.memory_rounded : Icons.auto_awesome_rounded,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          prediction.isFromCache ? 'Dari Memori Koreksi' : 'Hasil Deteksi AI',
                          style: TextStyleHelper.captionSmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    fd.indonesianName,
                    textAlign: TextAlign.center,
                    style: TextStyleHelper.displayMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HeaderBadge(
                        color: healthColor,
                        icon: healthIcon,
                        label: healthText,
                      ),
                      const SizedBox(width: 10),
                      _HeaderBadge(
                        color: Colors.white70,
                        icon: Icons.bar_chart_rounded,
                        label: '${(prediction.probability * 100).toStringAsFixed(1)}%',
                        textColor: Colors.white70,
                        bgColor: Colors.white.withValues(alpha: 0.13),
                        borderColor: Colors.white.withValues(alpha: 0.0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.calorieGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.calories.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.calories.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.warning,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Kalori',
                              style: TextStyleHelper.labelMedium.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${fd.calories}',
                                    style: TextStyleHelper.displayLarge.copyWith(
                                      fontSize: 32,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' kcal',
                                    style: TextStyleHelper.titleSmall.copyWith(
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.calories.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'per 100g',
                          style: TextStyleHelper.labelSmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _SectionLabel(icon: Icons.pie_chart_rounded, label: 'Nutrisi per 100g'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _NutrientTile(
                      Icons.fitness_center_rounded,
                      'Protein',
                      '${fd.protein.toStringAsFixed(1)}g',
                      AppColors.protein,
                    ),
                    _NutrientTile(
                      Icons.grain_rounded,
                      'Karbo',
                      '${fd.carbs.toStringAsFixed(1)}g',
                      AppColors.carbs,
                    ),
                    _NutrientTile(
                      Icons.water_drop_rounded,
                      'Lemak',
                      '${fd.fat.toStringAsFixed(1)}g',
                      AppColors.fat,
                    ),
                    _NutrientTile(
                      Icons.spa_rounded,
                      'Serat',
                      '${fd.fiber.toStringAsFixed(1)}g',
                      AppColors.fiber,
                    ),
                    _NutrientTile(
                      Icons.bubble_chart_rounded,
                      'Gula',
                      '${fd.sugar.toStringAsFixed(1)}g',
                      AppColors.sugar,
                    ),
                    _NutrientTile(
                      Icons.science_rounded,
                      'Sodium',
                      '${fd.sodium.toStringAsFixed(0)}mg',
                      AppColors.sodium,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _SectionLabel(icon: Icons.lightbulb_rounded, label: 'Info Kesehatan'),
                const SizedBox(height: 10),
                _InfoBanner(
                  bgColor: const Color(0xFFF0FAF4),
                  borderColor: AppColors.glow,
                  icon: Icons.lightbulb_rounded,
                  iconColor: AppColors.primary,
                  title: 'Tips Konsumsi',
                  body: fd.healthTip,
                ),
                const SizedBox(height: 10),
                _InfoBanner(
                  bgColor: const Color(0xFFFFF8F0),
                  borderColor: const Color(0xFFFFDDC4),
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.warning,
                  title: 'Perhatian',
                  body: fd.warning,
                ),

                const SizedBox(height: 20),

                _SectionLabel(icon: Icons.feedback_rounded, label: 'Apakah deteksi ini benar?'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FeedbackButton(
                        label: 'Benar',
                        icon: Icons.thumb_up_rounded,
                        color: AppColors.carbs,
                        onTap: () {
                          _showSnackBar('Terima kasih! Feedback Anda membantu.');
                          _resetAll();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FeedbackButton(
                        label: 'Salah',
                        icon: Icons.thumb_down_rounded,
                        color: AppColors.fat,
                        filled: true,
                        onTap: _showCorrectionDialog,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogueSection() {
    final catalogue = _getFoodCatalogue();
    
    if (catalogue.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: catalogue.length,
          itemBuilder: (_, i) {
            final food = catalogue[i];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 1.2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(food['emoji']!, style: TextStyleHelper.displayMedium.copyWith(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    food['name']!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleHelper.labelSmall.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _BracketPainter extends CustomPainter {
  final Color color;
  const _BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 22.0;
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - len, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BracketPainter o) => o.color != color;
}

class _HeaderBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Color? textColor;
  final Color? bgColor;
  final Color? borderColor;

  const _HeaderBadge({
    required this.color,
    required this.icon,
    required this.label,
    this.textColor,
    this.bgColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor ?? color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor ?? color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyleHelper.labelMedium.copyWith(
              color: textColor ?? color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyleHelper.titleMedium.copyWith(
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _NutrientTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _NutrientTile(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyleHelper.titleMedium.copyWith(
              fontSize: 14,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyleHelper.captionSmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final Color bgColor, borderColor, iconColor;
  final IconData icon;
  final String title, body;
  const _InfoBanner({
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyleHelper.titleSmall.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyleHelper.bodySmall.copyWith(
              height: 1.55,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: filled ? color : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: filled ? null : Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: filled ? Colors.white : color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyleHelper.labelLarge.copyWith(
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorrectionSheet extends StatelessWidget {
  final HybridFoodClassifier classifier;
  final File? selectedImage;
  final Prediction prediction;
  final void Function(String label, BuildContext context) onCorrected; 

  const _CorrectionSheet({
    required this.classifier,
    required this.selectedImage,
    required this.prediction,
    required this.onCorrected,
  });

  @override
  Widget build(BuildContext context) {
    final labels = classifier.labels;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.fat.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.edit_rounded, size: 18, color: AppColors.fat),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koreksi Deteksi',
                      style: TextStyleHelper.titleSmall.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Pilih makanan yang sebenarnya',
                      style: TextStyleHelper.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            height: 1,
            color: AppColors.divider,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: labels.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (ctx, i) {
                final label = labels[i];
                final fd = NutritionData.getFoodData(label);
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: AppColors.background,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.glow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        fd.indonesianName.isNotEmpty ? fd.indonesianName[0] : '?',
                        style: TextStyleHelper.headline4.copyWith(
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    fd.indonesianName,
                    style: TextStyleHelper.titleSmall.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: Text(
                    label,
                    style: TextStyleHelper.captionSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: const Text('Konfirmasi Koreksi'),
                        content: Text(
                          'Apakah gambar ini adalah ${fd.indonesianName}?\n\nModel akan belajar dari koreksi ini.',
                          style: TextStyleHelper.bodyMedium,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              onCorrected(label, context);
                            },
                            child: Text(
                              'Ya, Benar',
                              style: TextStyleHelper.bold(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}