import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/garden/domain/models/garden_event.dart';

void main() {
  group('GardenEventType', () {
    test('isMaintenance covers exactly the 4 maintenance types', () {
      const maintenance = {
        GardenEventType.fertilizer,
        GardenEventType.mulching,
        GardenEventType.slugControl,
        GardenEventType.treatment,
      };
      for (final t in GardenEventType.values) {
        expect(t.isMaintenance, maintenance.contains(t),
            reason: '$t.isMaintenance unexpected');
      }
    });

    test('maintenance types are not sowing types', () {
      for (final t in GardenEventType.values.where((t) => t.isMaintenance)) {
        expect(t.isSowing, isFalse, reason: '$t should not be sowing');
      }
    });

    test('fromString round-trips for all values, including new ones', () {
      for (final t in GardenEventType.values) {
        expect(GardenEventType.fromString(t.name), t);
      }
    });

    test('fromString falls back to watering on unknown', () {
      expect(GardenEventType.fromString('not_a_type'),
          GardenEventType.watering);
    });
  });

  group('GardenEventWithDetails', () {
    GardenEvent makeRawEvent({
      required String type,
      int? gardenPlantId,
      int? plantId,
      int? gardenId,
    }) {
      return GardenEvent(
        id: 1,
        gardenPlantId: gardenPlantId,
        plantId: plantId,
        gardenId: gardenId,
        eventType: type,
        eventDate: DateTime(2026, 4, 1),
        createdAt: DateTime(2026, 4, 1),
      );
    }

    test('hasGarden true when garden is non-null even without gardenPlant',
        () {
      final garden = Garden(
        id: 7,
        name: 'Mon potager',
        widthCells: 10,
        heightCells: 10,
        cellSizeCm: 10,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final detail = GardenEventWithDetails(
        event: makeRawEvent(type: 'mulching', gardenId: 7),
        garden: garden,
      );
      expect(detail.hasGarden, isTrue);
      expect(detail.gardenName, 'Mon potager');
    });

    test('hasGarden false when no garden at all', () {
      final detail = GardenEventWithDetails(
        event: makeRawEvent(type: 'mulching'),
      );
      expect(detail.hasGarden, isFalse);
      expect(detail.gardenName, '');
    });

    test('displayTitle uses type label when no plant for maintenance', () {
      final detail = GardenEventWithDetails(
        event: makeRawEvent(type: 'mulching'),
      );
      expect(detail.displayTitle, 'Paillage');
    });

    test('displayTitle uses plant name when available', () {
      final plant = Plant(
        id: 1,
        commonName: 'Tomate',
        categoryCode: 'fruit',
        isUserModified: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final detail = GardenEventWithDetails(
        event: makeRawEvent(type: 'watering', plantId: 1),
        plant: plant,
      );
      expect(detail.displayTitle, 'Tomate');
    });

    test('displayTitle falls back to "Plante inconnue" for non-maintenance '
        'event without plant', () {
      final detail = GardenEventWithDetails(
        event: makeRawEvent(type: 'watering'),
      );
      expect(detail.displayTitle, 'Plante inconnue');
    });
  });
}
