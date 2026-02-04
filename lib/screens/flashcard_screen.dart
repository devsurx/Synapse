import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
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

    try {
      final cards = await FlashcardService.generateFlashcards(pdfText);
      setState(() {
        _flashcards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _flashcards = [
          {"front": "Error", "back": "Failed to cultivate cards. Try again."},
        ];
        _isLoading = false;
      });
    }
  }

  // --- LOGIC: DELETE CARD ---
  void _deleteCard() {
    if (_flashcards.isEmpty) return;

    setState(() {
      _flashcards.removeAt(_currentIndex);

      // Prevent index out of bounds if we delete the last card
      if (_currentIndex >= _flashcards.length && _currentIndex > 0) {
        _currentIndex--;
      }
      _showAnswer = false;
    });

    if (_flashcards.isEmpty) {
      Navigator.pop(context); // Exit if no cards left
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Prune Card?",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          "This card will be removed from your garden session.",
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("KEEP", style: TextStyle(color: Colors.white24)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCard();
            },
            child: const Text(
              "DELETE",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI: MAIN BUILD ---
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
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && _flashcards.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white24),
              onPressed: _showDeleteConfirmation,
            ),
        ],
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
    if (_flashcards.isEmpty) return const SizedBox.shrink();
    double progress = (_currentIndex + 1) / _flashcards.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: const Color(0xFF8DAA91),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          Text(
            "${_currentIndex + 1} OF ${_flashcards.length}",
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    if (_flashcards.isEmpty) return const SizedBox.shrink();

    return Dismissible(
      key: ValueKey(_flashcards[_currentIndex]),
      direction: DismissDirection.up,
      onDismissed: (_) => _deleteCard(),
      background: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 50),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: Colors.redAccent,
          size: 40,
        ),
      ),
      child: GestureDetector(
        onTap: () => setState(() => _showAnswer = !_showAnswer),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return RotationYTransition(animation: animation, child: child);
            },
            child: _showAnswer
                ? _buildCardFace("back")
                : _buildCardFace("front"),
          ),
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _flashcards[_currentIndex][side]!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: isFront ? Colors.white : Colors.black,
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
          _controlButton(
            Icons.close_rounded,
            Colors.white24,
            () => _nextCard(),
          ),
          _controlButton(
            Icons.check_rounded,
            const Color(0xFF8DAA91),
            () => _nextCard(),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2)),
          color: color.withOpacity(0.05),
        ),
        child: Icon(icon, color: color, size: 32),
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
    final rotationValue = lerpDouble(0, math.pi, animation.value)!;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
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
