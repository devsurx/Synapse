import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class QuizScreen extends StatefulWidget {
  final String? studyContext;
  const QuizScreen({super.key, this.studyContext});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = false;
  bool _quizComplete = false;

  // --- AI LOGIC: GENERATING THE QUIZ ---

  Future<void> _generateQuiz() async {
    if (widget.studyContext == null) return;

    setState(() => _isLoading = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey:
            'AIzaSyCAnahv3xdlsl5Gc4lrxYYoCyR74tke2NI', // Use your actual key
      );

      final prompt =
          """
Generate a 5-question MCQ quiz BASED ONLY on the following text: ${widget.studyContext}
DO NOT use outside knowledge. If the text is empty, return an error message in JSON.
Format: JSON array [{question, options, answerIndex}]
""";

      final response = await model.generateContent([Content.text(prompt)]);
      final String cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      setState(() {
        _questions = jsonDecode(cleanJson);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI failed to build the quiz.")),
      );
    }
  }

  // --- UI LOGIC ---

  void _handleAnswer(int index) {
    if (_questions[_currentIndex]['answerIndex'] == index) {
      _score++;
    }

    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
      } else {
        _quizComplete = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("KNOWLEDGE CHECK"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8DAA91)),
              )
            : _questions.isEmpty
            ? _buildStartView()
            : _buildQuizView(),
      ),
    );
  }

  Widget _buildStartView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_outlined, size: 80, color: Colors.white10),
          const SizedBox(height: 20),
          const Text(
            "Ready to test your knowledge?",
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _generateQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8DAA91),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Generate AI Quiz"),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    if (_quizComplete) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Quiz Finished!",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              "Score: $_score / ${_questions.length}",
              style: TextStyle(fontSize: 24, color: Color(0xFF8DAA91)),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back to Home"),
            ),
          ],
        ),
      );
    }

    final q = _questions[_currentIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length,
          backgroundColor: Colors.white10,
          color: const Color(0xFF8DAA91),
        ),
        const SizedBox(height: 40),
        Text(
          "Question ${_currentIndex + 1}",
          style: const TextStyle(color: Colors.white38),
        ),
        const SizedBox(height: 10),
        Text(
          q['question'],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        ...List.generate(4, (i) => _buildOption(i, q['options'][i])),
      ],
    );
  }

  Widget _buildOption(int index, String text) {
    return GestureDetector(
      onTap: () => _handleAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white10,
              child: Text(
                "${index + 1}",
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
