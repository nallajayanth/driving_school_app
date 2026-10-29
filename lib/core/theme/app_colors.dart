import 'package:flutter/material.dart';

/// Centralized color palette for the Powerdrive Learning application.
/// Derived from the reference web platform and brand guidelines.
abstract class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primarySubtle = Color(0xFFEFF6FF);

  // Background and surface colors
  static const Color background = Color(0xFFF8FAFC); // Very light slate gray
  static const Color surface = Color(0xFFFFFFFF); // Pure white card surface
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Border and divider colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate / Near Black
  static const Color textSecondary = Color(0xFF64748B); // Slate Muted
  static const Color textMuted = Color(0xFF94A3B8); // Light Slate
  static const Color textInverse = Color(0xFFFFFFFF);

  // Leitner Box / Learning status colors
  // Box 0: New or not correct
  static const Color box0 = Color(0xFF0284C7); // Cyan / Sky Blue
  static const Color box0Background = Color(0xFFF0F9FF);

  // Box 1 (Subject 1): 1x correct
  static const Color box1 = Color(0xFFF59E0B); // Amber / Gold
  static const Color box1Background = Color(0xFFFFFBEB);

  // Box 2 (Subject 2): Correct twice in a row
  static const Color box2 = Color(0xFFEA580C); // Warm Orange
  static const Color box2Background = Color(0xFFFFF7ED);

  // Box 3 (Subject 3): Ready for exam
  static const Color box3 = Color(0xFF10B981); // Emerald Green
  static const Color box3Background = Color(0xFFECFDF5);

  // Semantic feedback colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Logout / Destructive action
  static const Color logout = Color(0xFFEF4444);
  static const Color logoutBackground = Color(0xFFFEF2F2);
}
