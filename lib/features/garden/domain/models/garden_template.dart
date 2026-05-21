/// Définition d'un modèle de potager prêt-à-l'emploi (template).
///
/// Stocké en JSON statique dans `assets/data/garden_templates.json` et
/// résolu par nom commun de plante au moment de l'application (le service
/// requête la DB pour obtenir les ids). Cohérent avec les réimports du
/// catalogue : si les ids changent, les noms restent.
class GardenTemplate {
  final String id;
  final String name;
  final String emoji;
  final String description;

  /// Niveau d'expérience suggéré : "Débutant", "Intermédiaire", "Confirmé".
  final String level;
  final double widthMeters;
  final double heightMeters;
  final int cellSizeCm;
  final List<TemplatePlant> plants;

  const GardenTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.level,
    required this.widthMeters,
    required this.heightMeters,
    required this.cellSizeCm,
    required this.plants,
  });

  factory GardenTemplate.fromJson(Map<String, dynamic> json) {
    final rawPlants = (json['plants'] as List<dynamic>? ?? []);
    return GardenTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      description: json['description'] as String,
      level: json['level'] as String,
      widthMeters: (json['width_m'] as num).toDouble(),
      heightMeters: (json['height_m'] as num).toDouble(),
      cellSizeCm: json['cell_size_cm'] as int,
      plants: rawPlants
          .map((p) => TemplatePlant.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Position d'une plante dans un template. La référence se fait par
/// `plantName` (résolu dynamiquement par le service contre `Plants.commonName`)
/// plutôt que par id, pour résister aux réimports.
class TemplatePlant {
  final String plantName;
  final int xCells;
  final int yCells;
  final int wCells;
  final int hCells;

  const TemplatePlant({
    required this.plantName,
    required this.xCells,
    required this.yCells,
    required this.wCells,
    required this.hCells,
  });

  factory TemplatePlant.fromJson(Map<String, dynamic> json) {
    return TemplatePlant(
      plantName: json['plant_name'] as String,
      xCells: json['x_cells'] as int,
      yCells: json['y_cells'] as int,
      wCells: json['w_cells'] as int,
      hCells: json['h_cells'] as int,
    );
  }
}
