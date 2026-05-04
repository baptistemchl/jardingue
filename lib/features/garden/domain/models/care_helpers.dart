/// Statut d'un soin recurrent (arrosage, fertilisation, renouvellement de
/// piege a pheromones...) au moment present.
///
/// Generique : la meme echelle s'applique a toute action periodique basee
/// sur (date de reference + intervalle en jours).
enum CareStatus {
  /// Jamais effectue (aucun event ou installation enregistre).
  never,

  /// Effectue recemment, prochaine echeance pas encore due.
  upToDate,

  /// Echeance aujourd'hui ou dans <=1 jour.
  dueSoon,

  /// Echeance passee depuis plus d'1 jour.
  overdue,
}

/// Calcule le statut d'un soin a un instant donne.
///
/// [lastDate] : derniere occurrence (arrosage, fertilisation, pose du piege).
/// [frequencyDays] : intervalle attendu en jours.
/// [now] : instant de reference (override pour tests).
///
/// Fenetre de tolerance : +/- 24h autour de la date due pour eviter les
/// flickerings dueSoon/overdue lies aux fuseaux horaires ou aux events
/// poses tot le matin.
CareStatus computeCareStatus({
  required DateTime? lastDate,
  required int frequencyDays,
  required DateTime now,
}) {
  if (lastDate == null) return CareStatus.never;
  final diff = now.difference(lastDate).inHours;
  final freqHours = frequencyDays * 24;
  if (diff < freqHours - 24) return CareStatus.upToDate;
  if (diff < freqHours + 24) return CareStatus.dueSoon;
  return CareStatus.overdue;
}

/// Deduit une frequence d'arrosage en jours a partir du texte descriptif.
///
/// Conserve pour compatibilite avec l'ancien systeme (le champ `watering`
/// est un texte libre dans le catalogue, pas un entier).
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

/// Frequence de fertilisation par defaut (jours) deduite de la categorie
/// de la plante quand le catalogue n'a pas de valeur explicite.
///
/// Ordres de grandeur etablis a partir des sources horticoles :
/// - legumes "gourmands" (tomate, courgette, mais) : ~21j
/// - legumes feuilles standards : ~30j
/// - racines / aromatiques : ~45j
/// - legumineuses (fixent l'azote) : ~60j
/// - fallback general : 30j
int defaultFertilizationFrequencyDays(String? categoryCode) {
  switch (categoryCode) {
    case 'fruit_vegetable':
      return 21;
    case 'leafy_green':
      return 30;
    case 'root':
    case 'tuber':
    case 'allium':
    case 'herb':
      return 45;
    case 'legume':
      return 60;
    case 'fruit':
      return 90;
    default:
      return 30;
  }
}
