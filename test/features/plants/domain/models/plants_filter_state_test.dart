import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/plants/domain/models/plants_filter_state.dart';

void main() {
  group('PlantsFilterState', () {
    test('default state has no active filters', () {
      const state = PlantsFilterState();
      expect(state.hasActiveFilters, isFalse);
      expect(state.searchQuery, isEmpty);
      expect(state.category, PlantCategory.all);
      expect(state.sunFilter, PlantSunFilter.all);
    });

    test('copyWith preserves unchanged fields', () {
      const original = PlantsFilterState(
        searchQuery: 'tomate',
        category: PlantCategory.herb,
        sunFilter: PlantSunFilter.fullSun,
      );

      final updated = original.copyWith(
        searchQuery: 'carotte',
      );

      expect(updated.searchQuery, 'carotte');
      expect(updated.category, PlantCategory.herb);
      expect(updated.sunFilter, PlantSunFilter.fullSun);
    });

    test('hasActiveFilters detects search query', () {
      const state = PlantsFilterState(
        searchQuery: 'test',
      );
      expect(state.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters detects category', () {
      const state = PlantsFilterState(
        category: PlantCategory.root,
      );
      expect(state.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters detects sun filter', () {
      const state = PlantsFilterState(
        sunFilter: PlantSunFilter.shade,
      );
      expect(state.hasActiveFilters, isTrue);
    });

    test('equality works correctly', () {
      const a = PlantsFilterState(searchQuery: 'x');
      const b = PlantsFilterState(searchQuery: 'x');
      const c = PlantsFilterState(searchQuery: 'y');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('PlantCategory', () {
    test('fromCode returns correct category', () {
      expect(
        PlantCategory.fromCode('herb'),
        PlantCategory.herb,
      );
      expect(
        PlantCategory.fromCode('root'),
        PlantCategory.root,
      );
    });

    test('fromCode returns all for null', () {
      expect(
        PlantCategory.fromCode(null),
        PlantCategory.all,
      );
    });

    test('fromCode returns all for unknown code', () {
      expect(
        PlantCategory.fromCode('nope'),
        PlantCategory.all,
      );
    });

    test('displayLabel includes emoji', () {
      expect(
        PlantCategory.herb.displayLabel,
        contains(PlantCategory.herb.emoji),
      );
    });
  });
}
