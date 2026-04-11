import 'package:flutter/material.dart';

class ResourceCategory {
  final String title;
  final IconData icon;
  final List<ResourceItem> items;

  ResourceCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class ResourceItem {
  final String label;
  final String content;

  ResourceItem({required this.label, required this.content});
}
