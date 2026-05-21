import 'package:drift/drift.dart';
import '../../../../core/services/database/app_database.dart';
import '../../domain/models/backup_data.dart';
import '../../domain/models/backup_metadata.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/firestore_backup_datasource.dart';
import '../dto/backup_dto.dart';

class BackupRepositoryImpl implements BackupRepository {
  final AppDatabase _db;
  final FirestoreBackupDatasource? _firestore;

  BackupRepositoryImpl({
    required AppDatabase db,
    required FirestoreBackupDatasource firestore,
  })  : _db = db,
        _firestore = firestore;

  /// Variante test-only : pas de firestore (les méthodes upload/
  /// download/fetchMetadata lèvent [UnsupportedError]). Utilisée par
  /// les tests d'intégration pour valider le pipeline export/restore
  /// local sans avoir à mocker Firebase.
  BackupRepositoryImpl.forTesting({
    required AppDatabase db,
  })  : _db = db,
        _firestore = null;

  FirestoreBackupDatasource get _requireFirestore {
    final fs = _firestore;
    if (fs == null) {
      throw UnsupportedError(
        'BackupRepositoryImpl.forTesting cannot perform cloud '
        'operations',
      );
    }
    return fs;
  }

  @override
  Future<BackupData> exportLocalData() async {
    final gardens = await _exportGardens();
    final plants = await _exportGardenPlants();
    final events = await _exportGardenEvents();
    final trees = await _exportUserFruitTrees();
    final userPlants = await _exportUserPlants();
    final userCompanions = await _exportUserPlantCompanions();
    final userAntagonists = await _exportUserPlantAntagonists();
    // Carnet de bord (v1.7.4+).
    final harvests = await _exportHarvests();
    final seedlings = await _exportSeedlings();
    final journalEntries = await _exportJournalEntries();

    return BackupData(
      metadata: BackupMetadata(
        createdAt: DateTime.now(),
        gardenCount: gardens.length,
        plantCount: plants.length,
        eventCount: events.length,
        treeCount: trees.length,
        userPlantCount: userPlants.length,
        harvestCount: harvests.length,
        seedlingCount: seedlings.length,
        journalEntryCount: journalEntries.length,
      ),
      gardens: gardens,
      gardenPlants: plants,
      gardenEvents: events,
      userFruitTrees: trees,
      userPlants: userPlants,
      userPlantCompanions: userCompanions,
      userPlantAntagonists: userAntagonists,
      harvests: harvests,
      seedlings: seedlings,
      journalEntries: journalEntries,
    );
  }

  @override
  Future<void> uploadBackup(
    String userId,
    BackupData data,
  ) async {
    final json = BackupDto.toFirestore(data);
    await _requireFirestore.write(userId, json);
  }

  @override
  Future<BackupMetadata?> fetchMetadata(
    String userId,
  ) async {
    final meta = await _requireFirestore.readMetadata(userId);
    if (meta == null) return null;
    return BackupDto.metadataFromFirestore(meta);
  }

  @override
  Future<BackupData?> downloadBackup(
    String userId,
  ) async {
    final json = await _requireFirestore.read(userId);
    if (json == null) return null;
    return BackupDto.fromFirestore(json);
  }

