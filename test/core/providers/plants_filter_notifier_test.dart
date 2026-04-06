import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';

void main() {
  group('PlantsFilterNotifier', () {
    late PlantsFilterNotifier notifier;

    setUp(() => notifier = PlantsFilterNotifier());
    tearDown(() => notifier.dispose());

    test('initial state has no filters', () {
      expect(notifier.state.hasActiveFilters, isFalse);
      expect(notifier.state.searchQuery, isEmpty);
    });

    test('setSearchQuery updates state', () {
      notifier.setSearchQuery('tomate');
      expect(notifier.state.searchQuery, 'tomate');
      expect(notifier.state.hasActiveFilters, isTrue);
    });

    test('setCategory updates state', () {
      notifier.setCategory(PlantCategory.herb);
      expect(
        notifier.state.category,
        PlantCategory.herb,
      );
      expect(notifier.state.hasActiveFilters, isTrue);
    });

    test('setSunFilter updates state', () {
      notifier.setSunFilter(PlantSunFilter.shade);
      expect(
        notifier.state.sunFilter,
        PlantSunFilter.shade,
      );
      expect(notifier.state.hasActiveFilters, isTrue);
    });

    test('clearFilters resets to default', () {
      notifier.setSearchQuery('test');
      notifier.setCategory(PlantCategory.root);
      notifier.setSunFilter(PlantSunFilter.fullSun);

      notifier.clearFilters();

      expect(notifier.state.hasActiveFilters, isFalse);
      expect(notifier.state.searchQuery, isEmpty);
      expect(
        notifier.state.category,
        PlantCategory.all,
      );
      expect(
        notifier.state.sunFilter,
        PlantSunFilter.all,
      );
    });

    test('preserves other filters when setting one', () {
      notifier.setSearchQuery('tomate');
      notifier.setCategory(PlantCategory.herb);

      notifier.setSunFilter(PlantSunFilter.fullSun);

      expect(notifier.state.searchQuery, 'tomate');
      expect(
        notifier.state.category,
        PlantCategory.herb,
      );
      expect(
        notifier.state.sunFilter,
        PlantSunFilter.fullSun,
      );
    });
  });
}
