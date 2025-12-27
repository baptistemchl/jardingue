import '../models/{{name.snakeCase()}}_model.dart';

/// Repository pour gérer les données de {{name.pascalCase()}}
abstract class {{name.pascalCase()}}Repository {
  /// Récupère tous les éléments
  Future<List<{{name.pascalCase()}}Model>> getAll();

  /// Récupère un élément par son ID
  Future<{{name.pascalCase()}}Model?> getById(String id);

  /// Crée un nouvel élément
  Future<{{name.pascalCase()}}Model> create({{name.pascalCase()}}Model item);

  /// Met à jour un élément
  Future<{{name.pascalCase()}}Model> update({{name.pascalCase()}}Model item);

  /// Supprime un élément
  Future<void> delete(String id);
}

/// Implémentation du repository {{name.pascalCase()}}
class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  // TODO: Injecter les datasources nécessaires

  @override
  Future<List<{{name.pascalCase()}}Model>> getAll() async {
    // TODO: Implémenter
    throw UnimplementedError();
  }

  @override
  Future<{{name.pascalCase()}}Model?> getById(String id) async {
    // TODO: Implémenter
    throw UnimplementedError();
  }

  @override
  Future<{{name.pascalCase()}}Model> create({{name.pascalCase()}}Model item) async {
    // TODO: Implémenter
    throw UnimplementedError();
  }

  @override
  Future<{{name.pascalCase()}}Model> update({{name.pascalCase()}}Model item) async {
    // TODO: Implémenter
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {
    // TODO: Implémenter
    throw UnimplementedError();
  }
}
