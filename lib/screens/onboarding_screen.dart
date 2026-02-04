import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../main.dart';

// --- 1. THE REACTIVE PARTICLE PAINTER ---
class PollenPainter extends CustomPainter {
  final double scrollOffset;
  final List<Offset> basePositions;

  PollenPainter({required this.scrollOffset, required this.basePositions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8DAA91).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int i = 0; i < basePositions.length; i++) {
      // Calculate responsive movement:
      // The pollen moves in the opposite direction of the swipe to create "drag"
      double parallaxEffect = (i % 5 + 1) * 0.2;
      double dx =
          (basePositions[i].dx - (scrollOffset * parallaxEffect)) % size.width;
      double dy = basePositions[i].dy;

      // Ensure particles wrap around the screen smoothly
      if (dx < 0) dx = size.width + dx;

      canvas.drawCircle(Offset(dx, dy), i % 3 + 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(PollenPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

// --- 2. THE UPDATED ONBOARDING SCREEN ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _scrollOffset = 0.0;
  int _currentPage = 0;

  // Generate random static positions once
  final List<Offset> _pollenPositions = List.generate(
    40,
    (index) => Offset(
      math.Random().nextDouble() * 500,
      math.Random().nextDouble() * 800,
    ),
  );

  @override
  void initState() {
    super.initState();
    // Listen to the controller to update particle positions in real-time
    _pageController.addListener(() {
      setState(() {
        _scrollOffset = _pageController.offset;
      });
    });
  }

  final List<Map<String, String>> _pages = [
    {
      "title": "Upload & Extract",
      "desc":
          "Turn your lecture PDFs into knowledge. Powered by AI, we extract core concepts instantly so you can skip the fluff.",
      "icon": "📄",
    },
    {
      "title": "ELI5 Laboratory",
      "desc":
          "Confused by jargon? Our lab turns complex theories into simple, catchy analogies in seconds.",
      "icon": "🧪",
    },
    {
      "title": "Grow Your Garden",
      "desc":
          "Gamify your focus. Start a Pomodoro timer and watch your digital plant grow. Every minute helps your garden bloom.",
      "icon": "🌱",
    },
    {
      "title": "AI Flashcards",
      "desc":
          "Master active recall. Generate smart flashcards optimized for quick memory sessions and high retention.",
      "icon": "🃏",
    },
    {
      "title": "Dynamic Roadmaps",
      "desc":
          "Never feel lost again. Build custom study plans based on your material, whether you have an hour or a week.",
      "icon": "🗺️",
    },
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // THE POLLEN LAYER
          Positioned.fill(
            child: CustomPaint(
              painter: PollenPainter(
                scrollOffset: _scrollOffset,
                basePositions: _pollenPositions,
              ),
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            itemCount: _pages.length,
            itemBuilder: (context, i) => _buildPage(i),
          ),

          // Top Skip Button
          Positioned(
            top: 60,
            right: 20,
            child: TextButton(
              onPressed: _finishOnboarding,
              child: const Text(
                "SKIP",
                style: TextStyle(color: Colors.white24, letterSpacing: 2),
              ),
            ),
          ),

          // Bottom Nav
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => _buildDot(index),
                  ),
                ),
                FloatingActionButton(
                  backgroundColor: const Color(0xFF8DAA91),
                  elevation: 0,
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: Icon(
                    _currentPage == _pages.length - 1
                        ? Icons.check
                        : Icons.arrow_forward_ios,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int i) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8DAA91).withOpacity(0.1),
            ),
            alignment: Alignment.center,
            child: Text(
              _pages[i]["icon"]!,
              style: const TextStyle(fontSize: 60),
            ),
          ),
          const SizedBox(height: 50),
          Text(
            _pages[i]["title"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _pages[i]["desc"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF8DAA91) : Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
