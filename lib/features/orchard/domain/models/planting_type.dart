/// Type de plantation choisi par l'utilisateur pour SON arbre.
///
/// La valeur stockée en DB est [dbValue] (lower-snake, stable). Toute valeur
/// inconnue lue depuis la DB (rare : import depuis backup tiers, downgrade
/// fonctionnel...) retombe sur [ground] pour éviter un crash d'affichage.
enum PlantingType {
  ground('ground', '🌱', 'Pleine terre'),
  pot('pot', '🪴', 'En pot'),
  espalier('espalier', '🧱', 'Espalier / Palissé');

  final String dbValue;
  final String emoji;
  final String label;

  const PlantingType(this.dbValue, this.emoji, this.label);

  static PlantingType? fromDbValue(String? value) {
    if (value == null) return null;
    for (final t in PlantingType.values) {
      if (t.dbValue == value) return t;
    }
    return PlantingType.ground;
  }
}
