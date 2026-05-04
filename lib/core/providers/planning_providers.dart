import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/planning/data/datasources/garden_tasks_datasource.dart';
import '../../features/planning/domain/models/planning_state.dart';
import '../../features/planning/domain/models/selected_plant.dart';
import '../../features/planning/domain/usecases/compute_planning_tasks.dart';
import '../services/crash_reporting/crash_reporting_service.dart';
import '../utils/plant_emoji_mapper.dart';
import 'database_providers.dart';
import 'weather_providers.dart';

// ============================================
// DATASOURCE TACHES POTAGERES
// ============================================

final gardenTasksDatasourceProvider =
    Provider<GardenTasksDatasource>((ref) {
  return GardenTasksDatasource();
});

// ============================================
// SELECTED PLANTS (union manuelle + jardin)
// ============================================

/// Stream brut : plantes posées sur n'importe quel potager, converties
/// en `SelectedPlant` (les zones `plantId=0` sont exclues).
final _gardenDerivedSelectedPlantsStream =
    StreamProvider<List<SelectedPlant>>((ref) async* {
  // `ref.watch` synchroniquement avant tout `await`.
  final initFuture = ref.read(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  await initFuture;
  yield* db.watchAllGardenPlantsWithPlantAndGarden().map((rows) {
    final map = <int, SelectedPlant>{};
    for (final row in rows) {
      final gp = row.readTable(db.gardenPlants);
      if (gp.plantId == 0) continue;
      final plant = row.readTableOrNull(db.plants);
      if (plant == null) continue;
      final addedAt = gp.plantedAt ?? gp.createdAt;
      final existing = map[gp.plantId];
      if (existing == null || addedAt.isAfter(existing.addedAt)) {
        map[gp.plantId] = SelectedPlant(
          plantId: gp.plantId,
          commonName: plant.commonName,
          categoryCode: plant.categoryCode,
          addedAt: addedAt,
        );
      }
    }
    return map.values.toList();
  });
});

/// Stream brut : plantes tracees via au moins un event (semis, plantation,
/// arrosage, recolte, entretien...). Source unifiee pour la planification.
final _eventDerivedSelectedPlantsStream =
    StreamProvider<List<SelectedPlant>>((ref) async* {
  final initFuture = ref.read(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  await initFuture;
  yield* db.watchTrackedPlantsWithDetails().map((rows) => rows
      .map((r) => SelectedPlant(
            plantId: r.plantId,
            commonName: r.commonName,
            categoryCode: r.categoryCode,
            addedAt: r.addedAt,
          ))
      .toList());
});

/// Union des deux sources : `garden_plants` (plante posee) et
/// `garden_events` (plante avec au moins un event, potager ou non).
///
/// On preserve la date d'ajout la plus ancienne pour rester chronologique.
/// Reactif par construction : tout changement DB (potager, event) re-emet.
final selectedPlantsProvider =
    AsyncNotifierProvider<SelectedPlantsNotifier, List<SelectedPlant>>(
  SelectedPlantsNotifier.new,
);

class SelectedPlantsNotifier extends AsyncNotifier<List<SelectedPlant>> {
  @override
  Future<List<SelectedPlant>> build() async {
    // Toutes les `ref.watch` doivent être déclarées synchroniquement
    // avant tout `await` pour préserver le bookkeeping pause/resume
    // de Riverpod 3.x lors d'un changement de TickerMode.
    final gardenFuture =
        ref.watch(_gardenDerivedSelectedPlantsStream.future);
    final eventsFuture =
        ref.watch(_eventDerivedSelectedPlantsStream.future);
    try {
      final garden = await gardenFuture;
      final fromEvents = await eventsFuture;
      final merged = <int, SelectedPlant>{};
      for (final p in fromEvents) {
        merged[p.plantId] = p;
      }
      for (final p in garden) {
        // Priorite a `garden_plants` (date plus precise via plantedAt).
        // Si la plante existe deja via event, on garde la date la plus
        // ancienne pour ne pas remonter artificiellement la plante.
        final existing = merged[p.plantId];
        if (existing == null || p.addedAt.isBefore(existing.addedAt)) {
          merged[p.plantId] = p;
        }
      }
      return merged.values.toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    } catch (e, st) {
      CrashReportingService.recordError(
        e, st,
        reason: 'selectedPlantsProvider.build',
      );
      rethrow;
    }
  }

  /// Retire une plante du suivi : supprime tous ses events et tous les
  /// gardenPlants qui la referencent. La plante reapparaitra si
  /// l'utilisateur la replante / re-logue un event.
  Future<void> remove(int plantId) async {
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      // 1. Supprimer les events lies via gardenPlantId (events des potagers)
      final gpIds = await (db.selectOnly(db.gardenPlants)
            ..addColumns([db.gardenPlants.id])
            ..where(db.gardenPlants.plantId.equals(plantId)))
          .map((r) => r.read(db.gardenPlants.id)!)
          .get();
      if (gpIds.isNotEmpty) {
        await (db.delete(db.gardenEvents)
              ..where((t) => t.gardenPlantId.isIn(gpIds)))
            .go();
      }
      // 2. Supprimer les events lies directement via plantId (sans potager)
      await (db.delete(db.gardenEvents)
            ..where((t) => t.plantId.equals(plantId)))
          .go();
      // 3. Supprimer les gardenPlants
      await (db.delete(db.gardenPlants)
            ..where((t) => t.plantId.equals(plantId)))
          .go();
    });
  }
}

