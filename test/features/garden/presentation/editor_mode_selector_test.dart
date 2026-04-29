import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/features/garden/domain/editor_mode.dart';
import 'package:jardingue/features/garden/presentation/widgets/editor/editor_mode_selector.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('EditorModeSelector', () {
    testWidgets('shows the active mode label only', (tester) async {
      await tester.pumpWidget(_wrap(
        EditorModeSelector(
          mode: EditorMode.locked,
          onChanged: (_) {},
        ),
      ));

      // Le label du segment actif est rendu (widthFactor 1.0).
      // Les autres labels sont presents dans l'arbre mais cliques
      // (widthFactor 0.0). On verifie que "Verrouillé" est trouve.
      expect(find.text('Verrouillé'), findsOneWidget);
    });

    testWidgets('renders the active label for each mode', (tester) async {
      for (final entry in {
        EditorMode.locked: 'Verrouillé',
        EditorMode.move: 'Déplacer',
        EditorMode.resize: 'Redimensionner',
      }.entries) {
        await tester.pumpWidget(_wrap(
          EditorModeSelector(
            mode: entry.key,
            onChanged: (_) {},
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget,
            reason: 'mode ${entry.key} should display "${entry.value}"');
      }
    });

    testWidgets('tapping each inactive segment switches mode', (tester) async {
      EditorMode current = EditorMode.locked;
      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (ctx, setState) {
            return EditorModeSelector(
              mode: current,
              onChanged: (m) => setState(() => current = m),
            );
          },
        ),
      ));

      expect(find.text('Verrouillé'), findsOneWidget);

      final segments = find.descendant(
        of: find.byType(EditorModeSelector),
        matching: find.byType(GestureDetector),
      );
      expect(segments, findsNWidgets(3));

      // Tap sur le 2eme segment (Déplacer)
      await tester.tap(segments.at(1));
      await tester.pumpAndSettle();
      expect(current, EditorMode.move);
      expect(find.text('Déplacer'), findsOneWidget);

      // Tap sur le 3eme segment (Redimensionner)
      await tester.tap(find.descendant(
        of: find.byType(EditorModeSelector),
        matching: find.byType(GestureDetector),
      ).at(2));
      await tester.pumpAndSettle();
      expect(current, EditorMode.resize);
      expect(find.text('Redimensionner'), findsOneWidget);

      // Retour au 1er segment (Verrouillé)
      await tester.tap(find.descendant(
        of: find.byType(EditorModeSelector),
        matching: find.byType(GestureDetector),
      ).at(0));
      await tester.pumpAndSettle();
      expect(current, EditorMode.locked);
      expect(find.text('Verrouillé'), findsOneWidget);
    });

    testWidgets('tapping the already-active segment does not call onChanged',
        (tester) async {
      var callCount = 0;
      await tester.pumpWidget(_wrap(
        EditorModeSelector(
          mode: EditorMode.move,
          onChanged: (_) => callCount++,
        ),
      ));

      // Le 2eme segment (move) est l'actif
      final segments = find.descendant(
        of: find.byType(EditorModeSelector),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(segments.at(1));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });
  });
}
