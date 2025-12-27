# 🏗️ Architecture Jardingue

## Vue d'ensemble

Jardingue utilise une architecture **Feature-First** combinée avec **Riverpod** pour le state management. Cette approche offre :

- ✅ **Modularité** : Chaque feature est indépendante
- ✅ **Scalabilité** : Facile d'ajouter de nouvelles features
- ✅ **Testabilité** : Chaque couche peut être testée isolément
- ✅ **Simplicité** : Pas de boilerplate excessif

## Structure des dossiers

```
lib/
├── core/                        # 🔧 Code partagé
│   ├── constants/
│   │   ├── app_colors.dart     # Palette de couleurs
│   │   └── app_spacing.dart    # Espacements & dimensions
│   │
│   ├── theme/
│   │   ├── app_theme.dart      # ThemeData Material
│   │   ├── app_typography.dart # Styles de texte
│   │   └── glass_decoration.dart # Glassmorphism
│   │
│   ├── widgets/                # Widgets réutilisables
│   │   ├── buttons/
│   │   ├── cards/
│   │   └── inputs/
│   │
│   ├── services/               # Services globaux
│   │   ├── database/           # Drift database
│   │   └── api/                # Clients HTTP
│   │
│   └── utils/                  # Helpers & extensions
│
├── features/                   # 📦 Features de l'app
│   ├── garden/                # Plan du potager
│   ├── plants/                # Catalogue de plantes
│   └── weather/               # Météo
│
├── router/                     # 🧭 Navigation
│   ├── app_router.dart        # Configuration go_router
│   └── scaffold_with_nav_bar.dart
│
└── main.dart                   # Point d'entrée
```

## Anatomie d'une Feature

Chaque feature suit la même structure :

```
feature_name/
├── data/                       # 💾 Couche données
│   ├── models/                # Modèles de données (Freezed)
│   │   └── plant_model.dart
│   │
│   ├── repositories/          # Abstraction accès données
│   │   └── plant_repository.dart
│   │
│   └── datasources/           # Sources de données
│       ├── plant_local_datasource.dart   # SQLite
│       └── plant_remote_datasource.dart  # API
│
├── presentation/              # 🎨 Couche présentation
│   ├── screens/              # Écrans complets
│   │   └── plants_screen.dart
│   │
│   └── widgets/              # Widgets de la feature
│       └── plant_card.dart
│
└── providers/                 # 🔄 State Riverpod
    └── plants_provider.dart
```

## Flux de données

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Widget    │────▶│  Provider   │────▶│ Repository  │
│  (ConsumerW)│◀────│  (Riverpod) │◀────│  (Abstract) │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │ DataSource  │
                                        │ (DB / API)  │
                                        └─────────────┘
```

### 1. Widget (Presentation)

```dart
class PlantsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute le provider
    final plantsState = ref.watch(plantsNotifierProvider);
    
    return plantsState.when(
      data: (plants) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Erreur: $e'),
    );
  }
}
```

### 2. Provider (State Management)

```dart
// Provider simple
final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  final repository = ref.watch(plantsRepositoryProvider);
  return repository.getAll();
});

// StateNotifier pour état mutable
class PlantsNotifier extends StateNotifier<AsyncValue<List<Plant>>> {
  final PlantsRepository _repository;
  
  Future<void> addPlant(Plant plant) async {
    await _repository.create(plant);
    // Refresh state...
  }
}
```

### 3. Repository (Abstraction)

```dart
abstract class PlantsRepository {
  Future<List<Plant>> getAll();
  Future<Plant?> getById(String id);
  Future<void> create(Plant plant);
  Future<void> update(Plant plant);
  Future<void> delete(String id);
}

class PlantsRepositoryImpl implements PlantsRepository {
  final PlantsLocalDataSource _localDataSource;
  
  @override
  Future<List<Plant>> getAll() => _localDataSource.getAllPlants();
}
```

### 4. DataSource (Données)

```dart
class PlantsLocalDataSource {
  final AppDatabase _db;
  
  Future<List<Plant>> getAllPlants() async {
    return _db.select(_db.plants).get();
  }
}
```

## Riverpod - Best Practices

### Providers de base

```dart
// Provider simple (lecture seule)
final configProvider = Provider<Config>((ref) => Config());

// FutureProvider (données asynchrones)
final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  return ref.watch(repositoryProvider).getAll();
});

// StateNotifierProvider (état mutable)
final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});
```

### Provider avec paramètre (family)

```dart
final plantByIdProvider = FutureProvider.family<Plant?, String>((ref, id) {
  return ref.watch(repositoryProvider).getById(id);
});

// Usage
final plant = ref.watch(plantByIdProvider('plant_123'));
```

### Invalidation et refresh

```dart
// Invalider pour forcer un refresh
ref.invalidate(plantsProvider);

// Refresh manuel
ref.refresh(plantsProvider);
```

## Navigation avec go_router

### Configuration

```dart
final appRouter = GoRouter(
  initialLocation: '/garden',
  routes: [
    ShellRoute(
      builder: (_, __, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(path: '/garden', builder: (_, __) => GardenScreen()),
        GoRoute(path: '/plants', builder: (_, __) => PlantsScreen()),
        GoRoute(path: '/weather', builder: (_, __) => WeatherScreen()),
      ],
    ),
  ],
);
```

### Navigation

```dart
// Navigation simple
context.go('/plants');

// Avec paramètre
context.go('/plants/plant_123');

// Push (empile)
context.push('/plants/plant_123/edit');

// Pop (dépile)
context.pop();
```

## Base de données (Drift)

### Définition de table

```dart
class Plants extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get spacing => integer()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### Requêtes

```dart
// Select all
final plants = await db.select(db.plants).get();

// Select with filter
final tomatoes = await (db.select(db.plants)
  ..where((p) => p.category.equals('fruit')))
  .get();

// Insert
await db.into(db.plants).insert(PlantCompanion(...));

// Update
await (db.update(db.plants)
  ..where((p) => p.id.equals(id)))
  .write(PlantCompanion(...));

// Delete
await (db.delete(db.plants)
  ..where((p) => p.id.equals(id)))
  .go();
```

## Bonnes pratiques

### 1. Séparation des responsabilités

- **Widget** : Affichage uniquement
- **Provider** : Logique métier et état
- **Repository** : Abstraction des données
- **DataSource** : Accès aux données brutes

### 2. Immutabilité avec Freezed

```dart
@freezed
class Plant with _$Plant {
  const factory Plant({
    required String id,
    required String name,
  }) = _Plant;
}

// Copie avec modification
final updatedPlant = plant.copyWith(name: 'Nouveau nom');
```

### 3. Gestion des erreurs

```dart
// Dans le provider
try {
  final data = await repository.getData();
  state = AsyncValue.data(data);
} catch (e, st) {
  state = AsyncValue.error(e, st);
}

// Dans le widget
asyncValue.when(
  data: (data) => /* ... */,
  loading: () => /* ... */,
  error: (e, _) => /* ... */,
);
```

### 4. Tests

```dart
// Test de repository
test('should return all plants', () async {
  final mockDataSource = MockPlantsDataSource();
  final repository = PlantsRepositoryImpl(mockDataSource);
  
  when(mockDataSource.getAll()).thenAnswer((_) async => [testPlant]);
  
  final result = await repository.getAll();
  expect(result, [testPlant]);
});
```

---

Pour plus de détails, voir les fichiers sources dans `lib/`.
