import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── AppTextStyles ────────────────────────────────────────────────────────────
//
// Centralized IBM Plex Sans text styles used across the app.
// Always reference these constants instead of calling GoogleFonts inline,
// so typography changes propagate from one place.
// ─────────────────────────────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  // ── Headings ───────────────────────────────────────────────────────────────
  static TextStyle heading1({Color color = const Color(0xff1A1A1A)}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: 24.sp, fontWeight: FontWeight.bold, color: color);

  static TextStyle heading2({Color color = const Color(0xff1A1A1A)}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: 20.sp, fontWeight: FontWeight.bold, color: color);

  static TextStyle heading3({Color color = const Color(0xff1A1A1A)}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: 18.sp, fontWeight: FontWeight.bold, color: color);

  static TextStyle title({Color color = const Color(0xff1A1A1A)}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: 16.sp, fontWeight: FontWeight.bold, color: color);

  static TextStyle titleSmall({Color color = const Color(0xff1A1A1A)}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: 14.sp, fontWeight: FontWeight.bold, color: color);

  // ── Body ───────────────────────────────────────────────────────────────────
  static TextStyle body({Color color = const Color(0xff1A1A1A)}) =>
      GoogleFonts.ibmPlexSans(fontSize: 14.sp, color: color);

  static TextStyle bodySmall({Color color = const Color(0xff707070)}) =>
      GoogleFonts.ibmPlexSans(fontSize: 13.sp, color: color);

  static TextStyle caption({Color color = const Color(0xff888888)}) =>
      GoogleFonts.ibmPlexSans(fontSize: 12.sp, color: color);

  static TextStyle micro({Color color = const Color(0xff888888)}) =>
      GoogleFonts.ibmPlexSans(fontSize: 11.sp, color: color);

  // ── Labels & hints ─────────────────────────────────────────────────────────
  static TextStyle label({Color color = const Color(0xff464555)}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: 13.sp, fontWeight: FontWeight.w600, color: color);

  static TextStyle hint({Color color = const Color(0xffBBBBBB)}) =>
      GoogleFonts.ibmPlexSans(fontSize: 13.sp, color: color);

  // ── Price ──────────────────────────────────────────────────────────────────
  static TextStyle price({Color color = const Color(0xff4D41DF)}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: 15.sp, fontWeight: FontWeight.bold, color: color);

  static TextStyle priceLarge({Color color = const Color(0xff4D41DF)}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: 18.sp, fontWeight: FontWeight.bold, color: color);

  // ── Buttons ────────────────────────────────────────────────────────────────
  static TextStyle button({Color color = Colors.white}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: 16.sp, fontWeight: FontWeight.bold, color: color);

  static TextStyle buttonSmall({Color color = Colors.white}) =>
      GoogleFonts.ibmPlexSans(
          fontSize: 14.sp, fontWeight: FontWeight.bold, color: color);
}
