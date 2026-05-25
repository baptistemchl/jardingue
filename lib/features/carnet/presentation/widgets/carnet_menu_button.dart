import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/carnet_ui_providers.dart';

/// Bouton « menu burger » à insérer dans le header de chaque écran
/// du shell pour ouvrir le Carnet de bord.
///
/// Style cohérent avec les autres icônes de header (36×36, fond clair,
/// bordure subtile) — interchangeable visuellement avec le bouton
/// Paramètres ou À propos.
class CarnetMenuButton extends ConsumerWidget {
  const CarnetMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.carnetOpenA11y,
      child: GestureDetector(
        onTap: () => ref.read(carnetUiProvider.notifier).open(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            PhosphorIcons.list(PhosphorIconsStyle.regular),
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
