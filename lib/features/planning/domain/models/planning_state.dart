import 'garden_task_data.dart';
import 'planning_task.dart';
import 'selected_plant.dart';
import 'task_urgency.dart';

/// Mode d'affichage de la planification.
enum PlanningViewMode {
  all('Tout'),
  myPlants('Mes plants'),
  gardenTasks('Tâches potagères');

  final String label;
  const PlanningViewMode(this.label);
}

class PlanningState {
  final List<SelectedPlant> selectedPlants;
  final Map<int, List<PlanningTask>>
      plantTasksByMonth;
  final Map<int, List<GardenTaskData>>
      gardenTasksByMonth;
  final Set<String> completedKeys;
  final int? monthFilter;
  final int? plantIdFilter;
  final PlanningViewMode viewMode;

  const PlanningState({
    this.selectedPlants = const [],
    this.plantTasksByMonth = const {},
    this.gardenTasksByMonth = const {},
    this.completedKeys = const {},
    this.monthFilter,
    this.plantIdFilter,
    this.viewMode = PlanningViewMode.all,
  });

  PlanningState copyWith({
    List<SelectedPlant>? selectedPlants,
    Map<int, List<PlanningTask>>?
        plantTasksByMonth,
    Map<int, List<GardenTaskData>>?
        gardenTasksByMonth,
    Set<String>? completedKeys,
    int? monthFilter,
    bool clearMonthFilter = false,
    int? plantIdFilter,
    bool clearPlantFilter = false,
    PlanningViewMode? viewMode,
  }) {
    return PlanningState(
      selectedPlants:
          selectedPlants ?? this.selectedPlants,
      plantTasksByMonth: plantTasksByMonth ??
          this.plantTasksByMonth,
      gardenTasksByMonth: gardenTasksByMonth ??
          this.gardenTasksByMonth,
      completedKeys:
          completedKeys ?? this.completedKeys,
      monthFilter: clearMonthFilter
          ? null
          : (monthFilter ?? this.monthFilter),
      plantIdFilter: clearPlantFilter
          ? null
          : (plantIdFilter ?? this.plantIdFilter),
      viewMode: viewMode ?? this.viewMode,
    );
  }

  bool get hasPlantFilter =>
      plantIdFilter != null;

  /// Mois actifs selon le mode de vue.
  List<int> get activeMonths {
    final months = <int>{};

    final showPlants =
        viewMode == PlanningViewMode.all ||
        viewMode == PlanningViewMode.myPlants;
    final showGarden =
        viewMode == PlanningViewMode.all ||
        viewMode == PlanningViewMode.gardenTasks;

    if (showPlants) {
      months.addAll(plantTasksByMonth.keys);
    }
    if (showGarden) {
      months.addAll(gardenTasksByMonth.keys);
    }

    final sorted = months.toList()..sort();
    if (monthFilter != null) {
      return sorted
          .where((m) => m == monthFilter)
          .toList();
    }
    return sorted;
  }

  /// Tâches plant pour un mois.
  List<PlanningTask> plantTasksForMonth(
    int month,
  ) {
    if (viewMode ==
        PlanningViewMode.gardenTasks) {
      return [];
    }

    var tasks =
        plantTasksByMonth[month] ?? [];
    if (plantIdFilter != null) {
      tasks = tasks
          .where(
            (t) => t.plantId == plantIdFilter,
          )
          .toList();
    }
    return tasks;
  }

  /// Tâches potagères pour un mois.
  List<GardenTaskData> gardenTasksForMonth(
    int month,
  ) {
    if (viewMode == PlanningViewMode.myPlants) {
      return [];
    }
    return gardenTasksByMonth[month] ?? [];
  }

  bool isCompleted(String taskKey, int month) {
    return completedKeys.contains(
      '${taskKey}_$month',
    );
  }

  int get totalPlantTasks =>
      plantTasksByMonth.values.fold(
        0,
        (sum, list) => sum + list.length,
      );

  int get totalGardenTasks =>
      gardenTasksByMonth.values.fold(
        0,
        (sum, list) => sum + list.length,
      );

  List<PlanningTask> get urgentPlantTasks {
    return plantTasksByMonth.values
        .expand((list) => list)
        .where(
          (t) => t.urgency == TaskUrgency.now,
        )
        .toList();
  }
}
