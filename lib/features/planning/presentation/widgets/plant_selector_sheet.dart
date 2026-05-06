import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/garden_event_providers.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../../../core/providers/planning_providers.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../garden/domain/models/garden_event.dart';

class PlantSelectorSheet
    extends ConsumerStatefulWidget {
  const PlantSelectorSheet({super.key});

  @override
  ConsumerState<PlantSelectorSheet> createState() =>
      _PlantSelectorSheetState();
}

class _PlantSelectorSheetState
    extends ConsumerState<PlantSelectorSheet> {
  String _search = '';
  final _selectedIds = <int>{};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final current = ref
          .read(selectedPlantsProvider)
          .value;
      if (current != null) {
        _selectedIds.addAll(
          current.map((p) => p.plantId),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(
      databaseInitProvider,
    );

    return Column(
      children: [
        const AppBottomSheetHandle(),
        // Titre
        Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Sélectionner des plants',
                  style: AppTypography.titleMedium
                      .copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedIds.length}'
                  ' sélectionnés',
                  style: AppTypography.caption
                      .copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Recherche
          Padding(
            padding: AppSpacing.horizontalPadding,
            child: TextField(
              onChanged: (v) =>
                  setState(() => _search = v),
              decoration: InputDecoration(
                hintText:
                    'Rechercher un plant...',
                prefixIcon: Icon(
                  PhosphorIcons.magnifyingGlass(
                    PhosphorIconsStyle.regular,
                  ),
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Liste
          Expanded(
            child: dbAsync.when(
              data: (_) => _buildList(),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: Text('$e'),
              ),
            ),
          ),

          // Bouton valider
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    _onValidate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Valider '
                  '(${_selectedIds.length})',
                  style: AppTypography.labelLarge
                      .copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildList() {
    final db = ref.read(databaseProvider);
    return FutureBuilder(
      future: db.getAllPlantsSorted(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        var plants = snapshot.data!;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          plants = plants
              .where(
                (p) => p.commonName
                    .toLowerCase()
                    .contains(q),
              )
              .toList();
        }

        return ListView.builder(
          itemCount: plants.length,
          itemBuilder: (context, index) {
            final plant = plants[index];
            final selected = _selectedIds
                .contains(plant.id);

            final emoji =
                PlantEmojiMapper.forPlant(plant);

            return ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      AppColors.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              title: Text(
                plant.commonName,
                style: AppTypography.bodyMedium,
              ),
              subtitle:
                  plant.categoryLabel != null
                      ? Text(
                          plant.categoryLabel!,
                          style: AppTypography
                              .caption
                              .copyWith(
                            color: AppColors
                                .textSecondary,
                          ),
                        )
                      : null,
              trailing: Checkbox(
                value: selected,
                activeColor: AppColors.primary,
                onChanged: (_) =>
                    _togglePlant(plant.id),
              ),
              onTap: () =>
                  _togglePlant(plant.id),
            );
          },
        );
      },
    );
  }

  void _togglePlant(int plantId) {
    setState(() {
      if (_selectedIds.contains(plantId)) {
        _selectedIds.remove(plantId);
      } else {
        _selectedIds.add(plantId);
      }
    });
  }

  Future<void> _onValidate(
    BuildContext context,
  ) async {
    final notifier = ref.read(
      selectedPlantsProvider.notifier,
    );
    final current = ref
            .read(selectedPlantsProvider)
            .value ??
        [];

    final currentIds = current.map((p) => p.plantId).toSet();
    final newlyAddedIds =
        _selectedIds.where((id) => !currentIds.contains(id)).toList();

    // Suppressions : si l'utilisateur a décoché, on retire.
    for (final id in currentIds) {
      if (!_selectedIds.contains(id)) {
        await notifier.remove(id);
      }
    }

    // S'il n'y a pas de nouvelles plantes à ajouter, on s'arrête ici.
    if (newlyAddedIds.isEmpty) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    // Demande la destination : potager OU event sans potager.
    final gardens = await ref.read(gardensListProvider.future);
    if (!context.mounted) return;

    final destination = await _askDestination(context, gardens);
    if (destination == null) return; // annulé

    if (destination.gardenId != null) {
      // Ajouter au potager en pending placement → la plante sera trackee
      // via garden_plants (fusionne dans selectedPlantsProvider).
      final gardenNotifier =
          ref.read(gardenNotifierProvider.notifier);
      for (final id in newlyAddedIds) {
        await gardenNotifier.addPlantPendingPlacement(
          gardenId: destination.gardenId!,
          plantId: id,
        );
      }
    } else {
      // Pas de potager : on cree un event (semis ou plantation) avec
      // plantId seul → la plante apparait dans la planification ET dans
      // Mon Suivi via garden_events.
      final eventNotifier =
          ref.read(gardenEventNotifierProvider.notifier);
      for (final id in newlyAddedIds) {
        await eventNotifier.logEvent(
          plantId: id,
          eventType: destination.eventType!,
          date: DateTime.now(),
        );
      }
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      if (destination.gardenId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${newlyAddedIds.length} plante(s) ajoutée(s) au '
              'potager "${destination.gardenName}". '
              'Placez-les dans l\'éditeur.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        final label = destination.eventType == GardenEventType.sowing
            ? 'semée(s)'
            : 'plantée(s)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${newlyAddedIds.length} plante(s) $label aujourd\'hui '
              '(visible dans Mon Suivi).',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Demande la destination : potager OU event (semis/plantation sans potager).
  /// Retourne null si annulé.
  Future<_AddDestination?> _askDestination(
    BuildContext context,
    List<Garden> gardens,
  ) {
    return showDialog<_AddDestination>(
      context: context,
      builder: (ctx) => _DestinationDialog(gardens: gardens),
    );
  }
}

/// Destination d'ajout : soit un potager (pending placement), soit un event
/// sans potager (semis ou plantation, daté du jour).
class _AddDestination {
  final int? gardenId;
  final String? gardenName;
  final GardenEventType? eventType;
  const _AddDestination.garden(int id, String name)
      : gardenId = id,
        gardenName = name,
        eventType = null;
  const _AddDestination.event(GardenEventType type)
      : gardenId = null,
        gardenName = null,
        eventType = type;
}

/// Dialog : "Ou ajouter ces plantes ?" — potager existant OU event seul
/// (semis / plantation aujourd'hui sans potager).
class _DestinationDialog extends StatelessWidget {
  final List<Garden> gardens;
  const _DestinationDialog({required this.gardens});

  void _pickGarden(BuildContext context, Garden g) {
    Navigator.of(context).pop(_AddDestination.garden(g.id, g.name));
  }

  void _pickEvent(BuildContext context, GardenEventType type) {
    Navigator.of(context).pop(_AddDestination.event(type));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Où ajouter ces plantes ?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (gardens.isNotEmpty) ...[
              Text(
                'Dans un potager',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              for (final g in gardens) ...[
                _DestinationTile(
                  emoji: '🌱',
                  title: g.year != null ? '${g.name} (${g.year})' : g.name,
                  subtitle: 'Placement à définir dans l\'éditeur',
                  onTap: () => _pickGarden(context, g),
                ),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 12),
              Text(
                'Sans potager (logué dans Mon Suivi)',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Aucun potager — choisissez le type d\'action enregistrée :',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            _DestinationTile(
              emoji: GardenEventType.sowing.emoji,
              title: 'J\'ai semé aujourd\'hui',
              subtitle: 'Crée un événement de semis',
              onTap: () => _pickEvent(context, GardenEventType.sowing),
            ),
            const SizedBox(height: 6),
            _DestinationTile(
              emoji: GardenEventType.planting.emoji,
              title: 'J\'ai planté aujourd\'hui',
              subtitle: 'Crée un événement de plantation',
              onTap: () => _pickEvent(context, GardenEventType.planting),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class _DestinationTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DestinationTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
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
