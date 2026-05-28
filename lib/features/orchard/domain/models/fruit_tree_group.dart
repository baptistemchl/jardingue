import 'user_fruit_tree_with_details.dart';

/// Regroupement logique d'arbres identiques du verger.
///
/// Clé de regroupement : (espèce + variété normalisée + type de plantation).
/// Le regroupement est purement présentation — la DB stocke toujours 1 ligne
/// par arbre. Un groupe peut contenir un seul arbre (carte simple), ou
/// plusieurs (carte groupée).
class FruitTreeGroup {
  /// Identifiant stable du groupe, utilisable comme clé Widget. Combine
  /// l'id espèce, la variété et le type de plantation.
  final String key;

  /// Tous les arbres du groupe, dans l'ordre de plantation (plus ancien
  /// d'abord, puis par id pour stabilité).
  final List<UserFruitTreeWithDetails> trees;

  const FruitTreeGroup({required this.key, required this.trees});

  /// Construit un groupe à partir d'un premier arbre (la clé est dérivée
  /// de ses propriétés). Les arbres suivants sont ajoutés via `add`.
  factory FruitTreeGroup.from(UserFruitTreeWithDetails tree) {
    return FruitTreeGroup(key: _keyFor(tree), trees: [tree]);
  }

  /// Représentant du groupe : son premier arbre (toutes les métadonnées
  /// partagées — espèce, variété, type — viennent de là).
  UserFruitTreeWithDetails get representative => trees.first;

  int get count => trees.length;
  bool get isSingle => trees.length == 1;
  bool get isGroup => trees.length > 1;

  /// Espèce (catalogue) du groupe.
  String get speciesName => representative.fruitTree.commonName;

  /// Emoji partagé.
  String get emoji => representative.fruitTree.emoji;

  /// Variété (peut être null).
  String? get variety => representative.variety;

  /// Type de plantation stocké en DB (peut être null pour les anciens).
  String? get plantingTypeDb => representative.userTree.plantingType;

  /// Nombre d'arbres par statut de santé.
  int get healthyCount =>
      trees.where((t) => t.healthStatus == 'good').length;
  int get warningCount =>
      trees.where((t) => t.healthStatus == 'warning').length;
  int get poorCount =>
      trees.where((t) => t.healthStatus == 'poor').length;

  /// Pire statut du groupe (pour la pastille agrégée).
  String get worstHealth {
    if (poorCount > 0) return 'poor';
    if (warningCount > 0) return 'warning';
    return 'good';
  }

  /// Rendement cumulé de la dernière récolte du groupe (somme des
  /// `lastYieldKg` non nuls). Null si aucun arbre n'a de rendement
  /// enregistré.
  double? get totalLastYieldKg {
    final yields =
        trees.map((t) => t.lastYieldKg).whereType<double>().toList();
    if (yields.isEmpty) return null;
    return yields.fold<double>(0, (a, b) => a + b);
  }

  /// Date de dernière récolte du groupe (la plus récente parmi les arbres).
  DateTime? get latestHarvestDate {
    final dates = trees
        .map((t) => t.lastHarvestDate)
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return null;
    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  /// Date de dernière taille du groupe (la plus ancienne — c'est la
  /// limite haute du prochain rappel, pas la plus récente).
  DateTime? get oldestPruningDate {
    final dates = trees
        .map((t) => t.lastPruningDate)
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return null;
    dates.sort((a, b) => a.compareTo(b));
    return dates.first;
  }

  /// Date de plantation moyenne (ou la première trouvée si quasi-identiques).
  DateTime? get plantingDate => representative.plantingDate;

  /// Clé de regroupement. La variété est normalisée (lowercase + trim) pour
  /// que "Reinette" et "reinette" tombent dans le même groupe. Le type de
  /// plantation null est traité comme 'ground' (cohérent avec le fallback
  /// d'affichage côté UI).
  static String _keyFor(UserFruitTreeWithDetails tree) {
    final speciesId = tree.fruitTree.id;
    final variety =
        (tree.variety ?? '').trim().toLowerCase();
    final planting = tree.userTree.plantingType ?? 'ground';
    return '$speciesId|$variety|$planting';
  }

  /// Regroupe une liste plate d'arbres utilisateur en groupes ordonnés.
  /// Ordre des groupes : par date de plantation du représentant (plus
  /// récent d'abord), puis par nom d'espèce.
  static List<FruitTreeGroup> groupAll(
      List<UserFruitTreeWithDetails> trees) {
    final byKey = <String, List<UserFruitTreeWithDetails>>{};
    for (final tree in trees) {
      byKey.putIfAbsent(_keyFor(tree), () => []).add(tree);
    }

    // Tri interne de chaque groupe : plantation la plus ancienne d'abord,
    // puis par id pour les ex æquo.
    for (final entry in byKey.entries) {
      entry.value.sort((a, b) {
        final ad = a.plantingDate;
        final bd = b.plantingDate;
        if (ad == null && bd == null) return a.id.compareTo(b.id);
        if (ad == null) return 1;
        if (bd == null) return -1;
        final byDate = ad.compareTo(bd);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    }

    final groups = byKey.entries
        .map((e) => FruitTreeGroup(key: e.key, trees: e.value))
        .toList();

    // Tri des groupes : plantation la plus récente d'abord, puis nom d'espèce.
    groups.sort((a, b) {
      final ad = a.representative.plantingDate;
      final bd = b.representative.plantingDate;
      if (ad == null && bd == null) {
        return a.speciesName.compareTo(b.speciesName);
      }
      if (ad == null) return 1;
      if (bd == null) return -1;
      final byDate = bd.compareTo(ad);
      return byDate != 0 ? byDate : a.speciesName.compareTo(b.speciesName);
    });

    return groups;
  }
}
