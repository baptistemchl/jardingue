import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/orchard_providers.dart';

void main() {
  group('FruitTreesFilterNotifier', () {
    late ProviderContainer container;
    late FruitTreesFilterNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(fruitTreesFilterProvider.notifier);
    });
    tearDown(() => container.dispose());

    test('initial state has no filters', () {
      final state = container.read(fruitTreesFilterProvider);
      expect(state.hasActiveFilters, isFalse);
    });

    test('setSearchQuery updates state', () {
      notifier.setSearchQuery('pommier');
      final state = container.read(fruitTreesFilterProvider);
      expect(state.searchQuery, 'pommier');
      expect(state.hasActiveFilters, isTrue);
    });

    test('setCategory updates state', () {
      notifier.setCategory(
        FruitTreeCategory.arbreFruitier,
      );
      expect(
        container.read(fruitTreesFilterProvider).category,
        FruitTreeCategory.arbreFruitier,
      );
    });

    test('setSelfFertileOnly updates state', () {
      notifier.setSelfFertileOnly(true);
      final state = container.read(fruitTreesFilterProvider);
      expect(state.selfFertileOnly, isTrue);
      expect(state.hasActiveFilters, isTrue);
    });

    test('setContainerSuitableOnly updates state', () {
      notifier.setContainerSuitableOnly(true);
      expect(
        container.read(fruitTreesFilterProvider).containerSuitableOnly,
        isTrue,
      );
    });

    test('clearFilters resets to default', () {
      notifier.setSearchQuery('cerisier');
      notifier.setCategory(
        FruitTreeCategory.petitFruit,
      );
      notifier.setSelfFertileOnly(true);

      notifier.clearFilters();

      final state = container.read(fruitTreesFilterProvider);
      expect(state.hasActiveFilters, isFalse);
      expect(state.searchQuery, isEmpty);
      expect(state.category, FruitTreeCategory.all);
      expect(state.selfFertileOnly, isNull);
    });
  });
}
