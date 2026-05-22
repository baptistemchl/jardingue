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
    // Si on a un successCount, on affiche « 5 / 12 godets » ; sinon
    // juste le count semé initial.
    if (s.successCount != null && s.count != null) {
      parts.add(loc.carnetSeedlingsSuccessRatio(
        s.successCount!,
        s.count!,
      ));
    } else if (s.count != null) {
      parts.add(loc.carnetSeedlingsCountInline(s.count!));
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

  /// Dialog de transition de statut : si l'utilisateur a renseigné un
  /// nombre de godets semés, on lui demande combien ont « réussi » à
  /// cette étape. Si la cible est « transplanted », on crée aussi un
  /// event planting dans GardenEvents pour lier à la planification.
  Future<void> _advanceWithDialog(
    BuildContext context,
    WidgetRef ref, {
    required SeedlingStatus next,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);
    final baseCount = seedling.successCount ?? seedling.count;
    int? newSuccess;

    if (baseCount != null && baseCount > 0) {
      final controller = TextEditingController(
        text: baseCount.toString(),
      );
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.seedlingAdvanceDialogTitle(
            _statusSpec(next, loc).label,
          )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.seedlingAdvanceDialogPrompt(baseCount),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  suffixText: 'godets',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(loc.seedlingAdvanceDialogConfirm),
            ),
          ],
        ),
      );
      if (ok != true) return;
      newSuccess = int.tryParse(controller.text.trim()) ?? baseCount;
    }

    await db.updateSeedlingStatus(
      seedling.id,
      next.code,
      successCount: newSuccess,
    );

    // Repiqué = planté : on matérialise vraiment la plantation dans le
    // potager si un gardenId est défini sur le semis. Sinon on
    // n'enregistre que l'event planting (visible dans calendrier mais
    // pas dans la grille du potager).
    if (next == SeedlingStatus.transplanted) {
      final gardenId = seedling.gardenId;
      int? createdGardenPlantId;
      if (gardenId != null) {
        final cell = await db.findFirstFreeCell(gardenId);
        createdGardenPlantId = await db.addPlantToGarden(
          GardenPlantsCompanion.insert(
            gardenId: gardenId,
            plantId: seedling.plantId,
            gridX: cell.x,
            gridY: cell.y,
            plantedAt: Value(DateTime.now()),
            notes: Value(newSuccess != null && seedling.count != null
                ? '$newSuccess / ${seedling.count} godets repiqués'
                : null),
          ),
        );
      }
      await db.insertPlantingEventForSeedling(
        plantId: seedling.plantId,
        gardenId: gardenId,
        plantedAt: DateTime.now(),
        notes: newSuccess != null && seedling.count != null
            ? '$newSuccess / ${seedling.count} godets repiqués'
            : null,
      );
      // Notification visuelle si on a placé dans le potager.
      if (createdGardenPlantId != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.seedlingTransplantedPlacedSnack),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
