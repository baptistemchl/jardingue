import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../../../core/providers/garden_event_providers.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import '../../../garden/domain/models/garden_event.dart';

/// Bottom sheet pour ajouter un evenement depuis le calendrier.
///
/// Pour semis/plantation :
///   Type → Plante (catalogue complet) → Potager (optionnel) → Confirmation
/// Pour arrosage/recolte :
///   Type → Source (potager) → Plante du potager → Confirmation
class AddEventSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onEventAdded;

  const AddEventSheet({
    super.key,
    required this.selectedDate,
    required this.onEventAdded,
  });

  @override
  ConsumerState<AddEventSheet> createState() => _AddEventSheetState();
}

enum _PlantSource { garden, catalog }

class _AddEventSheetState extends ConsumerState<AddEventSheet> {
  int _step = 0;
  GardenEventType? _eventType;

  // Pour semis/plantation : plante du catalogue + potager optionnel
  Plant? _catalogPlant;
  Garden? _targetGarden;

  // Pour arrosage/recolte : plante dans un potager
  Garden? _selectedGarden;
  int? _gardenPlantId;
  Plant? _gardenPlantRef;

  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    // Ne pas laisser la recherche fuir vers l'ecran Plantes principal.
    ref.read(plantsFilterProvider.notifier).clearFilters();
    super.dispose();
  }

  bool get _isSowingOrPlanting =>
      _eventType != null &&
      (_eventType!.isSowing || _eventType == GardenEventType.planting);

  String get _dateLabel =>
      '${widget.selectedDate.day.toString().padLeft(2, '0')}/'
      '${widget.selectedDate.month.toString().padLeft(2, '0')}/'
      '${widget.selectedDate.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(),
          Expanded(child: _buildCurrentStep()),
        ],
      ),
    );
  }

  Widget _buildHandle() => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (_step > 0)
              IconButton(
                onPressed: _goBack,
                icon:
                    Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (_step > 0) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_headerTitle, style: AppTypography.titleMedium),
                  Text(_dateLabel,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
            ),
          ],
        ),
      );

  // ============================================
  // NAVIGATION
  // ============================================

  // Steps pour semis/plantation :
  //   0=type, 1=plante catalogue, 2=choix potager (optionnel), 3=confirm
  // Steps pour arrosage/recolte :
  //   0=type, 10=source, 11=jardin ou catalogue, 12=plante, 13=confirm

  String get _headerTitle {
    if (_isSowingOrPlanting) {
      return switch (_step) {
        0 => 'Que voulez-vous enregistrer ?',
        1 => 'Quelle plante ?',
        2 => 'Ajouter à un potager ?',
        3 => 'Confirmer',
        _ => '',
      };
    }
    return switch (_step) {
      0 => 'Que voulez-vous enregistrer ?',
      10 => 'Choisir la source',
      11 => _trackingSource == _PlantSource.garden
          ? 'Dans quel jardin ?'
          : 'Plantes suivies',
      12 => 'Quelle plante ?',
      13 => 'Confirmer',
      _ => '',
    };
  }

  _PlantSource? _trackingSource;

  void _goBack() {
    setState(() {
      if (_isSowingOrPlanting) {
        _step = _step > 0 ? _step - 1 : 0;
      } else {
        switch (_step) {
          case 10:
            _step = 0;
          case 11:
            _step = 10;
          case 12:
            _step = 11;
          case 13:
            _step = _trackingSource == _PlantSource.garden ? 12 : 11;
        }
      }
    });
  }

  Widget _buildCurrentStep() {
    if (_isSowingOrPlanting) {
      return switch (_step) {
        0 => _buildTypeSelection(),
        1 => _buildCatalogSelection(),
        2 => _buildGardenChoice(),
        3 => _buildSowingConfirmation(),
        _ => const SizedBox.shrink(),
      };
    }
    return switch (_step) {
      0 => _buildTypeSelection(),
      10 => _buildTrackingSourceSelection(),
      11 => _trackingSource == _PlantSource.garden
          ? _buildGardenSelection()
          : _buildTrackedPlantsSelection(),
      12 => _buildGardenPlantSelection(),
      13 => _buildTrackingConfirmation(),
      _ => const SizedBox.shrink(),
    };
  }

  // ============================================
  // STEP 0 : Type
  // ============================================

  Widget _buildTypeSelection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Semis & Plantation',
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        _TypeCard(
          type: GardenEventType.sowingUnderCover,
          description: 'En interieur, serre, chassis...',
          onTap: () => setState(() {
            _eventType = GardenEventType.sowingUnderCover;
            _step = 1;
            _searchCtrl.clear();
            ref.read(plantsFilterProvider.notifier).setSearchQuery('');
          }),
        ),
        _TypeCard(
          type: GardenEventType.sowingOpenGround,
          description: 'Directement en pleine terre',
          onTap: () => setState(() {
            _eventType = GardenEventType.sowingOpenGround;
            _step = 1;
            _searchCtrl.clear();
            ref.read(plantsFilterProvider.notifier).setSearchQuery('');
          }),
        ),
        _TypeCard(
          type: GardenEventType.planting,
          description: 'Repiquage ou mise en terre',
          onTap: () => setState(() {
            _eventType = GardenEventType.planting;
            _step = 1;
            _searchCtrl.clear();
            ref.read(plantsFilterProvider.notifier).setSearchQuery('');
          }),
        ),
        const SizedBox(height: 24),
        Text('Suivi',
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        _TypeCard(
          type: GardenEventType.watering,
          description: 'Enregistrer un arrosage',
          onTap: () => _selectTrackingType(GardenEventType.watering),
        ),
        _TypeCard(
          type: GardenEventType.harvest,
          description: 'Enregistrer une recolte',
          onTap: () => _selectTrackingType(GardenEventType.harvest),
        ),
      ],
    );
  }

  void _selectTrackingType(GardenEventType type) {
    setState(() {
      _eventType = type;
      _step = 10;
      _trackingSource = null;
    });
  }

  // ============================================
  // ARROSAGE/RECOLTE : choix source
  // ============================================

  Widget _buildTrackingSourceSelection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SourceCard(
          icon: PhosphorIcons.squaresFour(PhosphorIconsStyle.duotone),
          title: 'Depuis un potager',
          subtitle: 'Choisir parmi les plantes de vos potagers',
          color: AppColors.primary,
          onTap: () => setState(() {
            _trackingSource = _PlantSource.garden;
            _step = 11;
          }),
        ),
        const SizedBox(height: 12),
        _SourceCard(
          icon: PhosphorIcons.notepad(PhosphorIconsStyle.duotone),
          title: 'Depuis mon suivi',
          subtitle: 'Plantes deja enregistrees dans votre calendrier',
          color: AppColors.info,
          onTap: () => setState(() {
            _trackingSource = _PlantSource.catalog;
            _step = 11;
          }),
        ),
      ],
    );
  }

  // ============================================
  // ARROSAGE/RECOLTE : plantes suivies
  // ============================================

  Widget _buildTrackedPlantsSelection() {
    final trackedAsync = ref.watch(trackedPlantsProvider);

    return trackedAsync.when(
      data: (plants) {
        if (plants.isEmpty) {
          return _EmptyMessage(
              icon: PhosphorIcons.notepad(PhosphorIconsStyle.duotone),
              text: 'Aucune plante dans votre suivi.\n'
                  'Enregistrez un semis ou une plantation d\'abord.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: plants.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final plant = plants[i];
            return _SelectionTile(
              emoji: PlantEmojiMapper.fromName(plant.commonName,
                  categoryCode: plant.categoryCode),
              title: plant.commonName,
              subtitle: plant.latinName,
              onTap: () => setState(() {
                _gardenPlantId = null;
                _gardenPlantRef = plant;
                _step = 13;
              }),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  // ============================================
  // SEMIS/PLANTATION : catalogue complet
  // ============================================

  Widget _buildCatalogSelection() {
    final plantsAsync = ref.watch(filteredPlantsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                ref.read(plantsFilterProvider.notifier).setSearchQuery(v);
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher une plante...',
              prefixIcon: Icon(PhosphorIcons.magnifyingGlass(
                  PhosphorIconsStyle.regular)),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: plantsAsync.when(
            data: (plants) {
              if (plants.isEmpty) {
                return _EmptyMessage(
                    icon: PhosphorIcons.magnifyingGlass(
                        PhosphorIconsStyle.duotone),
                    text: 'Aucune plante trouvee');
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: plants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final plant = plants[i];
                  return _SelectionTile(
                    emoji: PlantEmojiMapper.fromName(plant.commonName,
                        categoryCode: plant.categoryCode),
                    title: plant.commonName,
                    subtitle: plant.latinName,
                    onTap: () => setState(() {
                      _catalogPlant = plant;
                      _step = 2;
                    }),
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
          ),
        ),
      ],
    );
  }

  // ============================================
  // SEMIS/PLANTATION : choix potager (optionnel)
  // ============================================

  Widget _buildGardenChoice() {
    final gardensAsync = ref.watch(gardensListProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Option "sans potager"
        _SourceCard(
          icon: PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone),
          title: 'Sans potager',
          subtitle: 'Juste enregistrer l\'evenement dans le calendrier',
          color: AppColors.textSecondary,
          onTap: () => setState(() {
            _targetGarden = null;
            _step = 3;
          }),
        ),

        const SizedBox(height: 16),
        Text('Ou ajouter à un potager',
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),

        gardensAsync.when(
          data: (gardens) {
            if (gardens.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Aucun potager créé',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
              );
            }
            return Column(
              children: gardens.map((garden) {
                // Alerte dimensions si spacing plante > taille potager
                String? warning;
                if (_catalogPlant?.spacingBetweenPlants != null) {
                  final spacingM =
                      _catalogPlant!.spacingBetweenPlants! / 100.0;
                  final gardenW =
                      garden.widthCells * garden.cellSizeCm / 100.0;
                  final gardenH =
                      garden.heightCells * garden.cellSizeCm / 100.0;
                  if (spacingM > gardenW || spacingM > gardenH) {
                    warning =
                        'Espacement recommande (${_catalogPlant!.spacingBetweenPlants} cm) '
                        'depasse les dimensions du potager';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _GardenTileWithWarning(
                    garden: garden,
                    warning: warning,
                    onTap: () => setState(() {
                      _targetGarden = garden;
                      _step = 3;
                    }),
                  ),
                );
              }).toList(),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erreur: $e'),
        ),
      ],
    );
  }

  // ============================================
  // SEMIS/PLANTATION : confirmation
  // ============================================

  Widget _buildSowingConfirmation() {
    if (_catalogPlant == null || _eventType == null) {
      return const SizedBox.shrink();
    }
    final plant = _catalogPlant!;
    final emoji = PlantEmojiMapper.fromName(plant.commonName,
        categoryCode: plant.categoryCode);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _RecapCard(
          emoji: emoji,
          plant: plant,
          eventType: _eventType!,
          dateLabel: _dateLabel,
          gardenName: _targetGarden?.name,
          showPendingBadge: _targetGarden != null,
        ),
        const SizedBox(height: 16),
        _buildAdvice(plant),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _confirmSowing,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_eventType!.emoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Enregistrer',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSowing() async {
    if (_catalogPlant == null || _eventType == null) return;

    if (_targetGarden != null) {
      // Ajouter au potager en attente de placement + créer l'événement
      final spacing = _catalogPlant!.spacingBetweenPlants;
      final widthM = spacing != null && spacing > 0
          ? spacing / 100.0
          : null;

      await ref.read(gardenNotifierProvider.notifier).addPlantPendingPlacement(
            gardenId: _targetGarden!.id,
            plantId: _catalogPlant!.id,
            widthMeters: widthM,
            heightMeters: widthM,
            sowedAt: _eventType!.isSowing ? widget.selectedDate : null,
            plantedAt:
                _eventType == GardenEventType.planting
                    ? widget.selectedDate
                    : null,
          );
    } else {
      // Juste l'événement sans potager
      await ref.read(gardenEventNotifierProvider.notifier).logEvent(
            plantId: _catalogPlant!.id,
            eventType: _eventType!,
            date: widget.selectedDate,
          );
    }

    widget.onEventAdded();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  // ============================================
  // ARROSAGE/RECOLTE : jardin → plante existante
  // ============================================

  Widget _buildGardenSelection() {
    final gardensAsync = ref.watch(gardensListProvider);
    return gardensAsync.when(
      data: (gardens) {
        if (gardens.isEmpty) {
          return _EmptyMessage(
              icon: PhosphorIcons.plant(PhosphorIconsStyle.duotone),
              text: 'Aucun jardin créé');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: gardens.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final garden = gardens[i];
            return _SelectionTile(
              emoji: '🌱',
              title: garden.name,
              subtitle: _gardenDims(garden),
              onTap: () => setState(() {
                _selectedGarden = garden;
                _step = 12;
              }),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildGardenPlantSelection() {
    if (_selectedGarden == null) return const SizedBox.shrink();
    final plantsAsync =
        ref.watch(gardenPlantsProvider(_selectedGarden!.id));
    return plantsAsync.when(
      data: (plants) {
        final real =
            plants.where((p) => !p.isZone && p.plant != null).toList();
        if (real.isEmpty) {
          return _EmptyMessage(
              icon: PhosphorIcons.plant(PhosphorIconsStyle.duotone),
              text: 'Aucune plante dans ce jardin');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: real.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final gp = real[i];
            return _SelectionTile(
              emoji: PlantEmojiMapper.fromName(
                  gp.plant!.commonName,
                  categoryCode: gp.plant!.categoryCode),
              title: gp.plant!.commonName,
              subtitle: gp.plant!.latinName,
              onTap: () => setState(() {
                _gardenPlantId = gp.gardenPlant.id;
                _gardenPlantRef = gp.plant;
                _step = 13;
              }),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildTrackingConfirmation() {
    if (_gardenPlantRef == null || _eventType == null) {
      return const SizedBox.shrink();
    }
    final plant = _gardenPlantRef!;
    final emoji = PlantEmojiMapper.fromName(plant.commonName,
        categoryCode: plant.categoryCode);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _RecapCard(
          emoji: emoji,
          plant: plant,
          eventType: _eventType!,
          dateLabel: _dateLabel,
          gardenName: _selectedGarden?.name,
          showPendingBadge: false,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _confirmTracking,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_eventType!.emoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Enregistrer',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmTracking() async {
    await ref.read(gardenEventNotifierProvider.notifier).logEvent(
          gardenPlantId: _gardenPlantId,
          plantId: _gardenPlantId == null ? _gardenPlantRef?.id : null,
          eventType: _eventType!,
          date: widget.selectedDate,
        );
    widget.onEventAdded();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  // ============================================
  // CONSEILS METEO
  // ============================================

  Widget _buildAdvice(Plant plant) {
    final items = <_AdviceItem>[];

    if (plant.plantingMinTempC != null) {
      items.add(_AdviceItem(
          emoji: '🌡',
          text:
              'Temperature min. de plantation : ${plant.plantingMinTempC}°C'));
    }
    if (plant.plantingWeatherConditions != null &&
        plant.plantingWeatherConditions!.isNotEmpty) {
      items.add(
          _AdviceItem(emoji: '☁️', text: plant.plantingWeatherConditions!));
    }
    if (_eventType == GardenEventType.sowingUnderCover) {
      items.add(const _AdviceItem(
          emoji: '🏠',
          text:
              'Semis sous abri : protege du gel et des intemperies. '
              'Ideal quand les temperatures nocturnes sont basses.'));
    } else if (_eventType == GardenEventType.sowingOpenGround) {
      items.add(const _AdviceItem(
          emoji: '🌤',
          text:
              'Semis pleine terre : assurez-vous que le risque de gel '
              'est passe et que le sol est rechauffe.'));
    }

    final weatherAsync = ref.watch(weatherDataProvider);
    weatherAsync.whenData((weather) {
      final temp = weather.current.temperature;
      final minTemp = plant.plantingMinTempC;
      if (minTemp != null) {
        if (temp < minTemp) {
          items.add(_AdviceItem(
              emoji: '⚠️',
              text:
                  'Actuellement ${temp.round()}°C — en dessous du minimum '
                  'recommande de $minTemp°C.',
              isWarning: true));
        } else {
          items.add(_AdviceItem(
              emoji: '✅',
              text:
                  'Actuellement ${temp.round()}°C — temperature favorable '
                  '(min. $minTemp°C).'));
        }
      }
      if (weather.dailyForecast.isNotEmpty) {
        final todayMin = weather.dailyForecast.first.tempMin;
        if (todayMin <= 2 &&
            _eventType == GardenEventType.sowingOpenGround) {
          items.add(const _AdviceItem(
              emoji: '🥶',
              text:
                  'Risque de gel cette nuit ! Preferez un semis sous abri.',
              isWarning: true));
        }
      }
    });

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Conseils',
                style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.emoji,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(item.text,
                            style: AppTypography.bodySmall.copyWith(
                                color: item.isWarning
                                    ? AppColors.warning
                                    : AppColors.textSecondary))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _gardenDims(Garden g) {
    final w = (g.widthCells * g.cellSizeCm) / 100;
    final h = (g.heightCells * g.cellSizeCm) / 100;
    return '${w.toStringAsFixed(1)} m x ${h.toStringAsFixed(1)} m';
  }
}

// ============================================
// WIDGETS
// ============================================

class _AdviceItem {
  final String emoji, text;
  final bool isWarning;
  const _AdviceItem(
      {required this.emoji, required this.text, this.isWarning = false});
}

class _RecapCard extends StatelessWidget {
  final String emoji;
  final Plant plant;
  final GardenEventType eventType;
  final String dateLabel;
  final String? gardenName;
  final bool showPendingBadge;

  const _RecapCard({
    required this.emoji,
    required this.plant,
    required this.eventType,
    required this.dateLabel,
    this.gardenName,
    this.showPendingBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(plant.commonName, style: AppTypography.titleMedium),
          if (plant.latinName != null)
            Text(plant.latinName!,
                style: AppTypography.caption.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: eventType.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(eventType.emoji,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(eventType.label,
                    style: AppTypography.labelMedium.copyWith(
                        color: eventType.color,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(dateLabel,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          if (gardenName != null) ...[
            const SizedBox(height: 4),
            Text(gardenName!,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textTertiary)),
          ],
          if (showPendingBadge) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.clock(PhosphorIconsStyle.fill),
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text('En attente de placement dans le potager',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GardenTileWithWarning extends StatelessWidget {
  final Garden garden;
  final String? warning;
  final VoidCallback onTap;

  const _GardenTileWithWarning({
    required this.garden,
    this.warning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = (garden.widthCells * garden.cellSizeCm) / 100;
    final h = (garden.heightCells * garden.cellSizeCm) / 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                      child:
                          Text('🌱', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(garden.name,
                          style: AppTypography.titleSmall),
                      Text(
                          '${w.toStringAsFixed(1)} m x ${h.toStringAsFixed(1)} m',
                          style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    size: 16, color: AppColors.textTertiary),
              ],
            ),
            if (warning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill),
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(warning!,
                            style: AppTypography.caption.copyWith(
                                color: AppColors.warning, fontSize: 11))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final GardenEventType type;
  final String description;
  final VoidCallback onTap;

  const _TypeCard(
      {required this.type, required this.description, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                    child: Text(type.emoji,
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.label, style: AppTypography.titleSmall),
                    Text(description,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                  size: 16, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourceCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall),
                  Text(subtitle,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String emoji, title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SelectionTile(
      {required this.emoji,
      required this.title,
      this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child:
                      Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(text,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
