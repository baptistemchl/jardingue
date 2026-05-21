import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/carnet_tab.dart';
import '../providers/carnet_ui_providers.dart';
import 'tabs/harvests_tab.dart';
import 'tabs/journal_tab.dart';
import 'tabs/seedlings_tab.dart';
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

    // Position du bord gauche du drawer (sans les tabs qui dépassent).
    // Fermé : tout est hors écran à droite.
    // Ouvert : aligné au bord droit + drawerWidth de large.
    final closedX = size.width;
    final openX = size.width - drawerWidth;
    final targetX = ui.isOpen ? openX : closedX;
    final currentX = (targetX + _dragOffset).clamp(openX, closedX);
    final progress = ((closedX - currentX) / drawerWidth).clamp(0.0, 1.0);

    return Stack(
      children: [
        // Backdrop sombre + blur
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

        // Drawer + marque-pages qui dépassent
        AnimatedPositioned(
          duration: _dragOffset == 0
              ? const Duration(milliseconds: 320)
              : Duration.zero,
          curve: Curves.easeOutCubic,
          left: currentX - _tabWidth,
          top: 0,
          bottom: 0,
          width: drawerWidth + _tabWidth,
          child: GestureDetector(
            onHorizontalDragUpdate: (d) {
              setState(() {
                _dragOffset = (_dragOffset + d.delta.dx).clamp(0.0, drawerWidth);
              });
            },
            onHorizontalDragEnd: (d) {
              final v = d.velocity.pixelsPerSecond.dx;
              final shouldClose =
                  v > 600 || _dragOffset > drawerWidth * 0.35;
              setState(() => _dragOffset = 0);
              if (shouldClose) {
                ref.read(carnetUiProvider.notifier).close();
              }
            },
            child: Row(
              children: [
                _TabStrip(activeTab: ui.activeTab),
                Expanded(child: _DrawerBody(activeTab: ui.activeTab)),
              ],
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
      _TabSpec(CarnetTab.harvests, loc.carnetTabHarvests,
          PhosphorIcons.basket(PhosphorIconsStyle.regular)),
      _TabSpec(CarnetTab.seedlings, loc.carnetTabSeedlings,
          PhosphorIcons.plant(PhosphorIconsStyle.regular)),
      _TabSpec(CarnetTab.journal, loc.carnetTabJournal,
          PhosphorIcons.notebook(PhosphorIconsStyle.regular)),
      _TabSpec(CarnetTab.stats, loc.carnetTabStats,
          PhosphorIcons.chartBar(PhosphorIconsStyle.regular)),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 72, bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: entries.map((e) {
          final isActive = e.tab == activeTab;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
  const _TabSpec(this.tab, this.label, this.icon);
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
    final bg = isActive ? AppColors.kraftTab : AppColors.kraftTabLight;
    final fg = isActive ? Colors.white : AppColors.kraftInk;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 44,
        height: 90,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.18 : 0.08),
              blurRadius: isActive ? 10 : 4,
              offset: const Offset(-2, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(spec.icon, size: 18, color: fg),
            const SizedBox(height: 6),
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                spec.label,
                style: AppTypography.caption.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.kraftBackground,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(-6, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header carnet — barre de titre kraft.
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    loc.carnetTitle,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.kraftInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(carnetUiProvider.notifier).close(),
                  icon: Icon(
                    PhosphorIcons.x(PhosphorIconsStyle.bold),
                    color: AppColors.kraftInk,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Filet de séparation papier vergé.
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.kraftLine.withValues(alpha: 0.4),
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
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
