/// Déduit une fréquence d'arrosage en jours à partir du texte descriptif de la plante.
int defaultWateringFrequencyDays(String? wateringText) {
  if (wateringText == null || wateringText.isEmpty) return 3;
  final lower = wateringText.toLowerCase();
  if (lower.contains('abondant') ||
      lower.contains('régulier') ||
      lower.contains('regulier') ||
      lower.contains('fréquent') ||
      lower.contains('frequent')) {
    return 2;
  }
  if (lower.contains('modéré') ||
      lower.contains('modere') ||
      lower.contains('moyen') ||
      lower.contains('normal')) {
    return 3;
  }
  if (lower.contains('faible') ||
      lower.contains('peu') ||
      lower.contains('rare') ||
      lower.contains('limité')) {
    return 5;
  }
  return 3;
}
