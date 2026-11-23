import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Same palette as the E-Season passenger app (RegColors).
class AppColors {
  AppColors._();
  static const deepViolet = Color(0xFF1A0533);
  static const gold = Color(0xFFE8A020);
  static const amethyst = Color(0xFF9B59B6);
  static const bg = Color(0xFFF5F3F9);
  static const muted = Color(0xFF8A94A6);
  static const border = Color(0xFFDDE3EF);
  static const green = Color(0xFF1DA462);
  static const red = Color(0xFFD64545);
}

InputDecoration fieldDec(String label, IconData icon, {String? helper}) => InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 2,
      labelStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      filled: true,
      fillColor: AppColors.bg,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.deepViolet, width: 1.8)),
    );

ThemeData buildTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.deepViolet),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: AppColors.bg,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepViolet,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.deepViolet,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
