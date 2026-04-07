import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/premium/data/dto/backup_dto.dart';
import 'package:jardingue/features/premium/domain/models/backup_data.dart';
import 'package:jardingue/features/premium/domain/models/backup_metadata.dart';

void main() {
  group('BackupDto', () {
    final sampleData = BackupData(
      metadata: BackupMetadata(
        createdAt: DateTime(2026, 4, 7, 12, 0),
        gardenCount: 2,
        plantCount: 5,
        eventCount: 10,
        treeCount: 1,
      ),
      gardens: [
        {'id': 1, 'name': 'Potager principal'},
      ],
      gardenPlants: [
        {'id': 1, 'gardenId': 1, 'plantId': 42},
      ],
      gardenEvents: [
        {'id': 1, 'eventType': 'watering'},
      ],
      userFruitTrees: [
        {'id': 1, 'fruitTreeId': 7},
      ],
    );

    test(
      'toFirestore produces valid JSON structure',
      () {
        final json = BackupDto.toFirestore(sampleData);

        expect(json['metadata'], isA<Map>());
        expect(
          json['metadata']['gardenCount'],
          equals(2),
        );
        expect(json['gardens'], isA<List>());
        expect(json['gardenPlants'], isA<List>());
        expect(json['gardenEvents'], isA<List>());
        expect(json['userFruitTrees'], isA<List>());
      },
    );

    test(
      'fromFirestore roundtrips correctly',
      () {
        final json = BackupDto.toFirestore(sampleData);
        final restored = BackupDto.fromFirestore(json);

        expect(
          restored.metadata.gardenCount,
          equals(2),
        );
        expect(
          restored.metadata.plantCount,
          equals(5),
        );
        expect(restored.gardens.length, equals(1));
        expect(
          restored.gardens.first['name'],
          equals('Potager principal'),
        );
      },
    );

    test(
      'metadataFromFirestore parses correctly',
      () {
        final meta = BackupDto.metadataFromFirestore({
          'createdAt': '2026-04-07T12:00:00.000',
          'gardenCount': 3,
          'plantCount': 7,
          'eventCount': 20,
          'treeCount': 0,
        });

        expect(meta.gardenCount, equals(3));
        expect(meta.totalItems, equals(30));
      },
    );

    test(
      'fromFirestore handles missing lists gracefully',
      () {
        final data = BackupDto.fromFirestore({
          'metadata': {
            'createdAt': '2026-04-07T12:00:00.000',
            'gardenCount': 0,
            'plantCount': 0,
            'eventCount': 0,
            'treeCount': 0,
          },
          // pas de gardens, gardenPlants, etc.
        });

        expect(data.gardens, isEmpty);
        expect(data.gardenPlants, isEmpty);
        expect(data.gardenEvents, isEmpty);
        expect(data.userFruitTrees, isEmpty);
      },
    );
  });
}