// ============================================
// PLANNING STATE CONTROLLER
// ============================================

final planningStateProvider =
    AsyncNotifierProvider<
        PlanningStateNotifier,
        PlanningState>(
  PlanningStateNotifier.new,
);

class PlanningStateNotifier
    extends AsyncNotifier<PlanningState> {
  @override
  Future<PlanningState> build() async {
    // Toutes les `ref.watch` synchroniquement avant `await` (cf.
    // règle Riverpod 3.x sur le bookkeeping pause/resume).
    final selectedPlantsFuture =
        ref.watch(selectedPlantsProvider.future);
    final datasource = ref.watch(gardenTasksDatasourceProvider);
    final initFuture = ref.read(databaseInitProvider.future);
    final db = ref.watch(databaseProvider);
    final weather = ref.watch(weatherDataProvider);

    final selectedPlants = await selectedPlantsFuture;
    final gardenTasksByMonth = await datasource.loadByMonth();

    if (selectedPlants.isEmpty) {
      return PlanningState(
        gardenTasksByMonth: gardenTasksByMonth,
        completedKeys: await _loadCompletedKeys(),
      );
    }

    await initFuture;
    final currentMonth = DateTime.now().month;

    final plantDataList = <PlantData>[];
    for (final sp in selectedPlants) {
      final plant = await db.getPlantById(
        sp.plantId,
      );
      if (plant == null) continue;

      plantDataList.add(PlantData(
        id: plant.id,
        commonName: plant.commonName,
        emoji: PlantEmojiMapper.fromName(
          plant.commonName,
          categoryCode: plant.categoryCode,
        ),
        sowingCalendar: plant.sowingCalendar,
        plantingCalendar: plant.plantingCalendar,
        harvestCalendar: plant.harvestCalendar,
        plantingMinTempC: plant.plantingMinTempC,
      ));
    }

    final plantTasksByMonth =
        ComputePlanningTasks.executeAll(
      plants: plantDataList,
      currentMonth: currentMonth,
      weather: weather.value,
    );

    return PlanningState(
      selectedPlants: selectedPlants,
      plantTasksByMonth: plantTasksByMonth,
      gardenTasksByMonth: gardenTasksByMonth,
      completedKeys: await _loadCompletedKeys(),
    );
  }

  Future<Set<String>> _loadCompletedKeys() async {
    try {
      final db = ref.read(databaseProvider);
      return db.getCompletedTaskKeys(
        year: DateTime.now().year,
      );
    } catch (_) {
      return {};
    }
  }

  void setViewMode(PlanningViewMode mode) {
    final current = state.value;
    if (current == null) return;
    // Changer de mode reset le filtre plant
    state = AsyncData(current.copyWith(
      viewMode: mode,
      clearPlantFilter: true,
    ));
  }

  void setPlantFilter(int? plantId) {
    final current = state.value;
    if (current == null) return;

    if (plantId == null
        || plantId == current.plantIdFilter) {
      state = AsyncData(current.copyWith(
        clearPlantFilter: true,
      ));
    } else {
      // Forcer le mode "mes plants" quand on
      // sélectionne un plant spécifique
      state = AsyncData(current.copyWith(
        plantIdFilter: plantId,
        viewMode: PlanningViewMode.myPlants,
      ));
    }
  }

  void setMonthFilter(int? month) {
    final current = state.value;
    if (current == null) return;

    if (month == null) {
      state = AsyncData(current.copyWith(
        clearMonthFilter: true,
      ));
    } else if (month == current.monthFilter) {
      // Re-tap sur le même mois → clear
      state = AsyncData(current.copyWith(
        clearMonthFilter: true,
      ));
    } else {
      state = AsyncData(current.copyWith(
        monthFilter: month,
      ));
    }
  }

  Future<void> toggleTask({
    required String taskKey,
    required int month,
    int? plantId,
  }) async {
    final db = ref.read(databaseProvider);
    try {
      await db.togglePlanningTask(
        taskKey: taskKey,
        year: DateTime.now().year,
        month: month,
        plantId: plantId,
      );
      final keys = await _loadCompletedKeys();
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(completedKeys: keys),
        );
      }
    } catch (e, st) {
      CrashReportingService.recordError(
        e, st,
        reason: 'togglePlanningTask',
      );
    }
  }
}
