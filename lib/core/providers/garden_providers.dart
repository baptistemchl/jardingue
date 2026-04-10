import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../services/database/app_database.dart';
import '../../features/garden/data/repositories/garden_event_repository.dart';
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

/// Provider pour la liste des potagers.
final gardensListProvider = FutureProvider<List<Garden>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final repo = ref.watch(gardenRepositoryProvider);
  return repo.getAllGardens();
});

/// Provider pour un potager par ID.
final gardenByIdProvider =
    FutureProvider.family<Garden?, int>((ref, id) async {
  await ref.watch(databaseInitProvider.future);
  final repo = ref.watch(gardenRepositoryProvider);
  return repo.getGardenById(id);
});

/// Provider pour les plantes d'un potager avec details (JOIN, 1 requête).
final gardenPlantsProvider = FutureProvider.family<
    List<GardenPlantWithDetails>, int>((ref, gardenId) async {
  await ref.watch(databaseInitProvider.future);
  final gardenRepo = ref.watch(gardenRepositoryProvider);
  return gardenRepo.getGardenPlantsWithDetails(gardenId);
});

/// Provider pour le mode edition.
final gardenEditModeProvider = StateProvider<bool>((ref) => false);

// ============================================
// GARDEN NOTIFIER
// ============================================

final gardenNotifierProvider =
    StateNotifierProvider<GardenNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(gardenRepositoryProvider);
  return GardenNotifier(repo, ref);
});

class GardenNotifier extends StateNotifier<AsyncValue<void>> {
  final GardenRepository _repo;
  final Ref _ref;

  GardenNotifier(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<int> createGarden({
    required String name,
    required double widthMeters,
    required double heightMeters,
    int cellSizeCm = 10,
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
        ),
      );
      _ref.invalidate(gardensListProvider);
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
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
  }) async {
    state = const AsyncLoading();
    try {
      final widthCells =
          (widthMeters * 100 / cellSizeCm).ceil();
      final heightCells =
          (heightMeters * 100 / cellSizeCm).ceil();

      await _repo.updateGarden(
        Garden(
          id: id,
          name: name,
          widthCells: widthCells,
          heightCells: heightCells,
          cellSizeCm: cellSizeCm,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _ref.invalidate(gardensListProvider);
      _ref.invalidate(gardenByIdProvider(id));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteGarden(int id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteGarden(id);
      _ref.invalidate(gardensListProvider);
      state = const AsyncData(null);
    } catch (e, st) {
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
        ),
      );

      // Créer les événements correspondants
      final eventRepo = DriftGardenEventRepository(
          _ref.read(databaseProvider));
      if (sowedAt != null) {
        await eventRepo.addEvent(GardenEventsCompanion.insert(
          gardenPlantId: Value(id),
          eventType: GardenEventType.sowing.name,
          eventDate: sowedAt,
        ));
      }
      await eventRepo.addEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(id),
        eventType: GardenEventType.planting.name,
        eventDate: effectivePlantedAt,
      ));

      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
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
        ),
      );

      // Créer les événements
      final eventRepo = DriftGardenEventRepository(
          _ref.read(databaseProvider));
      if (sowedAt != null) {
        await eventRepo.addEvent(GardenEventsCompanion.insert(
          gardenPlantId: Value(id),
          eventType: GardenEventType.sowing.name,
          eventDate: sowedAt,
        ));
      }
      await eventRepo.addEvent(GardenEventsCompanion.insert(
        gardenPlantId: Value(id),
        eventType: GardenEventType.planting.name,
        eventDate: effectivePlantedAt,
      ));

      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
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
      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
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
      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
    } catch (e, st) {
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
      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
    } catch (e, st) {
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
      _ref.invalidate(gardenPlantsProvider(gardenId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
