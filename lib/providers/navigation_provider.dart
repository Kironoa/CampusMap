import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  final ValueNotifier<String> _categoryFilter = ValueNotifier<String>('All');
  final ValueNotifier<bool> _searchOpen = ValueNotifier<bool>(false);

  String get categoryFilter => _categoryFilter.value;
  bool get searchOpen => _searchOpen.value;

  ValueNotifier<String> get categoryFilterNotifier => _categoryFilter;
  ValueNotifier<bool> get searchOpenNotifier => _searchOpen;

  void setCategoryFilter(String value) {
    _categoryFilter.value = value;
    notifyListeners();
  }

  void setSearchOpen(bool value) {
    _searchOpen.value = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _categoryFilter.dispose();
    _searchOpen.dispose();
    super.dispose();
  }
}