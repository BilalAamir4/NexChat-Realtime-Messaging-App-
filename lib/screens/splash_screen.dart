import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const NexChatApp());
}

class NexChatApp extends StatelessWidget {
  const NexChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

// ─── Color tokens ────────────────────────────────────────────────────────────
const _indigo = Color(0xFF4F46E5);
const _violet = Color(0xFF7C3AED);
const _indigo100 = Color(0xFFE0E7FF);
const _indigo200 = Color(0xFFC7D2FE);
const _slateDark = Color(0xFF1E1B4B);
const _slateMid = Color(0xFF475569);

// ─── Splash Screen ───────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Beam sweep
  late final AnimationController _beamCtrl;
  late final Animation<double> _beamX;

  // Dark overlay fade out
  late final AnimationController _overlayCtrl;
  late final Animation<double> _overlayOpacity;

  // Icon scale + fade in
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;

  // Wordmark + tagline slide up + fade
  late final AnimationController _wordCtrl;
  late final Animation<double> _wordOpacity;
  late final Animation<Offset> _wordSlide;
  late final Animation<double> _tagOpacity;

  // Particle glow pulse
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();

    // 1. Beam sweeps across screen (0 → 900ms)
    _beamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _beamX = Tween<double>(begin: -0.15, end: 1.15).animate(
      CurvedAnimation(parent: _beamCtrl, curve: Curves.easeInOut),
    );

    // 2. Overlay fades out (400 → 1100ms)
    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _overlayOpacity = Tween<double>(begin: 0.92, end: 0.0).animate(
      CurvedAnimation(parent: _overlayCtrl, curve: Curves.easeOut),
    );

