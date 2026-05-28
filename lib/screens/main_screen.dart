import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import '../utils/app_colors.dart';
import '../utils/text_style_helper.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    ScanScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      // Bilah Navigasi Bawah dengan tombol scan menonjol ke atas
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Container(
            height: 60, // Tinggi bar
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade100,
                  width: 1.0,
                ),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none, // Agar tombol yang menonjol tidak terpotong
              children: [
                // Baris tombol biasa (kiri dan kanan) - diposisikan di tengah vertikal
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tab Kiri: Beranda
                    Expanded(
                      child: _buildNavItem(
                        index: 0,
                        label: 'Beranda',
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                      ),
                    ),
                    
                    // Spacer untuk tombol scan di tengah
                    const Expanded(
                      child: SizedBox(),
                    ),
                    
                    // Tab Kanan: Riwayat
                    Expanded(
                      child: _buildNavItem(
                        index: 2,
                        label: 'Riwayat',
                        icon: Icons.history_outlined,
                        activeIcon: Icons.history_rounded,
                      ),
                    ),
                  ],
                ),
                
                // Tombol Scan di Tengah (menonjol ke atas)
                Positioned(
                  left: 0,
                  right: 0,
                  top: -28, // Menaikkan tombol ke atas
                  child: Center(
                    child: _buildCenterNavItem(
                      index: 1,
                      label: 'Scan',
                      icon: Icons.auto_awesome_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // NAV ITEM STANDAR (Kiri & Kanan) - Posisi Tengah Vertikal
  // =========================
  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final bool isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textLight;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 60, // Tinggi penuh bar
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Posisi tengah vertikal
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 22, // Ukuran icon standar
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyleHelper.captionSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // NAV ITEM TENGAH (Scan - Tombol Sedang & Menonjol)
  // =========================
  Widget _buildCenterNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol scan ukuran sedang
          Container(
            width: 54,  // Ukuran sedang (tidak terlalu besar)
            height: 54, // Ukuran sedang (tidak terlalu besar)
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accent, AppColors.primary],
                    ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 26, // Ukuran icon sedang
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyleHelper.captionSmall.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textMedium,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}