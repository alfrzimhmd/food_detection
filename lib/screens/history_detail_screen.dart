// lib/screens/history_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/text_style_helper.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> historyItem;

  const HistoryDetailScreen({super.key, required this.historyItem});

  // ─── Safe extractors ──────────────────────────────────────────────────────
  String _s(String key, {String d = ''}) {
    try {
      return (historyItem[key] ?? d).toString();
    } catch (_) {
      return d;
    }
  }

  int _i(String key, {int d = 0}) {
    try {
      final v = historyItem[key];
      if (v == null) return d;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? d;
    } catch (_) {
      return d;
    }
  }

  double _d(String key, {double d = 0}) {
    try {
      final v = historyItem[key];
      if (v == null) return d;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? d;
    } catch (_) {
      return d;
    }
  }

  // ─── Health helpers ────────────────────────────────────────────────────────
  String _healthLabel(String raw) {
    final l = raw.toLowerCase();
    if (l.contains('unhealthy')) return 'Kurang Sehat';
    if (l.contains('medium')) return 'Cukup Sehat';
    if (l.contains('healthy')) return 'Sangat Sehat';
    return 'Tidak Diketahui';
  }

  Color _healthColor(String raw) {
    final l = raw.toLowerCase();
    if (l.contains('unhealthy')) return AppColors.fat;
    if (l.contains('medium')) return AppColors.calories;
    if (l.contains('healthy')) return AppColors.carbs;
    return AppColors.textLight;
  }

  IconData _healthIcon(String raw) {
    final l = raw.toLowerCase();
    if (l.contains('unhealthy')) return Icons.sentiment_dissatisfied_rounded;
    if (l.contains('medium')) return Icons.sentiment_neutral_rounded;
    if (l.contains('healthy')) return Icons.sentiment_very_satisfied_rounded;
    return Icons.help_outline_rounded;
  }

  String _formatDate(DateTime dt) {
    const mo = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${mo[dt.month - 1]} ${dt.year}  ·  $h:$m';
  }

  // ─── Sodium helpers ────────────────────────────────────────────────────────
  Color _sodiumColor(double mg) {
    if (mg > 800) return AppColors.fat;
    if (mg > 400) return AppColors.calories;
    return AppColors.carbs;
  }

  String _sodiumLabel(double mg) {
    if (mg > 800) return 'Tinggi';
    if (mg > 400) return 'Sedang';
    return 'Normal';
  }

  double _sodiumProgress(double mg) => (mg / 2300).clamp(0.0, 1.0);

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final name = _s('indonesian_name', d: 'Makanan');
    final millis = _i('scanned_at', d: DateTime.now().millisecondsSinceEpoch);
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final calories = _i('calories');
    final protein = _d('protein');
    final carbs = _d('carbs');
    final fat = _d('fat');
    final fiber = _d('fiber');
    final sugar = _d('sugar');
    final sodium = _d('sodium');
    final rawHealth = _s('health_level');
    final healthTip = _s('health_tip');
    final warning = _s('warning');

    final healthStatus = _healthLabel(rawHealth);
    final healthColor = _healthColor(rawHealth);
    final healthIcon = _healthIcon(rawHealth);

    final imagePath = _s('image_path');
    bool hasImage = false;
    if (imagePath.isNotEmpty) {
      try {
        hasImage = File(imagePath).existsSync();
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar with hero ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _buildHero(
                imagePath, hasImage, name,
                healthStatus, healthColor, healthIcon,
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Food name & date ─────────────────────────────────────
                  Text(
                    name,
                    style: TextStyleHelper.headline2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(date),
                        style: TextStyleHelper.caption.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // ── Calorie highlight ────────────────────────────────────
                  _buildCalorieCard(calories),
                  const SizedBox(height: 22),

                  // ── Section: Makro ───────────────────────────────────────
                  _sectionTitle('Rincian Nutrisi', Icons.bar_chart_rounded),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _macroCard(
                          'Protein',
                          protein.toStringAsFixed(1),
                          'g',
                          AppColors.protein,
                          Icons.fitness_center_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _macroCard(
                          'Karbohidrat',
                          carbs.toStringAsFixed(1),
                          'g',
                          AppColors.carbs,
                          Icons.grain_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _macroCard(
                          'Lemak',
                          fat.toStringAsFixed(1),
                          'g',
                          AppColors.fat,
                          Icons.water_drop_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Serat & Gula ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _miniCard(
                          'Serat',
                          fiber > 0 ? fiber.toStringAsFixed(1) : '0.0',
                          'g',
                          AppColors.fiber,
                          Icons.line_style_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _miniCard(
                          'Gula',
                          sugar > 0 ? sugar.toStringAsFixed(1) : '0.0',
                          'g',
                          AppColors.sugar,
                          Icons.cookie_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Sodium with linear progress ──────────────────────────
                  _buildSodiumCard(sodium),
                  const SizedBox(height: 22),

                  // ── Health tip ───────────────────────────────────────────
                  if (healthTip.isNotEmpty) ...[
                    _sectionTitle('Tips Konsumsi', Icons.lightbulb_rounded),
                    const SizedBox(height: 12),
                    _infoCard(
                      content: healthTip,
                      bg: const Color(0xFFECFBF1),
                      border: AppColors.carbs.withValues(alpha: 0.22),
                      iconBg: AppColors.carbs.withValues(alpha: 0.12),
                      icon: Icons.lightbulb_rounded,
                      iconColor: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Warning ──────────────────────────────────────────────
                  if (warning.isNotEmpty) ...[
                    _sectionTitle('Perhatian', Icons.warning_amber_rounded),
                    const SizedBox(height: 12),
                    _infoCard(
                      content: warning,
                      bg: const Color(0xFFFFF5F5),
                      border: AppColors.fat.withValues(alpha: 0.22),
                      iconBg: AppColors.fat.withValues(alpha: 0.12),
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.fat,
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 10),

                  // ── Back button ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Kembali',
                        style: TextStyleHelper.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero ─────────────────────────────────────────────────────────────────
  Widget _buildHero(
    String imagePath,
    bool hasImage,
    String name,
    String healthStatus,
    Color hColor,
    IconData hIcon,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image or gradient placeholder
        hasImage
            ? Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(name);
                },
              )
            : _buildPlaceholder(name),

        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.60),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
        ),

        // Health badge
        Positioned(
          bottom: 22,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hIcon, size: 17, color: hColor),
                const SizedBox(width: 7),
                Text(
                  healthStatus,
                  style: TextStyleHelper.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: hColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.splashGradient,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                Icons.restaurant_rounded,
                size: 56,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name.length > 24 ? '${name.substring(0, 24)}…' : name,
              style: TextStyleHelper.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Calorie card ──────────────────────────────────────────────────────────
  Widget _buildCalorieCard(int calories) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        gradient: AppColors.calorieGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.calories.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.calories.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.calories.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.calories,
              size: 26,
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Kalori',
                style: TextStyleHelper.labelMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$calories',
                      style: TextStyleHelper.displayLarge.copyWith(
                        fontSize: 34,
                        color: AppColors.calories,
                      ),
                    ),
                    TextSpan(
                      text: '  kkal',
                      style: TextStyleHelper.titleSmall.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section title ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.glow,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyleHelper.titleMedium.copyWith(
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ─── Macro card ────────────────────────────────────────────────────────────
  Widget _macroCard(
    String label,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyleHelper.displaySmall.copyWith(
                fontSize: 19,
                color: color,
              ),
            ),
          ),
          Text(
            unit,
            style: TextStyleHelper.captionSmall.copyWith(
              color: color.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyleHelper.captionSmall.copyWith(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mini card (serat/gula) ────────────────────────────────────────────────
  Widget _miniCard(
    String label,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyleHelper.captionSmall.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              Text(
                '$value $unit',
                style: TextStyleHelper.titleMedium.copyWith(
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Sodium card with linear progress ─────────────────────────────────────
  Widget _buildSodiumCard(double sodium) {
    final color = _sodiumColor(sodium);
    final label = _sodiumLabel(sodium);
    final progress = _sodiumProgress(sodium);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.science_rounded, size: 19, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sodium',
                      style: TextStyleHelper.labelMedium.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                    Text(
                      '${sodium.toStringAsFixed(0)} mg',
                      style: TextStyleHelper.titleMedium.copyWith(
                        fontSize: 19,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.20)),
                ),
                child: Text(
                  label,
                  style: TextStyleHelper.labelMedium.copyWith(
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Linear progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0 mg',
                    style: TextStyleHelper.captionSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% dari batas harian (2300 mg)',
                    style: TextStyleHelper.captionSmall.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Info card (tip / warning) ─────────────────────────────────────────────
  Widget _infoCard({
    required String content,
    required Color bg,
    required Color border,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: TextStyleHelper.bodyMedium.copyWith(
                height: 1.55,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}