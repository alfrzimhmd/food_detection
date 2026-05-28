// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/text_style_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _calCtr = TextEditingController();
  final _protCtr = TextEditingController();
  final _carbsCtr = TextEditingController();
  final _fatCtr = TextEditingController();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _calCtr.dispose();
    _protCtr.dispose();
    _carbsCtr.dispose();
    _fatCtr.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    final appState = Provider.of<AppState>(context, listen: false);
    _profile = appState.userProfile;
    
    if (_profile != null) {
      _nameCtr.text = _profile!['name'] ?? '';
      _calCtr.text = (_profile!['target_calories'] ?? 2000).toString();
      _protCtr.text = (_profile!['target_protein'] ?? 50.0).toString();
      _carbsCtr.text = (_profile!['target_carbs'] ?? 250.0).toString();
      _fatCtr.text = (_profile!['target_fat'] ?? 65.0).toString();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.saveUserProfile(
      name: _nameCtr.text.trim(),
      targetCalories: int.parse(_calCtr.text),
      targetProtein: double.parse(_protCtr.text),
      targetCarbs: double.parse(_carbsCtr.text),
      targetFat: double.parse(_fatCtr.text),
    );
    
    setState(() {
      _isEditing = false;
      _isLoading = true;
    });
    await _loadProfile();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Profil berhasil diperbarui!',
              style: TextStyleHelper.bold(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutDialog();
    if (confirmed != true || !mounted) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.resetAllData();
    
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding', (route) => false,
      );
    }
  }

  Future<bool?> _showLogoutDialog() {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'logout',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, _) => const _LogoutDialog(),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  String _joinDate() {
    final v = _profile?['created_at'];
    if (v == null) return 'Baru Saja';
    final d = DateTime.fromMillisecondsSinceEpoch(v as int);
    return '${d.day}/${d.month}/${d.year}';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: TextStyleHelper.titleMedium.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        actions: [
          if (!_isLoading && !_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                ),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildFormCard(),
                    const SizedBox(height: 16),
                    if (_isEditing) ...[
                      _buildActionRow(),
                      const SizedBox(height: 16),
                    ],
                    _buildLogoutTile(),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Profile header ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF23874A), AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circles
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -12,
            bottom: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Column(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _profile?['name'] ?? 'Pengguna',
                textAlign: TextAlign.center,
                style: TextStyleHelper.displaySmall.copyWith(
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Text(
                  'Bergabung sejak ${_joinDate()}',
                  style: TextStyleHelper.labelMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Form card ──────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardSection('Informasi Pribadi', Icons.badge_outlined),
          const SizedBox(height: 14),
          _textField(
            ctr: _nameCtr,
            label: 'Nama Lengkap',
            icon: Icons.person_outline_rounded,
            color: AppColors.primary,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
          ),
          const SizedBox(height: 24),
          _cardSection('Target Nutrisi Harian', Icons.track_changes_rounded),
          const SizedBox(height: 14),
          _numField(
            ctr: _calCtr,
            label: 'Target Kalori',
            unit: 'kcal',
            icon: Icons.local_fire_department_rounded,
            color: AppColors.calories,
          ),
          const SizedBox(height: 12),
          _numField(
            ctr: _protCtr,
            label: 'Target Protein',
            unit: 'g',
            icon: Icons.fitness_center_rounded,
            color: AppColors.protein,
          ),
          const SizedBox(height: 12),
          _numField(
            ctr: _carbsCtr,
            label: 'Target Karbohidrat',
            unit: 'g',
            icon: Icons.grain_rounded,
            color: AppColors.carbs,
          ),
          const SizedBox(height: 12),
          _numField(
            ctr: _fatCtr,
            label: 'Target Lemak',
            unit: 'g',
            icon: Icons.water_drop_rounded,
            color: AppColors.fat,
          ),
        ],
      ),
    );
  }

  Widget _cardSection(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.glow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 15),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: TextStyleHelper.titleSmall.copyWith(
            fontSize: 14,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  InputDecoration _dec({
    required String label,
    required IconData icon,
    required Color color,
    String? suffix,
  }) {
    final active = _isEditing;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyleHelper.labelMedium.copyWith(
        color: active ? color : AppColors.textLight,
      ),
      prefixIcon: Icon(icon, color: active ? color : AppColors.textLight, size: 20),
      suffixText: suffix,
      suffixStyle: TextStyleHelper.labelMedium.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: active ? Colors.white : AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: 2),
      ),
    );
  }

  Widget _textField({
    required TextEditingController ctr,
    required String label,
    required IconData icon,
    required Color color,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctr,
      enabled: _isEditing,
      style: TextStyleHelper.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      decoration: _dec(label: label, icon: icon, color: color),
      validator: validator,
    );
  }

  Widget _numField({
    required TextEditingController ctr,
    required String label,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: ctr,
      enabled: _isEditing,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyleHelper.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      decoration: _dec(label: label, icon: icon, color: color, suffix: unit),
      validator: (v) {
        if (v == null || v.isEmpty) return '$label tidak boleh kosong';
        if (double.tryParse(v) == null) return 'Masukkan nilai angka yang valid';
        return null;
      },
    );
  }

  // ─── Action row ─────────────────────────────────────────────────────────────
  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() => _isEditing = false);
              _loadProfile();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMedium,
              side: const BorderSide(color: AppColors.divider, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyleHelper.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Simpan',
              style: TextStyleHelper.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Logout tile ────────────────────────────────────────────────────────────
  Widget _buildLogoutTile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fat.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.fat.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.fat.withValues(alpha: 0.08),
          highlightColor: AppColors.fat.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.fat.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.fat,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keluar & Hapus Data',
                        style: TextStyleHelper.titleSmall.copyWith(
                          fontSize: 14,
                          color: AppColors.fat,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Menghapus semua riwayat dan data profil',
                        style: TextStyleHelper.captionSmall.copyWith(
                          color: AppColors.fat.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.fat.withValues(alpha: 0.45),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Logout Dialog (separate StatelessWidget for clean code) ──────────────────
class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top section with gradient ─────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFECEC), Color(0xFFFFF5F5)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Icon container
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.fat.withValues(alpha: 0.20),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.fat,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Keluar dari Akun?',
                        textAlign: TextAlign.center,
                        style: TextStyleHelper.headline3.copyWith(
                          fontSize: 20,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom section ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Column(
                    children: [
                      Text(
                        'Semua data termasuk riwayat scan dan profil akan dihapus secara permanen.',
                        textAlign: TextAlign.center,
                        style: TextStyleHelper.bodySmall.copyWith(
                          color: AppColors.textMedium,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Warning chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.fat.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.fat.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: AppColors.fat,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tindakan ini tidak dapat dibatalkan',
                              style: TextStyleHelper.labelSmall.copyWith(
                                color: AppColors.fat,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textMedium,
                                side: const BorderSide(
                                  color: AppColors.divider,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: TextStyleHelper.labelLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.fat,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.logout_rounded, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Keluar',
                                    style: TextStyleHelper.labelLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}