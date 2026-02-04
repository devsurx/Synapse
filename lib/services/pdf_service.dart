import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  static Future<String> extractText(String path) async {
    try {
      final File file = File(path);
      // Load an existing PDF document.
      final PdfDocument document = PdfDocument(
        inputBytes: await file.readAsBytes(),
      );
      // Extract text from all pages.
      String text = PdfTextExtractor(document).extractText();
      // Dispose the document.
      document.dispose();
      return text;
    } catch (e) {
      return "Error: Could not read PDF. $e";
    }
  }
}
