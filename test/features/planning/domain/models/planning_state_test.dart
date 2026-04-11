import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/planning/domain/models/planning_action_type.dart';
import 'package:jardingue/features/planning/domain/models/planning_state.dart';
import 'package:jardingue/features/planning/domain/models/planning_task.dart';
import 'package:jardingue/features/planning/domain/models/task_urgency.dart';

void main() {
  final task1 = PlanningTask(
    plantId: 1,
    plantName: 'Tomate',
    plantEmoji: '🍅',
    actionType:
        PlanningActionType.sowingOpenGround,
    urgency: TaskUrgency.now,
    message: 'Semis pleine terre',
  );

  final task2 = PlanningTask(
    plantId: 2,
    plantName: 'Carotte',
    plantEmoji: '🥕',
    actionType: PlanningActionType.planting,
    urgency: TaskUrgency.soon,
    message: 'Plantation',
  );

  final task3 = PlanningTask(
    plantId: 1,
    plantName: 'Tomate',
    plantEmoji: '🍅',
    actionType: PlanningActionType.harvest,
    urgency: TaskUrgency.blocked,
    message: 'Récolte',
    blockedByWeather: true,
    weatherReason: 'Trop froid',
  );

  group('PlanningState', () {
    test(
      'plantTasksForMonth retourne tout '
      'en mode all',
      () {
        final state = PlanningState(
          plantTasksByMonth: {
            4: [task1, task2],
            7: [task3],
          },
        );

        expect(
          state.plantTasksForMonth(4).length,
          2,
        );
        expect(
          state.plantTasksForMonth(7).length,
          1,
        );
        expect(
          state.plantTasksForMonth(1).length,
          0,
        );
      },
    );

    test(
      'plantTasksForMonth filtre par plantId',
      () {
        final state = PlanningState(
          plantTasksByMonth: {
            4: [task1, task2],
          },
          plantIdFilter: 2,
          viewMode: PlanningViewMode.myPlants,
        );

        final tasks =
            state.plantTasksForMonth(4);
        expect(tasks.length, 1);
        expect(
          tasks.first.plantName,
          'Carotte',
        );
      },
    );

    test(
      'mode gardenTasks masque les plant tasks',
      () {
        final state = PlanningState(
          plantTasksByMonth: {4: [task1]},
          viewMode: PlanningViewMode.gardenTasks,
        );

        expect(
          state.plantTasksForMonth(4).length,
          0,
        );
      },
    );

    test(
      'mode myPlants masque les garden tasks',
      () {
        final state = PlanningState(
          gardenTasksByMonth: {4: []},
          viewMode: PlanningViewMode.myPlants,
        );

        expect(
          state.gardenTasksForMonth(4).length,
          0,
        );
      },
    );

    test(
      'activeMonths retourne les bons mois',
      () {
        final state = PlanningState(
          plantTasksByMonth: {
            3: [task1],
            7: [task3],
          },
          gardenTasksByMonth: {
            1: [],
            3: [],
          },
        );

        expect(
          state.activeMonths,
          [1, 3, 7],
        );
      },
    );

    test(
      'activeMonths avec filtre mois',
      () {
        final state = PlanningState(
          plantTasksByMonth: {
            3: [task1],
            7: [task3],
          },
          monthFilter: 3,
        );

        expect(state.activeMonths, [3]);
      },
    );

    test(
      'activeMonths mode gardenTasks '
      'exclut les mois plants-only',
      () {
        final state = PlanningState(
          plantTasksByMonth: {5: [task1]},
          gardenTasksByMonth: {10: []},
          viewMode: PlanningViewMode.gardenTasks,
        );

        expect(state.activeMonths, [10]);
      },
    );

    test('isCompleted vérifie les clés', () {
      final state = PlanningState(
        completedKeys: {'task1_3', 'task2_7'},
      );

      expect(
        state.isCompleted('task1', 3),
        isTrue,
      );
      expect(
        state.isCompleted('task2', 7),
        isTrue,
      );
      expect(
        state.isCompleted('task1', 7),
        isFalse,
      );
    });

    test('copyWith conserve les valeurs', () {
      final state = PlanningState(
        plantTasksByMonth: {4: [task1]},
        monthFilter: 4,
      );

      final updated = state.copyWith(
        plantTasksByMonth: {
          4: [task1, task2],
        },
      );

      expect(
        updated.plantTasksByMonth[4]!.length,
        2,
      );
      expect(updated.monthFilter, 4);
    });

    test('copyWith clearMonthFilter', () {
      final state = PlanningState(
        monthFilter: 4,
      );

      final cleared = state.copyWith(
        clearMonthFilter: true,
      );

      expect(cleared.monthFilter, isNull);
    });

    test('copyWith clearPlantFilter', () {
      final state = PlanningState(
        plantIdFilter: 1,
      );

      final cleared = state.copyWith(
        clearPlantFilter: true,
      );

      expect(cleared.plantIdFilter, isNull);
    });

    test('copyWith viewMode', () {
      final state = PlanningState();

      final updated = state.copyWith(
        viewMode: PlanningViewMode.myPlants,
      );

      expect(
        updated.viewMode,
        PlanningViewMode.myPlants,
      );
    });

    test(
      'totalPlantTasks compte tous les mois',
      () {
        final state = PlanningState(
          plantTasksByMonth: {
            3: [task1, task2],
            7: [task3],
          },
        );

        expect(state.totalPlantTasks, 3);
      },
    );

    test('urgentPlantTasks filtre now', () {
      final state = PlanningState(
        plantTasksByMonth: {
          4: [task1, task2, task3],
        },
      );

      expect(
        state.urgentPlantTasks.length,
        1,
      );
      expect(
        state.urgentPlantTasks.first.urgency,
        TaskUrgency.now,
      );
    });
  });
}
