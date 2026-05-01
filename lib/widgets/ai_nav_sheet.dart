import 'package:flutter/material.dart';
import 'package:naviapp/services/ai_navigation_service.dart';

class AINavSheet extends StatefulWidget {
  final String? currentFloor;
  final String? currentRoomId;
  final void Function(AINavigationResult result) onNavigate;

  const AINavSheet({
    super.key,
    this.currentFloor,
    this.currentRoomId,
    required this.onNavigate,
  });

  @override
  State<AINavSheet> createState() => _AINavSheetState();
}

class _AINavSheetState extends State<AINavSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, String>> _apiHistory = [];
  bool _isLoading = false;

  Future<void> _send() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isLoading = true;
    });

    try {
      final result = await AINavigationService.navigate(
        userQuery: query,
        currentFloor: widget.currentFloor,
        currentRoomId: widget.currentRoomId,
        conversationHistory: _apiHistory,
      );

      _apiHistory.addAll([
        {'role': 'user', 'content': query},
        {'role': 'assistant', 'content': result.answer},
      ]);

      setState(() {
        _messages.add({'role': 'assistant', 'text': result.answer, 'steps': result.steps});
        _isLoading = false;
      });

      widget.onNavigate(result);
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'Sorry, I couldn\'t process that. Please try again.'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.psychology_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('AI Navigator', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      SizedBox(width: 8),
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Thinking...', style: TextStyle(color: Colors.grey)),
                    ]),
                  );
                }
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'] as String,
                          style: TextStyle(
                            color: isUser ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (!isUser && (msg['steps'] as List?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          ...(msg['steps'] as List).map((step) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              step.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Where do you want to go?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _isLoading ? null : _send,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
