// ignore_for_file: avoid_classes_with_only_static_members
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';

class AppErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Check your network and try again.';
    }
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      if (message.contains('api key') || message.contains('unauthorized')) {
        return 'Service configuration error. Please contact support.';
      }
      if (message.contains('ai') || message.contains('anthropic')) {
        return 'AI service is temporarily unavailable. Try again later.';
      }
    }
    return 'Something went wrong. Please try again or contact support.';
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          getUserFriendlyMessage(error),
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
