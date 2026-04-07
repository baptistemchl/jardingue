import 'package:drift/drift.dart';
import '../../../../core/services/database/app_database.dart';
import '../../domain/models/backup_data.dart';
import '../../domain/models/backup_metadata.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/firestore_backup_datasource.dart';
import '../dto/backup_dto.dart';

class BackupRepositoryImpl implements BackupRepository {
  final AppDatabase _db;
  final FirestoreBackupDatasource _firestore;

  BackupRepositoryImpl({
    required AppDatabase db,
    required FirestoreBackupDatasource firestore,
  })  : _db = db,
        _firestore = firestore;

  @override
  Future<BackupData> exportLocalData() async {
    final gardens = await _exportGardens();
    final plants = await _exportGardenPlants();
    final events = await _exportGardenEvents();
    final trees = await _exportUserFruitTrees();

    return BackupData(
      metadata: BackupMetadata(
        createdAt: DateTime.now(),
        gardenCount: gardens.length,
        plantCount: plants.length,
        eventCount: events.length,
        treeCount: trees.length,
      ),
      gardens: gardens,
      gardenPlants: plants,
      gardenEvents: events,
      userFruitTrees: trees,
    );
  }

  @override
  Future<void> uploadBackup(
    String userId,
    BackupData data,
  ) async {
    final json = BackupDto.toFirestore(data);
    await _firestore.write(userId, json);
  }

  @override
  Future<BackupMetadata?> fetchMetadata(
    String userId,
  ) async {
    final meta = await _firestore.readMetadata(userId);
    if (meta == null) return null;
    return BackupDto.metadataFromFirestore(meta);
  }

  @override
  Future<BackupData?> downloadBackup(
    String userId,
  ) async {
    final json = await _firestore.read(userId);
    if (json == null) return null;
    return BackupDto.fromFirestore(json);
  }

  @override
  Future<void> importToLocal(BackupData data) async {
    await _db.transaction(() async {
      await _clearUserData();
      await _importGardens(data.gardens);
      await _importGardenPlants(data.gardenPlants);
      await _importGardenEvents(data.gardenEvents);
      await _importUserFruitTrees(
        data.userFruitTrees,
      );
    });
  }

  // ── Export helpers ──

  Future<List<Map<String, dynamic>>>
      _exportGardens() async {
    final rows = await _db.select(_db.gardens).get();
    return rows
        .map((g) => {
              'id': g.id,
              'name': g.name,
              'widthCells': g.widthCells,
              'heightCells': g.heightCells,
              'cellSizeCm': g.cellSizeCm,
              'createdAt':
                  g.createdAt.toIso8601String(),
              'updatedAt':
                  g.updatedAt.toIso8601String(),
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      _exportGardenPlants() async {
    final rows =
        await _db.select(_db.gardenPlants).get();
    return rows
        .map((p) => {
              'id': p.id,
              'gardenId': p.gardenId,
              'plantId': p.plantId,
              'gridX': p.gridX,
              'gridY': p.gridY,
              'widthCells': p.widthCells,
              'heightCells': p.heightCells,
              'plantedAt':
                  p.plantedAt?.toIso8601String(),
              'sowedAt':
                  p.sowedAt?.toIso8601String(),
              'wateringFrequencyDays':
                  p.wateringFrequencyDays,
              'notes': p.notes,
              'createdAt':
                  p.createdAt.toIso8601String(),
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      _exportGardenEvents() async {
    final rows =
        await _db.select(_db.gardenEvents).get();
    return rows
        .map((e) => {
              'id': e.id,
              'gardenPlantId': e.gardenPlantId,
              'plantId': e.plantId,
              'eventType': e.eventType,
              'eventDate':
                  e.eventDate.toIso8601String(),
              'notes': e.notes,
              'createdAt':
                  e.createdAt.toIso8601String(),
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      _exportUserFruitTrees() async {
    final rows =
        await _db.select(_db.userFruitTrees).get();
    return rows
        .map((t) => {
              'id': t.id,
              'fruitTreeId': t.fruitTreeId,
              'nickname': t.nickname,
              'variety': t.variety,
              'plantingDate':
                  t.plantingDate?.toIso8601String(),
              'location': t.location,
              'notes': t.notes,
              'healthStatus': t.healthStatus,
              'lastPruningDate':
                  t.lastPruningDate?.toIso8601String(),
              'lastHarvestDate':
                  t.lastHarvestDate?.toIso8601String(),
              'lastYieldKg': t.lastYieldKg,
              'photos': t.photos,
              'createdAt':
                  t.createdAt.toIso8601String(),
              'updatedAt':
                  t.updatedAt.toIso8601String(),
            })
        .toList();
  }

  // ── Import helpers ──

  Future<void> _clearUserData() async {
    await _db.delete(_db.gardenEvents).go();
    await _db.delete(_db.gardenPlants).go();
    await _db.delete(_db.gardens).go();
    await _db.delete(_db.userFruitTrees).go();
  }

  Future<void> _importGardens(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      await _db.into(_db.gardens).insert(
            GardensCompanion.insert(
              name: r['name'] as String,
              widthCells: Value(r['widthCells'] as int),
              heightCells: Value(
                r['heightCells'] as int,
              ),
              cellSizeCm: Value(
                r['cellSizeCm'] as int,
              ),
            ),
          );
    }
  }

  Future<void> _importGardenPlants(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      await _db.into(_db.gardenPlants).insert(
            GardenPlantsCompanion.insert(
              gardenId: r['gardenId'] as int,
              plantId: r['plantId'] as int,
              gridX: r['gridX'] as int,
              gridY: r['gridY'] as int,
              widthCells: Value(
                r['widthCells'] as int? ?? 1,
              ),
              heightCells: Value(
                r['heightCells'] as int? ?? 1,
              ),
              plantedAt: Value(
                _parseDate(r['plantedAt']),
              ),
              sowedAt: Value(
                _parseDate(r['sowedAt']),
              ),
              wateringFrequencyDays: Value(
                r['wateringFrequencyDays'] as int?,
              ),
              notes: Value(r['notes'] as String?),
            ),
          );
    }
  }

  Future<void> _importGardenEvents(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      await _db.into(_db.gardenEvents).insert(
            GardenEventsCompanion.insert(
              gardenPlantId: Value(
                r['gardenPlantId'] as int?,
              ),
              plantId: Value(r['plantId'] as int?),
              eventType: r['eventType'] as String,
              eventDate: DateTime.parse(
                r['eventDate'] as String,
              ),
              notes: Value(r['notes'] as String?),
            ),
          );
    }
  }

  Future<void> _importUserFruitTrees(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      await _db.into(_db.userFruitTrees).insert(
            UserFruitTreesCompanion.insert(
              fruitTreeId: r['fruitTreeId'] as int,
              nickname: Value(
                r['nickname'] as String?,
              ),
              variety: Value(
                r['variety'] as String?,
              ),
              plantingDate: Value(
                _parseDate(r['plantingDate']),
              ),
              location: Value(
                r['location'] as String?,
              ),
              notes: Value(r['notes'] as String?),
              healthStatus: Value(
                r['healthStatus'] as String? ?? 'good',
              ),
              photos: Value(r['photos'] as String?),
            ),
          );
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw as String);
  }
}
