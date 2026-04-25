import 'package:flutter/material.dart';

double res(BuildContext context, double value) {
  final width = MediaQuery.of(context).size.width;
  return value * (width / 390).clamp(0.8, 1.4);
}