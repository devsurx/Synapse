import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Adjust based on your MainNavigation location

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
          "Upload your lecture PDFs. Our AI extracts the core concepts so you don't have to hunt through pages of text.",
      "icon": "📄",
    },
    {
      "title": "AI Tutor & Voice",
      "desc":
          "Chat with your notes using text or voice. Ask questions, clarify doubts, and get instant explanations.",
      "icon": "🎙️",
    },
    {
      "title": "Dynamic Roadmaps",
      "desc":
          "Generate custom study plans for 1 hour, 1 day, or 1 week based entirely on your specific material.",
      "icon": "🗺️",
    },
    {
      "title": "Quiz Mode",
      "desc":
          "Test your knowledge with AI-generated quizzes. No more 'random biology'—just what's in your file.",
      "icon": "🧠",
    },
  ];

  // Inside onboarding_screen.dart button tap
  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false); // The "Key" to the front door

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
                    color: Colors.white,
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
          Text(_pages[i]["icon"]!, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 40),
          Text(
            _pages[i]["title"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _pages[i]["desc"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white54,
              height: 1.5,
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
        color: _currentPage == index ? const Color(0xFF8DAA91) : Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
