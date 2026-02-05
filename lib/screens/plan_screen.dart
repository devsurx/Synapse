import 'dart:async';
import 'dart:ui';
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

  late Timer _loaderTimer;
  int _loaderTextIndex = 0;
  final List<String> _loaderMessages = [
    "Analyzing core concepts...",
    "Synthesizing source material...",
    "Optimizing memory anchors...",
    "Structuring your roadmap...",
    "Finalizing neural paths...",
  ];

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

  // --- PERSISTENCE LOGIC (UNTOUCHED) ---
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

  // --- RESET LOGIC (UNTOUCHED) ---
  Future<void> _resetPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_roadmap');
    await prefs.remove('saved_timeframe');
    setState(() {
      _roadmapText = "";
      _selectedTimeframe = "1 Week";
    });
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF121212).withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: const Text(
            "Reset Plan?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "This will clear your neural roadmap. It can be regenerated anytime.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CANCEL",
                style: TextStyle(color: Colors.white24, letterSpacing: 1.5),
              ),
            ),
            TextButton(
              onPressed: () {
                _resetPlan();
                Navigator.pop(context);
              },
              child: const Text(
                "PURGE",
                style: TextStyle(
                  color: Color(0xFF8DAA91),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- AI LOGIC (UNTOUCHED) ---
  // --- AI LOGIC WITH 503 RETRY ---
  Future<void> _generateRoadmap() async {
    if (widget.studyContext == null || widget.studyContext!.trim().isEmpty)
      return;

    final prefs = await SharedPreferences.getInstance();
    final String userApiKey = prefs.getString('gemini_api_key') ?? "";

    if (userApiKey.isEmpty) {
      setState(() => _errorType = "CONFIG_ERROR");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorType = null;
      _loaderTextIndex = 0;
    });

    _loaderTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _loaderTextIndex = (_loaderTextIndex + 1) % _loaderMessages.length;
      });
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: userApiKey,
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

      // --- ADDED 503 RETRY HANDLER ---
      GenerateContentResponse response;
      try {
        response = await model.generateContent([Content.text(prompt)]);
      } catch (e) {
        if (e.toString().contains('503')) {
          // Wait 2 seconds for server to breathe and try one last time
          await Future.delayed(const Duration(seconds: 2));
          response = await model.generateContent([Content.text(prompt)]);
        } else {
          rethrow;
        }
      }
      // -------------------------------

      final generatedText = response.text ?? "Failed to generate roadmap.";

      setState(() {
        _roadmapText = generatedText;
        _isLoading = false;
      });
      _loaderTimer.cancel();
      _savePlanToDisk(generatedText, _selectedTimeframe);
    } catch (e) {
      String errorStr = e.toString().toLowerCase();
      debugPrint("PLANNER ERROR: $e"); // Log for debugging

      setState(() {
        _isLoading = false;
        if (errorStr.contains('429') || errorStr.contains('quota')) {
          _errorType = "LIMIT";
        } else if (errorStr.contains('503')) {
          _errorType = "SERVER_BUSY"; // New 503 Case
        } else if (errorStr.contains('403') || errorStr.contains('invalid')) {
          _errorType = "AUTH_ERROR";
        } else {
          _errorType = "GENERAL";
        }
      });
      if (_loaderTimer.isActive) _loaderTimer.cancel();
    }
  }

  // --- REVAMPED UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Text(
                "NEXUS PLANNER",
                style: TextStyle(
                  letterSpacing: 4,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ),
        actions: [
          if (_roadmapText.isNotEmpty && !_isLoading)
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: const Color(0xFF8DAA91).withOpacity(0.5),
              ),
              onPressed: _confirmReset,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background Aesthetic Orbs
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlowOrb(const Color(0xFF8DAA91).withOpacity(0.15)),
          ),
          Column(
            children: [
              const SizedBox(height: 110),
              _buildTimeframeSelector(),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _isLoading
                      ? _buildImmersiveLoader()
                      : (_errorType != null
                            ? _buildApologyCard()
                            : _buildContent()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                _selectorTab("1 Hour"),
                _selectorTab("1 Day"),
                _selectorTab("1 Week"),
              ],
            ),
          ),
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
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8DAA91) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF8DAA91).withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white38,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_roadmapText.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_mosaic_outlined,
              color: Colors.white.withOpacity(0.05),
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              widget.studyContext == null
                  ? "SYSTEM WAITING FOR SOURCE PDF"
                  : "SELECT TEMPORAL RANGE TO INITIALIZE",
              style: const TextStyle(
                color: Colors.white24,
                letterSpacing: 2,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Markdown(
          data: _roadmapText,
          padding: const EdgeInsets.all(24),
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.7,
            ),
            h2: const TextStyle(
              color: Color(0xFF8DAA91),
              fontWeight: FontWeight.bold,
              fontSize: 20,
              height: 2.5,
              letterSpacing: 1,
            ),
            listBullet: const TextStyle(color: Color(0xFF8DAA91), fontSize: 16),
            strong: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            blockSpacing: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildImmersiveLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF8DAA91).withOpacity(0.3),
                  ),
                ),
              ),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.9, end: 1.1),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOutSine,
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8DAA91).withOpacity(0.05),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF8DAA91,
                            ).withOpacity(0.15 * scale),
                            blurRadius: 30 * scale,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.architecture_rounded,
                        color: Color(0xFF8DAA91),
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 50),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _loaderMessages[_loaderTextIndex].toUpperCase(),
              key: ValueKey<int>(_loaderTextIndex),
              style: const TextStyle(
                color: Color(0xFF8DAA91),
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "ARCHITECTING NEURAL PATHWAYS",
            style: TextStyle(
              color: Colors.white10,
              fontSize: 8,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApologyCard() {
    String title = "QUOTA EXHAUSTED";
    String message = "Temporal AI limit reached. Synchronization resets soon.";
    IconData icon = Icons.bolt_rounded;

    // Logic to switch UI based on the error caught in _generateRoadmap
    if (_errorType == "SERVER_BUSY") {
      title = "NEURAL LINK OVERLOAD";
      message =
          "The AI servers are currently processing high traffic. Please try again in a moment.";
      icon = Icons.cloud_off_rounded;
    } else if (_errorType == "AUTH_ERROR") {
      title = "KEY CORRUPTED";
      message = "Neural link failed. Verify API configuration in settings.";
      icon = Icons.key_off_rounded;
    } else if (_errorType == "CONFIG_ERROR") {
      title = "INITIALIZATION REQUIRED";
      message = "No API key detected. Please configure the core system.";
      icon = Icons.settings_rounded;
    } else if (_errorType == "GENERAL") {
      title = "SYNC ERROR";
      message = "An unexpected disruption occurred in the neural bridge.";
      icon = Icons.error_outline_rounded;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF8DAA91).withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF8DAA91), size: 48),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateRoadmap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8DAA91),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "RETRY SYNC",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
