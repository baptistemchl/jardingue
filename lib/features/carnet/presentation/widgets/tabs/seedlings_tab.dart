import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/providers/database_providers.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/seedling_status.dart';
import '../../providers/seedling_providers.dart';
import '../sheets/_shared_sheet_fields.dart';
import '../sheets/add_seedling_sheet.dart';
import '../_empty_tab_placeholder.dart';

class SeedlingsTab extends ConsumerWidget {
  const SeedlingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final grouped = ref.watch(seedlingsByStatusProvider);
    final plantsAsync = ref.watch(seedlingPlantsLookupProvider);
    final plants = plantsAsync.value ?? const <int, Plant>{};

    final germinating = grouped[SeedlingStatus.germinating] ?? const [];
    final ready = grouped[SeedlingStatus.ready] ?? const [];
    final transplanted = grouped[SeedlingStatus.transplanted] ?? const [];
    final failed = grouped[SeedlingStatus.failed] ?? const [];

    final hasAny = germinating.isNotEmpty ||
        ready.isNotEmpty ||
        transplanted.isNotEmpty ||
        failed.isNotEmpty;

    return Stack(
      children: [
        if (!hasAny)
          EmptyTabPlaceholder(
            icon: PhosphorIcons.plant(PhosphorIconsStyle.duotone),
            title: loc.carnetSeedlingsEmptyTitle,
            subtitle: loc.carnetSeedlingsEmptySubtitle,
          )
        else
          ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (germinating.isNotEmpty) ...[
                _StatusSection(
                  status: SeedlingStatus.germinating,
                  seedlings: germinating,
                  plants: plants,
                ),
                const SizedBox(height: 16),
              ],
              if (ready.isNotEmpty) ...[
                _StatusSection(
                  status: SeedlingStatus.ready,
                  seedlings: ready,
                  plants: plants,
                ),
                const SizedBox(height: 16),
              ],
              if (transplanted.isNotEmpty || failed.isNotEmpty) ...[
                _ArchiveSection(
                  transplanted: transplanted,
                  failed: failed,
                  plants: plants,
                ),
              ],
            ],
          ),
        Positioned(
          bottom: 8,
          right: 0,
          child: _AddButton(
            label: loc.carnetSeedlingsAddButton,
            onTap: () => AddSeedlingSheet.show(context),
          ),
        ),
      ],
    );
  }
}

class _StatusSection extends StatelessWidget {
  final SeedlingStatus status;
  final List<Seedling> seedlings;
  final Map<int, Plant> plants;

  const _StatusSection({
    required this.status,
    required this.seedlings,
    required this.plants,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final spec = _statusSpec(status, loc);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(spec.icon, size: 16, color: spec.color),
              ),
              const SizedBox(width: 10),
              Text(
                spec.label,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${seedlings.length}',
                  style: AppTypography.caption.copyWith(
                    color: spec.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...seedlings.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SeedlingCard(
                seedling: s,
                plant: plants[s.plantId],
                statusColor: spec.color,
              ),
            )),
      ],
    );
  }
}

class _ArchiveSection extends StatefulWidget {
  final List<Seedling> transplanted;
  final List<Seedling> failed;
  final Map<int, Plant> plants;

  const _ArchiveSection({
    required this.transplanted,
    required this.failed,
    required this.plants,
  });

  @override
  State<_ArchiveSection> createState() => _ArchiveSectionState();
}

class _ArchiveSectionState extends State<_ArchiveSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final total = widget.transplanted.length + widget.failed.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _expanded ? 0.25 : 0,
                  child: Icon(
                    PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  loc.carnetSeedlingsArchiveTitle,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$total',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          ...widget.transplanted.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SeedlingCard(
                  seedling: s,
                  plant: widget.plants[s.plantId],
                  statusColor: AppColors.success,
                  archived: true,
                ),
              )),
          ...widget.failed.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SeedlingCard(
                  seedling: s,
                  plant: widget.plants[s.plantId],
                  statusColor: AppColors.error,
                  archived: true,
                ),
              )),
        ],
      ],
    );
  }
}

