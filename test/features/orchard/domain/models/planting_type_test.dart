import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/orchard/domain/models/planting_type.dart';

void main() {
  group('PlantingType', () {
    test('dbValue is stable for each variant', () {
      expect(PlantingType.ground.dbValue, 'ground');
      expect(PlantingType.pot.dbValue, 'pot');
      expect(PlantingType.espalier.dbValue, 'espalier');
    });

    test('label and emoji are localized FR', () {
      expect(PlantingType.ground.emoji, '🌱');
      expect(PlantingType.ground.label, 'Pleine terre');
      expect(PlantingType.pot.emoji, '🪴');
      expect(PlantingType.pot.label, 'En pot');
      expect(PlantingType.espalier.emoji, '🧱');
      expect(PlantingType.espalier.label, 'Espalier / Palissé');
    });

    test('fromDbValue maps known strings', () {
      expect(PlantingType.fromDbValue('ground'), PlantingType.ground);
      expect(PlantingType.fromDbValue('pot'), PlantingType.pot);
      expect(PlantingType.fromDbValue('espalier'), PlantingType.espalier);
    });

    test('fromDbValue returns null when input is null', () {
      expect(PlantingType.fromDbValue(null), isNull);
    });

    test('fromDbValue falls back to ground for unknown values', () {
      expect(PlantingType.fromDbValue('greenhouse'), PlantingType.ground);
      expect(PlantingType.fromDbValue(''), PlantingType.ground);
    });
  });
}
