import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/about_screen.dart';
import '../features/garden/presentation/screens/garden_screen.dart';
import '../features/garden/presentation/screens/garden_editor_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/premium/presentation/screens/premium_screen.dart';
import '../features/plants/presentation/screens/plants_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/weather/presentation/screens/weather_screen.dart';
import '../features/planning/presentation/screens/planning_screen.dart';
import 'scaffold_with_nav_bar.dart';

/// Configuration du router de l'application
/// Utilise go_router pour une navigation déclarative

// Clés de navigation pour les branches
final rootNavigatorKey = GlobalKey<NavigatorState>();
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
  static const String planning = '/planning';
  static const String settings = '/settings';
  static const String premium = '/premium';
  static const String about = '/about';
}

/// Construit le router avec la route initiale selon l'état de l'onboarding.
GoRouter buildRouter({required bool showOnboarding}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
        parentNavigatorKey: rootNavigatorKey,
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
      // ROUTES HORS SHELL (SANS NAVBAR)
      // =========================================

      // Écran Premium / Cloud Backup
      GoRoute(
        path: AppRoutes.premium,
        name: 'premium',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const PremiumScreen(),
          );
        },
      ),

      // Éditeur de jardin
      GoRoute(
        path: '${AppRoutes.garden}/editor/:gardenId',
        name: 'gardenEditor',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final gardenId = int.parse(
            state.pathParameters['gardenId']!,
          );
          return MaterialPage(
            key: state.pageKey,
            child: GardenEditorScreen(
              gardenId: gardenId,
            ),
          );
        },
      ),

      // À propos
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AboutScreen(),
        ),
      ),

      // Météo dédiée (hors navbar, page push)
      GoRoute(
        path: AppRoutes.weather,
        name: 'weather',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            MaterialPage(
          key: state.pageKey,
          child: const WeatherScreen(),
        ),
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
          GoRoute(
            path: AppRoutes.garden,
            name: 'garden',
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: GardenScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.plants,
            name: 'plants',
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: PlantsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            name: 'calendar',
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: CalendarScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.planning,
            name: 'planning',
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: PlanningScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
