import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/study_note_model.dart';
import 'package:mobile_app/services/ai_service.dart';
import 'package:mobile_app/services/notes_service.dart';
import 'package:mobile_app/services/study_resource_service.dart';

class OfflineAIService {
  final DatabaseHelper _db = DatabaseHelper();
  final AIService _onlineAI = AIService();
  final NotesService _notesService = NotesService();
  final StudyResourceService _resourceService = StudyResourceService();

  InferenceModel? _localModel;

  /// Call this during your Splash Screen or App Initialization
  Future<void> initLocalAI() async {
    try {
      await FlutterGemma.initialize();
      _localModel = await FlutterGemma.getActiveModel(
        // Increased maxTokens to 4096 to support dynamic/long outputs (like 20 flashcards)
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
      );
    } catch (e) {
      debugPrint('Local AI Init Failed: $e');
    }
  }

  Future<String> generateContent({
    required String prompt,
    required int resourceId,
    required String type,
    int count = 5,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final String? cachedContent =
            await _db.getCachedAIContent(resourceId, type);
        if (cachedContent != null && cachedContent.isNotEmpty) {
          return cachedContent;
        }
      }

      final List<ConnectivityResult> connectivityResult =
          await Connectivity().checkConnectivity();
      final bool isOnline =
          !connectivityResult.contains(ConnectivityResult.none);

      String finalResult;

      if (isOnline) {
        try {
          finalResult = await _onlineAI.sendMessage(prompt);
          if (finalResult.isEmpty ||
              finalResult.contains('Error') ||
              finalResult.contains('limit')) {
            finalResult =
                await _generateLocalInference(prompt, type, count: count);
          }
        } catch (_) {
          finalResult =
              await _generateLocalInference(prompt, type, count: count);
        }
      } else {
        finalResult = await _generateLocalInference(prompt, type, count: count);
      }

      if (finalResult.isNotEmpty && !finalResult.startsWith('Local AI Error')) {
        await _db.saveAIContentToCache(resourceId, type, finalResult);
      }

      return finalResult;
    } catch (e) {
      return 'Service Error: $e';
    }
  }

  Future<String> _generateLocalInference(String prompt, String type,
      {int count = 5}) async {
    if (_localModel == null) {
      return "Local AI Error: Offline model not ready. Please download the 'Offline Pack' in settings.";
    }

    try {
      final chat = await _localModel!.createChat();

      String systemInstruction = "";
      switch (type.toLowerCase()) {
        case 'flashcard':
        case 'flashcards':
          systemInstruction =
              "Create exactly $count Q&A flashcards based on the text. Format: Q: [Question] A: [Answer]. Content: ";
          break;
        case 'quiz':
          systemInstruction =
              "Create a $count-question Multiple Choice Quiz. For EACH question use this exact format:\nQ: [Question]\nA) [Option]\nB) [Option]\nC) [Option]\nD) [Option]\nCorrect: [Letter]\n\nContent: ";
          break;
        case 'summary':
        default:
          systemInstruction =
              "Provide a concise summary of the following student notes: ";
      }

      // The `prompt` already contains the full, formatted instructions
      // written by the calling screen (notes_screen.dart). We pass it
      // directly to avoid duplicate / conflicting instructions.
      // The switch-case above is kept only as a fallback for direct calls
      // that supply a bare content string without a format header.
      final bool promptAlreadyFormatted =
          prompt.toLowerCase().contains('format:') ||
              prompt.toLowerCase().contains('generate') ||
              prompt.toLowerCase().contains('summarize');

      final String messageText =
          promptAlreadyFormatted ? prompt : "$systemInstruction\n$prompt";

      await chat.addQueryChunk(
        Message.text(text: messageText, isUser: true),
      );

      final response = await chat.generateChatResponse();
      await chat.close();

      try {
        final dynamic dynamicResponse = response;
        final String? resultText = dynamicResponse.text?.toString();

        if (resultText != null && resultText.isNotEmpty) {
          return resultText.trim();
        }
      } catch (_) {
        return response.toString().trim();
      }

      return "Local AI: No text content generated.";
    } catch (e) {
      return "Local AI Error: Inference failed - $e";
    }
  }

  Future<String> getOfflineResponse(int userId, String query) async {
    if (query.trim().isEmpty) return 'Ask me something about your studies!';

    try {
      final List<StudyNote> results = await _notesService.searchNotesOffline(
        userId,
        query.toLowerCase().trim(),
      );
      if (results.isEmpty) return "No local matches found for '$query'.";

      final findings = results
          .map((item) =>
              'NOTE: ${item.title}\n${item.content ?? item.description ?? ''}\n')
          .toList();

      return 'Found ${results.length} items:\n\n${findings.join("\n---\n")}';
    } catch (e) {
      return 'Offline AI Error: $e';
    }
  }

  Future<void> downloadOfflineModel(Function(int) onProgress) async {
    await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromNetwork(
          'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
        )
        .withProgress((progress) => onProgress(progress))
        .install();

    await initLocalAI();
  }

  String buildSummaryPrompt(String content) => 'Summary:\n\n$content';

  String buildFlashcardPrompt(String content, {int count = 5}) =>
      'Generate $count Flashcards:\n\nText:\n$content';

  String buildQuizPrompt(String content, int count) =>
      'Generate a $count-question Quiz:\n\nText:\n$content';

  Future<Map<String, String>> getContentForGeneration(
      int id, bool isNote) async {
    if (isNote) {
      final note = await _notesService.getNoteById(id);
      if (note == null) return {'title': 'Unknown', 'content': ''};
      return {
        'title': note.title,
        'content': note.content ?? note.description ?? '',
      };
    }

    final resource = await _resourceService.getResourceById(id);
    if (resource == null) return {'title': 'Unknown', 'content': ''};
    return {
      'title': resource.fileName,
      'content': resource.content ?? '',
    };
  }
}
