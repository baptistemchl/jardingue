import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/garden/domain/models/zone_type.dart';

void main() {
  group('ZoneType', () {
    test('fromName returns correct type', () {
      expect(
        ZoneType.fromName('greenhouse'),
        ZoneType.greenhouse,
      );
      expect(
        ZoneType.fromName('compost'),
        ZoneType.compost,
      );
      expect(
        ZoneType.fromName('path'),
        ZoneType.path,
      );
    });

    test('fromName returns null for null', () {
      expect(ZoneType.fromName(null), isNull);
    });

    test('fromName returns null for unknown', () {
      expect(ZoneType.fromName('unknown'), isNull);
    });

    test('all values have non-empty labels', () {
      for (final type in ZoneType.values) {
        expect(type.label, isNotEmpty);
        expect(type.emoji, isNotEmpty);
        expect(type.color, isNonZero);
      }
    });
  });
}
