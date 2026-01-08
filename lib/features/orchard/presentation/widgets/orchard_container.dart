import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/orchard_providers.dart';
import '../screens/orchard_screen.dart';
import 'fruit_tree_picker_sheet.dart';

/// Widget container pour afficher le verger sur l'écran d'accueil
class OrchardContainer extends ConsumerWidget {
  const OrchardContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treesAsync = ref.watch(userFruitTreesNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🌳', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon verger',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    treesAsync.when(
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
                      error: (_, __) => Text(
                        'Erreur',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _navigateToOrchard(context),
                icon: Icon(
                  PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Contenu
          treesAsync.when(
            data: (trees) {
              if (trees.isEmpty) {
                return _EmptyState(onAddTap: () => _showTreePicker(context));
              }

              // Affiche les 3 premiers arbres
              final displayTrees = trees.take(3).toList();
              final remainingCount = trees.length - 3;

              return Column(
                children: [
                  ...displayTrees.map(
                    (tree) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MiniTreeCard(tree: tree),
                    ),
                  ),
                  if (remainingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+$remainingCount autre${remainingCount > 1 ? 's' : ''}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Voir tout',
                          icon: PhosphorIcons.eye(PhosphorIconsStyle.bold),
                          onTap: () => _navigateToOrchard(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: 'Ajouter',
                          icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                          isPrimary: true,
                          onTap: () => _showTreePicker(context),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Erreur: $e',
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToOrchard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrchardScreen()),
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
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;

  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Commencez à gérer vos arbres fruitiers',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onAddTap,
          icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 16),
          label: const Text('Ajouter un arbre'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniTreeCard extends StatelessWidget {
  final UserFruitTreeWithDetails tree;

  const _MiniTreeCard({required this.tree});

  @override
  Widget build(BuildContext context) {
    final healthColor = switch (tree.healthStatus) {
      'good' => AppColors.success,
      'warning' => AppColors.warning,
      'poor' => AppColors.error,
      _ => AppColors.success,
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(tree.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tree.name,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tree.variety != null)
                  Text(
                    tree.variety!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: healthColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isPrimary ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
