import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/orchard/domain/models/fruit_trees_filter_state.dart';

void main() {
  group('FruitTreesFilterState', () {
    test('default state has no active filters', () {
      const state = FruitTreesFilterState();
      expect(state.hasActiveFilters, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      const original = FruitTreesFilterState(
        searchQuery: 'pommier',
        category: FruitTreeCategory.arbreFruitier,
      );

      final updated = original.copyWith(
        searchQuery: 'cerisier',
      );

      expect(updated.searchQuery, 'cerisier');
      expect(
        updated.category,
        FruitTreeCategory.arbreFruitier,
      );
    });

    test('hasActiveFilters detects filters', () {
      expect(
        const FruitTreesFilterState(
          searchQuery: 'test',
        ).hasActiveFilters,
        isTrue,
      );
      expect(
        const FruitTreesFilterState(
          category: FruitTreeCategory.petitFruit,
        ).hasActiveFilters,
        isTrue,
      );
      expect(
        const FruitTreesFilterState(
          selfFertileOnly: true,
        ).hasActiveFilters,
        isTrue,
      );
      expect(
        const FruitTreesFilterState(
          containerSuitableOnly: true,
        ).hasActiveFilters,
        isTrue,
      );
    });
  });

  group('FruitTreeCategory', () {
    test('fromCode returns correct category', () {
      expect(
        FruitTreeCategory.fromCode('arbre_fruitier'),
        FruitTreeCategory.arbreFruitier,
      );
    });

    test('fromCode returns all for null', () {
      expect(
        FruitTreeCategory.fromCode(null),
        FruitTreeCategory.all,
      );
    });

    test('fromCode returns all for unknown', () {
      expect(
        FruitTreeCategory.fromCode('nope'),
        FruitTreeCategory.all,
      );
    });
  });
}
