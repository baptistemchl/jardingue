import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../../../core/providers/planning_providers.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';

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

    return Container(
      height:
          MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: 12,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius:
                    BorderRadius.circular(2),
              ),
            ),
          ),

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
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context)
                      .padding
                      .bottom +
                  16,
            ),
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
      ),
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
                PlantEmojiMapper.fromName(
              plant.commonName,
              categoryCode:
                  plant.categoryCode,
            );

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

    // Demande la destination : potager ou suivi seulement.
    final gardens = await ref.read(gardensListProvider.future);
    if (!context.mounted) return;

    final destination = await _askDestination(context, gardens);
    if (destination == null) return; // annulé

    // Toujours ajouter au suivi (sélection manuelle).
    for (final id in newlyAddedIds) {
      await notifier.add(id);
    }

    // Si un potager a été choisi, placer les plantes en attente.
    if (destination.gardenId != null) {
      final gardenNotifier =
          ref.read(gardenNotifierProvider.notifier);
      for (final id in newlyAddedIds) {
        await gardenNotifier.addPlantPendingPlacement(
          gardenId: destination.gardenId!,
          plantId: id,
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
      }
    }
  }

  /// Demande si les nouvelles plantes vont dans un potager ou en suivi seul.
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

class _AddDestination {
  final int? gardenId;
  final String? gardenName;
  const _AddDestination.trackingOnly()
      : gardenId = null,
        gardenName = null;
  const _AddDestination.garden(int id, String name)
      : gardenId = id,
        gardenName = name;
}

class _DestinationDialog extends StatefulWidget {
  final List<Garden> gardens;
  const _DestinationDialog({required this.gardens});

  @override
  State<_DestinationDialog> createState() => _DestinationDialogState();
}

class _DestinationDialogState extends State<_DestinationDialog> {
  int? _selectedGardenId;

  @override
  void initState() {
    super.initState();
    if (widget.gardens.length == 1) {
      _selectedGardenId = widget.gardens.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gardens = widget.gardens;
    return AlertDialog(
      title: const Text('Où ajouter ces plantes ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisissez si ces plantes doivent être placées dans un '
            'potager ou seulement suivies.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (gardens.isEmpty)
            Text(
              'Aucun potager créé — elles seront ajoutées au suivi.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          else ...[
            Text('Potager', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButton<int?>(
                value: _selectedGardenId,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                hint: Text(
                  'Aucun',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'Aucun (suivi seulement)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  for (final g in gardens)
                    DropdownMenuItem<int?>(
                      value: g.id,
                      child: Text(
                        g.year != null ? '${g.name} (${g.year})' : g.name,
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) =>
                    setState(() => _selectedGardenId = v),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedGardenId == null) {
              Navigator.of(context)
                  .pop(const _AddDestination.trackingOnly());
            } else {
              final g = gardens.firstWhere(
                (x) => x.id == _selectedGardenId,
              );
              Navigator.of(context)
                  .pop(_AddDestination.garden(g.id, g.name));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
