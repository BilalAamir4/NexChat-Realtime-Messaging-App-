import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexchat_real_time_messaging_app/core/theme/app_theme.dart';
import 'package:nexchat_real_time_messaging_app/features/auth/providers/auth_provider.dart';
import 'package:nexchat_real_time_messaging_app/routes/app_routes.dart';

// ─────────────────────────────────────────────
//  Orb Data Model
// ─────────────────────────────────────────────
class _OrbData {
  final double x, y, radius, phaseX, phaseY, speed, rotPhase;
  final Color color;
  final int sides;

  const _OrbData({
    required this.x,
    required this.y,
    required this.radius,
    required this.phaseX,
    required this.phaseY,
    required this.speed,
    required this.rotPhase,
    required this.color,
    required this.sides,
  });
}

// ─────────────────────────────────────────────
//  Orb Painter
// ─────────────────────────────────────────────
class _OrbPainter extends CustomPainter {
  final List<_OrbData> orbs;
  final double t;

  const _OrbPainter({required this.orbs, required this.t});

  Path _polygon(Offset center, double r, int sides, double rotation) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = rotation + (2 * pi / sides) * i - pi / 2;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      final dx = sin(t * 2 * pi * orb.speed + orb.phaseX) * 0.04 * size.width;
      final dy =
          cos(t * 2 * pi * orb.speed + orb.phaseY) * 0.04 * size.height;
      final center =
      Offset(orb.x * size.width + dx, orb.y * size.height + dy);
      final rot = t * 2 * pi * 0.15 + orb.rotPhase;

