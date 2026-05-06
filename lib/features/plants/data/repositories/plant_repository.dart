import 'package:drift/drift.dart' show Value;
import '../../../../core/services/database/app_database.dart';
import '../../domain/models/user_plant_input.dart';

/// Abstract interface for plant-related data operations.
abstract interface class PlantRepository {
  Future<List<Plant>> getAllPlantsSorted();
  Future<Plant?> getPlantById(int id);
  Future<List<Plant>> searchPlants(String query);
  Future<int> countPlants();
  Future<int> countCatalogPlants();
  Future<List<Plant>> getCompanions(int plantId);
  Future<List<Plant>> getAntagonists(int plantId);
  Future<List<Plant>> getFilteredPlants({
    String? searchQuery,
    String? categoryCode,
    String? sunExposureContains,
  });
  Future<Map<String, int>> getCategoryCounts();
  Future<Map<String, int>> getCatalogCategoryCounts();
  Future<List<Plant>> getPlantsByIds(List<int> ids);
  Future<List<Plant>> getAllUserPlants();

  /// Crée une plante user. Retourne l'ID assigné. Insère également les
  /// relations compagne/antagoniste vers le catalogue si fournies.
  Future<int> insertUserPlant(
    UserPlantInput input, {
    List<int> companions,
    List<int> antagonists,
  });

  /// Met à jour une plante user existante. Si `companions` ou
  /// `antagonists` sont non-null, les relations correspondantes sont
  /// remplacées (delete + reinsert) ; si null, elles sont laissées
  /// intactes.
  Future<void> updateUserPlant(
    int id,
    UserPlantInput input, {
    List<int>? companions,
    List<int>? antagonists,
  });

  /// Renvoie un snapshot de l'utilisation actuelle d'une plante user
  /// (potagers où elle est posée + nombre d'événements liés).
  /// L'UI s'en sert pour afficher un avertissement avant suppression
  /// si la plante est en usage.
  Future<UserPlantUsageInfo> getUserPlantUsage(int id);

  /// Supprime une plante user en cascade : retire ses références dans
  /// les potagers, événements de suivi, tâches de planification, et
  /// relations compagne/antagoniste. La suppression est définitive ;
  /// l'UI doit prévenir l'utilisateur si [getUserPlantUsage] retourne
  /// un usage non vide.
  Future<void> deleteUserPlant(int id);
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
  Future<int> countCatalogPlants() => _db.countCatalogPlants();

  @override
  Future<List<Plant>> getCompanions(int plantId) =>
      _db.getCompanions(plantId);

  @override
  Future<List<Plant>> getAntagonists(int plantId) =>
      _db.getAntagonists(plantId);

  @override
  Future<List<Plant>> getFilteredPlants({
    String? searchQuery,
    String? categoryCode,
    String? sunExposureContains,
  }) =>
      _db.getFilteredPlants(
        searchQuery: searchQuery,
        categoryCode: categoryCode,
        sunExposureContains: sunExposureContains,
      );

  @override
  Future<Map<String, int>> getCategoryCounts() => _db.getCategoryCounts();

  @override
  Future<Map<String, int>> getCatalogCategoryCounts() =>
      _db.getCatalogCategoryCounts();

  @override
  Future<List<Plant>> getPlantsByIds(List<int> ids) =>
      _db.getPlantsByIds(ids);

  @override
  Future<List<Plant>> getAllUserPlants() => _db.getAllUserPlants();

  @override
  Future<int> insertUserPlant(
    UserPlantInput input, {
    List<int> companions = const [],
    List<int> antagonists = const [],
  }) async {
    final id = await _db.nextUserPlantId();
    final companion = _buildCompanion(input, id: id);
    await _db.insertUserPlant(companion);
    for (final c in companions) {
      await _db.insertCompanion(id, c);
    }
    for (final a in antagonists) {
      await _db.insertAntagonist(id, a);
    }
    return id;
  }

  @override
  Future<void> updateUserPlant(
    int id,
    UserPlantInput input, {
    List<int>? companions,
    List<int>? antagonists,
  }) async {
    final companion = _buildCompanion(input);
    await _db.updateUserPlant(id, companion);

    if (companions != null) {
      // Reset → reinsert : plus simple qu'un diff et OK pour une
      // petite liste éditée à la main.
      await _db.replaceCompanionsForUserPlant(id, companions);
    }
    if (antagonists != null) {
      await _db.replaceAntagonistsForUserPlant(id, antagonists);
    }
  }

  @override
  Future<UserPlantUsageInfo> getUserPlantUsage(int id) =>
      _db.getUserPlantUsage(id);

  @override
  Future<void> deleteUserPlant(int id) => _db.deleteUserPlant(id);

  /// Construit la `PlantsCompanion` à partir de l'[UserPlantInput].
  /// L'ID est optionnel : pour un update, on l'omet (la clause `where` du
  /// `update` cible déjà la bonne ligne).
  PlantsCompanion _buildCompanion(UserPlantInput i, {int? id}) {
    return PlantsCompanion(
      id: id != null ? Value(id) : const Value.absent(),
      commonName: Value(i.commonName),
      latinName: Value(i.latinName),
      categoryCode: Value(i.categoryCode),
      categoryLabel: Value(i.categoryLabel),
      spacingBetweenPlants: Value(i.spacingBetweenPlants),
      spacingBetweenRows: Value(i.spacingBetweenRows),
      plantingDepthCm: Value(i.plantingDepthCm),
      sunExposure: Value(i.sunExposure),
      soilMoisturePreference: Value(i.soilMoisturePreference),
      soilType: Value(i.soilType),
      growingZone: Value(i.growingZone),
      watering: Value(i.watering),
      plantingMinTempC: Value(i.plantingMinTempC),
      sowingCalendar: Value(i.sowingCalendarJson),
      plantingCalendar: Value(i.plantingCalendarJson),
      harvestCalendar: Value(i.harvestCalendarJson),
      sowingRecommendation: Value(i.sowingRecommendation),
      plantingAdvice: Value(i.plantingAdvice),
      careAdvice: Value(i.careAdvice),
      redFlags: Value(i.redFlags),
      practicalTips: Value(i.practicalTips),
      toxicity: Value(i.toxicity),
      rotationFamily: Value(i.rotationFamily),
      customEmoji: Value(i.customEmoji),
      isUserModified: const Value(true),
      updatedAt: Value(DateTime.now()),
    );
  }
}
