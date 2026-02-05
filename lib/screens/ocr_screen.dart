import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OCRScreen extends StatefulWidget {
  final Function(String) onNotesProcessed;
  const OCRScreen({super.key, required this.onNotesProcessed});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  bool _isProcessing = false;
  String _statusMessage = "Ready to scan notes";
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<void> _processHandwriting(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Reading handwriting...";
    });

    try {
      // 1. OCR Step
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      if (recognizedText.text.trim().isEmpty) {
        throw Exception("No text detected. Try a clearer photo.");
      }

      setState(() => _statusMessage = "AI Polishing text...");

      // 2. AI Cleanup Step (Fixing OCR errors)
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final prompt =
          """
      The following text was extracted from handwritten notes via OCR. 
      It might have typos. Please fix the grammar, spelling, and format it into 
      clean, readable study notes.
      TEXT: ${recognizedText.text}
      """;

      final response = await model.generateContent([Content.text(prompt)]);
      final cleanedText = response.text ?? recognizedText.text;

      // 3. Save & Notify
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'saved_pdf_text',
        cleanedText,
      ); // Save as current context
      widget.onNotesProcessed(cleanedText);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notes digitized and synced!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        _isProcessing = false;
        _statusMessage = "Ready to scan notes";
      });
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "HANDWRITING SCANNER",
          style: TextStyle(
            letterSpacing: 2,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white24,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScannerUI(),
              const SizedBox(height: 40),
              if (!_isProcessing) ...[
                _buildActionBtn(
                  "CAMERA",
                  Icons.camera_alt,
                  () => _processHandwriting(ImageSource.camera),
                ),
                const SizedBox(height: 16),
                _buildActionBtn(
                  "GALLERY",
                  Icons.photo_library,
                  () => _processHandwriting(ImageSource.gallery),
                ),
              ] else
                const CircularProgressIndicator(color: Color(0xFF8DAA91)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerUI() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: const Color(0xFF8DAA91).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 80,
            color: _isProcessing ? const Color(0xFF8DAA91) : Colors.white24,
          ),
          const SizedBox(height: 20),
          Text(
            _statusMessage,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF8DAA91), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
