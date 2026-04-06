/// Mapping centralisé des emojis pour les plantes.
/// Utilise le nom commun pour trouver l'emoji le plus
/// pertinent, avec fallback sur le code catégorie.
class PlantEmojiMapper {
  PlantEmojiMapper._();

  static const _nameToEmoji = <String, String>{
    // Legumes fruits
    'tomate': '\u{1F345}',
    'poivron': '\u{1FAD1}',
    'piment': '\u{1FAD1}',
    'aubergine': '\u{1F346}',
    'concombre': '\u{1F952}',
    'cornichon': '\u{1F952}',
    'courgette': '\u{1F952}',
    'melon': '\u{1F348}',
    'pasteque': '\u{1F349}',

    // Courges
    'courge': '\u{1F383}',
    'potiron': '\u{1F383}',
    'potimarron': '\u{1F383}',
    'citrouille': '\u{1F383}',
    'butternut': '\u{1F383}',
    'patisson': '\u{1F383}',

    // Legumes feuilles
    'salade': '\u{1F96C}',
    'laitue': '\u{1F96C}',
    'epinard': '\u{1F96C}',
    'mache': '\u{1F96C}',
    'roquette': '\u{1F96C}',
    'chou': '\u{1F96C}',
    'bette': '\u{1F96C}',
    'blette': '\u{1F96C}',

    // Legumes racines
    'carotte': '\u{1F955}',
    'radis': '\u{1F955}',
    'navet': '\u{1F955}',
    'betterave': '\u{1F955}',
    'panais': '\u{1F955}',
    'pomme de terre': '\u{1F954}',
    'patate': '\u{1F360}',
    'topinambour': '\u{1F954}',

    // Bulbes
    'oignon': '\u{1F9C5}',
    'echalote': '\u{1F9C5}',
    'poireau': '\u{1F9C5}',
    'ail': '\u{1F9C4}',

    // Legumineuses
    'haricot': '\u{1FADB}',
    'pois': '\u{1FADB}',
    'feve': '\u{1FADB}',

    // Petits fruits
    'fraise': '\u{1F353}',
    'framboise': '\u{1FAD0}',
    'groseille': '\u{1FAD0}',
    'cassis': '\u{1FAD0}',
    'myrtille': '\u{1FAD0}',
    'rhubarbe': '\u{1F33F}',

    // Aromates
    'lavande': '\u{1F49C}',
    'basilic': '\u{1F33F}',
    'persil': '\u{1F33F}',
    'ciboulette': '\u{1F33F}',
    'menthe': '\u{1F33F}',
    'thym': '\u{1F33F}',
    'romarin': '\u{1F33F}',
    'coriandre': '\u{1F33F}',
    'aneth': '\u{1F33F}',
    'estragon': '\u{1F33F}',
    'sauge': '\u{1F33F}',
    'origan': '\u{1F33F}',
    'cerfeuil': '\u{1F33F}',
    'marjolaine': '\u{1F33F}',
    'sarriette': '\u{1F33F}',

    // Autres legumes
    'artichaut': '\u{1F33B}',
    'mais': '\u{1F33D}',
    'brocoli': '\u{1F966}',
    'chou-fleur': '\u{1F966}',
    'asperge': '\u{1F33F}',
    'fenouil': '\u{1F33F}',
    'celeri': '\u{1F33F}',

    // Fleurs
    'tournesol': '\u{1F33B}',
    'capucine': '\u{1F33A}',
    'souci': '\u{1F33C}',
    'oeillet': '\u{1F338}',
  };

  static const _categoryToEmoji = <String, String>{
    'fruit_vegetable': '\u{1F345}',
    'leafy_green': '\u{1F96C}',
    'root': '\u{1F955}',
    'tuber': '\u{1F954}',
    'allium': '\u{1F9C5}',
    'legume': '\u{1FADB}',
    'herb': '\u{1F33F}',
    'fruit': '\u{1F353}',
    'stem': '\u{1F33F}',
    'flower': '\u{1F338}',
    'grain': '\u{1F33E}',
  };

  static const fallback = '\u{1F331}';

  /// Retourne l'emoji correspondant au nom commun de
  /// la plante, avec fallback sur la categorie.
  static String fromName(
    String commonName, {
    String? categoryCode,
  }) {
    final lower = _normalize(commonName);
    for (final entry in _nameToEmoji.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    if (categoryCode != null) {
      return _categoryToEmoji[categoryCode] ?? fallback;
    }
    return fallback;
  }

  /// Retourne l'emoji pour un code categorie.
  static String fromCategory(String? categoryCode) {
    if (categoryCode == null) return fallback;
    return _categoryToEmoji[categoryCode] ?? fallback;
  }

  /// Normalise les accents pour la recherche.
  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00e8', 'e')
        .replaceAll('\u00ea', 'e')
        .replaceAll('\u00e0', 'a')
        .replaceAll('\u00e2', 'a')
        .replaceAll('\u00f4', 'o')
        .replaceAll('\u00ee', 'i')
        .replaceAll('\u00fb', 'u')
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u0153', 'oe');
  }
}
