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
// SELECTED PLANTS CONTROLLER
// ============================================

final selectedPlantsProvider =
    AsyncNotifierProvider<
        SelectedPlantsNotifier,
        List<SelectedPlant>>(
  SelectedPlantsNotifier.new,
);

class SelectedPlantsNotifier
    extends AsyncNotifier<List<SelectedPlant>> {
  @override
  Future<List<SelectedPlant>> build() async {
    final repo = ref.watch(
      planningRepositoryProvider,
    );
    try {
      return await repo.getSelectedPlants();
    } catch (e, st) {
      CrashReportingService.recordError(
        e, st,
        reason: 'selectedPlantsProvider.build',
      );
      rethrow;
    }
  }

  Future<void> add(int plantId) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(
        planningRepositoryProvider,
      );
      await repo.addSelectedPlant(plantId);
      return repo.getSelectedPlants();
    });
  }

  Future<void> remove(int plantId) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(
        planningRepositoryProvider,
      );
      await repo.removeSelectedPlant(plantId);
      return repo.getSelectedPlants();
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

    await ref.watch(databaseInitProvider.future);
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
      weather: weather.valueOrNull,
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
    final current = state.valueOrNull;
    if (current == null) return;
    // Changer de mode reset le filtre plant
    state = AsyncData(current.copyWith(
      viewMode: mode,
      clearPlantFilter: true,
    ));
  }

  void setPlantFilter(int? plantId) {
    final current = state.valueOrNull;
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
    final current = state.valueOrNull;
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
      final current = state.valueOrNull;
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
