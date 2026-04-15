import 'package:mobile_app/helper/db_helper.dart';

class OfflineAIService {
  final DatabaseHelper _db = DatabaseHelper();

  /// MAIN SEARCH: Used by the Offline AI Chat Screen
  Future<String> searchOfflineKnowledge(int userId, String query) async {
    if (query.trim().isEmpty) {
      return "Please ask me something about your studies!";
    }

    try {
      final String cleanQuery = query.toLowerCase().trim();
      final List<Map<String, dynamic>> results =
          await _db.searchNotesOffline(userId, cleanQuery);

      if (results.isEmpty) {
        return "I couldn't find anything in your offline notes or files about '$query'.\n\nMake sure you have saved notes with those keywords!";
      }

      String response =
          "Found ${results.length} relevant items in your offline storage:\n\n";

      for (var item in results) {
        // Determine if it's a note or a file based on keys
        bool isNote = item.containsKey('title');
        String title = item['title'] ?? item['fileName'] ?? "Untitled";
        String typeEmoji = isNote ? "📌" : "📄";

        response += "$typeEmoji **$title**\n";

        if (item['description'] != null &&
            item['description'].toString().isNotEmpty) {
          response += "${item['description']}\n";
        }

        if (item['content'] != null && item['content'].toString().isNotEmpty) {
          String snippet = item['content'].toString();
          if (snippet.length > 100) {
            snippet = "${snippet.substring(0, 100)}..."; // Truncate long text
          }
          response += "📝 *Snippet: $snippet*\n";
        }
        response += "\n";
      }

      return response;
    } catch (e) {
      return "Error searching offline database: $e";
    }
  }

  /// DATA PROVIDER: Fetches content for Summary, Flashcards, and Quizzes
  /// [isNote] determines if we search the notes table or resources table
  Future<Map<String, String>> getContentForGeneration(
      int id, bool isNote) async {
    try {
      // Logic to fetch a single item's full content by ID
      final Map<String, dynamic>? data =
          isNote ? await _db.getNoteById(id) : await _db.getResourceById(id);

      if (data == null) return {"title": "Unknown", "content": ""};

      return {
        "title": (isNote ? data['title'] : data['fileName']) ?? "Untitled",
        "content": data['content'] ?? data['description'] ?? "",
      };
    } catch (e) {
      return {"title": "Error", "content": ""};
    }
  }

  /// HELPER: Formats the Quiz Prompt based on item count
  String buildQuizPrompt(String content, int itemCount) {
    return "Based on the following study material, generate a $itemCount-item multiple-choice quiz with an answer key at the end:\n\n$content";
  }

  /// HELPER: Formats the Flashcard Prompt
  String buildFlashcardPrompt(String content) {
    return "Create a set of comprehensive flashcards (Question/Answer format) based on this material:\n\n$content";
  }

  /// HELPER: Formats the Summary Prompt
  String buildSummaryPrompt(String content) {
    return "Provide a concise bulleted summary and key takeaways for the following text:\n\n$content";
  }
}
