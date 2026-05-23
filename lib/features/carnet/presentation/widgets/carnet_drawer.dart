import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/carnet_tab.dart';
import '../providers/carnet_ui_providers.dart';
import 'tabs/about_tab.dart';
import 'tabs/harvests_tab.dart';
import 'tabs/journal_tab.dart';
import 'tabs/seedlings_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/stats_tab.dart';

/// Drawer "Carnet de bord" qui slide depuis le bord droit.
///
/// Apparence carnet relié kraft, avec 4 onglets marque-pages
/// verticaux sur le bord gauche du drawer (côté intérieur écran).
class CarnetDrawer extends ConsumerStatefulWidget {
  const CarnetDrawer({super.key});

  @override
  ConsumerState<CarnetDrawer> createState() => _CarnetDrawerState();
}

class _CarnetDrawerState extends ConsumerState<CarnetDrawer>
    with SingleTickerProviderStateMixin {
  // Largeur du drawer relative à l'écran.
  static const double _drawerWidthFraction = 0.86;
  // Largeur d'un marque-page qui dépasse du drawer.
  static const double _tabWidth = 44;

  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(carnetUiProvider);
    final size = MediaQuery.of(context).size;
    final drawerWidth = size.width * _drawerWidthFraction;
    final fullWidth = drawerWidth + _tabWidth;

    // Drawer slide depuis le bord gauche.
    // Fermé : totalement hors écran à gauche (left = -fullWidth).
    // Ouvert : aligné au bord gauche (left = 0).
    const openX = 0.0;
    final closedX = -fullWidth;
    final targetX = ui.isOpen ? openX : closedX;
    final currentX = (targetX + _dragOffset).clamp(closedX, openX);
    final progress = ((currentX - closedX) / fullWidth).clamp(0.0, 1.0);

    return Stack(
      children: [
        // Backdrop sombre + blur sur tout l'écran.
        IgnorePointer(
          ignoring: !ui.isOpen,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 260),
            opacity: progress,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(carnetUiProvider.notifier).close(),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 4 * progress,
                  sigmaY: 4 * progress,
                ),
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ),

        // Drawer + marque-pages sur le côté droit du drawer
        // (côté intérieur écran quand drawer ouvert).
        AnimatedPositioned(
          duration: _dragOffset == 0
              ? const Duration(milliseconds: 320)
              : Duration.zero,
          curve: Curves.easeOutCubic,
          left: currentX,
          top: 0,
          bottom: 0,
          width: fullWidth,
          child: GestureDetector(
            onHorizontalDragUpdate: (d) {
              setState(() {
                _dragOffset =
                    (_dragOffset + d.delta.dx).clamp(-fullWidth, 0.0);
              });
            },
            onHorizontalDragEnd: (d) {
              final v = d.velocity.pixelsPerSecond.dx;
              final shouldClose =
                  v < -600 || _dragOffset < -fullWidth * 0.35;
              setState(() => _dragOffset = 0);
              if (shouldClose) {
                ref.read(carnetUiProvider.notifier).close();
              }
            },
            // Material englobant pour fournir le contexte (InkWell,
            // Switch) ET un DefaultTextStyle valide aux marque-pages
            // — sinon les Text dans RotatedBox héritent du fallback
            // Flutter avec underline jaune fluo.
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  Expanded(child: _DrawerBody(activeTab: ui.activeTab)),
                  _TabStrip(activeTab: ui.activeTab),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bandeau vertical des 4 marque-pages, accroché au bord gauche du drawer.
class _TabStrip extends ConsumerWidget {
  final CarnetTab activeTab;
  const _TabStrip({required this.activeTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final entries = <_TabSpec>[
      _TabSpec(
        CarnetTab.harvests,
        loc.carnetTabHarvests,
        PhosphorIcons.basket(PhosphorIconsStyle.regular),
        PhosphorIcons.basket(PhosphorIconsStyle.fill),
      ),
      _TabSpec(
        CarnetTab.seedlings,
        loc.carnetTabSeedlings,
        PhosphorIcons.plant(PhosphorIconsStyle.regular),
        PhosphorIcons.plant(PhosphorIconsStyle.fill),
      ),
      _TabSpec(
        CarnetTab.journal,
        loc.carnetTabJournal,
        PhosphorIcons.notebook(PhosphorIconsStyle.regular),
        PhosphorIcons.notebook(PhosphorIconsStyle.fill),
      ),
      _TabSpec(
        CarnetTab.stats,
        loc.carnetTabStats,
        PhosphorIcons.chartBar(PhosphorIconsStyle.regular),
        PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
      ),
      _TabSpec(
        CarnetTab.settings,
        loc.carnetTabSettings,
        PhosphorIcons.gearSix(PhosphorIconsStyle.regular),
        PhosphorIcons.gearSix(PhosphorIconsStyle.fill),
      ),
      _TabSpec(
        CarnetTab.about,
        loc.carnetTabAbout,
        PhosphorIcons.info(PhosphorIconsStyle.regular),
        PhosphorIcons.info(PhosphorIconsStyle.fill),
      ),
    ];

    // SingleChildScrollView pour permettre le défilement si le total
    // des 6 marque-pages dépasse la hauteur disponible (petits écrans,
    // Galaxy Fold replié, etc.). Les paddings haut/bas restent
    // généreux mais cèdent au scroll si nécessaire.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: entries.map((e) {
          final isActive = e.tab == activeTab;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _MarquePage(
              spec: e,
              isActive: isActive,
              onTap: () => ref.read(carnetUiProvider.notifier).setTab(e.tab),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabSpec {
  final CarnetTab tab;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabSpec(this.tab, this.label, this.icon, this.activeIcon);
}

/// Titre long affiché dans le header du drawer body selon l'onglet
/// courant — précise à l'utilisateur où il est sans le forcer à lire
/// l'icône active.
String _tabTitle(CarnetTab tab, AppLocalizations loc) {
  return switch (tab) {
    CarnetTab.harvests => loc.carnetHeaderHarvests,
    CarnetTab.seedlings => loc.carnetHeaderSeedlings,
    CarnetTab.journal => loc.carnetHeaderJournal,
    CarnetTab.stats => loc.carnetHeaderStats,
    CarnetTab.settings => loc.carnetHeaderSettings,
    CarnetTab.about => loc.carnetHeaderAbout,
  };
}

class _MarquePage extends StatelessWidget {
  final _TabSpec spec;
  final bool isActive;
  final VoidCallback onTap;

  const _MarquePage({
    required this.spec,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Effet marque-page « papier » : quand actif, la couleur du
    // marque-page = couleur de la page (crème) → impression que cet
    // onglet est physiquement attaché à la page ouverte. Inactif :
    // vert sauge muted comme la couverture du carnet.
    final bg = isActive ? AppColors.carnetPaper : AppColors.carnetCoverMuted;
    final fg = isActive ? AppColors.primary : AppColors.primaryDark;
    // Tooltip pour l'accessibilité — long-press affiche le label,
    // sinon les utilisateurs découvrent chaque onglet en tapant.
    // Transform.translate (au lieu de margin négative interdite par
    // AnimatedContainer) pour faire dépasser le marque-page actif de
    // 4 px vers la page → effet papier continu.
    return Transform.translate(
      offset: Offset(isActive ? -4 : 0, 0),
      child: Tooltip(
        message: spec.label,
        preferBelow: false,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: isActive ? 48 : 44,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              // Pas d'ombre quand actif : l'effet « ce marque-page
              // est physiquement attaché à la page » n'admet pas
              // d'ombre projetée à gauche. Inactif : petite ombre
              // douce pour le relief.
              boxShadow: isActive
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 5,
                        offset: const Offset(2, 3),
                      ),
                    ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isActive ? spec.activeIcon : spec.icon,
                  key: ValueKey(isActive),
                  size: isActive ? 22 : 20,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerBody extends ConsumerWidget {
  final CarnetTab activeTab;
  const _DrawerBody({required this.activeTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;
    // DecoratedBox externe pour l'ombre projetée vers la droite,
    // Material interne pour fournir le contexte requis par InkWell,
    // Switch et compagnie + couleur de fond du papier.
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(6, 0),
          ),
        ],
      ),
      child: Material(
        color: AppColors.carnetPaper,
        child: Column(
        children: [
          // Header carnet — titre différent selon l'onglet actif
          // pour que l'utilisateur sache toujours sur quelle section
          // il est. Le label vient de l'ARB, indexé par enum.
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.carnetTitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tabTitle(activeTab, loc),
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(carnetUiProvider.notifier).close(),
                  icon: Icon(
                    PhosphorIcons.x(PhosphorIconsStyle.bold),
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Filet de séparation, vert très clair.
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.carnetLine,
          ),
          const SizedBox(height: 8),
          // Contenu de l'onglet actif.
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(activeTab),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
                  child: switch (activeTab) {
                    CarnetTab.harvests => const HarvestsTab(),
                    CarnetTab.seedlings => const SeedlingsTab(),
                    CarnetTab.journal => const JournalTab(),
                    CarnetTab.stats => const StatsTab(),
                    CarnetTab.settings => const SettingsTab(),
                    CarnetTab.about => const AboutTab(),
                  },
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
