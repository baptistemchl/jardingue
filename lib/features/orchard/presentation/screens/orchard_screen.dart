import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/orchard_providers.dart';
import '../../../../core/widgets/page_help.dart';
import '../widgets/fruit_tree_group_card.dart';
import '../widgets/fruit_tree_group_sheet.dart';
import '../widgets/fruit_tree_picker_sheet.dart';
import '../widgets/pheromone_trap_reminders_card.dart';
import '../widgets/user_tree_detail_sheet.dart';
import 'traps_screen.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

PageHelp _buildOrchardHelp(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  return PageHelp(
    pageId: 'orchard',
    title: loc.orchardTitle,
    emoji: '🌳',
    why: loc.pageHelpOrchardWhy,
    how: loc.pageHelpOrchardHow,
    when: loc.pageHelpOrchardWhen,
    where: loc.pageHelpOrchardWhere,
  );
}

/// Écran principal du verger - Liste des arbres de l'utilisateur
class OrchardScreen extends ConsumerStatefulWidget {
  const OrchardScreen({super.key});

  @override
  ConsumerState<OrchardScreen> createState() => _OrchardScreenState();
}

class _OrchardScreenState extends ConsumerState<OrchardScreen> {
  @override
  void initState() {
    super.initState();
    // Help affiché uniquement à la première visite (clé SharedPrefs
    // `page_help_dismissed_orchard`). Décalé post-frame pour laisser
    // le screen s'installer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowPageHelp(context, _buildOrchardHelp(context));
    });
  }

  @override
  Widget build(BuildContext context) {
    final userTreesAsync = ref.watch(userFruitTreesNotifierProvider);
    final groupsAsync = ref.watch(groupedUserFruitTreesProvider);
    // Le FAB n'est utile que lorsqu'il y a déjà des arbres : sinon
    // l'empty-state propose déjà un CTA bien plus explicite (« Ajouter
    // un arbre » centré, illustré). Afficher les deux ensemble fait
    // doublon visuel.
    final hasTrees = userTreesAsync.maybeWhen(
      data: (trees) => trees.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      // On utilise une Stack pour superposer le contenu et le bouton personnalisé
      body: Stack(
        children: [
          // 1. Le contenu défilant (SafeArea + CustomScrollView)
          Positioned.fill(
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.screenPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  PhosphorIcons.arrowLeft(
                                    PhosphorIconsStyle.bold,
                                  ),
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    '🌳',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.orchardTitle,
                                      style: AppTypography.titleLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    userTreesAsync.when(
                                      data: (trees) => Text(
                                        trees.isEmpty
                                            ? AppLocalizations.of(context)!.orchardNoTrees
                                            : AppLocalizations.of(context)!.orchardTreeCount(trees.length),
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      loading: () => Text(
                                        AppLocalizations.of(context)!.loading,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      error: (_, _) => const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                              PageHelpButton(help: _buildOrchardHelp(context)),
                              const SizedBox(width: 4),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),

                  // Card rappels pieges a pheromones (full)
                  SliverPadding(
                    padding: AppSpacing.horizontalPadding,
                    sliver: const SliverToBoxAdapter(
                      child: PheromoneTrapRemindersCard(compact: false),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Bouton "Mes pieges" — acces a la gestion CRUD complete.
                  // Visible meme s'il n'y a aucun rappel a renouveler, pour
                  // permettre l'ajout du premier piege.
                  if (hasTrees)
                    SliverPadding(
                      padding: AppSpacing.horizontalPadding,
                      sliver: SliverToBoxAdapter(
                        child: _MyTrapsButton(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TrapsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (hasTrees)
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Liste des groupes (arbres seuls ou groupés par
                  // espèce + variété + type de plantation)
                  groupsAsync.when(
                    data: (groups) {
                      if (groups.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _EmptyState(
                            onAddTap: () => _showTreePicker(context),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: AppSpacing.horizontalPadding,
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final group = groups[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FruitTreeGroupCard(
                                group: group,
                                onTap: () => _openGroup(context, group),
                                onLongPress: group.isGroup
                                    ? () => _openGroup(
                                          context,
                                          group,
                                          startInSelection: true,
                                        )
                                    : null,
                              ),
                            );
                          }, childCount: groups.length),
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())),
                        ),
                      ),
                    ),
                  ),

                  // Espace pour le FAB (Augmenté à 160 car le FAB est plus haut)
                  const SliverToBoxAdapter(child: SizedBox(height: 160)),
                ],
              ),
            ),
          ),

          // 2. Le bouton flottant positionné manuellement — visible
          //    uniquement quand il y a au moins un arbre, pour ne pas
          //    faire doublon avec le CTA central de l'empty state.
          if (hasTrees)
            Positioned(
              bottom: 120,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _showTreePicker(context),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
                label: Text(AppLocalizations.of(context)!.add),
                elevation: 4,
              ),
            ),
        ],
      ),
    );
  }

  void _showTreePicker(BuildContext context) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FruitTreePickerSheet(),
    );
  }

  void _openGroup(
    BuildContext context,
    FruitTreeGroup group, {
    bool startInSelection = false,
  }) {
    // Si le "groupe" n'a qu'un seul arbre, on saute l'écran intermédiaire
    // et on ouvre directement la fiche de l'arbre — cohérent avec le
    // comportement historique d'un verger sans groupes.
    if (group.isSingle && !startInSelection) {
      _showTreeDetail(context, group.representative);
      return;
    }
    FruitTreeGroupSheet.show(
      context,
      group: group,
      startInSelection: startInSelection,
    );
  }

  void _showTreeDetail(BuildContext context, UserFruitTreeWithDetails tree) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserTreeDetailSheet(tree: tree),
    );
  }
}

class _MyTrapsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MyTrapsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                PhosphorIcons.bug(PhosphorIconsStyle.duotone),
                color: const Color(0xFFFB8C00),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.myTrapsAction,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;

  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppSpacing.horizontalPadding,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('🌳', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.orchardEmptyTitle,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.orchardEmptySubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddTap,
            icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
            label: Text(AppLocalizations.of(context)!.orchardAddTree),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
