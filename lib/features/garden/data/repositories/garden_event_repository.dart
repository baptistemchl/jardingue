import '../../../../core/services/database/app_database.dart';

/// Abstract interface for garden event operations.
abstract interface class GardenEventRepository {
  Future<int> addEvent(GardenEventsCompanion event);
  Future<List<GardenEvent>> getEventsForGardenPlant(int gardenPlantId);
  Future<List<GardenEvent>> getAllEvents();
  Future<List<GardenEvent>> getEventsForMonth(int year, int month);
  Future<GardenEvent?> getLastEventOfType(int gardenPlantId, String eventType);
  Future<int> deleteEvent(int id);
}

/// Drift-backed implementation of [GardenEventRepository].
class DriftGardenEventRepository implements GardenEventRepository {
  final AppDatabase _db;

  DriftGardenEventRepository(this._db);

  @override
  Future<int> addEvent(GardenEventsCompanion event) =>
      _db.addGardenEvent(event);

  @override
  Future<List<GardenEvent>> getEventsForGardenPlant(int gardenPlantId) =>
      _db.getEventsForGardenPlant(gardenPlantId);

  @override
  Future<List<GardenEvent>> getAllEvents() => _db.getAllEvents();

  @override
  Future<List<GardenEvent>> getEventsForMonth(int year, int month) =>
      _db.getEventsForMonth(year, month);

  @override
  Future<GardenEvent?> getLastEventOfType(
          int gardenPlantId, String eventType) =>
      _db.getLastEventOfType(gardenPlantId, eventType);

  @override
  Future<int> deleteEvent(int id) => _db.deleteGardenEvent(id);
}
