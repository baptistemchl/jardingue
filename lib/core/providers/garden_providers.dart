import 'package:flutter_riverpod/flutter_riverpod.dart';
// drift.Value reste utilisé pour les Companions (DTO drift des inserts).
// Les signatures externes du notifier exposent Patch<T>, pas Value<T>.
import 'package:drift/drift.dart' show Value;
import '../models/patch.dart';
import '../services/crash_reporting/crash_reporting_service.dart';
import '../services/database/app_database.dart';
import 'garden_event_providers.dart';
import '../../features/garden/domain/models/garden_event.dart';
import '../../features/garden/domain/models/garden_plant_with_details.dart';
import '../../features/garden/data/repositories/garden_repository.dart';
import 'database_providers.dart';

// Re-export des modeles pour retrocompatibilite
export '../../features/garden/domain/models/garden_plant_with_details.dart';
export '../../features/garden/domain/models/zone_type.dart';
export '../../features/garden/domain/models/garden_extension.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

/// Provider pour le repository des potagers.
final gardenRepositoryProvider = Provider<GardenRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftGardenRepository(db);
});

// ============================================
// GARDEN PROVIDERS
// ============================================

/// Stream réactif de la liste des potagers.
final gardensListProvider = StreamProvider<List<Garden>>((ref) async* {
  // `ref.watch` synchroniquement avant tout `await` (cf. règle
  // Riverpod 3.x sur le bookkeeping pause/resume).
  final initFuture = ref.read(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  await initFuture;
  yield* db.watchAllGardens();
});

/// Stream réactif d'un potager par ID.
final gardenByIdProvider =
    StreamProvider.family<Garden?, int>((ref, id) async* {
  final initFuture = ref.read(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  await initFuture;
  yield* db.watchGardenById(id);
});

/// Stream réactif des plantes d'un potager avec leurs détails.
/// Émet à chaque mutation de `garden_plants` ou `plants` — aucune
/// invalidation manuelle n'est nécessaire dans les notifiers.
final gardenPlantsProvider = StreamProvider.family<
    List<GardenPlantWithDetails>, int>((ref, gardenId) async* {
  final initFuture = ref.read(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  await initFuture;
  yield* db.watchGardenPlantsWithDetails(gardenId).map((rows) => rows
      .map((row) => GardenPlantWithDetails(
            gardenPlant: row.readTable(db.gardenPlants),
            plant: row.readTableOrNull(db.plants),
          ))
      .toList());
});

/// Stream réactif des amendements (lineage) d'un potager.
final gardenAmendmentsLineageProvider =
    StreamProvider.family<List<GardenAmendment>, int>(
        (ref, gardenId) async* {
  final initFuture = ref.read(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  await initFuture;
  yield* db.watchAmendmentsForGardenLineage(gardenId);
});

/// Provider pour le mode edition.
final gardenEditModeProvider = NotifierProvider<GardenEditModeNotifier, bool>(GardenEditModeNotifier.new);

class GardenEditModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

// ============================================
// GARDEN NOTIFIER
// ============================================

final gardenNotifierProvider =
    NotifierProvider<GardenNotifier, AsyncValue<void>>(GardenNotifier.new);

class GardenNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  GardenRepository get _repo => ref.read(gardenRepositoryProvider);

  Future<int> createGarden({
    required String name,
    required double widthMeters,
    required double heightMeters,
    int cellSizeCm = 10,
    int? year,
    int? previousGardenId,
  }) async {
    state = const AsyncLoading();
    try {
      final widthCells =
          (widthMeters * 100 / cellSizeCm).ceil();
      final heightCells =
          (heightMeters * 100 / cellSizeCm).ceil();

      final id = await _repo.createGarden(
        GardensCompanion.insert(
          name: name,
          widthCells: Value(widthCells),
          heightCells: Value(heightCells),
          cellSizeCm: Value(cellSizeCm),
          year: Value(year),
          previousGardenId: Value(previousGardenId),
        ),
      );
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.createGarden',
        extra: {'name': name, 'width': widthMeters, 'height': heightMeters},
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateGarden({
    required int id,
    required String name,
    required double widthMeters,
    required double heightMeters,
    int cellSizeCm = 10,
    Patch<int?> year = const Patch.absent(),
    Patch<int?> previousGardenId = const Patch.absent(),
  }) async {
    state = const AsyncLoading();
    try {
      final widthCells =
          (widthMeters * 100 / cellSizeCm).ceil();
      final heightCells =
          (heightMeters * 100 / cellSizeCm).ceil();

      await _repo.updateGardenPartial(
        id: id,
        name: name,
        widthCells: widthCells,
        heightCells: heightCells,
        cellSizeCm: cellSizeCm,
        year: year,
        previousGardenId: previousGardenId,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.updateGarden',
        extra: {'gardenId': id, 'name': name},
      );
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteGarden(int id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteGarden(id);
      // Invalide le cache de "Mon suivi" : le repo a deja cascade-delete
      // les events lies au potager, mais les FutureProviders n'observent
      // pas la table. Sans invalidation l'utilisateur voit des fantomes.
      ref.invalidate(allUserEventsProvider);
      ref.invalidate(monthUserEventsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.deleteGarden',
        extra: {'gardenId': id},
      );
      state = AsyncError(e, st);
    }
  }

  Future<int> addPlantToGarden({
    required int gardenId,
    required int plantId,
    required double xMeters,
    required double yMeters,
    required double widthMeters,
    required double heightMeters,
    String? notes,
    DateTime? sowedAt,
    DateTime? plantedAt,
    int? wateringFrequencyDays,
    int? previousCropPlantId,
  }) async {
    state = const AsyncLoading();
    try {
      final garden = await _repo.getGardenById(gardenId);
      if (garden == null) {
        throw Exception('Potager non trouve');
      }

      final cellSize = garden.cellSizeCm;
      final gridX = (xMeters * 100 / cellSize).round();
      final gridY = (yMeters * 100 / cellSize).round();
      final wCells =
          (widthMeters * 100 / cellSize).ceil();
      final hCells =
          (heightMeters * 100 / cellSize).ceil();

      final effectivePlantedAt = plantedAt ?? DateTime.now();

      final id = await _repo.addPlantToGarden(
        GardenPlantsCompanion.insert(
          gardenId: gardenId,
          plantId: plantId,
          gridX: gridX,
          gridY: gridY,
          widthCells: Value(wCells.clamp(1, 100)),
          heightCells: Value(hCells.clamp(1, 100)),
          plantedAt: Value(effectivePlantedAt),
          sowedAt: Value(sowedAt),
          wateringFrequencyDays: Value(wateringFrequencyDays),
          notes: Value(notes),
          previousCropPlantId: Value(previousCropPlantId),
        ),
      );

      // Créer les événements via le notifier pour declencher l'invalidation
      // de Mon Suivi (allUserEventsProvider, monthUserEventsProvider).
      final eventNotifier =
          ref.read(gardenEventNotifierProvider.notifier);
      if (sowedAt != null) {
        await eventNotifier.logEvent(
          gardenPlantId: id,
          eventType: GardenEventType.sowing,
          date: sowedAt,
        );
      }
      await eventNotifier.logEvent(
        gardenPlantId: id,
        eventType: GardenEventType.planting,
        date: effectivePlantedAt,
      );

      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.addPlantToGarden',
        extra: {'gardenId': gardenId, 'plantId': plantId},
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Met à jour la couleur personnalisée d'un pied placé (v19).
  /// [color] = null pour revenir à la couleur de catégorie.
  Future<void> updateGardenPlantColor({
    required int gardenPlantId,
    required int? color,
  }) async {
    try {
      await _repo.updateGardenPlantColor(gardenPlantId, color);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.updateGardenPlantColor',
        extra: {
          'gardenPlantId': gardenPlantId,
          'color': color ?? 'null',
        },
      );
      rethrow;
    }
  }

  /// Duplique un élément du potager (plante ou zone) en le plaçant
  /// dans le panier (gridX=-1, gridY=-1). La copie hérite intégralement
  /// de l'original : dimensions, dates, notes, fréquence d'arrosage,
  /// previousCropPlantId. Les events (sowing/planting) sont recréés
  /// avec les dates d'origine pour rester cohérents dans « Mon suivi ».
  Future<int> duplicateGardenPlant({
    required int gardenPlantId,
    required int gardenId,
  }) async {
    state = const AsyncLoading();
    try {
      final existing =
          await ref.read(gardenPlantsProvider(gardenId).future);
      final source =
          existing.where((e) => e.id == gardenPlantId).firstOrNull;
      if (source == null) {
        throw Exception('Element source introuvable');
      }
      final gp = source.gardenPlant;

      final id = await _repo.addPlantToGarden(
        GardenPlantsCompanion.insert(
          gardenId: gp.gardenId,
          plantId: gp.plantId,
          gridX: -1,
          gridY: -1,
          widthCells: Value(gp.widthCells),
          heightCells: Value(gp.heightCells),
          plantedAt: Value(gp.plantedAt),
          sowedAt: Value(gp.sowedAt),
          // Copie aussi la couleur perso (v19) pour rester cohérent
          // avec « tout, mêmes valeurs » du contrat de duplication.
          customColor: Value(gp.customColor),
          wateringFrequencyDays: Value(gp.wateringFrequencyDays),
          notes: Value(gp.notes),
          previousCropPlantId: Value(gp.previousCropPlantId),
        ),
      );

      // Recrée les events avec les mêmes dates que l'original pour que
      // « Mon suivi » reflète une plante du même âge.
      final eventNotifier = ref.read(gardenEventNotifierProvider.notifier);
      if (gp.sowedAt != null) {
        await eventNotifier.logEvent(
          gardenPlantId: id,
          eventType: GardenEventType.sowing,
          date: gp.sowedAt!,
        );
      }
      if (gp.plantedAt != null) {
        await eventNotifier.logEvent(
          gardenPlantId: id,
          eventType: GardenEventType.planting,
          date: gp.plantedAt!,
        );
      }

      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.duplicateGardenPlant',
        extra: {'gardenPlantId': gardenPlantId, 'gardenId': gardenId},
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Ajoute une plante au potager en attente de placement (gridX=-1, gridY=-1).
  /// L'utilisateur la placera plus tard dans l'editeur.
  Future<int> addPlantPendingPlacement({
    required int gardenId,
    required int plantId,
    double? widthMeters,
    double? heightMeters,
    DateTime? sowedAt,
    DateTime? plantedAt,
    int? wateringFrequencyDays,
    int? previousCropPlantId,
  }) async {
    state = const AsyncLoading();
    try {
      final garden = await _repo.getGardenById(gardenId);
      if (garden == null) throw Exception('Potager non trouve');

      final cellSize = garden.cellSizeCm;
      final wCells = widthMeters != null
          ? (widthMeters * 100 / cellSize).ceil().clamp(1, 100)
          : 1;
      final hCells = heightMeters != null
          ? (heightMeters * 100 / cellSize).ceil().clamp(1, 100)
          : 1;

      final effectivePlantedAt = plantedAt ?? DateTime.now();

      final id = await _repo.addPlantToGarden(
        GardenPlantsCompanion.insert(
          gardenId: gardenId,
          plantId: plantId,
          gridX: -1, // En attente de placement
          gridY: -1,
          widthCells: Value(wCells),
          heightCells: Value(hCells),
          plantedAt: Value(effectivePlantedAt),
          sowedAt: Value(sowedAt),
          wateringFrequencyDays: Value(wateringFrequencyDays),
          previousCropPlantId: Value(previousCropPlantId),
        ),
      );

      final eventNotifier =
          ref.read(gardenEventNotifierProvider.notifier);
      if (sowedAt != null) {
        await eventNotifier.logEvent(
          gardenPlantId: id,
          eventType: GardenEventType.sowing,
          date: sowedAt,
        );
      }
      await eventNotifier.logEvent(
        gardenPlantId: id,
        eventType: GardenEventType.planting,
        date: effectivePlantedAt,
      );

      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.addPlantPendingPlacement',
        extra: {'gardenId': gardenId, 'plantId': plantId},
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<int> addAmendment({
    required int gardenId,
    required String type,
    required double xMeters,
    required double yMeters,
    required double widthMeters,
    required double heightMeters,
    required DateTime appliedAt,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      final garden = await _repo.getGardenById(gardenId);
      if (garden == null) throw Exception('Potager non trouve');
      final cs = garden.cellSizeCm;
      final id = await ref.read(databaseProvider).addAmendment(
            GardenAmendmentsCompanion.insert(
              gardenId: gardenId,
              type: type,
              gridX: (xMeters * 100 / cs).round(),
              gridY: (yMeters * 100 / cs).round(),
              widthCells:
                  (widthMeters * 100 / cs).ceil().clamp(1, 100),
              heightCells:
                  (heightMeters * 100 / cs).ceil().clamp(1, 100),
              appliedAt: appliedAt,
              notes: Value(notes),
            ),
          );
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.addAmendment',
        extra: {'gardenId': gardenId, 'type': type},
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Met à jour la culture précédente (override manuel) d'une plante.
  /// Passer `null` efface l'override.
  Future<void> setPreviousCrop({
    required int gardenPlantId,
    required int gardenId,
    required int? previousCropPlantId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.updateGardenPlantDetails(
        id: gardenPlantId,
        previousCropPlantId: Patch<int?>(previousCropPlantId),
      );
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'GardenNotifier.setPreviousCrop',
          extra: {
            'gardenPlantId': gardenPlantId,
            'previousCropPlantId': previousCropPlantId ?? 'null',
          });
      state = AsyncError(e, st);
    }
  }

  Future<void> moveAmendment({
    required int id,
    required int gardenId,
    required double xMeters,
    required double yMeters,
  }) async {
    state = const AsyncLoading();
    try {
      final garden = await _repo.getGardenById(gardenId);
      if (garden == null) throw Exception('Potager non trouve');
      final cs = garden.cellSizeCm;
      await ref.read(databaseProvider).updateAmendment(
            id: id,
            gridX: (xMeters * 100 / cs).round(),
            gridY: (yMeters * 100 / cs).round(),
          );
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'GardenNotifier.moveAmendment',
          extra: {'amendmentId': id});
      state = AsyncError(e, st);
    }
  }

  Future<void> resizeAmendment({
    required int id,
    required int gardenId,
    required double widthMeters,
    required double heightMeters,
  }) async {
    state = const AsyncLoading();
    try {
      final garden = await _repo.getGardenById(gardenId);
      if (garden == null) throw Exception('Potager non trouve');
      final cs = garden.cellSizeCm;
      await ref.read(databaseProvider).updateAmendment(
            id: id,
            widthCells: (widthMeters * 100 / cs).ceil().clamp(1, 100),
            heightCells: (heightMeters * 100 / cs).ceil().clamp(1, 100),
          );
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'GardenNotifier.resizeAmendment',
          extra: {'amendmentId': id});
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteAmendment(int id, int gardenId) async {
    state = const AsyncLoading();
    try {
      await ref.read(databaseProvider).deleteAmendment(id);
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
          reason: 'GardenNotifier.deleteAmendment',
          extra: {'amendmentId': id});
      state = AsyncError(e, st);
    }
  }

  Future<int> addZoneToGarden({
    required int gardenId,
    required double xMeters,
    required double yMeters,
    required double widthMeters,
    required double heightMeters,
    required String zoneType,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      final garden = await _repo.getGardenById(gardenId);
      if (garden == null) {
        throw Exception('Potager non trouve');
      }

      final cellSize = garden.cellSizeCm;
      final gridX = (xMeters * 100 / cellSize).round();
      final gridY = (yMeters * 100 / cellSize).round();
      final wCells =
          (widthMeters * 100 / cellSize).ceil();
      final hCells =
          (heightMeters * 100 / cellSize).ceil();

      final notesStr =
          zoneType + (notes != null ? '|$notes' : '');

      final id = await _repo.addPlantToGarden(
        GardenPlantsCompanion.insert(
          gardenId: gardenId,
          plantId: 0,
          gridX: gridX,
          gridY: gridY,
          widthCells: Value(wCells.clamp(1, 100)),
          heightCells: Value(hCells.clamp(1, 100)),
          notes: Value(notesStr),
        ),
      );
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.addZoneToGarden',
        extra: {'gardenId': gardenId, 'zoneType': zoneType},
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> moveElement(
    int gardenPlantId,
    double xMeters,
    double yMeters,
    int gardenId,
  ) async {
    state = const AsyncLoading();
    try {
      final garden = await _repo.getGardenById(gardenId);
      if (garden == null) {
        throw Exception('Potager non trouve');
      }

      final cellSize = garden.cellSizeCm;
      final gridX = (xMeters * 100 / cellSize).round();
      final gridY = (yMeters * 100 / cellSize).round();

      await _repo.updateGardenPlantPosition(
        gardenPlantId,
        gridX,
        gridY,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.moveElement',
        extra: {'gardenPlantId': gardenPlantId, 'gardenId': gardenId},
      );
      state = AsyncError(e, st);
    }
  }

  Future<void> removeElement(
    int gardenPlantId,
    int gardenId,
  ) async {
    state = const AsyncLoading();
    try {
      await _repo.removePlantFromGarden(gardenPlantId);
      ref.invalidate(allUserEventsProvider);
      ref.invalidate(careRemindersProvider);
      ref.invalidate(trackedPlantsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.removeElement',
        extra: {'gardenPlantId': gardenPlantId, 'gardenId': gardenId},
      );
      state = AsyncError(e, st);
    }
  }

  Future<void> updateElementSize(
    int gardenPlantId,
    double widthMeters,
    double heightMeters,
    int gardenId,
  ) async {
    state = const AsyncLoading();
    try {
      final garden = await _repo.getGardenById(gardenId);
      if (garden == null) {
        throw Exception('Potager non trouve');
      }

      final cellSize = garden.cellSizeCm;
      final wCells =
          (widthMeters * 100 / cellSize).ceil();
      final hCells =
          (heightMeters * 100 / cellSize).ceil();

      await _repo.updateGardenPlantSize(
        gardenPlantId,
        wCells,
        hCells,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenNotifier.updateElementSize',
        extra: {'gardenPlantId': gardenPlantId, 'gardenId': gardenId},
      );
      state = AsyncError(e, st);
    }
  }
}
