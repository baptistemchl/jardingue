import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/planning/domain/models/garden_task_data.dart';

void main() {
  group('GardenTaskData', () {
    test('fromJson parse correctement', () {
      final json = {
        'id': 'jan_plan_garden',
        'title': 'Planifier le potager',
        'description': 'Commander les graines',
        'category': 'planning',
        'months': [1, 2],
        'priority': 'high',
      };

      final task = GardenTaskData.fromJson(json);

      expect(task.id, 'jan_plan_garden');
      expect(task.title, 'Planifier le potager');
      expect(
        task.category,
        GardenTaskCategory.planning,
      );
      expect(task.months, [1, 2]);
      expect(task.priority, 'high');
      expect(task.conditions, isNull);
    });

    test(
      'fromJson avec conditions',
      () {
        final json = {
          'id': 'mar_turn_soil',
          'title': 'Retourner le sol',
          'description': 'Bêcher les parcelles',
          'category': 'soil',
          'months': [3, 10, 11],
          'priority': 'high',
          'conditions': {
            'min_temp': 5,
            'requires_dry': true,
          },
        };

        final task =
            GardenTaskData.fromJson(json);

        expect(task.conditions, isNotNull);
        expect(task.conditions!.minTemp, 5.0);
        expect(
          task.conditions!.requiresDry,
          isTrue,
        );
      },
    );

    test('appliesToMonth fonctionne', () {
      final task = GardenTaskData(
        id: 'test',
        title: 'Test',
        description: 'Test',
        category: GardenTaskCategory.soil,
        months: [3, 4, 5],
        priority: 'medium',
      );

      expect(task.appliesToMonth(2), isFalse);
      expect(task.appliesToMonth(3), isTrue);
      expect(task.appliesToMonth(5), isTrue);
      expect(task.appliesToMonth(6), isFalse);
    });

    test(
      'catégorie inconnue → maintenance',
      () {
        final json = {
          'id': 'test',
          'title': 'Test',
          'description': 'Test',
          'category': 'unknown_category',
          'months': [1],
        };

        final task =
            GardenTaskData.fromJson(json);
        expect(
          task.category,
          GardenTaskCategory.maintenance,
        );
      },
    );

    test('priority par défaut = medium', () {
      final json = {
        'id': 'test',
        'title': 'Test',
        'description': 'Test',
        'category': 'soil',
        'months': [1],
      };

      final task = GardenTaskData.fromJson(json);
      expect(task.priority, 'medium');
    });
  });

  group('GardenTaskCategory', () {
    test('fromString trouve la catégorie', () {
      expect(
        GardenTaskCategory.fromString('soil'),
        GardenTaskCategory.soil,
      );
      expect(
        GardenTaskCategory.fromString(
          'greenhouse',
        ),
        GardenTaskCategory.greenhouse,
      );
    });

    test('fromString retourne null si inconnu', () {
      expect(
        GardenTaskCategory.fromString('nope'),
        isNull,
      );
    });
  });
}
