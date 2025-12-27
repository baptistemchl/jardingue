import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// Décorations Glassmorphism pour Jardingue
/// Effet verre dépoli moderne et élégant
abstract final class GlassDecoration {
  // ============================================
  // GLASS CONTAINERS
  // ============================================

  /// Décoration glass standard
  static BoxDecoration get standard => BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// Décoration glass plus opaque
  static BoxDecoration get strong => BoxDecoration(
        color: AppColors.glassFillStrong,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      );

  /// Décoration glass subtile (pour éléments secondaires)
  static BoxDecoration get subtle => BoxDecoration(
        color: AppColors.glassFill.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.2),
          width: 0.5,
        ),
      );

  /// Décoration glass pour cartes
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  /// Décoration glass pour nav bar
  static BoxDecoration get navBar => BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      );

  /// Décoration glass pour app bar
  static BoxDecoration get appBar => BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // ============================================
  // CUSTOM RADIUS VARIANTS
  // ============================================

  /// Glass avec radius personnalisé
  static BoxDecoration withRadius(double radius) => BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// Glass pill (boutons, tags)
  static BoxDecoration get pill => BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
      );

  // ============================================
  // COLORED VARIANTS
  // ============================================

  /// Glass avec teinte de couleur
  static BoxDecoration tinted(Color color, {double opacity = 0.1}) =>
      BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      );

  /// Glass primaire (vert)
  static BoxDecoration get primary => tinted(AppColors.primary);

  /// Glass succès
  static BoxDecoration get success => tinted(AppColors.success);

  /// Glass warning
  static BoxDecoration get warning => tinted(AppColors.warning);

  /// Glass error
  static BoxDecoration get error => tinted(AppColors.error);
}

/// Widget helper pour appliquer le blur glassmorphism
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BoxDecoration? decoration;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    super.key,
    required this.child,
    this.decoration,
    this.blur = 10,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: (decoration?.borderRadius as BorderRadius?) ??
            AppSpacing.borderRadiusXl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: decoration ?? GlassDecoration.standard,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Widget pour carte glassmorphism simple
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    final container = GlassContainer(
      decoration: GlassDecoration.card,
      blur: blur,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      margin: margin,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}
