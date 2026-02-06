import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'home_page.dart'; // To use glassBox and ImmersiveWrapper

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  bool _isLoading = true;
  List<dynamic> _questions = [];
  final Map<int, String> _userAnswers = {};
  int _currentStep = 0;
  bool _isGraded = false;
  String _feedback = "";

  @override
  void initState() {
    super.initState();
    _generateTest();
  }

  Future<void> _generateTest() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? "";
    final sourceText = prefs.getString('global_synced_pdf') ?? "";

    if (apiKey.isEmpty || sourceText.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );

    // Strict prompt for JSON output
    final prompt =
        """
    Analyze this text: $sourceText
    Generate 10 multiple-choice questions for a test. 
    Return ONLY a valid JSON array of objects with these keys: 
    "question", "options" (array of 4 strings), "answer" (the correct string).
    """;

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      setState(() {
        _questions = jsonDecode(cleanJson);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Generation Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _submitTest() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i]['answer']) {
        score++;
      }
    }
    setState(() {
      _isGraded = true;
      _feedback =
          "NEURAL EVALUATION: $score/10\n\n${score >= 7 ? 'STATUS: OPTIMIZED' : 'STATUS: FURTHER SYNC REQUIRED'}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return ImmersiveWrapper(
      title: "ASSESSMENT LAB",
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF918DAA)),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isGraded ? _buildResultView() : _buildTestView(),
            ),
    );
  }

  Widget _buildTestView() {
    if (_questions.isEmpty)
      return const Center(
        child: Text(
          "ERROR INITIALIZING CORE",
          style: TextStyle(color: Colors.white),
        ),
      );

    final q = _questions[_currentStep];

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentStep + 1) / 10,
          backgroundColor: Colors.white10,
          color: const Color(0xFF918DAA),
        ),
        const SizedBox(height: 30),
        Text(
          "QUESTION ${_currentStep + 1} OF 10",
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          q['question'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        ...List.generate(4, (index) {
          String option = q['options'][index];
          bool isSelected = _userAnswers[_currentStep] == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: glassBox(
              onTap: () => setState(() => _userAnswers[_currentStep] = option),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF918DAA)
                        : Colors.white24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text(
                  "PREV",
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF918DAA),
              ),
              onPressed: () {
                if (_currentStep < 9) {
                  setState(() => _currentStep++);
                } else {
                  _submitTest();
                }
              },
              child: Text(
                _currentStep < 9 ? "NEXT" : "FINALIZE",
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Color(0xFF918DAA),
          ),
          const SizedBox(height: 20),
          Text(
            _feedback,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          glassBox(
            onTap: () => Navigator.pop(context),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            child: const Text(
              "RETURN TO COMMAND",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
