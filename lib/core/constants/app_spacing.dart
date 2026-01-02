import 'package:flutter/material.dart';

/// Espacements et dimensions Jardingue
/// Suivant les principes Apple Human Interface Guidelines
abstract final class AppSpacing {
  // ============================================
  // SPACING (Padding & Margin)
  // ============================================

  /// 4px - Micro espacement
  static const double xs = 4.0;

  /// 8px - Petit espacement
  static const double sm = 8.0;

  /// 12px - Espacement compact
  static const double md = 12.0;

  /// 16px - Espacement standard
  static const double lg = 16.0;

  /// 20px - Espacement confortable
  static const double xl = 20.0;

  /// 24px - Grand espacement
  static const double xxl = 24.0;

  /// 32px - Très grand espacement
  static const double xxxl = 32.0;

  /// 48px - Espacement section
  static const double section = 48.0;

  // ============================================
  // BORDER RADIUS
  // ============================================

  /// 8px - Radius petit
  static const double radiusSm = 8.0;

  /// 12px - Radius moyen
  static const double radiusMd = 12.0;

  /// 16px - Radius standard (Apple-like)
  static const double radiusLg = 16.0;

  /// 20px - Radius grand
  static const double radiusXl = 20.0;

  /// 24px - Radius très grand (cartes principales)
  static const double radiusXxl = 24.0;

  /// 9999px - Radius pill/full
  static const double radiusFull = 9999.0;

  // ============================================
  // BORDER RADIUS PRESETS
  // ============================================

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius borderRadiusXxl = BorderRadius.all(
    Radius.circular(radiusXxl),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // ============================================
  // SIZING
  // ============================================

  /// Hauteur bouton standard
  static const double buttonHeight = 52.0;

  /// Hauteur bouton compact
  static const double buttonHeightSm = 44.0;

  /// Hauteur champ de saisie
  static const double inputHeight = 52.0;

  /// Taille icône petite
  static const double iconSm = 20.0;

  /// Taille icône standard
  static const double iconMd = 24.0;

  /// Taille icône grande
  static const double iconLg = 28.0;

  /// Taille icône très grande
  static const double iconXl = 32.0;

  /// Taille avatar petit
  static const double avatarSm = 32.0;

  /// Taille avatar moyen
  static const double avatarMd = 44.0;

  /// Taille avatar grand
  static const double avatarLg = 56.0;

  // ============================================
  // CARD SIZES
  // ============================================

  /// Hauteur carte compacte
  static const double cardHeightSm = 80.0;

  /// Hauteur carte standard
  static const double cardHeightMd = 120.0;

  /// Hauteur carte grande
  static const double cardHeightLg = 160.0;

  // ============================================
  // GRID (pour le plan du potager)
  // ============================================

  /// Taille cellule grille petite
  static const double gridCellSm = 48.0;

  /// Taille cellule grille standard
  static const double gridCellMd = 64.0;

  /// Taille cellule grille grande
  static const double gridCellLg = 80.0;

  // ============================================
  // SAFE AREA & SYSTEM
  // ============================================

  /// Padding horizontal écran
  static const double screenPaddingH = 20.0;

  /// Padding vertical écran
  static const double screenPaddingV = 16.0;

  /// EdgeInsets écran standard
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );

  /// EdgeInsets horizontal uniquement
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
  );
}

/// Durées d'animation
abstract final class AppDurations {
  /// 150ms - Animation rapide
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms - Animation standard
  static const Duration normal = Duration(milliseconds: 250);

  /// 350ms - Animation confortable
  static const Duration slow = Duration(milliseconds: 350);

  /// 500ms - Animation lente
  static const Duration slower = Duration(milliseconds: 500);
}

/// Courbes d'animation
abstract final class AppCurves {
  /// Courbe standard Apple
  static const Curve standard = Curves.easeInOut;

  /// Courbe entrée
  static const Curve enter = Curves.easeOut;

  /// Courbe sortie
  static const Curve exit = Curves.easeIn;

  /// Courbe rebond subtil
  static const Curve bounce = Curves.elasticOut;

  /// Courbe iOS spring-like
  static const Curve spring = Curves.easeOutCubic;
}
