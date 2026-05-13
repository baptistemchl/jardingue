# Variété libre + Type de plantation pour les arbres du verger

**Date** : 2026-05-13
**Statut** : Validé, prêt pour writing-plans
**Origine** : Feedback utilisateur Play Store — *« Abricotier ? On ne peut pas mentionner la variété ? Pourquoi en pot ? »*

## Contexte

Un utilisateur ayant téléchargé l'app a remonté deux confusions lors de l'ajout d'un Abricotier dans son verger :

1. **Variété non personnalisable** : le dropdown actuel propose 4 variétés (Bergeron, Rouge du Roussillon, Polonais, Orangered) + une option *« Je ne sais pas / Autre »* dont la valeur est `null`. Si la variété de l'utilisateur n'est pas dans la liste, il ne peut pas la mentionner.
2. **Tag « 🪴 En pot » trompeur** : dans le sheet de détail du catalogue (`FruitTreeDetailSheet`), le tag affiché dans le header est en réalité une **capacité** du catalogue (`container_suitable: true` signifie *« cet arbre peut être cultivé en pot »*). L'utilisateur a interprété ce tag comme *« l'app me force à déclarer mon arbre comme étant en pot »*. Aucun champ utilisateur ne permet aujourd'hui de préciser si SON arbre est en pleine terre, en pot, ou en espalier.

## Objectifs

- Permettre la saisie d'une variété en texte libre (avec suggestions issues du catalogue).
- Ajouter un sélecteur explicite de type de plantation : `Pleine terre` / `En pot` / `Espalier`.
- Lever l'ambiguïté du tag du header dans le catalogue.
- Permettre l'édition de ces deux champs après l'ajout, comme les autres champs (surnom, date, etc.).

## Non-objectifs (hors scope)

- Pas de filtre « par type de plantation » dans la liste du verger.
- Pas de logique différenciée dans la planification des tâches selon le type de plantation.
- Pas de champ « taille de pot » (juste un type, pas une dimension).
- Pas d'écran de migration utilisateur — les arbres existants restent à `plantingType = null` et s'affichent par défaut comme « Pleine terre ».

## Architecture

### 1. Modèle de données

**Table `UserFruitTrees`** — ajout d'une colonne :

```dart
TextColumn get plantingType => text().nullable()();
// valeurs: 'ground' | 'pot' | 'espalier'  (null = non renseigné)
```

Le champ `variety` (`text().nullable()`) reste inchangé — il est désormais utilisé en texte libre côté UI.

