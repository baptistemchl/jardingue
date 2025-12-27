import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Typographie Jardingue
/// Utilise Inter (proche de SF Pro) pour un look Apple-like
abstract final class AppTypography {
  // ============================================
  // BASE FONT
  // ============================================

  static String get _fontFamily => GoogleFonts.inter().fontFamily!;

  // ============================================
  // DISPLAY - Titres très grands
  // ============================================

  /// Display Large - 32px Bold
  static TextStyle get displayLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  /// Display Medium - 28px Bold
  static TextStyle get displayMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  /// Display Small - 24px SemiBold
  static TextStyle get displaySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  // ============================================
  // HEADLINE - Titres de section
  // ============================================

  /// Headline Large - 22px SemiBold
  static TextStyle get headlineLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  /// Headline Medium - 20px SemiBold
  static TextStyle get headlineMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
        color: AppColors.textPrimary,
      );

  /// Headline Small - 18px SemiBold
  static TextStyle get headlineSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  // ============================================
  // TITLE - Sous-titres
  // ============================================

  /// Title Large - 17px SemiBold
  static TextStyle get titleLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// Title Medium - 16px Medium
  static TextStyle get titleMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// Title Small - 15px Medium
  static TextStyle get titleSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: AppColors.textPrimary,
      );

  // ============================================
  // BODY - Texte courant
  // ============================================

  /// Body Large - 16px Regular
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  /// Body Medium - 15px Regular
  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  /// Body Small - 14px Regular
  static TextStyle get bodySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  // ============================================
  // LABEL - Labels et boutons
  // ============================================

  /// Label Large - 15px Medium
  static TextStyle get labelLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// Label Medium - 14px Medium
  static TextStyle get labelMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// Label Small - 13px Medium
  static TextStyle get labelSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  // ============================================
  // CAPTION - Petits textes
  // ============================================

  /// Caption - 12px Regular
  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  /// Caption Strong - 12px Medium
  static TextStyle get captionStrong => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  // ============================================
  // HELPERS
  // ============================================

  /// Applique une couleur à un style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Version secondaire d'un style
  static TextStyle secondary(TextStyle style) {
    return style.copyWith(color: AppColors.textSecondary);
  }

  /// Version tertiaire d'un style
  static TextStyle tertiary(TextStyle style) {
    return style.copyWith(color: AppColors.textTertiary);
  }
}
