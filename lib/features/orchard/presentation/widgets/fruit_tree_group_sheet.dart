import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/orchard_providers.dart';
import '../../../../core/services/crash_reporting/crash_reporting_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'user_tree_detail_sheet.dart';

/// Bottom sheet d'un groupe d'arbres identiques (même espèce/variété/type).
///
/// Fournit :
/// - un récapitulatif (récolte cumulée, dernière taille du groupe)
/// - des actions groupées rapides (tailler tous, récolter, noter un
///   traitement)
/// - la liste des arbres avec un mode sélection multiple pour appliquer
///   ces mêmes actions à un sous-ensemble du groupe
class FruitTreeGroupSheet extends ConsumerStatefulWidget {
  final FruitTreeGroup group;

  /// Si true, le mode sélection est activé dès l'ouverture (utilisé pour
  /// le long-press depuis la carte de groupe).
  final bool startInSelection;

  const FruitTreeGroupSheet({
    super.key,
    required this.group,
    this.startInSelection = false,
  });

  static Future<void> show(
    BuildContext context, {
    required FruitTreeGroup group,
    bool startInSelection = false,
  }) {
    return AppBottomSheet.show(
      context: context,
      heightFraction: 0.88,
      child: FruitTreeGroupSheet(
        group: group,
        startInSelection: startInSelection,
      ),
    );
  }

  @override
  ConsumerState<FruitTreeGroupSheet> createState() =>
      _FruitTreeGroupSheetState();
}

class _FruitTreeGroupSheetState extends ConsumerState<FruitTreeGroupSheet> {
  late Set<int> _selected;
  late bool _selectionMode;

  @override
  void initState() {
    super.initState();
    _selected = <int>{};
    _selectionMode = widget.startInSelection;
  }

  /// Récupère la version fraîche du groupe depuis le provider (les actions
  /// batch refresh la liste source — il faut suivre l'évolution).
  FruitTreeGroup? _currentGroup() {
    final groupsAsync = ref.watch(groupedUserFruitTreesProvider);
    return groupsAsync.maybeWhen(
      data: (groups) {
        try {
          return groups.firstWhere((g) => g.key == widget.group.key);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );
  }

  void _toggleSelection(int treeId) {
    setState(() {
      if (_selected.contains(treeId)) {
        _selected.remove(treeId);
      } else {
        _selected.add(treeId);
      }
    });
  }

  void _enterSelectionMode(int initialTreeId) {
    setState(() {
      _selectionMode = true;
      _selected = {initialTreeId};
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selected = {};
    });
  }

  void _openTreeDetail(UserFruitTreeWithDetails tree) {
    final navigator = Navigator.of(context, rootNavigator: true);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserTreeDetailSheet(tree: tree),
    ).then((_) {
      // Le navigator est conservé pour évite warning analyzer.
      if (mounted) setState(() {});
    });
    // navigator var purposely held: évite analyser unused mais documente
    // l'intention (la sheet enfant peut pop la stack).
    navigator.canPop();
  }

  @override
  Widget build(BuildContext context) {
    final group = _currentGroup() ?? widget.group;
    final loc = AppLocalizations.of(context)!;

    // Si toutes les fiches du groupe ont disparu (suppression depuis le
    // détail individuel), on ferme la sheet pour éviter un état orphelin.
    if (group.trees.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    final pt =
        PlantingType.fromDbValue(group.plantingTypeDb) ?? PlantingType.ground;
    final ids = group.trees.map((t) => t.id).toList();
    final selectionIds = _selected.toList();
    final hasSelection = _selectionMode && selectionIds.isNotEmpty;

    return Column(
      children: [
        const AppBottomSheetHandle(),
        _Header(
          group: group,
          plantingType: pt,
          selectionMode: _selectionMode,
          selectionCount: selectionIds.length,
          onClose: () => Navigator.of(context).pop(),
          onCancelSelection: _exitSelectionMode,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _StatsCard(group: group),
              const SizedBox(height: 20),

              // Actions sur tout le groupe (cachées en mode sélection — la
              // barre du bas prend le relais avec le même éventail)
              if (!_selectionMode) ...[
                Text(
                  loc.orchardGroupActionsTitle,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _BatchActionChips(
                  targetIds: ids,
                  group: group,
                ),
                const SizedBox(height: 24),
                if (group.count > 1) ...[
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _selectionMode = true),
                    icon: Icon(
                      PhosphorIcons.checkSquare(PhosphorIconsStyle.regular),
                      size: 18,
                    ),
                    label: Text(loc.orchardSelectionEnter),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],

              // Liste des arbres
              Text(
                loc.orchardGroupTreesTitle(group.count),
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...group.trees.map((tree) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TreeRow(
                      tree: tree,
                      selectionMode: _selectionMode,
                      selected: _selected.contains(tree.id),
                      onTap: () {
                        if (_selectionMode) {
                          _toggleSelection(tree.id);
                        } else {
                          _openTreeDetail(tree);
                        }
                      },
                      onLongPress: () {
                        if (!_selectionMode) {
                          _enterSelectionMode(tree.id);
                        }
                      },
                    ),
                  )),
            ],
          ),
        ),

        // Barre d'action en mode sélection
        if (_selectionMode)
          _SelectionActionBar(
            count: selectionIds.length,
            enabled: hasSelection,
            targetIds: selectionIds,
            onCancel: _exitSelectionMode,
          ),
      ],
    );
  }
}

// ============================================
// HEADER
// ============================================

class _Header extends StatelessWidget {
  final FruitTreeGroup group;
  final PlantingType plantingType;
  final bool selectionMode;
  final int selectionCount;
  final VoidCallback onClose;
  final VoidCallback onCancelSelection;

