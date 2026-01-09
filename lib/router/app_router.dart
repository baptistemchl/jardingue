import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/garden/presentation/screens/garden_screen.dart';
import '../features/garden/presentation/screens/garden_editor_screen.dart';
import '../features/plants/presentation/screens/plants_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/weather/presentation/screens/weather_screen.dart';
import 'scaffold_with_nav_bar.dart';

/// Configuration du router de l'application
/// Utilise go_router pour une navigation déclarative

// Clés de navigation pour les branches
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Routes nommées
abstract final class AppRoutes {
  static const String garden = '/garden';
  static const String gardenEditor = '/garden/editor';
  static const String plants = '/plants';
  static const String plantDetail = '/plants/:id';
  static const String calendar = '/calendar';
  static const String weather = '/weather';
  static const String settings = '/settings';
}

/// Configuration du router
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.garden,
  debugLogDiagnostics: true,
  routes: [
    // Shell route pour la navigation avec bottom bar
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        // Garden - Plan du potager
        GoRoute(
          path: AppRoutes.garden,
          name: 'garden',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: GardenScreen()),
          routes: [
            // Éditeur de jardin (sous-route pour garder la navbar)
            GoRoute(
              path: 'editor/:gardenId',
              name: 'gardenEditor',
              pageBuilder: (context, state) {
                final gardenId = int.parse(state.pathParameters['gardenId']!);
                return NoTransitionPage(
                  child: GardenEditorScreen(gardenId: gardenId),
                );
              },
            ),
          ],
        ),

        // Plants - Liste des plantes
        GoRoute(
          path: AppRoutes.plants,
          name: 'plants',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PlantsScreen()),
          routes: [
            // Detail d'une plante
            GoRoute(
              path: ':id',
              name: 'plantDetail',
              builder: (context, state) {
                final plantId = state.pathParameters['id']!;
                return PlantDetailScreen(plantId: plantId);
              },
            ),
          ],
        ),

        // Calendar - Calendrier du potager
        GoRoute(
          path: AppRoutes.calendar,
          name: 'calendar',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CalendarScreen()),
        ),

        // Weather - Météo
        GoRoute(
          path: AppRoutes.weather,
          name: 'weather',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: WeatherScreen()),
        ),
      ],
    ),
  ],
);

/// Placeholder pour PlantDetailScreen (à implémenter)
class PlantDetailScreen extends StatelessWidget {
  final String plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Plante $plantId')),
      body: Center(child: Text('Détail de la plante $plantId')),
    );
  }
}
