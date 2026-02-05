import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for API key retrieval
import 'dart:math' as math;
import '../services/ad_widget.dart';

class Eli5LabScreen extends StatefulWidget {
  const Eli5LabScreen({super.key});

  @override
  State<Eli5LabScreen> createState() => _Eli5LabScreenState();
}

class _Eli5LabScreenState extends State<Eli5LabScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  String _simplifiedText = "";
  bool _isLoading = false;
  String? _errorType;

  late AnimationController _labController;

  @override
  void initState() {
    super.initState();
    _labController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _labController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _simplifyConcept() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    // --- UPDATED: GET API KEY FROM SHARED PREFERENCES ---
    final prefs = await SharedPreferences.getInstance();
    final userApiKey = prefs.getString('gemini_api_key') ?? "";

    if (userApiKey.isEmpty) {
      _showSnackBar(
        "API Key missing! Please set it in Settings or Onboarding.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _simplifiedText = "";
      _errorType = null;
    });

    try {
      // Use the user's provided key and the correct model identifier
      final model = GenerativeModel(
        model: 'models/gemma-3-27b-it', // Updated to a stable Gemini model name
        apiKey: userApiKey,
      );

      final prompt =
          "Explain the following like I'm 5 years old. Use a funny analogy: $input";
      final response = await model.generateContent([Content.text(prompt)]);

      setState(() {
        _simplifiedText = response.text ?? "The lab couldn't process this.";
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("ELI5 ERROR: $e");
      setState(() {
        _isLoading = false;
        // Check for specific API errors (429 is limit, 403 is invalid key)
        if (e.toString().contains('429')) {
          _errorType = "LIMIT";
        } else if (e.toString().contains('403')) {
          _errorType = "AUTH";
        } else {
          _errorType = "GENERAL";
        }
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF8DAA91)),
        ),
      ),
    );
  }

  // --- LOADER & UI COMPONENTS REMAIN THE SAME ---
  Widget _buildLabLoader() {
    return Column(
      children: [
        const SizedBox(height: 40),
        SizedBox(
          height: 100,
          width: 100,
          child: AnimatedBuilder(
            animation: _labController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _labController.value * 2 * math.pi,
                    child: Container(
                      width: 80,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF8DAA91).withOpacity(0.3),
                          width: 1.5,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(80, 30),
                        ),
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: -_labController.value * 2 * math.pi + (math.pi / 2),
                    child: Container(
                      width: 80,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF8DAA91).withOpacity(0.3),
                          width: 1.5,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(80, 30),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8DAA91),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0xFF8DAA91), blurRadius: 10),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "DECONSTRUCTING COMPLEXITY",
          style: TextStyle(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ],
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
          "ELI5 LABORATORY",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildInputSection(),
            const SizedBox(height: 30),
            if (_isLoading) _buildLabLoader(),
            if (_errorType != null && !_isLoading) _buildApologyCard(),
            if (_simplifiedText.isNotEmpty &&
                !_isLoading &&
                _errorType == null) ...[
              _buildResultDisplay(),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  "SPONSORED",
                  style: TextStyle(
                    color: Colors.white10,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SubtleAdWidget(key: UniqueKey()),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApologyCard() {
    bool isLimit = _errorType == "LIMIT";
    bool isAuth = _errorType == "AUTH";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8DAA91).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            isAuth
                ? Icons.lock_person
                : (isLimit ? Icons.hourglass_empty : Icons.wifi_off_rounded),
            color: const Color(0xFF8DAA91),
            size: 48,
          ),
          const SizedBox(height: 20),
          Text(
            isAuth
                ? "INVALID API KEY"
                : (isLimit ? "LAB OVERLOADED" : "CONNECTION HICCUP"),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isAuth
                ? "Your API key seems incorrect. Please update it in the settings."
                : (isLimit
                      ? "The molecular processor is cooling down. Please wait a minute."
                      : "The lab's sensors are offline. Check your internet."),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _simplifyConcept,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8DAA91),
              foregroundColor: Colors.black,
            ),
            child: const Text(
              "RETRY EXPERIMENT",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        TextField(
          controller: _inputController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter a complex topic...",
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _simplifyConcept,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8DAA91),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "SIMPLIFY",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF8DAA91).withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF8DAA91).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFF8DAA91), size: 18),
              SizedBox(width: 8),
              Text(
                "SIMPLIFIED BREAKDOWN",
                style: TextStyle(
                  color: Color(0xFF8DAA91),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _simplifiedText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.7,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
