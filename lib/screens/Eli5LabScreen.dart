import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/ad_widget.dart';

class Eli5LabScreen extends StatefulWidget {
  const Eli5LabScreen({super.key});

  @override
  State<Eli5LabScreen> createState() => _Eli5LabScreenState();
}

class _Eli5LabScreenState extends State<Eli5LabScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _simplifiedText = "";
  bool _isLoading = false;

  // TIP: Ensure this key has "Generative Language API" enabled in Google Cloud/AI Studio
  final String _apiKey = "AIzaSyCAnahv3xdlsl5Gc4lrxYYoCyR74tke2NI";

  Future<void> _simplifyConcept() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _simplifiedText = "";
    });

    try {
      // FIX 1: Using the most stable 2026 model ID
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: _apiKey,
      );

      final prompt =
          "Explain the following like I'm 5 years old. Use a funny analogy: ${_inputController.text}";
      final content = [Content.text(prompt)];

      final response = await model.generateContent(content);

      setState(() {
        _simplifiedText = response.text ?? "The lab couldn't process this.";
        _isLoading = false;
      });
    } catch (e) {
      // FIX 2: Debug logging so you can see the REAL error in your terminal
      debugPrint("API ERROR: $e");

      setState(() {
        _simplifiedText = "⚠️ Connection Error. Check terminal for details.";
        _isLoading = false;
      });

      // FIX 3: Show a SnackBar with the actual error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString().split(':').last}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("ELI5 Laboratory", style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildInputSection(),
            const SizedBox(height: 30),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF8DAA91)),
              ),
            if (_simplifiedText.isNotEmpty && !_isLoading) ...[
              _buildResultDisplay(),
              const SizedBox(height: 32),

              // AD SECTION
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
              // Inside the 'if (_simplifiedText.isNotEmpty && !_isLoading)' block:
              const SizedBox(height: 12),
              SubtleAdWidget(
                key: UniqueKey(),
              ), // UniqueKey forces the widget to rebuild and load a new ad
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildInputSection() {
    return Column(
      children: [
        TextField(
          controller: _inputController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Paste jargon here...",
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF8DAA91).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8DAA91).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF8DAA91), size: 20),
              SizedBox(width: 8),
              Text(
                "THE 5-YEAR-OLD VERSION",
                style: TextStyle(
                  color: Color(0xFF8DAA91),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _simplifiedText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
