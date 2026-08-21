import 'package:flutter/material.dart';

/// Brand palette — reskinned to match the new Figma design: a clean,
/// airy off-white canvas, near-black for primary UI chrome (selected chips,
/// headings, the "Get Started" pill), and a vibrant pink used as the single
/// accent color for calls-to-action, prices and favorites.
///
/// Token *names* are kept the same as before (primaryNavy, gold, ...) even
/// though the hues changed, since dozens of widgets across the app already
/// reference them — this makes the whole app pick up the new look from one
/// file instead of a widget-by-widget rewrite.
class AppColors {
  AppColors._();

  // "Navy" tokens now hold the near-black used for dark chrome: selected
  // category chips, the splash background, bold headings.
  static const Color primaryNavy = Color(0xFF15161C);
  static const Color primaryNavyLight = Color(0xFF23242C);

  // "Gold" tokens now hold the pink accent used for prices, the favorite
  // heart, and primary CTAs like "Book Now".
  static const Color gold = Color(0xFFFF4D8D);
  static const Color goldLight = Color(0xFFFF8FB6);

  static const Color scaffoldLight = Color(0xFFF4F5F9);
  static const Color scaffoldDark = Color(0xFF0E0F14);

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1A1C24);

  static const Color textPrimaryLight = Color(0xFF15161C);
  static const Color textSecondaryLight = Color(0xFF8A8F98);
  static const Color textPrimaryDark = Color(0xFFF2F3F5);
  static const Color textSecondaryDark = Color(0xFFA0A6B4);

  static const Color success = Color(0xFF1E8E5A);
  static const Color error = Color(0xFFD64545);
  static const Color warning = Color(0xFFE0A63A);

  static const Color divider = Color(0xFFE9EAF0);
  static const Color dividerDark = Color(0xFF262B3A);

  static const Color whatsapp = Color(0xFF25D366);
}
