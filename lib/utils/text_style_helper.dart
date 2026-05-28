// lib/utils/text_style_helper.dart
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Helper untuk mengatur TextStyle secara konsisten di semua platform
/// termasuk Linux yang memiliki rendering font default berbeda
class TextStyleHelper {
  // ============================================================
  // HEADLINE STYLES (Untuk judul utama)
  // ============================================================
  
  /// Headline 1 - Paling besar (32-34px)
  static TextStyle get headline1 {
    return GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.2,
      color: Colors.black87,
    );
  }
  
  /// Headline 2 (28-30px)
  static TextStyle get headline2 {
    return GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.2,
      color: Colors.black87,
    );
  }
  
  /// Headline 3 (24-26px)
  static TextStyle get headline3 {
    return GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      height: 1.25,
      color: Colors.black87,
    );
  }
  
  /// Headline 4 (20-22px)
  static TextStyle get headline4 {
    return GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.3,
      color: Colors.black87,
    );
  }
  
  // ============================================================
  // TITLE STYLES (Untuk sub judul)
  // ============================================================
  
  /// Title Large (18-20px)
  static TextStyle get titleLarge {
    return GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.3,
      color: Colors.black87,
    );
  }
  
  /// Title Medium (16-17px)
  static TextStyle get titleMedium {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.35,
      color: Colors.black87,
    );
  }
  
  /// Title Small (14-15px)
  static TextStyle get titleSmall {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
      height: 1.4,
      color: Colors.black87,
    );
  }
  
  // ============================================================
  // BODY STYLES (Untuk teks biasa)
  // ============================================================
  
  /// Body Large (16px)
  static TextStyle get bodyLarge {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.5,
      color: Colors.black87,
    );
  }
  
  /// Body Medium (14px)
  static TextStyle get bodyMedium {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.5,
      color: Colors.black87,
    );
  }
  
  /// Body Small (12px)
  static TextStyle get bodySmall {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.2,
      height: 1.5,
      color: Colors.black87,
    );
  }
  
  // ============================================================
  // LABEL STYLES (Untuk teks pada tombol, badge, chip)
  // ============================================================
  
  /// Label Large (14px, bold)
  static TextStyle get labelLarge {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      height: 1.4,
      color: Colors.black87,
    );
  }
  
  /// Label Medium (12px, semi-bold)
  static TextStyle get labelMedium {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      height: 1.4,
      color: Colors.black87,
    );
  }
  
  /// Label Small (10px, medium)
  static TextStyle get labelSmall {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      height: 1.4,
      color: Colors.black87,
    );
  }
  
  // ============================================================
  // DISPLAY STYLES (Untuk angka, statistik)
  // ============================================================
  
  /// Display Large (36-40px, extra bold)
  static TextStyle get displayLarge {
    return GoogleFonts.plusJakartaSans(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      height: 1.1,
      color: Colors.black87,
    );
  }
  
  /// Display Medium (32-34px, extra bold)
  static TextStyle get displayMedium {
    return GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.1,
      color: Colors.black87,
    );
  }
  
  /// Display Small (28-30px, bold)
  static TextStyle get displaySmall {
    return GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.1,
      color: Colors.black87,
    );
  }
  
  // ============================================================
  // CAPTION STYLES (Untuk teks kecil, watermark)
  // ============================================================
  
  /// Caption (11px, regular)
  static TextStyle get caption {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.3,
      height: 1.4,
      color: Colors.grey,
    );
  }
  
  /// Caption Small (10px, light)
  static TextStyle get captionSmall {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.2,
      height: 1.3,
      color: Colors.grey,
    );
  }
  
  // ============================================================
  // UTILITY METHODS - Membuat TextStyle dengan kustomisasi
  // ============================================================
  
  /// Membuat bold text dengan font weight yang konsisten
  static TextStyle bold({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w700,
      letterSpacing: letterSpacing ?? 0.5,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  /// Membuat semi-bold text
  static TextStyle semiBold({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w600,
      letterSpacing: letterSpacing ?? 0.3,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  /// Membuat medium text
  static TextStyle medium({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w500,
      letterSpacing: letterSpacing ?? 0.2,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  /// Membuat regular text
  static TextStyle regular({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w400,
      letterSpacing: letterSpacing ?? 0.1,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  /// Membuat light text
  static TextStyle light({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w300,
      letterSpacing: letterSpacing ?? 0.1,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  // ============================================================
  // CUSTOM COLOR VARIANTS
  // ============================================================
  
  /// Membuat text dengan warna primary
  static TextStyle primary({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    final baseStyle = (fontWeight == FontWeight.w700 ? bold() : regular());
    return baseStyle.copyWith(
      fontSize: fontSize,
      color: const Color(0xFF10B981),
      letterSpacing: letterSpacing,
    );
  }
  
  /// Membuat text dengan warna error
  static TextStyle error({
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final baseStyle = (fontWeight == FontWeight.w700 ? bold() : regular());
    return baseStyle.copyWith(
      fontSize: fontSize,
      color: Colors.red,
    );
  }
  
  /// Membuat text dengan warna warning
  static TextStyle warning({
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final baseStyle = (fontWeight == FontWeight.w700 ? bold() : regular());
    return baseStyle.copyWith(
      fontSize: fontSize,
      color: const Color(0xFFF59E0B),
    );
  }
  
  // ============================================================
  // RESPONSIVE TEXT (Opsional, untuk ukuran layar berbeda)
  // ============================================================
  
  /// Mendapatkan ukuran font responsif berdasarkan lebar layar
  static double responsiveSize(BuildContext context, {required double baseSize}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return baseSize * 0.85;  // Layar kecil
    } else if (width < 400) {
      return baseSize * 0.95;  // Layar medium
    } else if (width < 600) {
      return baseSize;          // Layar normal
    } else {
      return baseSize * 1.1;   // Layar besar/tablet
    }
  }
  
  /// Text style responsif
  static TextStyle responsive({
    required BuildContext context,
    required TextStyle baseStyle,
    double? scaleFactor,
  }) {
    final width = MediaQuery.of(context).size.width;
    double scale = 1.0;
    if (width < 360) {
      scale = 0.85;
    } else if (width < 400) {
      scale = 0.95;
    } else if (width > 600) {
      scale = 1.1;
    }
    
    if (scaleFactor != null) {
      scale *= scaleFactor;
    }
    
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize! * scale,
    );
  }
}

// ============================================================
// EXTENSION - Memudahkan penggunaan di widget
// ============================================================

extension TextStyleExtension on TextStyle {
  /// Menggabungkan dengan warna tertentu
  TextStyle withColor(Color color) {
    return copyWith(color: color);
  }
  
  /// Menggabungkan dengan ukuran font tertentu
  TextStyle withSize(double size) {
    return copyWith(fontSize: size);
  }
  
  /// Membuat teks menjadi bold
  TextStyle get asBold {
    return copyWith(fontWeight: FontWeight.w700);
  }
  
  /// Membuat teks menjadi semi-bold
  TextStyle get asSemiBold {
    return copyWith(fontWeight: FontWeight.w600);
  }
  
  /// Membuat teks menjadi medium
  TextStyle get asMedium {
    return copyWith(fontWeight: FontWeight.w500);
  }
  
  /// Membuat teks menjadi light
  TextStyle get asLight {
    return copyWith(fontWeight: FontWeight.w300);
  }
  
  /// Menambahkan line height
  TextStyle withHeight(double height) {
    return copyWith(height: height);
  }
  
  /// Menyesuaikan warna dengan tema (light/dark mode) - Tambahan
  TextStyle themed(BuildContext context, {bool? isDark}) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final color = dark ? Colors.white : Colors.black87;
    return copyWith(color: color);
  }
  
  /// Menyesuaikan warna dengan tema sekunder
  TextStyle themedSecondary(BuildContext context, {bool? isDark}) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final color = dark ? Colors.white70 : Colors.black54;
    return copyWith(color: color);
  }
}