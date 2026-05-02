import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexchat_real_time_messaging_app/features/auth/providers/auth_provider.dart';
import 'package:nexchat_real_time_messaging_app/routes/app_routes.dart';

// ─────────────────────────────────────────────
//  Design Tokens
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
//  Orb Data + Painter (same as login/register)
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
//  Single OTP digit box
// ─────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFilled;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: isFilled ? _indigo.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFilled ? _indigo : _indigo200,
          width: isFilled ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _indigo.withOpacity(isFilled ? 0.12 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _slateDark,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  OTP Screen
// ─────────────────────────────────────────────
class OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_OrbData> _orbs;

  // 6 OTP boxes
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  // Resend countdown
  int _secondsLeft = 60;
  bool _canResend  = false;

  @override
  void initState() {
    super.initState();

    // Orbs
    final rng    = Random(77);
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

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))..repeat();

    // Start countdown
    _startCountdown();

    for (int i = 0; i < 6; i++) {
      final index = i;
      _otpControllers[index].addListener(() {
        if (index < 5 && _otpControllers[index].text.isNotEmpty) {
          _focusNodes[index + 1].requestFocus();
        }
        setState(() {});
      });
    }

    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startCountdown() async {
    for (int i = 60; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _secondsLeft = i;
        if (i == 0) _canResend = true;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ─── Get full OTP string ──────────────────────────────────────────────────
  String get _otpCode => _otpControllers.map((c) => c.text).join();



  // ─── Handle backspace ─────────────────────────────────────────────────────
  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
      setState(() {});
    }
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      _showError('Please enter the complete 6-digit code.');
      return;
    }
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).verifyOtp(
      verificationId: widget.verificationId,
      otpCode: _otpCode,
    );

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);

    if (state.isAuthenticated) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.dashboard, (_) => false);
    } else if (state.isError) {
      _showError(state.error ?? 'Invalid code. Please try again.');
      for (final c in _otpControllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      setState(() {});
    }
  }
  // ─── Resend OTP ───────────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() { _canResend = false; _secondsLeft = 60; });

    await ref.read(authNotifierProvider.notifier)
        .sendOtp(phoneNumber: widget.phoneNumber);

    _startCountdown();

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.isError) {
      _showError(state.error ?? 'Failed to resend code.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Code resent successfully'),
        backgroundColor: _indigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
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

  // ─── Verify Button ────────────────────────────────────────────────────────
  Widget _verifyButton(bool isLoading) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final pulse = (sin(_ctrl.value * 2 * pi) + 1) / 2;
        return GestureDetector(
          onTap: isLoading ? null : _verifyOtp,
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
                : const Text('Verify',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Mask phone: +92 300 ****567
    final masked = widget.phoneNumber.length > 6
        ? '${widget.phoneNumber.substring(0, widget.phoneNumber.length - 6)}'
        '****'
        '${widget.phoneNumber.substring(widget.phoneNumber.length - 3)}'
        : widget.phoneNumber;

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
          builder: (context, _) => Stack(
            children: [
              // Orbs
              Positioned.fill(
                child: CustomPaint(
                    painter: _OrbPainter(orbs: _orbs, t: _ctrl.value)),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
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
                          ),
                          const Spacer(),
                          // Logo pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
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
                                    gradient: LinearGradient(
                                        colors: [_indigo, _violet]),
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

                    // Card
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                          decoration: BoxDecoration(
                            color: _cardSurface.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: _indigo200, width: 1.2),
                            boxShadow: [
                              BoxShadow(color: _indigo.withOpacity(0.10),
                                  blurRadius: 32, offset: const Offset(0, 12)),
                              BoxShadow(color: _violet.withOpacity(0.06),
                                  blurRadius: 48, spreadRadius: 4,
                                  offset: const Offset(0, 20)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              // Shield icon
                              Center(
                                child: AnimatedBuilder(
                                  animation: _ctrl,
                                  builder: (context, _) {
                                    final glow = (sin(_ctrl.value * 2 * pi) + 1) / 2;
                                    return Container(
                                      width: 72, height: 72,
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
                                      child: const Icon(Icons.shield_outlined,
                                          color: Colors.white, size: 34),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Title
                              const Text('Verify your phone',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: _slateDark, letterSpacing: -0.4)),
                              const SizedBox(height: 8),

                              // Subtitle with masked number
                              Text(
                                'Enter the 6-digit code sent to\n$masked',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 14, color: _slateMuted, height: 1.5),
                              ),
                              const SizedBox(height: 36),

                              // OTP boxes
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (i) => KeyboardListener(
                                  focusNode: FocusNode(),
                                  onKeyEvent: (event) => _onKeyEvent(i, event),
                                  child: _OtpBox(
                                    controller: _otpControllers[i],
                                    focusNode: _focusNodes[i],
                                    isFilled: _otpControllers[i].text.isNotEmpty,
                                  ),
                                )),
                              ),

                              // Resend row
                              Center(
                                child: _canResend
                                    ? GestureDetector(
                                  onTap: _resendOtp,
                                  child: const Text('Resend code',
                                      style: TextStyle(color: _indigo,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                )
                                    : Text(
                                  'Resend code in ${_secondsLeft}s',
                                  style: const TextStyle(
                                      color: _slateMuted, fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Verify button
                              _verifyButton(authState.isLoading),
                            ],
                          ),
                        ),
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