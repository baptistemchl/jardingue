import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/orchard_providers.dart';
import '../widgets/user_fruit_tree_card.dart';
import '../widgets/fruit_tree_picker_sheet.dart';
import '../widgets/user_tree_detail_sheet.dart';

/// Écran principal du verger - Liste des arbres de l'utilisateur
class OrchardScreen extends ConsumerWidget {
  const OrchardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTreesAsync = ref.watch(userFruitTreesNotifierProvider);

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
                                      'Mon verger',
                                      style: AppTypography.titleLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    userTreesAsync.when(
                                      data: (trees) => Text(
                                        trees.isEmpty
                                            ? 'Aucun arbre'
                                            : '${trees.length} arbre${trees.length > 1 ? 's' : ''}',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      loading: () => Text(
                                        'Chargement...',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      error: (_, __) => const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),

                  // Liste des arbres
                  userTreesAsync.when(
                    data: (trees) {
                      if (trees.isEmpty) {
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
                            final tree = trees[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: UserFruitTreeCard(
                                tree: tree,
                                onTap: () => _showTreeDetail(context, tree),
                              ),
                            );
                          }, childCount: trees.length),
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
                          child: Text('Erreur: $e'),
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

          // 2. Le bouton flottant positionné manuellement
          Positioned(
            bottom: 120, // Rehaussé à 120px du bas
            right: 16, // Marge standard à droite
            child: FloatingActionButton.extended(
              onPressed: () => _showTreePicker(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
              label: const Text('Ajouter'),
              elevation: 4,
            ),
          ),
        ],
      ),
      // On retire le floatingActionButton du Scaffold car il est maintenant dans la Stack
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
            'Votre verger est vide',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos premiers arbres fruitiers\npour commencer à les suivre',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddTap,
            icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
            label: const Text('Ajouter un arbre'),
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
