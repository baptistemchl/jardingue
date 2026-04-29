/// Familles botaniques pertinentes pour la rotation des cultures au potager.
/// On ne garde que les familles qui ont un réel impact sur la rotation,
/// les autres (menthes, fraisiers, asperges vivaces...) sont regroupées
/// en "other" — pas d'alerte déclenchée.
enum RotationFamily {
  /// Tomate, pomme de terre, poivron, aubergine, piment.
  solanaceae('solanaceae', 'Solanacées'),

  /// Courge, courgette, concombre, melon, patisson.
  cucurbitaceae('cucurbitaceae', 'Cucurbitacées'),

  /// Chou, radis, navet, roquette, moutarde.
  brassicaceae('brassicaceae', 'Brassicacées'),

  /// Oignon, ail, poireau, échalote, ciboulette.
  alliaceae('alliaceae', 'Alliacées'),

  /// Haricot, pois, fève (fixateurs d'azote).
  fabaceae('fabaceae', 'Fabacées'),

  /// Carotte, persil, céleri, panais, fenouil.
  apiaceae('apiaceae', 'Apiacées'),

  /// Laitue, chicorée, endive, artichaut, topinambour.
  asteraceae('asteraceae', 'Astéracées'),

  /// Épinard, betterave, blette, arroche.
  chenopodiaceae('chenopodiaceae', 'Chénopodiacées'),

  /// Basilic, menthe, thym, romarin, sauge, origan.
  lamiaceae('lamiaceae', 'Lamiacées'),

  /// Maïs, blé (Poacées).
  poaceae('poaceae', 'Poacées'),

  /// Autres (rhubarbe, asperge, fraisier...) — pas d'alerte.
  other('other', 'Autres');

  final String code;
  final String label;
  const RotationFamily(this.code, this.label);

  static RotationFamily? fromCode(String? code) {
    if (code == null) return null;
    for (final f in RotationFamily.values) {
      if (f.code == code) return f;
    }
    return null;
  }

  /// Résout la famille à partir du nom latin (ex: "Solanum lycopersicum").
  /// Retourne null si le genre n'est pas reconnu — on stocke alors "other".
  static RotationFamily? fromLatinName(String? latinName) {
    if (latinName == null || latinName.trim().isEmpty) return null;
    // Premier mot = genre.
    final genus = latinName.trim().split(RegExp(r'\s+')).first.toLowerCase();
    return _genusToFamily[genus];
  }

  static const Map<String, RotationFamily> _genusToFamily = {
    // Solanacées
    'solanum': RotationFamily.solanaceae,
    'capsicum': RotationFamily.solanaceae,
    'lycopersicon': RotationFamily.solanaceae,
    // Cucurbitacées
    'cucurbita': RotationFamily.cucurbitaceae,
    'cucumis': RotationFamily.cucurbitaceae,
    'sechium': RotationFamily.cucurbitaceae,
    'citrullus': RotationFamily.cucurbitaceae,
    'lagenaria': RotationFamily.cucurbitaceae,
    // Brassicacées
    'brassica': RotationFamily.brassicaceae,
    'raphanus': RotationFamily.brassicaceae,
    'eruca': RotationFamily.brassicaceae,
    'diplotaxis': RotationFamily.brassicaceae,
    'lepidium': RotationFamily.brassicaceae,
    'nasturtium': RotationFamily.brassicaceae,
    'sinapis': RotationFamily.brassicaceae,
    // Alliacées
    'allium': RotationFamily.alliaceae,
    // Fabacées
    'phaseolus': RotationFamily.fabaceae,
    'pisum': RotationFamily.fabaceae,
    'vicia': RotationFamily.fabaceae,
    'lens': RotationFamily.fabaceae,
    'glycine': RotationFamily.fabaceae,
    'cicer': RotationFamily.fabaceae,
    // Apiacées
    'daucus': RotationFamily.apiaceae,
    'pastinaca': RotationFamily.apiaceae,
    'petroselinum': RotationFamily.apiaceae,
    'apium': RotationFamily.apiaceae,
    'foeniculum': RotationFamily.apiaceae,
    'anethum': RotationFamily.apiaceae,
    'anthriscus': RotationFamily.apiaceae,
    'coriandrum': RotationFamily.apiaceae,
    'levisticum': RotationFamily.apiaceae,
    // Astéracées
    'lactuca': RotationFamily.asteraceae,
    'cichorium': RotationFamily.asteraceae,
    'tragopogon': RotationFamily.asteraceae,
    'scorzonera': RotationFamily.asteraceae,
    'cynara': RotationFamily.asteraceae,
    'helianthus': RotationFamily.asteraceae,
    'artemisia': RotationFamily.asteraceae,
    'valerianella': RotationFamily.asteraceae,
    // Chénopodiacées (= Amaranthacées)
    'beta': RotationFamily.chenopodiaceae,
    'spinacia': RotationFamily.chenopodiaceae,
    'atriplex': RotationFamily.chenopodiaceae,
    'chenopodium': RotationFamily.chenopodiaceae,
    // Lamiacées
    'ocimum': RotationFamily.lamiaceae,
    'mentha': RotationFamily.lamiaceae,
    'thymus': RotationFamily.lamiaceae,
    'salvia': RotationFamily.lamiaceae,
    'rosmarinus': RotationFamily.lamiaceae,
    'origanum': RotationFamily.lamiaceae,
    'satureja': RotationFamily.lamiaceae,
    'lavandula': RotationFamily.lamiaceae,
    'stachys': RotationFamily.lamiaceae,
    // Poacées
    'zea': RotationFamily.poaceae,
    'triticum': RotationFamily.poaceae,
    'avena': RotationFamily.poaceae,
    'hordeum': RotationFamily.poaceae,
  };
}

/// Retourne true si planter `next` après `previous` est déconseillé
/// (règle simple : même famille => rotation cassée). La famille `other`
/// ne déclenche jamais d'alerte.
bool isRotationConflict(
  RotationFamily? previous,
  RotationFamily? next,
) {
  if (previous == null || next == null) return false;
  if (previous == RotationFamily.other || next == RotationFamily.other) {
    return false;
  }
  return previous == next;
}

/// Teste si deux rectangles (en coordonnées de cellule) se chevauchent.
/// Utilisé pour résoudre la culture précédente et croiser les amendements
/// avec l'emprise d'une plante.
bool gridRectsOverlap({
  required int ax,
  required int ay,
  required int aw,
  required int ah,
  required int bx,
  required int by,
  required int bw,
  required int bh,
}) {
  return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
}
