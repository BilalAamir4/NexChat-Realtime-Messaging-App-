import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  NexChat Design Tokens
// ─────────────────────────────────────────────
const _indigo = Color(0xFF4F46E5);
const _violet = Color(0xFF7C3AED);
const _indigo100 = Color(0xFFE0E7FF);
const _indigo200 = Color(0xFFC7D2FE);
const _cardSurface = Color(0xFFF7F8FF);
const _pageDark = Color(0xFFE8EEFF);
const _pageLight = Color(0xFFF0F4FF);
const _slateDark = Color(0xFF1E1B4B);
const _slateMid = Color(0xFF475569);
const _slateMuted = Color(0xFF94A3B8);

// ─────────────────────────────────────────────
//  Orb data model
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
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      final dx = sin(t * 2 * pi * orb.speed + orb.phaseX) * 0.04 * size.width;
      final dy = cos(t * 2 * pi * orb.speed + orb.phaseY) * 0.04 * size.height;
      final center = Offset(orb.x * size.width + dx, orb.y * size.height + dy);
      final rot = t * 2 * pi * 0.15 + orb.rotPhase;

      canvas.drawPath(
        _polygon(center, orb.radius, orb.sides, rot),
        Paint()
          ..color = orb.color.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawPath(
        _polygon(center, orb.radius * 0.68, orb.sides, rot + pi / orb.sides),
        Paint()
          ..color = orb.color.withOpacity(0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      canvas.drawPath(
        _polygon(center, orb.radius * 0.4, orb.sides, rot),
        Paint()
          ..color = orb.color.withOpacity(0.06)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(center, 2, Paint()..color = orb.color.withOpacity(0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.t != t;
}

// ─────────────────────────────────────────────
//  Step indicator widget
// ─────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current; // 0-indexed
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
            color: (isActive || isDone)
                ? _indigo
                : _indigo200,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
//  Register Screen
// ─────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_OrbData> _orbs;

  // Form state
  int _step = 0; // 0 = identity, 1 = credentials, 2 = avatar pick
  bool _obscure = true;
  bool _obscureConfirm = true;
  int _selectedAvatar = 0;

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Avatar palette options
  final List<Map<String, dynamic>> _avatarOptions = [
    {'label': 'NC', 'gradient': [const Color(0xFF4F46E5), const Color(0xFF7C3AED)]},
    {'label': 'NC', 'gradient': [const Color(0xFF0EA5E9), const Color(0xFF6366F1)]},
    {'label': 'NC', 'gradient': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]},
    {'label': 'NC', 'gradient': [const Color(0xFF10B981), const Color(0xFF3B82F6)]},
    {'label': 'NC', 'gradient': [const Color(0xFFF59E0B), const Color(0xFFEF4444)]},
    {'label': 'NC', 'gradient': [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]},
  ];

  @override
  void initState() {
    super.initState();

    final rng = Random(99);
    final colors = [_indigo, _violet, const Color(0xFF6366F1), const Color(0xFF818CF8)];
    _orbs = List.generate(14, (i) => _OrbData(
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
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
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

  // ── Shared field builder ─────────────────────
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _indigo200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _indigo.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          color: _slateDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _slateMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: _indigo.withOpacity(0.55), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ── Gradient primary button ──────────────────
  Widget _primaryButton(String label, VoidCallback onTap) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final pulse = (sin(_ctrl.value * 2 * pi) + 1) / 2;
        return GestureDetector(
          onTap: onTap,
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
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Back button ──────────────────────────────
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
        child: const Text(
          'Back',
          style: TextStyle(
            color: _indigo,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Step 0: Identity ─────────────────────────
  Widget _stepIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('Full Name'),
        const SizedBox(height: 8),
        _field(
          controller: _nameCtrl,
          hint: 'Your full name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),
        _sectionLabel('Username'),
        const SizedBox(height: 8),
        _field(
          controller: _usernameCtrl,
          hint: '@username',
          icon: Icons.alternate_email_rounded,
        ),
        const SizedBox(height: 28),
        _primaryButton('Continue', () => setState(() => _step = 1)),
      ],
    );
  }

  // ── Step 1: Credentials ──────────────────────
  Widget _stepCredentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('Email'),
        const SizedBox(height: 8),
        _field(
          controller: _emailCtrl,
          hint: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _sectionLabel('Password'),
        const SizedBox(height: 8),
        _field(
          controller: _passCtrl,
          hint: 'Create a password',
          icon: Icons.lock_outline_rounded,
          obscure: _obscure,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: _slateMuted,
              size: 20,
            ),
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
          suffix: GestureDetector(
            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
            child: Icon(
              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: _slateMuted,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _primaryButton('Continue', () => setState(() => _step = 2)),
        const SizedBox(height: 12),
        _backButton(() => setState(() => _step = 0)),
      ],
    );
  }

  // ── Step 2: Avatar ───────────────────────────
  Widget _stepAvatar() {
    final initials = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'NC';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview
        Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final pulse = (sin(_ctrl.value * 2 * pi) + 1) / 2;
              final grads = _avatarOptions[_selectedAvatar]['gradient'] as List<Color>;
              return Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: grads,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: grads[0].withOpacity(0.30 + 0.20 * pulse),
                      blurRadius: 20 + 12 * pulse,
                      spreadRadius: pulse * 3,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Your Name',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _slateDark,
            ),
          ),
        ),
        Center(
          child: Text(
            _usernameCtrl.text.trim().isNotEmpty
                ? '@${_usernameCtrl.text.trim()}'
                : '@username',
            style: const TextStyle(fontSize: 13, color: _slateMuted),
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('Choose your avatar color'),
        const SizedBox(height: 12),

        // Color swatches grid
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
            final grads = _avatarOptions[i]['gradient'] as List<Color>;
            final isSelected = _selectedAvatar == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedAvatar = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: grads,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
        _primaryButton('Create Account', () {
          Navigator.pushNamedAndRemoveUntil(context, '/chats', (_) => false);
        }),
        const SizedBox(height: 12),
        _backButton(() => setState(() => _step = 1)),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _slateMid,
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Header per step ──────────────────────────
  ({String title, String subtitle}) get _stepMeta => switch (_step) {
    0 => (title: 'Create Account', subtitle: 'Tell us who you are'),
    1 => (title: 'Set Credentials', subtitle: 'Secure your account'),
    _ => (title: 'Pick your look', subtitle: 'Choose an avatar color'),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _stepMeta;

    return Scaffold(
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
          builder: (context, _) {
            return Stack(
              children: [
                // ── Floating orbs ────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OrbPainter(orbs: _orbs, t: _ctrl.value),
                  ),
                ),

                // ── Content ──────────────────────
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
                                    color: _cardSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _indigo200, width: 1.2),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: _slateMid,
                                    size: 16,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 40),
                            const Spacer(),
                            // Logo pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: _cardSurface,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                Border.all(color: _indigo200, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [_indigo, _violet],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_rounded,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'NexChat',
                                    style: TextStyle(
                                      color: _slateDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
                              border:
                              Border.all(color: _indigo200, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: _indigo.withOpacity(0.10),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: _violet.withOpacity(0.06),
                                  blurRadius: 48,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Step indicator
                                _StepIndicator(current: _step, total: 3),
                                const SizedBox(height: 24),

                                // Title block
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Column(
                                    key: ValueKey(_step),
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        meta.title,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: _slateDark,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        meta.subtitle,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: _slateMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Step content with slide animation
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) {
                                    final offset = Tween<Offset>(
                                      begin: const Offset(0.08, 0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut,
                                    ));
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: offset,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey(_step),
                                    child: switch (_step) {
                                      0 => _stepIdentity(),
                                      1 => _stepCredentials(),
                                      _ => _stepAvatar(),
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
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                  color: _slateMuted, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                  color: _indigo,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}