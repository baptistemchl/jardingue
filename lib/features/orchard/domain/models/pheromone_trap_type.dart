/// Types de pieges a pheromones reconnus par l'application.
///
/// Liste fermee : un piege a pheromones cible un ravageur specifique
/// (la molecule diffuse n'attire que les males d'une espece). Les durees
/// de vie listees correspondent aux capsules longue duree communement
/// disponibles dans le commerce horticole francais (sources : Insectosphere,
/// Andermatt, Comptoir des Jardins, Jardins Animes).
enum PheromoneTrapType {
  /// Carpocapse des pommes/poires/noix (Cydia pomonella). Capsules
  /// longue duree : 90 jours typique. Cycle d'activite mai-aout.
  codlingMoth(
    label: 'Carpocapse',
    scientificName: 'Cydia pomonella',
    emoji: '🍎',
    defaultLifetimeDays: 90,
    targetTreesFr: ['Pommier', 'Poirier', 'Noyer', 'Cognassier'],
    description:
        'Pour pommiers, poiriers et noyers. Cible les vers du carpocapse, '
        'principal ravageur des fruits a pepins. Saison : mai-aout.',
  ),

  /// Mouche de la cerise (Rhagoletis cerasi). 2 capsules par saison
  /// suffisent typiquement (mai a recolte).
  cherryFruitFly(
    label: 'Mouche de la cerise',
    scientificName: 'Rhagoletis cerasi',
    emoji: '🍒',
    defaultLifetimeDays: 56,
    targetTreesFr: ['Cerisier'],
    description:
        'Pour cerisiers. Cible les vers blancs dans les cerises mures. '
        'Saison : debut mai jusqu\'a la recolte.',
  ),

  /// Tordeuse orientale du pecher (Cydia molesta). Aussi efficace
  /// sur prunier. Capsules ~84 jours.
  orientalFruitMoth(
    label: 'Tordeuse orientale',
    scientificName: 'Cydia molesta',
    emoji: '🍑',
    defaultLifetimeDays: 84,
    targetTreesFr: ['Pêcher', 'Prunier', 'Abricotier'],
    description:
        'Pour pechers et pruniers. Cible la tordeuse qui creuse galeries '
        'et fruits. Saison : avril-septembre, generations multiples.',
  ),

  /// Mouche de l'olive (Bactrocera oleae). Capsules ~60 jours.
  oliveFly(
    label: 'Mouche de l\'olive',
    scientificName: 'Bactrocera oleae',
    emoji: '🫒',
    defaultLifetimeDays: 60,
    targetTreesFr: ['Olivier'],
    description:
        'Pour oliviers. Cible la mouche dont les larves se nourrissent de '
        'la pulpe des olives. Saison : ete-automne.',
  ),

  /// Mouche du brou du noyer (Rhagoletis completa). Specifique noyer.
  walnutHuskFly(
    label: 'Mouche du brou',
    scientificName: 'Rhagoletis completa',
    emoji: '🌰',
    defaultLifetimeDays: 60,
    targetTreesFr: ['Noyer'],
    description:
        'Pour noyers. Cible la mouche qui pond dans le brou des noix. '
        'Saison : juillet-septembre.',
  );

  const PheromoneTrapType({
    required this.label,
    required this.scientificName,
    required this.emoji,
    required this.defaultLifetimeDays,
    required this.targetTreesFr,
    required this.description,
  });

  /// Libelle utilisateur (francais).
  final String label;

  /// Nom scientifique du ravageur cible.
  final String scientificName;

  /// Emoji representatif (en general un fruit cible).
  final String emoji;

  /// Duree de vie typique d'une capsule longue duree (jours).
  /// L'utilisateur peut surcharger cette valeur a la pose.
  final int defaultLifetimeDays;

  /// Noms communs (FR) des arbres pour lesquels ce piege est pertinent.
  /// Sert a filtrer les types proposes lors de l'ajout selon l'arbre cible.
  final List<String> targetTreesFr;

  /// Description courte affichee dans la sheet de selection.
  final String description;

  /// Resout depuis le name stocke en DB. Fallback : carpocapse (le plus
  /// commun) plutot que de planter sur une corruption silencieuse.
  static PheromoneTrapType fromString(String s) =>
      values.firstWhere((e) => e.name == s, orElse: () => codlingMoth);

  /// True si ce type est recommande pour un arbre dont le `commonName`
  /// (du catalogue FruitTree) est passe en parametre. Match insensible
  /// a la casse / accents (le matching exact suffit ici car la liste de
  /// targetTreesFr est curee a la main).
  bool isRelevantFor(String fruitTreeCommonName) {
    final lower = fruitTreeCommonName.toLowerCase();
    return targetTreesFr.any((t) => lower.contains(t.toLowerCase()));
  }
}
