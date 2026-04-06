import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database/database.dart';
import '../../features/plants/domain/models/plants_filter_state.dart';
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
final plantsFilterProvider = StateNotifierProvider<
    PlantsFilterNotifier, PlantsFilterState>((ref) {
  return PlantsFilterNotifier();
});

class PlantsFilterNotifier
    extends StateNotifier<PlantsFilterState> {
  PlantsFilterNotifier() : super(const PlantsFilterState());

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
final filteredPlantsProvider =
    FutureProvider<List<Plant>>((ref) async {
  await ref.watch(databaseInitProvider.future);

  final repo = ref.watch(plantRepositoryProvider);
  final filters = ref.watch(plantsFilterProvider);

  List<Plant> plants;
  if (filters.searchQuery.isEmpty) {
    plants = await repo.getAllPlantsSorted();
  } else {
    plants = await repo.searchPlants(filters.searchQuery);
  }

  if (filters.category != PlantCategory.all &&
      filters.category.code != null) {
    plants = plants
        .where(
          (p) => p.categoryCode == filters.category.code,
        )
        .toList();
  }

  if (filters.sunFilter != PlantSunFilter.all &&
      filters.sunFilter.value != null) {
    plants = plants.where((p) {
      final exposure = p.sunExposure?.toLowerCase() ?? '';
      return exposure.contains(filters.sunFilter.value!);
    }).toList();
  }

  return plants;
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

/// Provider pour les categories disponibles.
final availableCategoriesProvider =
    FutureProvider<List<CategoryCount>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final repo = ref.watch(plantRepositoryProvider);
  final plants = await repo.getAllPlantsSorted();

  final counts = <String, int>{};
  for (final plant in plants) {
    final code = plant.categoryCode ?? 'unknown';
    counts[code] = (counts[code] ?? 0) + 1;
  }

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
