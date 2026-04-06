import '../../../../core/services/database/app_database.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import 'plants_filter_state.dart';

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
