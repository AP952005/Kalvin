import 'package:flutter/material.dart';

/// Kalvin brand color system
class AppColors {
  // ── Primary Blue ──
  static const Color primaryBlue = Color(0xFF3880FF);
  static const Color primaryBlueLight = Color(0xFF5190FF);
  static const Color primaryBlueDark = Color(0xFF2060DD);

  // ── Secondary Orange ──
  static const Color primaryOrange = Color(0xFFF7931E);
  static const Color primaryOrangeLight = Color(0xFFFFA945);

  // ── Semantic ──
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFCC00);

  // ── Neutrals ──
  static const Color grey100 = Color(0xFFF5F6FA);
  static const Color grey200 = Color(0xFFE8EAF0);
  static const Color grey300 = Color(0xFFCDD1DB);
  static const Color grey400 = Color(0xFF9CA3B0);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);

  // ── Dark surfaces ──
  static const Color darkBg = Color(0xFF0B0E14);
  static const Color darkSurface = Color(0xFF111620);
  static const Color darkCard = Color(0xFF161C28);
  static const Color darkElevated = Color(0xFF1C2435);
  static const Color darkBorder = Color(0xFF252D3D);

  // ── Light surfaces ──
  static const Color lightBg = Color(0xFFF8F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF161C28), Color(0xFF1A2232)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
