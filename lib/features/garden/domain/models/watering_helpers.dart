/// Statut d'arrosage d'une plante au moment présent.
enum WateringStatus {
  /// Jamais arrosée (aucun event d'arrosage enregistré).
  never,
  /// Arrosée récemment, prochain arrosage pas encore dû.
  upToDate,
  /// Prochain arrosage dû aujourd'hui ou dans <=1 jour.
  dueSoon,
  /// Prochain arrosage passé depuis plus d'1 jour.
  overdue,
}

/// Calcule le statut d'arrosage d'une plante à un instant donné.
/// [lastWatered] : date du dernier arrosage, null si aucun.
/// [frequencyDays] : intervalle d'arrosage demandé (jours).
/// [now] : instant de référence (override pour tests).
WateringStatus computeWateringStatus({
  required DateTime? lastWatered,
  required int frequencyDays,
  required DateTime now,
}) {
  if (lastWatered == null) return WateringStatus.never;
  final diff = now.difference(lastWatered).inHours;
  final freqHours = frequencyDays * 24;
  if (diff < freqHours - 24) return WateringStatus.upToDate;
  if (diff < freqHours + 24) return WateringStatus.dueSoon;
  return WateringStatus.overdue;
}

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
