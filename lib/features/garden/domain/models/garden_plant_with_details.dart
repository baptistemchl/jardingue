import '../../../../core/services/database/app_database.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import 'zone_type.dart';

/// Modele combinant un element du potager (plante ou zone)
/// avec les details de la plante associee.
class GardenPlantWithDetails {
  final GardenPlant gardenPlant;
  final Plant? plant;

  const GardenPlantWithDetails({
    required this.gardenPlant,
    this.plant,
  });

  int get id => gardenPlant.id;
  int get gridX => gardenPlant.gridX;
  int get gridY => gardenPlant.gridY;
  int get widthCells => gardenPlant.widthCells;
  int get heightCells => gardenPlant.heightCells;
  String? get notes => gardenPlant.notes;
  DateTime? get plantedAt => gardenPlant.plantedAt;
  bool get isZone => gardenPlant.plantId == 0;

  /// True si la plante a ete ajoutee mais pas encore placee sur le plan
  bool get isPendingPlacement => gardenPlant.gridX < 0 || gardenPlant.gridY < 0;

  ZoneType? get zoneType {
    if (!isZone || notes == null) return null;
    final typeName = notes!.split('|').first;
    return ZoneType.fromName(typeName);
  }

  String get emoji {
    if (isZone) return zoneType?.emoji ?? '\u{2B1B}';
    if (plant == null) return PlantEmojiMapper.fallback;
    return PlantEmojiMapper.fromName(
      plant!.commonName,
      categoryCode: plant!.categoryCode,
    );
  }

  String get name {
    if (isZone) return zoneType?.label ?? 'Zone';
    return plant?.commonName ?? 'Plante';
  }

  int get color {
    if (isZone) return zoneType?.color ?? 0xFF9E9E9E;
    return _colorFromCategory(plant?.categoryCode);
  }

  double xMeters(int cellSizeCm) => gridX * cellSizeCm / 100;
  double yMeters(int cellSizeCm) => gridY * cellSizeCm / 100;
  double widthMeters(int cellSizeCm) {
    return widthCells * cellSizeCm / 100;
  }

  double heightMeters(int cellSizeCm) {
    return heightCells * cellSizeCm / 100;
  }

  static int _colorFromCategory(String? categoryCode) {
    return switch (categoryCode) {
      'leafy_green' => 0xFF4CAF50,
      'root' => 0xFFFF9800,
      'fruit_vegetable' => 0xFFF44336,
      'legume' => 0xFF8BC34A,
      'herb' => 0xFF009688,
      'allium' => 0xFF9C27B0,
      'tuber' => 0xFF795548,
      'fruit' => 0xFFE91E63,
      _ => 0xFF4CAF50,
    };
  }
}
