# 🌱 Jardingue

Application mobile Flutter pour la gestion de potager intelligente.

## ✨ Fonctionnalités

- 📐 **Plan du potager** : Créez et organisez visuellement votre jardin
- 🌿 **Base de plantes** : Catalogue complet avec propriétés et compatibilités
- ☀️ **Météo intégrée** : Prévisions et conseils de jardinage personnalisés
- 🔄 **Mode hors-ligne** : Toutes les données stockées localement

## 🏗️ Architecture

Le projet utilise une architecture **Feature-First** avec Riverpod :

```
lib/
├── core/                    # Éléments partagés
│   ├── constants/          # Couleurs, espacements
│   ├── theme/              # Thème Material + Glassmorphism
│   ├── widgets/            # Widgets réutilisables
│   ├── services/           # Services (API, DB)
│   └── utils/              # Helpers
│
├── features/               # Features (1 feature = 1 dossier)
│   ├── garden/            # Plan du potager
│   ├── plants/            # Gestion des plantes
│   └── weather/           # Météo
│
├── router/                 # Navigation (go_router)
└── main.dart
```

## 🎨 Design System

### Couleurs principales

| Couleur | Hex | Usage |
|---------|-----|-------|
| Primary (Vert sauge) | `#4A7C59` | Actions principales |
| Secondary (Jaune) | `#E9C46A` | Accents |
| Background | `#F5F7F2` | Fond de l'app |
| Surface | `#FFFFFF` | Cartes et surfaces |

### Glassmorphism

L'app utilise des effets de verre dépoli (glassmorphism) pour un look moderne :

```dart
GlassCard(
  child: Text('Contenu'),
)
```

## 🚀 Démarrage

### Prérequis

- Flutter 3.9+
- Dart 3.9+

### Installation

```bash
# Cloner le projet
git clone <repo>
cd jardingue

# Installer les dépendances
flutter pub get

# Générer le code (Freezed, Drift, etc.)
dart run build_runner build --delete-conflicting-outputs

# Lancer l'app
flutter run
```

## 📦 Packages principaux

| Package | Version | Usage |
|---------|---------|-------|
| flutter_riverpod | ^2.6.1 | State management |
| go_router | ^14.8.1 | Navigation |
| drift | ^2.26.0 | Base de données SQLite |
| dio | ^5.8.0 | Client HTTP |
| freezed | ^2.5.8 | Génération de modèles |

## 🧱 Générer une nouvelle feature

Le projet utilise Mason pour générer des features :

```bash
# Depuis la racine du projet
cd mason/feature
mason make feature --name ma_nouvelle_feature

# Les fichiers générés :
# - data/models/ma_nouvelle_feature_model.dart
# - data/repositories/ma_nouvelle_feature_repository.dart
# - presentation/screens/ma_nouvelle_feature_screen.dart
# - presentation/widgets/ma_nouvelle_feature_card.dart
# - providers/ma_nouvelle_feature_provider.dart
```

Ensuite, déplacez le dossier généré dans `lib/features/`.

## 📁 Structure d'une feature

```
feature_name/
├── data/
│   ├── models/           # Modèles Freezed
│   ├── repositories/     # Abstraction + implémentation
│   └── datasources/      # Sources de données (API, DB)
├── presentation/
│   ├── screens/          # Écrans
│   └── widgets/          # Widgets spécifiques
└── providers/            # Providers Riverpod
```

## 🗄️ Base de données

L'app utilise **Drift** pour le stockage local SQLite :

```dart
// Exemple de requête
final plants = await database.select(database.plants).get();
```

## 🌤️ API Météo

Utilise [Open-Meteo](https://open-meteo.com/) (gratuit, sans clé API) :

```dart
final weather = await weatherService.getCurrentWeather(
  latitude: 48.8566,
  longitude: 2.3522,
);
```

## 📝 Conventions de code

- **Fichiers** : `snake_case.dart`
- **Classes** : `PascalCase`
- **Variables/fonctions** : `camelCase`
- **Constantes** : `camelCase` ou `SCREAMING_SNAKE_CASE`

## 🧪 Tests

```bash
# Lancer tous les tests
flutter test

# Avec couverture
flutter test --coverage
```

## 📱 Builds

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 📄 License

MIT License - voir [LICENSE](LICENSE)

---

Fait avec 💚 et Flutter
