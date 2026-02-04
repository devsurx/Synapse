import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlanScreen extends StatefulWidget {
  final String? studyContext;
  const PlanScreen({super.key, this.studyContext});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  String _selectedTimeframe = "1 Week";
  String _roadmapText = "";
  bool _isLoading = false;
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: 'AIzaSyCAnahv3xdlsl5Gc4lrxYYoCyR74tke2NI',
    );
    // Auto-generate if context exists
    if (widget.studyContext != null && widget.studyContext!.isNotEmpty) {
      _generateRoadmap();
    }
  }

  Widget _buildImmersiveLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Pulsing Brain Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8DAA91).withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8DAA91).withOpacity(0.2 * value),
                        blurRadius: 20,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    size: 60,
                    color: Color(0xFF8DAA91),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),

          // 2. Cycling Status Text
          StreamBuilder<int>(
            stream: Stream.periodic(const Duration(seconds: 2), (i) => i % 4),
            builder: (context, snapshot) {
              const messages = [
                "Scanning your notes...",
                "Analyzing key concepts...",
                "Structuring your roadmap...",
                "Optimizing study sprints...",
              ];
              return Text(
                messages[snapshot.data ?? 0],
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1.2,
                  fontStyle: FontStyle.italic,
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 3. Sleek linear progress bar
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withOpacity(0.05),
              color: const Color(0xFF8DAA91),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }

  // --- AI LOGIC ---

  Future<void> _generateRoadmap() async {
    // Safety check: Don't call AI if context is missing
    if (widget.studyContext == null || widget.studyContext!.trim().isEmpty) {
      setState(() => _roadmapText = "");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String timeframeInstruction = "";
      if (_selectedTimeframe == "1 Hour") {
        timeframeInstruction =
            "a 60-minute intensive CRAM SESSION. Break it into 10-minute sprints.";
      } else if (_selectedTimeframe == "1 Day") {
        timeframeInstruction =
            "a focused 24-HOUR schedule with morning, afternoon, and evening blocks.";
      } else {
        timeframeInstruction = "a high-level 7-DAY mastery roadmap.";
      }

      final prompt =
          """
      You are a world-class study architect. 
      SOURCE MATERIAL: ${widget.studyContext}
      
      TASK: Create $timeframeInstruction
      STRICT RULE: Only use information from the source material. 
      FORMAT: Use Markdown with bold headers and bullet points. Add relevant emojis.
      """;

      final response = await _model.generateContent([Content.text(prompt)]);

      setState(() {
        _roadmapText = response.text ?? "Failed to generate roadmap.";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _roadmapText = "Error connecting to AI. Please check your connection.";
        _isLoading = false;
      });
    }
  }

  // --- UI COMPONENTS ---

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
                ? _buildImmersiveLoader() // <--- The new immersive loader
                : _buildContent(),
          ),
        ],
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
              color: isSelected ? Colors.white : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Empty State
    if (widget.studyContext == null || widget.studyContext!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.05),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Study Material Found",
              style: TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Upload a PDF on Home to generate a plan.",
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Roadmap Content
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          _roadmapText,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
