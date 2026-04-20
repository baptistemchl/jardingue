import 'dart:io' show Platform;

/// Mapping centralisé des emojis pour les plantes.
/// Utilise le nom commun pour trouver l'emoji le plus
/// pertinent, avec fallback sur le code catégorie.
class PlantEmojiMapper {
  PlantEmojiMapper._();

  /// Remplace les emojis Unicode 14+ par des équivalents
  /// Unicode 6 (universels) sur les OS trop anciens — sinon
  /// l'utilisateur voit un carré "tofu". La bascule est
  /// globale : Android 14 (API 34) / iOS 17.4+ pour Unicode
  /// 15.1, ce qui couvre aussi Unicode 14.
  static const _legacyFallbacks = <String, String>{
    '\u{1FADC}': '\u{1F955}', // root vegetable → carotte
    '\u{1FADA}': '\u{1F954}', // ginger root → pomme de terre
    '\u{1FAD8}': '\u{1F331}', // beans → seedling
    '\u{1FADB}': '\u{1F331}', // pea pod → seedling
    '\u{1FABB}': '\u{1F49C}', // hyacinth → coeur violet
  };

  static bool? _cachedModernSupport;

  static bool get _supportsModernEmojis {
    final cached = _cachedModernSupport;
    if (cached != null) return cached;
    final result = _detectModernEmojiSupport();
    _cachedModernSupport = result;
    return result;
  }

  static bool _detectModernEmojiSupport() {
    try {
      if (Platform.isAndroid) {
        // Format typique : "14" ou "Android 14 (API 34)".
        final v = Platform.operatingSystemVersion;
        final apiMatch = RegExp(r'API\s+(\d+)').firstMatch(v);
        if (apiMatch != null) {
          return int.parse(apiMatch.group(1)!) >= 34;
        }
        final majorMatch = RegExp(r'(\d+)').firstMatch(v);
        if (majorMatch != null) {
          return int.parse(majorMatch.group(1)!) >= 14;
        }
        return false;
      }
      if (Platform.isIOS) {
        final v = Platform.operatingSystemVersion;
        final m =
            RegExp(r'(\d+)\.(\d+)').firstMatch(v);
        if (m != null) {
          final major = int.parse(m.group(1)!);
          final minor = int.parse(m.group(2)!);
          return major > 17 || (major == 17 && minor >= 4);
        }
        return false;
      }
      // Desktop / autres : on assume une police récente.
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Visible pour les tests : permet de forcer le mode
  /// legacy ou moderne sans dépendre de la plateforme.
  static void debugSetModernEmojiSupport(bool? value) {
    _cachedModernSupport = value;
  }

  static String _withFallback(String emoji) {
    if (_supportsModernEmojis) return emoji;
    return _legacyFallbacks[emoji] ?? emoji;
  }

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
    'radis': '\u{1FADC}',
    'navet': '\u{1FADC}',
    'betterave': '\u{1F360}',
    'panais': '\u{1F955}',
    // Ordre important : "patate douce" doit matcher
    // avant "patate" (iteration sur insertion order).
    'patate douce': '\u{1F360}',
    'pomme de terre': '\u{1F954}',
    'patate': '\u{1F954}',
    'topinambour': '\u{1FADA}',

    // Bulbes
    'oignon': '\u{1F9C5}',
    'echalote': '\u{1F9C5}',
    'poireau': '\u{1F9C5}',
    'ail': '\u{1F9C4}',

    // Legumineuses
    'haricot': '\u{1FAD8}',
    'pois': '\u{1FADB}',
    'feve': '\u{1FAD8}',

    // Petits fruits
    'fraise': '\u{1F353}',
    'framboise': '\u{1FAD0}',
    'groseille': '\u{1FAD0}',
    'cassis': '\u{1FAD0}',
    'myrtille': '\u{1FAD0}',
    'rhubarbe': '\u{1F33F}',

    // Aromates
    'lavande': '\u{1FABB}',
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
    'artichaut': '\u{1F33F}',
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
      if (lower.contains(entry.key)) {
        return _withFallback(entry.value);
      }
    }
    if (categoryCode != null) {
      return _withFallback(
        _categoryToEmoji[categoryCode] ?? fallback,
      );
    }
    return fallback;
  }

  /// Retourne l'emoji pour un code categorie.
  static String fromCategory(String? categoryCode) {
    if (categoryCode == null) return fallback;
    return _withFallback(
      _categoryToEmoji[categoryCode] ?? fallback,
    );
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
