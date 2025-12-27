import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/database_providers.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: JardingueApp()));
}

class JardingueApp extends ConsumerStatefulWidget {
  const JardingueApp({super.key});

  @override
  ConsumerState<JardingueApp> createState() => _JardingueAppState();
}

class _JardingueAppState extends ConsumerState<JardingueApp> {
  @override
  void initState() {
    super.initState();
    // Lance l'import en arrière-plan sans bloquer l'UI
    Future.microtask(() {
      ref
          .read(databaseInitProvider.future)
          .then((count) {
            debugPrint('🌱 Base de données prête: $count plantes');
          })
          .catchError((e) {
            debugPrint('❌ Erreur DB: $e');
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jardingue',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
