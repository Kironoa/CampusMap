// lib/screens/ai_navigation_chat.dart
//
// In-app HELP assistant: teaches users HOW TO USE the app (QR scan,
// Floor Plan, Live Navigation, building handoff, voice, dark mode,
// troubleshooting). It does not compute routes — directions live in the
// Floor Plan and Live Navigation screens; this chat points users there.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:naviapp/services/app_help.dart';
import 'package:shimmer/shimmer.dart';

/// Chat message in the AI navigation conversation.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  ChatMessage.empty() : text = '', isUser = false, timestamp = DateTime.now();
}

/// State for the AI navigation chat screen.
class _AINavChatState extends State<AINavChatScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  // Oldest-first: with the reversed ListView below, index 0 (bottom)
  // is the newest message, so the conversation grows upward.
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  late final ScrollController _scrollController;

  /// Speaks AI replies aloud. Off by default until the user opts in.
  final FlutterTts _tts = FlutterTts();
  bool _speechEnabled = false;
  bool _isSpeaking = false;

  _AINavChatState();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _messages.add(ChatMessage(text: AppHelp.greeting, isUser: false));
    // Scroll to bottom (newest) after initial message.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _initTts();
  }

  /// Configures the platform TTS engine. Errors are swallowed so the chat
  /// keeps working (silently) where TTS is unavailable, e.g. widget tests.
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _tts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (_) {
      // TTS unavailable — text chat still works.
    }
  }

  /// Speaks [text] aloud when the user enabled voice replies.
  Future<void> _speak(String text) async {
    if (!_speechEnabled || text.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Ignore TTS failures; the text reply is already shown.
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore.
    }
  }

  void _toggleSpeech() {
    setState(() => _speechEnabled = !_speechEnabled);
    if (!_speechEnabled) {
      _stopSpeaking();
    } else {
      // Replay the latest AI reply so the user hears what enabling does.
      for (var i = _messages.length - 1; i >= 0; i--) {
        if (!_messages[i].isUser && _messages[i].text.isNotEmpty) {
          _speak(_messages[i].text);
          break;
        }
      }
    }
  }

  /// With `reverse: true`, offset 0 is the bottom (newest messages).
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }

  @override
  void dispose() {
    _stopSpeaking();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Answers a how-to question about using the app (offline topic matcher).
  Future<String> _answerHelpRequest(String text) async {
    return AppHelp.answerFor(text);
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
      // Keep only last 50 messages (drop oldest from the front).
      if (_messages.length > 50) _messages.removeAt(0);
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _addMessage(ChatMessage(text: text, isUser: true));
    setState(() => _isSending = true);
    // Stop any in-progress speech before answering the new request.
    await _stopSpeaking();
    try {
      final reply = await _answerHelpRequest(text);
      _addMessage(ChatMessage(text: reply, isUser: false));
      await _speak(reply);
    } finally {
      if (mounted) setState(() => _isSending = false);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Help'),
        backgroundColor: const Color(0xFF0A7040),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _speechEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            tooltip: _speechEnabled
                ? 'Mute spoken replies'
                : 'Speak replies aloud',
            onPressed: _toggleSpeech,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _addMessage(
                ChatMessage(text: AppHelp.capabilities, isUser: false),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              reverse: true,
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];

                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? const Color(0xFF0A7040)
                          : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: msg.isUser
                            ? const Radius.circular(6)
                            : const Radius.circular(20),
                        bottomLeft: msg.isUser
                            ? const Radius.circular(20)
                            : const Radius.circular(6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: textTheme.bodyMedium?.copyWith(
                            color: msg.isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                        // Replay button on AI replies for on-demand speech.
                        if (!msg.isUser && msg.text.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () {
                                if (_isSpeaking) {
                                  _stopSpeaking();
                                } else {
                                  _speak(msg.text);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  _isSpeaking
                                      ? Icons.stop_circle_outlined
                                      : Icons.volume_up_outlined,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(
                          0xFF0A7040,
                        ).withValues(alpha: isDark ? 0.35 : 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _handleSubmit(),
                      decoration: const InputDecoration(
                        hintText: 'Ask how to use the app...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0A7040),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x400A7040),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _handleSubmit,
                          tooltip: 'Send',
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// In-app help chat screen (how to use the app).
class AINavChatScreen extends StatefulWidget {
  const AINavChatScreen({super.key});

  @override
  State<AINavChatScreen> createState() => _AINavChatState();
}