class _SeedlingCard extends ConsumerWidget {
  final Seedling seedling;
  final Plant? plant;
  final Color statusColor;
  final bool archived;

  const _SeedlingCard({
    required this.seedling,
    required this.plant,
    required this.statusColor,
    this.archived = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    // Préservation historique : si le plant catalogue est supprimé,
    // on retombe sur le snapshot du nom saisi à la création.
    final displayName = plant?.commonName ??
        seedling.plantNameSnapshot ??
        loc.carnetSeedlingsUnknownPlant;
    final emoji = plant != null
        ? PlantEmojiMapper.fromName(
            plant!.commonName,
            categoryCode: plant!.categoryCode,
          )
        : (seedling.plantNameSnapshot != null
            ? PlantEmojiMapper.fromName(seedling.plantNameSnapshot!)
            : '🌱');
    final status = SeedlingStatus.fromCode(seedling.status);
    final nextStatus = status.next;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.carnetSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.carnetLine),
      ),
      child: Opacity(
        opacity: archived ? 0.65 : 1.0,
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge « plante supprimée » si on n'a que le
                      // snapshot disponible côté DB.
                      if (plant == null &&
                          seedling.plantNameSnapshot != null) ...[
                        const SizedBox(width: 6),
                        _DeletedPlantBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(context, seedling),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Bouton arrosage rapide — disponible tant que le semi
            // n'est pas archivé (transplanted/failed). Tap = enregistre
            // un event watering_seedling + snackbar de feedback.
            if (!archived)
              _WaterButton(
                onTap: () => _quickWater(context, ref),
              ),
            if (!archived && nextStatus != null)
              _AdvanceButton(
                color: statusColor,
                nextLabel: _statusSpec(nextStatus, loc).label,
                onTap: () => _advanceWithDialog(
                  context,
                  ref,
                  next: nextStatus,
                ),
              )
            else if (!archived)
              _FailButton(onTap: () async {
                final db = ref.read(databaseProvider);
                await db.updateSeedlingStatus(
                  seedling.id,
                  SeedlingStatus.failed.code,
                );
              }),
          ],
        ),
      ),
    );
  }

  String _subtitle(BuildContext context, Seedling s) {
    final loc = AppLocalizations.of(context)!;
    final parts = <String>[];
    parts.add(loc.carnetSeedlingsSowedOn(formatCarnetDate(s.sowedAt)));
    // Stock disponible en priorité, puis ratio si pas encore initialisé.
    if (s.remainingStock != null && s.successCount != null) {
      parts.add(loc.carnetSeedlingsInStock(
        s.remainingStock!,
        s.successCount!,
      ));
    } else if (s.successCount != null && s.count != null) {
      parts.add(loc.carnetSeedlingsSuccessRatio(
        s.successCount!,
        s.count!,
      ));
    } else if (s.count != null) {
      parts.add(loc.carnetSeedlingsCountInline(s.count!));
    }
    // Cumul échecs si renseigné.
    if (s.failedCount != null && s.failedCount! > 0) {
      parts.add(loc.carnetSeedlingsFailedInline(s.failedCount!));
    }
    return parts.join(' • ');
  }


  /// Enregistre un event watering_seedling pour ce semi. Pas de
  /// dialog — un tap = un arrosage. Le snackbar confirme.
  Future<void> _quickWater(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);
    await db.insertWateringEventForSeedling(
      plantId: seedling.plantId,
      gardenId: seedling.gardenId,
      seedlingStatus: seedling.status,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.seedlingWateredSnack),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Dialog de transition de statut. Demande deux nombres ENSEMBLE :
  /// combien ont réussi à cette étape, combien ont échoué. Plus de
  /// bouton « − » séparé : la déclaration d'échec se fait au moment
  /// naturel d'une transition.
  ///
  /// Pour ready → transplanted : on saute le dialog de comptage et
  /// on ouvre directement le _TransplantDialog (qui contient aussi
  /// son propre champ échec, voir plus bas).
  Future<void> _advanceWithDialog(
    BuildContext context,
    WidgetRef ref, {
    required SeedlingStatus next,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);

    // Transition vers transplanted → on délègue au _TransplantDialog
    // qui gère stock + potager + échec d'un coup.
    if (next == SeedlingStatus.transplanted) {
      await _openTransplantDialog(context, ref);
      return;
    }

    final baseCount = seedling.successCount ?? seedling.count;
    int? newSuccess;
    int? newFailed = seedling.failedCount;

    if (baseCount != null && baseCount > 0) {
      final result = await showDialog<_AdvanceResult>(
        context: context,
        builder: (ctx) => _AdvanceDialog(
          base: baseCount,
          nextStatusLabel: _statusSpec(next, loc).label,
        ),
      );
      if (result == null) return;
      newSuccess = result.success;
      newFailed = (seedling.failedCount ?? 0) + result.failed;
    }

    // Autres transitions (germinating → ready) : on initialise aussi
    // le stock disponible à successCount, point de départ avant le
    // premier repiquage partiel.
    await db.updateSeedlingStatus(
      seedling.id,
      next.code,
      successCount: newSuccess,
      remainingStock: newSuccess,
      failedCount: newFailed,
    );
  }

  /// Dialog de repiquage partiel : combien planter, combien d'échecs
  /// depuis la dernière étape, dans quel potager. Plante les N
  /// GardenPlants à des cellules libres. Si reste > 0 après repiquage,
  /// le semi reste en statut ready avec remainingStock mis à jour.
  Future<void> _openTransplantDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);

    // Stock disponible : prefer remainingStock (déjà initialisé) sinon
    // fallback sur successCount ou count initial.
    final available = seedling.remainingStock ??
        seedling.successCount ??
        seedling.count ??
        1;

    // Charger la liste des potagers pour le picker.
    final gardens = await db.select(db.gardens).get();
    if (gardens.isEmpty) {
      // Pas de potager créé → on ne peut pas placer. On informe et on
      // passe quand même en transplanted pour fermer le cycle.
      await db.updateSeedlingStatus(
        seedling.id,
        SeedlingStatus.transplanted.code,
        remainingStock: 0,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.seedlingTransplantNoGardenSnack),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final result = await showDialog<_TransplantResult>(
      context: context,
      builder: (ctx) => _TransplantDialog(
        availableStock: available,
        gardens: gardens,
        defaultGardenId: seedling.gardenId ?? gardens.first.id,
      ),
    );
    if (result == null) return;

    // Place N GardenPlants dans le potager choisi. Chaque plante
    // cherche sa propre cellule libre pour éviter les overlaps.
    for (var i = 0; i < result.toPlant; i++) {
      final cell = await db.findFirstFreeCell(result.gardenId);
      await db.addPlantToGarden(
        GardenPlantsCompanion.insert(
          gardenId: result.gardenId,
          plantId: seedling.plantId,
          gridX: cell.x,
          gridY: cell.y,
          plantedAt: Value(DateTime.now()),
          notes: Value('Issu d\'un semi · $available en stock'),
        ),
      );
    }

    // Event planting pour le calendrier (1 seul, avec le nombre dans
    // les notes).
    await db.insertPlantingEventForSeedling(
      plantId: seedling.plantId,
      gardenId: result.gardenId,
      plantedAt: DateTime.now(),
      notes: '${result.toPlant} plant(s) repiqué(s)',
    );

    // Mise à jour du semi : stock restant (= disponible − plantés −
    // échoués). Statut "ready" tant que stock > 0, sinon →
    // transplanted (tout repiqué) ou failed (tout perdu).
    final newRemaining =
        (available - result.toPlant - result.failed).clamp(0, available);
    final newFailed = (seedling.failedCount ?? 0) + result.failed;
    final newStatus = newRemaining > 0
        ? SeedlingStatus.ready.code
        : result.toPlant > 0
            ? SeedlingStatus.transplanted.code
            : SeedlingStatus.failed.code;
    await db.updateSeedlingStatus(
      seedling.id,
      newStatus,
      remainingStock: newRemaining,
      failedCount: newFailed,
      gardenId: result.gardenId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newRemaining > 0
              ? loc.seedlingTransplantPartialSnack(
                  result.toPlant,
                  newRemaining,
                )
              : loc.seedlingTransplantedPlacedSnack),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TransplantResult {
  final int toPlant;
  final int failed;
  final int gardenId;
  const _TransplantResult({
    required this.toPlant,
    required this.failed,
    required this.gardenId,
  });
}

class _AdvanceResult {
  final int success;
  final int failed;
  const _AdvanceResult({required this.success, required this.failed});
}

/// Dialog de transition (germination → ready, etc.) qui demande
/// ENSEMBLE le nombre de réussites et d'échecs à cette étape. Le
/// total ne peut excéder le stock initial. Le reste éventuel
/// (base - success - failed) reste « en attente » conceptuellement
/// — mais comme on n'avance plus le statut sans repiquage, c'est OK.
class _AdvanceDialog extends StatefulWidget {
  final int base;
  final String nextStatusLabel;
  const _AdvanceDialog({required this.base, required this.nextStatusLabel});

  @override
  State<_AdvanceDialog> createState() => _AdvanceDialogState();
}

class _AdvanceDialogState extends State<_AdvanceDialog> {
  late int _success;
  int _failed = 0;

  @override
  void initState() {
    super.initState();
    _success = widget.base;
  }

  int get _max => widget.base;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final remaining = _max - _success - _failed;
    return AlertDialog(
      title: Text(loc.seedlingAdvanceDialogTitleV2),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.seedlingAdvanceDialogPromptV2(widget.base),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _CounterRow(
            label: loc.seedlingAdvanceFieldSuccess,
            icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
            color: AppColors.success,
            value: _success,
            onChange: (v) {
              final clamped = v.clamp(0, _max - _failed);
              setState(() => _success = clamped);
            },
            max: _max,
          ),
          const SizedBox(height: 10),
          _CounterRow(
            label: loc.seedlingAdvanceFieldFailed,
            icon: PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
            color: AppColors.error,
            value: _failed,
            onChange: (v) {
              final clamped = v.clamp(0, _max - _success);
              setState(() => _failed = clamped);
            },
            max: _max,
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 10),
            Text(
              loc.seedlingAdvanceRemainingHint(remaining),
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _AdvanceResult(success: _success, failed: _failed),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: Text(loc.seedlingAdvanceDialogConfirm),
        ),
      ],
    );
  }
}

