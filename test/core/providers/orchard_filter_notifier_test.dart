import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/orchard_providers.dart';

void main() {
  group('FruitTreesFilterNotifier', () {
    late FruitTreesFilterNotifier notifier;

    setUp(() => notifier = FruitTreesFilterNotifier());
    tearDown(() => notifier.dispose());

    test('initial state has no filters', () {
      expect(notifier.state.hasActiveFilters, isFalse);
    });

    test('setSearchQuery updates state', () {
      notifier.setSearchQuery('pommier');
      expect(notifier.state.searchQuery, 'pommier');
      expect(notifier.state.hasActiveFilters, isTrue);
    });

    test('setCategory updates state', () {
      notifier.setCategory(
        FruitTreeCategory.arbreFruitier,
      );
      expect(
        notifier.state.category,
        FruitTreeCategory.arbreFruitier,
      );
    });

    test('setSelfFertileOnly updates state', () {
      notifier.setSelfFertileOnly(true);
      expect(
        notifier.state.selfFertileOnly,
        isTrue,
      );
      expect(notifier.state.hasActiveFilters, isTrue);
    });

    test('setContainerSuitableOnly updates state', () {
      notifier.setContainerSuitableOnly(true);
      expect(
        notifier.state.containerSuitableOnly,
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

      expect(notifier.state.hasActiveFilters, isFalse);
      expect(notifier.state.searchQuery, isEmpty);
      expect(
        notifier.state.category,
        FruitTreeCategory.all,
      );
      expect(notifier.state.selfFertileOnly, isNull);
    });
  });
}
