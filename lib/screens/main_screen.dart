import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';

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

  // =========================
  // COLORS
  // =========================
  static const Color _primaryColor = Color(0xFF166534);
  static const Color _inactiveColor = Color(0xFF94A3B8);
  static const Color _backgroundColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      // Bilah Navigasi Bawah Full Lebar Rata Kanan, Kiri, & Bawah
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          top: false, // Hanya menyertakan padding aman di bagian bawah perangkat
          child: Container(
            height: 58, // Tinggi ramping, kompak, dan hemat ruang
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade100,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
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

                // Tab Tengah: Scan (Menonjol 3D ke Atas dengan Judul Teks)
                Expanded(
                  child: _buildCenterNavItem(
                    index: 1,
                    label: 'Scan',
                    icon: Icons.auto_awesome_rounded,
                  ),
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
          ),
        ),
      ),
    );
  }

  // =========================
  // NAV ITEM STANDAR (Kiri & Kanan)
  // =========================
  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final bool isSelected = _currentIndex == index;
    final color = isSelected ? _primaryColor : _inactiveColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // NAV ITEM TENGAH (Scan AI Menonjol Halus)
  // =========================
  Widget _buildCenterNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _currentIndex == index;
    
    // Warna dinamis tombol tengah agar berpadu harmonis dan menonjol
    final buttonColor = isSelected ? _primaryColor : Colors.grey.shade50;
    final iconColor = isSelected ? Colors.white : _primaryColor;
    final textColor = isSelected ? _primaryColor : _inactiveColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Transform.translate(
        offset: const Offset(0, -10), // Menaikkan tombol visual secara mandiri ke atas garis border
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: buttonColor,
                border: Border.all(
                  color: isSelected ? _primaryColor : Colors.black.withOpacity(0.04),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}