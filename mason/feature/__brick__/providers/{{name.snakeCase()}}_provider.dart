import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/{{name.snakeCase()}}_model.dart';
import '../data/repositories/{{name.snakeCase()}}_repository.dart';

/// Provider pour le repository {{name.pascalCase()}}
final {{name.camelCase()}}RepositoryProvider = Provider<{{name.pascalCase()}}Repository>((ref) {
  return {{name.pascalCase()}}RepositoryImpl();
});

/// Provider pour la liste des {{name.pascalCase()}}
final {{name.camelCase()}}ListProvider = FutureProvider<List<{{name.pascalCase()}}Model>>((ref) async {
  final repository = ref.watch({{name.camelCase()}}RepositoryProvider);
  return repository.getAll();
});

/// Provider pour un {{name.pascalCase()}} par ID
final {{name.camelCase()}}ByIdProvider = FutureProvider.family<{{name.pascalCase()}}Model?, String>((ref, id) async {
  final repository = ref.watch({{name.camelCase()}}RepositoryProvider);
  return repository.getById(id);
});

/// State notifier pour gérer l'état de {{name.pascalCase()}}
class {{name.pascalCase()}}Notifier extends StateNotifier<AsyncValue<List<{{name.pascalCase()}}Model>>> {
  final {{name.pascalCase()}}Repository _repository;

  {{name.pascalCase()}}Notifier(this._repository) : super(const AsyncValue.loading()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getAll();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadData();
  }

  Future<void> add({{name.pascalCase()}}Model item) async {
    try {
      await _repository.create(item);
      await _loadData();
    } catch (e) {
      // Gérer l'erreur
      rethrow;
    }
  }

  Future<void> update({{name.pascalCase()}}Model item) async {
    try {
      await _repository.update(item);
      await _loadData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);
      await _loadData();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider pour le notifier {{name.pascalCase()}}
final {{name.camelCase()}}NotifierProvider = StateNotifierProvider<{{name.pascalCase()}}Notifier, AsyncValue<List<{{name.pascalCase()}}Model>>>((ref) {
  final repository = ref.watch({{name.camelCase()}}RepositoryProvider);
  return {{name.pascalCase()}}Notifier(repository);
});
