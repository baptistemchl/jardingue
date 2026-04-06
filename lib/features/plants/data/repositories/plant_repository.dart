import '../../../../core/services/database/app_database.dart';

/// Abstract interface for plant-related data operations.
abstract interface class PlantRepository {
  Future<List<Plant>> getAllPlantsSorted();
  Future<Plant?> getPlantById(int id);
  Future<List<Plant>> searchPlants(String query);
  Future<int> countPlants();
  Future<List<Plant>> getCompanions(int plantId);
  Future<List<Plant>> getAntagonists(int plantId);
}

/// Drift-backed implementation of [PlantRepository].
class DriftPlantRepository implements PlantRepository {
  final AppDatabase _db;

  DriftPlantRepository(this._db);

  @override
  Future<List<Plant>> getAllPlantsSorted() => _db.getAllPlantsSorted();

  @override
  Future<Plant?> getPlantById(int id) => _db.getPlantById(id);

  @override
  Future<List<Plant>> searchPlants(String query) => _db.searchPlants(query);

  @override
  Future<int> countPlants() => _db.countPlants();

  @override
  Future<List<Plant>> getCompanions(int plantId) =>
      _db.getCompanions(plantId);

  @override
  Future<List<Plant>> getAntagonists(int plantId) =>
      _db.getAntagonists(plantId);
}
