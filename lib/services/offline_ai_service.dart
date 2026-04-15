import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/services/ai_service.dart';

class OfflineAIService {
  final DatabaseHelper _db = DatabaseHelper();
  final AIService _onlineAI = AIService();

  /// SMART GENERATION: The main entry point for ResourceScreen.
  Future<String> generateContent({
    required String prompt,
    required int resourceId,
    required String type, // "SUMMARY", "FLASHCARDS", or "QUIZ"
  }) async {
    try {
      // 1. Check Local Cache first
      final String? cachedContent =
          await _db.getCachedAIContent(resourceId, type);
      if (cachedContent != null && cachedContent.isNotEmpty)
        return cachedContent;

      // 2. Check Connection
      final List<ConnectivityResult> connectivityResult =
          await (Connectivity().checkConnectivity());
      bool isOnline = !connectivityResult.contains(ConnectivityResult.none);

      String finalResult;

      if (isOnline) {
        try {
          finalResult = await _onlineAI.sendMessage(prompt);
          if (finalResult.isEmpty ||
              finalResult.contains("Error") ||
              finalResult.contains("limit")) {
            finalResult = await _generateLocalInference(prompt, type);
          }
        } catch (e) {
          finalResult = await _generateLocalInference(prompt, type);
        }
      } else {
        finalResult = await _generateLocalInference(prompt, type);
      }

      // 3. Save to Cache
      if (finalResult.isNotEmpty && !finalResult.startsWith("Service Error")) {
        await _db.saveAIContentToCache(resourceId, type, finalResult);
      }

      return finalResult;
    } catch (e) {
      return "Service Error: $e";
    }
  }

  /// LOCAL INFERENCE: Patterns-based extraction for accuracy
  Future<String> _generateLocalInference(String prompt, String type) async {
    // Extract raw text from the prompt
    String textContent = prompt.split("Text:").last.trim();

    List<String> sentences = textContent
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.length > 25)
        .toList();

    if (sentences.isEmpty) return "Local AI: Not enough content found.";

    if (type == "FLASHCARDS") {
      StringBuffer buffer = StringBuffer();
      // Regex to find definitions (Concept IS definition)
      final defReg =
          RegExp(r'\b(is|are|refers to|means|defines)\b', caseSensitive: false);

      int count = 0;
      for (String s in sentences) {
        if (defReg.hasMatch(s)) {
          var parts = s.split(defReg);
          if (parts.length >= 2 && parts[0].trim().length > 3) {
            buffer.writeln("Q: What is ${parts[0].trim()}?");
            buffer.writeln("A: ${s.trim()}\n");
            count++;
          }
        }
        if (count >= 5) break;
      }
      return buffer.isNotEmpty
          ? buffer.toString()
          : "Q: Key Concept?\nA: ${sentences[0]}";
    } else if (type == "QUIZ") {
      StringBuffer buffer = StringBuffer();
      for (int i = 0; i < (sentences.length > 3 ? 3 : sentences.length); i++) {
        buffer.writeln(
            "${i + 1}. Which statement is true regarding '${sentences[i].substring(0, 15)}...'?");
        buffer.writeln("A) ${sentences[i]}");
        buffer.writeln("B) It is false.");
        buffer.writeln("C) It is not mentioned.");
        buffer.writeln("D) None of the above.");
        buffer.writeln("Answer: A\n");
      }
      return buffer.toString();
    }

    return "Offline Summary: ${sentences.take(2).join(' ')}";
  }

  /// MAIN SEARCH: For the Offline Chat Screen
  Future<String> getOfflineResponse(int userId, String query) async {
    if (query.trim().isEmpty) return "Ask me something about your studies!";
    try {
      final List<Map<String, dynamic>> results =
          await _db.searchNotesOffline(userId, query.toLowerCase().trim());
      if (results.isEmpty) return "No local matches found for '$query'.";

      List<String> findings = [];
      for (var item in results) {
        bool isNote = item.containsKey('title');
        findings.add(
            "${isNote ? "📝" : "📄"} **${isNote ? "NOTE" : "FILE"}: ${item['title'] ?? item['fileName']}**\n${item['content'] ?? item['description']}\n");
      }
      return "Found ${results.length} items:\n\n${findings.join("\n---\n")}";
    } catch (e) {
      return "Offline AI Error: $e";
    }
  }

  String buildSummaryPrompt(String content) => "Summary:\n\n$content";
  String buildFlashcardPrompt(String content, {int count = 5}) =>
      "Q/A Format:\n\nText:\n$content";
  String buildQuizPrompt(String content, int count) =>
      "Quiz:\n\nText:\n$content";

  Future<Map<String, String>> getContentForGeneration(
      int id, bool isNote) async {
    final data =
        isNote ? await _db.getNoteById(id) : await _db.getResourceById(id);
    if (data == null) return {"title": "Unknown", "content": ""};
    return {
      "title": (isNote ? data['title'] : data['fileName']) ?? "Untitled",
      "content": data['content'] ?? data['description'] ?? "",
    };
  }
}
