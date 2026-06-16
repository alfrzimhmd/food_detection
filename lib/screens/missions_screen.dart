// lib/screens/missions_screen.dart
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/text_style_helper.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.refreshMissionData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: Column(
        children: [
          _buildAppBar(),
          _buildStatsHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDailyMissionsTab(),
                _buildAchievementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  
  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Misi & Tantangan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Selesaikan misi dan kumpulkan poin',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATS HEADER
  // ============================================================
  
  Widget _buildStatsHeader() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final totalPoints = appState.totalPoints;
        final streak = appState.userStreak;
        final badgesCount = appState.badgesCount;
        final totalMissionsCompleted = appState.totalMissionsCompleted;
        final weeklyProgress = _calculateWeeklyProgressFromTotal(totalMissionsCompleted);
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                const Color(0xFF0F3D22),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.star_rounded,
                    value: totalPoints.toString(),
                    label: 'Total Poin',
                    color: const Color(0xFFFFD700),
                    gradientColors: [const Color(0xFFFFD700), const Color(0xFFFFA000)],
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    icon: Icons.local_fire_department_rounded,
                    value: '$streak',
                    label: 'Hari Streak',
                    color: const Color(0xFFFF5722),
                    gradientColors: [const Color(0xFFFF5722), const Color(0xFFE64A19)],
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    icon: Icons.workspace_premium_rounded,
                    value: badgesCount.toString(),
                    label: 'pencapaian',
                    color: const Color(0xFF9C27B0),
                    gradientColors: [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildStatCardSmall(
                    icon: Icons.emoji_events_rounded,
                    value: totalMissionsCompleted.toString(),
                    label: 'Misi Selesai',
                    color: const Color(0xFF00BCD4),
                    gradientColors: [const Color(0xFF00BCD4), const Color(0xFF00838F)],
                  ),
                  const SizedBox(width: 10),
                  _buildStatCardSmall(
                    icon: Icons.trending_up_rounded,
                    value: '$weeklyProgress%',
                    label: 'Progress Minggu',
                    color: const Color(0xFF4CAF50),
                    gradientColors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyleHelper.headingExtraBold(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyleHelper.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardSmall({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyleHelper.headingExtraBold(fontSize: 18, color: Colors.white),
                ),
                Text(
                  label,
                  style: TextStyleHelper.captionSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateWeeklyProgressFromTotal(int totalMissionsCompleted) {
    const weeklyTarget = 20;
    int progress = ((totalMissionsCompleted / weeklyTarget) * 100).toInt();
    return progress.clamp(0, 100);
  }

  // ============================================================
  // TAB BAR
  // ============================================================
  
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryExtraLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.primary,
        labelStyle: TextStyleHelper.labelMedium.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyleHelper.labelMedium.copyWith(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Misi Hari Ini'),
          Tab(text: 'Pencapaian'),
        ],
      ),
    );
  }

  // ============================================================
  // DAILY MISSIONS TAB
  // ============================================================
  
  Widget _buildDailyMissionsTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isMissionLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Memuat misi...'),
              ],
            ),
          );
        }
        
        final missions = appState.dailyMissions;
        
        if (missions.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => appState.refreshMissionData(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 400,
                child: _buildAllMissionsCompletedState(),
              ),
            ),
          );
        }
        
        // Cek apakah semua misi sudah selesai (completed atau claimed)
        final allCompleted = missions.every((m) => 
          m['status'] == 'completed' || m['status'] == 'claimed');
        
        if (allCompleted) {
          return RefreshIndicator(
            onRefresh: () => appState.refreshMissionData(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 400,
                child: _buildAllMissionsCompletedState(),
              ),
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => appState.refreshMissionData(),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];
              return _buildMissionCard(mission, index, appState);
            },
          ),
        );
      },
    );
  }

  Widget _buildAllMissionsCompletedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.carbs],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Semua Misi Selesai! 🎉',
            style: TextStyleHelper.titleMedium.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selamat! Anda telah menyelesaikan semua misi hari ini.',
            style: TextStyleHelper.bodySmall.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 4),
          Text(
            'Kembali besok untuk misi baru!',
            style: TextStyleHelper.caption.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission, int index, AppState appState) {
    final status = mission['status'] as String;
    final currentValue = mission['current_value'] as int? ?? 0;
    final targetCount = mission['target_count'] as int;
    final rewardPoints = mission['reward_points'] as int;
    final isCompleted = status == 'completed';
    final isClaimed = status == 'claimed';
    final missionProgressId = mission['id'] as int;
    final progress = currentValue / targetCount;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        elevation: isCompleted && !isClaimed ? 4 : 1,
        borderRadius: BorderRadius.circular(24),
        color: isCompleted && !isClaimed
            ? AppColors.accent
            : AppColors.cardColor(context),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (isCompleted && !isClaimed && !_isClaiming) {
              _handleClaimMission(context, missionProgressId, mission, appState);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getMissionColor(mission['name']),
                            _getMissionColor(mission['name']).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getMissionIcon(mission['name']),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission['name'] as String,
                            style: TextStyleHelper.titleMedium.copyWith(
                              color: isCompleted && !isClaimed
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildDifficultyBadge(mission['difficulty'] as String),
                        ],
                      ),
                    ),
                    if (!isClaimed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isCompleted
                              ? LinearGradient(
                                  colors: [Colors.white, Colors.white.withValues(alpha: 0.9)],
                                )
                              : LinearGradient(
                                  colors: [AppColors.accent, AppColors.accentDark],
                                ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: isCompleted
                                  ? AppColors.accent
                                  : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+$rewardPoints',
                              style: TextStyleHelper.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isCompleted
                                    ? AppColors.accent
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                
                Text(
                  mission['description'] as String,
                  style: TextStyleHelper.bodySmall.copyWith(
                    color: isCompleted && !isClaimed
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.textMedium,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                
                if (!isClaimed) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isCompleted && !isClaimed
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppColors.divider,
                            color: isCompleted && !isClaimed
                                ? Colors.white
                                : _getMissionColor(mission['name']),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted && !isClaimed
                              ? Colors.white.withValues(alpha: 0.2)
                              : _getMissionColor(mission['name']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$currentValue/$targetCount',
                          style: TextStyleHelper.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isCompleted && !isClaimed
                                ? Colors.white
                                : _getMissionColor(mission['name']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                
                if (isClaimed)
                  _buildStatusRow(Icons.check_circle_rounded, 'Sudah diklaim', Colors.grey),
                if (isCompleted && !isClaimed)
                  _buildClaimButton(mission['name'] as String, () {
                    _handleClaimMission(context, missionProgressId, mission, appState);
                  }),
                if (!isCompleted && !isClaimed && progress > 0)
                  _buildStatusRow(Icons.trending_up_rounded, 'Sedang berlangsung...', AppColors.info),
                if (!isCompleted && !isClaimed && progress == 0)
                  _buildStatusRow(Icons.access_time_rounded, 'Belum dimulai', AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Map<String, dynamic> style;
    
    switch (difficulty) {
      case 'easy':
        style = {'color': AppColors.success, 'text': 'Mudah', 'icon': Icons.sentiment_satisfied_rounded};
        break;
      case 'medium':
        style = {'color': AppColors.moderate, 'text': 'Sedang', 'icon': Icons.trending_up_rounded};
        break;
      case 'hard':
        style = {'color': AppColors.danger, 'text': 'Sulit', 'icon': Icons.bolt_rounded};
        break;
      default:
        style = {'color': AppColors.textLight, 'text': difficulty, 'icon': Icons.circle_rounded};
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (style['color'] as Color).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style['icon'] as IconData, size: 12, color: style['color'] as Color),
          const SizedBox(width: 4),
          Text(
            style['text'] as String,
            style: TextStyleHelper.caption.copyWith(
              color: style['color'] as Color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyleHelper.caption.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton(String missionName, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isClaiming ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isClaiming
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Klaim Hadiah',
                    style: TextStyleHelper.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // ACHIEVEMENTS TAB (Badges)
  // ============================================================
  
  Widget _buildAchievementsTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final badges = appState.badges;
        
        if (badges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryExtraLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum ada pencapaian',
                  style: TextStyleHelper.titleMedium.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selesaikan misi untuk mendapatkan pencapaian!',
                  style: TextStyleHelper.bodySmall.copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            return _buildBadgeCardAdvanced(badge);
          },
        );
      },
    );
  }

  Widget _buildBadgeCardAdvanced(Map<String, dynamic> badge) {
    final badgeName = badge['badge_name'] as String;
    final earnedDate = badge['earned_date'] as String;
    final formattedDate = _formatDate(earnedDate);
    
    Color getBadgeGradientStart(String name) {
      if (name.contains('Sayur') || name.contains('Serat')) return const Color(0xFF4CAF50);
      if (name.contains('Protein')) return const Color(0xFF2196F3);
      if (name.contains('Kalori')) return const Color(0xFFFF9800);
      if (name.contains('Sodium')) return const Color(0xFF9C27B0);
      if (name.contains('Gula')) return const Color(0xFFE91E63);
      if (name.contains('Konsisten') || name.contains('Streak')) return const Color(0xFFF44336);
      if (name.contains('Explorer')) return const Color(0xFF00BCD4);
      if (name.contains('Master')) return const Color(0xFF673AB7);
      return AppColors.primary;
    }
    
    Color getBadgeGradientEnd(String name) {
      if (name.contains('Sayur') || name.contains('Serat')) return const Color(0xFF2E7D32);
      if (name.contains('Protein')) return const Color(0xFF1565C0);
      if (name.contains('Kalori')) return const Color(0xFFF57C00);
      if (name.contains('Sodium')) return const Color(0xFF6A1B9A);
      if (name.contains('Gula')) return const Color(0xFFC2185B);
      if (name.contains('Konsisten') || name.contains('Streak')) return const Color(0xFFD32F2F);
      if (name.contains('Explorer')) return const Color(0xFF00838F);
      if (name.contains('Master')) return const Color(0xFF4527A0);
      return AppColors.primaryDark;
    }
    
    bool isRare = badgeName.contains('Master') || 
                  badgeName.contains('Explorer') || 
                  badgeName.contains('Perfect') ||
                  badgeName.contains('Extreme');
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              getBadgeGradientStart(badgeName),
              getBadgeGradientEnd(badgeName),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: getBadgeGradientStart(badgeName).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -5,
              left: -5,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getBadgeIcon(badgeName),
                      color: getBadgeGradientStart(badgeName),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    badgeName,
                    style: TextStyleHelper.titleSmall.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 10, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyleHelper.captionSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isRare)
              Positioned(
                top: 8,
                right: -20,
                child: Transform.rotate(
                  angle: 0.5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LANGKA',
                      style: TextStyleHelper.labelSmall.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CLAIM HANDLER
  // ============================================================
  
  Future<void> _handleClaimMission(BuildContext context, int missionProgressId, Map<String, dynamic> mission, AppState appState) async {
    if (_isClaiming) return;
    
    setState(() {
      _isClaiming = true;
    });
    
    final rewardPoints = mission['reward_points'] as int;
    final badgeName = mission['badge_name'] as String?;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Mengklaim hadiah...',
                style: TextStyleHelper.bodyMedium.copyWith(color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ),
    );
    
    try {
      final success = await appState.claimMissionReward(missionProgressId);
      
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        if (success) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (successContext) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.success, AppColors.carbs],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '🎉 Selamat! 🎉',
                    style: TextStyleHelper.headline4.copyWith(color: AppColors.success),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Anda telah menyelesaikan misi',
                    style: TextStyleHelper.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mission['name'] as String,
                    style: TextStyleHelper.titleMedium.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDark],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '+$rewardPoints Poin',
                          style: TextStyleHelper.titleMedium.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (badgeName != null && badgeName.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'pencapaian: $badgeName',
                            style: TextStyleHelper.titleMedium.copyWith(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(successContext),
                  child: Text('Lihat pencapaian', style: TextStyleHelper.labelMedium.copyWith(color: AppColors.primary)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(successContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
          
          await appState.refreshMissionData();
          
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Gagal mengklaim hadiah, coba lagi'),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Hari ini';
      } else if (difference.inDays == 1) {
        return 'Kemarin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari lalu';
      } else {
        return '${date.day} ${_getMonthName(date.month)} ${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
  
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }
  
  IconData _getMissionIcon(String missionName) {
    if (missionName.contains('Sayur') || missionName.contains('Serat') || missionName.contains('Fiber')) {
      return Icons.eco_rounded;
    } else if (missionName.contains('Protein')) {
      return Icons.fitness_center_rounded;
    } else if (missionName.contains('Kalori')) {
      return Icons.local_fire_department_rounded;
    } else if (missionName.contains('Sodium') || missionName.contains('Garam')) {
      return Icons.water_drop_rounded;
    } else if (missionName.contains('Gula') || missionName.contains('Sugar')) {
      return Icons.cookie_rounded;
    } else if (missionName.contains('Sehat') || missionName.contains('Health')) {
      return Icons.favorite_rounded;
    } else if (missionName.contains('Streak') || missionName.contains('Konsisten')) {
      return Icons.local_fire_department_rounded;
    } else if (missionName.contains('Breakfast') || missionName.contains('Pagi')) {
      return Icons.brightness_5_rounded;
    } else if (missionName.contains('Eksplorasi') || missionName.contains('Explorer')) {
      return Icons.explore_rounded;
    } else if (missionName.contains('Gorengan')) {
      return Icons.no_food_rounded;
    } else if (missionName.contains('Clean') || missionName.contains('Bersih')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.emoji_events_rounded;
  }
  
  Color _getMissionColor(String missionName) {
    if (missionName.contains('Sayur') || missionName.contains('Serat') || missionName.contains('Fiber')) {
      return AppColors.fiber;
    } else if (missionName.contains('Protein')) {
      return AppColors.protein;
    } else if (missionName.contains('Kalori')) {
      return AppColors.calories;
    } else if (missionName.contains('Sodium') || missionName.contains('Garam')) {
      return AppColors.sodium;
    } else if (missionName.contains('Gula') || missionName.contains('Sugar')) {
      return AppColors.sugar;
    } else if (missionName.contains('Sehat') || missionName.contains('Health')) {
      return AppColors.healthy;
    } else if (missionName.contains('Streak') || missionName.contains('Konsisten')) {
      return AppColors.warning;
    } else if (missionName.contains('Breakfast') || missionName.contains('Pagi')) {
      return const Color(0xFFFFA000);
    } else if (missionName.contains('Eksplorasi') || missionName.contains('Explorer')) {
      return const Color(0xFF7B1FA2);
    } else if (missionName.contains('Gorengan')) {
      return const Color(0xFFD84315);
    } else if (missionName.contains('Clean') || missionName.contains('Bersih')) {
      return AppColors.info;
    }
    return AppColors.primary;
  }
  
  IconData _getBadgeIcon(String badgeName) {
    if (badgeName.contains('Sayur') || badgeName.contains('Serat')) {
      return Icons.eco_rounded;
    } else if (badgeName.contains('Protein')) {
      return Icons.fitness_center_rounded;
    } else if (badgeName.contains('Kalori')) {
      return Icons.local_fire_department_rounded;
    } else if (badgeName.contains('Sodium')) {
      return Icons.water_drop_rounded;
    } else if (badgeName.contains('Gula')) {
      return Icons.cookie_rounded;
    } else if (badgeName.contains('Sehat') || badgeName.contains('Health')) {
      return Icons.favorite_rounded;
    } else if (badgeName.contains('Streak') || badgeName.contains('Konsisten')) {
      return Icons.local_fire_department_rounded;
    } else if (badgeName.contains('Breakfast')) {
      return Icons.brightness_5_rounded;
    } else if (badgeName.contains('Explorer') || badgeName.contains('Eksplorasi')) {
      return Icons.explore_rounded;
    } else if (badgeName.contains('Gorengan')) {
      return Icons.no_food_rounded;
    } else if (badgeName.contains('Master')) {
      return Icons.workspace_premium_rounded;
    }
    return Icons.workspace_premium_rounded;
  }
}