import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/garden/presentation/screens/garden_screen.dart';
import '../features/garden/presentation/screens/garden_editor_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
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
  static const String onboarding = '/onboarding';
  static const String garden = '/garden';
  static const String gardenEditor = '/garden/editor';
  static const String plants = '/plants';
  static const String plantDetail = '/plants/:id';
  static const String calendar = '/calendar';
  static const String weather = '/weather';
  static const String settings = '/settings';
}

/// Construit le router avec la route initiale selon l'état de l'onboarding.
GoRouter buildRouter({required bool showOnboarding}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation:
        showOnboarding ? AppRoutes.onboarding : AppRoutes.garden,
    debugLogDiagnostics: true,
    routes: [
      // =========================================
      // ONBOARDING (SANS NAVBAR)
      // =========================================
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: OnboardingScreen(
              onComplete: () {
                // Remplace la route pour empêcher le retour arrière
                GoRouter.of(context).go(AppRoutes.garden);
              },
            ),
          );
        },
      ),

      // =========================================
      // ROUTE HORS SHELL (SANS NAVBAR)
      // =========================================

      // Éditeur de jardin - SANS navbar pour éviter les changements de page accidentels
      GoRoute(
        path: '${AppRoutes.garden}/editor/:gardenId',
        name: 'gardenEditor',
        parentNavigatorKey: _rootNavigatorKey,
        // Utilise le navigateur root (pas le shell)
        pageBuilder: (context, state) {
          final gardenId = int.parse(state.pathParameters['gardenId']!);
          return MaterialPage(
            key: state.pageKey,
            child: GardenEditorScreen(gardenId: gardenId),
          );
        },
      ),

      // =========================================
      // SHELL ROUTE (AVEC NAVBAR)
      // =========================================
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
          ),

          // Plants - Liste des plantes
          GoRoute(
            path: AppRoutes.plants,
            name: 'plants',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlantsScreen()),
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
}
