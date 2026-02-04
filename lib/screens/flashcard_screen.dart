import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
// Ensure this matches your actual service filename
import '../services/gemini_flashcard_service.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with TickerProviderStateMixin {
  List<Map<String, String>> _flashcards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showAnswer = false;
  String? _errorType;

  // Animation controller for the custom loader
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateFlashcards();
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  // --- LOGIC: AI GENERATION ---
  Future<void> _generateFlashcards() async {
    setState(() {
      _isLoading = true;
      _errorType = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final pdfText = prefs.getString('saved_pdf_text') ?? "";

    if (pdfText.isEmpty) {
      setState(() {
        _flashcards = [
          {"front": "No PDF Found", "back": "Please upload a PDF first."},
        ];
        _isLoading = false;
      });
      return;
    }

    try {
      final cards = await FlashcardService.generateFlashcards(pdfText);
      setState(() {
        _flashcards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorType = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- UI: IMMERSIVE LOADING SCREEN ---
  Widget _buildImmersiveLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Rotating outer ring
              RotationTransition(
                turns: _loadingController,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF8DAA91).withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Pulsing Core
              AnimatedBuilder(
                animation: _loadingController,
                builder: (context, child) {
                  return Container(
                    width:
                        60 +
                        (10 * math.sin(_loadingController.value * 2 * math.pi)),
                    height:
                        60 +
                        (10 * math.sin(_loadingController.value * 2 * math.pi)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8DAA91).withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8DAA91).withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF8DAA91),
                      size: 30,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            "CULTIVATING KNOWLEDGE",
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withOpacity(0.05),
              color: const Color(0xFF8DAA91).withOpacity(0.5),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI: APOLOGY CARD WIDGET ---
  Widget _buildApologyCard() {
    String title = "GARDEN AT CAPACITY";
    String message =
        "The AI is currently overwhelmed. Please wait a moment for the soil to recover.";
    IconData icon = Icons.wb_sunny_outlined;
    bool showRetry = true;

    if (_errorType == "OFFLINE") {
      title = "CONNECTION LOST";
      message =
          "I can't reach the study clouds. Please check your internet connection.";
      icon = Icons.cloud_off_rounded;
    } else if (_errorType == "CONFIG_ERROR") {
      title = "SETUP REQUIRED";
      message = "The API Key is missing. Check your --dart-define settings.";
      icon = Icons.settings_suggest_outlined;
      showRetry = false;
    }

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: const Color(0xFF8DAA91)),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (showRetry) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: _generateFlashcards,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF8DAA91).withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "RETRY CULTIVATION",
                  style: TextStyle(
                    color: Color(0xFF8DAA91),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ACTIVE RECALL",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Colors.white24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildImmersiveLoader()
          : _errorType != null
          ? _buildApologyCard()
          : Column(
              children: [
                const SizedBox(height: 20),
                _buildProgressBar(),
                const SizedBox(height: 40),
                Expanded(child: _buildCardStack()),
                _buildControls(),
                const SizedBox(height: 50),
              ],
            ),
    );
  }

  Widget _buildProgressBar() {
    if (_flashcards.isEmpty) return const SizedBox.shrink();
    double progress = (_currentIndex + 1) / _flashcards.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.white10,
        color: const Color(0xFF8DAA91),
        minHeight: 6,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildCardStack() {
    if (_flashcards.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => setState(() => _showAnswer = !_showAnswer),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInBack,
          transitionBuilder: (child, anim) =>
              RotationYTransition(animation: anim, child: child),
          child: _showAnswer ? _buildCardFace("back") : _buildCardFace("front"),
        ),
      ),
    );
  }

  Widget _buildCardFace(String side) {
    bool isFront = side == "front";
    return Container(
      key: ValueKey(side),
      width: MediaQuery.of(context).size.width * 0.85,
      height: 460,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: isFront ? const Color(0xFF1A1A1A) : const Color(0xFF8DAA91),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isFront ? Colors.white.withOpacity(0.05) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Text(
            _flashcards[_currentIndex][side]!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: isFront ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconBtn(Icons.close_rounded, Colors.white12, _nextCard),
          _iconBtn(Icons.check_rounded, const Color(0xFF8DAA91), _nextCard),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    } else {
      Navigator.pop(context);
    }
  }
}

// --- TRANSITION HELPER ---
class RotationYTransition extends AnimatedWidget {
  const RotationYTransition({
    super.key,
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final rotationValue = lerpDouble(0, math.pi, animation.value)!;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(rotationValue),
      child: rotationValue > (math.pi / 2)
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: child,
            )
          : child,
    );
  }
}
