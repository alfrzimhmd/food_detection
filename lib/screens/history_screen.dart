import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/database_manager.dart';
import 'history_detail_screen.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class _C {
  static const Color primary     = Color(0xFF1B6B3A);
  static const Color primaryDark = Color(0xFF0F3D22);
  static const Color glow        = Color(0xFFB2F2CB);
  static const Color bg          = Color(0xFFF4F8F5);
  static const Color card        = Colors.white;
  static const Color textDark    = Color(0xFF0D2818);
  static const Color textMid     = Color(0xFF4A6558);
  static const Color textLight   = Color(0xFFA0B8AA);
  static const Color divider     = Color(0xFFE4EDE8);
  static const Color calColor    = Color(0xFFF59E0B);
  static const Color protColor   = Color(0xFF3B82F6);
  static const Color carbColor   = Color(0xFF10B981);
  static const Color fatColor    = Color(0xFFEF4444);
}

enum _LoadState { loading, success, error }

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
  
  final DatabaseManager _dbManager = DatabaseManager();

  List<Map<String, dynamic>> _allHistory = [];
  List<Map<String, dynamic>> _filteredHistory = [];

  _LoadState _loadState = _LoadState.loading;
  String _errorMessage = '';

  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  static const _filters = ['Semua', 'Sangat Sehat', 'Cukup Sehat', 'Kurang Sehat'];

  AnimationController? _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    
    // Sinkronisasi pembaruan reaktif dengan DatabaseManager
    DatabaseManager.databaseUpdateNotifier.addListener(_loadHistory);
    _loadHistory();
  }

  @override
  void dispose() {
    DatabaseManager.databaseUpdateNotifier.removeListener(_loadHistory);
    _shimmerCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    
    debugPrint('🔵 _loadHistory: START');
    
    setState(() {
      _loadState = _LoadState.loading;
      _errorMessage = '';
    });

    try {
      final result = await _dbManager.getAllScanHistory();
      debugPrint('✅ Loaded ${result.length} items from database');
      
      if (!mounted) return;

      setState(() {
        _allHistory = result;
        _loadState = _LoadState.success;
      });
      _applyFilters();
      
      debugPrint('🔵 SetState success: _allHistory.length=${_allHistory.length}');
      
    } catch (e, stacktrace) {
      debugPrint('❌ Error: $e');
      debugPrint(stacktrace.toString());
      if (mounted) {
        setState(() {
          _loadState = _LoadState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    
    setState(() {
      var list = List<Map<String, dynamic>>.from(_allHistory);

      if (_selectedFilter != 'Semua') {
        list = list.where((item) {
          final hl = item['health_level'] as String?;
          if (hl == null) return false;
          final l = hl.toLowerCase();
          if (_selectedFilter == 'Sangat Sehat') return l.contains('healthy');
          if (_selectedFilter == 'Cukup Sehat') return l.contains('medium');
          if (_selectedFilter == 'Kurang Sehat') return l.contains('unhealthy');
          return false;
        }).toList();
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        list = list.where((item) {
          final name = (item['indonesian_name'] as String? ?? '').toLowerCase();
          return name.contains(q);
        }).toList();
      }

      _filteredHistory = list;
    });
  }

  String _healthLabel(String? hl) {
    if (hl == null) return 'Tidak diketahui';
    final l = hl.toLowerCase();
    if (l.contains('healthy')) return 'Sangat Sehat';
    if (l.contains('medium')) return 'Cukup Sehat';
    if (l.contains('unhealthy')) return 'Kurang Sehat';
    return 'Tidak diketahui';
  }

  Color _healthColor(String? hl) {
    if (hl == null) return _C.textLight;
    final l = hl.toLowerCase();
    if (l.contains('healthy')) return _C.carbColor;
    if (l.contains('medium')) return _C.calColor;
    if (l.contains('unhealthy')) return _C.fatColor;
    return _C.textLight;
  }

  IconData _healthIcon(String? hl) {
    if (hl == null) return Icons.help_outline_rounded;
    final l = hl.toLowerCase();
    if (l.contains('healthy')) return Icons.sentiment_very_satisfied_rounded;
    if (l.contains('medium')) return Icons.sentiment_neutral_rounded;
    if (l.contains('unhealthy')) return Icons.sentiment_dissatisfied_rounded;
    return Icons.help_outline_rounded;
  }

  Future<void> _deleteSingleItem(int id) async {
    try {
      await _dbManager.deleteScanHistory(id);
      // Pembaruan data asinkron akan otomatis terpicu lewat ChangeNotifier
      _showSnackBar('Riwayat dihapus');
    } catch (e) {
      _showSnackBar('Gagal menghapus');
    }
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await _showConfirmDialog(
      title: 'Hapus Semua Riwayat',
      body: 'Seluruh riwayat scan akan dihapus permanen.',
      confirmLabel: 'Hapus Semua',
      confirmColor: _C.fatColor,
    );
    if (ok != true || !mounted) return;
    
    try {
      await _dbManager.deleteAllScanHistory();
      _showSnackBar('Semua riwayat telah dihapus');
    } catch (e) {
      _showSnackBar('Gagal menghapus');
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: confirmColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.delete_rounded, color: confirmColor, size: 26),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: _C.textDark)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _C.textMid, height: 1.5)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _C.bg, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.divider, width: 1.5),
                  ),
                  child: const Center(
                    child: Text('Batal', style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14,
                        color: _C.textMid)),
                  ),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: confirmColor, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: confirmColor.withOpacity(0.3),
                        blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(child: Text(confirmLabel,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 14))),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _C.primary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 BUILD: _loadState=$_loadState, items=${_filteredHistory.length}');
    
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildAppBar(),
          if (_loadState == _LoadState.success && _allHistory.isNotEmpty) ...[
            _buildSearchBar(),
            _buildFilterChips(),
          ],
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: _C.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Riwayat Scan',
                    style: TextStyle(color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                if (_loadState == _LoadState.success)
                  Text('${_allHistory.length} total scan',
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ]),
            ),
            _AppBarAction(icon: Icons.refresh_rounded, onTap: _loadHistory),
            if (_allHistory.isNotEmpty) ...[
              const SizedBox(width: 6),
              _AppBarAction(icon: Icons.delete_sweep_rounded,
                  onTap: _confirmDeleteAll,
                  color: _C.fatColor.withOpacity(0.9)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _C.primaryDark,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: TextField(
          onChanged: (v) {
            _searchQuery = v;
            _applyFilters();
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
      color: _C.primaryDark,
      child: Container(
        decoration: const BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final sel = _selectedFilter == f;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = f);
                  _applyFilters();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _C.primary : _C.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? _C.primary : _C.divider, width: 1.5),
                  ),
                  child: Text(f, style: TextStyle(
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? Colors.white : _C.textMid)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadState == _LoadState.loading) {
      return _buildShimmerList();
    }
    
    if (_loadState == _LoadState.error) {
      return _buildErrorState();
    }
    
    if (_filteredHistory.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: _C.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredHistory.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _buildHistoryCard(_filteredHistory[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _searchQuery.isNotEmpty || _selectedFilter != 'Semua';
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: _C.glow, borderRadius: BorderRadius.circular(24)),
          child: Icon(
            isFiltered ? Icons.search_off_rounded : Icons.camera_alt_outlined,
            color: _C.primary, size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isFiltered ? 'Tidak ditemukan' : 'Belum ada riwayat scan',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: _C.textDark),
        ),
        const SizedBox(height: 6),
        Text(
          isFiltered
              ? 'Coba ubah filter atau kata kunci'
              : 'Mulai scan makanan untuk melihat riwayat',
          style: const TextStyle(fontSize: 13, color: _C.textLight),
        ),
        if (isFiltered) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() { _searchQuery = ''; _selectedFilter = 'Semua'; });
              _applyFilters();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: _C.glow, borderRadius: BorderRadius.circular(20)),
              child: const Text('Hapus Filter',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: _C.primary)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _C.fatColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(Icons.error_outline_rounded, color: _C.fatColor, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Gagal memuat data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: _C.textDark)),
        const SizedBox(height: 6),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: _C.textLight),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _loadHistory,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Coba Lagi', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final id = item['id'] as int? ?? 0;
    final scannedAt = DateTime.fromMillisecondsSinceEpoch(
        (item['scanned_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch);
    final timeStr = '${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
    final dateStr = '${scannedAt.day} ${_monthName(scannedAt.month)} ${scannedAt.year}';
    
    final imagePath = item['image_path'] as String?;
    final name = (item['indonesian_name'] as String? ?? 'Makanan').trim();
    final cal = (item['calories'] as num?)?.toInt() ?? 0;
    final protein = (item['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (item['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (item['fat'] as num?)?.toDouble() ?? 0.0;
    
    final hl = item['health_level'] as String?;
    final hColor = _healthColor(hl);
    final hLabel = _healthLabel(hl);
    final hIcon = _healthIcon(hl);

    bool hasValidImage = false;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        hasValidImage = File(imagePath).existsSync();
      } catch (e) {}
    }

    return Dismissible(
      key: ValueKey('hist_$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showConfirmDialog(
        title: 'Hapus Riwayat',
        body: '"$name" akan dihapus permanen.',
        confirmLabel: 'Hapus',
        confirmColor: _C.fatColor,
      ).then((v) => v == true),
      onDismissed: (_) => _deleteSingleItem(id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _C.fatColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.delete_rounded, color: _C.fatColor, size: 24),
          const SizedBox(height: 4),
          Text('Hapus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.fatColor)),
        ]),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HistoryDetailScreen(historyItem: Map.from(item)),
            ),
          );
        },
        child: Container(
          height: 124, // Memaksakan batas tinggi agar Row dan ClipRRect aman (Mencegah Layout Loop Freeze)
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 96,
                height: 124, // Penyelaras tinggi mutlak
                child: hasValidImage
                    ? Image.file(
                        File(imagePath!), 
                        fit: BoxFit.cover, 
                        cacheWidth: 200, // Mengoptimalkan memori native (UI thread tidak membeku)
                        errorBuilder: (_, __, ___) => _photoFallback(name),
                      )
                    : _photoFallback(name),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pembagian ruang asri vertikal
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.textDark)),
                      ),
                      Icon(Icons.chevron_right_rounded, color: _C.textLight.withOpacity(0.7), size: 20),
                    ]),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: _C.textLight),
                      const SizedBox(width: 4),
                      Text('$timeStr  ·  $dateStr', style: const TextStyle(fontSize: 11, color: _C.textLight)),
                    ]),
                    Row(children: [
                      _badge(icon: Icons.local_fire_department_rounded, label: '$cal kcal', color: _C.calColor),
                      const SizedBox(width: 6),
                      _badge(icon: hIcon, label: hLabel, color: hColor),
                    ]),
                    Row(children: [
                      _MacroPill('P', '${protein.toStringAsFixed(1)} g', _C.protColor),
                      const SizedBox(width: 5),
                      _MacroPill('K', '${carbs.toStringAsFixed(1)} g', _C.carbColor),
                      const SizedBox(width: 5),
                      _MacroPill('L', '${fat.toStringAsFixed(1)} g', _C.fatColor),
                    ]),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _badge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _photoFallback(String name) {
    return Container(
      color: _C.glow,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.restaurant_rounded, color: _C.primary, size: 28),
        const SizedBox(height: 4),
        Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _C.primary)),
      ]),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _shimmerCard(),
    );
  }

  Widget _shimmerCard() {
    final ctrl = _shimmerCtrl;
    if (ctrl == null || !ctrl.isAnimating) {
      return Container(height: 100, decoration: BoxDecoration(color: const Color(0xFFE4EDE8), borderRadius: BorderRadius.circular(20)));
    }
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Container(
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
        width: 36, height: 36,
        decoration: BoxDecoration(color: (color ?? Colors.white).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: '$abbr ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
          TextSpan(text: value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}