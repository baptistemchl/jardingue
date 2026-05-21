import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/carnet_ui_providers.dart';

/// Petit bouton « marque-page » épinglé au bord droit de l'écran,
/// servant de point d'entrée toujours visible vers le Carnet de bord.
///
/// Forme : demi-pilule sortant du bord droit avec un icône notebook.
class CarnetHandle extends ConsumerWidget {
  const CarnetHandle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(carnetUiProvider);
    final topPad = MediaQuery.of(context).padding.top;
    // Masque le handle quand le drawer est déjà ouvert (évite le doublon).
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      right: ui.isOpen ? -56 : 0,
      top: topPad + 14,
      child: Semantics(
        button: true,
        label: AppLocalizations.of(context)!.carnetOpenA11y,
        child: GestureDetector(
          onTap: () => ref.read(carnetUiProvider.notifier).open(),
          child: Container(
            width: 38,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.kraftTab,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(-3, 3),
                ),
              ],
            ),
            child: Icon(
              PhosphorIcons.notebook(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
