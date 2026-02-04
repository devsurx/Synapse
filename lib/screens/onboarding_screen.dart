import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Upload & Extract",
      "desc":
          "Turn your lecture PDFs into knowledge. Powered by Gemini 2.5-Flash, we extract core concepts instantly so you can skip the fluff.",
      "icon": "📄",
    },
    {
      "title": "ELI5 Laboratory",
      "desc":
          "Confused by jargon? Our lab uses Gemini 2.5-Flash-Lite to turn complex theories into simple, catchy analogies in seconds.",
      "icon": "🧪",
    },
    {
      "title": "Grow Your Garden",
      "desc":
          "Gamify your focus. Start a Pomodoro timer and watch your digital plant grow. Every minute of focus helps your garden bloom.",
      "icon": "🌱",
    },
    {
      "title": "AI Flashcards",
      "desc":
          "Master active recall. Generate smart flashcards via Gemini 2.5-Flash-Lite, optimized for quick memory sessions and high RPD.",
      "icon": "🃏",
    },
    {
      "title": "Dynamic Roadmaps",
      "desc":
          "Never feel lost again. Gemini 2.5-Flash builds custom study plans based on your material, whether you have an hour or a week.",
      "icon": "🗺️",
    },
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            itemCount: _pages.length,
            itemBuilder: (context, i) => _buildPage(i),
          ),

          // Skip Button
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

          // Bottom Navigation
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
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Icon(
                    _currentPage == _pages.length - 1
                        ? Icons.check
                        : Icons.arrow_forward_ios,
                    color:
                        Colors.black, // Dark icon on light green looks modern
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
              // REMOVE 'const' from here because .withOpacity is a method call
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
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        // Corrected the color logic - remove 'const' from the conditional branch
        color: _currentPage == index ? const Color(0xFF8DAA91) : Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
