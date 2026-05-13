import 'package:drift/drift.dart' hide isNull, isNotNull;
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
