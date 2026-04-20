import '../../../../core/services/database/app_database.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import 'plants_filter_state.dart';

/// Normalisation tolerante pour la recherche de plantes :
/// minuscules, suppression des accents et des separateurs courants
/// (tirets, espaces, apostrophes). Permet a "choux fleurs", "choufleur"
/// ou "Choux-Fleurs" de matcher la meme plante.
String normalizePlantSearch(String input) {
  const withAccents = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const without =    'aaaaaaceeeeiiiinoooooouuuuyy';
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final code in lower.runes) {
    final ch = String.fromCharCode(code);
    final idx = withAccents.indexOf(ch);
    if (idx >= 0) {
      buffer.write(without[idx]);
    } else if (ch == '-' || ch == '\'' || ch == '\u2019' || ch == ' ') {
      // Ignorer tirets, apostrophes, espaces.
      continue;
    } else {
      buffer.write(ch);
    }
  }
  return buffer.toString();
}

/// Extensions utilitaires pour le modele Plant de Drift.
extension PlantHelpers on Plant {
  PlantCategory get category {
    return PlantCategory.fromCode(categoryCode);
  }

  String get categoryDisplayLabel {
    return categoryLabel ?? category.label;
  }

  String get emoji {
    return PlantEmojiMapper.fromName(
      commonName,
      categoryCode: categoryCode,
    );
  }

  String get sunIcon {
    final exposure = sunExposure?.toLowerCase() ?? '';
    if (exposure.contains('ombrag')) return '\u{1F325}\u{FE0F}';
    if (exposure.contains('mi-ombre')) return '\u{26C5}';
    return '\u{2600}\u{FE0F}';
  }

  String get sunLabel {
    final exposure = sunExposure?.toLowerCase() ?? '';
    if (exposure.contains('ombrag')) return 'Ombrage';
    if (exposure.contains('mi-ombre')) return 'Mi-ombre';
    if (exposure.contains('ensoleill')) return 'Ensoleille';
    return sunExposure ?? 'Non defini';
  }
}
