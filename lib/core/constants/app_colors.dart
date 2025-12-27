import 'package:flutter/material.dart';

/// Palette de couleurs Jardingue
/// Inspirée nature avec une touche Apple-like
abstract final class AppColors {
  // ============================================
  // BACKGROUNDS
  // ============================================

  /// Fond principal de l'app - gris-vert très clair
  static const Color background = Color(0xFFF5F7F2);

  /// Surface des cartes et éléments
  static const Color surface = Color(0xFFFFFFFF);

  /// Fond secondaire pour contraste subtil
  static const Color surfaceVariant = Color(0xFFF0F4EC);

  // ============================================
  // GLASSMORPHISM
  // ============================================

  /// Remplissage des éléments glass
  static const Color glassFill = Color(0x40FFFFFF);

  /// Remplissage glass plus opaque
  static const Color glassFillStrong = Color(0x80FFFFFF);

  /// Bordure des éléments glass
  static const Color glassBorder = Color(0x30FFFFFF);

  /// Ombre pour glass effect
  static const Color glassShadow = Color(0x15000000);

  // ============================================
  // COULEURS PRIMAIRES - NATURE
  // ============================================

  /// Vert sauge - couleur principale
  static const Color primary = Color(0xFF4A7C59);

  /// Vert sauge clair
  static const Color primaryLight = Color(0xFF6B9B7A);

  /// Vert sauge foncé
  static const Color primaryDark = Color(0xFF2D5A3D);

  /// Container primary avec opacité
  static const Color primaryContainer = Color(0xFFE8F5E9);

  // ============================================
  // COULEURS SECONDAIRES
  // ============================================

  /// Jaune soleil - accent chaleureux
  static const Color secondary = Color(0xFFE9C46A);

  /// Jaune soleil clair
  static const Color secondaryLight = Color(0xFFF4D98C);

  /// Orange terre
  static const Color tertiary = Color(0xFFE07A5F);

  // ============================================
  // COULEURS SÉMANTIQUES
  // ============================================

  /// Succès - vert récolte
  static const Color success = Color(0xFF6A994E);

  /// Attention - orange doux
  static const Color warning = Color(0xFFF4A261);

  /// Erreur - terracotta
  static const Color error = Color(0xFFBC4749);

  /// Info - bleu ciel
  static const Color info = Color(0xFF5B9BD5);

  // ============================================
  // TEXTES
  // ============================================

  /// Texte principal
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Texte secondaire
  static const Color textSecondary = Color(0xFF6B7280);

  /// Texte tertiaire / désactivé
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Texte sur fond coloré
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================
  // BORDURES & DIVIDERS
  // ============================================

  /// Bordure subtile
  static const Color border = Color(0xFFE5E7EB);

  /// Bordure plus visible
  static const Color borderStrong = Color(0xFFD1D5DB);

  /// Divider
  static const Color divider = Color(0xFFF3F4F6);

  // ============================================
  // CATÉGORIES DE PLANTES
  // ============================================

  /// Légumes feuilles
  static const Color categoryLeafy = Color(0xFF6B9B7A);

  /// Légumes fruits
  static const Color categoryFruit = Color(0xFFE07A5F);

  /// Légumes racines
  static const Color categoryRoot = Color(0xFFC9A66B);

  /// Aromates
  static const Color categoryHerb = Color(0xFF9DC88D);

  /// Fleurs
  static const Color categoryFlower = Color(0xFFE9A8C9);

  // ============================================
  // EXPOSITION SOLEIL
  // ============================================

  /// Plein soleil
  static const Color sunFull = Color(0xFFF4A261);

  /// Mi-ombre
  static const Color sunPartial = Color(0xFFE9C46A);

  /// Ombre
  static const Color sunShade = Color(0xFF8DB38B);

  // ============================================
  // GRADIENTS
  // ============================================

  /// Gradient principal
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  /// Gradient nature
  static const LinearGradient natureGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F5E9), Color(0xFFF5F7F2)],
  );

  /// Gradient sunset (pour météo)
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4A261), Color(0xFFE07A5F)],
  );
}
