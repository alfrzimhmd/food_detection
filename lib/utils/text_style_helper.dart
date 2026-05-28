// lib/utils/text_style_helper.dart
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';

/// Helper untuk mengatur TextStyle secara konsisten di semua platform
/// Menggunakan font dari assets/fonts/ dengan weight yang eksplisit
class TextStyleHelper {
  
  // ============================================================
  // HEADLINE STYLES (Plus Jakarta Sans - Weight 800)
  // ============================================================
  
  static TextStyle get headline1 {
    return const TextStyle(
      fontFamily: 'PlusJakartaSansExtraBold',
      fontSize: 32,
      letterSpacing: -0.5,
      height: 1.2,
      color: Colors.black87,
    );
  }
  
  static TextStyle get headline2 {
    return const TextStyle(
      fontFamily: 'PlusJakartaSansExtraBold',
      fontSize: 28,
      letterSpacing: -0.5,
      height: 1.2,
      color: Colors.black87,
    );
  }
  
  static TextStyle get headline3 {
    return const TextStyle(
      fontFamily: 'PlusJakartaSansExtraBold',
      fontSize: 24,
      letterSpacing: -0.3,
      height: 1.25,
      color: Colors.black87,
    );
  }
  
  static TextStyle get headline4 {
    return const TextStyle(
      fontFamily: 'PlusJakartaSansBold',
      fontSize: 20,
      letterSpacing: -0.3,
      height: 1.3,
      color: Colors.black87,
    );
  }
  
  // ============================================================
  // TITLE STYLES (Plus Jakarta Sans - Weight 700)
  // ============================================================
  
  static TextStyle get titleLarge {
    return const TextStyle(
      fontFamily: 'PlusJakartaSansBold',
      fontSize: 18,
      letterSpacing: -0.2,
      height: 1.3,
      color: Colors.black87,
    );
  }
  
  static TextStyle get titleMedium {
    return const TextStyle(
      fontFamily: 'PlusJakartaSansBold',
      fontSize: 16,
      letterSpacing: -0.2,
      height: 1.35,
      color: Colors.black87,
    );
  }
  
  static TextStyle get titleSmall {
    return const TextStyle(
      fontFamily: 'PlusJakartaSansBold',
      fontSize: 14,
      letterSpacing: -0.1,
      height: 1.4,
      color: Colors.black87,
    );
  }
  
  // ============================================================
  // BODY STYLES (Inter - Weight 400)
  // ============================================================
  
  static TextStyle get bodyLarge {
    return const TextStyle(
      fontFamily: 'InterRegular',
      fontSize: 16,
      letterSpacing: 0.15,
      height: 1.5,
      color: Colors.black87,
    );
  }
  
  static TextStyle get bodyMedium {
    return const TextStyle(
      fontFamily: 'InterRegular',
      fontSize: 14,
      letterSpacing: 0.15,
      height: 1.5,
      color: Colors.black87,
    );
  }
  
  static TextStyle get bodySmall {
    return const TextStyle(
      fontFamily: 'InterRegular',
      fontSize: 12,
      letterSpacing: 0.2,
      height: 1.5,
      color: Colors.black87,
    );
  }
  
  // ============================================================
  // LABEL STYLES (Inter - Weight 700, 600, 500)
  // ============================================================
  
  static TextStyle get labelLarge {
    return const TextStyle(
      fontFamily: 'InterBold',
      fontSize: 14,
      letterSpacing: 0.5,
      height: 1.4,
      color: Colors.black87,
    );
  }
  
  static TextStyle get labelMedium {
    return const TextStyle(
      fontFamily: 'InterSemiBold',
      fontSize: 12,
      letterSpacing: 0.4,
      height: 1.4,
      color: Colors.black87,
    );
  }
  
  static TextStyle get labelSmall {
    return const TextStyle(
      fontFamily: 'InterMedium',
      fontSize: 10,
      letterSpacing: 0.3,
      height: 1.4,
      color: Colors.black87,
    );
  }
  
  // ============================================================
  // DISPLAY STYLES (Plus Jakarta Sans - Weight 800, 700)
  // ============================================================
  
  static TextStyle get displayLarge {
    return const TextStyle(
      fontFamily: 'PlusJakartaSansExtraBold',
      fontSize: 36,
      letterSpacing: -0.8,
      height: 1.1,
      color: Colors.black87,
    );
  }
  
  static TextStyle get displayMedium {
    return const TextStyle(
      fontFamily: 'PlusJakartaSansExtraBold',
      fontSize: 32,
      letterSpacing: -0.5,
      height: 1.1,
      color: Colors.black87,
    );
  }
  
  static TextStyle get displaySmall {
    return const TextStyle(
      fontFamily: 'PlusJakartaSansBold',
      fontSize: 28,
      letterSpacing: -0.4,
      height: 1.1,
      color: Colors.black87,
    );
  }
  
  // ============================================================
  // CAPTION STYLES (Inter - Weight 400)
  // ============================================================
  
  static TextStyle get caption {
    return const TextStyle(
      fontFamily: 'InterRegular',
      fontSize: 11,
      letterSpacing: 0.3,
      height: 1.4,
      color: Colors.grey,
    );
  }
  
  static TextStyle get captionSmall {
    return const TextStyle(
      fontFamily: 'InterRegular',
      fontSize: 10,
      letterSpacing: 0.2,
      height: 1.3,
      color: Colors.grey,
    );
  }
  
  // ============================================================
  // UTILITY METHODS - Dengan font family yang sesuai
  // ============================================================
  
  static TextStyle bold({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'InterBold',
      fontSize: fontSize ?? 14,
      letterSpacing: letterSpacing ?? 0.5,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  static TextStyle semiBold({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'InterSemiBold',
      fontSize: fontSize ?? 14,
      letterSpacing: letterSpacing ?? 0.3,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  static TextStyle medium({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'InterMedium',
      fontSize: fontSize ?? 14,
      letterSpacing: letterSpacing ?? 0.2,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  static TextStyle regular({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'InterRegular',
      fontSize: fontSize ?? 14,
      letterSpacing: letterSpacing ?? 0.1,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  static TextStyle light({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'InterRegular',
      fontSize: fontSize ?? 14,
      letterSpacing: letterSpacing ?? 0.1,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  // ============================================================
  // HEADING UTILITY (Plus Jakarta Sans)
  // ============================================================
  
  static TextStyle headingBold({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'PlusJakartaSansBold',
      fontSize: fontSize ?? 16,
      letterSpacing: letterSpacing ?? -0.2,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  static TextStyle headingExtraBold({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'PlusJakartaSansExtraBold',
      fontSize: fontSize ?? 20,
      letterSpacing: letterSpacing ?? -0.3,
      color: color ?? Colors.black87,
      decoration: decoration,
    );
  }
  
  // ============================================================
  // CUSTOM COLOR VARIANTS
  // ============================================================
  
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
  // RESPONSIVE TEXT
  // ============================================================
  
  static double responsiveSize(BuildContext context, {required double baseSize}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return baseSize * 0.85;
    } else if (width < 400) {
      return baseSize * 0.95;
    } else if (width < 600) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }
  
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
// EXTENSION
// ============================================================

extension TextStyleExtension on TextStyle {
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
  TextStyle get asBold => copyWith(fontFamily: 'InterBold');
  TextStyle get asSemiBold => copyWith(fontFamily: 'InterSemiBold');
  TextStyle get asMedium => copyWith(fontFamily: 'InterMedium');
  TextStyle get asLight => copyWith(fontFamily: 'InterRegular');
  TextStyle withHeight(double height) => copyWith(height: height);
}