import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database/database.dart';

// ============================================
// DATABASE PROVIDERS (base)
// ============================================

/// Provider singleton pour la base de données
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider pour le service d'import
final plantImportServiceProvider = Provider<PlantImportService>((ref) {
  final db = ref.watch(databaseProvider);
  return PlantImportService(db);
});

/// Provider pour l'initialisation de la base de données
final databaseInitProvider = FutureProvider<int>((ref) async {
  final importService = ref.watch(plantImportServiceProvider);
  return importService.importFromAssets();
});

// ============================================
// FILTRES
// ============================================

/// Catégories de plantes (basées sur category_code du JSON)
enum PlantCategory {
  all('Tous', '🌱', null),
  fruitVegetable('Légumes-fruits', '🍅', 'fruit_vegetable'),
  leafyGreen('Légumes-feuilles', '🥬', 'leafy_green'),
  root('Légumes-racines', '🥕', 'root'),
  tuber('Tubercules', '🥔', 'tuber'),
  allium('Bulbes', '🧅', 'allium'),
  legume('Légumineuses', '🫛', 'legume'),
  herb('Aromates', '🌿', 'herb'),
  fruit('Petits fruits', '🍓', 'fruit'),
  stem('Légumes-tiges', '🌿', 'stem'),
  flower('Fleurs', '🌸', 'flower'),
  grain('Grains', '🌾', 'grain');

  final String label;
  final String emoji;
  final String? code;

  const PlantCategory(this.label, this.emoji, this.code);

  String get displayLabel => '$emoji $label';

  /// Trouve la catégorie à partir du code
  static PlantCategory fromCode(String? code) {
    if (code == null) return all;
    return PlantCategory.values.firstWhere(
      (c) => c.code == code,
      orElse: () => all,
    );
  }
}

/// Filtres d'exposition soleil
enum PlantSunFilter {
  all('Tous', null),
  fullSun('☀️ Ensoleillé', 'ensoleillé'),
  partialShade('⛅ Mi-ombre', 'mi-ombre'),
  shade('🌥️ Ombragé', 'ombragé');

  final String label;
  final String? value;

  const PlantSunFilter(this.label, this.value);
}

/// État complet des filtres
class PlantsFilterState {
  final String searchQuery;
  final PlantCategory category;
  final PlantSunFilter sunFilter;

  const PlantsFilterState({
    this.searchQuery = '',
    this.category = PlantCategory.all,
    this.sunFilter = PlantSunFilter.all,
  });

  PlantsFilterState copyWith({
    String? searchQuery,
    PlantCategory? category,
    PlantSunFilter? sunFilter,
  }) {
    return PlantsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      sunFilter: sunFilter ?? this.sunFilter,
    );
  }

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      category != PlantCategory.all ||
      sunFilter != PlantSunFilter.all;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantsFilterState &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          category == other.category &&
          sunFilter == other.sunFilter;

  @override
  int get hashCode =>
      searchQuery.hashCode ^ category.hashCode ^ sunFilter.hashCode;
}

/// Provider pour l'état des filtres
final plantsFilterProvider =
    StateNotifierProvider<PlantsFilterNotifier, PlantsFilterState>((ref) {
      return PlantsFilterNotifier();
    });

class PlantsFilterNotifier extends StateNotifier<PlantsFilterState> {
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

/// Provider pour la liste filtrée des plantes
final filteredPlantsProvider = FutureProvider<List<Plant>>((ref) async {
  await ref.watch(databaseInitProvider.future);

  final db = ref.watch(databaseProvider);
  final filters = ref.watch(plantsFilterProvider);

  // Récupère toutes les plantes ou recherche
  List<Plant> plants;
  if (filters.searchQuery.isEmpty) {
    plants = await db.getAllPlantsSorted();
  } else {
    plants = await db.searchPlants(filters.searchQuery);
  }

  // Filtre par catégorie (utilise le category_code de la BDD)
  if (filters.category != PlantCategory.all && filters.category.code != null) {
    plants = plants
        .where((p) => p.categoryCode == filters.category.code)
        .toList();
  }

  // Filtre par exposition soleil
  if (filters.sunFilter != PlantSunFilter.all &&
      filters.sunFilter.value != null) {
    plants = plants.where((p) {
      final exposure = p.sunExposure?.toLowerCase() ?? '';
      return exposure.contains(filters.sunFilter.value!);
    }).toList();
  }

  return plants;
});

/// Provider pour le nombre total de plantes (sans filtres)
final totalPlantsCountProvider = FutureProvider<int>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  return db.countPlants();
});

/// Provider pour le nombre de plantes filtrées
final filteredPlantsCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(filteredPlantsProvider).whenData((plants) => plants.length);
});

