/// Categories de plantes (basees sur category_code du JSON).
enum PlantCategory {
  all('Tous', '\u{1F331}', null),
  fruitVegetable('Legumes-fruits', '\u{1F345}', 'fruit_vegetable'),
  leafyGreen('Legumes-feuilles', '\u{1F96C}', 'leafy_green'),
  root('Legumes-racines', '\u{1F955}', 'root'),
  tuber('Tubercules', '\u{1F954}', 'tuber'),
  allium('Bulbes', '\u{1F9C5}', 'allium'),
  legume('Legumineuses', '\u{1FADB}', 'legume'),
  herb('Aromates', '\u{1F33F}', 'herb'),
  fruit('Petits fruits', '\u{1F353}', 'fruit'),
  stem('Legumes-tiges', '\u{1F33F}', 'stem'),
  flower('Fleurs', '\u{1F338}', 'flower'),
  grain('Grains', '\u{1F33E}', 'grain');

  final String label;
  final String emoji;
  final String? code;

  const PlantCategory(this.label, this.emoji, this.code);

  String get displayLabel => '$emoji $label';

  static PlantCategory fromCode(String? code) {
    if (code == null) return all;
    for (final category in values) {
      if (category.code == code) return category;
    }
    return all;
  }
}

/// Filtres d'exposition soleil.
enum PlantSunFilter {
  all('Tous', null),
  fullSun('\u{2600}\u{FE0F} Ensoleille', 'ensoleill\u{00e9}'),
  partialShade('\u{26C5} Mi-ombre', 'mi-ombre'),
  shade('\u{1F325}\u{FE0F} Ombrage', 'ombrag\u{00e9}');

  final String label;
  final String? value;

  const PlantSunFilter(this.label, this.value);
}

/// Etat complet des filtres de plantes.
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
          searchQuery == other.searchQuery &&
          category == other.category &&
          sunFilter == other.sunFilter;

  @override
  int get hashCode => Object.hash(
        searchQuery,
        category,
        sunFilter,
      );
}
