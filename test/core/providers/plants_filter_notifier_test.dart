import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';

void main() {
  group('PlantsFilterNotifier', () {
    late ProviderContainer container;
    late PlantsFilterNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(plantsFilterProvider.notifier);
    });
    tearDown(() => container.dispose());

    test('initial state has no filters', () {
      final state = container.read(plantsFilterProvider);
      expect(state.hasActiveFilters, isFalse);
      expect(state.searchQuery, isEmpty);
    });

    test('setSearchQuery updates state', () {
      notifier.setSearchQuery('tomate');
      final state = container.read(plantsFilterProvider);
      expect(state.searchQuery, 'tomate');
      expect(state.hasActiveFilters, isTrue);
    });

    test('setCategory updates state', () {
      notifier.setCategory(PlantCategory.herb);
      final state = container.read(plantsFilterProvider);
      expect(state.category, PlantCategory.herb);
      expect(state.hasActiveFilters, isTrue);
    });

    test('setSunFilter updates state', () {
      notifier.setSunFilter(PlantSunFilter.shade);
      final state = container.read(plantsFilterProvider);
      expect(state.sunFilter, PlantSunFilter.shade);
      expect(state.hasActiveFilters, isTrue);
    });

    test('clearFilters resets to default', () {
      notifier.setSearchQuery('test');
      notifier.setCategory(PlantCategory.root);
      notifier.setSunFilter(PlantSunFilter.fullSun);

      notifier.clearFilters();

      final state = container.read(plantsFilterProvider);
      expect(state.hasActiveFilters, isFalse);
      expect(state.searchQuery, isEmpty);
      expect(state.category, PlantCategory.all);
      expect(state.sunFilter, PlantSunFilter.all);
    });

    test('preserves other filters when setting one', () {
      notifier.setSearchQuery('tomate');
      notifier.setCategory(PlantCategory.herb);

      notifier.setSunFilter(PlantSunFilter.fullSun);

      final state = container.read(plantsFilterProvider);
      expect(state.searchQuery, 'tomate');
      expect(state.category, PlantCategory.herb);
      expect(state.sunFilter, PlantSunFilter.fullSun);
    });
  });
}
