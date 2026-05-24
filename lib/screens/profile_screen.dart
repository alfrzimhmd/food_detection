import 'package:flutter/material.dart';
import '../data/database_manager.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const Color primary      = Color(0xFF1B6B3A);
  static const Color primaryDark  = Color(0xFF0F3D22);
  static const Color glow         = Color(0xFFD6F5E3);
  static const Color bg           = Color(0xFFF2F7F4);
  static const Color card         = Colors.white;
  static const Color textDark     = Color(0xFF1A3328);
  static const Color textMid      = Color(0xFF5A7265);
  static const Color textLight    = Color(0xFFACC4B4);
  static const Color divider      = Color(0xFFE4EDE8);
  static const Color calColor     = Color(0xFFF59E0B);
  static const Color protColor    = Color(0xFF3B82F6);
  static const Color carbColor    = Color(0xFF10B981);
  static const Color fatColor     = Color(0xFFEF4444);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseManager _db = DatabaseManager();
  final _formKey  = GlobalKey<FormState>();
  final _nameCtr  = TextEditingController();
  final _calCtr   = TextEditingController();
  final _protCtr  = TextEditingController();
  final _carbsCtr = TextEditingController();
  final _fatCtr   = TextEditingController();

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
    _profile = await _db.getUserProfile();
    if (_profile != null) {
      _nameCtr.text  = _profile!['name']            ?? '';
      _calCtr.text   = (_profile!['target_calories'] ?? 2000).toString();
      _protCtr.text  = (_profile!['target_protein']  ?? 50.0).toString();
      _carbsCtr.text = (_profile!['target_carbs']    ?? 250.0).toString();
      _fatCtr.text   = (_profile!['target_fat']      ?? 65.0).toString();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    await _db.saveUserProfile(
      name:           _nameCtr.text.trim(),
      targetCalories: int.parse(_calCtr.text),
      targetProtein:  double.parse(_protCtr.text),
      targetCarbs:    double.parse(_carbsCtr.text),
      targetFat:      double.parse(_fatCtr.text),
    );
    setState(() { _isEditing = false; _isLoading = true; });
    await _loadProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Profil berhasil diperbarui!',
            style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: _C.primary,
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
    await _db.resetAllDataComplete();
    // ↑ Adjust to your actual reset method name
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/onboarding', (route) => false,
    );
  }

  Future<bool?> _showLogoutDialog() {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'logout',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => const _LogoutDialog(),
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
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: _C.primaryDark,
        elevation: 0,
        actions: [
          if (!_isLoading && !_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
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
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
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
          colors: [Color(0xFF23874A), _C.primaryDark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _C.primaryDark.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circles
          Positioned(right: -24, top: -24,
            child: Container(width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(left: -12, bottom: -20,
            child: Container(width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
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
                    color: Colors.white.withOpacity(0.35),
                    width: 2,
                  ),
                ),
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Text(
                  'Bergabung sejak ${_joinDate()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
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
        color: _C.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            color: _C.primary,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
          ),
          const SizedBox(height: 24),
          _cardSection('Target Nutrisi Harian', Icons.track_changes_rounded),
          const SizedBox(height: 14),
          _numField(ctr: _calCtr,   label: 'Target Kalori',      unit: 'kcal', icon: Icons.local_fire_department_rounded, color: _C.calColor),
          const SizedBox(height: 12),
          _numField(ctr: _protCtr,  label: 'Target Protein',     unit: 'g',    icon: Icons.fitness_center_rounded,        color: _C.protColor),
          const SizedBox(height: 12),
          _numField(ctr: _carbsCtr, label: 'Target Karbohidrat', unit: 'g',    icon: Icons.grain_rounded,                 color: _C.carbColor),
          const SizedBox(height: 12),
          _numField(ctr: _fatCtr,   label: 'Target Lemak',       unit: 'g',    icon: Icons.water_drop_rounded,            color: _C.fatColor),
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
            color: _C.glow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _C.primary, size: 15),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _C.textDark,
            letterSpacing: -0.2,
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
      labelStyle: TextStyle(
        color: active ? color : _C.textLight,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: active ? color : _C.textLight, size: 20),
      suffixText: suffix,
      suffixStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      filled: true,
      fillColor: active ? Colors.white : _C.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _C.divider, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _C.divider, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _C.divider, width: 1.5),
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _C.textDark,
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _C.textDark,
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
              foregroundColor: _C.textMid,
              side: const BorderSide(color: _C.divider, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Simpan',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
        border: Border.all(color: _C.fatColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: _C.fatColor.withOpacity(0.05),
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
          splashColor: _C.fatColor.withOpacity(0.08),
          highlightColor: _C.fatColor.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.fatColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: _C.fatColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keluar & Hapus Data',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _C.fatColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Menghapus semua riwayat dan data profil',
                        style: TextStyle(
                          fontSize: 11,
                          color: _C.fatColor.withOpacity(0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _C.fatColor.withOpacity(0.45),
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
                  color: Colors.black.withOpacity(0.18),
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
                      topLeft:  Radius.circular(28),
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
                              color: const Color(0xFFEF4444).withOpacity(0.20),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFEF4444),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Keluar dari Akun?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A3328),
                          letterSpacing: -0.5,
                          height: 1.1,
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
                      const Text(
                        'Semua data termasuk riwayat scan dan profil akan dihapus secara permanen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5A7265),
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Warning chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.18),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Tindakan ini tidak dapat dibatalkan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
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
                                foregroundColor: const Color(0xFF5A7265),
                                side: const BorderSide(
                                  color: Color(0xFFE4EDE8),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout_rounded, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Keluar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
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