# Variété libre + Type de plantation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permettre à l'utilisateur de saisir une variété personnalisée en texte libre lors de l'ajout d'un arbre fruitier, et de préciser le type de plantation (pleine terre / pot / espalier). Lever la confusion induite par le tag « 🪴 En pot » du catalogue.

**Architecture:** Ajout d'une colonne `plantingType` (TEXT nullable) sur la table Drift `UserFruitTrees` via migration v16→v17. Nouveau domain enum `PlantingType`. Le dropdown de variété actuel est remplacé par un `Autocomplete<String>` qui accepte texte libre + suggestions du catalogue. Un sélecteur `ChoiceChip` (3 options) est ajouté en tête du formulaire d'ajout. Le sheet « Mon arbre » expose ces deux infos comme chips tappables ouvrant des sheets d'édition inline. Le tag du catalogue est renommé « Cultivable en pot ».

**Tech Stack:** Flutter (FVM, SDK ^3.11.4), Drift 2.26+ (avec build_runner), flutter_riverpod 3.3+, phosphor_flutter, package `intl` pour les dates. Tests via `flutter_test` + `ProviderScope` overrides. Toujours préfixer les commandes par `fvm` (cf. `MEMORY.md`).

**Spec source:** `docs/superpowers/specs/2026-05-13-tree-variety-planting-design.md`

---

## File Structure