/// Provider pour les catégories disponibles (avec comptage)
final availableCategoriesProvider = FutureProvider<List<CategoryCount>>((
  ref,
) async {
  await ref.watch(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  final plants = await db.getAllPlantsSorted();

  final counts = <String, int>{};
  for (final plant in plants) {
    final code = plant.categoryCode ?? 'unknown';
    counts[code] = (counts[code] ?? 0) + 1;
  }

  return counts.entries
      .map((e) => CategoryCount(code: e.key, count: e.value))
      .toList();
});

class CategoryCount {
  final String code;
  final int count;

  CategoryCount({required this.code, required this.count});
}

// ============================================
// SINGLE PLANT PROVIDERS
// ============================================

/// Provider pour une plante par ID
final plantByIdProvider = FutureProvider.family<Plant?, int>((ref, id) async {
  await ref.watch(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  return db.getPlantById(id);
});

/// Provider pour les plantes compagnes
final plantCompanionsProvider = FutureProvider.family<List<Plant>, int>((
  ref,
  plantId,
) async {
  final db = ref.watch(databaseProvider);
  return db.getCompanions(plantId);
});

/// Provider pour les plantes antagonistes
final plantAntagonistsProvider = FutureProvider.family<List<Plant>, int>((
  ref,
  plantId,
) async {
  final db = ref.watch(databaseProvider);
  return db.getAntagonists(plantId);
});

// ============================================
// PLANT EXTENSION HELPERS
// ============================================

extension PlantHelpers on Plant {
  /// Récupère la catégorie enum depuis le code en BDD
  PlantCategory get category => PlantCategory.fromCode(categoryCode);

  /// Label de catégorie (depuis la BDD ou fallback)
  String get categoryDisplayLabel => categoryLabel ?? category.label;

  /// Emoji selon le nom de la plante
  String get emoji {
    final name = commonName.toLowerCase();

    // Légumes fruits
    if (name.contains('tomate')) return '🍅';
    if (name.contains('poivron') || name.contains('piment')) return '🫑';
    if (name.contains('aubergine')) return '🍆';
    if (name.contains('concombre') || name.contains('cornichon')) return '🥒';
    if (name.contains('courgette')) return '🥒';
    if (name.contains('melon')) return '🍈';
    if (name.contains('pastèque')) return '🍉';

    // Courges
    if (_matchesAny(name, [
      'courge',
      'potiron',
      'potimarron',
      'citrouille',
      'butternut',
      'patisson',
    ]))
      return '🎃';

    // Légumes feuilles
    if (_matchesAny(name, ['salade', 'laitue', 'épinard', 'mâche', 'roquette']))
      return '🥬';
    if (name.contains('chou')) return '🥬';
    if (_matchesAny(name, ['bette', 'blette'])) return '🥬';

    // Légumes racines
    if (name.contains('carotte')) return '🥕';
    if (name.contains('radis')) return '🥕';
    if (name.contains('navet')) return '🥕';
    if (name.contains('betterave')) return '🥕';
    if (name.contains('panais')) return '🥕';
    if (name.contains('pomme de terre')) return '🥔';
    if (name.contains('patate')) return '🍠';
    if (name.contains('topinambour')) return '🥔';

    // Bulbes
    if (name.contains('oignon')) return '🧅';
    if (name.contains('ail')) return '🧄';
    if (name.contains('échalote')) return '🧅';
    if (name.contains('poireau')) return '🧅';

    // Légumineuses
    if (name.contains('haricot')) return '🫛';
    if (name.contains('pois')) return '🫛';
    if (name.contains('fève')) return '🫛';

    // Petits fruits
    if (name.contains('fraise')) return '🍓';
    if (name.contains('framboise')) return '🫐';
    if (name.contains('groseille')) return '🫐';
    if (name.contains('cassis')) return '🫐';
    if (name.contains('myrtille')) return '🫐';
    if (name.contains('rhubarbe')) return '🌿';

    // Aromates
    if (name.contains('lavande')) return '💜';
    if (_matchesAny(name, [
      'basilic',
      'persil',
      'ciboulette',
      'menthe',
      'thym',
      'romarin',
      'coriandre',
      'aneth',
      'estragon',
      'sauge',
      'origan',
      'cerfeuil',
      'marjolaine',
      'sarriette',
    ]))
      return '🌿';

    // Autres
    if (name.contains('artichaut')) return '🌻';
    if (name.contains('maïs')) return '🌽';
    if (name.contains('brocoli') || name.contains('chou-fleur')) return '🥦';
    if (name.contains('asperge')) return '🌿';
    if (name.contains('fenouil')) return '🌿';
    if (name.contains('céleri')) return '🌿';

    // Fleurs
    if (name.contains('tournesol')) return '🌻';
    if (name.contains('capucine')) return '🌺';
    if (name.contains('souci')) return '🌼';
    if (name.contains('œillet')) return '🌸';

    // Défaut selon la catégorie
    switch (categoryCode) {
      case 'fruit_vegetable':
        return '🍅';
      case 'leafy_green':
        return '🥬';
      case 'root':
        return '🥕';
      case 'tuber':
        return '🥔';
      case 'allium':
        return '🧅';
      case 'legume':
        return '🫛';
      case 'herb':
        return '🌿';
      case 'fruit':
        return '🍓';
      case 'stem':
        return '🌿';
      case 'flower':
        return '🌸';
      case 'grain':
        return '🌾';
      default:
        return '🌱';
    }
  }

  bool _matchesAny(String name, List<String> keywords) {
    return keywords.any((kw) => name.contains(kw));
  }

  /// Icône d'exposition au soleil
  String get sunIcon {
    final exposure = sunExposure?.toLowerCase() ?? '';
    if (exposure.contains('ombrag')) return '🌥️';
    if (exposure.contains('mi-ombre')) return '⛅';
    return '☀️';
  }

  /// Label court pour l'exposition
  String get sunLabel {
    final exposure = sunExposure?.toLowerCase() ?? '';
    if (exposure.contains('ombrag')) return 'Ombragé';
    if (exposure.contains('mi-ombre')) return 'Mi-ombre';
    if (exposure.contains('ensoleill')) return 'Ensoleillé';
    return sunExposure ?? 'Non défini';
  }
}
