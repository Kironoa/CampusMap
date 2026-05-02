import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:naviapp/services/ai_navigation_service.dart';

class AINavSheet extends StatefulWidget {
  final String? currentFloor;
  final String? currentRoomId;
  final void Function(List<Offset> pathPoints, int? targetFloor, String? targetRoomId)? onNavigationResult;
  final void Function(String destination)? onNavigateRequest;

  const AINavSheet({
    super.key,
    this.currentFloor,
    this.currentRoomId,
    this.onNavigationResult,
    this.onNavigateRequest,
  });

  @override
  State<AINavSheet> createState() => _AINavSheetState();
}

class _AINavSheetState extends State<AINavSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, String>> _apiHistory = [];
  bool _isLoading = false;
  List<Offset> _lastPathPoints = [];
  int? _lastTargetFloor;
  String? _lastTargetRoomId;

  Future<void> _send() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    final isNavRequest = _isNavigationRequest;
    final destination = _destinationFromQuery;

    if (isNavRequest && destination.isNotEmpty && widget.onNavigateRequest != null) {
      Navigator.pop(context);
      widget.onNavigateRequest!(destination);
      return;
    }

    _controller.clear();
    if (!mounted) return;
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

      _lastPathPoints = result.pathPoints;
      if (result.floor != null) {
        _lastTargetFloor = int.tryParse(result.floor!);
      }
      _lastTargetRoomId = result.targetRoomId;

      _apiHistory.addAll([
        {'role': 'user', 'content': query},
        {'role': 'assistant', 'content': result.answer},
      ]);

      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': result.answer,
          'steps': result.steps,
          'hasPath': result.pathPoints.isNotEmpty,
        });
        _isLoading = false;
      });

      if (result.pathPoints.isEmpty && result.targetRoomId != null && widget.onNavigateRequest != null) {
        widget.onNavigateRequest!(result.targetRoomId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'Sorry, I couldn\'t process that. Please try again.'
        });
        _isLoading = false;
      });
    }
  }

  void _showPathOnMap() {
    if (_lastPathPoints.isNotEmpty && widget.onNavigationResult != null) {
      Navigator.pop(context);
      widget.onNavigationResult!(_lastPathPoints, _lastTargetFloor, _lastTargetRoomId);
    }
  }

  bool get _isNavigationRequest {
    final query = _controller.text.trim().toLowerCase();
    return query.contains('go to') ||
        query.contains('take me to') ||
        query.contains('navigate to') ||
        query.contains('find') ||
        query.contains('where is') ||
        query.contains('how to get');
  }

  String get _destinationFromQuery {
    final query = _controller.text.trim().toLowerCase();
    String destination = query
        .replaceAll('take me to ', '')
        .replaceAll('go to ', '')
        .replaceAll('navigate to ', '')
        .replaceAll('find ', '')
        .replaceAll('where is ', '')
        .replaceAll('how to get to ', '')
        .trim();
    return destination;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _buildSteps(List steps, bool isDark) {
    return steps.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFF1C0A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C1F0E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4B3621) : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    color: Color(0xFF16A34A), size: 24),
                const SizedBox(width: 8),
                Text('AI Navigator',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFFF7ED) : const Color(0xFF1C0A00),
                    )),
                if (widget.currentRoomId != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Text(
                      widget.currentRoomId!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(
            height: 16,
            color: isDark ? const Color(0xFF3D2A10) : const Color(0xFFFED7AA),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Thinking...',
                          style: TextStyle(color: Color(0xFF16A34A))),
                    ]),
                  );
                }
                final msg = _messages[index];
                return _MessageBubble(
                  message: msg,
                  isUser: msg['role'] == 'user',
                  isDark: isDark,
                  steps: _buildSteps(msg['steps'] as List? ?? [], isDark),
                  onShowPath: msg['hasPath'] == true ? _showPathOnMap : null,
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Where do you want to go?',
                      hintStyle: TextStyle(
                        color: isDark
                            ? const Color(0xFFFED7AA)
                            : const Color(0xFF78350F),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFFFED7AA)
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFFFED7AA)
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: Color(0xFFF97316),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _isLoading ? null : _send,
                  backgroundColor: _isLoading
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isUser;
  final bool isDark;
  final List<Widget> steps;
  final VoidCallback? onShowPath;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.isDark,
    this.steps = const [],
    this.onShowPath,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFFF97316)
              : (isDark
                  ? const Color(0xFF14532D)
                  : const Color(0xFFF0FDF4)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['text'] as String,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFF1C0A00)),
              ),
            ),
            if (!isUser && steps.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...steps,
            ],
            if (!isUser && message['hasPath'] == true && onShowPath != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onShowPath,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Show on Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
