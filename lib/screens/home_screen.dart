import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/database_manager.dart';
import 'profile_screen.dart';
import 'history_detail_screen.dart';

// ─────────────────────────────────────────────
//  ROUTE OBSERVER — daftarkan di MaterialApp
//  MaterialApp(navigatorObservers: [homeRouteObserver])
// ─────────────────────────────────────────────
final RouteObserver<ModalRoute<void>> homeRouteObserver =
    RouteObserver<ModalRoute<void>>();

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class _C {
  static const Color primary     = Color(0xFF1B6B3A);
  static const Color primaryDark = Color(0xFF0F3D22);
  static const Color accent      = Color(0xFF4CAF7D);
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

class _T {
  static const TextStyle displayName = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w800,
    letterSpacing: -0.5, color: Colors.white, height: 1.1,
  );
  static const TextStyle greetingMeta = TextStyle(
    fontSize: 12.5, fontWeight: FontWeight.w500,
    color: Colors.white70, letterSpacing: 0.2,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700,
    color: _C.textDark, letterSpacing: -0.3,
  );
  static const TextStyle cardValue = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w800,
    letterSpacing: -0.5, color: _C.textDark,
  );
  static const TextStyle cardLabel = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: _C.textLight, letterSpacing: 0.5,
  );
  static const TextStyle tag = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.8,
  );
}

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final DatabaseManager _dbManager = DatabaseManager();

  Map<String, dynamic>? _userProfile;
  Map<String, double>   _todayNutrition = {};
  int                   _todayCalories  = 0;
  bool                  _isLoading      = true;

  List<Map<String, dynamic>> _recentHistory = [];

  AnimationController? _shimmerController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      homeRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    debugPrint('HomeScreen: didPopNext → refresh data');
    _loadData();
  }

  @override
  void dispose() {
    homeRouteObserver.unsubscribe(this);
    _shimmerController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _dbManager.getUserProfile(),
        _dbManager.getTodayNutritionSummary(),
        _dbManager.getTodayTotalCalories(),
        _dbManager.getAllScanHistory(),
      ]);

      if (!mounted) return;

      _userProfile    = results[0] as Map<String, dynamic>?;
      _todayNutrition = (results[1] as Map<String, double>?) ?? {};
      _todayCalories  = (results[2] as int?) ?? 0;

      final allHistory = (results[3] as List<Map<String, dynamic>>?) ?? [];
      _recentHistory  = allHistory.take(5).toList();
    } catch (e) {
      debugPrint('HomeScreen _loadData error: $e');
      if (!mounted) return;
      _userProfile    = null;
      _todayNutrition = {};
      _todayCalories  = 0;
      _recentHistory  = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  _GreetingInfo _getGreeting() {
    final h = DateTime.now().hour;
    if (h >= 4  && h < 11) return _GreetingInfo('Selamat Pagi',  '☀️', 'Mulai hari dengan gizi yang baik!');
    if (h >= 11 && h < 15) return _GreetingInfo('Selamat Siang', '🌤', 'Jangan lewatkan makan siangmu!');
    if (h >= 15 && h < 18) return _GreetingInfo('Selamat Sore',  '🌇', 'Semangat sore ini!');
    return _GreetingInfo('Selamat Malam', '🌙', 'Catat makan malammu sekarang.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: _C.primary,
        strokeWidth: 2.5,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_isLoading)
                    _buildSkeletonBody()
                  else ...[
                    const SizedBox(height: 20),
                    _buildCalorieSummaryCard(),
                    const SizedBox(height: 16),
                    _buildMacroRow(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Riwayat Scan Hari Ini', Icons.history_rounded),
                    const SizedBox(height: 12),
                    _buildRecentHistory(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final greeting  = _getGreeting();
    final name      = _userProfile?['name'] as String? ?? 'Pengguna';
    final target    = (_userProfile?['target_calories'] as int?) ?? 2000;
    final remaining = (target - _todayCalories).clamp(0, target);

    return SliverAppBar(
      expandedHeight: 220,
      collapsedHeight: 70,
      pinned: true,
      floating: false,
      stretch: true,
      backgroundColor: _C.primaryDark,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      title: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('NutriScan',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            // Diubah ke ikon Akun/Profil sesuai instruksi
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),
        IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
          ),
          onPressed: _loadData,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _buildGreetingBackground(greeting, name, target, remaining),
      ),
    );
  }

  Widget _buildGreetingBackground(
      _GreetingInfo g, String name, int target, int remaining) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6B3A), Color(0xFF0F3D22)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -30, right: -20,
            child: Container(width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04)))),
          Positioned(bottom: 20, left: -40,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 82, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(g.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(g.greeting, style: _T.greetingMeta),
                  ]),
                ),
                const SizedBox(height: 8),
                Text(name, style: _T.displayName),
                const SizedBox(height: 4),
                Text(g.tagline, style: _T.greetingMeta),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15), width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFCD34D), size: 16),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '$remaining kcal ',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w800, fontSize: 14,
                              letterSpacing: -0.3),
                        ),
                        const TextSpan(
                          text: 'tersisa dari target ',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        TextSpan(
                          text: '$target kcal',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieSummaryCard() {
    final target   = ((_userProfile?['target_calories'] as int?) ?? 2000).toDouble();
    final progress = (_todayCalories / target).clamp(0.0, 1.0);
    final pct      = (progress * 100).toInt();

    Color progressColor = _C.accent;
    if (pct >= 90)  progressColor = _C.calColor;
    if (pct > 100)  progressColor = _C.fatColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('KALORI HARI INI',
                  style: _T.tag.copyWith(color: _C.textLight)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '$_todayCalories',
                    style: _T.cardValue.copyWith(
                        fontSize: 30, color: progressColor),
                  ),
                  TextSpan(
                    text: ' / ${target.toInt()} kcal',
                    style: _T.cardLabel.copyWith(
                        fontSize: 13, color: _C.textMid),
                  ),
                ]),
              ),
            ]),
            _buildRingProgress(progress, pct, progressColor),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(children: [
            Container(height: 10, color: _C.divider),
            AnimatedFractionallySizedBox(
              widthFactor: progress,
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_C.accent, progressColor]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sudah dikonsumsi', style: _T.cardLabel),
            Text(
              pct >= 100 ? '⚠ Target tercapai' : '$pct% dari target',
              style: _T.cardLabel.copyWith(
                  color: pct >= 100 ? _C.fatColor : _C.textMid),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildRingProgress(double progress, int pct, Color color) {
    return SizedBox(
      width: 64, height: 64,
      child: Stack(fit: StackFit.expand, children: [
        CircularProgressIndicator(
          value: 1.0, strokeWidth: 6,
          valueColor: AlwaysStoppedAnimation<Color>(_C.divider),
        ),
        CircularProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          strokeWidth: 6,
          strokeCap: StrokeCap.round,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        Center(
          child: Text('$pct%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                  color: color, letterSpacing: -0.5)),
        ),
      ]),
    );
  }

  Widget _buildMacroRow() {
    final tProt = (_userProfile?['target_protein'] as double?) ?? 50.0;
    final tCarb = (_userProfile?['target_carbs']   as double?) ?? 250.0;
    final tFat  = (_userProfile?['target_fat']     as double?) ?? 65.0;

    final cProt = _todayNutrition['total_protein'] ?? 0.0;
    final cCarb = _todayNutrition['total_carbs']   ?? 0.0;
    final cFat  = _todayNutrition['total_fat']     ?? 0.0;

    return Row(children: [
      Expanded(child: _buildMacroCard('💪', 'Protein', cProt, tProt, 'g',
          _C.protColor, const Color(0xFFEFF6FF))),
      const SizedBox(width: 10),
      Expanded(child: _buildMacroCard('🌾', 'Karbo', cCarb, tCarb, 'g',
          _C.carbColor, const Color(0xFFECFDF5))),
      const SizedBox(width: 10),
      Expanded(child: _buildMacroCard('🫒', 'Lemak', cFat, tFat, 'g',
          _C.fatColor, const Color(0xFFFEF2F2))),
    ]);
  }

  Widget _buildMacroCard(
    String emoji, String label,
    double current, double target, String unit,
    Color color, Color bgColor,
  ) {
    final progress = (current / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08),
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 4),
          Text(label, style: _T.tag.copyWith(color: color, letterSpacing: 0.8)),
        ]),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: current.toStringAsFixed(1),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: color, letterSpacing: -0.5),
            ),
            TextSpan(
              text: '/$unit',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.6)),
            ),
          ]),
        ),
        Text('${target.toInt()} $unit target',
            style: _T.cardLabel.copyWith(fontSize: 10)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(children: [
            Container(height: 5, color: color.withOpacity(0.15)),
            AnimatedFractionallySizedBox(
              widthFactor: progress,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
            color: _C.glow, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: _C.primary),
      ),
      const SizedBox(width: 10),
      Text(title, style: _T.sectionTitle),
    ]);
  }

  Widget _buildRecentHistory() {
    if (_recentHistory.isEmpty) return _buildEmptyHistory();

    return Column(
      children: _recentHistory.asMap().entries.map((e) {
        return _buildHistoryCard(e.value, e.key == _recentHistory.length - 1);
      }).toList(),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: _cardDecoration(),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              color: _C.glow, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.camera_alt_outlined,
              color: _C.primary, size: 28),
        ),
        const SizedBox(height: 14),
        const Text('Belum ada scan hari ini',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: _C.textDark)),
        const SizedBox(height: 6),
        const Text('Foto makanan Anda dan mulai\nmelacak nutrisi harian!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _C.textLight, height: 1.5)),
      ]),
    );
  }

  // ─── REDESAIN KARTU RIWAYAT (Lebih Premium, Indah, & Aman) ───
  Widget _buildHistoryCard(Map<String, dynamic> item, bool isLast) {
    final scannedAt = DateTime.fromMillisecondsSinceEpoch((item['scanned_at'] as int?) ?? 0);
    final timeStr = '${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
    final dateStr = '${scannedAt.day}/${scannedAt.month}';
    final imagePath = item['image_path'] as String?;
    final name = (item['indonesian_name'] as String? ?? 'Makanan').trim();
    final cal = item['calories'] as int? ?? 0;
    final protein = (item['protein'] as num?)?.toStringAsFixed(1) ?? '0.0';
    final carbs   = (item['carbs']   as num?)?.toStringAsFixed(1) ?? '0.0';
    final fat     = (item['fat']     as num?)?.toStringAsFixed(1) ?? '0.0';

    bool hasValidImage = false;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        hasValidImage = File(imagePath).existsSync();
      } catch (e) {
        hasValidImage = false;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
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
          height: 124, // Memaksakan batas tinggi vertikal mutlak untuk mencegah Layout Loop Freeze
          decoration: _cardDecoration(radius: 20),
          child: Row(children: [
            // Photo thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 96,
                height: 124,
                child: hasValidImage
                    ? Image.file(
                        File(imagePath!), 
                        fit: BoxFit.cover,
                        cacheWidth: 200, // Mengoptimalkan ram dan cpu (Menghindari ANR crash)
                        errorBuilder: (_, __, ___) => _thumbFallback(name),
                      )
                    : _thumbFallback(name),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pembagian ruang asri vertikal
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700, color: _C.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: _C.textLight.withOpacity(0.7), size: 20),
                    ]),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: _C.textLight),
                      const SizedBox(width: 4),
                      Text('$timeStr  ·  $dateStr', style: const TextStyle(fontSize: 11, color: _C.textLight)),
                    ]),
                    Row(children: [
                      _badge(icon: Icons.local_fire_department_rounded, label: '$cal kcal', color: _C.calColor),
                    ]),
                    Row(children: [
                      _macroPill('P', '$protein g', _C.protColor),
                      const SizedBox(width: 6),
                      _macroPill('K', '$carbs g', _C.carbColor),
                      const SizedBox(width: 6),
                      _macroPill('L', '$fat g', _C.fatColor),
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

  Widget _thumbFallback(String name) {
    return Container(
      color: _C.glow,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_rounded, color: _C.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.primary),
          ),
        ],
      ),
    );
  }

  Widget _macroPill(String abbr, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: '$abbr ',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                color: color, letterSpacing: 0.5),
          ),
          TextSpan(
            text: value,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: color),
          ),
        ]),
      ),
    );
  }

  // ─── Skeleton ─────────────────────────────
  Widget _buildSkeletonBody() {
    return Column(children: [
      const SizedBox(height: 20),
      _shimmerBox(height: 130, radius: 20),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _shimmerBox(height: 110, radius: 18)),
        const SizedBox(width: 10),
        Expanded(child: _shimmerBox(height: 110, radius: 18)),
        const SizedBox(width: 10),
        Expanded(child: _shimmerBox(height: 110, radius: 18)),
      ]),
      const SizedBox(height: 20),
      _shimmerBox(height: 90, radius: 20),
      const SizedBox(height: 10),
      _shimmerBox(height: 90, radius: 20),
    ]);
  }

  Widget _shimmerBox({required double height, double radius = 12}) {
    final controller = _shimmerController;
    if (controller == null) {
      return Container(
          height: height,
          decoration: BoxDecoration(
              color: const Color(0xFFE8EDE9),
              borderRadius: BorderRadius.circular(radius)));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + controller.value * 3, 0),
            end:   Alignment(0   + controller.value * 3, 0),
            colors: const [
              Color(0xFFE8EDE9), Color(0xFFF4F8F5), Color(0xFFE8EDE9),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4)),
      ],
    );
  }
}

class _GreetingInfo {
  final String greeting, emoji, tagline;
  const _GreetingInfo(this.greeting, this.emoji, this.tagline);
}