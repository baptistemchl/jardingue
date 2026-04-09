import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/notifications/notification_service.dart';
import 'core/services/rating/rate_app_service.dart';
import 'core/services/update/in_app_update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/database_providers.dart';
import 'core/providers/garden_event_providers.dart';
import 'features/premium/presentation/providers/backup_providers.dart';
import 'features/premium/presentation/providers/premium_providers.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'router/app_router.dart';

/// Déclenche le rate sheet depuis l'intérieur de MaterialApp.
class _RateAppTrigger extends StatefulWidget {
  final Widget child;
  const _RateAppTrigger({required this.child});

  @override
  State<_RateAppTrigger> createState() => _RateAppTriggerState();
}

class _RateAppTriggerState extends State<_RateAppTrigger> {
  bool _triggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_triggered) {
      _triggered = true;
      // Attendre que le Navigator (router) soit monté dans l'arbre
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) maybeShowRateSheet();
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp();

  // Initialiser les locales pour DateFormat
  await initializeDateFormatting('fr_FR', null);

  // Initialiser les notifications
  await NotificationService().init();

  // Vérifier si l'onboarding doit être affiché
  final showOnboarding = await shouldShowOnboarding();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(ProviderScope(child: JardingueApp(showOnboarding: showOnboarding)));
}

class JardingueApp extends ConsumerStatefulWidget {
  final bool showOnboarding;

  const JardingueApp({super.key, required this.showOnboarding});

  @override
  ConsumerState<JardingueApp> createState() => _JardingueAppState();
}

class _JardingueAppState extends ConsumerState<JardingueApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _router = buildRouter(showOnboarding: widget.showOnboarding);

    // Vérifie les mises à jour Play Store
    InAppUpdateService.checkForUpdate();

    // Lance l'import en arrière-plan sans bloquer l'UI
    Future.microtask(() {
      ref
          .read(databaseInitProvider.future)
          .then((count) {
            debugPrint('🌱 Base de données prête: $count plantes');
            // Planifier les notifications d'arrosage
            ref.read(wateringNotificationSchedulerProvider.future);
          })
          .catchError((e) {
            debugPrint('❌ Erreur DB: $e');
          });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _autoBackupIfPremium();
    }
  }

  Future<void> _autoBackupIfPremium() async {
    final premium = ref.read(premiumNotifierProvider);
    final user = ref.read(firebaseUserProvider);
    if (!premium.isPremium || user == null) return;

    try {
      final repo = ref.read(backupRepositoryProvider);
      final data = await repo.exportLocalData();
      await repo.uploadBackup(user.uid, data);
      debugPrint('Auto-backup cloud effectué.');
    } catch (e) {
      debugPrint('Auto-backup échoué : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jardingue',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      locale: const Locale('fr', 'FR'),
      builder: (context, child) => _RateAppTrigger(child: child!),
    );
  }
}
