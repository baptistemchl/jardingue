import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/planning/data/datasources/garden_tasks_datasource.dart';
import '../../features/planning/data/repositories/planning_repository.dart';
import '../../features/planning/domain/models/planning_state.dart';
import '../../features/planning/domain/models/selected_plant.dart';
import '../../features/planning/domain/repositories/planning_repository_interface.dart';
import '../../features/planning/domain/usecases/compute_planning_tasks.dart';
import '../services/crash_reporting/crash_reporting_service.dart';
import '../utils/plant_emoji_mapper.dart';
import 'database_providers.dart';
import 'weather_providers.dart';

// ============================================
// REPOSITORY
// ============================================

final planningRepositoryProvider =
    Provider<PlanningRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return PlanningRepositoryImpl(db);
});

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

/// Stream brut des lignes `selected_plants` (sélection manuelle via
/// l'écran Plantes).
final _manualSelectedPlantsStream = StreamProvider<List<SelectedPlant>>(
  (ref) async* {
    await ref.read(databaseInitProvider.future);
    final db = ref.watch(databaseProvider);
    yield* db.watchSelectedPlants().map((rows) => rows.map((row) {
          final sp = row.readTable(db.selectedPlantsTable);
          final plant = row.readTable(db.plants);
          return SelectedPlant(
            plantId: sp.plantId,
            commonName: plant.commonName,
            categoryCode: plant.categoryCode,
            addedAt: sp.addedAt,
          );
        }).toList());
  },
);

/// Stream brut : plantes posées sur n'importe quel potager, converties
/// en `SelectedPlant` (les zones `plantId=0` sont exclues).
final _gardenDerivedSelectedPlantsStream =
    StreamProvider<List<SelectedPlant>>((ref) async* {
  await ref.read(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
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

/// Union des deux sources : les sélections manuelles gagnent sur les
/// dérivées (même plantId) pour préserver leur date d'ajout originale.
///
/// Réactif par construction : dès qu'une ligne bouge dans
/// `selected_plants` ou `garden_plants`, ce provider ré-émet.
final selectedPlantsProvider =
    AsyncNotifierProvider<SelectedPlantsNotifier, List<SelectedPlant>>(
  SelectedPlantsNotifier.new,
);

class SelectedPlantsNotifier extends AsyncNotifier<List<SelectedPlant>> {
  @override
  Future<List<SelectedPlant>> build() async {
    try {
      final manual = await ref.watch(_manualSelectedPlantsStream.future);
      final garden =
          await ref.watch(_gardenDerivedSelectedPlantsStream.future);
      final merged = <int, SelectedPlant>{};
      for (final p in garden) {
        merged[p.plantId] = p;
      }
      for (final p in manual) {
        merged[p.plantId] = p; // priorité à la sélection manuelle
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

  Future<void> add(int plantId) async {
    final repo = ref.read(planningRepositoryProvider);
    await repo.addSelectedPlant(plantId);
    // Pas besoin d'update local : le stream `.watch()` se chargera
    // de pousser la nouvelle valeur au prochain tick DB.
  }

  Future<void> remove(int plantId) async {
    final repo = ref.read(planningRepositoryProvider);
    await repo.removeSelectedPlant(plantId);
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
    final selectedPlants = await ref.watch(
      selectedPlantsProvider.future,
    );

    // Charger les tâches potagères JSON
    final datasource = ref.watch(
      gardenTasksDatasourceProvider,
    );
    final gardenTasksByMonth =
        await datasource.loadByMonth();

    if (selectedPlants.isEmpty) {
      return PlanningState(
        gardenTasksByMonth: gardenTasksByMonth,
        completedKeys: await _loadCompletedKeys(),
      );
    }

    await ref.read(databaseInitProvider.future);
    final db = ref.watch(databaseProvider);
    final weather = ref.watch(weatherDataProvider);
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
