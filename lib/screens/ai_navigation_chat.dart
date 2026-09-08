// lib/screens/ai_navigation_chat.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naviapp/providers/user_location_provider.dart';
import 'package:naviapp/services/ai_navigation_service.dart';
import 'package:naviapp/services/navigation_graph.dart';
import 'package:naviapp/services/pathfinder.dart';
import 'package:naviapp/services/route_calculator.dart';
import 'package:naviapp/services/room_catalog.dart';
import 'package:provider/provider.dart';

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
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  Timer? _pollTimer;
  ScrollController? _scrollController;

  _AINavChatState();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _messages.add(
      ChatMessage(
        text:
            'Ask me to navigate anywhere on campus! Try: "Navigate to room 305" or "How do I get to the library from the main entrance?"',
        isUser: false,
      ),
    );
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => setState(() {}),
    );
    // Scroll to bottom after initial message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController?.jumpTo(_scrollController!.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pollTimer?.cancel();
    _scrollController?.dispose();
    super.dispose();
  }

  /// Returns (floorIndex, startLabel, destinationRoomName, destinationRoomId) or null.
  Map<String, dynamic>? _parseNavigationRequest(String text) {
    final lower = text.toLowerCase();

    // Pattern: "navigate to [room]" or "go to [room]" or "get directions to [room]"
    final navPatterns = [
      RegExp(
        r'(?:navigate|go|directions?)\s+to\s+(.+?)(?:\.|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:how\s+do\s+i|show\s+me)\s+(?:the\s+)?(?:way\s+to|route\s+to)\s+(.+?)(?:\.|$)',
        caseSensitive: false,
      ),
    ];

    String? roomName;
    String? floorKeyword;

    for (final pattern in navPatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null && match.group(1) != null) {
        final extracted = match.group(1)!.trim();
        // Check for floor keywords
        if (extracted.contains('ground') || extracted.contains('first floor')) {
          floorKeyword = 'Ground Floor';
        } else if (extracted.contains('2nd') ||
            extracted.contains('second floor')) {
          floorKeyword = '2nd Floor';
        } else if (extracted.contains('3rd') ||
            extracted.contains('third floor')) {
          floorKeyword = '3rd Floor';
        }

        // Extract room name (remove floor keywords)
        roomName = extracted;
        if (floorKeyword != null) {
          roomName = roomName
              .replaceAll(RegExp(floorKeyword, caseSensitive: false), '')
              .trim();
        }
        break;
      }
    }

    if (roomName == null) return null;

    // Determine floor
    int floorIndex = 0; // default Ground Floor
    if (lower.contains('third') || lower.contains('3rd')) {
      floorIndex = 2;
    } else if (lower.contains('second') || lower.contains('2nd')) {
      floorIndex = 1;
    }

    // Try to find room ID from catalog
    String? roomId;
    final allRooms = RoomCatalog.allRooms.keys.toList();
    for (final floorKey in allRooms) {
      final rooms = RoomCatalog.allRooms[floorKey]!;
      for (final room in rooms) {
        if (room['name']!.toLowerCase().contains(roomName.toLowerCase())) {
          roomId = room['id'];
          break;
        }
      }
      if (roomId != null) break;
    }

    // Determine start label based on live position
    String startLabel = 'your location';
    final userProvider = context.read<UserLocationProvider>();
    if (userProvider.position != null) {
      startLabel = 'your live location';
    }

    return {
      'floorIndex': floorIndex,
      'startLabel': startLabel,
      'destinationRoomName': roomName,
      'destinationRoomId': roomId,
    };
  }

  /// Process a navigation request through the routing + AI pipeline.
  Future<void> _handleNavigation(Map<String, dynamic> parsed) async {
    final floorIndex = parsed['floorIndex'] as int;
    final startLabel = parsed['startLabel'] as String;
    final destinationRoomName = parsed['destinationRoomName'] as String;
    final destinationRoomId = parsed['destinationRoomId'] as String?;

    if (destinationRoomId == null || destinationRoomName.isEmpty) {
      _addMessage(
        ChatMessage(
          text:
              'I could not find a room matching "$destinationRoomName". Try specifying the full room name or check the spelling.',
          isUser: false,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Get live position if available
      final livePosition = context.read<UserLocationProvider>().position;

      NavigationResult? result;
      if (livePosition != null) {
        result = RouteCalculator.fromLivePosition(
          position: livePosition,
          roomId: destinationRoomId,
          destinationFloor: floorIndex,
        );
      } else {
        final nodes = NavigationGraph.nodesForFloor(floorIndex);
        final edges = NavigationGraph.edgesForFloor(floorIndex);
        final endNodeId = Pathfinder.findNearestNodeToRoom(
          destinationRoomId,
          floorIndex,
        );
        final pathPoints = Pathfinder.findPath(
          startNodeId: nodes.first.id,
          endNodeId: endNodeId,
          nodes: nodes,
          edges: edges,
        );
        result = NavigationResult(
          path: pathPoints,
          floorIndices: List.filled(pathPoints.length, floorIndex),
          floorIndex: floorIndex,
          roomId: destinationRoomId,
        );
      }

      if (result == null || result.path.isEmpty) {
        _addMessage(
          ChatMessage(
            text:
                'I could not find a path to $destinationRoomName on the ${_floorName(floorIndex)}. Is the room name correct?',
            isUser: false,
          ),
        );
        return;
      }

      // Get AI directions
      final floorName = _floorName(floorIndex);
      final directions = await AINavigationService.getDirectionsText(
        fromLabel: startLabel,
        toRoomName: destinationRoomName,
        floorName: floorName,
      );

      _addMessage(
        ChatMessage(
          text: directions ?? 'Following the paw trail to $destinationRoomName',
          isUser: false,
        ),
      );
    } catch (e) {
      _addMessage(
        ChatMessage(text: 'Navigation error: ${e.toString()}', isUser: false),
      );
    } finally {
      setState(() => _isSending = false);
      _controller.clear();
    }
  }

  String _floorName(int floorIndex) {
    switch (floorIndex) {
      case 0:
        return 'Ground Floor';
      case 1:
        return '2nd Floor';
      case 2:
        return '3rd Floor';
      default:
        return 'Floor $floorIndex';
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
      // Keep only last 50 messages
      if (_messages.length > 50) _messages.removeLast();
      // Scroll to bottom after adding message
      _scrollController?.jumpTo(_scrollController!.position.maxScrollExtent);
    });
    _controller.clear();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _addMessage(ChatMessage(text: text, isUser: true));

    // Check if this is a navigation request
    final parsed = _parseNavigationRequest(text);
    if (parsed != null && parsed['destinationRoomId'] != null) {
      _handleNavigation(parsed);
    } else {
      // Treat as conversational query
      _addMessage(ChatMessage(text: _getAIResponse(text), isUser: false));
    }
  }

  String _getAIResponse(String text) {
    // Navigation-aware responses for common queries
    final lower = text.toLowerCase();
    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey')) {
      return 'Hello! I\'m NaviApp\'s AI navigation assistant. I can help you find routes between any rooms on campus (Ground, 2nd, or 3rd Floor). Try asking me to "Navigate to room 305" or "How do I get to the library"?';
    }
    if (lower.contains('thank') || lower.contains('thanks')) {
      return 'You\'re welcome! Safe travels! Feel free to ask for directions to any building location.';
    }
    if (lower.contains('help')) {
      return 'I can help you navigate around campus! Try saying things like:\n'
          '- "Navigate to room 305"\n'
          '- "How do I get to the library?"\n'
          '- "Go to the main entrance from the library"\n'
          '- "Directions from the cafeteria to the auditorium"';
    }
    if (lower.contains('floor')) {
      return 'I can help you navigate between all three floors of the building: Ground Floor, 2nd Floor, and 3rd Floor. Each floor has different room layouts and staircases connecting them. Ask me for directions between specific rooms!';
    }
    if (lower.contains('room')) {
      return 'I can help you navigate to any room on campus! I have access to room catalogs for all three floors. Just ask me to "Navigate to [room name]" and I\'ll find the best route for you.';
    }
    if (lower.contains('where') || lower.contains('location')) {
      return 'I can help you locate rooms and starting points on campus! I know the positions of QR code starting points on all floors, as well as room locations. Ask me for directions or location information!';
    }
    return 'I\'m not sure I understand. I\'m NaviApp\'s AI navigation assistant - I help you find routes between rooms on campus. Try asking me to "Navigate to room 305" or "How do I get to the library"?';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Navigation'),
        backgroundColor: const Color(0xFF0A7040),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _addMessage(
                ChatMessage(
                  text:
                      'I\'m NaviApp\'s AI navigation assistant! I can help you find routes between rooms on campus. Try asking things like "Navigate to room 305" or "How do I get to the library from the main entrance?"',
                  isUser: false,
                ),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? const Color(0xFF0A7040)
                          : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : Colors.black87,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
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
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _handleSubmit(),
                      decoration: const InputDecoration(
                        hintText: 'Type your request...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0A7040),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF0A7040)),
                        onPressed: _handleSubmit,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat-based AI navigation screen.
class AINavChatScreen extends StatefulWidget {
  const AINavChatScreen({super.key});

  @override
  State<AINavChatScreen> createState() => _AINavChatState();
}
