import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_flashcard_service.dart';
import '../services/openrouter_service.dart';
import '../widgets/synapse_widgets.dart';
import 'home_page.dart';

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

  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _generateFlashcards();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _generateFlashcards() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorType = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Pull the text we just saved in the Portal
      final pdfText = prefs.getString('global_synced_pdf') ?? "";

      debugPrint("Flashcard Screen -> Text found: ${pdfText.length} chars");

      if (pdfText.trim().isEmpty) {
        setState(() {
          _errorType =
              "NO_TEXT"; // This triggers the Garden Issue if text is missing
          _isLoading = false;
        });
        return;
      }

      // Pass to OpenRouter
      final apiKey = await OpenRouterService.getApiKey();
      final cards = await FlashcardService.generateFlashcards(pdfText, apiKey);

      if (mounted) {
        setState(() {
          _flashcards = cards;
          _isLoading = false;
          if (_flashcards.isEmpty) _errorType = "EMPTY_RESULT";
        });
      }
    } catch (e) {
      debugPrint("FLASHCARD ERROR: $e");
      String errorMessage = "GENERAL";

      if (e.toString().contains('503')) {
        errorMessage =
            "Server At Limit! Please Try Later!"; // Add a specific case for this
      }

      if (mounted) {
        setState(() {
          _errorType = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const PillHeader("ACTIVE RECALL"),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: Colors.white54,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildImmersiveLoader();
    if (_errorType != null) return _buildApologyCard();

    return Column(
      children: [
        const SizedBox(height: 20),
        _buildProgressBar(),
        const SizedBox(height: 40),
        Expanded(child: _buildCardStack()),
        _buildControls(),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (_flashcards.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: LinearProgressIndicator(
        value: (_currentIndex + 1) / _flashcards.length,
        backgroundColor: Colors.white10,
        color: const Color(0xFF8DAA91),
        minHeight: 4,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // FIXED: Hardware-safe Transition to avoid BLASTBufferQueue errors
  Widget _buildCardStack() {
    return GestureDetector(
      onTap: () => setState(() => _showAnswer = !_showAnswer),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildCardFace(
            _showAnswer ? "back" : "front",
            key: ValueKey(_currentIndex.toString() + _showAnswer.toString()),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace(String side, {required Key key}) {
    bool isFront = side == "front";
    String text = _flashcards[_currentIndex][side] ?? "";

    return Container(
      key: key,
      width: MediaQuery.of(context).size.width * 0.85,
      height: 460,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: isFront ? const Color(0xFF1A1A1A) : const Color(0xFF8DAA91),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isFront ? Colors.white.withOpacity(0.05) : Colors.transparent,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: isFront ? Colors.white : Colors.black87,
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
          _circleBtn(Icons.close_rounded, Colors.white12, _nextCard),
          _circleBtn(Icons.check_rounded, const Color(0xFF8DAA91), _nextCard),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 28),
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

  Widget _buildImmersiveLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _loadingController,
            child: const Icon(
              Icons.auto_awesome,
              size: 40,
              color: Color(0xFF8DAA91),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "GROWING YOUR DECK...",
            style: TextStyle(
              color: Colors.white24,
              letterSpacing: 4,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApologyCard() {
    final bool noText = _errorType == "NO_TEXT";
    return ErrorCard(
      icon: noText ? Icons.description_outlined : Icons.error_outline_rounded,
      title: noText ? "NO PDF TEXT FOUND" : "GARDEN ERROR",
      message: noText
          ? "Sync a document from the home screen first, then grow your deck."
          : "Something disrupted the deck synthesis. ${_errorType ?? ""}",
      actionLabel: "RETRY",
      onRetry: _generateFlashcards,
    );
  }
}
