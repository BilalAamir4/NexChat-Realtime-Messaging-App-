import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexchat_real_time_messaging_app/features/auth/providers/auth_provider.dart';
import 'package:nexchat_real_time_messaging_app/routes/app_routes.dart';

// ─────────────────────────────────────────────
//  NexChat Design Tokens
// ─────────────────────────────────────────────
const _indigo      = Color(0xFF4F46E5);
const _violet      = Color(0xFF7C3AED);
const _indigo100   = Color(0xFFE0E7FF);
const _indigo200   = Color(0xFFC7D2FE);
const _cardSurface = Color(0xFFF7F8FF);
const _pageDark    = Color(0xFFE8EEFF);
const _pageLight   = Color(0xFFF0F4FF);
const _slateDark   = Color(0xFF1E1B4B);
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
      final rotation = t * 2 * pi * 0.15 + orb.rotPhase;

      canvas.drawPath(_polygon(center, orb.radius, orb.sides, rotation),
          Paint()..color = orb.color.withOpacity(0.18)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.drawPath(_polygon(center, orb.radius * 0.68, orb.sides, rotation + pi / orb.sides),
          Paint()..color = orb.color.withOpacity(0.10)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      canvas.drawPath(_polygon(center, orb.radius * 0.4, orb.sides, rotation),
          Paint()..color = orb.color.withOpacity(0.06));
      canvas.drawCircle(center, 2, Paint()..color = orb.color.withOpacity(0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.t != t;
}

// ─────────────────────────────────────────────
//  Login Screen
// ─────────────────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_OrbData> _orbs;

  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _obscure       = true;

  @override
  void initState() {
    super.initState();
    final rng    = Random(42);
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).signIn(
      email: _emailCtrl.text,
      password: _passCtrl.text,
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
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: _indigo200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Verify your identity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _slateDark)),
              const SizedBox(height: 6),
              const Text('Enter your phone number to receive a one-time code.',
                  style: TextStyle(fontSize: 14, color: _slateMuted)),
              const SizedBox(height: 24),

              // Phone field — same style as card fields
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
                        onTap: authState.isLoading ? null : () async {
                          final phone = phoneCtrl.text.trim();
                          if (phone.isEmpty) return;
                          Navigator.pop(context);

                          await ref.read(authNotifierProvider.notifier)
                              .sendOtp(phoneNumber: phone);

                          if (!mounted) return;
                          final s = ref.read(authNotifierProvider);
                          if (s.isCodeSent) {
                            Navigator.pushNamed(context, AppRoutes.otp,
                                arguments: {
                                  'verificationId': s.verificationId,
                                  'phoneNumber': phone,
                                });
                          } else if (s.isError) {
                            _showError(s.error ?? 'Failed to send OTP.');
                          }
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
                            boxShadow: [
                              BoxShadow(
                                color: _indigo.withOpacity(0.25 + 0.20 * pulse),
                                blurRadius: 16 + 12 * pulse,
                                spreadRadius: pulse * 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
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

  // ─── Error Snackbar ───────────────────────────────────────────────────────
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Input Field ──────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
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

  // ─── Aurora Button ────────────────────────────────────────────────────────
  Widget _loginButton(bool isLoading) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final pulse = (sin(_ctrl.value * 2 * pi) + 1) / 2;
        return GestureDetector(
          onTap: isLoading ? null : _signIn,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [_indigo, _violet],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _indigo.withOpacity(0.25 + 0.20 * pulse),
                  blurRadius: 16 + 12 * pulse,
                  spreadRadius: pulse * 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Sign in',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          ),
        );
      },
    );
  }

  // ─── Logo Mark ────────────────────────────────────────────────────────────
  Widget _logoMark() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final glow = (sin(_ctrl.value * 2 * pi) + 1) / 2;
        return Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_indigo, _violet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(
                  color: _indigo.withOpacity(0.30 + 0.20 * glow),
                  blurRadius: 20 + 12 * glow,
                  spreadRadius: glow * 3,
                )],
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 14),
            const Text('NexChat',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                    color: _slateDark, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text('Welcome back',
                style: TextStyle(fontSize: 14, color: _slateMuted, letterSpacing: 0.2)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

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

              // Card
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                        decoration: BoxDecoration(
                          color: _cardSurface.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: _indigo200, width: 1.2),
                          boxShadow: [
                            BoxShadow(color: _indigo.withOpacity(0.10), blurRadius: 32, offset: const Offset(0, 12)),
                            BoxShadow(color: _violet.withOpacity(0.06), blurRadius: 48, spreadRadius: 4, offset: const Offset(0, 20)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: _logoMark()),
                            const SizedBox(height: 36),

                            // Email
                            _field(
                              controller: _emailCtrl,
                              hint: 'Email address',
                              icon: Icons.email_outlined,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter your email';
                                if (!v.contains('@')) return 'Please enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
                            _field(
                              controller: _passCtrl,
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscure,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter your password';
                                if (v.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                              suffix: GestureDetector(
                                onTap: () => setState(() => _obscure = !_obscure),
                                child: Icon(
                                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: _slateMuted, size: 20,
                                ),
                              ),
                            ),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4)),
                                child: const Text('Forgot password?',
                                    style: TextStyle(color: _indigo, fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Sign in button
                            _loginButton(authState.isLoading),
                            const SizedBox(height: 24),

                            // Divider
                            Row(children: [
                              Expanded(child: Divider(color: _indigo200, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or', style: TextStyle(color: _slateMuted, fontSize: 13)),
                              ),
                              Expanded(child: Divider(color: _indigo200, thickness: 1)),
                            ]),
                            const SizedBox(height: 20),

                            // Create account
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _indigo200, width: 1.2),
                                ),
                                alignment: Alignment.center,
                                child: const Text('Create account',
                                    style: TextStyle(color: _indigo, fontSize: 15,
                                        fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}