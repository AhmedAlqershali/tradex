// ─── Tradex Design Tokens ────────────────────────────────────────────────────
//
// Single source of truth for all colors used across the app.
// Every screen should reference these constants instead of hardcoding colors.
//
// Primary brand: #4D41DF  (indigo)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  /// The canonical Tradex primary color. Use everywhere.
  static const primary     = Color(0xff4D41DF);
  static const primaryDark = Color(0xff3127A5);
  static const primarySoft = Color(0xffEDE9FF);

  // ── Scaffolds & surfaces ────────────────────────────────────────────────────
  static const scaffold    = Color(0xffF8F9FD);
  static const card        = Colors.white;

  // ── Text ────────────────────────────────────────────────────────────────────
  static const textDark    = Color(0xff1A1A1A);
  static const textMid     = Color(0xff464555);
  static const textGray    = Color(0xff707070);
  static const textLight   = Color(0xff888888);
  static const textHint    = Color(0xffBBBBBB);

  // ── Borders & fills ─────────────────────────────────────────────────────────
  static const border      = Color(0xffEFEFEF);
  static const fieldFill   = Color(0xffF2F3F6);

  // ── Semantic ────────────────────────────────────────────────────────────────
  static const green       = Color(0xff00C896);
  static const orange      = Color(0xffF59E0B);
  static const red         = Color(0xffEF4444);
  static const amber       = Color(0xffF59E0B);

  // ── Legacy aliases (kept for backward compatibility) ────────────────────────
  static const purple      = primary;         // was Color(0xFF6C63FF)
  static const darkBg      = Color(0xFF1A1A2E);
  static const white       = Colors.white;
  static const lightGray   = Color(0xFFF5F5F5);
  static const cardWhite   = Colors.white;
  static const teal        = Color(0xFF00B4D8);
  static const pink        = Color(0xFFFF4E8A);
}
