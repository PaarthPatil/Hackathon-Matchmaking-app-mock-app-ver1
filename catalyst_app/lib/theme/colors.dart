import 'package:flutter/material.dart';

/// Color tokens for Catalyst app - used by both light and dark themes
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primaryBlue = Color(0xFF0A84FF);
  static const Color secondaryCyan = Color(0xFF5AC8FA);

  // Light mode colors
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F3F5);
  static const Color lightOnSurface = Color(0xFF1A1A1A);
  static const Color lightOnSurfaceVariant = Color(0xFF6B7280);
  static const Color lightOutline = Color(0xFFE5E7EB);
  static const Color lightError = Color(0xFFDC2626);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkOnSurface = Color(0xFFF9FAFB);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkOutline = Color(0xFF374151);
  static const Color darkError = Color(0xFFF87171);

  // Semantic colors - same for both modes
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