**Created:**
- `lib/features/orchard/domain/models/planting_type.dart` — enum `PlantingType { ground, pot, espalier }` avec `dbValue`, `emoji`, `label`, et helper `fromDbValue`.
- `lib/features/orchard/presentation/widgets/variety_autocomplete_field.dart` — widget réutilisable enveloppant `Autocomplete<String>` (formulaire d'ajout + édition inline).
- `lib/features/orchard/presentation/widgets/planting_type_selector.dart` — widget réutilisable enveloppant le sélecteur `ChoiceChip` (formulaire d'ajout + édition inline).
- `lib/features/orchard/presentation/sheets/edit_variety_sheet.dart` — bottom sheet d'édition inline de la variété pour un arbre déjà ajouté.
- `lib/features/orchard/presentation/sheets/edit_planting_type_sheet.dart` — bottom sheet d'édition inline du type de plantation.
- `test/features/orchard/domain/models/planting_type_test.dart`
- `test/features/orchard/data/user_fruit_tree_planting_type_test.dart` — round-trip DB
- `test/features/orchard/presentation/widgets/fruit_tree_detail_sheet_form_test.dart` — widget test formulaire
- `test/features/orchard/presentation/widgets/user_tree_detail_sheet_header_test.dart` — widget test header tappable

**Modified:**
- `lib/core/services/database/orchard_tables.dart` — ajout de la colonne `plantingType`.
- `lib/core/services/database/app_database.dart` — bump `schemaVersion` à 17 + bloc migration v16→v17.
- `lib/core/services/database/app_database.g.dart` — **régénéré** par `fvm dart run build_runner build`.
- `lib/core/services/database/fruit_tree_import_service.dart` — bump version pour forcer le re-import du JSON enrichi.
- `lib/features/orchard/data/repositories/fruit_tree_repository.dart` — ajout `plantingType` aux signatures `addUserFruitTree` (via Companion) et `updateUserFruitTreePartial`.
- `lib/core/providers/orchard_providers.dart` — propagation `plantingType` dans `addTree` et `updateTree`.
- `lib/features/orchard/presentation/widgets/fruit_tree_detail_sheet.dart` — réordonnancement formulaire + intégration des 2 nouveaux widgets + renommage tag header.
- `lib/features/orchard/presentation/widgets/user_tree_detail_sheet.dart` — chips éditables dans le header.
- `lib/features/premium/data/repositories/backup_repository_impl.dart` — export/import du champ `plantingType` (tolérant à l'absence).
- `assets/data/fruit_trees.json` — enrichissement opportuniste des `popular_varieties`.

---

## Task 1: Domain enum `PlantingType`

**Files:**
- Create: `lib/features/orchard/domain/models/planting_type.dart`
- Test: `test/features/orchard/domain/models/planting_type_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/orchard/domain/models/planting_type_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/orchard/domain/models/planting_type.dart';

void main() {
  group('PlantingType', () {
    test('dbValue is stable for each variant', () {
      expect(PlantingType.ground.dbValue, 'ground');
      expect(PlantingType.pot.dbValue, 'pot');
      expect(PlantingType.espalier.dbValue, 'espalier');
    });

    test('label and emoji are localized FR', () {
      expect(PlantingType.ground.emoji, '🌱');
      expect(PlantingType.ground.label, 'Pleine terre');
      expect(PlantingType.pot.emoji, '🪴');
      expect(PlantingType.pot.label, 'En pot');
      expect(PlantingType.espalier.emoji, '🧱');
      expect(PlantingType.espalier.label, 'Espalier / Palissé');
    });

    test('fromDbValue maps known strings', () {
      expect(PlantingType.fromDbValue('ground'), PlantingType.ground);
      expect(PlantingType.fromDbValue('pot'), PlantingType.pot);
      expect(PlantingType.fromDbValue('espalier'), PlantingType.espalier);
    });

    test('fromDbValue returns null when input is null', () {
      expect(PlantingType.fromDbValue(null), isNull);
    });

    test('fromDbValue falls back to ground for unknown values', () {
      expect(PlantingType.fromDbValue('greenhouse'), PlantingType.ground);
      expect(PlantingType.fromDbValue(''), PlantingType.ground);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
fvm flutter test test/features/orchard/domain/models/planting_type_test.dart
```

Expected: FAIL — `PlantingType` is not defined (compile error).

- [ ] **Step 3: Implement the enum**

```dart
// lib/features/orchard/domain/models/planting_type.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

```
fvm flutter test test/features/orchard/domain/models/planting_type_test.dart
```

Expected: PASS — 5 tests passent.

- [ ] **Step 5: Commit**

```bash
git add lib/features/orchard/domain/models/planting_type.dart test/features/orchard/domain/models/planting_type_test.dart
git commit -m "feat(orchard): add PlantingType domain enum"
```

---

## Task 2: Drift schema + migration v16→v17

**Files:**
- Modify: `lib/core/services/database/orchard_tables.dart`
- Modify: `lib/core/services/database/app_database.dart:51` (schemaVersion) + bloc migration
- Regenerate: `lib/core/services/database/app_database.g.dart`
- Test: `test/features/orchard/data/user_fruit_tree_planting_type_test.dart`

- [ ] **Step 1: Write the failing test (round-trip DB + migration safety)**

```dart
// test/features/orchard/data/user_fruit_tree_planting_type_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> _insertCatalogTree() async {
    return db.insertFruitTree(
      FruitTreesCompanion.insert(
        id: const Value(1),
        commonName: 'Abricotier',
      ),
    );
  }

  test('insert + read UserFruitTree avec plantingType=pot', () async {
    await _insertCatalogTree();
    final id = await db.addUserFruitTree(
      UserFruitTreesCompanion.insert(
        fruitTreeId: 1,
        plantingType: const Value('pot'),
      ),
    );

    final row = await (db.select(db.userFruitTrees)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    expect(row.plantingType, 'pot');
  });

  test('insert UserFruitTree sans plantingType => null en base', () async {
    await _insertCatalogTree();
    final id = await db.addUserFruitTree(
      UserFruitTreesCompanion.insert(fruitTreeId: 1),
    );
    final row = await (db.select(db.userFruitTrees)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.plantingType, isNull);
  });

  test('updateUserFruitTreePartial accepte plantingType', () async {
    await _insertCatalogTree();
    final id = await db.addUserFruitTree(
      UserFruitTreesCompanion.insert(fruitTreeId: 1),
    );

    await db.updateUserFruitTreePartial(
      id: id,
      plantingType: 'espalier',
    );

    final row = await (db.select(db.userFruitTrees)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.plantingType, 'espalier');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```
fvm flutter test test/features/orchard/data/user_fruit_tree_planting_type_test.dart
```

Expected: FAIL — `plantingType` n'existe pas sur `UserFruitTreesCompanion` (compile error). `updateUserFruitTreePartial` n'accepte pas `plantingType`.

- [ ] **Step 3: Add the column to the Drift table**

Open `lib/core/services/database/orchard_tables.dart` et ajouter, dans la classe `UserFruitTrees` juste après la ligne `TextColumn get variety => text().nullable()();` (ligne 111) :

```dart
  // Type de plantation choisi par l'utilisateur ('ground' | 'pot' | 'espalier')
  // Null = non renseigné (anciens arbres pré-v17), affiché comme "Pleine terre".
  TextColumn get plantingType => text().nullable()();
```

- [ ] **Step 4: Bump schemaVersion + add migration block**

Dans `lib/core/services/database/app_database.dart`, modifier la ligne 51 :

```dart
  @override
  int get schemaVersion => 17;
```

Puis, dans la méthode `migration` (`onUpgrade`), ajouter ce bloc **après** le bloc `if (from < 16)` (juste avant la fermeture de la lambda `onUpgrade`) :

```dart
        // Migration v16 -> v17 : type de plantation utilisateur sur les arbres.
        // Ajoute la colonne `planting_type` (nullable). Les arbres existants
        // restent à null et sont affichés par défaut comme "Pleine terre".
        if (from < 17) {
          await _safeAddColumn(m, userFruitTrees, userFruitTrees.plantingType);
        }
```

- [ ] **Step 5: Extend `updateUserFruitTreePartial` to support plantingType**

Dans `lib/core/services/database/app_database.dart`, modifier la signature et le corps de `updateUserFruitTreePartial` (lignes 1051-1087) pour ajouter le paramètre `plantingType` :

```dart
  Future<void> updateUserFruitTreePartial({
    required int id,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
    String? plantingType,
  }) {
    return (update(userFruitTrees)..where((t) => t.id.equals(id))).write(
      UserFruitTreesCompanion(
        nickname: nickname != null ? Value(nickname) : const Value.absent(),
        variety: variety != null ? Value(variety) : const Value.absent(),
        plantingDate: plantingDate != null
            ? Value(plantingDate)
            : const Value.absent(),
        location: location != null ? Value(location) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        healthStatus: healthStatus != null
            ? Value(healthStatus)
            : const Value.absent(),
        lastPruningDate: lastPruningDate != null
            ? Value(lastPruningDate)
            : const Value.absent(),
        lastHarvestDate: lastHarvestDate != null
            ? Value(lastHarvestDate)
            : const Value.absent(),
        lastYieldKg: lastYieldKg != null
            ? Value(lastYieldKg)
            : const Value.absent(),
        plantingType:
            plantingType != null ? Value(plantingType) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
```

- [ ] **Step 6: Regenerate Drift code**

```
fvm dart run build_runner build --delete-conflicting-outputs
```

Expected: build_runner termine en succès, `app_database.g.dart` est régénéré avec la nouvelle colonne.

- [ ] **Step 7: Run the test to verify it passes**

```
fvm flutter test test/features/orchard/data/user_fruit_tree_planting_type_test.dart
```

Expected: PASS — 3 tests passent.

- [ ] **Step 8: Run the full test suite to confirm no regression**

```
fvm flutter test
```

Expected: PASS — tous les tests passent (les anciens tests qui construisent un `UserFruitTreesCompanion` sans `plantingType` continuent de fonctionner car le champ est optionnel).

- [ ] **Step 9: Commit**

```bash
git add lib/core/services/database/orchard_tables.dart lib/core/services/database/app_database.dart lib/core/services/database/app_database.g.dart test/features/orchard/data/user_fruit_tree_planting_type_test.dart
git commit -m "feat(db): add planting_type column on UserFruitTrees (schema v17)"
```

---

## Task 3: Repository + Notifier wiring

**Files:**
- Modify: `lib/features/orchard/data/repositories/fruit_tree_repository.dart`
- Modify: `lib/core/providers/orchard_providers.dart`

Pas de nouveau test ici — la couche repository ne fait que déléguer à la DB déjà couverte par Task 2. Le notifier sera couvert indirectement par les tests widget des Tasks 5 et 6.

- [ ] **Step 1: Update the abstract interface**

Dans `lib/features/orchard/data/repositories/fruit_tree_repository.dart`, modifier la signature de `updateUserFruitTreePartial` dans `abstract interface class FruitTreeRepository` (lignes 21-32) :

```dart
  Future<void> updateUserFruitTreePartial({
    required int id,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
    String? plantingType,
  });
```

- [ ] **Step 2: Update the Drift implementation**

Dans le même fichier, modifier l'implémentation `updateUserFruitTreePartial` dans `class DriftFruitTreeRepository` (lignes 106-129) :

```dart
  @override
  Future<void> updateUserFruitTreePartial({
    required int id,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
    String? plantingType,
  }) =>
      _db.updateUserFruitTreePartial(
        id: id,
        nickname: nickname,
        variety: variety,
        plantingDate: plantingDate,
        location: location,
        notes: notes,
        healthStatus: healthStatus,
        lastPruningDate: lastPruningDate,
        lastHarvestDate: lastHarvestDate,
        lastYieldKg: lastYieldKg,
        plantingType: plantingType,
      );
```

- [ ] **Step 3: Update the Riverpod notifier `addTree`**

Dans `lib/core/providers/orchard_providers.dart`, modifier `addTree` (lignes 170-190) :

```dart
  Future<int> addTree({
    required int fruitTreeId,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    PlantingType? plantingType,
  }) async {
    final companion = UserFruitTreesCompanion(
      fruitTreeId: Value(fruitTreeId),
      nickname: Value(nickname),
      variety: Value(variety),
      plantingDate: Value(plantingDate),
      location: Value(location),
      notes: Value(notes),
      plantingType: Value(plantingType?.dbValue),
    );

    final id = await _repo.addUserFruitTree(companion);
    await _loadData();
    return id;
  }
```

- [ ] **Step 4: Update the Riverpod notifier `updateTree`**

Modifier `updateTree` (lignes 192-217) :

```dart
  Future<void> updateTree({
    required int id,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
    PlantingType? plantingType,
  }) async {
    await _repo.updateUserFruitTreePartial(
      id: id,
      nickname: nickname,
      variety: variety,
      plantingDate: plantingDate,
      location: location,
      notes: notes,
      healthStatus: healthStatus,
      lastPruningDate: lastPruningDate,
      lastHarvestDate: lastHarvestDate,
      lastYieldKg: lastYieldKg,
      plantingType: plantingType?.dbValue,
    );
    await _loadData();
  }
```

- [ ] **Step 5: Add the import of PlantingType + export for callers**

En haut de `lib/core/providers/orchard_providers.dart`, ajouter l'import :

```dart
import '../../features/orchard/domain/models/planting_type.dart';
```

Puis ajouter l'export (juste après les autres `export` lignes 14-17) :

```dart
export '../../features/orchard/domain/models/planting_type.dart';
```

- [ ] **Step 6: Run the test suite**

```
fvm flutter test
```

Expected: PASS — les tests Task 1 et Task 2 passent toujours. Les autres tests existants ne sont pas impactés (param optionnel).

- [ ] **Step 7: Verify static analysis**

```
fvm flutter analyze
```

Expected: no issues.

- [ ] **Step 8: Commit**

```bash
git add lib/features/orchard/data/repositories/fruit_tree_repository.dart lib/core/providers/orchard_providers.dart
git commit -m "feat(orchard): propagate plantingType through repository + notifier"
```

---

## Task 4: Backup/restore — sérialisation `plantingType`

**Files:**
- Modify: `lib/features/premium/data/repositories/backup_repository_impl.dart`

Aucun nouveau test : le pipeline backup a un test d'intégration existant qui valide le round-trip — il continuera de passer car le champ est tolérant à l'absence.

- [ ] **Step 1: Add plantingType to export**

Dans `lib/features/premium/data/repositories/backup_repository_impl.dart`, modifier `_exportUserFruitTrees` (lignes 277-304). Insérer la ligne `'plantingType'` juste après `'healthStatus'` :

```dart
  Future<List<Map<String, dynamic>>>
      _exportUserFruitTrees() async {
    final rows =
        await _db.select(_db.userFruitTrees).get();
    return rows
        .map((t) => {
              'id': t.id,
              'fruitTreeId': t.fruitTreeId,
              'nickname': t.nickname,
              'variety': t.variety,
              'plantingDate':
                  t.plantingDate?.toIso8601String(),
              'location': t.location,
              'notes': t.notes,
              'healthStatus': t.healthStatus,
              'plantingType': t.plantingType,
              'lastPruningDate':
                  t.lastPruningDate?.toIso8601String(),
              'lastHarvestDate':
                  t.lastHarvestDate?.toIso8601String(),
              'lastYieldKg': t.lastYieldKg,
              'photos': t.photos,
              'createdAt':
                  t.createdAt.toIso8601String(),
              'updatedAt':
                  t.updatedAt.toIso8601String(),
            })
        .toList();
  }
```

- [ ] **Step 2: Add plantingType to import (tolerant to absent field)**

Dans le même fichier, modifier `_importUserFruitTrees` (lignes 535-562). Ajouter la ligne `plantingType:` juste après `photos:` :

```dart
  Future<void> _importUserFruitTrees(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final r in rows) {
      await _db.into(_db.userFruitTrees).insert(
            UserFruitTreesCompanion.insert(
              fruitTreeId: r['fruitTreeId'] as int,
              nickname: Value(
                r['nickname'] as String?,
              ),
              variety: Value(
                r['variety'] as String?,
              ),
              plantingDate: Value(
                _parseDate(r['plantingDate']),
              ),
              location: Value(
                r['location'] as String?,
              ),
              notes: Value(r['notes'] as String?),
              healthStatus: Value(
                r['healthStatus'] as String? ?? 'good',
              ),
              photos: Value(r['photos'] as String?),
              // Absent des backups < v1.6.5 → null, affiché "Pleine terre".
              plantingType: Value(
                r['plantingType'] as String?,
              ),
            ),
          );
    }
  }
```

- [ ] **Step 3: Run test suite**

```
fvm flutter test
```

Expected: PASS — pas de régression.

- [ ] **Step 4: Commit**

```bash
git add lib/features/premium/data/repositories/backup_repository_impl.dart
git commit -m "feat(backup): include plantingType in user fruit tree backup"
```

---

## Task 5: Widget `VarietyAutocompleteField`

**Files:**
- Create: `lib/features/orchard/presentation/widgets/variety_autocomplete_field.dart`

Pas de test isolé pour ce widget — il sera couvert via le test du formulaire (Task 7) et du sheet d'édition (Task 8). Sa surface est trop fine (passthrough sur `Autocomplete`) pour justifier un test propre.

- [ ] **Step 1: Implement the widget**

```dart
// lib/features/orchard/presentation/widgets/variety_autocomplete_field.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Champ de saisie de variété pour un arbre fruitier.
///
/// Combine un [Autocomplete] qui propose [suggestions] (variétés populaires
/// issues du catalogue) tout en acceptant n'importe quel texte libre. La
/// valeur courante est exposée via [onChanged] ; un texte vide est mappé sur
/// `null` côté caller (variété "non renseignée").
class VarietyAutocompleteField extends StatefulWidget {
  final List<String> suggestions;
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const VarietyAutocompleteField({
    super.key,
    required this.suggestions,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<VarietyAutocompleteField> createState() =>
      _VarietyAutocompleteFieldState();
}

class _VarietyAutocompleteFieldState extends State<VarietyAutocompleteField> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.initialValue ?? ''),
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return widget.suggestions;
        final lower = value.text.toLowerCase();
        return widget.suggestions
            .where((v) => v.toLowerCase().contains(lower));
      },
      onSelected: (s) => widget.onChanged(s.isEmpty ? null : s),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (s) =>
              widget.onChanged(s.trim().isEmpty ? null : s.trim()),
          decoration: InputDecoration(
            hintText: 'Ex: Bergeron, ou la vôtre',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final opt = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(opt),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(opt, style: AppTypography.bodyMedium),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Verify static analysis**

```
fvm flutter analyze lib/features/orchard/presentation/widgets/variety_autocomplete_field.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/orchard/presentation/widgets/variety_autocomplete_field.dart
git commit -m "feat(orchard): add VarietyAutocompleteField widget"
```

---

## Task 6: Widget `PlantingTypeSelector`

**Files:**
- Create: `lib/features/orchard/presentation/widgets/planting_type_selector.dart`

- [ ] **Step 1: Implement the widget**

```dart
// lib/features/orchard/presentation/widgets/planting_type_selector.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/planting_type.dart';

/// Sélecteur à choix unique pour le type de plantation d'un arbre.
///
/// Affiche 3 [ChoiceChip] côte à côte. Quand l'arbre n'est pas
/// `containerSuitable` et que l'utilisateur sélectionne [PlantingType.pot],
/// un avertissement discret apparaît sous le sélecteur — l'option reste
/// cliquable (on ne bride pas l'utilisateur).
class PlantingTypeSelector extends StatelessWidget {
  final PlantingType selected;
  final ValueChanged<PlantingType> onChanged;
  final bool containerSuitable;
  final double? heightAdultM;

  const PlantingTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.containerSuitable = true,
    this.heightAdultM,
  });

  String _potWarningMessage() {
    final h = heightAdultM;
    if (h == null) {
      return 'Cet arbre tolère mal la culture en pot.';
    }
    return 'Cet arbre tolère mal la culture en pot (taille adulte ~${h.toStringAsFixed(0)} m).';
  }

  @override
  Widget build(BuildContext context) {
    final showWarning =
        selected == PlantingType.pot && !containerSuitable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlantingType.values.map((t) {
            final isSelected = t == selected;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(t.label),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(t),
              backgroundColor: AppColors.background,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color:
                    isSelected ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        ),
        if (showWarning) ...[
          const SizedBox(height: 8),
          Text(
            _potWarningMessage(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Verify static analysis**

```
fvm flutter analyze lib/features/orchard/presentation/widgets/planting_type_selector.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/orchard/presentation/widgets/planting_type_selector.dart
git commit -m "feat(orchard): add PlantingTypeSelector widget"
```

---

## Task 7: Refactor `FruitTreeDetailSheet` form

**Files:**
- Modify: `lib/features/orchard/presentation/widgets/fruit_tree_detail_sheet.dart`
- Test: `test/features/orchard/presentation/widgets/fruit_tree_detail_sheet_form_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/features/orchard/presentation/widgets/fruit_tree_detail_sheet_form_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';
import 'package:jardingue/core/providers/orchard_providers.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/orchard/domain/models/planting_type.dart';
import 'package:jardingue/features/orchard/presentation/widgets/fruit_tree_detail_sheet.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

class _RecordingNotifier extends UserFruitTreesNotifier {
  final List<Map<String, dynamic>> addCalls = [];

  @override
  AsyncValue<List<UserFruitTreeWithDetails>> build() => const AsyncData([]);

  @override
  Future<int> addTree({
    required int fruitTreeId,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    PlantingType? plantingType,
  }) async {
    addCalls.add({
      'fruitTreeId': fruitTreeId,
      'nickname': nickname,
      'variety': variety,
      'plantingDate': plantingDate,
      'location': location,
      'notes': notes,
      'plantingType': plantingType,
    });
    return 1;
  }
}

FruitTree _abricotierTree() {
  final now = DateTime(2026, 1, 1);
  return FruitTree(
    id: 12,
    commonName: 'Abricotier',
    emoji: '🟠',
    category: 'arbre_fruitier',
    droughtTolerance: true,
    selfFertile: true,
    containerSuitable: true,
    popularVarieties: '["Bergeron","Rouge du Roussillon"]',
    heightAdultM: 5.0,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildApp(Widget child, _RecordingNotifier notifier) {
  return ProviderScope(
    overrides: [
      databaseInitProvider.overrideWith((_) async => 0),
      userFruitTreesNotifierProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets(
    'submit avec variété libre + type=pot => addTree appelé avec ces valeurs',
    (tester) async {
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        _buildApp(FruitTreeDetailSheet(tree: _abricotierTree()), notifier),
      );

      // Ouvrir le formulaire
      await tester.tap(find.text('Ajouter à mon verger'));
      await tester.pumpAndSettle();

      // Sélection du type "En pot"
      await tester.tap(find.text('En pot'));
      await tester.pumpAndSettle();

      // Saisie d'une variété libre (non listée)
      final varietyField = find.byType(TextField).first;
      await tester.enterText(varietyField, 'MaVariété');
      await tester.pumpAndSettle();

      // Confirmer
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(notifier.addCalls, hasLength(1));
      final call = notifier.addCalls.first;
      expect(call['fruitTreeId'], 12);
      expect(call['variety'], 'MaVariété');
      expect(call['plantingType'], PlantingType.pot);
    },
  );

  testWidgets(
    'submit sans toucher au type => plantingType = ground (défaut)',
    (tester) async {
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        _buildApp(FruitTreeDetailSheet(tree: _abricotierTree()), notifier),
      );

      await tester.tap(find.text('Ajouter à mon verger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(notifier.addCalls.first['plantingType'], PlantingType.ground);
      expect(notifier.addCalls.first['variety'], isNull);
    },
  );
}
```

- [ ] **Step 2: Run the test to verify it fails**

```
fvm flutter test test/features/orchard/presentation/widgets/fruit_tree_detail_sheet_form_test.dart
```

Expected: FAIL — le widget ne compile pas (`PlantingType?` non géré par `addTree`) ou ne contient pas les ChoiceChips attendus.

- [ ] **Step 3: Update FruitTreeDetailSheet — imports + state**

Dans `lib/features/orchard/presentation/widgets/fruit_tree_detail_sheet.dart`, ajouter les imports en tête de fichier (après les imports existants) :

```dart
import '../../domain/models/planting_type.dart';
import 'planting_type_selector.dart';
import 'variety_autocomplete_field.dart';
```

Puis dans `_FruitTreeDetailSheetState` (lignes 25-30), remplacer :

```dart
class _FruitTreeDetailSheetState extends ConsumerState<FruitTreeDetailSheet> {
  bool _showAddForm = false;
  final _nicknameController = TextEditingController();
  String? _selectedVariety;
  DateTime? _plantingDate;
  bool _isLoading = false;
```

par :

```dart
class _FruitTreeDetailSheetState extends ConsumerState<FruitTreeDetailSheet> {
  bool _showAddForm = false;
  final _nicknameController = TextEditingController();
  String? _variety;
  PlantingType _plantingType = PlantingType.ground;
  DateTime? _plantingDate;
  bool _isLoading = false;
```

- [ ] **Step 4: Update `_addToOrchard` to pass the new fields**

Remplacer le bloc `_addToOrchard` (lignes 62-104) — la modification clé est dans l'appel `addTree(...)` :

```dart
  Future<void> _addToOrchard() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(userFruitTreesNotifierProvider.notifier)
          .addTree(
            fruitTreeId: widget.tree.id,
            nickname: _nicknameController.text.trim().isEmpty
                ? null
                : _nicknameController.text.trim(),
            variety: _variety,
            plantingDate: _plantingDate,
            plantingType: _plantingType,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.tree.emoji} ${widget.tree.commonName} ajouté à votre verger !',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'FruitTreeDetailSheet._addToOrchard',
        extra: {'treeId': widget.tree.id, 'treeName': widget.tree.commonName},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
```

- [ ] **Step 5: Rename the misleading header tag**

Dans la méthode `build`, modifier le bloc `Wrap` des tags (lignes 187-201). Remplacer :

```dart
                    if (tree.containerSuitable)
                      const _Tag(emoji: '🪴', label: 'En pot'),
```

par :

```dart
                    if (tree.containerSuitable)
                      const _Tag(emoji: '🪴', label: 'Cultivable en pot'),
```

- [ ] **Step 6: Rewrite the form (`_buildAddForm`)**

Remplacer **toute** la méthode `_buildAddForm` (lignes 316-435) par :

```dart
  Widget _buildAddForm(List<String> varieties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.info(PhosphorIconsStyle.fill),
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Personnalisez votre arbre (optionnel)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 1. Type de plantation
        Text('Type de plantation', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        PlantingTypeSelector(
          selected: _plantingType,
          onChanged: (t) => setState(() => _plantingType = t),
          containerSuitable: widget.tree.containerSuitable,
          heightAdultM: widget.tree.heightAdultM,
        ),

        const SizedBox(height: 20),

        // 2. Variété (Autocomplete avec saisie libre)
        Text('Variété (optionnel)', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        VarietyAutocompleteField(
          suggestions: varieties,
          initialValue: _variety,
          onChanged: (v) => _variety = v,
        ),

        const SizedBox(height: 20),

        // 3. Surnom
        Text('Surnom', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _nicknameController,
          decoration: InputDecoration(
            hintText: 'Ex: Le pommier du fond',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 4. Date de plantation
        Text('Date de plantation', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _plantingDate != null
                      ? DateFormat(
                          'dd MMMM yyyy',
                          'fr_FR',
                        ).format(_plantingDate!)
                      : 'Non renseignée',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _plantingDate != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
```

Note importante : le paramètre `List<String> varieties` reste le même (issu de `tree.varietiesList`), il est désormais passé au `VarietyAutocompleteField` au lieu du dropdown.

- [ ] **Step 7: Run the widget test**

```
fvm flutter test test/features/orchard/presentation/widgets/fruit_tree_detail_sheet_form_test.dart
```

Expected: PASS — 2 tests passent.

- [ ] **Step 8: Run the full test suite**

```
fvm flutter test
```

Expected: PASS — pas de régression.

- [ ] **Step 9: Visual smoke test (manuel)**

```
fvm flutter run
```

Manuellement vérifier dans l'app :
1. Tap sur FAB du verger → picker → choisir un arbre.
2. Tap sur « Ajouter à mon verger » → le formulaire affiche **dans cet ordre** : Type de plantation (3 chips), Variété (Autocomplete), Surnom, Date.
3. Taper "MonTest" dans le champ variété → aucune suggestion ne match → le texte reste.
4. Sélectionner "En pot" sur un arbre non `containerSuitable` (ex: Cerisier acide) → un message d'info gris apparaît.
5. Confirmer → un snackbar de succès, l'arbre apparaît dans la liste.
6. Dans le header AVANT ajout (la liste de tags du catalogue), le tag est désormais « 🪴 Cultivable en pot » au lieu de « 🪴 En pot ».

- [ ] **Step 10: Commit**

```bash
git add lib/features/orchard/presentation/widgets/fruit_tree_detail_sheet.dart test/features/orchard/presentation/widgets/fruit_tree_detail_sheet_form_test.dart
git commit -m "feat(orchard): free-text variety + planting type selector in add form"
```

---

## Task 8: Edit sheets — variété et type de plantation

**Files:**
- Create: `lib/features/orchard/presentation/sheets/edit_variety_sheet.dart`
- Create: `lib/features/orchard/presentation/sheets/edit_planting_type_sheet.dart`

Pas de test isolé pour ces sheets (couvert via le test du header en Task 9). Surface très fine : un widget composé déjà testé + un bouton.

- [ ] **Step 1: Implement `EditVarietySheet`**

```dart
// lib/features/orchard/presentation/sheets/edit_variety_sheet.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../widgets/variety_autocomplete_field.dart';

/// Bottom sheet d'édition inline de la variété d'un arbre du verger.
///
/// Renvoie le nouveau texte au pop (ou `null` si annulé / vidé).
class EditVarietySheet extends StatefulWidget {
  final String? initialValue;
  final List<String> suggestions;

  const EditVarietySheet({
    super.key,
    required this.suggestions,
    this.initialValue,
  });

  /// Helper — renvoie `null` si l'utilisateur a annulé, ou la nouvelle valeur
  /// (peut être `null` si l'utilisateur a vidé le champ pour "non renseignée").
  static Future<({String? value})?> show(
    BuildContext context, {
    required List<String> suggestions,
    String? initialValue,
  }) {
    return AppBottomSheet.show<({String? value})>(
      context: context,
      child: EditVarietySheet(
        initialValue: initialValue,
        suggestions: suggestions,
      ),
    );
  }

  @override
  State<EditVarietySheet> createState() => _EditVarietySheetState();
}

class _EditVarietySheetState extends State<EditVarietySheet> {
  String? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Variété',
                      style: AppTypography.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              VarietyAutocompleteField(
                initialValue: widget.initialValue,
                suggestions: widget.suggestions,
                onChanged: (v) => _value = v,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, (value: _value)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Implement `EditPlantingTypeSheet`**

```dart
// lib/features/orchard/presentation/sheets/edit_planting_type_sheet.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/models/planting_type.dart';
import '../widgets/planting_type_selector.dart';

/// Bottom sheet d'édition inline du type de plantation d'un arbre du verger.
class EditPlantingTypeSheet extends StatefulWidget {
  final PlantingType initialValue;
  final bool containerSuitable;
  final double? heightAdultM;

  const EditPlantingTypeSheet({
    super.key,
    required this.initialValue,
    this.containerSuitable = true,
    this.heightAdultM,
  });

  static Future<PlantingType?> show(
    BuildContext context, {
    required PlantingType initialValue,
    bool containerSuitable = true,
    double? heightAdultM,
  }) {
    return AppBottomSheet.show<PlantingType>(
      context: context,
      child: EditPlantingTypeSheet(
        initialValue: initialValue,
        containerSuitable: containerSuitable,
        heightAdultM: heightAdultM,
      ),
    );
  }

  @override
  State<EditPlantingTypeSheet> createState() =>
      _EditPlantingTypeSheetState();
}

class _EditPlantingTypeSheetState extends State<EditPlantingTypeSheet> {
  late PlantingType _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Type de plantation',
                      style: AppTypography.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PlantingTypeSelector(
                selected: _selected,
                onChanged: (t) => setState(() => _selected = t),
                containerSuitable: widget.containerSuitable,
                heightAdultM: widget.heightAdultM,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Static analysis**

```
fvm flutter analyze lib/features/orchard/presentation/sheets/
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/orchard/presentation/sheets/edit_variety_sheet.dart lib/features/orchard/presentation/sheets/edit_planting_type_sheet.dart
git commit -m "feat(orchard): add edit-variety and edit-planting-type bottom sheets"
```

---

## Task 9: Header tappable dans `UserTreeDetailSheet`

**Files:**
- Modify: `lib/features/orchard/presentation/widgets/user_tree_detail_sheet.dart`
- Test: `test/features/orchard/presentation/widgets/user_tree_detail_sheet_header_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/features/orchard/presentation/widgets/user_tree_detail_sheet_header_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/providers/database_providers.dart';
import 'package:jardingue/core/providers/orchard_providers.dart';
import 'package:jardingue/core/services/database/app_database.dart';
import 'package:jardingue/features/orchard/domain/models/planting_type.dart';
import 'package:jardingue/features/orchard/presentation/widgets/user_tree_detail_sheet.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

class _RecordingNotifier extends UserFruitTreesNotifier {
  final List<Map<String, dynamic>> updateCalls = [];

  @override
  AsyncValue<List<UserFruitTreeWithDetails>> build() => const AsyncData([]);

  @override
  Future<void> updateTree({
    required int id,
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
    PlantingType? plantingType,
  }) async {
    updateCalls.add({
      'id': id,
      'variety': variety,
      'plantingType': plantingType,
    });
  }
}

UserFruitTreeWithDetails _fakeTree({
  String? variety,
  String? plantingType,
}) {
  final now = DateTime(2026, 1, 1);
  return UserFruitTreeWithDetails(
    userTree: UserFruitTree(
      id: 42,
      fruitTreeId: 12,
      variety: variety,
      plantingType: plantingType,
      healthStatus: 'good',
      createdAt: now,
      updatedAt: now,
    ),
    fruitTree: FruitTree(
      id: 12,
      commonName: 'Abricotier',
      emoji: '🟠',
      category: 'arbre_fruitier',
      droughtTolerance: true,
      selfFertile: true,
      containerSuitable: true,
      popularVarieties: '["Bergeron"]',
      heightAdultM: 5.0,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Widget _buildApp(Widget child, _RecordingNotifier notifier,
    {Override? extraOverride}) {
  return ProviderScope(
    overrides: [
      databaseInitProvider.overrideWith((_) async => 0),
      userFruitTreesNotifierProvider.overrideWith(() => notifier),
      // userFruitTreeByIdProvider est lu apres updateTree — on stubbe `null`
      // pour eviter un crash dans le reload : le widget garde son state
      // local et le test n'a pas besoin de la valeur rechargee.
      userFruitTreeByIdProvider.overrideWith((ref, id) async => null),
      if (extraOverride != null) extraOverride,
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets(
    'chip variété affiche la valeur stockée',
    (tester) async {
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        _buildApp(
          UserTreeDetailSheet(tree: _fakeTree(variety: 'Bergeron')),
          notifier,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bergeron'), findsOneWidget);
    },
  );

  testWidgets(
    'chip planting type affiche "Pleine terre" par défaut si null',
    (tester) async {
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        _buildApp(
          UserTreeDetailSheet(tree: _fakeTree()),
          notifier,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pleine terre'), findsWidgets);
    },
  );

  testWidgets(
    'chip planting type affiche la valeur stockée',
    (tester) async {
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        _buildApp(
          UserTreeDetailSheet(tree: _fakeTree(plantingType: 'pot')),
          notifier,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('En pot'), findsOneWidget);
    },
  );
}
```

- [ ] **Step 2: Run the test to verify it fails**

```
fvm flutter test test/features/orchard/presentation/widgets/user_tree_detail_sheet_header_test.dart
```

Expected: FAIL — les chips de variété et type de plantation n'existent pas encore dans le header.

- [ ] **Step 3: Add the imports to `user_tree_detail_sheet.dart`**

Ajouter en tête de `lib/features/orchard/presentation/widgets/user_tree_detail_sheet.dart` :

```dart
import '../../../../core/services/database/fruit_tree_import_service.dart';
import '../../domain/models/planting_type.dart';
import '../sheets/edit_planting_type_sheet.dart';
import '../sheets/edit_variety_sheet.dart';
```

(L'import `fruit_tree_import_service.dart` apporte l'extension `varietiesList` sur `FruitTree`.)

- [ ] **Step 4: Add `plantingType` to the `_update` helper**

Modifier la méthode `_update` (lignes 31-60) — ajouter le paramètre :

```dart
  Future<void> _update({
    String? nickname,
    String? variety,
    DateTime? plantingDate,
    String? location,
    String? notes,
    String? healthStatus,
    DateTime? lastPruningDate,
    DateTime? lastHarvestDate,
    double? lastYieldKg,
    PlantingType? plantingType,
  }) async {
    await ref.read(userFruitTreesNotifierProvider.notifier).updateTree(
          id: _tree.id,
          nickname: nickname,
          variety: variety,
          plantingDate: plantingDate,
          location: location,
          notes: notes,
          healthStatus: healthStatus,
          lastPruningDate: lastPruningDate,
          lastHarvestDate: lastHarvestDate,
          lastYieldKg: lastYieldKg,
          plantingType: plantingType,
        );
    // Recharger les données
    final updated =
        await ref.read(userFruitTreeByIdProvider(_tree.id).future);
    if (updated != null && mounted) {
      setState(() => _tree = updated);
    }
  }
```

- [ ] **Step 5: Add header chips for variety and planting type**

Dans la méthode `build` de `_UserTreeDetailSheetState`, dans le `ListView` du contenu (autour des lignes 95-100, sous le `Row` du header avec l'emoji + nom), **insérer** un nouveau widget `Wrap` de chips juste après la fin du `Row` du header (avant les autres sections existantes). Repérer la fin du `Row` du header (qui contient l'emoji + commonName + nickname) et ajouter, juste après ce `Row` :

```dart
                const SizedBox(height: 12),

                // Chips tappables : variété + type de plantation (données user)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (userTree.variety != null && userTree.variety!.isNotEmpty)
                      _EditableHeaderChip(
                        emoji: '🏷️',
                        label: userTree.variety!,
                        onTap: _onEditVariety,
                      ),
                    _EditableHeaderChip(
                      emoji: (PlantingType.fromDbValue(userTree.plantingType) ??
                              PlantingType.ground)
                          .emoji,
                      label: (PlantingType.fromDbValue(userTree.plantingType) ??
                              PlantingType.ground)
                          .label,
                      onTap: _onEditPlantingType,
                    ),
                  ],
                ),
```

Note : `userTree` correspond à `_tree.userTree`, déjà disponible localement dans le build.

- [ ] **Step 6: Add the edit handlers and the `_EditableHeaderChip` widget**

Dans `_UserTreeDetailSheetState`, juste avant la fermeture de la classe (après `_getHealthColor` ou la dernière méthode existante), ajouter :

```dart
  Future<void> _onEditVariety() async {
    final result = await EditVarietySheet.show(
      context,
      suggestions: _tree.fruitTree.varietiesList,
      initialValue: _tree.userTree.variety,
    );
    if (result == null) return; // Annulé
    // result.value peut être null (champ vidé) — on transmet tel quel.
    await _update(variety: result.value ?? '');
  }

  Future<void> _onEditPlantingType() async {
    final current =
        PlantingType.fromDbValue(_tree.userTree.plantingType) ??
            PlantingType.ground;
    final result = await EditPlantingTypeSheet.show(
      context,
      initialValue: current,
      containerSuitable: _tree.fruitTree.containerSuitable,
      heightAdultM: _tree.fruitTree.heightAdultM,
    );
    if (result == null) return;
    await _update(plantingType: result);
  }
```

**Attention** : `_update(variety: result.value ?? '')` passe `''` quand l'utilisateur a vidé le champ. Or `updateTree(variety: null)` saute la mise à jour (champ optionnel). Pour permettre l'effacement, ajuster : transmettre `result.value ?? ''` est OK car la méthode `updateUserFruitTreePartial` traite `variety != null` comme "à mettre à jour" — donc `''` met la colonne à `''`. Si on préfère un effacement propre (`NULL` en DB) il faudrait élargir l'interface avec `Value<String?>` ; on garde la chaîne vide pour minimiser le delta (l'UI traitera `''` comme `null` lors de l'affichage, déjà via `userTree.variety != null && userTree.variety!.isNotEmpty`).

À la fin du fichier (hors de `_UserTreeDetailSheetState`, niveau top-level) ou avant la fermeture du fichier, ajouter le widget :

```dart
class _EditableHeaderChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _EditableHeaderChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit,
              size: 12,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
```

(Importer `AppTypography` si pas déjà fait, et `AppColors` également.)

- [ ] **Step 7: Run the widget test**

```
fvm flutter test test/features/orchard/presentation/widgets/user_tree_detail_sheet_header_test.dart
```

Expected: PASS — 3 tests passent.

- [ ] **Step 8: Run the full test suite**

```
fvm flutter test
```

Expected: PASS — pas de régression.

- [ ] **Step 9: Visual smoke test (manuel)**

```
fvm flutter run
```

1. Verger → tap sur un arbre existant.
2. Dans le header du sheet, on voit désormais sous le titre les chips « 🏷️ {variété} » (si renseignée) et « 🌱 Pleine terre » (ou autre).
3. Tap sur la chip variété → un sheet d'édition s'ouvre avec l'autocomplete pré-rempli. Modifier, enregistrer → le header se met à jour.
4. Tap sur la chip type plantation → un sheet avec les 3 chips. Sélectionner « En pot » → enregistrer → le header se met à jour.

- [ ] **Step 10: Commit**

```bash
git add lib/features/orchard/presentation/widgets/user_tree_detail_sheet.dart test/features/orchard/presentation/widgets/user_tree_detail_sheet_header_test.dart
git commit -m "feat(orchard): editable variety + planting type chips in user tree header"
```

---

## Task 10: Enrichissement JSON `fruit_trees.json`

**Files:**
- Modify: `assets/data/fruit_trees.json`
- Modify: `lib/core/services/database/fruit_tree_import_service.dart` (force re-import on existing installs)

Pas de test : enrichissement de contenu uniquement. Le test "round-trip JSON ↔ DB" existant (s'il existe — sinon le smoke manuel suffit) couvre déjà le parsing.

- [ ] **Step 1: Enrich `popular_varieties` for trees with sparse lists**

Ouvrir `assets/data/fruit_trees.json` et compléter les listes `popular_varieties` qui semblent maigres. Règles strictes :
- **Cap à 6–8 variétés max** par arbre.
- Variétés vraiment populaires en France/Belgique/Suisse.
- Pas de doublons, pas de variations orthographiques.
- Conserver l'ordre alpha n'est pas requis (ordre actuel = plus populaire d'abord).

Pour l'**Abricotier (id 12)** spécifiquement (la plainte utilisateur initiale), enrichir comme suit (de 4 → 6) :

```json
      "popular_varieties": [
        "Bergeron",
        "Rouge du Roussillon",
        "Polonais",
        "Orangered",
        "Goldrich",
        "Hâtif de Colomer"
      ],
```

Pour les autres arbres : lire `assets/data/fruit_trees.json` arbre par arbre, et **uniquement** quand la liste contient < 4 variétés, ajouter 1 à 2 variétés populaires connues. Si la liste a déjà ≥ 4 variétés, **ne pas y toucher**. Cette discipline évite les changements gratuits et garde le diff focalisé.

Variétés courantes à connaître pour les arbres les plus consultés (à appliquer uniquement si la liste actuelle est < 4) :
- Pommier : Reinette du Mans, Jonagold, Belle de Boskoop
- Poirier : Conférence, Williams, Comice, Beurré Hardy
- Cerisier : Burlat, Bigarreau Napoléon, Reverchon, Sunburst
- Prunier : Reine-Claude, Mirabelle de Nancy, Quetsche d'Alsace
- Pêcher : Reine des vergers, Redhaven, Charles Ingouf
- Figuier : Goutte d'or, Madeleine des deux saisons, Violette de Solliès
- Olivier : Picholine, Tanche, Cailletier, Aglandau
- Noyer : Franquette, Mayette, Parisienne, Lara
- Châtaignier : Marigoule, Bouche de Bétizac, Marsol
- Amandier : Ferragnès, Lauranne, Ferraduel

Ne **pas inventer** de variétés ; en cas de doute, garder la liste actuelle.

- [ ] **Step 2: Force re-import on existing installs**

Le service `FruitTreeImportService` détecte uniquement la version v5 (présence de `climateAdaptation`). Pour propager le nouveau JSON aux installs existants, ajouter un check de version dédié. Modifier `lib/core/services/database/fruit_tree_import_service.dart`, méthode `importFromAssets` (lignes 16-28). Ajouter un check sur l'Abricotier :

```dart
  Future<int> importFromAssets({bool forceReimport = false}) async {
    // Vérifie si les données existent déjà
    final existingCount = await _db.countFruitTrees();
    if (existingCount > 0 && !forceReimport) {
      // Vérifie si les données enrichies (v5+) sont présentes
      final sample = await _db.getFruitTreeById(1);
      if (sample != null && sample.climateAdaptation == null) {
        debugPrint('🌳 Données obsolètes, réimport forcé...');
        return importFromAssets(forceReimport: true);
      }
      // V17 : variétés enrichies (Abricotier passe de 4 à 6 variétés).
      // On utilise l'Abricotier (id 12) comme sentinelle : s'il a < 6
      // variétés en base alors qu'il en a 6 dans le JSON v17, on re-importe.
      final abricotier = await _db.getFruitTreeById(12);
      if (abricotier != null) {
        final varietyCount = abricotier.varietiesList.length;
        if (varietyCount < 6) {
          debugPrint('🌳 Variétés v17 manquantes, réimport forcé...');
          return importFromAssets(forceReimport: true);
        }
      }
      debugPrint('🌳 Base arbres fruitiers déjà peuplée ($existingCount arbres)');
      return existingCount;
    }
```

Note : `varietiesList` est l'extension déjà présente en fin de fichier (lignes 192-199) — pas besoin d'import supplémentaire car on est dans le même fichier.

- [ ] **Step 3: Run the test suite**

```
fvm flutter test
```

Expected: PASS — pas de régression.

- [ ] **Step 4: Visual smoke test (fresh install + upgrade)**

```
fvm flutter run
```

**Cas 1 — upgrade (DB existante)** :
1. Build l'app sur un appareil qui a déjà une install antérieure.
2. Verger → ouvrir Abricotier → onglet « Variétés populaires ».
3. Vérifier que 6 variétés sont listées (les anciennes 4 + Goldrich + Hâtif de Colomer).

**Cas 2 — fresh install** :
1. Désinstaller l'app, réinstaller.
2. Idem cas 1 → 6 variétés visibles.

- [ ] **Step 5: Commit**

```bash
git add assets/data/fruit_trees.json lib/core/services/database/fruit_tree_import_service.dart
git commit -m "feat(orchard): enrich fruit_trees.json varieties + force re-import on upgrade"
```

---

## Task 11: Final verification

**Files:** none

- [ ] **Step 1: Full test suite**

```
fvm flutter test
```

Expected: ALL PASS — no failures, no skipped tests added by this work.

- [ ] **Step 2: Static analysis**

```
fvm flutter analyze
```

Expected: no issues / no new warnings.

- [ ] **Step 3: Build verification**

```
fvm flutter build apk --debug
```

Expected: build success.

- [ ] **Step 4: Manual end-to-end test**

Tester sur device le scénario complet du retour utilisateur original :
1. Ouvrir le verger (fresh install).
2. Tap FAB → picker → choisir « Abricotier ».
3. Vérifier que les 6 variétés s'affichent dans la fiche.
4. Tap « Ajouter à mon verger » → formulaire visible.
5. Sélectionner « En pot ».
6. Dans Variété, taper « MonAbricotier » (texte libre non listé).
7. Confirmer.
8. Ouvrir l'arbre depuis la liste du verger → header montre « 🏷️ MonAbricotier » + « 🪴 En pot ».
9. Tap sur la chip variété → modifier en « Bergeron » → enregistrer.
10. Tap sur la chip type plantation → modifier en « Espalier » → enregistrer.
11. Vérifier que le header reflète les nouvelles valeurs.

- [ ] **Step 5: Self-review of the diff**

```
git diff master --stat
```

Vérifier que la liste de fichiers modifiés correspond exactement à celle annoncée dans la section **File Structure** ci-dessus. Tout fichier inattendu = à investiguer avant de proposer la PR.

---

## Spec coverage check

| Spec section | Task(s) |
|---|---|
| Modèle de données — colonne `plantingType` | Task 2 |
| Enum domaine `PlantingType` | Task 1 |
| Migration drift v16→v17 | Task 2 (Step 4) |
| Formulaire d'ajout — réordonnancement | Task 7 (Step 6) |
| Variété — Autocomplete | Task 5 + Task 7 |
| Type de plantation — ChoiceChips | Task 6 + Task 7 |
| Avertissement si !containerSuitable | Task 6 |
| `addTree(plantingType)` | Task 3 + Task 7 |
| Header user tree — chips data utilisateur | Task 9 |
| Édition inline variété + type | Task 8 + Task 9 |
| `updateTree(plantingType)` | Task 3 + Task 9 |
| Catalogue — renommage tag « 🪴 En pot » | Task 7 (Step 5) |
| JSON — enrichissement variétés | Task 10 |
| Re-import forcé pour anciens installs | Task 10 (Step 2) |
| Backup/restore — sérialisation | Task 4 |
| Tests DB | Task 2 |
| Test widget formulaire | Task 7 |
| Test widget user tree header | Task 9 |
| Tolérance `null` pour anciens arbres | Task 2 (default in onUpgrade) + Task 9 (fallback `PlantingType.ground`) |