    // 3. Icon materialises (500 → 1300ms)
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // 4. Wordmark rises (1200 → 1700ms)
    _wordCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _wordOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wordCtrl, curve: Curves.easeOut),
    );
    _wordSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _wordCtrl, curve: Curves.easeOut));
    _tagOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _wordCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // 5. Continuous particle pulse
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _beamCtrl.forward();
    _overlayCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _iconCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _wordCtrl.forward();

    // Wait for wordmark animation + a moment, then navigate
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
  @override
  void dispose() {
    _beamCtrl.dispose();
    _overlayCtrl.dispose();
    _iconCtrl.dispose();
    _wordCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _slateDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background gradient ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0D2A), Color(0xFF1E1B4B), Color(0xFF2D1B69)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Particle field ──────────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
            ),
          ),

          // ── Scan-line texture overlay ───────────────────────────────────
          CustomPaint(painter: _ScanLinePainter()),

          // ── Dark vignette overlay (fades out) ───────────────────────────
          AnimatedBuilder(
            animation: _overlayOpacity,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(_overlayOpacity.value * 0.5),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(_overlayOpacity.value * 0.8),
                  ],
                ),
              ),
            ),
          ),

          // ── Beam of light ───────────────────────────────────────────────
          AnimatedBuilder(
            animation: _beamX,
            builder: (_, __) {
              if (_beamCtrl.status == AnimationStatus.completed) {
                return const SizedBox.shrink();
              }
              return CustomPaint(
                painter: _BeamPainter(
                  progress: _beamX.value,
                  screenWidth: size.width,
                  screenHeight: size.height,
                ),
              );
            },
          ),

          // ── Center content ──────────────────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Icon
              AnimatedBuilder(
                animation: _iconCtrl,
                builder: (_, __) => Transform.scale(
                  scale: _iconScale.value,
                  child: Opacity(
                    opacity: _iconOpacity.value,
                    child: const _NexChatIcon(size: 100),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Wordmark
              AnimatedBuilder(
                animation: _wordCtrl,
                builder: (_, __) => SlideTransition(
                  position: _wordSlide,
                  child: FadeTransition(
                    opacity: _wordOpacity,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_indigo200, Colors.white, _indigo100],
                          ).createShader(bounds),
                          child: const Text(
                            'NEXCHAT',
                            style: TextStyle(
                              fontSize: 32,
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
                              fontSize: 12,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w400,
                              color: _indigo200.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Bottom loader bar
              AnimatedBuilder(
                animation: _wordCtrl,
                builder: (_, __) => Opacity(
                  opacity: _wordOpacity.value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 52),
                    child: _LoaderBar(progress: _particleCtrl),
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

// ─── NexChat Icon (N-node mark) ───────────────────────────────────────────────
class _NexChatIcon extends StatelessWidget {
  final double size;
  const _NexChatIcon({required this.size});

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
            color: _indigo.withOpacity(0.6),
            blurRadius: 32,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: _violet.withOpacity(0.4),
            blurRadius: 60,
            spreadRadius: 8,
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
    final w = size.width;
    final h = size.height;

    // Subtle top-left highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.35, h * 0.28),
        width: w * 0.55,
        height: h * 0.3,
      ),
      highlightPaint,
    );

    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final lx = w * 0.195, rx = w * 0.735;
    final barW = w * 0.115;
    final top = h * 0.165, bottom = h * 0.835;

    // Left vertical bar
    final leftRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(lx, top, barW, bottom - top),
      Radius.circular(barW / 2),
    );
    canvas.drawRRect(leftRRect, barPaint);

    // Right vertical bar
    final rightRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rx, top, barW, bottom - top),
      Radius.circular(barW / 2),
    );
    canvas.drawRRect(rightRRect, barPaint);

    // Diagonal bar
    final diagPath = Path()
      ..moveTo(lx + barW * 0.15, top + 4)
      ..lineTo(lx + barW * 1.1, top + 4)
      ..lineTo(rx + barW * 0.85, bottom - 4)
      ..lineTo(rx - barW * 0.1, bottom - 4)
      ..close();
    canvas.drawPath(diagPath, barPaint);

    // Node circles
    final nodes = [
      (lx + barW / 2, top + barW / 2, _indigo),
      (rx + barW / 2, top + barW / 2, _violet),
      (lx + barW / 2, bottom - barW / 2, _violet),
      (rx + barW / 2, bottom - barW / 2, _indigo),
    ];

    for (final (nx, ny, color) in nodes) {
      // Colored ring
      canvas.drawCircle(
        Offset(nx, ny),
        barW * 0.62,
        Paint()..color = color,
      );
      // White ring
      canvas.drawCircle(
        Offset(nx, ny),
        barW * 0.62,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = barW * 0.22,
      );
      // White center dot
      canvas.drawCircle(
        Offset(nx, ny),
        barW * 0.24,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Beam Painter ─────────────────────────────────────────────────────────────
class _BeamPainter extends CustomPainter {
  final double progress;
  final double screenWidth;
  final double screenHeight;

  const _BeamPainter({
    required this.progress,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = progress * screenWidth;
    final beamW = screenWidth * 0.18;

    // Wide soft glow
    final softPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          _indigo200.withOpacity(0.12),
          Colors.white.withOpacity(0.28),
          _indigo200.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(
        Rect.fromLTWH(cx - beamW * 2, 0, beamW * 4, screenHeight),
      );
    canvas.drawRect(
      Rect.fromLTWH(cx - beamW * 2, 0, beamW * 4, screenHeight),
      softPaint,
    );

    // Tight core beam
    final corePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          _indigo.withOpacity(0.5),
          Colors.white.withOpacity(0.85),
          _indigo.withOpacity(0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(
        Rect.fromLTWH(cx - beamW / 2, 0, beamW, screenHeight),
      );
    canvas.drawRect(
      Rect.fromLTWH(cx - beamW / 2, 0, beamW, screenHeight),
      corePaint,
    );

    // Reflection sparks at beam edges
    final sparkPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, screenHeight * 0.25), 4, sparkPaint);
    canvas.drawCircle(Offset(cx, screenHeight * 0.5), 6, sparkPaint);
    canvas.drawCircle(Offset(cx, screenHeight * 0.75), 4, sparkPaint);
  }

  @override
  bool shouldRepaint(covariant _BeamPainter old) =>
      old.progress != progress;
}

// ─── Particle Painter ─────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  static final _rand = math.Random(42);
  static final List<_Particle> _particles = List.generate(
    55,
        (_) => _Particle(
      x: _rand.nextDouble(),
      y: _rand.nextDouble(),
      r: _rand.nextDouble() * 1.5 + 0.4,
      speed: _rand.nextDouble() * 0.003 + 0.001,
      phase: _rand.nextDouble() * math.pi * 2,
    ),
  );

  const _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final alpha = (math.sin(t * math.pi * 2 + p.phase) * 0.5 + 0.5) * 0.55;
      final paint = Paint()
        ..color = _indigo200.withOpacity(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(
        Offset(p.x * size.width, (p.y + t * p.speed * 10) % 1.0 * size.height),
        p.r,
        paint,
      );
    }

    // Connection lines between nearby particles
    final linePaint = Paint()
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < _particles.length; i++) {
      for (int j = i + 1; j < _particles.length; j++) {
        final a = _particles[i], b = _particles[j];
        final dx = (a.x - b.x) * size.width;
        final dy = (a.y - b.y) * size.height;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 80) {
          linePaint.color = _indigo.withOpacity((1 - dist / 80) * 0.18);
          canvas.drawLine(
            Offset(a.x * size.width, a.y * size.height),
            Offset(b.x * size.width, b.y * size.height),
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

class _Particle {
  final double x, y, r, speed, phase;
  const _Particle({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
  });
}

// ─── Scan Line Painter ────────────────────────────────────────────────────────
class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.018)
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
      width: 120,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: progress,
            builder: (_, __) {
              final shimmer = progress.value;
              return Container(
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: _indigo.withOpacity(0.25),
                ),
                child: FractionallySizedBox(
                  widthFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: LinearGradient(
                        stops: [
                          math.max(0, shimmer - 0.3),
                          shimmer,
                          math.min(1, shimmer + 0.3),
                        ],
                        colors: [
                          _indigo.withOpacity(0.2),
                          Colors.white.withOpacity(0.8),
                          _indigo.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

