import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_decoration.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/database/database.dart';

/// Écran de la liste des plantes
class PlantsScreen extends ConsumerStatefulWidget {
  const PlantsScreen({super.key});

  @override
  ConsumerState<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends ConsumerState<PlantsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  // Pagination
  static const int _pageSize = 20;
  int _displayedCount = _pageSize;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final plantsAsync = ref.read(filteredPlantsProvider);
    plantsAsync.whenData((plants) {
      if (_displayedCount < plants.length) {
        setState(() => _isLoadingMore = true);

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _displayedCount = (_displayedCount + _pageSize).clamp(
                0,
                plants.length,
              );
              _isLoadingMore = false;
            });
          }
        });
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(plantsFilterProvider.notifier).setSearchQuery(query);
      setState(() => _displayedCount = _pageSize);
    });
  }

  void _resetPagination() {
    setState(() => _displayedCount = _pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(filteredPlantsProvider);
    final filters = ref.watch(plantsFilterProvider);
    final totalCount = ref.watch(totalPlantsCountProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Plantes',
                            style: AppTypography.displayMedium,
                          ),
                        ),
                        totalCount.when(
                          data: (count) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: AppSpacing.borderRadiusFull,
                            ),
                            child: Text(
                              '$count variétés',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Découvrez et gérez vos variétés',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // Barre de recherche
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.horizontalPadding,
                child: _SearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // Filtres par catégorie
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: AppSpacing.horizontalPadding,
                    child: Text(
                      'Catégorie',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: AppSpacing.horizontalPadding,
                      itemCount: PlantCategory.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = PlantCategory.values[index];
                        final isSelected = filters.category == category;
                        return _CategoryChip(
                          emoji: category.emoji,
                          label: category.label,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(plantsFilterProvider.notifier)
                                .setCategory(category);
                            _resetPagination();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

            // Filtres par exposition
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: AppSpacing.horizontalPadding,
                    child: Text(
                      'Exposition',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: AppSpacing.horizontalPadding,
                      itemCount: PlantSunFilter.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = PlantSunFilter.values[index];
                        final isSelected = filters.sunFilter == filter;
                        return _FilterChip(
                          label: filter.label,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(plantsFilterProvider.notifier)
                                .setSunFilter(filter);
                            _resetPagination();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // Résultats info + bouton clear
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.horizontalPadding,
                child: plantsAsync.when(
                  data: (plants) {
                    if (!filters.hasActiveFilters)
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        children: [
                          Text(
                            '${plants.length} résultat${plants.length > 1 ? 's' : ''}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              ref
                                  .read(plantsFilterProvider.notifier)
                                  .clearFilters();
                              _resetPagination();
                            },
                            child: Text(
                              'Effacer les filtres',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Liste des plantes
            plantsAsync.when(
              data: (plants) {
                if (plants.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(
                      hasFilters: filters.hasActiveFilters,
                      onClearFilters: () {
                        _searchController.clear();
                        ref.read(plantsFilterProvider.notifier).clearFilters();
                        _resetPagination();
                      },
                    ),
                  );
                }

                final displayedPlants = plants.take(_displayedCount).toList();
                final hasMore = _displayedCount < plants.length;

                return SliverPadding(
                  padding: AppSpacing.horizontalPadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == displayedPlants.length) {
                        return _LoadingIndicator(isLoading: _isLoadingMore);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _PlantCard(plant: displayedPlants[index]),
                      );
                    }, childCount: displayedPlants.length + (hasMore ? 1 : 0)),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: AppSpacing.horizontalPadding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: _PlantCardSkeleton(),
                    ),
                    childCount: 6,
                  ),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorState(
                  error: error.toString(),
                  onRetry: () => ref.invalidate(filteredPlantsProvider),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

// ============================================
// WIDGETS
// ============================================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher une plante...',
          prefixIcon: Icon(
            PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
            color: AppColors.textTertiary,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    PhosphorIcons.x(PhosphorIconsStyle.bold),
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final Plant plant;

  const _PlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => _showPlantDetail(context, plant),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Center(
              child: Text(plant.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.commonName,
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        plant.categoryDisplayLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(plant.sunIcon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      plant.sunLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
            color: AppColors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showPlantDetail(BuildContext context, Plant plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlantDetailSheet(plant: plant),
    );
  }
}

class _PlantCardSkeleton extends StatelessWidget {
  const _PlantCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final bool isLoading;

  const _LoadingIndicator({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: AnimatedOpacity(
          opacity: isLoading ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyState({required this.hasFilters, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasFilters ? '🔍' : '🌱',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Aucun résultat' : 'Aucune plante',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Essayez de modifier vos critères'
                  : 'La base de données est vide',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Effacer les filtres'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold)),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// DETAIL SHEET
// ============================================

class _PlantDetailSheet extends ConsumerWidget {
  final Plant plant;

  const _PlantDetailSheet({required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionsAsync = ref.watch(plantCompanionsProvider(plant.id));
    final antagonistsAsync = ref.watch(plantAntagonistsProvider(plant.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppSpacing.borderRadiusLg,
                    ),
                    child: Center(
                      child: Text(
                        plant.emoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plant.commonName, style: AppTypography.titleLarge),
                        if (plant.latinName != null)
                          Text(
                            plant.latinName!,
                            style: AppTypography.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${plant.category.emoji} ${plant.categoryDisplayLabel}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Infos rapides
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: plant.sunIcon, label: plant.sunLabel),
                  if (plant.spacingBetweenPlants != null)
                    _InfoChip(
                      icon: '📏',
                      label: '${plant.spacingBetweenPlants} cm',
                    ),
                  if (plant.plantingMinTempC != null)
                    _InfoChip(
                      icon: '🌡️',
                      label: '≥ ${plant.plantingMinTempC}°C',
                    ),
                  if (plant.watering != null)
                    _InfoChip(icon: '💧', label: 'Arrosage régulier'),
                ],
              ),
              const SizedBox(height: 24),

              // Périodes
              if (plant.sowingOpenGroundPeriod != null ||
                  plant.transplantingPeriod != null ||
                  plant.harvestPeriod != null) ...[
                _SectionTitle(title: '📅 Périodes'),
                if (plant.sowingOpenGroundPeriod != null)
                  _PeriodRow(
                    label: 'Semis pleine terre',
                    value: plant.sowingOpenGroundPeriod!,
                  ),
                if (plant.sowingUnderCoverPeriod != null)
                  _PeriodRow(
                    label: 'Semis sous abri',
                    value: plant.sowingUnderCoverPeriod!,
                  ),
                if (plant.transplantingPeriod != null)
                  _PeriodRow(
                    label: 'Repiquage',
                    value: plant.transplantingPeriod!,
                  ),
                if (plant.harvestPeriod != null)
                  _PeriodRow(label: 'Récolte', value: plant.harvestPeriod!),
                const SizedBox(height: 16),
              ],

              if (plant.plantingAdvice != null) ...[
                _SectionTitle(title: '🌱 Plantation'),
                Text(plant.plantingAdvice!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              if (plant.careAdvice != null) ...[
                _SectionTitle(title: '🧑‍🌾 Entretien'),
                Text(plant.careAdvice!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              if (plant.redFlags != null) ...[
                _SectionTitle(title: '⚠️ Points d\'attention'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(plant.redFlags!, style: AppTypography.bodySmall),
                ),
                const SizedBox(height: 16),
              ],

              // Compagnons
              companionsAsync.when(
                data: (companions) {
                  if (companions.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: '✅ Bonnes associations'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: companions
                            .map(
                              (c) => _PlantChip(
                                emoji: c.emoji,
                                name: c.commonName,
                                color: AppColors.success,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Antagonistes
              antagonistsAsync.when(
                data: (antagonists) {
                  if (antagonists.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: '❌ À éviter'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: antagonists
                            .map(
                              (a) => _PlantChip(
                                emoji: a.emoji,
                                name: a.commonName,
                                color: AppColors.error,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.titleSmall),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  final String label;
  final String value;

  const _PeriodRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _PlantChip extends StatelessWidget {
  final String emoji;
  final String name;
  final Color color;

  const _PlantChip({
    required this.emoji,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(name, style: AppTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
