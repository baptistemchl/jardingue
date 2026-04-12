import 'package:flutter/material.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../../../core/providers/database_providers.dart';
import '../../../../../core/providers/garden_event_providers.dart';
import '../../../../../core/providers/garden_providers.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../domain/models/garden_event.dart';
import '../../../domain/models/watering_helpers.dart';
import 'dimension_input.dart';

/// Sheet detaillee pour une plante dans l'editeur
/// de potager, avec edition des dimensions.
class EditorPlantDetailSheet
    extends ConsumerStatefulWidget {
  final GardenPlantWithDetails element;
  final Garden garden;
  final double maxWidthM;
  final double maxHeightM;
  final Function(double w, double h) onUpdate;
  final VoidCallback onDelete;

  const EditorPlantDetailSheet({
    super.key,
    required this.element,
    required this.garden,
    required this.maxWidthM,
    required this.maxHeightM,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  ConsumerState<EditorPlantDetailSheet> createState() =>
      _State();
}

class _State extends ConsumerState<EditorPlantDetailSheet> {
  late double _width;
  late double _height;
  bool _showSizeEditor = false;

  @override
  void initState() {
    super.initState();
    final cs = widget.garden.cellSizeCm;
    _width = widget.element.widthMeters(cs);
    _height = widget.element.heightMeters(cs);
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.element.plant!;
    final companionsAsync =
        ref.watch(plantCompanionsProvider(plant.id));
    final antagonistsAsync =
        ref.watch(plantAntagonistsProvider(plant.id));
    final cs = widget.garden.cellSizeCm;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              _handle(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeader(plant),
                    const SizedBox(height: 24),
                    _buildPositionCard(plant, cs),
                    const SizedBox(height: 16),
                    _buildCultureCard(plant),
                    const SizedBox(height: 16),
                    _buildQuickActionsCard(),
                    const SizedBox(height: 16),
                    _buildEventHistoryCard(),
                    const SizedBox(height: 16),
                    _buildCalendarCard(plant),
                    _buildCompanions(companionsAsync),
                    _buildAntagonists(antagonistsAsync),
                    _buildNotes(),
                    const SizedBox(height: 24),
                    _buildDeleteButton(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _handle() {
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

  Widget _buildHeader(Plant plant) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Color(widget.element.color)
                .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              widget.element.emoji,
              style: const TextStyle(fontSize: 40),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plant.commonName,
                style: AppTypography.titleLarge,
              ),
              if (plant.latinName != null)
                Text(
                  plant.latinName!,
                  style: AppTypography.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (plant.categoryLabel != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plant.categoryLabel!,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionCard(Plant plant, int cs) {
    return _InfoCard(
      title: AppLocalizations.of(context)!.inGarden,
      icon: PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
      trailing: IconButton(
        onPressed: () => setState(
          () => _showSizeEditor = !_showSizeEditor,
        ),
        icon: Icon(
          _showSizeEditor
              ? PhosphorIcons.caretUp(
                  PhosphorIconsStyle.bold,
                )
              : PhosphorIcons.pencilSimple(
                  PhosphorIconsStyle.regular,
                ),
          size: 18,
          color: AppColors.primary,
        ),
        tooltip: AppLocalizations.of(context)!.editDimensions,
      ),
      children: [
        _InfoRow(
          label: AppLocalizations.of(context)!.position,
          value:
              '${widget.element.xMeters(cs).toStringAsFixed(2)}m '
              '\u{00D7} '
              '${widget.element.yMeters(cs).toStringAsFixed(2)}m',
        ),
        _InfoRow(
          label: AppLocalizations.of(context)!.dimensions,
          value:
              '${_width.toStringAsFixed(2)}m '
              '\u{00D7} '
              '${_height.toStringAsFixed(2)}m',
        ),
        if (widget.element.plantedAt != null)
          _EditableDateRow(
            label: AppLocalizations.of(context)!.plantedOn,
            date: widget.element.plantedAt!,
            onChanged: (newDate) async {
              final gpId = widget.element.gardenPlant.id;
              final gardenId = widget.element.gardenPlant.gardenId;
              await ref
                  .read(gardenRepositoryProvider)
                  .updateGardenPlantDetails(
                    id: gpId,
                    plantedAt: newDate,
                  );
              ref.invalidate(gardenPlantsProvider(gardenId));
            },
          ),
        if (widget.element.gardenPlant.sowedAt != null)
          _EditableDateRow(
            label: AppLocalizations.of(context)!.sownOn,
            date: widget.element.gardenPlant.sowedAt!,
            onChanged: (newDate) async {
              final gpId = widget.element.gardenPlant.id;
              final gardenId = widget.element.gardenPlant.gardenId;
              await ref
                  .read(gardenRepositoryProvider)
                  .updateGardenPlantDetails(
                    id: gpId,
                    sowedAt: newDate,
                  );
              ref.invalidate(gardenPlantsProvider(gardenId));
            },
          ),
        _EditableWateringRow(
          currentFrequency: widget.element.gardenPlant.wateringFrequencyDays ??
              defaultWateringFrequencyDays(widget.element.plant?.watering),
          plantWatering: widget.element.plant?.watering,
          onChanged: (freq) async {
            final gpId = widget.element.gardenPlant.id;
            final gardenId = widget.element.gardenPlant.gardenId;
            await ref
                .read(gardenRepositoryProvider)
                .updateGardenPlantDetails(
                  id: gpId,
                  wateringFrequencyDays: freq,
                );
            ref.invalidate(gardenPlantsProvider(gardenId));
            ref.invalidate(wateringRemindersProvider);
          },
        ),
        if (_showSizeEditor) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          DimensionInput(
            label: AppLocalizations.of(context)!.width,
            value: _width,
            min: 0.1,
            max: widget.maxWidthM,
            unit: 'm',
            onChanged: (v) =>
                setState(() => _width = v),
          ),
          const SizedBox(height: 12),
          DimensionInput(
            label: AppLocalizations.of(context)!.length,
            value: _height,
            min: 0.1,
            max: widget.maxHeightM,
            unit: 'm',
            onChanged: (v) =>
                setState(() => _height = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  widget.onUpdate(_width, _height),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.saveDimensions,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCultureCard(Plant plant) {
    final rows = <Widget>[];
    if (plant.spacingBetweenPlants != null) {
      rows.add(_InfoRow(
        label: AppLocalizations.of(context)!.recommendedSpacing,
        value: '${plant.spacingBetweenPlants} cm',
      ));
    }
    if (plant.plantingDepthCm != null) {
      rows.add(_InfoRow(
        label: AppLocalizations.of(context)!.plantingDepth,
        value: '${plant.plantingDepthCm} cm',
      ));
    }
    if (plant.sunExposure != null) {
      rows.add(_InfoRow(
        label: AppLocalizations.of(context)!.exposureLabel,
        value: plant.sunExposure!,
      ));
    }
    if (plant.watering != null) {
      rows.add(_InfoRow(
        label: AppLocalizations.of(context)!.watering,
        value: plant.watering!,
      ));
    }
    if (plant.soilType != null) {
      rows.add(_InfoRow(
        label: AppLocalizations.of(context)!.soilType,
        value: plant.soilType!,
      ));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _InfoCard(
      title: AppLocalizations.of(context)!.culture,
      icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
      children: rows,
    );
  }

  Widget _buildQuickActionsCard() {
    final gpId = widget.element.gardenPlant.id;
    final lastWateringAsync = ref.watch(lastWateringProvider(gpId));

    return _InfoCard(
      title: AppLocalizations.of(context)!.quickActions,
      icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
      children: [
        // Indicateur dernier arrosage
        lastWateringAsync.when(
          data: (lastDate) {
            final String label;
            if (lastDate == null) {
              label = AppLocalizations.of(context)!.neverWatered;
            } else {
              final days = DateTime.now().difference(lastDate).inDays;
              if (days == 0) {
                label = AppLocalizations.of(context)!.wateredToday;
              } else if (days == 1) {
                label = AppLocalizations.of(context)!.wateredYesterday;
              } else {
                label = AppLocalizations.of(context)!.lastWateringDaysAgo(days);
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Text('💧', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(label, style: AppTypography.bodySmall),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                emoji: '💧',
                label: AppLocalizations.of(context)!.waterAction,
                color: const Color(0xFF03A9F4),
                onTap: () {
                  ref
                      .read(gardenEventNotifierProvider.notifier)
                      .quickWater(gpId);
                  ref.invalidate(lastWateringProvider(gpId));
                  ref.invalidate(gardenPlantEventsProvider(gpId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.wateringRegistered),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                emoji: '🧺',
                label: AppLocalizations.of(context)!.harvestAction,
                color: const Color(0xFFE91E63),
                onTap: () {
                  ref
                      .read(gardenEventNotifierProvider.notifier)
                      .quickHarvest(gpId);
                  ref.invalidate(gardenPlantEventsProvider(gpId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.harvestRegistered),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                emoji: '📝',
                label: AppLocalizations.of(context)!.other,
                color: AppColors.textSecondary,
                onTap: () => _showAddEventDialog(gpId),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddEventDialog(int gardenPlantId) {
    GardenEventType selectedType = GardenEventType.sowing;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.addEvent),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<GardenEventType>(
                initialValue: selectedType,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.type,
                  border: const OutlineInputBorder(),
                ),
                items: GardenEventType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text('${t.emoji} ${t.label}'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedType = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(PhosphorIcons.calendar(
                    PhosphorIconsStyle.regular)),
                title: Text(
                  '${selectedDate.day.toString().padLeft(2, '0')}/'
                  '${selectedDate.month.toString().padLeft(2, '0')}/'
                  '${selectedDate.year}',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref
                    .read(gardenEventNotifierProvider.notifier)
                    .logEvent(
                      gardenPlantId: gardenPlantId,
                      eventType: selectedType,
                      date: selectedDate,
                    );
                ref.invalidate(
                    gardenPlantEventsProvider(gardenPlantId));
                ref.invalidate(
                    lastWateringProvider(gardenPlantId));
              },
              child: Text(AppLocalizations.of(context)!.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHistoryCard() {
    final gpId = widget.element.gardenPlant.id;
    final eventsAsync = ref.watch(gardenPlantEventsProvider(gpId));

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        // Afficher les 10 derniers
        final recent = events.take(10).toList();
        return _InfoCard(
          title: AppLocalizations.of(context)!.history,
          icon: PhosphorIcons.clockCounterClockwise(
              PhosphorIconsStyle.fill),
          children: recent
              .map((e) {
                final type = GardenEventType.fromString(e.eventType);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(type.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          type.label,
                          style: AppTypography.bodySmall,
                        ),
                      ),
                      Text(
                        _fmtDate(e.eventDate),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              })
              .toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCalendarCard(Plant plant) {
    if (plant.sowingRecommendation == null &&
        plant.harvestPeriod == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _InfoCard(
        title: AppLocalizations.of(context)!.calendar,
        icon: PhosphorIcons.calendar(
          PhosphorIconsStyle.fill,
        ),
        children: [
          if (plant.sowingRecommendation != null)
            _InfoRow(
              label: AppLocalizations.of(context)!.sowing,
              value: plant.sowingRecommendation!,
            ),
          if (plant.harvestPeriod != null)
            _InfoRow(
              label: AppLocalizations.of(context)!.harvest,
              value: plant.harvestPeriod!,
            ),
        ],
      ),
    );
  }

  Widget _buildCompanions(
    AsyncValue<List<Plant>> async,
  ) {
    return async.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return _CompanionSection(
          title: AppLocalizations.of(context)!.goodAssociations,
          icon: PhosphorIcons.handshake(
            PhosphorIconsStyle.fill,
          ),
          iconColor: AppColors.success,
          plants: list,
          isGood: true,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAntagonists(
    AsyncValue<List<Plant>> async,
  ) {
    return async.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return _CompanionSection(
          title: AppLocalizations.of(context)!.avoidNearby,
          icon: PhosphorIcons.prohibit(
            PhosphorIconsStyle.fill,
          ),
          iconColor: AppColors.error,
          plants: list,
          isGood: false,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNotes() {
    final notes = widget.element.notes;
    if (notes == null || notes.isEmpty) {
      return const SizedBox.shrink();
    }
    return _InfoCard(
      title: AppLocalizations.of(context)!.notes,
      icon: PhosphorIcons.notepad(PhosphorIconsStyle.fill),
      children: [Text(notes, style: AppTypography.bodyMedium)],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmDelete(context),
      icon: Icon(
        PhosphorIcons.trash(PhosphorIconsStyle.regular),
      ),
      label: Text(AppLocalizations.of(context)!.removeFromGarden),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removePlantConfirm),
        content: Text(
          AppLocalizations.of(context)!.removePlantMessage(widget.element.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}

// ========== Editable rows ==========

class _EditableDateRow extends StatefulWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _EditableDateRow({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  State<_EditableDateRow> createState() => _EditableDateRowState();
}

class _EditableDateRowState extends State<_EditableDateRow> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.date;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _date,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null && picked != _date) {
            setState(() => _date = picked);
            widget.onChanged(picked);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                widget.label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _fmt(_date),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableWateringRow extends StatefulWidget {
  final int currentFrequency;
  final String? plantWatering;
  final ValueChanged<int> onChanged;

  const _EditableWateringRow({
    required this.currentFrequency,
    this.plantWatering,
    required this.onChanged,
  });

  @override
  State<_EditableWateringRow> createState() => _EditableWateringRowState();
}

class _EditableWateringRowState extends State<_EditableWateringRow> {
  late int _freq;

  @override
  void initState() {
    super.initState();
    _freq = widget.currentFrequency;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _showFrequencyPicker(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                AppLocalizations.of(context)!.watering,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    AppLocalizations.of(context)!.everyNDays(_freq),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFrequencyPicker() {
    int tempFreq = _freq;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.wateringFrequency),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.plantWatering != null &&
                  widget.plantWatering!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('💧',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.needWatering(widget.plantWatering!),
                            style: AppTypography.caption.copyWith(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [2, 3, 5, 7, 10, 14].map((d) {
                  final selected = tempFreq == d;
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => tempFreq = d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.blue
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? Colors.blue
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.nDays(d),
                        style: AppTypography.bodySmall.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _freq = tempFreq);
                widget.onChanged(tempFreq);
              },
              child: Text(AppLocalizations.of(context)!.validate),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== Widgets utilitaires ==========

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Plant> plants;
  final bool isGood;

  const _CompanionSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.plants,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: plants
              .map(
                (p) => _CompanionChip(
                  plant: p,
                  isGood: isGood,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
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

class _CompanionChip extends StatelessWidget {
  final Plant plant;
  final bool isGood;
  const _CompanionChip({
    required this.plant,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isGood ? AppColors.success : AppColors.error;
    final emoji = PlantEmojiMapper.fromName(
      plant.commonName,
      categoryCode: plant.categoryCode,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            plant.commonName,
            style: AppTypography.labelSmall
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
