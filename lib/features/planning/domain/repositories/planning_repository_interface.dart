import '../models/selected_plant.dart';

abstract class PlanningRepositoryInterface {
  Future<List<SelectedPlant>> getSelectedPlants();
  Future<void> addSelectedPlant(int plantId);
  Future<void> removeSelectedPlant(int plantId);
  Future<List<int>> getSelectedPlantIds();
}
