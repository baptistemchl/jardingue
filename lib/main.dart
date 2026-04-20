import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/crash_reporting/crash_reporting_service.dart';
import 'core/services/crash_reporting/crashlytics_provider_observer.dart';
import 'core/services/notifications/notification_service.dart';
import 'core/services/rating/rate_app_service.dart';
import 'core/services/update/in_app_update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/database_providers.dart';
import 'core/providers/frost_notification_provider.dart';
import 'core/providers/garden_event_providers.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) maybeShowRateSheet();
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() async {
  // Zone gardée : capture toutes les erreurs async non-catchées
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialiser Firebase
    await Firebase.initializeApp();

    // Initialiser Crashlytics et les handlers d'erreurs globaux
    await CrashReportingService.initialize();
    await CrashReportingService.log('App démarrée');

    // Initialiser les locales pour DateFormat
    await initializeDateFormatting('fr_FR', null);

    // Initialiser les notifications
    try {
      await NotificationService().init();
    } catch (e, st) {
      CrashReportingService.recordError(
        e, st,
        reason: 'NotificationService.init',
      );
    }

    // Vérifier si l'onboarding doit être affiché
    bool showOnboarding = false;
    try {
      showOnboarding = await shouldShowOnboarding();
    } catch (e, st) {
      CrashReportingService.recordError(
        e, st,
        reason: 'shouldShowOnboarding',
      );
    }

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
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

    runApp(
      ProviderScope(
        observers: [CrashlyticsProviderObserver()],
        child: JardingueApp(showOnboarding: showOnboarding),
      ),
    );
  }, (error, stack) {
    // Dernière ligne de défense : erreurs async échappées de la zone
    CrashReportingService.recordFatalError(
      error, stack,
      reason: 'runZonedGuarded (erreur non capturée dans la zone)',
    );
  });
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
    CrashReportingService.guard(
      action: () async => InAppUpdateService.checkForUpdate(),
      fallback: null,
      reason: 'InAppUpdateService.checkForUpdate',
    );

    // Lance l'import en arrière-plan sans bloquer l'UI
    Future.microtask(() {
      ref
          .read(databaseInitProvider.future)
          .then((count) {
            CrashReportingService.log('DB prête: $count plantes');
            // Planifier les notifications d'arrosage
            ref.read(wateringNotificationSchedulerProvider.future);
            // Planifier l'alerte de gel si la meteo l'indique
            ref.read(frostNotificationSchedulerProvider.future);
          })
          .catchError((Object e, StackTrace st) {
            CrashReportingService.recordError(
              e, st,
              reason: 'databaseInitProvider',
              extra: {'phase': 'init'},
            );
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
      CrashReportingService.log('Auto-backup cloud effectué');
    } catch (e, st) {
      CrashReportingService.recordError(
        e, st,
        reason: 'autoBackupIfPremium',
        extra: {'uid': user.uid},
      );
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