**Migration drift** : bump du `schemaVersion` (lire la valeur actuelle dans `app_database.dart` au moment de l'implémentation) + `MigrationStrategy.onUpgrade` qui ajoute la colonne `planting_type`. Les arbres existants conservent `null` et seront affichés comme « Pleine terre » à l'écran (mais la valeur en base reste `null` tant que l'utilisateur n'édite pas).

**Enum domaine** — nouveau fichier `lib/features/orchard/domain/models/planting_type.dart` :

```dart
enum PlantingType {
  ground('ground', '🌱', 'Pleine terre'),
  pot('pot', '🪴', 'En pot'),
  espalier('espalier', '🧱', 'Espalier / Palissé');

  final String dbValue;
  final String emoji;
  final String label;
  const PlantingType(this.dbValue, this.emoji, this.label);

  static PlantingType? fromDbValue(String? value) =>
      value == null ? null : PlantingType.values.firstWhere(
        (t) => t.dbValue == value,
        orElse: () => PlantingType.ground,
      );
}
```

### 2. Formulaire d'ajout (`FruitTreeDetailSheet`)

Le formulaire actuel (révélé par le bouton « Ajouter à mon verger ») reçoit deux changements et un réordonnancement.

**Ordre des champs (du plus important au moins)** :
1. **Type de plantation** — ChoiceChips (sélection unique) :
   ```
   [ 🌱 Pleine terre ]  [ 🪴 En pot ]  [ 🧱 Espalier ]
   ```
   - Valeur par défaut : `PlantingType.ground`.
   - Si l'arbre n'est pas `containerSuitable` et que l'utilisateur sélectionne « En pot » → afficher un texte d'info gris discret : *« Cet arbre tolère mal la culture en pot (taille adulte ~X m). »* L'option reste fonctionnellement cliquable, on ne bloque pas l'utilisateur.
2. **Variété** — composant `Autocomplete<String>` Flutter :
   - `optionsBuilder` filtre `tree.varietiesList` selon le texte tapé.
   - Si l'utilisateur tape une valeur qui ne match aucune suggestion, sa saisie est conservée.
   - Label : « Variété (optionnel) », hint : « Ex: Bergeron, ou la vôtre ».
3. **Surnom** — `TextField` existant, inchangé.
4. **Date de plantation** — picker existant, inchangé.

**Appel `addTree(...)`** : le notifier `userFruitTreesNotifierProvider` reçoit un paramètre supplémentaire `plantingType` (typé `PlantingType?`).

### 3. Vue « Mon arbre » (`UserTreeDetailSheet`)

**Modifications du header** : ajout sous le titre/sous-titre de chips affichant les données utilisateur :

- Si `variety != null` : chip tappable « 🏷️ {variety} » → ouvre un mini bottom sheet d'édition qui ré-utilise le même `Autocomplete` que le formulaire d'ajout, pré-rempli avec la valeur actuelle.
- Toujours visible : chip tappable du type de plantation (avec emoji + label de l'enum, ou « 🌱 Pleine terre » par défaut si `null`) → ouvre un bottom sheet avec les 3 `ChoiceChip`, sélection actuelle marquée.

**Persistance** : la méthode `updateTree(...)` du notifier supporte déjà `variety`. On ajoute `plantingType` (`PlantingType?`) à sa signature et à `_update(...)` dans `_UserTreeDetailSheetState`.

**Pas d'autre changement** sur le reste du sheet (édition de surnom, date, location, notes, healthStatus restent inchangés).

### 4. Catalogue (`FruitTreeDetailSheet`) — nettoyage

Dans le header du sheet, **avant** ajout :
- Le tag actuel `if (tree.containerSuitable) const _Tag(emoji: '🪴', label: 'En pot')` est renommé en `_Tag(emoji: '🪴', label: 'Cultivable en pot')` pour clarifier qu'il s'agit d'une capacité, pas d'une affectation.
- Le reste du header est inchangé.
- L'info `container_min_size_l` reste affichée dans la fiche détaillée (`_buildDetailedInfo`).

### 5. JSON `assets/data/fruit_trees.json`

Les 100 arbres ont déjà un champ `popular_varieties` rempli. **Pas de migration de données nécessaire**.

**Enrichissement opportuniste** : relire chaque arbre et ajouter 1–3 variétés courantes manquantes si pertinent (ex. Abricotier → « Goldrich », « Hâtif de Colomer »). Règles :
- Cap à 6–8 variétés maximum par arbre, pour rester lisible.
- Variétés vraiment populaires et adaptées au climat français/européen.
- Pas de doublons, pas de variations orthographiques.
- Si une liste de 4 variétés est déjà bien représentative, ne pas l'allonger artificiellement.

Le `FruitTreeImportService` détectera automatiquement le changement via son mécanisme existant (à vérifier au moment de l'implémentation — bumper la version d'import si nécessaire pour forcer un re-seed).

## Composants modifiés / créés

| Fichier | Modification |
|---|---|
| `lib/core/services/database/orchard_tables.dart` | Ajout colonne `plantingType` sur `UserFruitTrees` |
| `lib/core/services/database/app_database.dart` | Bump `schemaVersion` + migration `onUpgrade` |
| `lib/core/services/database/app_database.g.dart` | Régénération via `fvm dart run build_runner build` |
| `lib/features/orchard/domain/models/planting_type.dart` | **Nouveau** — enum `PlantingType` |
| `lib/features/orchard/data/repositories/fruit_tree_repository.dart` | Propager `plantingType` dans `addTree` et `updateTree` |
| `lib/core/providers/orchard_providers.dart` | Idem (notifier) |
| `lib/features/orchard/presentation/widgets/fruit_tree_detail_sheet.dart` | Réordonnancement formulaire + Autocomplete variété + ChoiceChips type plantation + renommage tag header |
| `lib/features/orchard/presentation/widgets/user_tree_detail_sheet.dart` | Chips tappables dans le header + sheets d'édition inline |
| `assets/data/fruit_trees.json` | Enrichissement opportuniste des `popular_varieties` |
| `test/features/orchard/...` | Nouveaux tests (voir plan de tests) |

## Plan de tests

1. **DB** — `user_fruit_trees_table_test.dart` (ou équivalent) :
   - Insertion + lecture d'un arbre avec `plantingType` = chaque valeur de l'enum + `null`.
   - Round-trip via `PlantingType.fromDbValue` / `enum.dbValue`.
2. **Migration drift** : test de migration `vN` → `vN+1` qui préserve les arbres existants avec `plantingType = null`.
3. **Widget `FruitTreeDetailSheet`** (formulaire d'ajout) :
   - Saisie variété libre (non listée) → appel à `addTree(variety: 'MaVariéte', ...)`.
   - Sélection d'un type ChoiceChip → appel à `addTree(plantingType: PlantingType.pot, ...)`.
   - Sélection variété existante via autocomplete → variété correcte transmise.
4. **Widget `UserTreeDetailSheet`** :
   - Tap sur chip variété → ouvre le sheet d'édition.
   - Confirmation édition → `updateTree(variety: ...)` appelé avec la nouvelle valeur.
   - Idem pour le type de plantation.
5. **Pas de test du catalogue** pour le renommage du tag (changement de string trivial).

## Compatibilité ascendante

- **Sauvegarde Firestore (`firestore_backup_datasource`)** : à vérifier — si la sauvegarde sérialise les `UserFruitTrees`, ajouter `plantingType` au mapping (sérialisation + désérialisation tolérante à l'absence du champ pour les anciennes sauvegardes).
- **Riverpod** : respect du pattern existant — tout `ref.watch` synchrone AVANT tout `await` dans les providers async ; capture du notifier avant `await` dans les callbacks de widget.
- **AppBottomSheet** : les nouveaux sheets d'édition inline doivent utiliser `AppBottomSheet` de `core/widgets`, pas `SafeArea` direct.

## Risques

- **Drift codegen** : `fvm dart run build_runner build --delete-conflicting-outputs` peut être nécessaire après modification de la table.
- **Re-seed du catalogue** : si le `FruitTreeImportService` utilise un hash de version et qu'on bump pas ce hash, les enrichissements de variétés ne seront pas appliqués aux installations existantes. À tester en upgrade-in-place.
- **Backup/restore** : risque mineur de perdre `plantingType` si la sauvegarde n'est pas mise à jour avant la prochaine release.
