import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviapp/providers/theme_provider.dart';

double res(BuildContext context, double value) {
  final provider = Provider.of<ThemeProvider>(context, listen: false);
  return value * provider.uiScale;
}