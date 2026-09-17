import 'package:flutter/material.dart';

/// Synapse design system — single source of truth for color, type,
/// spacing and shape. All screens should draw from here instead of
/// hard-coding hex values, so the whole app shifts in one place.
abstract final class AppColors {
  // Backgrounds
  static const Color abyss = Color(0xFF0A0E0B);
  static const Color forest = Color(0xFF0F1710);
  static const Color coal = Color(0xFF0F0F0F);

  // Brand accents
  static const Color sage = Color(0xFF8DAA91);
  static const Color sageDeep = Color(0xFF6A8A6E);
  static const Color sand = Color(0xFFD4A373);
  static const Color lavender = Color(0xFF9A94C8);
  static const Color aqua = Color(0xFFA3C4BC);

  // Text
  static const Color textPrimary = Color(0xFFEDEFEA);
  static const Color textSecondary = Color(0xFFB9BFB5);
  static const Color textFaint = Color(0xFF8A9187);

  // Surfaces & lines (white overlays on dark bg)
  static Color surface(double opacity) => Colors.white.withOpacity(opacity);
  static const double surfaceCard = 0.04;
  static const double surfaceRaised = 0.07;
  static const double lineSubtle = 0.08;
  static const double lineStrong = 0.14;

  // Status
  static const Color danger = Color(0xFFFF8A80);
  static const Color warning = Colors.orangeAccent;
  static const Color spotify = Color(0xFF1DB954);
}

abstract final class AppRadii {
  static const double card = 24;
  static const double sheet = 30;
  static const double pill = 18;
  static const double button = 16;
  static const double chip = 999;
}

/// Type scale. Labels are the signature "system" voice
/// (tiny, bold, wide-tracked); body copy stays quiet and readable.
abstract final class AppType {
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.15,
  );
  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );
  static const TextStyle label = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: AppColors.textFaint,
    letterSpacing: 2.5,
  );
  static TextStyle labelTinted(Color color) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: color,
    letterSpacing: 2.5,
  );
}

/// App-wide Material theme (scaffold, inputs, snackbars).
ThemeData buildSynapseTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.abyss,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.sage,
      secondary: AppColors.sand,
      surface: AppColors.abyss,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.textPrimary,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      contentTextStyle: const TextStyle(color: AppColors.sage),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.sage,
    ),
  );
}
