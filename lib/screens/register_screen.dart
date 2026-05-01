import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexchat_real_time_messaging_app/features/auth/providers/auth_provider.dart';
import 'package:nexchat_real_time_messaging_app/routes/app_routes.dart';

// ─────────────────────────────────────────────
//  NexChat Design Tokens
// ─────────────────────────────────────────────
const _indigo      = Color(0xFF4F46E5);
const _violet      = Color(0xFF7C3AED);
const _indigo200   = Color(0xFFC7D2FE);
const _cardSurface = Color(0xFFF7F8FF);
const _pageDark    = Color(0xFFE8EEFF);
const _pageLight   = Color(0xFFF0F4FF);
const _slateDark   = Color(0xFF1E1B4B);
const _slateMid    = Color(0xFF475569);
const _slateMuted  = Color(0xFF94A3B8);

// ─────────────────────────────────────────────
//  Orb Data Model
// ─────────────────────────────────────────────
class _OrbData {
  final double x, y, radius, phaseX, phaseY, speed, rotPhase;
  final Color color;
  final int sides;

  const _OrbData({
    required this.x, required this.y, required this.radius,
    required this.phaseX, required this.phaseY, required this.speed,
    required this.rotPhase, required this.color, required this.sides,
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
      final dy = cos(t * 2 * pi * orb.speed + orb.phaseY) * 0.04 * size.height;
      final center = Offset(orb.x * size.width + dx, orb.y * size.height + dy);
      final rot = t * 2 * pi * 0.15 + orb.rotPhase;

      canvas.drawPath(_polygon(center, orb.radius, orb.sides, rot),
          Paint()..color = orb.color.withOpacity(0.18)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.drawPath(_polygon(center, orb.radius * 0.68, orb.sides, rot + pi / orb.sides),
          Paint()..color = orb.color.withOpacity(0.10)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      canvas.drawPath(_polygon(center, orb.radius * 0.4, orb.sides, rot),
          Paint()..color = orb.color.withOpacity(0.06));
      canvas.drawCircle(center, 2, Paint()..color = orb.color.withOpacity(0.25));
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
        final isDone   = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: (isActive || isDone) ? _indigo : _indigo200,
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

  int    _step           = 0;
  bool   _obscure        = true;
  bool   _obscureConfirm = true;
  int    _selectedAvatar = 0;
  String _pendingPhone   = ''; // holds the phone number while waiting for codeSent
  bool   _checkingEmail    = false; // true while verifying email availability
  bool   _checkingUsername = false; // true while verifying username uniqueness

  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _avatarOptions = [
    {'gradient': [const Color(0xFF4F46E5), const Color(0xFF7C3AED)]},
    {'gradient': [const Color(0xFF0EA5E9), const Color(0xFF6366F1)]},
    {'gradient': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]},
    {'gradient': [const Color(0xFF10B981), const Color(0xFF3B82F6)]},
    {'gradient': [const Color(0xFFF59E0B), const Color(0xFFEF4444)]},
    {'gradient': [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]},
  ];

  @override
  void initState() {
    super.initState();
    final rng    = Random(99);
    final colors = [_indigo, _violet, const Color(0xFF6366F1), const Color(0xFF818CF8)];
    _orbs = List.generate(14, (_) => _OrbData(
      x: rng.nextDouble(), y: rng.nextDouble(),
      radius: 28 + rng.nextDouble() * 44,
      phaseX: rng.nextDouble() * 2 * pi, phaseY: rng.nextDouble() * 2 * pi,
      speed: 0.4 + rng.nextDouble() * 0.5,
      rotPhase: rng.nextDouble() * 2 * pi,
      color: colors[rng.nextInt(colors.length)],
      sides: rng.nextBool() ? 6 : 5,
    ));
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
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

  // ─── Sign Up ──────────────────────────────────────────────────────────────
  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).signUp(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      displayName: _nameCtrl.text,
      username: _usernameCtrl.text,
    );

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);

    if (state.isOtpPending) {
      _showPhoneSheet();
    } else if (state.isError) {
      _showError(state.error ?? 'Something went wrong.');
    }
  }

  // ─── Phone Bottom Sheet ───────────────────────────────────────────────────
  void _showPhoneSheet() {
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
          decoration: const BoxDecoration(
            color: _cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: _indigo200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('One last step',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _slateDark)),
              const SizedBox(height: 6),
              const Text('Enter your phone number to secure your account with SMS verification.',
                  style: TextStyle(fontSize: 14, color: _slateMuted)),
              const SizedBox(height: 24),

              // Phone field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _indigo200, width: 1.2),
                  boxShadow: [BoxShadow(color: _indigo.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 15, color: _slateDark, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: '+92 300 1234567',
                    hintStyle: TextStyle(color: _slateMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.phone_outlined, color: _indigo, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Send code button
              Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authNotifierProvider);
                  return AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) {
                      final pulse = (sin(_ctrl.value * 2 * pi) + 1) / 2;
                      return GestureDetector(
                        // FIX: fire-and-forget. verifyPhoneNumber callbacks fire
                        // AFTER the future returns, so await+poll always sees
                        // stale state. ref.listen in build() handles navigation.
                        onTap: authState.isLoading ? null : () {
                          final phone = phoneCtrl.text.trim();
                          if (phone.isEmpty) return;
                          _pendingPhone = phone;
                          ref.read(authNotifierProvider.notifier)
                              .sendOtp(phoneNumber: phone);
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [_indigo, _violet],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [BoxShadow(
                              color: _indigo.withOpacity(0.25 + 0.20 * pulse),
                              blurRadius: 16 + 12 * pulse,
                              spreadRadius: pulse * 2,
                              offset: const Offset(0, 4),
                            )],
                          ),
                          alignment: Alignment.center,
                          child: authState.isLoading
                              ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Send code',
                              style: TextStyle(color: Colors.white, fontSize: 16,
                                  fontWeight: FontWeight.w700, letterSpacing: 0.4)),
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

  // ─── Error Snack bar ───────────────────────────────────────────────────────
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Field Builder ────────────────────────────────────────────────────────
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _indigo200, width: 1.2),
        boxShadow: [BoxShadow(color: _indigo.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 15, color: _slateDark, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _slateMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: _indigo.withOpacity(0.55), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          errorBorder: InputBorder.none,
        ),
      ),
    );
  }

  // ─── Primary Button ───────────────────────────────────────────────────────
  Widget _primaryButton(String label, VoidCallback? onTap, {bool isLoading = false}) {
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
                colors: [_indigo, _violet],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [BoxShadow(
                color: _indigo.withOpacity(0.25 + 0.20 * pulse),
                blurRadius: 16 + 12 * pulse,
                spreadRadius: pulse * 2,
                offset: const Offset(0, 4),
              )],
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          ),
        );
      },
    );
  }

  // ─── Back Button ──────────────────────────────────────────────────────────
  Widget _backButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _indigo200, width: 1.2),
        ),
        alignment: Alignment.center,
        child: const Text('Back',
            style: TextStyle(color: _indigo, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: _slateMid, letterSpacing: 0.3));
  }

  // ─── Step 0: Identity ─────────────────────────────────────────────────────
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
              if (v == null || v.trim().isEmpty) return 'Please enter your name';
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
              if (v == null || v.trim().isEmpty) return 'Please enter a username';
              if (v.trim().length < 3) return 'Username must be at least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: 28),
          _primaryButton('Continue', _checkingUsername ? null : () async {
            if (!_step0Key.currentState!.validate()) return;
            FocusScope.of(context).unfocus();
            setState(() => _checkingUsername = true);
            try {
              final username = _usernameCtrl.text.trim().toLowerCase();
              final query = await FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isEqualTo: username)
                  .limit(1)
                  .get();
              if (!mounted) return;
              if (query.docs.isNotEmpty) {
                _showError('That username is already taken. Please choose another.');
              } else {
                setState(() => _step = 1);
              }
            } catch (e) {
              if (!mounted) return;
              _showError('Could not check username. Please try again.');
            } finally {
              if (mounted) setState(() => _checkingUsername = false);
            }
          }, isLoading: _checkingUsername),
        ],
      ),
    );
  }

  // ─── Step 1: Credentials ──────────────────────────────────────────────────
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
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
            suffix: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _slateMuted, size: 20),
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
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
            suffix: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _slateMuted, size: 20),
            ),
          ),
          const SizedBox(height: 28),
          _primaryButton('Continue', _checkingEmail ? null : () async {
            if (!_step1Key.currentState!.validate()) return;
            FocusScope.of(context).unfocus();
            setState(() => _checkingEmail = true);
            try {
              // Check if this email is already registered before going to step 2
              final methods = await FirebaseAuth.instance
                  .fetchSignInMethodsForEmail(_emailCtrl.text.trim());
              if (!mounted) return;
              if (methods.isNotEmpty) {
                // Email taken — show error inline, stay on step 1
                _showError('An account already exists with this email.');
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
              if (mounted) setState(() => _checkingEmail = false);
            }
          }, isLoading: isLoading || _checkingEmail),
          const SizedBox(height: 12),
          _backButton(() => setState(() => _step = 0)),
        ],
      ),
    );
  }

  // ─── Step 2: Avatar ───────────────────────────────────────────────────────
  Widget _stepAvatar(bool isLoading) {
    final initials = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'NC';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Avatar preview
        Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final pulse = (sin(_ctrl.value * 2 * pi) + 1) / 2;
              final grads = _avatarOptions[_selectedAvatar]['gradient'] as List<Color>;
              return Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: grads,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(
                    color: grads[0].withOpacity(0.30 + 0.20 * pulse),
                    blurRadius: 20 + 12 * pulse,
                    spreadRadius: pulse * 3,
                  )],
                ),
                alignment: Alignment.center,
                child: Text(initials,
                    style: const TextStyle(color: Colors.white, fontSize: 30,
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Your Name',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _slateDark),
          ),
        ),
        Center(
          child: Text(
            _usernameCtrl.text.trim().isNotEmpty ? '@${_usernameCtrl.text.trim()}' : '@username',
            style: const TextStyle(fontSize: 13, color: _slateMuted),
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('Choose your avatar color'),
        const SizedBox(height: 12),

        // Color swatches
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10,
          ),
          itemCount: _avatarOptions.length,
          itemBuilder: (ctx, i) {
            final grads = _avatarOptions[i]['gradient'] as List<Color>;
            final isSelected = _selectedAvatar == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedAvatar = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: grads,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: isSelected
                      ? Border.all(color: _slateDark, width: 2.5)
                      : Border.all(color: Colors.transparent, width: 2.5),
                  boxShadow: isSelected
                      ? [BoxShadow(color: grads[0].withOpacity(0.4), blurRadius: 10)]
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

  ({String title, String subtitle}) get _stepMeta => switch (_step) {
    0 => (title: 'Create Account', subtitle: 'Tell us who you are'),
    1 => (title: 'Set Credentials', subtitle: 'Secure your account'),
    _ => (title: 'Pick your look',  subtitle: 'Choose an avatar color'),
  };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final meta      = _stepMeta;

    // FIX: React to state changes here instead of polling after await.
    // verifyPhoneNumber fires callbacks asynchronously — by the time
    // await sendOtp() returns, state hasn't updated yet. ref.listen
    // fires on every transition so we always catch codeSent/error.
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!mounted) return;
      if (next.isCodeSent && _pendingPhone.isNotEmpty) {
        // Dismiss the bottom sheet, then navigate to OTP screen
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_pageDark, _pageLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => Stack(
            children: [
              // Floating orbs
              Positioned.fill(
                child: CustomPaint(painter: _OrbPainter(orbs: _orbs, t: _ctrl.value)),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          if (_step == 0)
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: _cardSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _indigo200, width: 1.2),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: _slateMid, size: 16),
                              ),
                            )
                          else
                            const SizedBox(width: 40),
                          const Spacer(),
                          // Logo pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: _cardSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _indigo200, width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18, height: 18,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: [_indigo, _violet]),
                                  ),
                                  child: const Icon(Icons.chat_bubble_rounded,
                                      color: Colors.white, size: 10),
                                ),
                                const SizedBox(width: 6),
                                const Text('NexChat',
                                    style: TextStyle(color: _slateDark,
                                        fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),

                    // Scrollable card
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                          decoration: BoxDecoration(
                            color: _cardSurface.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: _indigo200, width: 1.2),
                            boxShadow: [
                              BoxShadow(color: _indigo.withOpacity(0.10),
                                  blurRadius: 32, offset: const Offset(0, 12)),
                              BoxShadow(color: _violet.withOpacity(0.06),
                                  blurRadius: 48, spreadRadius: 4, offset: const Offset(0, 20)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StepIndicator(current: _step, total: 3),
                              const SizedBox(height: 24),

                              // Title
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Column(
                                  key: ValueKey(_step),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(meta.title,
                                        style: const TextStyle(fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: _slateDark, letterSpacing: -0.4)),
                                    const SizedBox(height: 4),
                                    Text(meta.subtitle,
                                        style: const TextStyle(fontSize: 14, color: _slateMuted)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Step content
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  final offset = Tween<Offset>(
                                    begin: const Offset(0.08, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                      parent: animation, curve: Curves.easeOut));
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(position: offset, child: child),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey(_step),
                                  child: switch (_step) {
                                    0 => _stepIdentity(),
                                    1 => _stepCredentials(authState.isLoading),
                                    _ => _stepAvatar(authState.isLoading),
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Already have account
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(color: _slateMuted, fontSize: 13)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('Sign in',
                                style: TextStyle(color: _indigo, fontSize: 13,
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
      ),
    );
  }
}