import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexchat_real_time_messaging_app/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Color tokens ────────────────────────────────────────────────────────────
const _indigo    = Color(0xFF4F46E5);
const _violet    = Color(0xFF7C3AED);
const _indigo100 = Color(0xFFE0E7FF);
const _indigo200 = Color(0xFFC7D2FE);
const _slateDark = Color(0xFF1E1B4B);

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _constellationCtrl;
  late final AnimationController _constellationFadeCtrl;
  late final Animation<double>   _constellationFade;
  late final AnimationController _beamCtrl;
  late final Animation<double>   _beamProgress;
  late final AnimationController _rippleCtrl;
  late final Animation<double>   _rippleRadius;
  late final Animation<double>   _rippleOpacity;
  late final AnimationController _iconCtrl;
  late final Animation<double>   _iconScale;
  late final Animation<double>   _iconOpacity;
  late final Animation<double>   _iconGlow;
  late final AnimationController _wordCtrl;
  late final Animation<double>   _wordOpacity;
  late final Animation<Offset>   _wordSlide;
  late final Animation<double>   _tagOpacity;
  late final AnimationController _overlayCtrl;
  late final Animation<double>   _overlayOpacity;

  double _beamX = -0.2;

  @override
  void initState() {
    super.initState();

    _constellationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _constellationFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _constellationFade = CurvedAnimation(
      parent: _constellationFadeCtrl,
      curve: Curves.easeOut,
    );

    _beamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _beamProgress = Tween<double>(begin: -0.2, end: 1.2).animate(
      CurvedAnimation(parent: _beamCtrl, curve: Curves.easeInOut),
    );
    _beamCtrl.addListener(() => setState(() => _beamX = _beamProgress.value));

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _rippleRadius = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeIn),
    );

    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _iconGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _wordCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _wordOpacity = CurvedAnimation(parent: _wordCtrl, curve: Curves.easeOut);
    _wordSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _wordCtrl, curve: Curves.easeOut));
    _tagOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _wordCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _overlayOpacity = Tween<double>(begin: 0.88, end: 0.0).animate(
      CurvedAnimation(parent: _overlayCtrl, curve: Curves.easeOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    _constellationFadeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    _beamCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 650));

    _rippleCtrl.forward();
    _overlayCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));

    _iconCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 700));

    await _wordCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // ── Update lastSeen for returning users ──────────────────────────────────
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'lastSeen': FieldValue.serverTimestamp()});
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      user != null ? AppRoutes.dashboard : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _constellationCtrl.dispose();
    _constellationFadeCtrl.dispose();
    _beamCtrl.dispose();
    _rippleCtrl.dispose();
    _iconCtrl.dispose();
    _wordCtrl.dispose();
    _overlayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerY = size.height * 0.42;

    return Scaffold(
      backgroundColor: _slateDark,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── 1. Deep background gradient ───────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF080720),
                  Color(0xFF1E1B4B),
                  Color(0xFF2D1B69),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── 2. Constellation network ──────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([
              _constellationCtrl,
              _constellationFadeCtrl,
            ]),
            builder: (_, _) => CustomPaint(
              painter: _ConstellationPainter(
                tick:        _constellationCtrl.value,
                fadeIn:      _constellationFade.value,
                beamX:       _beamX,
                screenWidth: size.width,
              ),
            ),
          ),

          // ── 3. Scan-line texture ──────────────────────────────────────
          CustomPaint(painter: _ScanLinePainter()),

          // ── 4. Dark vignette ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _overlayOpacity,
            builder: (_, _) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Colors.black.withValues(alpha: _overlayOpacity.value * 0.3),
                    Colors.black.withValues(alpha: _overlayOpacity.value * 0.92),
                  ],
                ),
              ),
            ),
          ),

          // ── 5. Beam of light ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _beamCtrl,
            builder: (_, _) {
              if (_beamCtrl.isCompleted) return const SizedBox.shrink();
              return CustomPaint(
                painter: _BeamPainter(
                  beamX:        _beamX,
                  screenWidth:  size.width,
                  screenHeight: size.height,
                ),
              );
            },
          ),

          // ── 6. Ripple burst ───────────────────────────────────────────
          AnimatedBuilder(
            animation: _rippleCtrl,
            builder: (_, _) {
              if (_rippleCtrl.isDismissed) return const SizedBox.shrink();
              return CustomPaint(
                painter: _RipplePainter(
                  cx:      size.width / 2,
                  cy:      centerY,
                  radius:  _rippleRadius.value * size.width * 0.65,
                  opacity: _rippleOpacity.value,
                ),
              );
            },
          ),

          // ── 7. Icon + wordmark ────────────────────────────────────────
          Column(
            children: [
              SizedBox(height: (centerY - 50).clamp(0.0, double.infinity)),
              AnimatedBuilder(
                animation: _iconCtrl,
                builder: (_, _) => Transform.scale(
                  scale: _iconScale.value,
                  child: Opacity(
                    opacity: _iconOpacity.value,
                    child: _NexChatIcon(
                      size: 100,
                      glowIntensity: _iconGlow.value,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              AnimatedBuilder(
                animation: _wordCtrl,
                builder: (_, _) => SlideTransition(
                  position: _wordSlide,
                  child: FadeTransition(
                    opacity: _wordOpacity,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [_indigo200, Colors.white, _indigo100],
                            stops: [0.0, 0.5, 1.0],
                          ).createShader(b),
                          child: const Text(
                            'NEXCHAT',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 10,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: _tagOpacity,
                          child: Text(
                            'connect beyond limits',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 3.5,
                              fontWeight: FontWeight.w400,
                              color: _indigo200.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              AnimatedBuilder(
                animation: _wordCtrl,
                builder: (_, _) => FadeTransition(
                  opacity: _wordOpacity,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 56),
                    child: _LoaderBar(progress: _constellationCtrl),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Constellation Painter ────────────────────────────────────────────────────
class _ConstellationPainter extends CustomPainter {
  final double tick;
  final double fadeIn;
  final double beamX;
  final double screenWidth;

  static final _rand = math.Random(7);
  static final _nodes = List.generate(60, (_) => _ConstellationNode(
    x:     _rand.nextDouble(),
    y:     _rand.nextDouble(),
    vx:    (_rand.nextDouble() - 0.5) * 0.006,
    vy:    (_rand.nextDouble() - 0.5) * 0.006,
    r:     _rand.nextDouble() * 1.6 + 0.5,
    phase: _rand.nextDouble() * math.pi * 2,
  ));

  const _ConstellationPainter({
    required this.tick,
    required this.fadeIn,
    required this.beamX,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final n in _nodes) {
      n.cx = (n.x + tick * n.vx * 8) % 1.0;
      n.cy = (n.y + tick * n.vy * 8) % 1.0;
    }

    final beamScreenX = beamX * size.width;
    const beamInfluence = 90.0;

    final linePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5;
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final a = _nodes[i], b = _nodes[j];
        final ax = a.cx * size.width, ay = a.cy * size.height;
        final bx = b.cx * size.width, by = b.cy * size.height;
        final dx = ax - bx, dy = ay - by;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > 85) continue;

        final base = (1 - dist / 85) * 0.18 * fadeIn;
        final aBoost = math.max(0.0, 1 - (ax - beamScreenX).abs() / beamInfluence);
        final bBoost = math.max(0.0, 1 - (bx - beamScreenX).abs() / beamInfluence);
        final beamBoost = math.max(aBoost, bBoost);
        final activated = (a.activated && b.activated) ? 0.1 : 0.0;
        final alpha = (base + beamBoost * 0.55 + activated).clamp(0.0, 0.85);

        linePaint.color = Color.lerp(_indigo, _indigo200, beamBoost)!
            .withValues(alpha: alpha);
        canvas.drawLine(Offset(ax, ay), Offset(bx, by), linePaint);
      }
    }

    for (final n in _nodes) {
      final nx = n.cx * size.width, ny = n.cy * size.height;
      final pulse = math.sin(tick * math.pi * 6 + n.phase) * 0.5 + 0.5;
      final beamDist = (nx - beamScreenX).abs();
      final beamBoost = math.max(0.0, 1 - beamDist / beamInfluence);

      if (beamBoost > 0.1) n.activated = true;

      final activatedBoost = n.activated ? 0.35 : 0.0;
      final baseAlpha = ((0.12 + pulse * 0.22 + beamBoost * 0.72 + activatedBoost)
          .clamp(0.0, 1.0)) * fadeIn;

      if (beamBoost > 0.05) {
        canvas.drawCircle(
          Offset(nx, ny),
          n.r * 4.5,
          Paint()
            ..color = _indigo200.withValues(alpha: beamBoost * 0.5 * fadeIn)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      canvas.drawCircle(
        Offset(nx, ny),
        n.r + beamBoost * 1.8,
        Paint()
          ..color = Color.lerp(_indigo200, Colors.white, beamBoost)!
              .withValues(alpha: baseAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) =>
      old.tick != tick || old.beamX != beamX || old.fadeIn != fadeIn;
}

class _ConstellationNode {
  final double x, y, vx, vy, r, phase;
  double cx = 0, cy = 0;
  bool activated = false;

  _ConstellationNode({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.r, required this.phase,
  }) { cx = x; cy = y; }
}

// ─── Beam Painter ─────────────────────────────────────────────────────────────
class _BeamPainter extends CustomPainter {
  final double beamX, screenWidth, screenHeight;
  const _BeamPainter({
    required this.beamX,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = beamX * screenWidth;
    final bw = screenWidth * 0.16;

    canvas.drawRect(
      Rect.fromLTWH(cx - bw * 2.5, 0, bw * 5, screenHeight),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            _indigo.withValues(alpha: 0.08),
            _indigo200.withValues(alpha: 0.22),
            _indigo.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(cx - bw * 2.5, 0, bw * 5, screenHeight)),
    );

    canvas.drawRect(
      Rect.fromLTWH(cx - bw * 0.5, 0, bw, screenHeight),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            _indigo.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0.9),
            _indigo.withValues(alpha: 0.45),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        ).createShader(Rect.fromLTWH(cx - bw * 0.5, 0, bw, screenHeight)),
    );

    canvas.drawRect(
      Rect.fromLTWH(cx - bw * 4, 0, bw * 3.5, screenHeight),
      Paint()
        ..shader = LinearGradient(
          colors: [
            _indigo200.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(cx - bw * 4, 0, bw * 3.5, screenHeight)),
    );

    final sparkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (final yFrac in [0.2, 0.42, 0.65, 0.84]) {
      canvas.drawCircle(Offset(cx, screenHeight * yFrac), 3, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BeamPainter old) => old.beamX != beamX;
}

// ─── Ripple Painter ───────────────────────────────────────────────────────────
class _RipplePainter extends CustomPainter {
  final double cx, cy, radius, opacity;
  const _RipplePainter({
    required this.cx, required this.cy,
    required this.radius, required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    canvas.drawCircle(Offset(cx, cy), radius,
      Paint()
        ..color = _indigo.withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    if (radius > 20) {
      canvas.drawCircle(Offset(cx, cy), radius * 0.6,
        Paint()
          ..color = _indigo200.withValues(alpha: opacity * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
    canvas.drawCircle(Offset(cx, cy), math.max(0, radius * 0.12),
      Paint()
        ..color = Colors.white.withValues(alpha: (opacity * 0.35).clamp(0, 1))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) =>
      old.radius != radius || old.opacity != opacity;
}

// ─── NexChat Icon ─────────────────────────────────────────────────────────────
class _NexChatIcon extends StatelessWidget {
  final double size;
  final double glowIntensity;
  const _NexChatIcon({required this.size, required this.glowIntensity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_indigo, _violet],
        ),
        boxShadow: [
          BoxShadow(
            color: _indigo.withValues(alpha: 0.55 * glowIntensity),
            blurRadius: 28 + 20 * glowIntensity,
            spreadRadius: 2 + 6 * glowIntensity,
          ),
          BoxShadow(
            color: _violet.withValues(alpha: 0.4 * glowIntensity),
            blurRadius: 55 + 30 * glowIntensity,
            spreadRadius: 6 + 8 * glowIntensity,
          ),
        ],
      ),
      child: CustomPaint(painter: _NMarkPainter()),
    );
  }
}

class _NMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.35, h * 0.28), width: w * 0.55, height: h * 0.3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final p = Paint()..color = Colors.white;
    final lx = w * 0.195, rx = w * 0.735, bw = w * 0.115;
    final top = h * 0.165, bot = h * 0.835;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(lx, top, bw, bot - top), Radius.circular(bw / 2)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rx, top, bw, bot - top), Radius.circular(bw / 2)), p);
    canvas.drawPath(Path()
      ..moveTo(lx + bw * 0.15, top + 4)..lineTo(lx + bw * 1.1, top + 4)
      ..lineTo(rx + bw * 0.85, bot - 4)..lineTo(rx - bw * 0.1, bot - 4)..close(), p);

    for (final (nx, ny, c) in [
      (lx + bw / 2, top + bw / 2, _indigo),
      (rx + bw / 2, top + bw / 2, _violet),
      (lx + bw / 2, bot - bw / 2, _violet),
      (rx + bw / 2, bot - bw / 2, _indigo),
    ]) {
      canvas.drawCircle(Offset(nx, ny), bw * 0.62, Paint()..color = c);
      canvas.drawCircle(Offset(nx, ny), bw * 0.62, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = bw * 0.22);
      canvas.drawCircle(Offset(nx, ny), bw * 0.24, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Scan-line Painter ────────────────────────────────────────────────────────
class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.016)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Loader Bar ───────────────────────────────────────────────────────────────
class _LoaderBar extends StatelessWidget {
  final AnimationController progress;
  const _LoaderBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: AnimatedBuilder(
        animation: progress,
        builder: (_, _) {
          final t = progress.value;
          return Container(
            height: 1.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: _indigo.withValues(alpha: 0.2),
            ),
            child: FractionallySizedBox(
              widthFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: LinearGradient(
                    stops: [
                      math.max(0.0, t - 0.25),
                      t,
                      math.min(1.0, t + 0.25),
                    ],
                    colors: [
                      _indigo.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.75),
                      _indigo.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}