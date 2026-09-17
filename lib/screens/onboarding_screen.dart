import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../main.dart';

// --- 1. THE PARTICLE BACKGROUND (kept) ---
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

// --- 2. PAGE MODEL ---
class _OnboardingPage {
  final String title;
  final String desc;
  final String icon;
  final Color accent;
  final bool isWelcome;
  final List<String>? bullets;

  const _OnboardingPage({
    required this.title,
    required this.desc,
    required this.icon,
    required this.accent,
    this.isWelcome = false,
    this.bullets,
  });
}

// --- 3. THE ONBOARDING SCREEN ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _scrollOffset = 0.0;
  int _currentPage = 0;

  final List<Offset> _pollenPositions = List.generate(
    40,
    (index) => Offset(
      math.Random().nextDouble() * 500,
      math.Random().nextDouble() * 800,
    ),
  );

  static const Color _brandGreen = Color(0xFF8DAA91);
  static const Color _brandSand = Color(0xFFD4A373);

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: "Welcome to Synapse",
      desc:
          "Your AI study companion. Upload your notes once, and every lab — planning, recall, testing — works from your material.",
      icon: "assets/logo_circle.png",
      accent: _brandGreen,
      isWelcome: true,
    ),
    _OnboardingPage(
      title: "Study Planner",
      desc:
          "Turn any document into a focused roadmap — a 1-hour cram sprint, a 1-day push, or a full 7-day mastery plan.",
      icon: "📅",
      accent: _brandGreen,
    ),
    _OnboardingPage(
      title: "ELI5 Laboratory",
      desc:
          "Paste any complex topic and get it back as a simple, vivid analogy you can't forget.",
      icon: "🧪",
      accent: _brandSand,
    ),
    _OnboardingPage(
      title: "Feynman Lab",
      desc:
          "Teach a curious AI student from your notes. It asks questions until the gaps in your knowledge show up.",
      icon: "👨‍🏫",
      accent: _brandGreen,
    ),
    _OnboardingPage(
      title: "Active Recall",
      desc:
          "Auto-grown flashcards plus 10-question graded exams, generated from your own documents.",
      icon: "🗂️",
      accent: _brandSand,
    ),
    _OnboardingPage(
      title: "Scan Anything",
      desc:
          "Snap a photo of handwritten notes or upload a PDF — text is extracted and synced to every lab instantly.",
      icon: "📷",
      accent: _brandGreen,
    ),
    _OnboardingPage(
      title: "Grow Your Rank",
      desc: "Everything you do feeds your plant. Keep the streak alive.",
      icon: "🏆",
      accent: _brandSand,
      bullets: const [
        "Finish a focus session → +25% level XP, +1 streak",
        "Complete daily missions → bonus XP",
        "Quit mid-session → plant withers, streak resets",
      ],
    ),
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
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _proceedToApp() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _goNext() {
    HapticFeedback.lightImpact();
    if (_isLastPage) {
      _proceedToApp();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Stack(
          children: [
            // Pollen parallax background
            Positioned.fill(
              child: CustomPaint(
                painter: PollenPainter(
                  scrollOffset: _scrollOffset,
                  basePositions: _pollenPositions,
                ),
              ),
            ),
            Column(
              children: [
                // --- Header: back / step / skip ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _currentPage > 0
                          ? IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white54,
                                size: 20,
                              ),
                              onPressed: _goBack,
                            )
                          : const SizedBox(width: 48),
                      Text(
                        "STEP ${_currentPage + 1} OF ${_pages.length}",
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _proceedToApp,
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
                // --- Progress bar ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _pages.length,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _brandGreen,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ),
                // --- Swipeable pages ---
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (int page) =>
                        setState(() => _currentPage = page),
                    itemCount: _pages.length,
                    itemBuilder: (context, i) => _buildPage(i),
                  ),
                ),
                // --- Bottom CTA ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _goNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandGreen,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Row(
                          key: ValueKey<bool>(_isLastPage),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              // Read live so the label swaps exactly on settle
                              _isLastPage ? "GET STARTED" : "NEXT",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              _isLastPage
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Soft brand glow behind the CTA, keyed to current accent
            Positioned(
              bottom: -60,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        page.accent.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int i) {
    final page = _pages[i];
    if (page.bullets != null) return _buildRankPage(page);
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconTile(page),
          const SizedBox(height: 44),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            page.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankPage(_OnboardingPage page) {
    const ladder = [
      ["🌱", "LV 1"],
      ["🪴", "LV 10"],
      ["🌸", "LV 20"],
      ["🌳", "LV 50"],
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white54,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ladder
                  .map(
                    (step) => Column(
                      children: [
                        Text(step[0], style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text(
                          step[1],
                          style: const TextStyle(
                            color: Color(0xFFD4A373),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          ...page.bullets!.map(
            (b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF8DAA91),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconTile(_OnboardingPage page) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            page.accent.withOpacity(0.28),
            page.accent.withOpacity(0.06),
          ],
        ),
        border: Border.all(color: page.accent.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: page.accent.withOpacity(0.18),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: page.isWelcome
          ? ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                page.icon,
                width: 76,
                height: 76,
                fit: BoxFit.contain,
              ),
            )
          : Text(page.icon, style: const TextStyle(fontSize: 58)),
    );
  }
}
