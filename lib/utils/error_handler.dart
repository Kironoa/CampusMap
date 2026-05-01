import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AppErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Check your network and try again.';
    }
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (error is PermissionDeniedException) {
      return 'Location permission denied. Enable it in your device settings.';
    }
    if (error is LocationServiceDisabledException) {
      return 'Location services are disabled. Please turn on GPS.';
    }
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      if (message.contains('api key') || message.contains('unauthorized')) {
        return 'Service configuration error. Please contact support.';
      }
      if (message.contains('gemini') || message.contains('generative')) {
        return 'AI service is temporarily unavailable. Try again later.';
      }
      if (message.contains('google map') || message.contains('maps')) {
        return 'Maps service is unavailable. Check your connection.';
      }
      if (message.contains('database') || message.contains('sqlite')) {
        return 'Unable to access offline data. The app will use online mode.';
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

  static void handleError(BuildContext context, dynamic error) {
    showErrorSnackBar(context, error);
  }
}
