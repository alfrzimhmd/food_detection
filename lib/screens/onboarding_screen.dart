// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/text_style_helper.dart';

// ==================== DATA MODEL ====================

/// Model data untuk setiap halaman onboarding
class OnboardingData {
  final String tag;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;

  const OnboardingData({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
  });
}

// ==================== ONBOARDING SCREEN ====================

/// Halaman onboarding untuk pengguna baru
/// Menampilkan 3 halaman: pengenalan, cara kerja, dan form profil
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ==================== CONTROLLERS ====================
  
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form controllers untuk profil user
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetCaloriesController = TextEditingController(text: '2000');
  final TextEditingController _targetProteinController = TextEditingController(text: '50');
  final TextEditingController _targetCarbsController = TextEditingController(text: '250');
  final TextEditingController _targetFatController = TextEditingController(text: '65');

  bool _isLoading = false;

  // ==================== ANIMATION CONTROLLERS ====================
  
  // Animasi icon (scale & rotate)
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconRotate;
  
  // Animasi konten (fade & slide)
  late final AnimationController _contentController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  // Warna latar belakang per halaman
  static const List<Color> _pageBgColors = [
    Color(0xFFF0FAF4),
    Color(0xFFE8F6EF),
    Color(0xFFF0FAF4),
  ];

  // ==================== DATA PAGES ====================
  
  static const _pages = [
    OnboardingData(
      tag: 'SELAMAT DATANG',
      title: 'Makan Cerdas,\nHidup Sehat',
      subtitle: 'Deteksi Makanan Instan',
      description: 'Kenali makanan favorit Anda seketika. Dapatkan informasi nutrisi lengkap hanya dengan satu jepretan foto.',
      icon: Icons.eco_rounded,
    ),
    OnboardingData(
      tag: 'CARA KERJA',
      title: 'Foto, Analisis,\nlalu Tahu',
      subtitle: 'Nutrisi Lengkap Seketika',
      description: 'AI kami mengenali jenis makanan dari foto dan langsung menampilkan kalori, protein, karbohidrat, lemak, serta tips kesehatan yang relevan.',
      icon: Icons.document_scanner_rounded,
    ),
    OnboardingData(
      tag: 'PERSONALISASI',
      title: 'Target Nutrisi\nyang Tepat',
      subtitle: 'Sesuai Kebutuhan Anda',
      description: 'Atur profil dan target nutrisi harian Anda agar rekomendasi lebih akurat dan sesuai gaya hidup.',
      icon: Icons.tune_rounded,
    ),
  ];

  // ==================== LIFECYCLE ====================
  
  @override
  void initState() {
    super.initState();
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Inisialisasi animasi icon
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _iconRotate = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOut),
    );

    // Inisialisasi animasi konten
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    // Mulai animasi
    _iconController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
    // Bersihkan semua controller
    _pageController.dispose();
    _iconController.dispose();
    _contentController.dispose();
    _nameController.dispose();
    _targetCaloriesController.dispose();
    _targetProteinController.dispose();
    _targetCarbsController.dispose();
    _targetFatController.dispose();
    super.dispose();
  }

  // ==================== NAVIGATION ====================
  
  /// Handler saat halaman berubah
  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    // Reset animasi
    _iconController.forward(from: 0);
    _contentController.forward(from: 0);
  }

  /// Navigasi ke halaman berikutnya
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _saveUserProfile();
    }
  }

  /// Navigasi ke halaman sebelumnya
  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  // ==================== SAVE PROFILE ====================
  
  /// Menyimpan profil user dan navigasi ke main screen
  Future<void> _saveUserProfile() async {
    FocusScope.of(context).unfocus();

    // Validasi nama
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Harap masukkan nama Anda', isError: true);
      return;
    }

    // Parsing nilai nutrisi
    final calories = int.tryParse(_targetCaloriesController.text);
    final protein = double.tryParse(_targetProteinController.text);
    final carbs = double.tryParse(_targetCarbsController.text);
    final fat = double.tryParse(_targetFatController.text);

    if (calories == null || protein == null || carbs == null || fat == null) {
      _showSnackBar('Pastikan semua nilai nutrisi valid', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final success = await appState.saveUserProfile(
        name: _nameController.text.trim(),
        targetCalories: calories,
        targetProtein: protein,
        targetCarbs: carbs,
        targetFat: fat,
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        _showSnackBar('Gagal menyimpan profil', isError: true);
      }
    } catch (e) {
      debugPrint('Save error: $e');
      _showSnackBar('Terjadi kesalahan, silakan coba lagi', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== SNACKBAR ====================
  
  /// Menampilkan snackbar dengan pesan
  void _showSnackBar(String message, {bool isError = false}) {
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ==================== BUILD ====================
  
  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: _pageBgColors[_currentPage],
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isLast),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: isLast
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i], i),
              ),
            ),
            _buildBottomBar(page, isLast),
          ],
        ),
      ),
    );
  }

  // ==================== TOP BAR ====================
  
  /// Membangun top bar dengan step dots dan tombol skip
  Widget _buildTopBar(bool isLast) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step dots
          Row(
            children: List.generate(_pages.length, (i) {
              final active = i == _currentPage;
              final passed = i < _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                margin: const EdgeInsets.only(right: 6),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : passed
                          ? AppColors.accent
                          : AppColors.glow,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Skip button (hidden on last page)
          if (!isLast)
            GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  _pages.length - 1,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glow, width: 1.5),
                ),
                child: Text(
                  'Lewati',
                  style: TextStyleHelper.labelMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }

  // ==================== PAGE CONTENT ====================
  
  /// Membangun konten halaman onboarding
  Widget _buildPage(OnboardingData page, int index) {
    final isForm = index == _pages.length - 1;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),

          // Icon block (tidak untuk halaman form)
          if (!isForm) ...[
            ScaleTransition(
              scale: _iconScale,
              child: RotationTransition(
                turns: _iconRotate,
                child: _buildIconBlock(page),
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Konten dengan animasi fade & slide
          FadeTransition(
            opacity: _contentFade,
            child: SlideTransition(
              position: _contentSlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag
                  Text(
                    page.tag,
                    style: TextStyleHelper.labelSmall.copyWith(
                      letterSpacing: 2.5,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Title
                  Text(
                    page.title,
                    style: TextStyleHelper.headline1.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle badge
                  if (!isForm) ...[
                    _buildSubtitleBadge(page.subtitle),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      page.description,
                      style: TextStyleHelper.bodyMedium.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Feature pills
                    _buildFeaturePills(index),
                  ],
                ],
              ),
            ),
          ),

          // Form (halaman terakhir)
          if (isForm) ...[
            const SizedBox(height: 4),
            FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: _buildForm(),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Membangun icon block dengan animasi
  Widget _buildIconBlock(OnboardingData page) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(page.icon, size: 44, color: Colors.white),
    );
  }

  /// Membangun badge subtitle
  Widget _buildSubtitleBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyleHelper.titleSmall.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Membangun feature pills (fitur-fitur unggulan)
  Widget _buildFeaturePills(int pageIndex) {
    final features = const [
      [
        ['📸', 'Foto Instan'],
        ['🥗', 'Cek Kalori'],
        ['💡', 'Tips Sehat'],
      ],
      [
        ['🤖', 'AI Canggih'],
        ['⚡', 'Hasil Cepat'],
        ['📊', 'Data Lengkap'],
      ],
    ];

    if (pageIndex >= features.length) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: features[pageIndex]
          .map(
            (f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glow, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f[0], style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    f[1],
                    style: TextStyleHelper.labelMedium.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ==================== FORM ====================
  
  /// Membangun form profil user
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Name field
        _buildSectionLabel('Profil Anda', Icons.person_outline_rounded),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _nameController,
          hint: 'Masukkan nama Anda',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 28),

        // Nutrition targets
        _buildSectionLabel('Target Nutrisi Harian', Icons.track_changes_rounded),
        const SizedBox(height: 4),
        Text(
          'Nilai default sudah sesuai standar umum. Sesuaikan jika perlu.',
          style: TextStyleHelper.bodySmall.copyWith(
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 14),

        // 2-column grid untuk nutrisi
        Row(
          children: [
            Expanded(
              child: _buildNutritionCard(
                controller: _targetCaloriesController,
                label: 'Kalori',
                unit: 'kcal',
                emoji: '🔥',
                accentColor: AppColors.calories,
                bgColor: const Color(0xFFFFFBEB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionCard(
                controller: _targetProteinController,
                label: 'Protein',
                unit: 'gram',
                emoji: '💪',
                accentColor: AppColors.protein,
                bgColor: const Color(0xFFEFF6FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNutritionCard(
                controller: _targetCarbsController,
                label: 'Karbohidrat',
                unit: 'gram',
                emoji: '🌾',
                accentColor: AppColors.carbs,
                bgColor: const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionCard(
                controller: _targetFatController,
                label: 'Lemak',
                unit: 'gram',
                emoji: '🫒',
                accentColor: AppColors.fat,
                bgColor: const Color(0xFFFEF2F2),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.glow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glow, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profil dapat diubah kapan saja melalui menu Pengaturan.',
                  style: TextStyleHelper.bodySmall.copyWith(
                    height: 1.5,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Membangun label section dengan icon
  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyleHelper.titleSmall.copyWith(
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  /// Membangun text field dengan styling custom
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: TextStyleHelper.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyleHelper.bodySmall.copyWith(
            color: AppColors.textLight,
          ),
          prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  /// Membangun card input nutrisi
  Widget _buildNutritionCard({
    required TextEditingController controller,
    required String label,
    required String unit,
    required String emoji,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyleHelper.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.left,
                  style: TextStyleHelper.displaySmall.copyWith(
                    fontSize: 22,
                    color: accentColor,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                unit,
                style: TextStyleHelper.captionSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accentColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM BAR ====================
  
  /// Membangun bottom bar dengan tombol navigasi
  Widget _buildBottomBar(OnboardingData page, bool isLast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: BoxDecoration(
        color: _pageBgColors[_currentPage],
      ),
      child: Row(
        children: [
          // Back button
          if (_currentPage > 0) ...[
            _buildSecondaryButton(
              label: 'Kembali',
              icon: Icons.arrow_back_rounded,
              onTap: _prevPage,
            ),
            const SizedBox(width: 12),
          ],

          // Primary CTA
          Expanded(
            child: _buildPrimaryButton(
              label: isLast ? 'Mulai Sekarang' : 'Lanjutkan',
              icon: isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
              isLoading: _isLoading,
              onTap: _nextPage,
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun tombol primary
  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyleHelper.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                ],
              ),
      ),
    );
  }

  /// Membangun tombol secondary
  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glow, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyleHelper.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}