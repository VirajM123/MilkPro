import 'package:flutter/material.dart';

/// Central color tokens for the Milk Distribution application.
///
/// These values are derived from the existing Login and Dashboard screens.
/// Screens should reference these semantic tokens instead of declaring their
/// own copies of the same colors.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF1665E8);
  static const Color primaryDark = Color(0xFF1454D8);
  static const Color primaryDeep = Color(0xFF0B2D69);
  static const Color primarySoft = Color(0xFFEDF5FF);
  static const Color primaryBorder = Color(0xFFD5E4FF);

  // Surfaces
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFD);
  static const Color surfaceBlue = Color(0xFFF3F7FF);

  // Content
  static const Color textPrimary = Color(0xFF14213D);
  static const Color textSecondary = Color(0xFF687894);
  static const Color textMuted = Color(0xFF8795AA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Structure
  static const Color border = Color(0xFFE1E7F0);
  static const Color divider = Color(0xFFE9ECF1);
  static const Color disabled = Color(0xFFB8C1CF);

  // Semantic states
  static const Color success = Color(0xFF16A765);
  static const Color successSoft = Color(0xFFEAF8F0);
  static const Color warning = Color(0xFFFF7A21);
  static const Color warningSoft = Color(0xFFFFF3E8);
  static const Color error = Color(0xFFE5484D);
  static const Color errorSoft = Color(0xFFFFECEE);
  static const Color info = Color(0xFF20BCE8);
  static const Color infoSoft = Color(0xFFEAF9FF);
  static const Color purple = Color(0xFF7357EB);
  static const Color purpleSoft = Color(0xFFF3EFFF);

  // Transaction states
  static const Color draft = textSecondary;
  static const Color dispatched = primary;
  static const Color inProgress = warning;
  static const Color settled = success;
  static const Color cancelled = error;

  // Overlays and shadows
  static const Color scrim = Color(0x66000000);
  static const Color shadowSoft = Color(0x0D000000);
  static const Color shadowPrimary = Color(0x1F1665E8);
}
