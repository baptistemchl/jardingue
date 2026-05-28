import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/orchard_providers.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

/// Carte du verger qui affiche soit un arbre unique (mode "simple"), soit
/// un groupe d'arbres identiques (espèce + variété + type de plantation).
///
/// Le rendu s'adapte au cardinal :
/// - 1 arbre : pastille santé classique, infos de l'arbre (date, lieu...)
/// - N arbres : badge `×N` sur l'emoji, ligne santé mixte
///
/// `onTap` reçoit le groupe complet ; l'écran appelant décide d'ouvrir la
/// sheet d'arbre individuel ou la sheet de groupe selon `group.isSingle`.
class FruitTreeGroupCard extends StatelessWidget {
  final FruitTreeGroup group;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FruitTreeGroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final representative = group.representative;
    final healthColor = _healthColor(group.worstHealth);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji + badge ×N (ou pastille santé si arbre seul)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      group.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                if (group.isGroup)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: _CountBadge(count: group.count),
                  )
                else
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: healthColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.isGroup
                        ? representative.fruitTree.commonName
                        : representative.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _subtitle(loc),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (group.isGroup)
                    _HealthSummary(group: group)
                  else
                    _SingleInfoRow(tree: representative),
                ],
              ),
            ),

            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              color: AppColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Sous-titre : "Reinette · Pleine terre" en groupe, ou nom de l'espèce
  /// en simple.
  String _subtitle(AppLocalizations loc) {
    if (group.isSingle) {
      return group.representative.fruitTree.commonName;
    }
    final variety = group.variety;
    final pt = PlantingType.fromDbValue(group.plantingTypeDb) ??
        PlantingType.ground;
    if (variety != null && variety.trim().isNotEmpty) {
      return loc.orchardGroupVarietyAndType(variety.trim(), pt.label);
    }
    return pt.label;
  }

  static Color _healthColor(String status) {
    return switch (status) {
      'good' => AppColors.success,
      'warning' => AppColors.warning,
      'poor' => AppColors.error,
      _ => AppColors.success,
    };
  }
}

/// Pastille ×N en haut-droite de l'emoji. Reste sobre (pastille pleine
/// `primary`, texte blanc) pour ne pas écraser la carte mais rester
/// identifiable d'un coup d'œil.
class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          loc.orchardGroupCardCount(count),
          style: AppTypography.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Ligne santé mixte pour les groupes. Trois cas :
/// - tous sains : "6 arbres en bon état"
/// - mélange sain/à surveiller : "5 en forme · 1 à surveiller"
/// - au moins un en alerte : "4 en forme · 2 en alerte"
class _HealthSummary extends StatelessWidget {
  final FruitTreeGroup group;

  const _HealthSummary({required this.group});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final healthy = group.healthyCount;
    final warning = group.warningCount;
    final alert = group.poorCount;

    final (text, dotColor) = switch ((healthy, warning, alert)) {
      (final h, 0, 0) => (
          loc.orchardGroupHealthAllGood(h),
          AppColors.success,
        ),
      (final h, _, final a) when a > 0 => (
          loc.orchardGroupHealthAlert(h, a),
          AppColors.error,
        ),
      (final h, final w, _) => (
          loc.orchardGroupHealthMixed(h, w),
          AppColors.warning,
        ),
    };

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bandeau d'infos d'un arbre seul (date + lieu) repris du visuel existant.
class _SingleInfoRow extends StatelessWidget {
  final UserFruitTreeWithDetails tree;

  const _SingleInfoRow({required this.tree});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (tree.plantingDate != null)
          _InfoChip(
            icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular),
            label: _formatAge(tree.plantingDate!),
          ),
        if (tree.plantingDate != null && tree.location != null)
          const SizedBox(width: 8),
        if (tree.location != null)
          Expanded(
            child: _InfoChip(
              icon: PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
              label: tree.location!,
            ),
          ),
      ],
    );
  }

  static String _formatAge(DateTime plantingDate) {
    final now = DateTime.now();
    final difference = now.difference(plantingDate);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;
    if (years > 0) {
      return '$years an${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months mois';
    } else {
      return '${difference.inDays}j';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