/// Dialog de repiquage : combien planter, combien d'échecs depuis la
/// dernière transition, dans quel potager.
class _TransplantDialog extends StatefulWidget {
  final int availableStock;
  final List<Garden> gardens;
  final int defaultGardenId;

  const _TransplantDialog({
    required this.availableStock,
    required this.gardens,
    required this.defaultGardenId,
  });

  @override
  State<_TransplantDialog> createState() => _TransplantDialogState();
}

class _TransplantDialogState extends State<_TransplantDialog> {
  late int _toPlant;
  int _failed = 0;
  late int _gardenId;

  @override
  void initState() {
    super.initState();
    _toPlant = widget.availableStock;
    _gardenId = widget.defaultGardenId;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final maxPlant = widget.availableStock - _failed;
    return AlertDialog(
      title: Text(loc.seedlingTransplantDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.seedlingTransplantDialogStockHint(widget.availableStock),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _CounterRow(
              label: loc.seedlingTransplantDialogCountLabel,
              icon: PhosphorIcons.shovel(PhosphorIconsStyle.fill),
              color: AppColors.primary,
              value: _toPlant,
              onChange: (v) {
                final clamped = v.clamp(0, maxPlant);
                setState(() => _toPlant = clamped);
              },
              max: maxPlant,
            ),
            const SizedBox(height: 10),
            _CounterRow(
              label: loc.seedlingTransplantFieldFailed,
              icon: PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
              color: AppColors.error,
              value: _failed,
              onChange: (v) {
                final clamped =
                    v.clamp(0, widget.availableStock - _toPlant);
                setState(() => _failed = clamped);
              },
              max: widget.availableStock,
            ),
            const SizedBox(height: 16),
            Text(
              loc.seedlingTransplantDialogGardenLabel,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            for (final g in widget.gardens)
              InkWell(
                onTap: () => setState(() => _gardenId = g.id),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _gardenId == g.id
                            ? PhosphorIcons.radioButton(
                                PhosphorIconsStyle.fill,
                              )
                            : PhosphorIcons.circle(
                                PhosphorIconsStyle.regular,
                              ),
                        size: 18,
                        color: _gardenId == g.id
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(g.name)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.commonCancel),
        ),
        FilledButton(
          onPressed: _toPlant + _failed > 0
              ? () => Navigator.pop(
                    context,
                    _TransplantResult(
                      toPlant: _toPlant,
                      failed: _failed,
                      gardenId: _gardenId,
                    ),
                  )
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: Text(loc.seedlingTransplantDialogConfirm),
        ),
      ],
    );
  }
}