  @override
  Future<void> importToLocal(BackupData data) async {
    await _db.transaction(() async {
      await _clearUserData();
      // Les user plants doivent être insérées AVANT les gardenPlants
      // car ces derniers référencent Plants.id via FK ; pour les
      // backups antérieurs à v1.6, `data.userPlants` est vide → no-op.
      await _importUserPlants(data.userPlants);
      await _importGardens(data.gardens);
      await _importGardenPlants(data.gardenPlants);
      await _importGardenEvents(data.gardenEvents);
      await _importUserPlantCompanions(
        data.userPlantCompanions,
      );
      await _importUserPlantAntagonists(
        data.userPlantAntagonists,
      );
      await _importUserFruitTrees(
        data.userFruitTrees,
      );
      // Carnet de bord (v1.7.4+) — référence GardenPlants + Plants +
      // Gardens, donc importé APRÈS ces tables. Les backups antérieurs
      // ont des listes vides → no-op rétrocompatible.
      await _importHarvests(data.harvests);
      await _importSeedlings(data.seedlings);
      await _importJournalEntries(data.journalEntries);
      // Sauvegardes anciennes : les gardenPlants peuvent avoir ete crees
      // sans events `planting`/`sowing` associes. Sans ce backfill, les
      // plantes restaurees n'apparaissent pas dans Mon Suivi.
      await _db.backfillMissingPlantingEvents();
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
              // Couleur perso (v19). Absent des backups < v1.7.3 → la
              // restore retombe sur la couleur de catégorie.
              'customColor': p.customColor,
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
      _exportUserPlants() async {
    final rows = await (_db.select(_db.plants)
          ..where((t) => t.isUserModified.equals(true)))
        .get();
    // Sérialise toutes les colonnes pour pouvoir reconstruire la plante
    // à l'identique au restore. L'id ≥ 1_000_000 est préservé tel quel
    // (cf. _importUserPlants).
    return rows
        .map((p) => {
              'id': p.id,
              'commonName': p.commonName,
              'latinName': p.latinName,
              'categoryCode': p.categoryCode,
              'categoryLabel': p.categoryLabel,
              'spacingBetweenPlants': p.spacingBetweenPlants,
              'spacingBetweenRows': p.spacingBetweenRows,
              'plantingDepthCm': p.plantingDepthCm,
              'sunExposure': p.sunExposure,
              'soilMoisturePreference': p.soilMoisturePreference,
              'soilTreatmentAdvice': p.soilTreatmentAdvice,
              'soilType': p.soilType,
              'growingZone': p.growingZone,
              'watering': p.watering,
              'plantingMinTempC': p.plantingMinTempC,
              'plantingWeatherConditions':
                  p.plantingWeatherConditions,
              'sowingUnderCoverPeriod':
                  p.sowingUnderCoverPeriod,
              'sowingOpenGroundPeriod':
                  p.sowingOpenGroundPeriod,
              'transplantingPeriod': p.transplantingPeriod,
              'harvestPeriod': p.harvestPeriod,
              'sowingRecommendation': p.sowingRecommendation,
              'cultivationGreenhouse':
                  p.cultivationGreenhouse,
              'plantingAdvice': p.plantingAdvice,
              'careAdvice': p.careAdvice,
              'redFlags': p.redFlags,
              'mainDestroyers': p.mainDestroyers,
              'sowingCalendar': p.sowingCalendar,
              'plantingCalendar': p.plantingCalendar,
              'harvestCalendar': p.harvestCalendar,
              'climateAdaptation': p.climateAdaptation,
              'toxicity': p.toxicity,
              'practicalTips': p.practicalTips,
              'rotationFamily': p.rotationFamily,
              'customEmoji': p.customEmoji,
              'createdAt':
                  p.createdAt.toIso8601String(),
              'updatedAt':
                  p.updatedAt.toIso8601String(),
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      _exportUserPlantCompanions() async {
    final rows = await (_db.select(_db.plantCompanions)
          ..where((t) =>
              t.plantId.isBiggerOrEqualValue(
                  AppDatabase.userPlantIdMin) |
              t.companionId.isBiggerOrEqualValue(
                  AppDatabase.userPlantIdMin)))
        .get();
    return rows
        .map((c) => {
              'plantId': c.plantId,
              'companionId': c.companionId,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      _exportUserPlantAntagonists() async {
    final rows = await (_db.select(_db.plantAntagonists)
          ..where((t) =>
              t.plantId.isBiggerOrEqualValue(
                  AppDatabase.userPlantIdMin) |
              t.antagonistId.isBiggerOrEqualValue(
                  AppDatabase.userPlantIdMin)))
        .get();
    return rows
        .map((a) => {
              'plantId': a.plantId,
              'antagonistId': a.antagonistId,
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
              'plantingType': t.plantingType,
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
    // Carnet de bord d'abord (références GardenPlants + Plants + Gardens).
    await _db.delete(_db.harvests).go();
    await _db.delete(_db.seedlings).go();
    await _db.delete(_db.journalEntries).go();
    await _db.delete(_db.gardenEvents).go();
    await _db.delete(_db.gardenPlants).go();
    await _db.delete(_db.gardens).go();
    await _db.delete(_db.userFruitTrees).go();
    // Les user plants et leurs relations doivent être effacées avant
    // l'import : on repart d'un état propre. Les paires catalogue ↔
    // catalogue (plantId<1_000_000 ET companionId<1_000_000) sont
    // préservées.
    await (_db.delete(_db.plantCompanions)
          ..where((t) =>
              t.plantId
                  .isBiggerOrEqualValue(AppDatabase.userPlantIdMin) |
              t.companionId
                  .isBiggerOrEqualValue(AppDatabase.userPlantIdMin)))
        .go();
    await (_db.delete(_db.plantAntagonists)
          ..where((t) =>
              t.plantId
                  .isBiggerOrEqualValue(AppDatabase.userPlantIdMin) |
              t.antagonistId
                  .isBiggerOrEqualValue(AppDatabase.userPlantIdMin)))
        .go();
    await (_db.delete(_db.plants)
          ..where((t) => t.isUserModified.equals(true)))
        .go();
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
              // Présent uniquement dans les backups ≥ v1.7.3 (v19).
              // Pour les backups plus anciens, la clé est absente
              // → la restore laisse customColor à NULL (catégorie).
              customColor: Value(
                r['customColor'] as int?,
              ),
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

  Future<void> _importUserPlants(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      // L'id explicite (≥ 1_000_000) doit être préservé pour que les
      // gardenPlants se rebranchent correctement via leur FK plantId.
      await _db.into(_db.plants).insert(
            PlantsCompanion(
              id: Value(r['id'] as int),
              commonName:
                  Value(r['commonName'] as String),
              latinName: Value(r['latinName'] as String?),
              categoryCode:
                  Value(r['categoryCode'] as String?),
              categoryLabel:
                  Value(r['categoryLabel'] as String?),
              spacingBetweenPlants: Value(
                r['spacingBetweenPlants'] as int?,
              ),
              spacingBetweenRows: Value(
                r['spacingBetweenRows'] as int?,
              ),
              plantingDepthCm:
                  Value(r['plantingDepthCm'] as int?),
              sunExposure:
                  Value(r['sunExposure'] as String?),
              soilMoisturePreference: Value(
                r['soilMoisturePreference'] as String?,
              ),
              soilTreatmentAdvice: Value(
                r['soilTreatmentAdvice'] as String?,
              ),
              soilType: Value(r['soilType'] as String?),
              growingZone:
                  Value(r['growingZone'] as String?),
              watering: Value(r['watering'] as String?),
              plantingMinTempC: Value(
                r['plantingMinTempC'] as int?,
              ),
              plantingWeatherConditions: Value(
                r['plantingWeatherConditions']
                    as String?,
              ),
              sowingUnderCoverPeriod: Value(
                r['sowingUnderCoverPeriod'] as String?,
              ),
              sowingOpenGroundPeriod: Value(
                r['sowingOpenGroundPeriod'] as String?,
              ),
              transplantingPeriod: Value(
                r['transplantingPeriod'] as String?,
              ),
              harvestPeriod:
                  Value(r['harvestPeriod'] as String?),
              sowingRecommendation: Value(
                r['sowingRecommendation'] as String?,
              ),
              cultivationGreenhouse: Value(
                r['cultivationGreenhouse'] as String?,
              ),
              plantingAdvice: Value(
                r['plantingAdvice'] as String?,
              ),
              careAdvice:
                  Value(r['careAdvice'] as String?),
              redFlags: Value(r['redFlags'] as String?),
              mainDestroyers: Value(
                r['mainDestroyers'] as String?,
              ),
              sowingCalendar: Value(
                r['sowingCalendar'] as String?,
              ),
              plantingCalendar: Value(
                r['plantingCalendar'] as String?,
              ),
              harvestCalendar: Value(
                r['harvestCalendar'] as String?,
              ),
              climateAdaptation: Value(
                r['climateAdaptation'] as String?,
              ),
              toxicity: Value(r['toxicity'] as String?),
              practicalTips: Value(
                r['practicalTips'] as String?,
              ),
              rotationFamily: Value(
                r['rotationFamily'] as String?,
              ),
              // customEmoji absent des backups < v1.6.2 → laissé null,
              // PlantEmojiMapper retombera sur la déduction nom/catégorie.
              customEmoji: Value(
                r['customEmoji'] as String?,
              ),
              isUserModified: const Value(true),
              createdAt: Value(
                _parseDate(r['createdAt']) ??
                    DateTime.now(),
              ),
              updatedAt: Value(
                _parseDate(r['updatedAt']) ??
                    DateTime.now(),
              ),
            ),
          );
    }
  }

  Future<void> _importUserPlantCompanions(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      await _db.insertCompanion(
        r['plantId'] as int,
        r['companionId'] as int,
      );
    }
  }

  Future<void> _importUserPlantAntagonists(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      await _db.insertAntagonist(
        r['plantId'] as int,
        r['antagonistId'] as int,
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
              // Absent des backups < v1.6.5 → null, affiché "Pleine terre".
              plantingType: Value(
                r['plantingType'] as String?,
              ),
            ),
          );
    }
  }

  // ── Carnet de bord (v1.7.4+) ──

  Future<List<Map<String, dynamic>>>
      _exportHarvests() async {
    final rows = await _db.select(_db.harvests).get();
    return rows
        .map((h) => {
              // L'id n'est pas exporté : les harvests sont
              // ré-incrémentés à l'import. plantId pointe vers user
              // plant (≥ 1M, préservé) ou catalogue (stable).
              'gardenPlantId': h.gardenPlantId,
              'plantId': h.plantId,
              'gardenId': h.gardenId,
              'harvestedAt': h.harvestedAt.toIso8601String(),
              'quantity': h.quantity,
              'unit': h.unit,
              'note': h.note,
              'createdAt': h.createdAt.toIso8601String(),
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      _exportSeedlings() async {
    final rows = await _db.select(_db.seedlings).get();
    return rows
        .map((s) => {
              'plantId': s.plantId,
              'gardenId': s.gardenId,
              'sowedAt': s.sowedAt.toIso8601String(),
              'expectedTransplantAt':
                  s.expectedTransplantAt?.toIso8601String(),
              'status': s.status,
              'count': s.count,
              'note': s.note,
              'createdAt': s.createdAt.toIso8601String(),
              'updatedAt': s.updatedAt.toIso8601String(),
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      _exportJournalEntries() async {
    final rows = await _db.select(_db.journalEntries).get();
    return rows
        .map((j) => {
              'gardenId': j.gardenId,
              'entryDate': j.entryDate.toIso8601String(),
              'title': j.title,
              'content': j.content,
              'tags': j.tags,
              'createdAt': j.createdAt.toIso8601String(),
              'updatedAt': j.updatedAt.toIso8601String(),
            })
        .toList();
  }

  Future<void> _importHarvests(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      await _db.into(_db.harvests).insert(
            HarvestsCompanion.insert(
              gardenPlantId:
                  Value(r['gardenPlantId'] as int?),
              plantId: r['plantId'] as int,
              gardenId: Value(r['gardenId'] as int?),
              harvestedAt: DateTime.parse(
                r['harvestedAt'] as String,
              ),
              // quantity peut être stocké comme int ou double dans le
              // JSON Firestore selon le scénario d'écriture.
              quantity: (r['quantity'] as num).toDouble(),
              unit: r['unit'] as String,
              note: Value(r['note'] as String?),
            ),
          );
    }
  }

  Future<void> _importSeedlings(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      await _db.into(_db.seedlings).insert(
            SeedlingsCompanion.insert(
              plantId: r['plantId'] as int,
              gardenId: Value(r['gardenId'] as int?),
              sowedAt: DateTime.parse(
                r['sowedAt'] as String,
              ),
              expectedTransplantAt: Value(
                _parseDate(r['expectedTransplantAt']),
              ),
              status: Value(
                r['status'] as String? ?? 'germinating',
              ),
              count: Value(r['count'] as int?),
              note: Value(r['note'] as String?),
            ),
          );
    }
  }

  Future<void> _importJournalEntries(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      await _db.into(_db.journalEntries).insert(
            JournalEntriesCompanion.insert(
              gardenId: Value(r['gardenId'] as int?),
              entryDate: DateTime.parse(
                r['entryDate'] as String,
              ),
              title: Value(r['title'] as String?),
              content: r['content'] as String,
              tags: Value(r['tags'] as String?),
            ),
          );
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw as String);
  }
}
