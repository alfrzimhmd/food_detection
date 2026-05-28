// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/text_style_helper.dart';
import 'profile_screen.dart';
import 'history_detail_screen.dart';
import 'history_screen.dart';

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          final appState = Provider.of<AppState>(context, listen: false);
          await appState.refresh();
        },
        color: AppColors.primary,
        strokeWidth: 2.5,
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.isLoading && appState.recentHistory.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }
            
            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(context, appState),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildCalorieSummaryCard(appState),
                      const SizedBox(height: 16),
                      _buildMacroRow(appState),
                      const SizedBox(height: 24),
                      _buildSectionHeaderWithSeeAll(context, 'Riwayat Scan Terbaru', Icons.history_rounded),
                      const SizedBox(height: 12),
                      _buildRecentHistory(context, appState),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppState appState) {
    final greeting = _getGreeting();
    final name = appState.userProfile?['name'] as String? ?? 'Pengguna';
    final target = appState.targetCalories;
    final remaining = (target - appState.todayCalories).clamp(0, target);

    return SliverAppBar(
      expandedHeight: 220,
      collapsedHeight: 70,
      pinned: true,
      floating: false,
      stretch: true,
      backgroundColor: AppColors.primaryDark,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'NutriScan',
            style: TextStyleHelper.titleMedium.copyWith(
              color: Colors.white,
              fontSize: 17,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            await appState.refresh();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _buildGreetingBackground(greeting, name, target, remaining),
      ),
    );
  }

  Widget _buildGreetingBackground(
    _GreetingInfo g,
    String name,
    int target,
    int remaining,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 82, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(g.emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        g.greeting,
                        style: TextStyleHelper.labelMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyleHelper.displaySmall.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  g.tagline,
                  style: TextStyleHelper.labelMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFCD34D),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$remaining kcal ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const TextSpan(
                              text: 'tersisa dari target ',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            TextSpan(
                              text: '$target kcal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieSummaryCard(AppState appState) {
    final progress = appState.calorieProgress;
    final pct = appState.calorieProgressPercent;

    Color progressColor = AppColors.accent;
    if (pct >= 90) progressColor = AppColors.calories;
    if (pct > 100) progressColor = AppColors.fat;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KALORI HARI INI',
                    style: TextStyleHelper.labelSmall.copyWith(
                      letterSpacing: 1.8,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${appState.todayCalories}',
                          style: TextStyleHelper.displayMedium.copyWith(
                            fontSize: 30,
                            color: progressColor,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${appState.targetCalories} kcal',
                          style: TextStyleHelper.bodySmall.copyWith(
                            fontSize: 13,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildRingProgress(progress, pct, progressColor),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 10, color: AppColors.divider),
                AnimatedFractionallySizedBox(
                  widthFactor: progress,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, progressColor],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sudah dikonsumsi',
                style: TextStyleHelper.labelMedium,
              ),
              Text(
                pct >= 100 ? '⚠ Target tercapai' : '$pct% dari target',
                style: TextStyleHelper.labelMedium.copyWith(
                  color: pct >= 100 ? AppColors.fat : AppColors.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingProgress(double progress, int pct, Color color) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.divider),
          ),
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 6,
            strokeCap: StrokeCap.round,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Center(
            child: Text(
              '$pct%',
              style: TextStyleHelper.labelMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(AppState appState) {
    return Row(
      children: [
        Expanded(
          child: _buildMacroCard(
            '💪',
            'Protein',
            appState.todayNutrition['total_protein'] ?? 0,
            appState.targetProtein,
            'g',
            AppColors.protein,
            const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMacroCard(
            '🌾',
            'Karbo',
            appState.todayNutrition['total_carbs'] ?? 0,
            appState.targetCarbs,
            'g',
            AppColors.carbs,
            const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMacroCard(
            '🫒',
            'Lemak',
            appState.todayNutrition['total_fat'] ?? 0,
            appState.targetFat,
            'g',
            AppColors.fat,
            const Color(0xFFFEF2F2),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard(
    String emoji,
    String label,
    double current,
    double target,
    String unit,
    Color color,
    Color bgColor,
  ) {
    final progress = (current / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyleHelper.labelSmall.copyWith(
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: current.toStringAsFixed(1),
                  style: TextStyleHelper.titleMedium.copyWith(
                    fontSize: 18,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: '/$unit',
                  style: TextStyleHelper.captionSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${target.toInt()} $unit target',
            style: TextStyleHelper.captionSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 5, color: color.withValues(alpha: 0.15)),
                AnimatedFractionallySizedBox(
                  widthFactor: progress,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderWithSeeAll(BuildContext context, String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.glow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyleHelper.titleMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          },
          child: Row(
            children: [
              Text(
                'Lihat Semua',
                style: TextStyleHelper.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHistory(BuildContext context, AppState appState) {
    final recentItems = appState.recentHistory.take(3).toList();
    
    if (recentItems.isEmpty) {
      return _buildEmptyHistory(context);
    }

    return Column(
      children: recentItems.asMap().entries.map((e) {
        return _buildHistoryCard(
          context,
          e.value,
          e.key == recentItems.length - 1,
          appState,
        );
      }).toList(),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    Map<String, dynamic> item,
    bool isLast,
    AppState appState,
  ) {
    final scannedAt = DateTime.fromMillisecondsSinceEpoch(
      (item['scanned_at'] as int?) ?? 0,
    );
    final timeStr =
        '${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
    final dateStr = '${scannedAt.day}/${scannedAt.month}';
    final imagePath = item['image_path'] as String?;
    final name = (item['indonesian_name'] as String? ?? 'Makanan').trim();
    final cal = item['calories'] as int? ?? 0;
    final protein = (item['protein'] as num?)?.toStringAsFixed(1) ?? '0.0';
    final carbs = (item['carbs'] as num?)?.toStringAsFixed(1) ?? '0.0';
    final fat = (item['fat'] as num?)?.toStringAsFixed(1) ?? '0.0';
    
    // Cek apakah file gambar valid
    bool hasValidImage = false;
    File? imageFile;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        imageFile = File(imagePath);
        hasValidImage = imageFile.existsSync();
      } catch (e) {
        hasValidImage = false;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HistoryDetailScreen(historyItem: Map.from(item)),
            ),
          );
          await appState.refresh();
        },
        child: Container(
          padding: const EdgeInsets.all(12), 
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16), 
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.glow,
                  ),
                  child: hasValidImage && imageFile != null
                      ? Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                          width: 70,
                          height: 70,
                          cacheWidth: 150,
                          errorBuilder: (context, error, stackTrace) {
                            return _imageFallback(name);
                          },
                        )
                      : _imageFallback(name),
                ),
              ),
              
              const SizedBox(width: 14),

              // Info Makanan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Makanan
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleHelper.titleMedium.copyWith(
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Waktu Scan
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$timeStr  •  $dateStr',
                          style: TextStyleHelper.caption.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Kalori & Nutrisi
                    Row(
                      children: [
                        // Kalori badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.calories.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 12,
                                color: AppColors.calories,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$cal kkal',
                                style: TextStyleHelper.labelSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.calories,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Protein
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.protein.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'P $protein g',
                            style: TextStyleHelper.captionSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.protein,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Karbo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.carbs.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'K $carbs g',
                            style: TextStyleHelper.captionSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.carbs,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Lemak
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.fat.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'L $fat g',
                            style: TextStyleHelper.captionSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.fat,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.glow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(String name) {
    return Container(
      color: AppColors.glow,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 2),
            Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyleHelper.titleMedium.copyWith(
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory(BuildContext context) {    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.grey.shade50,
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.carbs.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.carbs,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat Scan',
            style: TextStyleHelper.titleMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai scan makanan Anda sekarang\ndan lacak nutrisi harian',
            textAlign: TextAlign.center,
            style: TextStyleHelper.bodySmall.copyWith(
              color: AppColors.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  _GreetingInfo _getGreeting() {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 11) {
      return _GreetingInfo('Selamat Pagi', '☀️', 'Mulai hari dengan gizi yang baik!');
    }
    if (h >= 11 && h < 15) {
      return _GreetingInfo('Selamat Siang', '🌤', 'Jangan lewatkan makan siangmu!');
    }
    if (h >= 15 && h < 18) {
      return _GreetingInfo('Selamat Sore', '🌇', 'Semangat sore ini!');
    }
    return _GreetingInfo('Selamat Malam', '🌙', 'Catat makan malammu sekarang.');
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _GreetingInfo {
  final String greeting, emoji, tagline;
  const _GreetingInfo(this.greeting, this.emoji, this.tagline);
}