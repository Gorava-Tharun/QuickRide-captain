import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand Accents
  static const Color primary = Color(0xFFFFC700); // Captain Gold
  static const Color primaryDark = Color(0xFFFF9E00);
  static const Color secondary = Color(0xFF00E5FF); // Electric Cyan
  static const Color onlineGreen = Color(0xFF10B981); // Captain Online
  static const Color offlineGrey = Color(0xFF64748B); // Captain Offline

  // Surfaces & Backgrounds
  static const Color backgroundDark = Color(0xFF0A0E17);
  static const Color surfaceDark = Color(0xFF131B2A);
  static const Color surfaceElevatedDark = Color(0xFF1B2436);
  static const Color cardDark = Color(0xFF162032);
  static const Color borderDark = Color(0xFF263248);

  // Typography
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
