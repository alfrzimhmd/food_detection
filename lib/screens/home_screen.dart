import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/hybrid_classifier.dart';
import '../data/nutrition_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final HybridFoodClassifier _classifier = HybridFoodClassifier();
  bool _isLoading = true;
  bool _isPredicting = false;
  File? _selectedImage;
  Prediction? _predictionResult;
  bool _isFoodListExpanded = false;
  
  // ==================== ANIMASI PROSES ====================
  // 0 = idle, 1 = membaca gambar, 2 = menganalisa, 3 = memprediksi
  int _processingStep = 0;
  late AnimationController _animationController;
  late AnimationController _arrowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _arrowRotation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _arrowRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _classifier.loadModel();
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading model: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _predictionResult = null;
          _processingStep = 0;
        });
        _animationController.reset();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar('Gagal mengambil gambar', Colors.red);
    }
  }

  // ==================== PREDIKSI DENGAN ANIMASI PROSES ====================
  Future<void> _predictImage() async {
    if (_selectedImage == null) {
      _showSnackBar('Silakan pilih gambar terlebih dahulu', Colors.orange);
      return;
    }
    
    setState(() {
      _isPredicting = true;
      _processingStep = 1; // Step 1: Membaca gambar
    });
    
    try {
      // Step 1 — membaca gambar (delay untuk animasi)
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _processingStep = 2); // Step 2: Menganalisa

      List<int> imageBytes = await _selectedImage!.readAsBytes();

      // Step 2 — menganalisa (delay untuk animasi)
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() => _processingStep = 3); // Step 3: Memprediksi

      // Step 3 — prediksi
      Prediction prediction = await _classifier.predict(imageBytes);

      setState(() {
        _predictionResult = prediction;
        _isPredicting = false;
        _processingStep = 0;
      });
      _animationController.forward();
      
    } catch (e) {
      debugPrint('Error predicting: $e');
      _showSnackBar('Gagal memprediksi gambar', Colors.red);
      setState(() {
        _isPredicting = false;
        _processingStep = 0;
      });
    }
  }

  void _resetAll() {
    _animationController.reset();
    setState(() {
      _selectedImage = null;
      _predictionResult = null;
      _processingStep = 0;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== DIALOG KOREKSI ====================
  void _showCorrectionDialog() {
    final List<String> foodLabels = _classifier.labels;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.edit_rounded,
                          size: 18, color: Colors.red.shade700),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Koreksi Deteksi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            'Pilih makanan yang sebenarnya',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey.shade200, height: 20),
              // List makanan
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: foodLabels.length,
                  itemBuilder: (context, index) {
                    final label = foodLabels[index];
                    final foodData = NutritionData.getFoodData(label);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        child: Text(
                          foodData.indonesianName[0],
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        foodData.indonesianName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        label,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () async {
                        Navigator.pop(context);
                        
                        // Konfirmasi sebelum menyimpan
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (confirmContext) => AlertDialog(
                            title: const Text('Konfirmasi Koreksi'),
                            content: Text(
                              'Apakah Anda yakin gambar ini adalah ${foodData.indonesianName}?\n\nModel akan belajar dari koreksi ini.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(confirmContext, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(confirmContext, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                ),
                                child: const Text('Ya, Benar'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          await _saveFeedback(label);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ==================== MENYIMPAN FEEDBACK ====================
  Future<void> _saveFeedback(String correctLabel) async {
    if (_selectedImage == null || _predictionResult == null) return;
    
    _showSnackBar('Menyimpan koreksi...', Colors.blue);
    
    final imageBytes = await _selectedImage!.readAsBytes();
    await _classifier.learnFromFeedback(
      imageBytes: imageBytes,
      originalPrediction: _predictionResult!.label,
      correctLabel: correctLabel,
    );
    
    final newCacheSize = await _classifier.getCacheSize();
    
    // Tampilkan dialog sukses
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Feedback Tersimpan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Model telah belajar bahwa gambar ini adalah:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                NutritionData.getIndonesianName(correctLabel),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sekarang coba upload GAMBAR YANG SAMA untuk melihat hasilnya!\n\nCache size: $newCacheSize entries',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAll();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 16),
                  Text('Memuat model...'),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 55,
                  floating: true,
                  pinned: true,
                  stretch: true,
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Food Detection',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2E7D32),
                            Color(0xFF1B5E20),
                            Color(0xFF0A3D0A),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildUploadCard(),
                      const SizedBox(height: 16),
                      if (_predictionResult != null)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildResultCard(_predictionResult!),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildSupportedFoodCard(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  // ==================== UPLOAD CARD DENGAN PROCESSING OVERLAY ====================
  Widget _buildUploadCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Upload Gambar Makanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih foto dari kamera atau galeri',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // ==================== PREVIEW GAMBAR DENGAN OVERLAY ====================
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                color: Colors.grey.shade50,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _isPredicting
                    ? _buildProcessingOverlay()  // Animasi proses
                    : _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_selectedImage!, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 13, color: Colors.greenAccent),
                                  SizedBox(width: 4),
                                  Text('Gambar siap', style: TextStyle(fontSize: 10, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.restaurant_rounded, size: 48, color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(height: 12),
                          Text('Belum ada gambar', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                          Text('Pilih foto melalui tombol di bawah', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tombol Kamera dan Galeri
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Kamera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Tombol Prediksi atau Reset
            if (_predictionResult == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPredicting ? null : _predictImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8F00),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFFF8F00).withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isPredicting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 18),
                            SizedBox(width: 8),
                            Text('Prediksi Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resetAll,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset & Deteksi Lagi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== PROCESSING OVERLAY (ANIMASI) ====================
  Widget _buildProcessingOverlay() {
    final List<Map<String, dynamic>> steps = [
      {'icon': Icons.image_search_rounded, 'label': 'Membaca gambar...'},
      {'icon': Icons.grid_4x4_rounded, 'label': 'Menganalisa piksel...'},
      {'icon': Icons.auto_awesome_rounded, 'label': 'Memprediksi makanan...'},
    ];
    
    final currentStep = (_processingStep - 1).clamp(0, 2);
    final stepData = steps[currentStep];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Gambar asli sebagai background blur-effect
        if (_selectedImage != null)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.55),
              BlendMode.darken,
            ),
            child: Image.file(_selectedImage!, fit: BoxFit.cover),
          ),
        // Konten overlay
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lingkaran pulsa animasi
            _PulsingIcon(icon: stepData['icon'] as IconData),
            const SizedBox(height: 20),
            Text(
              stepData['label'] as String,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // Step indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(steps.length, (i) {
                final isActive = i == currentStep;
                final isDone = i < currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.shade400
                        : isActive
                            ? Colors.white
                            : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== RESULT CARD ====================
  Widget _buildResultCard(Prediction prediction) {
    final foodData = NutritionData.getFoodData(prediction.label);
    final healthLevel = NutritionData.getHealthLevel(prediction.label);
    final isLowConfidence = prediction.probability < 0.7;
    final isVeryLowConfidence = prediction.probability < 0.5;
    final healthColor = NutritionData.getHealthColor(healthLevel);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
          // Hero Header dengan gradient
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1B5E20),
                    Color(0xFF2E7D32),
                    Color(0xFF388E3C),
                    Color(0xFF1B5E20),
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Dekorasi lingkaran
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 50,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                prediction.isFromCache ? Icons.memory : Icons.auto_awesome,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                prediction.isFromCache ? 'Dari Memori Koreksi' : 'Hasil Deteksi AI',
                                style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          foodData.indonesianName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 2), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: healthColor.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: healthColor.withValues(alpha: 0.55)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(NutritionData.getHealthIcon(healthLevel), size: 14, color: healthColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    NutritionData.getHealthText(healthLevel),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: healthColor),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bar_chart_rounded, size: 13, color: Colors.white70),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${(prediction.probability * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                // Warning jika confidence rendah
                if (isVeryLowConfidence)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Keyakinan sangat rendah. Coba foto ulang dengan pencahayaan lebih baik.',
                            style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isLowConfidence)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_rounded, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Keyakinan rendah (${(prediction.probability * 100).toStringAsFixed(1)}%). Foto mungkin kurang jelas.',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (isLowConfidence || isVeryLowConfidence) const SizedBox(height: 16),

                // Calorie Highlight
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF8F00).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8F00).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFE65100), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Kalori', style: TextStyle(fontSize: 12, color: Color(0xFFBF360C), fontWeight: FontWeight.w500)),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: '${foodData.calories}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                                const TextSpan(text: ' kcal', style: TextStyle(fontSize: 14, color: Color(0xFFBF360C), fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('per 100g', style: TextStyle(fontSize: 11, color: Color(0xFFBF360C))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFF8F00).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                            child: Text('~${((foodData.calories) * 2.5).round()} kJ', style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Nutrisi Grid
                const Text('Nutrisi per 100g', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildNutrientTile(icon: Icons.fitness_center_rounded, label: 'Protein', value: foodData.protein.toStringAsFixed(1), unit: 'g', accentColor: const Color(0xFF1565C0)),
                    _buildNutrientTile(icon: Icons.grain_rounded, label: 'Karbo', value: foodData.carbs.toStringAsFixed(1), unit: 'g', accentColor: const Color(0xFF2E7D32)),
                    _buildNutrientTile(icon: Icons.water_drop_rounded, label: 'Lemak', value: foodData.fat.toStringAsFixed(1), unit: 'g', accentColor: const Color(0xFFC62828)),
                    _buildNutrientTile(icon: Icons.spa_rounded, label: 'Serat', value: foodData.fiber.toStringAsFixed(1), unit: 'g', accentColor: const Color(0xFF00695C)),
                    _buildNutrientTile(icon: Icons.bubble_chart_rounded, label: 'Gula', value: foodData.sugar.toStringAsFixed(1), unit: 'g', accentColor: const Color(0xFFAD1457)),
                    _buildNutrientTile(icon: Icons.science_rounded, label: 'Sodium', value: foodData.sodium.toStringAsFixed(0), unit: 'mg', accentColor: const Color(0xFF6A1B9A)),
                  ],
                ),
                const SizedBox(height: 20),

                // Sodium Progress Bar
                _buildSodiumBar(foodData),
                const SizedBox(height: 20),

                // Tips & Peringatan
                const Text('Info Kesehatan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF1F8E9), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFF2E7D32))),
                          const SizedBox(width: 8),
                          const Text('Tips Konsumsi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(foodData.healthTip, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.2))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFE65100).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE65100))),
                          const SizedBox(width: 8),
                          const Text('Perhatian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(foodData.warning, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Feedback Buttons
                const Text('Apakah deteksi ini benar?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSnackBar('Terima kasih! Feedback Anda membantu model belajar.', Colors.green),
                        icon: const Icon(Icons.thumb_up_rounded, size: 16),
                        label: const Text('Benar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showCorrectionDialog,
                        icon: const Icon(Icons.thumb_down_rounded, size: 16),
                        label: const Text('Salah'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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

  // ==================== HELPER WIDGETS ====================
  
  Widget _buildNutrientTile({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: accentColor)),
                TextSpan(text: unit, style: TextStyle(fontSize: 10, color: accentColor.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSodiumBar(dynamic foodData) {
    final sodiumVal = (foodData.sodium as double).clamp(0, 2000);
    final pct = sodiumVal / 2000;
    final barColor = sodiumVal > 1000 ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_rounded, size: 16, color: Colors.purple.shade600),
              const SizedBox(width: 6),
              Text('Kandungan Sodium', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const Spacer(),
              Text('${foodData.sodium.toStringAsFixed(0)} mg', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: barColor)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: barColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 mg', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              Text('Batas harian: 2000 mg', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pilih gambar makanan untuk mendapatkan estimasi kalori, nutrisi, tips kesehatan, dan saran konsumsi.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedFoodCard() {
    final List<Map<String, String>> supportedFoods = [
      {'label': 'Ayam Goreng', 'icon': '🍗'}, {'label': 'Bakso', 'icon': '🍲'}, {'label': 'Burger', 'icon': '🍔'},
      {'label': 'French Fries', 'icon': '🍟'}, {'label': 'Gado-Gado', 'icon': '🥗'}, {'label': 'Gudeg', 'icon': '🍛'},
      {'label': 'Gulai Ikan', 'icon': '🐟'}, {'label': 'Ikan Goreng', 'icon': '🐠'}, {'label': 'Mie Goreng', 'icon': '🍜'},
      {'label': 'Nasi Goreng', 'icon': '🍳'}, {'label': 'Pempek', 'icon': '🧆'}, {'label': 'Pizza', 'icon': '🍕'},
      {'label': 'Rawon', 'icon': '🥣'}, {'label': 'Rendang', 'icon': '🥩'}, {'label': 'Sate', 'icon': '🍢'},
      {'label': 'Soto', 'icon': '🍵'}, {'label': 'Telur Balado', 'icon': '🥚'}, {'label': 'Telur Dadar', 'icon': '🍳'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() => _isFoodListExpanded = !_isFoodListExpanded);
              _isFoodListExpanded ? _arrowController.forward() : _arrowController.reverse();
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: _isFoodListExpanded ? const BorderRadius.vertical(top: Radius.circular(24)) : BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.restaurant_menu_rounded, size: 18, color: Colors.white)),
                  const SizedBox(width: 10),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Makanan yang Dapat Dideteksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)), SizedBox(height: 2), Text('Model mendukung 18 jenis makanan', style: TextStyle(fontSize: 11, color: Colors.white70))])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.3))), child: Text('${supportedFoods.length}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  RotationTransition(turns: _arrowRotation, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.white))),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isFoodListExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.5, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    itemCount: supportedFoods.length,
                    itemBuilder: (context, index) {
                      final food = supportedFoods[index];
                      return Container(
                        decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.15))),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(food['icon']!, style: const TextStyle(fontSize: 14)), const SizedBox(width: 5), Flexible(child: Text(food['label']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)), overflow: TextOverflow.ellipsis, maxLines: 1))]),
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, size: 15, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Foto makanan selain daftar di atas mungkin menghasilkan prediksi yang tidak akurat.', style: TextStyle(fontSize: 11, color: Colors.amber.shade800, height: 1.4))),
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _arrowController.dispose();
    _classifier.dispose();
    super.dispose();
  }
}

// ==================== PULSING ICON WIDGET ====================
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  const _PulsingIcon({required this.icon});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.88, end: 1.12).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: Icon(widget.icon, size: 34, color: Colors.white),
          ),
        ),
      ),
    );
  }
}