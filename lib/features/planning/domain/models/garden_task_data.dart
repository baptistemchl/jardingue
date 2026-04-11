/// Catégories de tâches potagères générales.
enum GardenTaskCategory {
  soil('Travail du sol', '⛏️'),
  fertilization('Fumure & Amendement', '💩'),
  greenhouse('Serre & Abris', '🏠'),
  protection('Protection', '🛡️'),
  maintenance('Entretien', '🧹'),
  watering('Arrosage', '💧'),
  composting('Compostage', '♻️'),
  planning('Organisation', '📋'),
  mulching('Paillage', '🍂'),
  tools('Outillage', '🔧');

  final String label;
  final String emoji;

  const GardenTaskCategory(
    this.label,
    this.emoji,
  );

  static GardenTaskCategory? fromString(
    String value,
  ) {
    for (final cat in values) {
      if (cat.name == value) return cat;
    }
    return null;
  }
}

/// Tâche potagère chargée depuis le JSON.
class GardenTaskData {
  final String id;
  final String title;
  final String description;
  final GardenTaskCategory category;
  final List<int> months;
  final String priority;
  final GardenTaskConditions? conditions;

  const GardenTaskData({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.months,
    required this.priority,
    this.conditions,
  });

  bool appliesToMonth(int month) =>
      months.contains(month);

  factory GardenTaskData.fromJson(
    Map<String, dynamic> json,
  ) {
    GardenTaskConditions? conditions;
    if (json['conditions'] != null) {
      conditions = GardenTaskConditions.fromJson(
        json['conditions'] as Map<String, dynamic>,
      );
    }

    return GardenTaskData(
      id: json['id'] as String,
      title: json['title'] as String,
      description:
          json['description'] as String,
      category:
          GardenTaskCategory.fromString(
                json['category'] as String,
              ) ??
              GardenTaskCategory.maintenance,
      months: (json['months'] as List<dynamic>)
          .cast<int>(),
      priority:
          (json['priority'] as String?) ?? 'medium',
      conditions: conditions,
    );
  }
}

/// Conditions météo optionnelles pour une tâche.
class GardenTaskConditions {
  final double? minTemp;
  final double? maxTemp;
  final bool requiresDry;

  const GardenTaskConditions({
    this.minTemp,
    this.maxTemp,
    this.requiresDry = false,
  });

  factory GardenTaskConditions.fromJson(
    Map<String, dynamic> json,
  ) {
    return GardenTaskConditions(
      minTemp: (json['min_temp'] as num?)
          ?.toDouble(),
      maxTemp: (json['max_temp'] as num?)
          ?.toDouble(),
      requiresDry:
          (json['requires_dry'] as bool?) ?? false,
    );
  }
}
