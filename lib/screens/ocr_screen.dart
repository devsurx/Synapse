import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/openrouter_service.dart';
import '../widgets/synapse_widgets.dart';

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

      // 2. AI Cleanup Step (Fixing OCR errors) via OpenRouter
      final apiKey = await OpenRouterService.getApiKey();
      if (apiKey.isEmpty) {
        throw Exception("OpenRouter API key missing. Add it in Settings.");
      }
      final prompt =
          """
      The following text was extracted from handwritten notes via OCR.
      It might have typos. Please fix the grammar, spelling, and format it into
      clean, readable study notes.
      TEXT: ${recognizedText.text}
      """;

      String cleanedText;
      try {
        cleanedText = await OpenRouterService.generateText(
          prompt,
          apiKey: apiKey,
          systemInstruction:
              'You clean up OCR text into polished, readable study notes.',
        );
      } catch (_) {
        cleanedText = recognizedText.text;
      }

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
        title: const PillHeader("HANDWRITING SCANNER"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white54,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
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
                PrimaryButton(
                  label: "CAMERA",
                  icon: Icons.camera_alt_rounded,
                  onPressed: () => _processHandwriting(ImageSource.camera),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: "GALLERY",
                  icon: Icons.photo_library_rounded,
                  onPressed: () => _processHandwriting(ImageSource.gallery),
                  background: Colors.white.withOpacity(0.08),
                  foreground: Colors.white,
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
}
