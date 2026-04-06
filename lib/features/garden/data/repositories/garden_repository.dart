import '../../../../core/services/database/app_database.dart';

/// Abstract interface for garden-related data operations.
abstract interface class GardenRepository {
  Future<List<Garden>> getAllGardens();
  Future<Garden?> getGardenById(int id);
  Future<int> createGarden(GardensCompanion garden);
  Future<bool> updateGarden(Garden garden);
  Future<int> deleteGarden(int id);
  Future<List<GardenPlant>> getGardenPlants(int gardenId);
  Future<int> addPlantToGarden(GardenPlantsCompanion gp);
  Future<int> removePlantFromGarden(int id);
  Future<void> updateGardenPlantPosition(int id, int x, int y);
  Future<void> updateGardenPlantSize(int id, int w, int h);
  Future<void> updateGardenPlantDetails({
    required int id,
    DateTime? sowedAt,
    DateTime? plantedAt,
    int? wateringFrequencyDays,
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
  Future<int> deleteGarden(int id) => _db.deleteGarden(id);

  @override
  Future<List<GardenPlant>> getGardenPlants(int gardenId) =>
      _db.getGardenPlants(gardenId);

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
  Future<void> updateGardenPlantDetails({
    required int id,
    DateTime? sowedAt,
    DateTime? plantedAt,
    int? wateringFrequencyDays,
  }) =>
      _db.updateGardenPlantDetails(
        id: id,
        sowedAt: sowedAt,
        plantedAt: plantedAt,
        wateringFrequencyDays: wateringFrequencyDays,
      );
}
