// lib/utils/app_colors.dart
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';

/// Centralized color palette for the entire application
class AppColors {
  // ============================================================
  // PRIMARY COLORS - Brand Identity
  // ============================================================
  
  /// Primary brand color - Forest Green
  static const Color primary = Color(0xFF1B6B3A);
  
  /// Primary dark variant - Darker forest green
  static const Color primaryDark = Color(0xFF0F3D22);
  
  /// Primary light variant - Lighter forest green
  static const Color primaryLight = Color(0xFF2E8B57);
  
  /// Primary extra light variant - Very light forest green
  static const Color primaryExtraLight = Color(0xFFE8F5E9);
  
  // ============================================================
  // SECONDARY/ACCENT COLORS
  // ============================================================
  
  /// Accent color - Fresh mint green
  static const Color accent = Color(0xFF4CAF7D);
  
  /// Accent dark variant
  static const Color accentDark = Color(0xFF388E3C);
  
  /// Accent light variant
  static const Color accentLight = Color(0xFF80E0A7);
  
  /// Glow color - Light mint for backgrounds and highlights
  static const Color glow = Color(0xFFB2F2CB);
  
  // ============================================================
  // BACKGROUND COLORS
  // ============================================================
  
  /// Main background color (light mode)
  static const Color background = Color(0xFFF4F8F5);
  
  /// Card background color (light mode)
  static const Color cardBackground = Colors.white;
  
  /// Dark background (dark mode)
  static const Color backgroundDark = Color(0xFF111827);
  
  /// Dark card background (dark mode)
  static const Color cardBackgroundDark = Color(0xFF1F2937);
  
  // ============================================================
  // TEXT COLORS
  // ============================================================
  
  /// Dark text color for primary content
  static const Color textDark = Color(0xFF0D2818);
  
  /// Medium text color for secondary content
  static const Color textMedium = Color(0xFF4A6558);
  
  /// Light text color for tertiary content
  static const Color textLight = Color(0xFFA0B8AA);
  
  /// White text color
  static const Color textWhite = Colors.white;
  
  /// White text with opacity
  static const Color textWhite70 = Colors.white70;
  
  /// White text with opacity 38%
  static const Color textWhite38 = Colors.white38;
  
  // ============================================================
  // DIVIDER & BORDER COLORS
  // ============================================================
  
  /// Divider color for light mode
  static const Color divider = Color(0xFFE4EDE8);
  
  /// Border color for light mode
  static const Color border = Color(0xFFE0E0E0);
  
  /// Dark divider color
  static const Color dividerDark = Color(0xFF374151);
  
  /// Dark border color
  static const Color borderDark = Color(0xFF374151);
  
  // ============================================================
  // NUTRITION MACRO COLORS
  // ============================================================
  
  /// Calories color - Amber/Orange
  static const Color calories = Color(0xFFF59E0B);
  
  /// Protein color - Blue
  static const Color protein = Color(0xFF3B82F6);
  
  /// Carbohydrates color - Green
  static const Color carbs = Color(0xFF10B981);
  
  /// Fat color - Red
  static const Color fat = Color(0xFFEF4444);
  
  /// Fiber color - Teal
  static const Color fiber = Color(0xFF00897B);
  
  /// Sugar color - Pink/Rose
  static const Color sugar = Color(0xFFAD1457);
  
  /// Sodium color - Purple
  static const Color sodium = Color(0xFF6A1B9A);
  
  // ============================================================
  // HEALTH LEVEL COLORS
  // ============================================================
  
  /// Healthy level color - Green
  static const Color healthy = Color(0xFF10B981);
  
  /// Moderate/Cukup level color - Orange
  static const Color moderate = Color(0xFFF59E0B);
  
  /// Warning/Perhatian level color - Deep Orange
  static const Color warning = Color(0xFFE65100);
  
  /// Danger level color - Red
  static const Color danger = Color(0xFFEF4444);
  
  // ============================================================
  // STATUS COLORS
  // ============================================================
  
  /// Success color
  static const Color success = Color(0xFF10B981);
  
  /// Error color
  static const Color error = Color(0xFFEF4444);
  
  /// Info color
  static const Color info = Color(0xFF3B82F6);
  
  // ============================================================
  // OVERLAY & SHADOW COLORS
  // ============================================================
  
  /// Shadow color with opacity
  static const Color shadow = Color(0xFF000000);
  
  /// Overlay dark color
  static const Color overlayDark = Color(0x80000000);
  
  /// Overlay light color
  static const Color overlayLight = Color(0x33FFFFFF);
  
  // ============================================================
  // GRADIENT DEFINITIONS
  // ============================================================
  
  /// Primary gradient (top-left to bottom-right)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  /// Accent gradient
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, primary],
  );
  
  /// Calorie card gradient (light mode)
  static const LinearGradient calorieGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF8EC), Color(0xFFFFEDD5)],
  );
  
  /// Scan result header gradient
  static const LinearGradient resultHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B6B3A), Color(0xFF2E7D32), Color(0xFF1B5E20)],
  );
  
  /// Splash screen gradient
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A3D0A), Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
    stops: [0.0, 0.35, 0.65, 1.0],
  );
  
  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// Get text color based on background brightness
  static Color getContrastText(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  /// Get appropriate card color based on theme mode
  static Color cardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? cardBackgroundDark : cardBackground;
  }
  
  /// Get appropriate background color based on theme mode
  static Color backgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? backgroundDark : background;
  }
  
  /// Get appropriate text color based on theme mode
  static Color textColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? textWhite : textDark;
  }
  
  /// Get appropriate secondary text color based on theme mode
  static Color secondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? textWhite70 : textMedium;
  }
}

// ============================================================
// EXTENSION - Theme-aware color getters
// ============================================================

/// Extension untuk mendapatkan warna yang sesuai dengan tema
extension ThemeColors on BuildContext {
  /// Card color berdasarkan tema
  Color get cardColor => AppColors.cardColor(this);
  
  /// Background color berdasarkan tema
  Color get backgroundColor => AppColors.backgroundColor(this);
  
  /// Text color berdasarkan tema
  Color get textColor => AppColors.textColor(this);
  
  /// Secondary text color berdasarkan tema
  Color get secondaryTextColor => AppColors.secondaryTextColor(this);
  
  /// Divider color berdasarkan tema
  Color get dividerColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AppColors.dividerDark : AppColors.divider;
  }
}