      canvas.drawPath(
          _polygon(center, orb.radius, orb.sides, rot),
          Paint()
            ..color = orb.color.withOpacity(0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      canvas.drawPath(
          _polygon(
              center, orb.radius * 0.68, orb.sides, rot + pi / orb.sides),
          Paint()
            ..color = orb.color.withOpacity(0.10)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
      canvas.drawPath(
          _polygon(center, orb.radius * 0.4, orb.sides, rot),
          Paint()..color = orb.color.withOpacity(0.06));
      canvas.drawCircle(
          center, 2, Paint()..color = orb.color.withOpacity(0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.t != t;
}

// ─────────────────────────────────────────────
//  Step Indicator
// ─────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        final isDone = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: (isActive || isDone) ? NexColors.indigo : context.cardBorder,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
//  Register Screen
// ─────────────────────────────────────────────
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_OrbData> _orbs;

  int _step = 0;
  bool _obscure = true;
  bool _obscureConfirm = true;
  int _selectedAvatar = 0;
  String _pendingPhone = '';
  bool _checkingEmail = false;
  bool _checkingUsername = false;

  // ── Profile picture state ──────────────────
  File? _selectedImage;
  bool _useCustomImage = false;
  final _imagePicker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _avatarOptions = [
    {
      'gradient': [const Color(0xFF4F46E5), const Color(0xFF7C3AED)]
    },
    {
      'gradient': [const Color(0xFF0EA5E9), const Color(0xFF6366F1)]
    },
    {
      'gradient': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
    },
    {
      'gradient': [const Color(0xFF10B981), const Color(0xFF3B82F6)]
    },
    {
      'gradient': [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
    },
    {
      'gradient': [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]
    },
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random(99);
    final colors = [
      NexColors.indigo,
      NexColors.violet,
      const Color(0xFF6366F1),
      const Color(0xFF818CF8)
    ];
    _orbs = List.generate(
        14,
            (_) => _OrbData(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radius: 28 + rng.nextDouble() * 44,
          phaseX: rng.nextDouble() * 2 * pi,
          phaseY: rng.nextDouble() * 2 * pi,
          speed: 0.4 + rng.nextDouble() * 0.5,
          rotPhase: rng.nextDouble() * 2 * pi,
          color: colors[rng.nextInt(colors.length)],
          sides: rng.nextBool() ? 6 : 5,
        ));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ─── Image Picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;
      setState(() {
        _selectedImage = File(picked.path);
        _useCustomImage = true;
        _selectedAvatar = -1;
      });
    } catch (e) {
      if (mounted) _showError('Could not pick image. Please try again.');
    }
  }

  void _removeCustomImage() {
    setState(() {
      _selectedImage = null;
      _useCustomImage = false;
      _selectedAvatar = 0;
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.cardBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Profile photo',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            _sourceOption(
              Icons.photo_library_outlined,
              'Choose from gallery',
                  () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
            _sourceOption(
              Icons.camera_alt_outlined,
              'Take a photo',
                  () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_useCustomImage) ...[
              const SizedBox(height: 10),
              _sourceOption(
                Icons.delete_outline_rounded,
                'Remove photo',
                    () {
                  Navigator.pop(context);
                  _removeCustomImage();
                },
                danger: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sourceOption(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? const Color(0xFFEF4444) : NexColors.indigo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: context.isDark ? NexColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─── Sign Up ───────────────────────────────────────────────────────────────

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).signUp(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      displayName: _nameCtrl.text,
      username: _usernameCtrl.text,
      profileImage: _useCustomImage ? _selectedImage : null, // ← new
    );

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);

    if (state.isOtpPending) {
      _showPhoneSheet();
    } else if (state.isError) {
      _showError(state.error ?? 'Something went wrong.');
    }
  }

  // ─── Phone Sheet ───────────────────────────────────────────────────────────

  void _showPhoneSheet() {
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: context.cardBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text('One last step',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary)),
              const SizedBox(height: 6),
              Text(
                  'Enter your phone number to secure your account with SMS verification.',
                  style: TextStyle(fontSize: 14, color: context.textMuted)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: context.isDark ? NexColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                  Border.all(color: context.cardBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                        color: NexColors.indigo.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                      fontSize: 15,
                      color: context.textPrimary,
                      fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: '+92 300 1234567',
                    hintStyle:
                    TextStyle(color: context.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.phone_outlined,
                        color: NexColors.indigo, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authNotifierProvider);
                  return AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) {
                      final pulse = (sin(_ctrl.value * 2 * pi) + 1) / 2;
                      return GestureDetector(
                        onTap: authState.isLoading
                            ? null
                            : () {
                          final phone = phoneCtrl.text.trim();
                          if (phone.isEmpty) return;
                          _pendingPhone = phone;
                          ref
                              .read(authNotifierProvider.notifier)
                              .sendOtp(phoneNumber: phone);
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [NexColors.indigo, NexColors.violet],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: NexColors.indigo.withOpacity(
                                    0.25 + 0.20 * pulse),
                                blurRadius: 16 + 12 * pulse,
                                spreadRadius: pulse * 2,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: authState.isLoading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Text('Send code',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4)),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Shared Widgets ────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? NexColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
              color: NexColors.indigo.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
            fontSize: 15,
            color: context.textPrimary,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
          prefixIcon:
          Icon(icon, color: NexColors.indigo.withOpacity(0.55), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle:
          const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          errorBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap,
      {bool isLoading = false}) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final pulse = (sin(_ctrl.value * 2 * pi) + 1) / 2;
        return GestureDetector(
          onTap: isLoading ? null : onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [NexColors.indigo, NexColors.violet],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  NexColors.indigo.withOpacity(0.25 + 0.20 * pulse),
                  blurRadius: 16 + 12 * pulse,
                  spreadRadius: pulse * 2,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4)),
          ),
        );
      },
    );
  }

  Widget _backButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder, width: 1.2),
        ),
        alignment: Alignment.center,
        child: const Text('Back',
            style: TextStyle(
                color: NexColors.indigo,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
            letterSpacing: 0.3));
  }

  // ─── Step 0: Identity ──────────────────────────────────────────────────────

  Widget _stepIdentity() {
    return Form(
      key: _step0Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('Full Name'),
          const SizedBox(height: 8),
          _field(
            controller: _nameCtrl,
            hint: 'Your full name',
            icon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Please enter your name';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _sectionLabel('Username'),
          const SizedBox(height: 8),
          _field(
            controller: _usernameCtrl,
            hint: '@username',
            icon: Icons.alternate_email_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Please enter a username';
              if (v.trim().length < 3)
                return 'Username must be at least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: 28),
          _primaryButton(
              'Continue',
              _checkingUsername
                  ? null
                  : () async {
                if (!_step0Key.currentState!.validate()) return;
                FocusScope.of(context).unfocus();
                setState(() => _checkingUsername = true);
                final username =
                _usernameCtrl.text.trim().toLowerCase();
                try {
                  final query = await FirebaseFirestore.instance
                      .collection('users')
                      .where('username', isEqualTo: username)
                      .limit(1)
                      .get();
                  if (!mounted) return;
                  if (query.docs.isNotEmpty) {
                    _showError(
                        'That username is already taken. Please choose another.');
                  } else {
                    setState(() => _step = 1);
                  }
                } catch (e) {
                  if (!mounted) return;
                  _showError(
                      'Could not check username. Please try again.');
                } finally {
                  if (mounted)
                    setState(() => _checkingUsername = false);
                }
              },
              isLoading: _checkingUsername),
        ],
      ),
    );
  }

  // ─── Step 1: Credentials ───────────────────────────────────────────────────

  Widget _stepCredentials(bool isLoading) {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('Email'),
          const SizedBox(height: 8),
          _field(
            controller: _emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _sectionLabel('Password'),
          const SizedBox(height: 8),
          _field(
            controller: _passCtrl,
            hint: 'Create a password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a password';
              if (v.length < 6)
                return 'Password must be at least 6 characters';
              return null;
            },
            suffix: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: context.textMuted,
                  size: 20),
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Confirm Password'),
          const SizedBox(height: 8),
          _field(
            controller: _confirmCtrl,
            hint: 'Re-enter password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            validator: (v) {
              if (v == null || v.isEmpty)
                return 'Please confirm your password';
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
            suffix: GestureDetector(
              onTap: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: context.textMuted,
                  size: 20),
            ),
          ),
          const SizedBox(height: 28),
          _primaryButton(
              'Continue',
              _checkingEmail
                  ? null
                  : () async {
                if (!_step1Key.currentState!.validate()) return;
                FocusScope.of(context).unfocus();
                setState(() => _checkingEmail = true);
                try {
                  final methods = await FirebaseAuth.instance
                      .fetchSignInMethodsForEmail(
                      _emailCtrl.text.trim());
                  if (!mounted) return;
                  if (methods.isNotEmpty) {
                    _showError(
                        'An account already exists with this email.');
                  } else {
                    setState(() => _step = 2);
                  }
                } on FirebaseAuthException catch (e) {
                  if (!mounted) return;
                  _showError(
                    e.code == 'invalid-email'
                        ? 'Please enter a valid email address.'
                        : 'Could not verify email. Please try again.',
                  );
                } finally {
                  if (mounted)
                    setState(() => _checkingEmail = false);
                }
              },
              isLoading: isLoading || _checkingEmail),
          const SizedBox(height: 12),
          _backButton(() => setState(() => _step = 0)),
        ],
      ),
    );
  }

  // ─── Step 2: Avatar ────────────────────────────────────────────────────────

  Widget _stepAvatar(bool isLoading) {
    final initials = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text
        .trim()
        .split(' ')
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase()
        : 'NC';

    final activeGrads = (_selectedAvatar >= 0 && !_useCustomImage)
        ? _avatarOptions[_selectedAvatar]['gradient'] as List<Color>
        : [NexColors.indigo, NexColors.violet];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Avatar preview ────────────────────────────────────────────────
        Center(
          child: GestureDetector(
            onTap: _showImageSourceSheet,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final pulse = (sin(_ctrl.value * 2 * pi) + 1) / 2;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _useCustomImage
                            ? null
                            : LinearGradient(
                            colors: activeGrads,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        image: (_useCustomImage && _selectedImage != null)
                            ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: activeGrads[0]
                                .withOpacity(0.30 + 0.20 * pulse),
                            blurRadius: 20 + 12 * pulse,
                            spreadRadius: pulse * 3,
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _useCustomImage
                          ? null
                          : Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                    ),
                    // Camera badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: [NexColors.indigo, NexColors.violet]),
                          border: Border.all(
                              color: context.cardSurface, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                                color: NexColors.indigo.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Name & username preview ───────────────────────────────────────
        Center(
          child: Text(
            _nameCtrl.text.trim().isNotEmpty
                ? _nameCtrl.text.trim()
                : 'Your Name',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.textPrimary),
          ),
        ),
        Center(
          child: Text(
            _usernameCtrl.text.trim().isNotEmpty
                ? '@${_usernameCtrl.text.trim()}'
                : '@username',
            style: TextStyle(fontSize: 13, color: context.textMuted),
          ),
        ),

        const SizedBox(height: 20),

        // ── Divider with label ────────────────────────────────────────────
        Row(
          children: [
            Expanded(
                child: Divider(color: context.cardBorder, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _useCustomImage ? 'or use a color instead' : 'or choose a color',
                style: TextStyle(
                    fontSize: 12,
                    color: context.textMuted,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
                child: Divider(color: context.cardBorder, thickness: 1)),
          ],
        ),

        const SizedBox(height: 14),

        // ── Color swatch grid ─────────────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: _avatarOptions.length,
          itemBuilder: (ctx, i) {
            final grads =
            _avatarOptions[i]['gradient'] as List<Color>;
            final isSelected = !_useCustomImage && _selectedAvatar == i;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedAvatar = i;
                _useCustomImage = false;
                _selectedImage = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: grads,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  border: isSelected
                      ? Border.all(
                      color: context.textPrimary, width: 2.5)
                      : Border.all(
                      color: Colors.transparent, width: 2.5),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                        color: grads[0].withOpacity(0.4),
                        blurRadius: 10)
                  ]
                      : [],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 28),
        _primaryButton('Create Account', _signUp, isLoading: isLoading),
        const SizedBox(height: 12),
        _backButton(() => setState(() => _step = 1)),
      ],
    );
  }

  // ─── Step Meta ─────────────────────────────────────────────────────────────

  ({String title, String subtitle}) get _stepMeta => switch (_step) {
    0 => (title: 'Create Account', subtitle: 'Tell us who you are'),
    1 => (title: 'Set Credentials', subtitle: 'Secure your account'),
    _ => (
    title: 'Pick your look',
    subtitle: 'Upload a photo or choose a color'
    ),
  };

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final meta = _stepMeta;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!mounted) return;
      if (next.isCodeSent && _pendingPhone.isNotEmpty) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushNamed(context, AppRoutes.otp, arguments: {
          'verificationId': next.verificationId,
          'phoneNumber': _pendingPhone,
        });
        _pendingPhone = '';
      } else if (next.isAuthenticated) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.chat, (_) => false);
      } else if (next.isError && _pendingPhone.isNotEmpty) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showError(next.error ?? 'Failed to send OTP.');
        _pendingPhone = '';
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(gradient: context.pageGradient),
        child: Stack(
          children: [
            // ── Orb painter (only this rebuilds every frame) ──────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => CustomPaint(
                  painter: _OrbPainter(orbs: _orbs, t: _ctrl.value),
                ),
              ),
            ),

            // ── Static UI ─────────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        if (_step == 0)
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: context.cardSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: context.cardBorder, width: 1.2),
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: context.textSecondary, size: 16),
                            ),
                          )
                        else
                          const SizedBox(width: 40),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: context.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: context.cardBorder, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [
                                    NexColors.indigo,
                                    NexColors.violet
                                  ]),
                                ),
                                child: const Icon(
                                    Icons.chat_bubble_rounded,
                                    color: Colors.white,
                                    size: 10),
                              ),
                              const SizedBox(width: 6),
                              Text('NexChat',
                                  style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding:
                      const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: Container(
                        padding:
                        const EdgeInsets.fromLTRB(24, 28, 24, 28),
                        decoration: BoxDecoration(
                          color:
                          context.cardSurface.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: context.cardBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                                color: NexColors.indigo.withOpacity(0.10),
                                blurRadius: 32,
                                offset: const Offset(0, 12)),
                            BoxShadow(
                                color: NexColors.violet.withOpacity(0.06),
                                blurRadius: 48,
                                spreadRadius: 4,
                                offset: const Offset(0, 20)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StepIndicator(current: _step, total: 3),
                            const SizedBox(height: 24),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Column(
                                key: ValueKey(_step),
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(meta.title,
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: context.textPrimary,
                                          letterSpacing: -0.4)),
                                  const SizedBox(height: 4),
                                  Text(meta.subtitle,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: context.textMuted)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                final offset = Tween<Offset>(
                                  begin: const Offset(0.08, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut));
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                      position: offset, child: child),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey(_step),
                                child: switch (_step) {
                                  0 => _stepIdentity(),
                                  1 => _stepCredentials(
                                      authState.isLoading),
                                  _ => _stepAvatar(authState.isLoading),
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: TextStyle(
                                color: context.textMuted, fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Sign in',
                              style: TextStyle(
                                  color: NexColors.indigo,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
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
    );
  }
}