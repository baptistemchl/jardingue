/// Categories d'arbres fruitiers.
enum FruitTreeCategory {
  all('Tous', '\u{1F333}', null),
  arbreFruitier('Arbres', '\u{1F333}', 'arbre_fruitier'),
  arbusteFruitier('Arbustes', '\u{1F33F}', 'arbuste_fruitier'),
  petitFruit('Petits fruits', '\u{1F353}', 'petit_fruit'),
  lianeFruitiere('Lianes', '\u{1F347}', 'liane_fruitiere');

  final String label;
  final String emoji;
  final String? code;

  const FruitTreeCategory(this.label, this.emoji, this.code);

  String get displayLabel => '$emoji $label';

  static FruitTreeCategory fromCode(String? code) {
    if (code == null) return all;
    for (final category in values) {
      if (category.code == code) return category;
    }
    return all;
  }
}

/// Etat des filtres pour arbres fruitiers.
class FruitTreesFilterState {
  final String searchQuery;
  final FruitTreeCategory category;
  final bool? selfFertileOnly;
  final bool? containerSuitableOnly;

  const FruitTreesFilterState({
    this.searchQuery = '',
    this.category = FruitTreeCategory.all,
    this.selfFertileOnly,
    this.containerSuitableOnly,
  });

  FruitTreesFilterState copyWith({
    String? searchQuery,
    FruitTreeCategory? category,
    bool? selfFertileOnly,
    bool? containerSuitableOnly,
  }) {
    return FruitTreesFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      selfFertileOnly: selfFertileOnly ?? this.selfFertileOnly,
      containerSuitableOnly:
          containerSuitableOnly ?? this.containerSuitableOnly,
    );
  }

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      category != FruitTreeCategory.all ||
      selfFertileOnly == true ||
      containerSuitableOnly == true;
}
