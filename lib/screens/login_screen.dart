import 'dart:math';

import 'package:flutter/material.dart';

class FuturisticLoginScreen extends StatefulWidget {
  const FuturisticLoginScreen({super.key});

  @override
  State<FuturisticLoginScreen> createState() => _FuturisticLoginScreenState();
}

class _FuturisticLoginScreenState extends State<FuturisticLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int particleCount = 20;
  final List<Offset> _particlePositions = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();

    // Initialize random particle positions
    for (int i = 0; i < particleCount; i++) {
      _particlePositions.add(Offset(_rand.nextDouble(), _rand.nextDouble()));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  InputDecoration futuristicInputDecoration(String label, Color color) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: color, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentGradient = LinearGradient(
      colors: const [Color(0xFF00F5FF), Color(0xFF7B61FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              // Floating particles behind the card
              Positioned.fill(
                child: CustomPaint(
                  painter: ParticlePainter(
                    particlePositions: _particlePositions,
                    animationValue: _controller.value,
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Welcome to NexChat",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A24),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email Field with icon
                      TextField(
                        decoration:
                            futuristicInputDecoration(
                              "Email",
                              const Color(0xFF00F5FF),
                            ).copyWith(
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field with icons
                      TextField(
                        obscureText: true,
                        decoration:
                            futuristicInputDecoration(
                              "Password",
                              const Color(0xFF7B61FF),
                            ).copyWith(
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.grey,
                              ),
                              suffixIcon: const Icon(
                                Icons.visibility_off_outlined,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Animated gradient login button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: accentGradient,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00F5FF,
                              ).withOpacity(0.4 * sin(_controller.value * pi)),
                              blurRadius: 20 * sin(_controller.value * pi),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () {
                              Navigator.pushNamed(context, '/chats');
                            },
                            child: const Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Create Account button
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text(
                          "Create Account",
                          style: TextStyle(color: Color(0xFF7B61FF)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Particle Painter
class ParticlePainter extends CustomPainter {
  final List<Offset> particlePositions;
  final double animationValue;
  ParticlePainter({
    required this.particlePositions,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blueAccent.withOpacity(0.08);

    for (var pos in particlePositions) {
      final x = (pos.dx + 0.02 * sin(animationValue * 2 * pi)) % 1;
      final y = (pos.dy + 0.015 * cos(animationValue * 2 * pi)) % 1;
      final offset = Offset(x * size.width, y * size.height);
      canvas.drawCircle(offset, 8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
