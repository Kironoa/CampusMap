import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  final List<Map<String, String>> conversationMessages = [];
  bool isLoading = false;

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void addMessage(Map<String, String> message) {
    conversationMessages.add(message);
    notifyListeners();
  }

  void clearConversation() {
    conversationMessages.clear();
    notifyListeners();
  }
}
