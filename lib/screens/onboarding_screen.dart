import 'package:flutter/material.dart';
import '../data/database_manager.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Controller untuk form di slide 2 dan 3
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetCaloriesController = TextEditingController();
  final TextEditingController _targetProteinController = TextEditingController();
  final TextEditingController _targetCarbsController = TextEditingController();
  final TextEditingController _targetFatController = TextEditingController();
  
  final DatabaseManager _dbManager = DatabaseManager();
  bool _isLoading = false;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Selamat Datang!',
      description: 'Aplikasi deteksi makanan pintar yang membantu Anda mengenali jenis makanan dan informasi nutrisinya secara instan.',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF2E7D32),
      backgroundColor: Color(0xFFF1F8E9),
    ),
    OnboardingData(
      title: 'Kenali Makanan Anda',
      description: 'Cukup foto makanan Anda, aplikasi akan langsung mengenali jenis makanan dan menampilkan informasi kalori, protein, karbohidrat, lemak, dan tips kesehatan.',
      icon: Icons.photo_camera_rounded,
      color: Color(0xFF2E7D32),
      backgroundColor: Color(0xFFE8F5E9),
    ),
    OnboardingData(
      title: 'Atur Target Harian',
      description: 'Masukkan data diri Anda untuk mendapatkan rekomendasi nutrisi yang dipersonalisasi.',
      icon: Icons.assignment_rounded,
      color: Color(0xFF2E7D32),
      backgroundColor: Color(0xFFE8F5E9),
      isForm: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _targetCaloriesController.dispose();
    _targetProteinController.dispose();
    _targetCarbsController.dispose();
    _targetFatController.dispose();
    super.dispose();
  }

  Future<void> _saveUserProfile() async {
    // Validasi input
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Masukkan nama Anda', Colors.red);
      return;
    }
    
    int? targetCalories = int.tryParse(_targetCaloriesController.text);
    double? targetProtein = double.tryParse(_targetProteinController.text);
    double? targetCarbs = double.tryParse(_targetCarbsController.text);
    double? targetFat = double.tryParse(_targetFatController.text);
    
    if (targetCalories == null || targetProtein == null || targetCarbs == null || targetFat == null) {
      _showSnackBar('Masukkan target nutrisi dengan benar', Colors.red);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _dbManager.saveUserProfile(
        name: _nameController.text.trim(),
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        targetCarbs: targetCarbs,
        targetFat: targetFat,
      );
      
      // Verifikasi data tersimpan
      final savedProfile = await _dbManager.getUserProfile();
      if (savedProfile != null) {
        debugPrint('Profile saved successfully: ${savedProfile['name']}');
      } else {
        debugPrint('Warning: Profile not found after save');
      }
      
      if (mounted) {
        // Gunakan pushReplacementNamed agar tidak bisa kembali ke onboarding
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      _showSnackBar('Terjadi kesalahan, silakan coba lagi', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _pages[_currentPage].backgroundColor,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: _currentPage == index ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _pages[_currentPage].color
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            
                            // Icon atau Ilustrasi
                            if (!page.isForm)
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: page.color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  page.icon,
                                  size: 70,
                                  color: page.color,
                                ),
                              ),
                            
                            const SizedBox(height: 48),
                            
                            // Title
                            Text(
                              page.title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: page.color,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Description
                            if (!page.isForm)
                              Text(
                                page.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            
                            const SizedBox(height: 40),
                            
                            // Form (hanya di slide terakhir)
                            if (page.isForm) _buildForm(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Tombol Navigasi
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _pages[_currentPage].color,
                            side: BorderSide(color: _pages[_currentPage].color),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Kembali'),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_currentPage < _pages.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  _saveUserProfile();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage].color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_currentPage == _pages.length - 1 ? 'Mulai' : 'Lanjut'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // Input Nama
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Anda',
              hintText: 'Masukkan nama Anda',
              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2E7D32)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Judul Target Nutrisi
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Target Nutrisi Harian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Grid Input Target
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildNutritionInputField(
              label: 'Kalori',
              unit: 'kcal',
              controller: _targetCaloriesController,
              keyboardType: TextInputType.number,
              icon: Icons.local_fire_department_rounded,
              color: Colors.orange,
              defaultValue: '2000',
            ),
            _buildNutritionInputField(
              label: 'Protein',
              unit: 'g',
              controller: _targetProteinController,
              keyboardType: TextInputType.number,
              icon: Icons.fitness_center_rounded,
              color: Colors.blue,
              defaultValue: '50',
            ),
            _buildNutritionInputField(
              label: 'Karbohidrat',
              unit: 'g',
              controller: _targetCarbsController,
              keyboardType: TextInputType.number,
              icon: Icons.grain_rounded,
              color: Colors.green,
              defaultValue: '250',
            ),
            _buildNutritionInputField(
              label: 'Lemak',
              unit: 'g',
              controller: _targetFatController,
              keyboardType: TextInputType.number,
              icon: Icons.water_drop_rounded,
              color: Colors.red,
              defaultValue: '65',
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Info card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Target ini akan digunakan untuk menghitung progress nutrisi harian Anda.',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionInputField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required IconData icon,
    required Color color,
    required String defaultValue,
  }) {
    controller.text = defaultValue;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          prefixIcon: Icon(icon, color: color, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final bool isForm;
  
  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.isForm = false,
  });
}