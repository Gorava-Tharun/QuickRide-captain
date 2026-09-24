import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';

/// Centralized Error & Exception Handler for QuickRide Captain App.
class CaptainErrorHandler {
  CaptainErrorHandler._();

  /// Translates raw technical exceptions into friendly user strings.
  static String getFriendlyErrorMessage(Object? error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    if (error is FirebaseAuthException) {
      switch (error.code.toLowerCase()) {
        case 'user-not-found':
          return 'No Captain account found with this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect credentials. Please verify your phone or password.';
        case 'email-already-in-use':
          return 'A captain account already exists with this email.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'user-disabled':
          return 'Your Captain account is under review or suspended. Contact Admin.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again in a few minutes.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return error.message ?? 'Authentication error. Please try again.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code.toLowerCase()) {
        case 'permission-denied':
          return 'Access denied. You do not have permission for this action.';
        case 'unavailable':
          return 'Service temporarily unavailable. Operating in local mode.';
        case 'not-found':
          return 'Ride or document could not be found.';
        case 'deadline-exceeded':
          return 'Connection timed out. Please try again.';
        case 'quota-exceeded':
          return 'Storage limit reached. Please contact support.';
        default:
          return error.message ?? 'Database error. Operating in offline protection.';
      }
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network and retry.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please check your network connection.';
    }

    final str = error.toString();
    if (str.contains('SocketException') || str.contains('Network is unreachable')) {
      return 'No internet connection. Please check your network and retry.';
    }
    if (str.contains('permission-denied')) {
      return 'Access denied. You do not have permission for this action.';
    }

    return 'Operation could not be completed. Please try again.';
  }

  /// Displays a styled error SnackBar with optional retry action.
  static void showErrorSnackBar(
    BuildContext context,
    Object? error, {
    VoidCallback? onRetry,
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = customMessage ?? getFriendlyErrorMessage(error);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Displays a success SnackBar.
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }
}
