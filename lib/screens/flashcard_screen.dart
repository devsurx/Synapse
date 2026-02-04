import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_flashcard_service.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<Map<String, String>> _flashcards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _generateFlashcards();
  }

  // --- LOGIC: AI GENERATION ---
  // Inside flashcard_screen.dart
  Future<void> _generateFlashcards() async {
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

    // Call the real AI service
    final cards = await FlashcardService.generateFlashcards(pdfText);

    setState(() {
      _flashcards = cards;
      _isLoading = false;
    });
  }

  // --- UI: FLASHCARD STACK ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Active Recall",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8DAA91)),
            )
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
    double progress = (_currentIndex + 1) / _flashcards.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: const Color(0xFF8DAA91),
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Text(
            "${_currentIndex + 1} / ${_flashcards.length}",
            style: const TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    if (_currentIndex >= _flashcards.length) {
      return const Center(
        child: Text("Session Complete! 🎉", style: TextStyle(fontSize: 20)),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _showAnswer = !_showAnswer),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return RotationYTransition(animation: animation, child: child);
          },
          child: _showAnswer ? _buildCardFace("back") : _buildCardFace("front"),
        ),
      ),
    );
  }

  Widget _buildCardFace(String side) {
    return Container(
      key: ValueKey(side),
      width: 320,
      height: 450,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: side == "front"
            ? const Color(0xFF1E1E1E)
            : const Color(0xFF8DAA91),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _flashcards[_currentIndex][side]!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: side == "front" ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _controlButton(Icons.close, Colors.redAccent, () => _nextCard()),
          _controlButton(
            Icons.check,
            const Color(0xFF8DAA91),
            () => _nextCard(),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
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
      // End of session logic
      Navigator.pop(context);
    }
  }
}

// --- HELPER: 3D ROTATION ---
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
    final rotationValue = lerpDouble(0, 3.14, animation.value)!;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(rotationValue),
      child: rotationValue > 1.57
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(3.14),
              child: child,
            )
          : child,
    );
  }
}
