// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/database_manager.dart';

// ─────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class _AppColors {
  static const Color primary     = Color(0xFF1B6B3A);   // deep forest green
  static const Color accent      = Color(0xFF4CAF7D);   // fresh mint
  static const Color highlight   = Color(0xFFB2F2CB);  
  static const Color textDark    = Color(0xFF0D2818);
  static const Color textMid     = Color(0xFF4A6558);
  static const Color textLight   = Color(0xFF8FB5A0);
  static const Color errorRed    = Color(0xFFE53935);

  // Per-page subtle bg tints
  static const List<Color> pageBg = [
    Color(0xFFF0FAF4),
    Color(0xFFE8F6EF),
    Color(0xFFF0FAF4),
  ];
}

class _AppTextStyles {
  static const TextStyle tag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.5,
    color: _AppColors.accent,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.8,
    color: _AppColors.textDark,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: _AppColors.primary,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.65,
    color: _AppColors.textMid,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );
}

// ─────────────────────────────────────────────
//  ONBOARDING SCREEN
// ─────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form controllers
  final TextEditingController _nameController         = TextEditingController();
  final TextEditingController _targetCaloriesController = TextEditingController(text: '2000');
  final TextEditingController _targetProteinController  = TextEditingController(text: '50');
  final TextEditingController _targetCarbsController    = TextEditingController(text: '250');
  final TextEditingController _targetFatController      = TextEditingController(text: '65');

  final DatabaseManager _dbManager = DatabaseManager();
  bool _isLoading = false;

  // Animations
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconRotate;

  late final AnimationController _contentController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  static const _pages = [
    OnboardingData(
      tag: 'SELAMAT DATANG',
      title: 'Makan Cerdas,\nHidup Sehat',
      subtitle: 'Deteksi Makanan Instan',
      description:
          'Kenali makanan favorit Anda seketika. Dapatkan informasi nutrisi lengkap hanya dengan satu jepretan foto.',
      icon: Icons.eco_rounded,
    ),
    OnboardingData(
      tag: 'CARA KERJA',
      title: 'Foto, Analisis,\nlalu Tahu',
      subtitle: 'Nutrisi Lengkap Seketika',
      description:
          'AI kami mengenali jenis makanan dari foto dan langsung menampilkan kalori, protein, karbohidrat, lemak, serta tips kesehatan yang relevan.',
      icon: Icons.document_scanner_rounded,
    ),
    OnboardingData(
      tag: 'PERSONALISASI',
      title: 'Target Nutrisi\nyang Tepat',
      subtitle: 'Sesuai Kebutuhan Anda',
      description:
          'Atur profil dan target nutrisi harian Anda agar rekomendasi lebih akurat dan sesuai gaya hidup.',
      icon: Icons.tune_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconScale = CurvedAnimation(parent: _iconController, curve: Curves.elasticOut);
    _iconRotate = Tween<double>(begin: -0.05, end: 0.0)
        .animate(CurvedAnimation(parent: _iconController, curve: Curves.easeOut));

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade  = CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    _iconController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
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

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _iconController.forward(from: 0);
    _contentController.forward(from: 0);
  }

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

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _saveUserProfile() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Harap masukkan nama Anda', isError: true);
      return;
    }

    final calories = int.tryParse(_targetCaloriesController.text);
    final protein  = double.tryParse(_targetProteinController.text);
    final carbs    = double.tryParse(_targetCarbsController.text);
    final fat      = double.tryParse(_targetFatController.text);

    if (calories == null || protein == null || carbs == null || fat == null) {
      _showSnackBar('Pastikan semua nilai nutrisi valid', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _dbManager.saveUserProfile(
        name: _nameController.text.trim(),
        targetCalories: calories,
        targetProtein: protein,
        targetCarbs: carbs,
        targetFat: fat,
      );

      final saved = await _dbManager.getUserProfile();
      if (saved != null) debugPrint('✅ Profile saved: ${saved['name']}');

      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      debugPrint('❌ Save error: $e');
      _showSnackBar('Terjadi kesalahan, silakan coba lagi', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: isError ? _AppColors.errorRed : _AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: _AppColors.pageBg[_currentPage],
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

  // ─── TOP BAR ─────────────────────────────────
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
                      ? _AppColors.primary
                      : passed
                          ? _AppColors.accent
                          : _AppColors.highlight,
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
                  border: Border.all(color: _AppColors.highlight, width: 1.5),
                ),
                child: const Text(
                  'Lewati',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textMid,
                    letterSpacing: 0.2,
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

  // ─── PAGE CONTENT ────────────────────────────
  Widget _buildPage(OnboardingData page, int index) {
    final isForm = index == _pages.length - 1;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),

          // Icon block
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

          // Tag
          FadeTransition(
            opacity: _contentFade,
            child: SlideTransition(
              position: _contentSlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(page.tag, style: _AppTextStyles.tag),
                  const SizedBox(height: 10),
                  Text(page.title, style: _AppTextStyles.headline),
                  const SizedBox(height: 8),
                  if (!isForm) ...[
                    _buildSubtitleBadge(page.subtitle),
                    const SizedBox(height: 16),
                    Text(page.description, style: _AppTextStyles.body),
                    const SizedBox(height: 24),
                    _buildFeaturePills(index),
                  ],
                ],
              ),
            ),
          ),

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

  Widget _buildIconBlock(OnboardingData page) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: _AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(page.icon, size: 44, color: Colors.white),
    );
  }

  Widget _buildSubtitleBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _AppColors.highlight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: _AppTextStyles.subtitle),
    );
  }

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
                border: Border.all(color: _AppColors.highlight, width: 1.5),
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ─── FORM ─────────────────────────────────────
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
          style: _AppTextStyles.body.copyWith(fontSize: 12.5),
        ),
        const SizedBox(height: 14),

        // 2-column grid
        Row(
          children: [
            Expanded(
              child: _buildNutritionCard(
                controller: _targetCaloriesController,
                label: 'Kalori',
                unit: 'kcal',
                emoji: '🔥',
                accentColor: const Color(0xFFF59E0B),
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
                accentColor: const Color(0xFF3B82F6),
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
                accentColor: const Color(0xFF10B981),
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
                accentColor: const Color(0xFFEF4444),
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
            color: _AppColors.highlight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _AppColors.highlight, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profil dapat diubah kapan saja melalui menu Pengaturan.',
                  style: _AppTextStyles.body.copyWith(fontSize: 12.5, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _AppColors.textDark,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

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
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _AppColors.textLight, fontSize: 14),
          prefixIcon: Icon(icon, color: _AppColors.accent, size: 20),
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
            borderSide: const BorderSide(color: _AppColors.accent, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.1,
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: -0.5,
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
                style: TextStyle(
                  fontSize: 11,
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

  // ─── BOTTOM BAR ──────────────────────────────
  Widget _buildBottomBar(OnboardingData page, bool isLast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: BoxDecoration(
        color: _AppColors.pageBg[_currentPage],
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
          color: _AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _AppColors.primary.withValues(alpha: 0.35),
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
                  Text(label, style: _AppTextStyles.button.copyWith(color: Colors.white)),
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
          border: Border.all(color: _AppColors.highlight, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: _AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: _AppTextStyles.button.copyWith(color: _AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}