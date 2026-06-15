import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'history/history_screen.dart';
import 'missions_screen.dart';
import 'education/education_screen.dart';
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
    HomeScreen(),          // 0
    ScanScreen(),          // 1
    MissionsScreen(),     // 2
    EducationScreen(),     // 3
    HistoryScreen(),       // 4
  ];

  final List<NavItem> _navItems = const [
    NavItem(
      index: 0,
      label: "Beranda",
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    NavItem(
      index: 1,
      label: "Scan",
      icon: Icons.auto_awesome_rounded,
      activeIcon: Icons.auto_awesome_rounded,
    ),
    NavItem(
      index: 2,
      label: "Misi",
      icon: Icons.emoji_events_rounded,
      activeIcon: Icons.emoji_events_rounded,
    ),
    NavItem(
      index: 3,
      label: "Edukasi",
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
    ),
    NavItem(
      index: 4,
      label: "Riwayat",
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
    ),
  ];

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              /// ==========================
              /// MENU REGULER
              /// ==========================
              Row(
                children: [
                  Expanded(
                    child: _buildRegularNavItem(_navItems[0]), // Beranda
                  ),
                  Expanded(
                    child: _buildRegularNavItem(_navItems[4]), // Riwayat
                  ),

                  // Ruang kosong untuk tombol Scan
                  const SizedBox(width: 80),

                  Expanded(
                    child: _buildRegularNavItem(_navItems[2]), // Jurnal
                  ),
                  Expanded(
                    child: _buildRegularNavItem(_navItems[3]), // Edukasi
                  ),
                ],
              ),

              /// ==========================
              /// TOMBOL SCAN (FLOATING)
              /// ==========================
              Positioned(
                top: -28,
                child: _buildCenterNavItem(_navItems[1]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // NAVIGATION ITEM BIASA
  // ==========================================================
  Widget _buildRegularNavItem(NavItem item) {
    final bool isSelected = _currentIndex == item.index;

    return InkWell(
      onTap: () => _changePage(item.index),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 82,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 23,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textLight,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyleHelper.captionSmall.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textLight,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TOMBOL SCAN TENGAH
  // ==========================================================
  Widget _buildCenterNavItem(NavItem item) {
    final bool isSelected = _currentIndex == item.index;

    return GestureDetector(
      onTap: () => _changePage(item.index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent,
                        AppColors.primary,
                      ],
                    ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected
                          ? AppColors.primary
                          : AppColors.accent)
                      .withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: TextStyleHelper.captionSmall.copyWith(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textMedium,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// MODEL ITEM NAVIGASI
// ==========================================================

class NavItem {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}