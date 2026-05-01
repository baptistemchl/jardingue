import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Bottom sheet partage Jardingue.
///
/// Encapsule la decoration (bord arrondi haut + couleur surface) et la
/// SafeArea bottom afin que le contenu ne soit jamais tronque par la barre
/// de navigation Android 3 boutons.
///
/// Usage typique avec [showModalBottomSheet] :
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   useRootNavigator: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => AppBottomSheet(
///     heightFraction: 0.82,
///     child: Column(
///       children: [
///         const AppBottomSheetHandle(),
///         // ... contenu
///       ],
///     ),
///   ),
/// );
/// ```
///
/// Ou via le helper :
/// ```dart
/// AppBottomSheet.show(
///   context: context,
///   heightFraction: 0.82,
///   child: Column(...),
/// );
/// ```
///
/// **Important :** ne pas ajouter de `MediaQuery.padding.bottom` dans le
/// padding du contenu — la SafeArea s'en charge deja. Sinon double padding.
class AppBottomSheet extends StatelessWidget {
  /// Contenu du sheet. Doit inclure son propre [AppBottomSheetHandle] en
  /// haut si la handle est desiree.
  final Widget child;

  /// Hauteur cible en proportion de l'ecran (ex: 0.82).
  /// Null = sheet en wrap-content.
  final double? heightFraction;

  /// Couleur de fond. Defaut : [AppColors.surface].
  final Color? backgroundColor;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.heightFraction,
    this.backgroundColor,
  });

  /// Helper qui appelle [showModalBottomSheet] avec la configuration standard.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? heightFraction,
    Color? backgroundColor,
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppBottomSheet(
        heightFraction: heightFraction,
        backgroundColor: backgroundColor,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = heightFraction != null
        ? MediaQuery.of(context).size.height * heightFraction!
        : null;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: child,
      ),
    );
  }
}

/// Handle visuel standardise (barre 40x4) en haut d'un [AppBottomSheet].
class AppBottomSheetHandle extends StatelessWidget {
  const AppBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
