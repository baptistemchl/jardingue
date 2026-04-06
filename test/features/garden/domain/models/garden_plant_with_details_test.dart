import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/garden/domain/models/zone_type.dart';
import 'package:jardingue/core/utils/plant_emoji_mapper.dart';

void main() {
  group('ZoneType integration', () {
    test('all zone types have valid color values', () {
      for (final zone in ZoneType.values) {
        expect(zone.color, isNonZero);
        expect(zone.label, isNotEmpty);
        expect(zone.emoji, isNotEmpty);
      }
    });

    test('roundtrip fromName for all values', () {
      for (final zone in ZoneType.values) {
        expect(
          ZoneType.fromName(zone.name),
          zone,
        );
      }
    });
  });

  group('PlantEmojiMapper coverage', () {
    test('all category codes return non-fallback', () {
      final codes = [
        'fruit_vegetable',
        'leafy_green',
        'root',
        'tuber',
        'allium',
        'legume',
        'herb',
        'fruit',
        'stem',
        'flower',
        'grain',
      ];
      for (final code in codes) {
        expect(
          PlantEmojiMapper.fromCategory(code),
          isNot(PlantEmojiMapper.fallback),
          reason: 'Failed for $code',
        );
      }
    });

    test('courge family all map correctly', () {
      final courges = [
        'Courge',
        'Potiron',
        'Potimarron',
        'Citrouille',
        'Butternut',
        'Patisson',
      ];
      for (final name in courges) {
        expect(
          PlantEmojiMapper.fromName(name),
          '\u{1F383}',
          reason: 'Failed for $name',
        );
      }
    });

    test('aromates all map to herb emoji', () {
      final herbs = [
        'Basilic',
        'Persil',
        'Thym',
        'Romarin',
        'Menthe',
        'Ciboulette',
        'Coriandre',
        'Aneth',
      ];
      for (final name in herbs) {
        expect(
          PlantEmojiMapper.fromName(name),
          '\u{1F33F}',
          reason: 'Failed for $name',
        );
      }
    });
  });
}
