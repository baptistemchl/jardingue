import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/widgets/app_bottom_sheet.dart';

/// Hauteur typique d'une barre de navigation Android 3 boutons.
const double _navBar = 48.0;

/// Taille d'ecran simulee pour les tests.
const Size _screenSize = Size(400, 800);

void _setupView(WidgetTester tester) {
  tester.view.physicalSize = _screenSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Wrappe [child] dans un MaterialApp qui injecte
/// `MediaQuery.padding.bottom = 48` pour simuler une barre 3 boutons.
Widget _appWithBottomInset(Widget child) {
  return MaterialApp(
    builder: (ctx, builderChild) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(
        padding: const EdgeInsets.only(bottom: _navBar),
      ),
      child: builderChild!,
    ),
    home: child,
  );
}

void main() {
  group('AppBottomSheet (rendu direct)', () {
    testWidgets('rend le handle quand AppBottomSheetHandle est dans le child',
        (tester) async {
      _setupView(tester);

      await tester.pumpWidget(
        _appWithBottomInset(
          const Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomSheet(
              heightFraction: 0.5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBottomSheetHandle(),
                  Text('Content'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AppBottomSheetHandle), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('respecte heightFraction (0.5 => moitie de l\'ecran)',
        (tester) async {
      _setupView(tester);

      await tester.pumpWidget(
        _appWithBottomInset(
          const Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomSheet(
              heightFraction: 0.5,
              child: SizedBox.expand(),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AppBottomSheet));
      expect(size.height, _screenSize.height * 0.5);
    });

    testWidgets(
      'inset le contenu au-dessus de MediaQuery.padding.bottom (3 boutons)',
      (tester) async {
        _setupView(tester);

        await tester.pumpWidget(
          _appWithBottomInset(
            const Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomSheet(
                heightFraction: 0.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBottomSheetHandle(),
                    Spacer(),
                    SizedBox(
                      key: Key('save-btn'),
                      height: 56,
                      width: double.infinity,
                      child: ColoredBox(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final rect = tester.getRect(find.byKey(const Key('save-btn')));
        expect(
          rect.bottom,
          lessThanOrEqualTo(_screenSize.height - _navBar),
          reason: 'Le bouton bas est dans la zone occultee par la barre 3 '
              'boutons. SafeArea(top:false) du wrapper a ete casse.',
        );
      },
    );

    testWidgets('sans heightFraction => wrap-content (mainAxis min)',
        (tester) async {
      _setupView(tester);

      await tester.pumpWidget(
        _appWithBottomInset(
          const Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBottomSheetHandle(),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AppBottomSheet));
      // wrap-content : pas la hauteur totale de l'ecran
      expect(size.height, lessThan(_screenSize.height));
    });
  });

  group('AppBottomSheet.show() (helper modal)', () {
    testWidgets('ouvre le sheet et le bouton bas est cliquable',
        (tester) async {
      _setupView(tester);

      var tapped = false;

      await tester.pumpWidget(
        _appWithBottomInset(
          Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => AppBottomSheet.show<void>(
                    context: ctx,
                    heightFraction: 0.82,
                    child: Column(
                      children: [
                        const AppBottomSheetHandle(),
                        const Expanded(child: SizedBox.shrink()),
                        ElevatedButton(
                          key: const Key('save-btn'),
                          onPressed: () => tapped = true,
                          child: const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-btn')), findsOneWidget);

      // Position dans la zone safe (pas occultee par la barre OS).
      final rect = tester.getRect(find.byKey(const Key('save-btn')));
      expect(
        rect.bottom,
        lessThanOrEqualTo(_screenSize.height - _navBar),
        reason: 'Bouton "Enregistrer" tronque par la barre 3 boutons',
      );

      // Click effectif (pas de hit-test miss).
      await tester.tap(find.byKey(const Key('save-btn')));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('Navigator.pop ferme le sheet', (tester) async {
      _setupView(tester);

      await tester.pumpWidget(
        _appWithBottomInset(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppBottomSheet.show<void>(
                  context: ctx,
                  child: Builder(
                    builder: (sheetCtx) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppBottomSheetHandle(),
                        TextButton(
                          key: const Key('close-btn'),
                          onPressed: () => Navigator.pop(sheetCtx),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('close-btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('close-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('close-btn')), findsNothing);
    });
  });

  group('Regression bug paillage (AddEventSheet)', () {
    testWidgets(
      'heightFraction 0.82 + bouton confirm en bas reste cliquable',
      (tester) async {
        // Reproduit le scenario qui a declenche tout le ticket :
        // AddEventSheet > Entretien > Paillage > Confirmer. Le bouton
        // "Enregistrer" etait tronque par la barre 3 boutons Android.
        _setupView(tester);

        var confirmed = false;

        await tester.pumpWidget(
          _appWithBottomInset(
            Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => AppBottomSheet.show<void>(
                    context: ctx,
                    heightFraction: 0.82, // meme valeur qu'AddEventSheet
                    child: Column(
                      children: [
                        const AppBottomSheetHandle(),
                        const Expanded(
                          child: Center(child: Text('Step Paillage')),
                        ),
                        ElevatedButton(
                          key: const Key('confirm-btn'),
                          onPressed: () => confirmed = true,
                          child: const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();

        final rect = tester.getRect(find.byKey(const Key('confirm-btn')));
        expect(
          rect.bottom,
          lessThanOrEqualTo(_screenSize.height - _navBar),
          reason: 'REGRESSION : bouton confirm Paillage masque par 3 boutons',
        );

        await tester.tap(find.byKey(const Key('confirm-btn')));
        await tester.pumpAndSettle();
        expect(confirmed, isTrue);
      },
    );
  });
}
