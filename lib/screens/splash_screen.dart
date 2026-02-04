import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui'; // Required for ImageFilter
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // 1. Setup Animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true); // Loop for the "breathing" effect

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Subtle breathing pulse
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // 2. Start Visuals
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _opacity = 1.0);
    });

    // 3. Navigation Logic
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    Widget nextScreen = isFirstTime
        ? const OnboardingScreen()
        : const MainNavigationHolder();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1710), // Ultra-dark forest green
      body: Stack(
        children: [
          // Background "Aura" Glows
          Positioned(
            top: -100,
            right: -50,
            child: _buildAura(250, const Color(0xFF8DAA91).withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildAura(200, const Color(0xFFD4A373).withOpacity(0.1)),
          ),

          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1500),
              opacity: _opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Logo Container
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8DAA91).withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.01),
                          ],
                        ),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Image.asset(
                        'assets/logo_circle.png',
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Brand Name
                  const Text(
                    "SYNAPSE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight:
                          FontWeight.w200, // Light weight for "Zen" feel
                      letterSpacing: 12,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(height: 1, width: 20, color: Colors.white10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "GROW YOUR MIND",
                          style: TextStyle(
                            color: const Color(0xFF8DAA91).withOpacity(0.6),
                            fontSize: 10,
                            letterSpacing: 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(height: 1, width: 20, color: Colors.white10),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAura(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }
}
