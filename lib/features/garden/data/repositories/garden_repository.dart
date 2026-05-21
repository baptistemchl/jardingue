import 'package:drift/drift.dart' as drift;
import '../../../../core/models/patch.dart';
import '../../../../core/services/database/app_database.dart';
import '../../domain/models/garden_plant_with_details.dart';

/// Traduit un [Patch] de la couche métier en `drift.Value<T>` utilisée
/// côté base. Cantonne l'import `drift` à la couche data.
drift.Value<T> _patchToValue<T>(Patch<T> p) =>
    p.present ? drift.Value(p.value) : const drift.Value.absent();

/// Abstract interface for garden-related data operations.
abstract interface class GardenRepository {
  Future<List<Garden>> getAllGardens();
  Future<Garden?> getGardenById(int id);
  Future<int> createGarden(GardensCompanion garden);
  Future<bool> updateGarden(Garden garden);
  Future<void> updateGardenPartial({
    required int id,
    String? name,
    int? widthCells,
    int? heightCells,
    int? cellSizeCm,
    Patch<int?> year,
    Patch<int?> previousGardenId,
  });
  Future<int> deleteGarden(int id);
  Future<List<GardenPlant>> getGardenPlants(int gardenId);
  Future<List<GardenPlantWithDetails>> getGardenPlantsWithDetails(
      int gardenId);
  Future<int> addPlantToGarden(GardenPlantsCompanion gp);
  Future<int> removePlantFromGarden(int id);
  Future<void> updateGardenPlantPosition(int id, int x, int y);
  Future<void> updateGardenPlantSize(int id, int w, int h);
  Future<void> updateGardenPlantColor(int id, int? color);
  Future<int> updateGardenPlantsColorBySpecies({
    required int gardenId,
    required int plantId,
    required int? color,
  });
  Future<void> updateGardenPlantDetails({
    required int id,
    DateTime? sowedAt,
    DateTime? plantedAt,
    int? wateringFrequencyDays,
    Patch<int?> previousCropPlantId,
  });
}

/// Drift-backed implementation of [GardenRepository].
class DriftGardenRepository implements GardenRepository {
  final AppDatabase _db;

  DriftGardenRepository(this._db);

  @override
  Future<List<Garden>> getAllGardens() => _db.getAllGardens();

  @override
  Future<Garden?> getGardenById(int id) => _db.getGardenById(id);

  @override
  Future<int> createGarden(GardensCompanion garden) =>
      _db.createGarden(garden);

  @override
  Future<bool> updateGarden(Garden garden) => _db.updateGarden(garden);

  @override
  Future<void> updateGardenPartial({
    required int id,
    String? name,
    int? widthCells,
    int? heightCells,
    int? cellSizeCm,
    Patch<int?> year = const Patch.absent(),
    Patch<int?> previousGardenId = const Patch.absent(),
  }) =>
      _db.updateGardenPartial(
        id: id,
        name: name,
        widthCells: widthCells,
        heightCells: heightCells,
        cellSizeCm: cellSizeCm,
        year: _patchToValue(year),
        previousGardenId: _patchToValue(previousGardenId),
      );

  @override
  Future<int> deleteGarden(int id) => _db.deleteGarden(id);

  @override
  Future<List<GardenPlant>> getGardenPlants(int gardenId) =>
      _db.getGardenPlants(gardenId);

  @override
  Future<List<GardenPlantWithDetails>> getGardenPlantsWithDetails(
      int gardenId) async {
    final results = await _db.getGardenPlantsWithDetails(gardenId);
    return results.map((row) {
      final gp = row.readTable(_db.gardenPlants);
      final plant = row.readTableOrNull(_db.plants);
      return GardenPlantWithDetails(gardenPlant: gp, plant: plant);
    }).toList();
  }

  @override
  Future<int> addPlantToGarden(GardenPlantsCompanion gp) =>
      _db.addPlantToGarden(gp);

  @override
  Future<int> removePlantFromGarden(int id) =>
      _db.removePlantFromGarden(id);

  @override
  Future<void> updateGardenPlantPosition(int id, int x, int y) =>
      _db.updateGardenPlantPosition(id, x, y);

  @override
  Future<void> updateGardenPlantSize(int id, int w, int h) =>
      _db.updateGardenPlantSize(id, w, h);

  @override
  Future<void> updateGardenPlantColor(int id, int? color) =>
      _db.updateGardenPlantColor(id, color);

  @override
  Future<int> updateGardenPlantsColorBySpecies({
    required int gardenId,
    required int plantId,
    required int? color,
  }) =>
      _db.updateGardenPlantsColorBySpecies(
        gardenId: gardenId,
        plantId: plantId,
        color: color,
      );

  @override
  Future<void> updateGardenPlantDetails({
    required int id,
    DateTime? sowedAt,
    DateTime? plantedAt,
    int? wateringFrequencyDays,
    Patch<int?> previousCropPlantId = const Patch.absent(),
  }) =>
      _db.updateGardenPlantDetails(
        id: id,
        sowedAt: sowedAt,
        plantedAt: plantedAt,
        wateringFrequencyDays: wateringFrequencyDays,
        previousCropPlantId: _patchToValue(previousCropPlantId),
      );
}
