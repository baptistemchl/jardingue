import 'dart:async';
import 'dart:convert';
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
import '../../../../core/widgets/decorative_background.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

/// Écran de la liste des plantes
class PlantsScreen extends ConsumerStatefulWidget {
  const PlantsScreen({super.key});

  @override
  ConsumerState<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends ConsumerState<PlantsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  // Pagination
  static const int _pageSize = 20;
  int _displayedCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final plantsAsync = ref.read(filteredPlantsProvider);
    plantsAsync.whenData((plants) {
      if (_displayedCount >= plants.length) return;
      setState(() {
        _displayedCount = (_displayedCount + _pageSize)
            .clamp(0, plants.length);
      });
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

  void _unfocus() {
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(filteredPlantsProvider);
    final filters = ref.watch(plantsFilterProvider);
    final totalCount = ref.watch(totalPlantsCountProvider);

    return GestureDetector(
      onTap: _unfocus,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: Stack(
          children: [
            const DecorativeBackground(),

            // Contenu
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                                  AppLocalizations.of(context)!.plants,
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
                                    AppLocalizations.of(context)!.varietiesCount(count),
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
                            AppLocalizations.of(context)!.discoverVarieties,
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
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        onClear: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),

                  // Filtres par catégorie
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: AppSpacing.horizontalPadding,
                          child: Text(
                            AppLocalizations.of(context)!.categoryLabel,
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final category = PlantCategory.values[index];
                              final isSelected = filters.category == category;
                              return _CategoryChip(
                                emoji: category.emoji,
                                label: category.label,
                                isSelected: isSelected,
                                onTap: () {
                                  _unfocus();
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

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),

                  // Filtres par exposition
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: AppSpacing.horizontalPadding,
                          child: Text(
                            AppLocalizations.of(context)!.exposureLabel,
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final filter = PlantSunFilter.values[index];
                              final isSelected = filters.sunFilter == filter;
                              return _FilterChip(
                                label: filter.label,
                                isSelected: isSelected,
                                onTap: () {
                                  _unfocus();
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

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),

                  // Résultats info + bouton clear
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.horizontalPadding,
                      child: plantsAsync.when(
                        data: (plants) {
                          if (!filters.hasActiveFilters) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.resultsCount(plants.length),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    _unfocus();
                                    _searchController.clear();
                                    ref
                                        .read(plantsFilterProvider.notifier)
                                        .clearFilters();
                                    _resetPagination();
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.clearFilters,
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
                              _unfocus();
                              _searchController.clear();
                              ref
                                  .read(plantsFilterProvider.notifier)
                                  .clearFilters();
                              _resetPagination();
                            },
                          ),
                        );
                      }

                      final displayedPlants = plants
                          .take(_displayedCount)
                          .toList();
                      final hasMore = _displayedCount < plants.length;

                      return SliverPadding(
                        padding: AppSpacing.horizontalPadding,
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == displayedPlants.length) {
                                return _LoadingIndicator(
                                  isLoading: false,
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: _PlantCard(
                                  plant: displayedPlants[index],
                                  onTap: () {
                                    _unfocus();
                                    _showPlantDetail(
                                      context,
                                      displayedPlants[index],
                                    );
                                  },
                                ),
                              );
                            },
                            childCount:
                                displayedPlants.length + (hasMore ? 1 : 0),
                          ),
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
          ],
        ),
      ),
    );
  }

  void _showPlantDetail(BuildContext context, Plant plant) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlantDetailSheet(plant: plant),
    );
  }
}

// ============================================
// WIDGETS
// ============================================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
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
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchPlant,
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
  final VoidCallback onTap;

  const _PlantCard({required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
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
              hasFilters ? AppLocalizations.of(context)!.noResults : AppLocalizations.of(context)!.noPlants,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? AppLocalizations.of(context)!.tryModifyingCriteria
                  : AppLocalizations.of(context)!.databaseEmpty,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onClearFilters,
                child: Text(AppLocalizations.of(context)!.clearFilters),
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
            Text(AppLocalizations.of(context)!.loadingError, style: AppTypography.titleMedium),
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
              label: Text(AppLocalizations.of(context)!.retry),
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
                    _InfoChip(icon: '💧', label: AppLocalizations.of(context)!.regularWatering),
                ],
              ),
              const SizedBox(height: 24),

              // Périodes
              if (plant.sowingOpenGroundPeriod != null ||
                  plant.transplantingPeriod != null ||
                  plant.harvestPeriod != null) ...[
                _SectionTitle(title: AppLocalizations.of(context)!.periodsSection),
                if (plant.sowingOpenGroundPeriod != null)
                  _PeriodRow(
                    label: AppLocalizations.of(context)!.sowingOpenGround,
                    value: plant.sowingOpenGroundPeriod!,
                  ),
                if (plant.sowingUnderCoverPeriod != null)
                  _PeriodRow(
                    label: AppLocalizations.of(context)!.sowingUnderCover,
                    value: plant.sowingUnderCoverPeriod!,
                  ),
                if (plant.transplantingPeriod != null)
                  _PeriodRow(
                    label: AppLocalizations.of(context)!.transplanting,
                    value: plant.transplantingPeriod!,
                  ),
                if (plant.harvestPeriod != null)
                  _PeriodRow(label: AppLocalizations.of(context)!.harvestLabel, value: plant.harvestPeriod!),
                const SizedBox(height: 16),
              ],

              if (plant.plantingAdvice != null) ...[
                _SectionTitle(title: AppLocalizations.of(context)!.plantingSection),
                Text(plant.plantingAdvice!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              if (plant.careAdvice != null) ...[
                _SectionTitle(title: AppLocalizations.of(context)!.careSection),
                Text(plant.careAdvice!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              if (plant.redFlags != null) ...[
                _SectionTitle(title: AppLocalizations.of(context)!.attentionSection),
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

              // Adaptation climatique
              if (plant.climateAdaptation != null) ...[
                _SectionTitle(title: '🌍 Adaptation climatique'),
                _ClimateAdaptationSection(
                  climateJson: plant.climateAdaptation!,
                ),
                const SizedBox(height: 16),
              ],

              // Toxicité
              if (plant.toxicity != null) ...[
                _SectionTitle(title: '☠️ Toxicité'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plant.toxicity!,
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Conseils pratiques
              if (plant.practicalTips != null) ...[
                _SectionTitle(title: '💡 Conseils pratiques'),
                Text(plant.practicalTips!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              // Compagnons
              companionsAsync.when(
                data: (companions) {
                  if (companions.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: AppLocalizations.of(context)!.goodCompanions),
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
                      _SectionTitle(title: AppLocalizations.of(context)!.badCompanions),
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

              const SizedBox(height: 80),
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

class _ClimateAdaptationSection extends StatelessWidget {
  final String climateJson;

  const _ClimateAdaptationSection({required this.climateJson});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> climate = {};
    try {
      climate = json.decode(climateJson) as Map<String, dynamic>;
    } catch (_) {
      return const SizedBox.shrink();
    }

    const regions = [
      ('cold', '❄️', 'Région froide'),
      ('temperate', '🌤️', 'Région tempérée'),
      ('hot', '☀️', 'Région chaude'),
    ];

    return Column(
      children: [
        for (final (key, emoji, label) in regions)
          if (climate[key] != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          climate[key].toString(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

