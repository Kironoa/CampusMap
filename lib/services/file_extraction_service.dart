import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class FileExtractionService {
  static final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  static Future<String> extractText(String filePath, String category) async {
    final File file = File(filePath);
    if (!await file.exists()) return "";

    try {
      if (category == 'pdf') {
        return await _extractFromPdf(file);
      } else if (category == 'jpg' || category == 'png') {
        return await _extractFromImage(file);
      }
    } catch (e) {
      print("Extraction Error: $e");
    }
    return "";
  }

  static Future<String> _extractFromPdf(File file) async {
    final PdfDocument document =
        PdfDocument(inputBytes: await file.readAsBytes());

    // Use LayoutText (keeps columns and paragraphs together better)
    PdfTextExtractor extractor = PdfTextExtractor(document);
    String text = extractor.extractText();

    // CLEANUP: Remove extra newlines that break sentences
    text = text.replaceAll(RegExp(r'\r\n+|\n+|\r+'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    if (text.trim().length < 20) {
      print("OCR might be needed for this PDF.");
    }

    document.dispose();
    return text.trim();
  }

  static Future<String> _extractFromImage(File file) async {
    final inputImage = InputImage.fromFile(file);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    // Join lines with spaces to maintain sentence integrity
    return recognizedText.text.replaceAll('\n', ' ').trim();
  }
}
