import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/orchard_providers.dart';

/// Sheet affichant les détails d'un arbre du verger personnel
/// avec édition inline de tous les champs.
class UserTreeDetailSheet extends ConsumerStatefulWidget {
  final UserFruitTreeWithDetails tree;

  const UserTreeDetailSheet({super.key, required this.tree});

  @override
  ConsumerState<UserTreeDetailSheet> createState() =>
      _UserTreeDetailSheetState();
}

class _UserTreeDetailSheetState extends ConsumerState<UserTreeDetailSheet> {
  late UserFruitTreeWithDetails _tree;

  @override
  void initState() {
    super.initState();
    _tree = widget.tree;
  }

  /// Met à jour l'arbre et rafraichit l'UI
  Future<void> _update({
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
  }) async {
    await ref.read(userFruitTreesNotifierProvider.notifier).updateTree(
          id: _tree.id,
          nickname: nickname,
          variety: variety,
          plantingDate: plantingDate,
          location: location,
          notes: notes,
          healthStatus: healthStatus,
          lastPruningDate: lastPruningDate,
          lastHarvestDate: lastHarvestDate,
          lastYieldKg: lastYieldKg,
        );
    // Recharger les données
    final updated =
        await ref.read(userFruitTreeByIdProvider(_tree.id).future);
    if (updated != null && mounted) {
      setState(() => _tree = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fruitTree = _tree.fruitTree;
    final userTree = _tree.userTree;
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
              padding: EdgeInsets.fromLTRB(
                20, 0, 20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
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
                              border:
                                  Border.all(color: Colors.white, width: 2),
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
                          // Nom editable
                          GestureDetector(
                            onTap: () => _editText(
                              title: 'Nom',
                              currentValue: userTree.nickname,
                              hint: fruitTree.commonName,
                              onSave: (v) => _update(nickname: v),
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(_tree.name,
                                      style: AppTypography.titleLarge),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  PhosphorIcons.pencilSimple(
                                      PhosphorIconsStyle.regular),
                                  size: 16,
                                  color: AppColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            fruitTree.commonName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          // Variete editable
                          GestureDetector(
                            onTap: () => _editText(
                              title: 'Variete',
                              currentValue: userTree.variety,
                              hint: 'Ex: Golden, Granny Smith...',
                              onSave: (v) => _update(variety: v),
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    userTree.variety ?? 'Ajouter une variete',
                                    style: AppTypography.caption.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: userTree.variety != null
                                          ? AppColors.textTertiary
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  PhosphorIcons.pencilSimple(
                                      PhosphorIconsStyle.regular),
                                  size: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ],
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
                  onTap: () => _showHealthDialog(),
                  child: _HealthStatusCard(status: userTree.healthStatus),
                ),

                const SizedBox(height: 16),

                // Infos plantation
                _InfoCard(
                  title: 'Informations',
                  icon: PhosphorIcons.info(PhosphorIconsStyle.fill),
                  children: [
                    _EditableInfoRow(
                      label: 'Plante le',
                      value: userTree.plantingDate != null
                          ? DateFormat('dd MMMM yyyy', 'fr_FR')
                              .format(userTree.plantingDate!)
                          : 'Non renseignee',
                      onTap: () => _editDate(
                        title: 'Date de plantation',
                        currentValue: userTree.plantingDate,
                        onSave: (d) => _update(plantingDate: d),
                      ),
                    ),
                    if (userTree.plantingDate != null)
                      _InfoRow(
                        label: 'Age',
                        value: _calculateAge(userTree.plantingDate!),
                      ),
                    _EditableInfoRow(
                      label: 'Emplacement',
                      value: userTree.location ?? 'Non renseigne',
                      onTap: () => _editText(
                        title: 'Emplacement',
                        currentValue: userTree.location,
                        hint: 'Ex: Fond du jardin, cote sud...',
                        onSave: (v) => _update(location: v),
                      ),
                    ),
                    _InfoRow(
                      label: 'Espece',
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
                    _EditableInfoRow(
                      label: 'Derniere taille',
                      value: userTree.lastPruningDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(userTree.lastPruningDate!)
                          : 'Non renseignee',
                      onTap: () => _editDate(
                        title: 'Derniere taille',
                        currentValue: userTree.lastPruningDate,
                        onSave: (d) => _update(lastPruningDate: d),
                      ),
                    ),
                    _EditableInfoRow(
                      label: 'Derniere recolte',
                      value: userTree.lastHarvestDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(userTree.lastHarvestDate!)
                          : 'Non renseignee',
                      onTap: () => _editDate(
                        title: 'Derniere recolte',
                        currentValue: userTree.lastHarvestDate,
                        onSave: (d) => _update(lastHarvestDate: d),
                      ),
                    ),
                    _EditableInfoRow(
                      label: 'Dernier rendement',
                      value: userTree.lastYieldKg != null
                          ? '${userTree.lastYieldKg} kg'
                          : 'Non renseigne',
                      onTap: () => _editNumber(
                        title: 'Dernier rendement (kg)',
                        currentValue: userTree.lastYieldKg,
                        onSave: (v) => _update(lastYieldKg: v),
                      ),
                    ),
                  ],
                ),

                // Notes
                const SizedBox(height: 12),
                _NotesCard(
                  notes: userTree.notes,
                  onTap: () => _editMultilineText(
                    title: 'Notes',
                    currentValue: userTree.notes,
                    hint: 'Observations, traitements, remarques...',
                    onSave: (v) => _update(notes: v),
                  ),
                ),

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
                        onTap: () => _recordPruning(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: PhosphorIcons.basket(PhosphorIconsStyle.bold),
                        label: 'Recolte',
                        color: AppColors.secondary,
                        onTap: () => _recordHarvest(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.bold),
                        label: 'Sante',
                        color: AppColors.warning,
                        onTap: () => _showHealthDialog(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Conseil saisonnier
                const _SeasonalAdviceCard(),

                const SizedBox(height: 20),

                // Supprimer
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(),
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

  // ============================================
  // DIALOGUES D'EDITION
  // ============================================

  /// Attend que le dialog soit completement ferme avant de continuer
  Future<void> _waitForDialogDismiss() =>
      WidgetsBinding.instance.endOfFrame;

  Future<void> _editText({
    required String title,
    required String? currentValue,
    required String hint,
    required Future<void> Function(String) onSave,
  }) async {
    String? result;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: currentValue);
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                result = controller.text;
                Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    if (result != null && result!.isNotEmpty) {
      await _waitForDialogDismiss();
      if (mounted) await onSave(result!);
    }
  }

  Future<void> _editMultilineText({
    required String title,
    required String? currentValue,
    required String hint,
    required Future<void> Function(String) onSave,
  }) async {
    String? result;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: currentValue);
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                result = controller.text;
                Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await _waitForDialogDismiss();
      if (mounted) await onSave(result!);
    }
  }

  Future<void> _editDate({
    required String title,
    required DateTime? currentValue,
    required Future<void> Function(DateTime) onSave,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: title,
    );
    if (picked != null) {
      await _waitForDialogDismiss();
      if (mounted) await onSave(picked);
    }
  }

  Future<void> _editNumber({
    required String title,
    required double? currentValue,
    required Future<void> Function(double) onSave,
  }) async {
    double? result;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(
          text: currentValue?.toString() ?? '',
        );
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              suffixText: 'kg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                result = double.tryParse(
                    controller.text.replaceAll(',', '.'));
                Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await _waitForDialogDismiss();
      if (mounted) await onSave(result!);
    }
  }

  // ============================================
  // ACTIONS
  // ============================================

  Color _getHealthColor(String status) {
    return switch (status) {
      'good' => AppColors.success,
      'warning' => AppColors.warning,
      'poor' => AppColors.error,
      _ => AppColors.success,
    };
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content:
            Text('Voulez-vous retirer "${_tree.name}" de votre verger ?'),
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

    if (confirmed == true && mounted) {
      await ref
          .read(userFruitTreesNotifierProvider.notifier)
          .deleteTree(_tree.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_tree.name} retire du verger'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _recordPruning() async {
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
      await _update(lastPruningDate: DateTime.now());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Taille enregistree'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _recordHarvest() async {
    double? fruitYield;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enregistrer une recolte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Combien avez-vous recolte ?'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quantite (kg)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              onChanged: (value) {
                fruitYield =
                    double.tryParse(value.replaceAll(',', '.'));
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
      await _update(
        lastHarvestDate: DateTime.now(),
        lastYieldKg: fruitYield,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recolte enregistree${fruitYield != null ? ' ($fruitYield kg)' : ''}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showHealthDialog() async {
    final status = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Etat de sante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HealthOption(
              emoji: '💚',
              label: 'Bon etat',
              value: 'good',
              currentValue: _tree.userTree.healthStatus,
            ),
            const SizedBox(height: 8),
            _HealthOption(
              emoji: '💛',
              label: 'A surveiller',
              value: 'warning',
              currentValue: _tree.userTree.healthStatus,
            ),
            const SizedBox(height: 8),
            _HealthOption(
              emoji: '❤️',
              label: 'Probleme',
              value: 'poor',
              currentValue: _tree.userTree.healthStatus,
            ),
          ],
        ),
      ),
    );

    if (status != null && status != _tree.userTree.healthStatus) {
      await _update(healthStatus: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Etat de sante mis a jour'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}

// ============================================
// WIDGETS
// ============================================

class _HealthStatusCard extends StatelessWidget {
  final String status;

  const _HealthStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final (emoji, label, color) = switch (status) {
      'good' => ('💚', 'Bon etat', AppColors.success),
      'warning' => ('💛', 'A surveiller', AppColors.warning),
      'poor' => ('❤️', 'Probleme detecte', AppColors.error),
      _ => ('💚', 'Bon etat', AppColors.success),
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
                  'Etat de sante',
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

/// InfoRow avec un bouton d'edition
class _EditableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _EditableInfoRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
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
            const SizedBox(width: 6),
            Icon(
              PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de notes editable
class _NotesCard extends StatelessWidget {
  final String? notes;
  final VoidCallback onTap;

  const _NotesCard({required this.notes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasNotes = notes != null && notes!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Icon(PhosphorIcons.notepad(PhosphorIconsStyle.fill),
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hasNotes ? notes! : 'Ajouter des notes...',
              style: AppTypography.bodySmall.copyWith(
                color: hasNotes
                    ? AppColors.textSecondary
                    : AppColors.primary,
                fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ],
        ),
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
      1 || 2 => ('✂️', 'Periode ideale pour la taille (hors gel).'),
      3 => ('🌱', 'Preparez le sol. Derniere chance pour tailler.'),
      4 || 5 => ('🌸', 'Floraison ! Surveillez les gelees tardives.'),
      6 || 7 => ('🍃', 'Eclaircissez les fruits. Arrosez par temps sec.'),
      8 || 9 => ('🧺', 'Periode de recolte pour beaucoup de fruitiers.'),
      10 => ('🍂', 'Ramassez feuilles et fruits tombes.'),
      11 || 12 => ('🌳', 'Periode de plantation ideale.'),
      _ => ('🌳', 'Observez votre arbre.'),
    };
  }
}
