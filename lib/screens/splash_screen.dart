import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Ensure this points to your MainNavigationHolder
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // 1. Setup Animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // 2. Start Visuals
    _controller.forward();

    // Slight delay before fading in the text/logo
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    // 3. Navigation Logic
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (!mounted) return;

    // Determine target screen
    Widget nextScreen = isFirstTime
        ? const OnboardingScreen()
        : const MainNavigationHolder();

    // Use a PageRouteBuilder for a smooth Fade Transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(
          milliseconds: 800,
        ), // Adjust speed here
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
      backgroundColor: const Color(0xFF1A1A2E), // Custom deep indigo/blue
      body: SafeArea(
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1000),
            opacity: _opacity,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 120, // Adjust size as needed
                      width: 120,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "STUDY COACH",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "AI-POWERED LEARNING",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
