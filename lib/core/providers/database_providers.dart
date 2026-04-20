import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database/database.dart';
import '../../features/plants/domain/models/plants_filter_state.dart';
import '../../features/plants/domain/models/plant_helpers.dart';
import '../../features/plants/data/repositories/plant_repository.dart';

// Re-export des modeles pour retrocompatibilite
export '../../features/plants/domain/models/plants_filter_state.dart';
// PlantHelpers est exporte separement pour les
// fichiers qui en ont besoin directement.
export '../../features/plants/domain/models/plant_helpers.dart';

// ============================================
// DATABASE PROVIDERS (base)
// ============================================

/// Provider singleton pour la base de donnees.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider pour le service d'import.
final plantImportServiceProvider =
    Provider<PlantImportService>((ref) {
  final db = ref.watch(databaseProvider);
  return PlantImportService(db);
});

/// Provider pour l'initialisation de la base de donnees.
final databaseInitProvider = FutureProvider<int>((ref) async {
  final importService = ref.watch(plantImportServiceProvider);
  return importService.importFromAssets();
});

// ============================================
// REPOSITORY PROVIDERS
// ============================================

/// Provider pour le repository des plantes.
final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftPlantRepository(db);
});

// ============================================
// FILTRES
// ============================================

/// Provider pour l'etat des filtres.
final plantsFilterProvider = NotifierProvider<
    PlantsFilterNotifier, PlantsFilterState>(PlantsFilterNotifier.new);

class PlantsFilterNotifier extends Notifier<PlantsFilterState> {
  @override
  PlantsFilterState build() => const PlantsFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(PlantCategory category) {
    state = state.copyWith(category: category);
  }

  void setSunFilter(PlantSunFilter filter) {
    state = state.copyWith(sunFilter: filter);
  }

  void clearFilters() {
    state = const PlantsFilterState();
  }
}

// ============================================
// PLANTS LIST PROVIDERS
// ============================================

/// Provider pour la liste filtree des plantes.
/// Les filtres categorie/exposition sont appliques en SQL, la recherche
/// textuelle est appliquee en Dart avec une normalisation tolerante
/// (accents, tirets, espaces et apostrophes ignores).
final filteredPlantsProvider =
    FutureProvider<List<Plant>>((ref) async {
  await ref.watch(databaseInitProvider.future);

  final repo = ref.watch(plantRepositoryProvider);
  final filters = ref.watch(plantsFilterProvider);

  final plants = await repo.getFilteredPlants(
    searchQuery: null,
    categoryCode: filters.category != PlantCategory.all
        ? filters.category.code
        : null,
    sunExposureContains: filters.sunFilter != PlantSunFilter.all
        ? filters.sunFilter.value
        : null,
  );

  if (filters.searchQuery.isEmpty) return plants;

  final needle = normalizePlantSearch(filters.searchQuery);
  if (needle.isEmpty) return plants;

  return plants.where((p) {
    final common = normalizePlantSearch(p.commonName);
    if (common.contains(needle)) return true;
    final latin = p.latinName;
    if (latin != null && normalizePlantSearch(latin).contains(needle)) {
      return true;
    }
    return false;
  }).toList();
});

/// Provider pour le nombre total de plantes (sans filtres).
final totalPlantsCountProvider =
    FutureProvider<int>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final repo = ref.watch(plantRepositoryProvider);
  return repo.countPlants();
});

/// Provider pour le nombre de plantes filtrees.
final filteredPlantsCountProvider =
    Provider<AsyncValue<int>>((ref) {
  return ref
      .watch(filteredPlantsProvider)
      .whenData((plants) => plants.length);
});

/// Provider pour les categories disponibles (SQL GROUP BY).
final availableCategoriesProvider =
    FutureProvider<List<CategoryCount>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final repo = ref.watch(plantRepositoryProvider);
  final counts = await repo.getCategoryCounts();

  return counts.entries
      .map(
        (e) => CategoryCount(code: e.key, count: e.value),
      )
      .toList();
});

class CategoryCount {
  final String code;
  final int count;

  const CategoryCount({
    required this.code,
    required this.count,
  });
}

// ============================================
// SINGLE PLANT PROVIDERS
// ============================================

/// Provider pour une plante par ID.
final plantByIdProvider =
    FutureProvider.family<Plant?, int>((ref, id) async {
  await ref.watch(databaseInitProvider.future);
  final repo = ref.watch(plantRepositoryProvider);
  return repo.getPlantById(id);
});

/// Provider pour les plantes compagnes.
final plantCompanionsProvider =
    FutureProvider.family<List<Plant>, int>((ref, plantId) async {
  final repo = ref.watch(plantRepositoryProvider);
  return repo.getCompanions(plantId);
});

/// Provider pour les plantes antagonistes.
final plantAntagonistsProvider =
    FutureProvider.family<List<Plant>, int>((ref, plantId) async {
  final repo = ref.watch(plantRepositoryProvider);
  return repo.getAntagonists(plantId);
});
