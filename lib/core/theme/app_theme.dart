import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Backgrounds
  static const bgPrimary   = Color(0xFF0A0E1A);
  static const bgSecondary = Color(0xFF111827);
  static const bgElevated  = Color(0xFF1E293B);
  static const bgCard      = Color(0xFF162032);

  // Accents
  static const accentBlue  = Color(0xFF3B82F6);
  static const accentIndigo = Color(0xFF6366F1);

  // Crisis severity
  static const crisisRed    = Color(0xFFEF4444);
  static const crisisAmber  = Color(0xFFF59E0B);
  static const crisisYellow = Color(0xFFEAB308);
  static const crisisGreen  = Color(0xFF22C55E);
  static const crisisTeal   = Color(0xFF14B8A6);

  // Text
  static const textPrimary   = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted     = Color(0xFF475569);

  // Glass / overlays
  static const glass      = Color(0x0DFFFFFF);
  static const glassBorder = Color(0x1AFFFFFF);
  static const overlay    = Color(0xCC0A0E1A);

  // Severity map
  static Color forSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return crisisRed;
      case 'high':     return crisisAmber;
      case 'medium':   return crisisYellow;
      case 'low':      return crisisTeal;
      default:         return crisisGreen;
    }
  }

  // Status map
  static Color forStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':      return crisisRed;
      case 'in_progress': return crisisAmber;
      case 'resolved':    return crisisGreen;
      case 'reported':    return accentBlue;
      default:            return textSecondary;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typography
// ─────────────────────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
    letterSpacing: 1.0,
  );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 13, color: AppColors.textSecondary,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.accentBlue,
        secondary: AppColors.accentIndigo,
        surface:   AppColors.bgSecondary,
        error:     AppColors.crisisRed,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor:       AppColors.textPrimary,
        displayColor:    AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.bgSecondary,
        selectedIconTheme: IconThemeData(color: AppColors.accentBlue, size: 22),
        unselectedIconTheme: IconThemeData(color: AppColors.textMuted, size: 22),
        selectedLabelTextStyle: TextStyle(color: AppColors.accentBlue, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
        indicatorColor: Color(0x203B82F6),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spacing & Radius constants
// ─────────────────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  AppRadius._();
  static const sm  = BorderRadius.all(Radius.circular(8));
  static const md  = BorderRadius.all(Radius.circular(12));
  static const lg  = BorderRadius.all(Radius.circular(16));
  static const xl  = BorderRadius.all(Radius.circular(24));
  static const full = BorderRadius.all(Radius.circular(999));
}