  const _Header({
    required this.group,
    required this.plantingType,
    required this.selectionMode,
    required this.selectionCount,
    required this.onClose,
    required this.onCancelSelection,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final variety = group.variety?.trim();
    final subtitle = (variety != null && variety.isNotEmpty)
        ? loc.orchardGroupVarietyAndType(variety, plantingType.label)
        : plantingType.label;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child:
                  Text(group.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectionMode
                      ? loc.orchardSelectionCount(selectionCount)
                      : loc.orchardGroupSheetTitle(
                          group.speciesName, group.count),
                  style: AppTypography.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: selectionMode ? onCancelSelection : onClose,
            icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
            tooltip:
                selectionMode ? loc.orchardSelectionCancel : loc.cancel,
          ),
        ],
      ),
    );
  }
}

// ============================================
// STATS
// ============================================

class _StatsCard extends StatelessWidget {
  final FruitTreeGroup group;

  const _StatsCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final totalYield = group.totalLastYieldKg;
    final oldestPruning = group.oldestPruningDate;

    final harvestValue = totalYield == null
        ? loc.orchardGroupStatsHarvestNone
        : loc.orchardGroupStatsHarvestValue(_formatKg(totalYield));
    final pruningValue = oldestPruning == null
        ? loc.orchardGroupStatsPruningNone
        : loc.orchardGroupStatsPruningValue(
            DateFormat('MMMM yyyy', 'fr_FR').format(oldestPruning),
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              emoji: '🧺',
              title: loc.orchardGroupStatsHarvestTitle,
              value: harvestValue,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.primary.withValues(alpha: 0.15),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _StatItem(
              emoji: '✂️',
              title: loc.orchardGroupStatsPruningTitle,
              value: pruningValue,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatKg(double kg) {
    if (kg == kg.roundToDouble()) return kg.toStringAsFixed(0);
    return kg.toStringAsFixed(1);
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;

  const _StatItem({
    required this.emoji,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ============================================
// ACTION CHIPS (top, applied to all the group)
// ============================================

class _BatchActionChips extends ConsumerWidget {
  final List<int> targetIds;
  final FruitTreeGroup group;

  const _BatchActionChips({
    required this.targetIds,
    required this.group,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: PhosphorIcons.scissors(PhosphorIconsStyle.bold),
            label: loc.orchardGroupActionPruneAll,
            color: AppColors.primary,
            onTap: () => BatchActions.runPrune(
              context: context,
              ref: ref,
              ids: targetIds,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionChip(
            icon: PhosphorIcons.basket(PhosphorIconsStyle.bold),
            label: loc.orchardGroupActionHarvest,
            color: AppColors.secondary,
            onTap: () => BatchActions.runHarvest(
              context: context,
              ref: ref,
              ids: targetIds,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionChip(
            icon: PhosphorIcons.dropHalf(PhosphorIconsStyle.bold),
            label: loc.orchardGroupActionTreat,
            color: AppColors.warning,
            onTap: () => BatchActions.runTreatment(
              context: context,
              ref: ref,
              ids: targetIds,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TREE ROW (in the list)
// ============================================

class _TreeRow extends StatelessWidget {
  final UserFruitTreeWithDetails tree;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TreeRow({
    required this.tree,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final healthColor = switch (tree.healthStatus) {
      'good' => AppColors.success,
      'warning' => AppColors.warning,
      'poor' => AppColors.error,
      _ => AppColors.success,
    };

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (selectionMode) ...[
              Icon(
                selected
                    ? PhosphorIcons.checkSquare(PhosphorIconsStyle.fill)
                    : PhosphorIcons.square(PhosphorIconsStyle.regular),
                color: selected
                    ? AppColors.primary
                    : AppColors.textTertiary,
                size: 22,
              ),
              const SizedBox(width: 12),
            ] else ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: healthColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tree.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tree.plantingDate != null)
                    Text(
                      'Planté le ${DateFormat('dd/MM/yyyy').format(tree.plantingDate!)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (!selectionMode)
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: 14,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// SELECTION BOTTOM BAR
// ============================================

class _SelectionActionBar extends ConsumerWidget {
  final int count;
  final bool enabled;
  final List<int> targetIds;
  final VoidCallback onCancel;

  const _SelectionActionBar({
    required this.count,
    required this.enabled,
    required this.targetIds,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loc.orchardSelectionCount(count),
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SelectionAction(
                  icon: PhosphorIcons.scissors(PhosphorIconsStyle.bold),
                  label: loc.orchardGroupActionPruneAll,
                  color: AppColors.primary,
                  enabled: enabled,
                  onTap: () => BatchActions.runPrune(
                    context: context,
                    ref: ref,
                    ids: targetIds,
                    onDone: onCancel,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelectionAction(
                  icon: PhosphorIcons.basket(PhosphorIconsStyle.bold),
                  label: loc.orchardGroupActionHarvest,
                  color: AppColors.secondary,
                  enabled: enabled,
                  onTap: () => BatchActions.runHarvest(
                    context: context,
                    ref: ref,
                    ids: targetIds,
                    onDone: onCancel,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelectionAction(
                  icon: PhosphorIcons.dropHalf(PhosphorIconsStyle.bold),
                  label: loc.orchardGroupActionTreat,
                  color: AppColors.warning,
                  enabled: enabled,
                  onTap: () => BatchActions.runTreatment(
                    context: context,
                    ref: ref,
                    ids: targetIds,
                    onDone: onCancel,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// BATCH ACTIONS (shared by top chips + selection bar)
// ============================================

/// Helpers d'application en masse des actions (taille, récolte, traitement)
/// pour un sous-ensemble d'arbres. Centralisé ici pour éviter la
/// duplication entre les chips du haut et la barre de sélection.
abstract class BatchActions {
  static Future<void> runPrune({
    required BuildContext context,
    required WidgetRef ref,
    required List<int> ids,
    VoidCallback? onDone,
  }) async {
    if (ids.isEmpty) return;
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(userFruitTreesNotifierProvider.notifier);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.orchardBatchPruneTitle(ids.length)),
        content: Text(loc.orchardBatchPruneMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await notifier.applyBatch(
        ids: ids,
        lastPruningDate: DateTime.now(),
      );
      messenger.showSnackBar(SnackBar(
        content: Text(loc.orchardBatchPruneDone(ids.length)),
        backgroundColor: AppColors.success,
      ));
      onDone?.call();
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'BatchActions.runPrune',
          extra: {'count': ids.length});
      messenger.showSnackBar(SnackBar(
        content: Text(loc.errorWithMessage(e.toString())),
        backgroundColor: AppColors.error,
      ));
    }
  }

  static Future<void> runHarvest({
    required BuildContext context,
    required WidgetRef ref,
    required List<int> ids,
    VoidCallback? onDone,
  }) async {
    if (ids.isEmpty) return;
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(userFruitTreesNotifierProvider.notifier);

    double? totalKg;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          title: Text(loc.orchardBatchHarvestTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.orchardBatchHarvestMessage(ids.length)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                  labelText: loc.orchardBatchHarvestTotalLabel,
                  border: const OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                onChanged: (v) {
                  setSt(() {
                    totalKg = double.tryParse(v.replaceAll(',', '.'));
                  });
                },
              ),
              if (totalKg != null && totalKg! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    loc.orchardBatchHarvestPerTreeHint(
                      _formatKg(totalKg! / ids.length),
                    ),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.save),
            ),
          ],
        );
      }),
    );
    if (confirmed != true) return;

    final perTreeKg = (totalKg != null && totalKg! > 0)
        ? totalKg! / ids.length
        : null;
    try {
      await notifier.applyBatch(
        ids: ids,
        lastHarvestDate: DateTime.now(),
        lastYieldKg: perTreeKg,
      );
      messenger.showSnackBar(SnackBar(
        content: Text(loc.orchardBatchHarvestDone(ids.length)),
        backgroundColor: AppColors.success,
      ));
      onDone?.call();
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'BatchActions.runHarvest',
          extra: {'count': ids.length});
      messenger.showSnackBar(SnackBar(
        content: Text(loc.errorWithMessage(e.toString())),
        backgroundColor: AppColors.error,
      ));
    }
  }

  static Future<void> runTreatment({
    required BuildContext context,
    required WidgetRef ref,
    required List<int> ids,
    VoidCallback? onDone,
  }) async {
    if (ids.isEmpty) return;
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(userFruitTreesNotifierProvider.notifier);

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.orchardBatchTreatTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.orchardBatchTreatMessage(ids.length)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: loc.orchardBatchTreatHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(loc.save),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;

    // Préfixe avec la date pour faciliter la relecture dans les notes
    // ("12/05/2026 — Bouillie bordelaise").
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final notesLine = '$dateStr — $result';

    try {
      await notifier.applyBatch(ids: ids, notesAppend: notesLine);
      messenger.showSnackBar(SnackBar(
        content: Text(loc.orchardBatchTreatDone(ids.length)),
        backgroundColor: AppColors.success,
      ));
      onDone?.call();
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'BatchActions.runTreatment',
          extra: {'count': ids.length});
      messenger.showSnackBar(SnackBar(
        content: Text(loc.errorWithMessage(e.toString())),
        backgroundColor: AppColors.error,
      ));
    }
  }

  static String _formatKg(double kg) {
    if (kg == kg.roundToDouble()) return kg.toStringAsFixed(0);
    return kg.toStringAsFixed(1);
  }
}