/// Compteur ± réutilisé par les deux dialogs (avance + repiquage)
/// pour saisir une quantité bornée. Icône colorée à gauche, label,
/// valeur centrale, boutons − et +.
class _CounterRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int value;
  final int max;
  final ValueChanged<int> onChange;

  const _CounterRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.max,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value > 0 ? () => onChange(value - 1) : null,
          icon: Icon(PhosphorIcons.minus(PhosphorIconsStyle.bold), size: 16),
        ),
        SizedBox(
          width: 32,
          child: Center(
            child: Text(
              '$value',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value < max ? () => onChange(value + 1) : null,
          icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 16),
        ),
      ],
    );
  }
}

/// Mini badge affiché à côté d'un nom de plante quand la Plant FK
/// n'est plus dans le catalogue mais que le snapshot du nom est connu.
class _DeletedPlantBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        loc.carnetPlantDeletedBadge,
        style: AppTypography.caption.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _AdvanceButton extends StatelessWidget {
  final Color color;
  final String nextLabel;
  final VoidCallback onTap;
  const _AdvanceButton({
    required this.color,
    required this.nextLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                nextLabel,
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton 💧 compact à côté du bouton d'avancement. Tap = log un
/// arrosage. Visuellement bleu info pour le démarquer du flow de
/// statut (vert) et du fail (gris).
class _WaterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WaterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              PhosphorIcons.dropHalf(PhosphorIconsStyle.fill),
              size: 14,
              color: AppColors.info,
            ),
          ),
        ),
      ),
    );
  }
}

class _FailButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FailButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        PhosphorIcons.xCircle(PhosphorIconsStyle.regular),
        size: 18,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _StatusSpec {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusSpec(this.label, this.icon, this.color);
}

_StatusSpec _statusSpec(SeedlingStatus s, AppLocalizations loc) {
  return switch (s) {
    SeedlingStatus.germinating => _StatusSpec(
        loc.carnetSeedlingsStatusGerminating,
        PhosphorIcons.dropHalf(PhosphorIconsStyle.fill),
        AppColors.info,
      ),
    SeedlingStatus.ready => _StatusSpec(
        loc.carnetSeedlingsStatusReady,
        PhosphorIcons.plant(PhosphorIconsStyle.fill),
        AppColors.primary,
      ),
    SeedlingStatus.transplanted => _StatusSpec(
        loc.carnetSeedlingsStatusTransplanted,
        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        AppColors.success,
      ),
    SeedlingStatus.failed => _StatusSpec(
        loc.carnetSeedlingsStatusFailed,
        PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
        AppColors.error,
      ),
  };
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
