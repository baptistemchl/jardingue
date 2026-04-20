import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/providers/garden_event_providers.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import 'add_event_sheet.dart';
import '../../../garden/domain/models/garden_event.dart';
import '../../../garden/presentation/widgets/editor/editor_plant_detail_sheet.dart';

/// Vue "Mon suivi" dans le calendrier — affiche tous les événements
/// avec un filtre optionnel par mois (indépendant du calendrier principal).
class UserEventsView extends ConsumerStatefulWidget {
  final DateTime selectedMonth;

  const UserEventsView({super.key, required this.selectedMonth});

  @override
  ConsumerState<UserEventsView> createState() => _UserEventsViewState();
}

class _UserEventsViewState extends ConsumerState<UserEventsView> {
  /// null = tous les mois, sinon filtre sur ce mois
  DateTime? _filterMonth;

  @override
  Widget build(BuildContext context) {
    final allEventsAsync = ref.watch(
      allUserEventsProvider,
    );
    final plantFilter = ref.watch(
      calendarPlantFilterProvider,
    );

    return Stack(
      children: [
        allEventsAsync.when(
          data: (allEvents) {
            if (allEvents.isEmpty) {
              return const _EmptyUserEvents();
            }

            // Filtre par plant global
            var events = allEvents;
            if (plantFilter != null) {
              events = events
                  .where(
                    (e) =>
                        e.event.plantId ==
                        plantFilter,
                  )
                  .toList();
            }

            // Mois disponibles
            final availableMonths =
                <DateTime>{};
            for (final e in events) {
              final d = e.event.eventDate;
              availableMonths.add(
                DateTime(d.year, d.month),
              );
            }
            final sortedMonths =
                availableMonths.toList()
                  ..sort(
                    (a, b) => b.compareTo(a),
                  );

            // Filtre mois local
            final filtered =
                _filterMonth == null
                    ? events
                    : events.where((e) {
                        final d =
                            e.event.eventDate;
                        return d.year ==
                                _filterMonth!
                                    .year &&
                            d.month ==
                                _filterMonth!
                                    .month;
                      }).toList();

            // Grouper par date
            final grouped = <DateTime, List<GardenEventWithDetails>>{};
            for (final e in filtered) {
              final day = DateTime(
                e.event.eventDate.year,
                e.event.eventDate.month,
                e.event.eventDate.day,
              );
              grouped.putIfAbsent(day, () => []).add(e);
            }
            final sortedDays = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return Column(
              children: [
                // Chips de filtre par mois
                _MonthFilterBar(
                  availableMonths: sortedMonths,
                  selectedMonth: _filterMonth,
                  onSelected: (m) => setState(() {
                    _filterMonth = m == _filterMonth ? null : m;
                  }),
                ),
                const SizedBox(height: 4),

                // Liste des événements
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune activite pour ce mois',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: AppSpacing.horizontalPadding,
                          itemCount: sortedDays.length + 1,
                          itemBuilder: (context, index) {
                            if (index == sortedDays.length) {
                              return SizedBox(
                                height: MediaQuery.of(context).padding.bottom + 80,
                              );
                            }
                            final day = sortedDays[index];
                            final dayEvents = grouped[day]!;
                            return _DayEventsSection(
                                day: day, events: dayEvents);
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),

        // Bouton ajouter un événement
        Positioned(
          bottom: 100,
          right: 20,
          child: FloatingActionButton.extended(
            heroTag: 'add_calendar_event',
            onPressed: () => _showAddEventSheet(context, ref),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
            label: const Text('Ajouter'),
          ),
        ),
      ],
    );
  }

  void _showAddEventSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEventSheet(
        selectedDate: DateTime.now(),
        onEventAdded: () {
          ref.invalidate(allUserEventsProvider);
          ref.invalidate(
              monthUserEventsProvider(widget.selectedMonth));
        },
      ),
    );
  }
}

// ============================================
// FILTRE PAR MOIS
// ============================================

class _MonthFilterBar extends StatelessWidget {
  final List<DateTime> availableMonths;
  final DateTime? selectedMonth;
  final ValueChanged<DateTime> onSelected;

  const _MonthFilterBar({
    required this.availableMonths,
    required this.selectedMonth,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: availableMonths.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          // Premier chip = "Tout"
          if (index == 0) {
            final isSelected = selectedMonth == null;
            return GestureDetector(
              onTap: () {
                if (!isSelected) onSelected(selectedMonth!);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  'Tout',
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }

          final month = availableMonths[index - 1];
          final isSelected = selectedMonth != null &&
              selectedMonth!.year == month.year &&
              selectedMonth!.month == month.month;

          // Capitaliser la première lettre
          final label = month.frenchMonthName;
          final capitalized =
              label[0].toUpperCase() + label.substring(1);
          final displayLabel = month.year == DateTime.now().year
              ? capitalized
              : '$capitalized ${month.year}';

          return GestureDetector(
            onTap: () => onSelected(month),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Text(
                displayLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// ÉTAT VIDE
// ============================================

class _EmptyUserEvents extends StatelessWidget {
  const _EmptyUserEvents();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.calendarBlank(PhosphorIconsStyle.duotone),
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune activite enregistree',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos semis, plantations, arrosages et recoltes '
              'apparaitront ici.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// SECTION PAR JOUR
// ============================================

class _DayEventsSection extends StatelessWidget {
  final DateTime day;
  final List<GardenEventWithDetails> events;

  const _DayEventsSection({required this.day, required this.events});

  @override
  Widget build(BuildContext context) {
    final dayLabel =
        '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dayLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${events.length} activite${events.length > 1 ? 's' : ''}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...events.map((e) => _UserEventTile(event: e)),
      ],
    );
  }
}

// ============================================
// TUILE D'ÉVÉNEMENT
// ============================================

class _UserEventTile extends ConsumerWidget {
  final GardenEventWithDetails event;

  const _UserEventTile({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = event.type;
    final plantEmoji = event.plant != null
        ? PlantEmojiMapper.fromName(
            event.plant!.commonName,
            categoryCode: event.plant!.categoryCode,
          )
        : '🌱';

    return GestureDetector(
      onTap: () => _openPlantDetail(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: type.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(plantEmoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.plantName,
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: type.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(type.emoji,
                                style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 3),
                            Text(
                              type.label,
                              style: AppTypography.caption.copyWith(
                                color: type.color,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (event.gardenName.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            event.gardenName,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _openPlantDetail(BuildContext context, WidgetRef ref) {
    if (event.plant == null) return;

    final gp = event.gardenPlant;
    final garden = event.garden;
    if (gp == null || garden == null) {
      _showSimplePlantInfo(context, ref);
      return;
    }

    final element = GardenPlantWithDetails(
      gardenPlant: gp,
      plant: event.plant,
    );

    final maxW = garden.widthCells * garden.cellSizeCm / 100.0;
    final maxH = garden.heightCells * garden.cellSizeCm / 100.0;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditorPlantDetailSheet(
        element: element,
        garden: garden,
        maxWidthM: maxW,
        maxHeightM: maxH,
        onUpdate: (w, h) async {
          Navigator.of(ctx, rootNavigator: true).pop();
          await ref
              .read(gardenRepositoryProvider)
              .updateGardenPlantSize(gp.id, w.round(), h.round());
          ref.invalidate(gardenPlantsProvider(garden.id));
        },
        onDelete: () async {
          Navigator.of(ctx, rootNavigator: true).pop();
          await ref
              .read(gardenRepositoryProvider)
              .removePlantFromGarden(gp.id);
          ref.invalidate(gardenPlantsProvider(garden.id));
        },
      ),
    );
  }

  void _showSimplePlantInfo(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EventDetailSheet(event: event),
    );
  }
}

// ============================================
// DETAIL / MODIFIER UN EVENEMENT
// ============================================

class _EventDetailSheet extends ConsumerStatefulWidget {
  final GardenEventWithDetails event;

  const _EventDetailSheet({required this.event});

  @override
  ConsumerState<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends ConsumerState<_EventDetailSheet> {
  late GardenEventType _currentType;

  @override
  void initState() {
    super.initState();
    _currentType = widget.event.type;
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.event.plant!;
    final emoji = PlantEmojiMapper.fromName(
        plant.commonName, categoryCode: plant.categoryCode);
    final date =
        '${widget.event.event.eventDate.day.toString().padLeft(2, '0')}/'
        '${widget.event.event.eventDate.month.toString().padLeft(2, '0')}/'
        '${widget.event.event.eventDate.year}';

    final hasChanged = _currentType != widget.event.type;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(plant.commonName, style: AppTypography.titleLarge),
          if (plant.latinName != null)
            Text(plant.latinName!,
                style: AppTypography.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(date,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          if (widget.event.gardenName.isNotEmpty)
            Text(widget.event.gardenName,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 20),

          Text('Type d\'evenement', style: AppTypography.labelMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GardenEventType.values.map((t) {
              final selected = _currentType == t;
              return GestureDetector(
                onTap: () => setState(() => _currentType = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? t.color
                        : t.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? t.color
                          : t.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        t.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: selected ? Colors.white : t.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (_currentType.isSowing) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentType == GardenEventType.sowingUnderCover
                          ? 'Semis sous abri : recommande dans les regions '
                              'froides ou quand les temperatures nocturnes '
                              'descendent sous 10°C. Protege du gel.'
                          : 'Semis pleine terre : uniquement quand le risque '
                              'de gel est passe. Dans les regions froides, '
                              'privilegiez les semis sous serre ou chassis.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          if (hasChanged)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final notifier =
                      ref.read(gardenEventNotifierProvider.notifier);
                  await notifier.deleteEvent(
                    widget.event.event.id,
                    widget.event.event.gardenPlantId ?? 0,
                  );
                  await notifier.logEvent(
                    gardenPlantId: widget.event.event.gardenPlantId,
                    plantId: widget.event.event.plantId,
                    eventType: _currentType,
                    date: widget.event.event.eventDate,
                  );
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Enregistrer la modification'),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Supprimer cet evenement ?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.error),
                          child: const Text('Supprimer')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(gardenEventNotifierProvider.notifier)
                      .deleteEvent(
                        widget.event.event.id,
                        widget.event.event.gardenPlantId ?? 0,
                      );
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                }
              },
              icon: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular),
                  size: 16),
              label: const Text('Supprimer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
