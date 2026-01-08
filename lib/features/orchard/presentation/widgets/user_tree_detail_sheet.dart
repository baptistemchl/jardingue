import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/orchard_providers.dart';

/// Sheet affichant les détails d'un arbre du verger personnel
class UserTreeDetailSheet extends ConsumerWidget {
  final UserFruitTreeWithDetails tree;

  const UserTreeDetailSheet({super.key, required this.tree});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fruitTree = tree.fruitTree;
    final userTree = tree.userTree;
    final healthColor = _getHealthColor(userTree.healthStatus);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                // Header
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: healthColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              fruitTree.emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: healthColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tree.name, style: AppTypography.titleLarge),
                          Text(
                            fruitTree.commonName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (userTree.variety != null)
                            Text(
                              userTree.variety!,
                              style: AppTypography.caption.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // État de santé
                GestureDetector(
                  onTap: () => _showHealthDialog(context, ref),
                  child: _HealthStatusCard(status: userTree.healthStatus),
                ),

                const SizedBox(height: 16),

                // Infos plantation
                _InfoCard(
                  title: 'Informations',
                  icon: PhosphorIcons.info(PhosphorIconsStyle.fill),
                  children: [
                    if (userTree.plantingDate != null) ...[
                      _InfoRow(
                        label: 'Planté le',
                        value: DateFormat(
                          'dd MMMM yyyy',
                          'fr_FR',
                        ).format(userTree.plantingDate!),
                      ),
                      _InfoRow(
                        label: 'Âge',
                        value: _calculateAge(userTree.plantingDate!),
                      ),
                    ],
                    if (userTree.location != null)
                      _InfoRow(label: 'Emplacement', value: userTree.location!),
                    _InfoRow(
                      label: 'Espèce',
                      value: fruitTree.latinName ?? fruitTree.commonName,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Suivi
                _InfoCard(
                  title: 'Suivi',
                  icon: PhosphorIcons.chartLine(PhosphorIconsStyle.fill),
                  children: [
                    _InfoRow(
                      label: 'Dernière taille',
                      value: userTree.lastPruningDate != null
                          ? DateFormat(
                              'dd/MM/yyyy',
                            ).format(userTree.lastPruningDate!)
                          : 'Non renseignée',
                    ),
                    _InfoRow(
                      label: 'Dernière récolte',
                      value: userTree.lastHarvestDate != null
                          ? DateFormat(
                              'dd/MM/yyyy',
                            ).format(userTree.lastHarvestDate!)
                          : 'Non renseignée',
                    ),
                    if (userTree.lastYieldKg != null)
                      _InfoRow(
                        label: 'Dernier rendement',
                        value: '${userTree.lastYieldKg} kg',
                      ),
                  ],
                ),

                // Notes
                if (userTree.notes != null && userTree.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Notes',
                    icon: PhosphorIcons.notepad(PhosphorIconsStyle.fill),
                    children: [
                      Text(
                        userTree.notes!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Actions rapides
                Text(
                  'Actions',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: PhosphorIcons.scissors(PhosphorIconsStyle.bold),
                        label: 'Taille',
                        color: AppColors.primary,
                        onTap: () => _recordPruning(context, ref),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: PhosphorIcons.basket(PhosphorIconsStyle.bold),
                        label: 'Récolte',
                        color: AppColors.secondary,
                        onTap: () => _recordHarvest(context, ref),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.bold),
                        label: 'Santé',
                        color: AppColors.warning,
                        onTap: () => _showHealthDialog(context, ref),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Conseil saisonnier
                _SeasonalAdviceCard(),

                const SizedBox(height: 20),

                // Supprimer
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular)),
                  label: const Text('Retirer du verger'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(String status) {
    switch (status) {
      case 'good':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'poor':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }

  String _calculateAge(DateTime plantingDate) {
    final now = DateTime.now();
    final difference = now.difference(plantingDate);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;

    if (years > 0) {
      return '$years an${years > 1 ? 's' : ''}${months > 0 ? ' et $months mois' : ''}';
    } else if (months > 0) {
      return '$months mois';
    } else {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous retirer "${tree.name}" de votre verger ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(userFruitTreesNotifierProvider.notifier)
          .deleteTree(tree.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tree.name} retiré du verger'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _recordPruning(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enregistrer une taille'),
        content: const Text('Confirmer la taille d\'aujourd\'hui ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(userFruitTreesNotifierProvider.notifier)
          .updateTree(id: tree.id, lastPruningDate: DateTime.now());
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Taille enregistrée ✂️'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _recordHarvest(BuildContext context, WidgetRef ref) async {
    double? fruitYield;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enregistrer une récolte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Combien avez-vous récolté ?'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quantité (kg)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              onChanged: (value) {
                fruitYield = double.tryParse(value.replaceAll(',', '.'));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(userFruitTreesNotifierProvider.notifier)
          .updateTree(
            id: tree.id,
            lastHarvestDate: DateTime.now(),
            lastYieldKg: fruitYield,
          );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Récolte enregistrée 🧺${fruitYield != null ? ' ($fruitYield kg)' : ''}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showHealthDialog(BuildContext context, WidgetRef ref) async {
    final status = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('État de santé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HealthOption(
              emoji: '💚',
              label: 'Bon état',
              value: 'good',
              currentValue: tree.userTree.healthStatus,
            ),
            const SizedBox(height: 8),
            _HealthOption(
              emoji: '💛',
              label: 'À surveiller',
              value: 'warning',
              currentValue: tree.userTree.healthStatus,
            ),
            const SizedBox(height: 8),
            _HealthOption(
              emoji: '❤️',
              label: 'Problème',
              value: 'poor',
              currentValue: tree.userTree.healthStatus,
            ),
          ],
        ),
      ),
    );

    if (status != null && status != tree.userTree.healthStatus) {
      await ref
          .read(userFruitTreesNotifierProvider.notifier)
          .updateTree(id: tree.id, healthStatus: status);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('État de santé mis à jour'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}

class _HealthStatusCard extends StatelessWidget {
  final String status;

  const _HealthStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final (emoji, label, color) = switch (status) {
      'good' => ('💚', 'Bon état', AppColors.success),
      'warning' => ('💛', 'À surveiller', AppColors.warning),
      'poor' => ('❤️', 'Problème détecté', AppColors.error),
      _ => ('💚', 'Bon état', AppColors.success),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'État de santé',
                  style: AppTypography.caption.copyWith(color: color),
                ),
                Text(
                  label,
                  style: AppTypography.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _HealthOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String currentValue;

  const _HealthOption({
    required this.emoji,
    required this.label,
    required this.value,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;

    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                PhosphorIcons.check(PhosphorIconsStyle.bold),
                color: AppColors.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonalAdviceCard extends StatelessWidget {
  const _SeasonalAdviceCard();

  @override
  Widget build(BuildContext context) {
    final month = DateTime.now().month;
    final (emoji, advice) = _getSeasonalAdvice(month);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conseil du mois',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  advice,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _getSeasonalAdvice(int month) {
    return switch (month) {
      1 || 2 => ('✂️', 'Période idéale pour la taille (hors gel).'),
      3 => ('🌱', 'Préparez le sol. Dernière chance pour tailler.'),
      4 || 5 => ('🌸', 'Floraison ! Surveillez les gelées tardives.'),
      6 || 7 => ('🍃', 'Éclaircissez les fruits. Arrosez par temps sec.'),
      8 || 9 => ('🧺', 'Période de récolte pour beaucoup de fruitiers.'),
      10 => ('🍂', 'Ramassez feuilles et fruits tombés.'),
      11 || 12 => ('🌳', 'Période de plantation idéale.'),
      _ => ('🌳', 'Observez votre arbre.'),
    };
  }
}
