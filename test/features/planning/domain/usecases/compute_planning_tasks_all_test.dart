import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/planning/domain/models/planning_action_type.dart';
import 'package:jardingue/features/planning/domain/usecases/compute_planning_tasks.dart';

void main() {
  final tomatoPlant = PlantData(
    id: 1,
    commonName: 'Tomate',
    emoji: '🍅',
    sowingCalendar: '{"monthly_period":'
        '{"March":"Oui (sous abri)",'
        '"April":"Oui (pleine terre)",'
        '"May":"Oui (pleine terre)"}}',
    plantingCalendar: '{"monthly_period":'
        '{"May":"Oui (après saints de glace)",'
        '"June":"Oui"}}',
    harvestCalendar: '{"monthly_period":'
        '{"July":"Oui",'
        '"August":"Oui",'
        '"September":"Oui"}}',
    plantingMinTempC: 15,
  );

  group('ComputePlanningTasks.executeAll', () {
    test(
      'retourne des tâches pour plusieurs mois',
      () {
        final result =
            ComputePlanningTasks.executeAll(
          plants: [tomatoPlant],
          currentMonth: 4,
        );

        // Mars : semis sous abri
        expect(result[3], isNotNull);
        expect(result[3], isNotEmpty);

        // Avril : semis pleine terre
        expect(result[4], isNotNull);
        expect(result[4], isNotEmpty);

        // Mai : semis + plantation
        expect(result[5], isNotNull);
        expect(result[5]!.length, greaterThan(1));

        // Juillet : récolte
        expect(result[7], isNotNull);
        expect(
          result[7]!.any(
            (t) =>
                t.actionType ==
                PlanningActionType.harvest,
          ),
          isTrue,
        );

        // Janvier : rien
        expect(result[1], isNull);
      },
    );

    test('mois sans tâches = absent de la map', () {
      final result =
          ComputePlanningTasks.executeAll(
        plants: [tomatoPlant],
        currentMonth: 6,
      );

      expect(result.containsKey(1), isFalse);
      expect(result.containsKey(2), isFalse);
      expect(result.containsKey(10), isFalse);
    });

    test('liste vide = map vide', () {
      final result =
          ComputePlanningTasks.executeAll(
        plants: [],
        currentMonth: 4,
      );

      expect(result, isEmpty);
    });

    test(
      'rétrocompatibilité execute() mois unique',
      () {
        final tasks =
            ComputePlanningTasks.execute(
          plants: [tomatoPlant],
          month: 3,
        );

        expect(tasks, isNotEmpty);
        expect(
          tasks.first.actionType,
          PlanningActionType.sowingUnderCover,
        );
      },
    );
  });
}
