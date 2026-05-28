// lib/screens/history_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/text_style_helper.dart';
import 'history_detail_screen.dart';
import '../data/nutrition_data.dart';

// ─────────────────────────────────────────────
//  HISTORY SCREEN
// ─────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  static const _filters = ['Semua', 'Sangat Sehat', 'Cukup Sehat', 'Kurang Sehat'];

  AnimationController? _shimmerCtrl;
  
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    debugPrint('🏠 HistoryScreen: initState');
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    debugPrint('🏠 HistoryScreen: dispose');
    _debounceTimer?.cancel();
    _shimmerCtrl?.dispose();
    super.dispose();
  }

  String _getHealthLabelFromData(Map<String, dynamic> item) {
    final healthLevelStr = item['health_level'] as String?;
    if (healthLevelStr == null) return 'Tidak diketahui';
    
    switch (healthLevelStr.toLowerCase()) {
      case 'healthy':
        return NutritionData.getHealthText(HealthLevel.healthy);
      case 'medium':
        return NutritionData.getHealthText(HealthLevel.medium);
      case 'unhealthy':
        return NutritionData.getHealthText(HealthLevel.unhealthy);
      default:
        return healthLevelStr;
    }
  }

  Color _getHealthColorFromData(Map<String, dynamic> item) {
    final healthLevelStr = item['health_level'] as String?;
    if (healthLevelStr == null) return AppColors.textLight;
    
    switch (healthLevelStr.toLowerCase()) {
      case 'healthy':
        return NutritionData.getHealthColor(HealthLevel.healthy);
      case 'medium':
        return NutritionData.getHealthColor(HealthLevel.medium);
      case 'unhealthy':
        return NutritionData.getHealthColor(HealthLevel.unhealthy);
      default:
        return AppColors.textLight;
    }
  }

  IconData _getHealthIconFromData(Map<String, dynamic> item) {
    final healthLevelStr = item['health_level'] as String?;
    if (healthLevelStr == null) return Icons.help_outline_rounded;
    
    switch (healthLevelStr.toLowerCase()) {
      case 'healthy':
        return NutritionData.getHealthIcon(HealthLevel.healthy);
      case 'medium':
        return NutritionData.getHealthIcon(HealthLevel.medium);
      case 'unhealthy':
        return NutritionData.getHealthIcon(HealthLevel.unhealthy);
      default:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _deleteSingleItem(int id, AppState appState) async {
    // 🔥 Cancel previous delete if any
    _debounceTimer?.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      debugPrint('🗑️ Delete item: $id');
      
      final itemToDelete = appState.scanHistory.firstWhere(
        (item) => item['id'] == id,
        orElse: () => {},
      );
      
      final imagePath = itemToDelete['image_path'] as String?;
      
      try {
        await appState.deleteScanHistory(id);
        
        if (imagePath != null && imagePath.isNotEmpty) {
          try {
            final imageFile = File(imagePath);
            if (await imageFile.exists()) {
              await imageFile.delete();
              debugPrint('🗑️ Image file deleted: $imagePath');
            }
          } catch (e) {
            debugPrint('⚠️ Failed to delete image file: $e');
          }
        }
        
        if (mounted) {
          _showSnackBar('Riwayat berhasil dihapus');
        }
      } catch (e) {
        debugPrint('❌ Delete error: $e');
        if (mounted) {
          _showSnackBar('Gagal menghapus riwayat', isError: true);
        }
      }
    });
  }

  Future<void> _confirmDeleteAll(AppState appState) async {
    debugPrint('🗑️ Confirm delete all');
    final ok = await _showConfirmDialog(
      title: 'Hapus Semua Riwayat',
      body: 'Seluruh riwayat scan akan dihapus permanen. Data profil akan tetap tersimpan.',
      confirmLabel: 'Hapus Semua',
      confirmColor: AppColors.fat,
    );
    if (ok != true || !mounted) return;
    
    try {
      await appState.deleteAllScanHistory();  // 🔥 Gunakan method dari AppState
      if (mounted) {
        _showSnackBar('Semua riwayat telah dihapus');
      }
    } catch (e) {
      debugPrint('❌ Delete all error: $e');
      if (mounted) {
        _showSnackBar('Gagal menghapus riwayat', isError: true);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: confirmColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.delete_rounded, color: confirmColor, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyleHelper.headline4.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyleHelper.bodySmall.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            'Batal',
                            style: TextStyleHelper.labelLarge.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: confirmColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: confirmColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            confirmLabel,
                            style: TextStyleHelper.labelLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
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
            Expanded(
              child: Text(
                msg,
                style: TextStyleHelper.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> allHistory,
    String searchQuery,
    String selectedFilter,
  ) {
    var list = List<Map<String, dynamic>>.from(allHistory);

    if (selectedFilter != 'Semua') {
      list = list.where((item) {
        final hl = item['health_level'] as String?;
        if (hl == null) return false;
        final l = hl.toLowerCase();
          if (selectedFilter == 'Sangat Sehat') {
            return l == 'healthy';  // exact match, bukan contains
          }
          if (selectedFilter == 'Cukup Sehat') {
            return l == 'medium';   // exact match, bukan contains
          }
          if (selectedFilter == 'Kurang Sehat') {
            return l == 'unhealthy'; // exact match, bukan contains
          }
        return false;
      }).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((item) {
        final name = (item['indonesian_name'] as String? ?? '').toLowerCase();
        return name.contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 HistoryScreen: build called');
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final allHistory = appState.scanHistory;
          final filteredHistory = _applyFilters(allHistory, _searchQuery, _selectedFilter);
          final isLoading = appState.isLoading && allHistory.isEmpty;
          
          debugPrint('📊 Consumer build: allHistory.length=${allHistory.length}, filteredHistory.length=${filteredHistory.length}, isLoading=$isLoading');
          
          return Column(
            children: [
              _buildAppBar(allHistory.length, isLoading),
              if (!isLoading && allHistory.isNotEmpty) ...[
                _buildSearchBar(),
                _buildFilterChips(),
              ],
              Expanded(
                child: _buildBody(
                  isLoading: isLoading,
                  allHistory: allHistory,
                  filteredHistory: filteredHistory,
                  appState: appState,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(int totalCount, bool isLoading) {
    return Container(
      color: AppColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (!isLoading)
                      Text(
                        '$totalCount total scan',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (totalCount > 0) ...[
                const SizedBox(width: 6),
                _AppBarAction(
                  icon: Icons.delete_rounded,
                  onTap: () {
                    final appState = Provider.of<AppState>(context, listen: false);
                    _confirmDeleteAll(appState);
                  },
                  color: AppColors.fat.withValues(alpha: 0.9),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: TextField(
          onChanged: (v) {
            debugPrint('🔍 Search query changed: $v');
            setState(() {
              _searchQuery = v;
            });
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Cari nama makanan...',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white54, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: AppColors.primaryDark,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final sel = _selectedFilter == f;
              return GestureDetector(
                onTap: () {
                  debugPrint('🔍 Filter changed: $f');
                  setState(() => _selectedFilter = f);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.divider,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    f,
                    style: TextStyleHelper.labelMedium.copyWith(
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? Colors.white : AppColors.textMedium,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isLoading,
    required List<Map<String, dynamic>> allHistory,
    required List<Map<String, dynamic>> filteredHistory,
    required AppState appState,
  }) {
    if (isLoading) {
      debugPrint('⏳ Showing shimmer loading');
      return _buildShimmerList();
    }
    
    if (allHistory.isEmpty) {
      debugPrint('📭 Empty history state');
      return _buildEmptyState();
    }
    
    if (filteredHistory.isEmpty) {
      debugPrint('🔍 No results for filter/search');
      return _buildEmptyState(isFiltered: true);
    }
    
    debugPrint('📋 Showing ${filteredHistory.length} items');
    
    return RefreshIndicator(
      onRefresh: () {
        debugPrint('🔄 Pull to refresh');
        return appState.refresh();
      },
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredHistory.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _buildHistoryCard(filteredHistory[index], appState);
        },
      ),
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.glow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isFiltered ? Icons.search_off_rounded : Icons.camera_alt_outlined,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'Tidak ditemukan' : 'Belum ada riwayat scan',
            style: TextStyleHelper.titleMedium.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Coba ubah filter atau kata kunci'
                : 'Mulai scan makanan untuk melihat riwayat',
            style: TextStyleHelper.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                debugPrint('🔍 Clear filters');
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'Semua';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.glow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Hapus Filter',
                  style: TextStyleHelper.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, AppState appState) {
    final id = item['id'] as int? ?? 0;
    final scannedAt = DateTime.fromMillisecondsSinceEpoch(
      (item['scanned_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
    final timeStr = '${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
    final dateStr = '${scannedAt.day} ${_monthName(scannedAt.month)} ${scannedAt.year}';
    
    final imagePath = item['image_path'] as String?;
    final name = (item['indonesian_name'] as String? ?? 'Makanan').trim();
    final cal = (item['calories'] as num?)?.toInt() ?? 0;
    final protein = (item['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (item['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (item['fat'] as num?)?.toDouble() ?? 0.0;
    
    final hColor = _getHealthColorFromData(item);
    final hLabel = _getHealthLabelFromData(item);
    final hIcon = _getHealthIconFromData(item);

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

    return Dismissible(
      key: ValueKey('hist_$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showConfirmDialog(
        title: 'Hapus Riwayat',
        body: '"$name" akan dihapus permanen.',
        confirmLabel: 'Hapus',
        confirmColor: AppColors.fat,
      ).then((v) => v == true),
      onDismissed: (_) {
        // 🔥 Jangan langsung hapus di sini, karena bisa crash
        // Gunakan Future.microtask untuk menghindari crash
        Future.microtask(() => _deleteSingleItem(id, appState));
      },
        background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.fat.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: AppColors.fat, size: 24),
            const SizedBox(height: 4),
            Text(
              'Hapus',
              style: TextStyleHelper.labelSmall.copyWith(
                color: AppColors.fat,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          debugPrint('📱 Tap history item: $name (id=$id)');
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HistoryDetailScreen(historyItem: Map.from(item)),
            ),
          );
          debugPrint('🔄 Returning from detail, refreshing data...');
          await appState.refresh();
        },
        child: Container(
          height: 100,
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
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 80,
                  height: 100,
                  child: hasValidImage && imageFile != null
                      ? Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 100,
                          cacheWidth: 150,
                          errorBuilder: (context, error, stackTrace) {
                            return _photoFallback(name);
                          },
                        )
                      : _photoFallback(name),
                ),
              ),
              
              const SizedBox(width: 12),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleHelper.titleMedium.copyWith(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$timeStr  •  $dateStr',
                            style: TextStyleHelper.captionSmall.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(hIcon, size: 11, color: hColor),
                                const SizedBox(width: 4),
                                Text(
                                  hLabel,
                                  style: TextStyleHelper.labelSmall.copyWith(
                                    fontSize: 10,
                                    color: hColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.calories.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 11,
                                  color: AppColors.calories,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$cal kkal',
                                  style: TextStyleHelper.labelSmall.copyWith(
                                    fontSize: 10,
                                    color: AppColors.calories,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      Row(
                        children: [
                          _MacroPill('P', '${protein.toStringAsFixed(1)}g', AppColors.protein),
                          const SizedBox(width: 5),
                          _MacroPill('K', '${carbs.toStringAsFixed(1)}g', AppColors.carbs),
                          const SizedBox(width: 5),
                          _MacroPill('L', '${fat.toStringAsFixed(1)}g', AppColors.fat),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoFallback(String name) {
    return Container(
      color: AppColors.glow,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 28),
          const SizedBox(height: 4),
          Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyleHelper.displayMedium.copyWith(
              fontSize: 18,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => _shimmerCard(),
    );
  }

  Widget _shimmerCard() {
    final ctrl = _shimmerCtrl;
    
    if (ctrl == null || !ctrl.isAnimating) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFE4EDE8),
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, _) => Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + ctrl.value * 3, 0),
            end: Alignment(0 + ctrl.value * 3, 0),
            colors: const [Color(0xFFE4EDE8), Color(0xFFF4F8F5), Color(0xFFE4EDE8)],
          ),
        ),
      ),
    );
  }

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[(m - 1).clamp(0, 11)];
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _AppBarAction({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 18),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String abbr, value;
  final Color color;
  const _MacroPill(this.abbr, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$abbr ',
              style: TextStyleHelper.labelSmall.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyleHelper.captionSmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}