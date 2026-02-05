import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../main.dart';

// --- 1. THE PARTICLE BACKGROUND ---
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
      double parallaxEffect = (i % 5 + 1) * 0.2;
      double dx =
          (basePositions[i].dx - (scrollOffset * parallaxEffect)) % size.width;
      double dy = basePositions[i].dy;
      if (dx < 0) dx = size.width + dx;
      canvas.drawCircle(Offset(dx, dy), i % 3 + 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(PollenPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

// --- 2. THE ONBOARDING SCREEN ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _apiKeyController = TextEditingController();
  double _scrollOffset = 0.0;
  int _currentPage = 0;

  final List<Offset> _pollenPositions = List.generate(
    40,
    (index) => Offset(
      math.Random().nextDouble() * 500,
      math.Random().nextDouble() * 800,
    ),
  );

  final List<Map<String, String>> _pages = [
    {
      "title": "Study Planner",
      "desc": "Build custom roadmaps based on your notes.",
      "icon": "📅",
    },
    {
      "title": "ELI5 Laboratory",
      "desc": "Turn complex jargon into simple analogies.",
      "icon": "🧪",
    },
    {
      "title": "Smart Flashcards",
      "desc": "Master subjects through spaced repetition.",
      "icon": "🗂️",
    },
    {
      "title": "AI Tutor Chat",
      "desc": "Chat with an AI briefed on your documents.",
      "icon": "🤖",
    },
    {
      "title": "Image to Text",
      "desc": "Snap a photo of notes for AI analysis.",
      "icon": "📷",
    },
    {
      "title": "AI Activation",
      "desc": "To enable these features, you'll need a free Gemini API key.",
      "icon": "🔑",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() => _scrollOffset = _pageController.offset);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://aistudio.google.com/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // --- NEW: THE VALIDATION DIALOG ---
  void _showNoKeyWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Wait! No API Key?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Without a Gemini API key, the Planner, ELI5, and AI Chat features will not work. You can add it later in Settings, but your experience will be limited for now.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "I'LL GET ONE",
              style: TextStyle(color: Color(0xFF8DAA91)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _proceedToApp(); // Continue anyway
            },
            child: const Text(
              "CONTINUE ANYWAY",
              style: TextStyle(color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToApp() async {
    final prefs = await SharedPreferences.getInstance();
    if (_apiKeyController.text.isNotEmpty) {
      await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
    }
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
            itemBuilder: (context, i) {
              if (i == _pages.length - 1) return _buildApiPage(i);
              return _buildStandardPage(i);
            },
          ),

          // Back / Skip Navigation
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _currentPage > 0
                    ? IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white24,
                          size: 20,
                        ),
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      )
                    : const SizedBox.shrink(),
                TextButton(
                  onPressed:
                      _showNoKeyWarning, // Skip also triggers the warning now
                  child: const Text(
                    "SKIP",
                    style: TextStyle(
                      color: Colors.white24,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar
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
                      if (_apiKeyController.text.isEmpty) {
                        _showNoKeyWarning();
                      } else {
                        _proceedToApp();
                      }
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

  // UI Helpers (Standard Page, API Page, Dots, etc.)
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

  Widget _buildStandardPage(int i) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconCircle(_pages[i]["icon"]!),
          const SizedBox(height: 50),
          Text(
            _pages[i]["title"]!,
            textAlign: TextAlign.center,
            style: _titleStyle,
          ),
          const SizedBox(height: 20),
          Text(
            _pages[i]["desc"]!,
            textAlign: TextAlign.center,
            style: _descStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildApiPage(int i) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(30, 120, 30, 150),
      child: Column(
        children: [
          _buildIconCircle(_pages[i]["icon"]!),
          const SizedBox(height: 30),
          Text(_pages[i]["title"]!, style: _titleStyle.copyWith(fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            _pages[i]["desc"]!,
            textAlign: TextAlign.center,
            style: _descStyle,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _instructionStep(
                  "1",
                  "Go to aistudio.google.com",
                  isLink: true,
                  onTap: _launchURL,
                ),
                _instructionStep("2", "Click 'Get API Key' in sidebar"),
                _instructionStep("3", "Paste the key below"),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Paste AIza... key here",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFF8DAA91)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF8DAA91)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionStep(
    String num,
    String text, {
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFF8DAA91),
              child: Text(
                num,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isLink ? const Color(0xFF8DAA91) : Colors.white70,
                  fontSize: 14,
                  decoration: isLink
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
            if (isLink)
              const Icon(Icons.open_in_new, size: 14, color: Color(0xFF8DAA91)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconCircle(String icon) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8DAA91).withOpacity(0.1),
      ),
      alignment: Alignment.center,
      child: Text(icon, style: const TextStyle(fontSize: 50)),
    );
  }

  TextStyle get _titleStyle => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: -1,
  );
  TextStyle get _descStyle =>
      const TextStyle(fontSize: 15, color: Colors.white54, height: 1.5);
}
