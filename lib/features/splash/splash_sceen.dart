import 'dart:async';

import 'package:flutter/material.dart';

// Removed: import 'home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

// Dummy HomeScreen so the splash screen has somewhere to navigate to
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NexChat Home')),
      body: const Center(
        child: Text('Welcome to NexChat!', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}

// --- YOUR ORIGINAL CODE BELOW ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    /// Main animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    /// Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 25, end: 45).animate(_glowController);

    _mainController.forward();

    Timer(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F14)
          : const Color(0xFFF5F7FA),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// HERO LOGO
                Hero(
                  tag: "nexchat_logo",
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00F5FF,
                                    ).withOpacity(0.6),
                                    blurRadius: _glowAnimation.value,
                                    spreadRadius: 3,
                                  ),
                                ]
                              : [
                                  const BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 15,
                                  ),
                                ],
                        ),
                        child: Icon(
                          Icons.chat_bubble_rounded,
                          size: 70,
                          color: isDark
                              ? const Color(0xFF00F5FF)
                              : const Color(0xFF2962FF),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                /// STYLED TEXT
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Nex",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A24),
                        ),
                      ),
                      TextSpan(
                        text: "Chat",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF00F5FF)
                              : const Color(0xFF2962FF),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Next Gen Conversations",
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 1,
                    color: isDark ? Colors.white70 : Colors.black54,
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
