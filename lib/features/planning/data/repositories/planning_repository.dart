import '../../../../core/services/database/app_database.dart';
import '../../domain/models/selected_plant.dart';
import '../../domain/repositories/planning_repository_interface.dart';

class PlanningRepositoryImpl
    implements PlanningRepositoryInterface {
  final AppDatabase _db;

  PlanningRepositoryImpl(this._db);

  /// Retourne uniquement les sélections manuelles de la table
  /// `selected_plants`. L'union avec les plantes posées sur un potager
  /// se fait côté provider (cf. `selectedPlantsProvider`) pour rester
  /// réactif.
  @override
  Future<List<SelectedPlant>> getSelectedPlants() async {
    final rows = await _db.getSelectedPlants();
    return rows.map((row) {
      final sp = row.readTable(_db.selectedPlantsTable);
      final plant = row.readTable(_db.plants);
      return SelectedPlant(
        plantId: sp.plantId,
        commonName: plant.commonName,
        categoryCode: plant.categoryCode,
        addedAt: sp.addedAt,
      );
    }).toList();
  }

  @override
  Future<void> addSelectedPlant(
    int plantId,
  ) async {
    await _db.insertSelectedPlant(plantId);
  }

  @override
  Future<void> removeSelectedPlant(
    int plantId,
  ) async {
    await _db.deleteSelectedPlant(plantId);
  }

  @override
  Future<List<int>> getSelectedPlantIds() {
    return _db.getSelectedPlantIds();
  }
}
