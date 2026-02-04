import 'dart:async'; // Added for the text timer
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PlanScreen extends StatefulWidget {
  final String? studyContext;
  const PlanScreen({super.key, this.studyContext});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> with TickerProviderStateMixin {
  String _selectedTimeframe = "1 Week";
  String _roadmapText = "";
  bool _isLoading = false;
  String? _errorType;

  // Immersive Loader Logic
  late Timer _loaderTimer;
  int _loaderTextIndex = 0;
  final List<String> _loaderMessages = [
    "Analyzing core concepts...",
    "Synthesizing source material...",
    "Optimizing memory anchors...",
    "Structuring your roadmap...",
    "Finalizing neural paths...",
  ];

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();
    _loadPersistedPlan();
  }

  @override
  void dispose() {
    if (_isLoading) _loaderTimer.cancel();
    super.dispose();
  }

  // --- PERSISTENCE LOGIC ---

  Future<void> _loadPersistedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTimeframe = prefs.getString('saved_timeframe') ?? "1 Week";
      _roadmapText = prefs.getString('saved_roadmap') ?? "";
    });

    if (_roadmapText.isEmpty &&
        widget.studyContext != null &&
        widget.studyContext!.isNotEmpty) {
      _generateRoadmap();
    }
  }

  Future<void> _savePlanToDisk(String text, String timeframe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_roadmap', text);
    await prefs.setString('saved_timeframe', timeframe);
  }

  // --- AI LOGIC ---

  Future<void> _generateRoadmap() async {
    if (widget.studyContext == null || widget.studyContext!.trim().isEmpty)
      return;

    setState(() {
      _isLoading = true;
      _errorType = null;
      _loaderTextIndex = 0;
    });

    // Cycle through loading messages
    _loaderTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _loaderTextIndex = (_loaderTextIndex + 1) % _loaderMessages.length;
      });
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview', // Switched to stable name
        apiKey: _apiKey,
      );

      String timeframeInstruction = _selectedTimeframe == "1 Hour"
          ? "a 60-minute intensive CRAM SESSION. Break it into 10-minute sprints."
          : _selectedTimeframe == "1 Day"
          ? "a focused 24-HOUR schedule with morning, afternoon, and evening blocks."
          : "a high-level 7-DAY mastery roadmap.";

      final prompt =
          """
      You are a world-class study architect. 
      SOURCE MATERIAL: ${widget.studyContext}
      TASK: Create $timeframeInstruction
      STRICT RULE: Only use information from the source material. 
      FORMATTING: Markdown with bold headers (##) and emojis.
      """;

      final response = await model.generateContent([Content.text(prompt)]);
      final generatedText = response.text ?? "Failed to generate roadmap.";

      setState(() {
        _roadmapText = generatedText;
        _isLoading = false;
      });
      _loaderTimer.cancel();
      _savePlanToDisk(generatedText, _selectedTimeframe);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorType = e.toString().contains('429') ? "LIMIT" : "GENERAL";
      });
      _loaderTimer.cancel();
    }
  }

  // --- NEW IMMERSIVE LOADER ---

  Widget _buildImmersiveLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing Icon
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.2),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOutSine,
            builder: (context, double scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8DAA91).withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8DAA91).withOpacity(0.2 * scale),
                        blurRadius: 20 * scale,
                        spreadRadius: 5 * scale,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: Color(0xFF8DAA91),
                    size: 60,
                  ),
                ),
              );
            },
            onEnd:
                () {}, // Handled by repeating tween in custom animation if needed, but builder works for subtle pulse
          ),
          const SizedBox(height: 50),
          // Progress Indicator
          const SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white10,
              color: Color(0xFF8DAA91),
              minHeight: 2,
            ),
          ),
          const SizedBox(height: 24),
          // Fading Messages
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _loaderMessages[_loaderTextIndex],
              key: ValueKey<int>(_loaderTextIndex),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                letterSpacing: 1.2,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REMAINING UI (Same as previous with minor style tweaks) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "STUDY PLANNER",
          style: TextStyle(
            letterSpacing: 3,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white24,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTimeframeSelector(),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? _buildImmersiveLoader()
                : (_errorType != null ? _buildApologyCard() : _buildContent()),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_roadmapText.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, color: Colors.white10, size: 64),
            const SizedBox(height: 16),
            Text(
              widget.studyContext == null
                  ? "Upload a PDF first"
                  : "Tap a timeframe to generate plan",
              style: const TextStyle(color: Colors.white24),
            ),
          ],
        ),
      );
    }

    return Markdown(
      data: _roadmapText,
      padding: const EdgeInsets.all(24),
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
        h2: const TextStyle(
          color: Color(0xFF8DAA91),
          fontWeight: FontWeight.bold,
          fontSize: 22,
          height: 2,
        ),
        listBullet: const TextStyle(color: Color(0xFF8DAA91), fontSize: 16),
        strong: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        blockSpacing: 20,
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _selectorTab("1 Hour"),
            _selectorTab("1 Day"),
            _selectorTab("1 Week"),
          ],
        ),
      ),
    );
  }

  Widget _selectorTab(String label) {
    bool isSelected = _selectedTimeframe == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTimeframe = label);
          _generateRoadmap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8DAA91) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApologyCard() {
    bool isLimit = _errorType == "LIMIT";
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF8DAA91).withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLimit ? Icons.bolt : Icons.wifi_off,
              color: const Color(0xFF8DAA91),
              size: 48,
            ),
            const SizedBox(height: 20),
            Text(
              isLimit ? "SPEED LIMIT HIT" : "OFFLINE",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generateRoadmap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8DAA91),
              ),
              child: const Text("RETRY", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
