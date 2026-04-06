import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/services/database/database.dart';

// ============================================
// PLANT DETAIL BOTTOM SHEET (COMPLET)
// ============================================

void showPlantDetail(BuildContext context, Plant plant) {
  showModalBottomSheet(
    useRootNavigator: true,
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: PlantDetailSheet(plant: plant),
    ),
  );
}

class PlantDetailSheet extends ConsumerWidget {
  final Plant plant;

  const PlantDetailSheet({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionsAsync = ref.watch(plantCompanionsProvider(plant.id));
    final antagonistsAsync = ref.watch(plantAntagonistsProvider(plant.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
              const SizedBox(height: 20),

              // Calendrier annuel
              _PlantYearCalendar(plant: plant),
              const SizedBox(height: 20),

              // Infos rapides
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: plant.sunIcon, label: plant.sunLabel),
                  if (plant.spacingBetweenPlants != null)
                    _InfoChip(
                      icon: '📏',
                      label: '${plant.spacingBetweenPlants} cm entre plants',
                    ),
                  if (plant.spacingBetweenRows != null)
                    _InfoChip(
                      icon: '↔️',
                      label: '${plant.spacingBetweenRows} cm entre rangs',
                    ),
                  if (plant.plantingDepthCm != null)
                    _InfoChip(
                      icon: '⬇️',
                      label: '${plant.plantingDepthCm} cm profondeur',
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

              // Périodes détaillées
              if (plant.sowingOpenGroundPeriod != null ||
                  plant.sowingUnderCoverPeriod != null ||
                  plant.transplantingPeriod != null ||
                  plant.harvestPeriod != null) ...[
                _DetailSectionTitle(title: '📅 Périodes'),
                if (plant.sowingUnderCoverPeriod != null)
                  _PeriodInfo(
                    type: GardenActivityType.sowingUnderCover,
                    value: plant.sowingUnderCoverPeriod!,
                  ),
                if (plant.sowingOpenGroundPeriod != null)
                  _PeriodInfo(
                    type: GardenActivityType.sowingOpenGround,
                    value: plant.sowingOpenGroundPeriod!,
                  ),
                if (plant.transplantingPeriod != null)
                  _PeriodInfo(
                    type: GardenActivityType.planting,
                    value: plant.transplantingPeriod!,
                  ),
                if (plant.harvestPeriod != null)
                  _PeriodInfo(
                    type: GardenActivityType.harvest,
                    value: plant.harvestPeriod!,
                  ),
                const SizedBox(height: 16),
              ],

              // Conseils de semis
              if (plant.sowingRecommendation != null) ...[
                _DetailSectionTitle(title: '🌱 Conseils de semis'),
                _DetailCard(
                  color: GardenActivityType.sowingOpenGround.color,
                  child: Text(
                    plant.sowingRecommendation!,
                    style: AppTypography.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Conseils de plantation
              if (plant.plantingAdvice != null) ...[
                _DetailSectionTitle(title: '🪴 Plantation'),
                Text(plant.plantingAdvice!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              // Conditions météo
              if (plant.plantingWeatherConditions != null) ...[
                _DetailSectionTitle(title: '🌤️ Conditions de plantation'),
                _DetailCard(
                  color: AppColors.info,
                  child: Text(
                    plant.plantingWeatherConditions!,
                    style: AppTypography.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Conseils d'entretien
              if (plant.careAdvice != null) ...[
                _DetailSectionTitle(title: '🧑‍🌾 Entretien'),
                Text(plant.careAdvice!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              // Arrosage détaillé
              if (plant.watering != null) ...[
                _DetailSectionTitle(title: '💧 Arrosage'),
                Text(plant.watering!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              // Sol
              if (plant.soilType != null ||
                  plant.soilMoisturePreference != null ||
                  plant.soilTreatmentAdvice != null) ...[
                _DetailSectionTitle(title: '🪨 Sol'),
                if (plant.soilType != null)
                  _DetailRow(label: 'Type de sol', value: plant.soilType!),
                if (plant.soilMoisturePreference != null)
                  _DetailRow(
                    label: 'Humidité',
                    value: plant.soilMoisturePreference!,
                  ),
                if (plant.soilTreatmentAdvice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      plant.soilTreatmentAdvice!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // Zone de culture
              if (plant.growingZone != null) ...[
                _DetailSectionTitle(title: '📍 Zone de culture'),
                Text(plant.growingZone!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
              ],

              // Culture sous serre
              if (plant.cultivationGreenhouse != null) ...[
                _DetailSectionTitle(title: '🏠 Culture sous abri'),
                _DetailCard(
                  color: GardenActivityType.sowingUnderCover.color,
                  child: Text(
                    plant.cultivationGreenhouse!,
                    style: AppTypography.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Points d'attention
              if (plant.redFlags != null) ...[
                _DetailSectionTitle(title: '⚠️ Points d\'attention'),
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

              // Nuisibles
              if (plant.mainDestroyers != null) ...[
                _DetailSectionTitle(title: '🐛 Nuisibles & maladies'),
                _DestroyersList(destroyersJson: plant.mainDestroyers!),
                const SizedBox(height: 16),
              ],

              // Compagnons
              companionsAsync.when(
                data: (companions) {
                  if (companions.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailSectionTitle(title: '✅ Bonnes associations'),
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
                      _DetailSectionTitle(title: '❌ À éviter'),
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

// ============================================
// UTILITY WIDGETS (private)
// ============================================

class _DetailSectionTitle extends StatelessWidget {
  final String title;

  const _DetailSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.titleSmall),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Color color;
  final Widget child;

  const _DetailCard({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

class _DestroyersList extends StatelessWidget {
  final String destroyersJson;

  const _DestroyersList({required this.destroyersJson});

  @override
  Widget build(BuildContext context) {
    List<String> destroyers = [];
    try {
      final decoded = json.decode(destroyersJson);
      if (decoded is List) {
        destroyers = decoded.cast<String>();
      }
    } catch (_) {
      // Si ce n'est pas du JSON, c'est peut-être une string simple
      destroyers = [destroyersJson];
    }

    if (destroyers.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: destroyers
          .map(
            (d) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🐛', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    d,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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

class _PlantYearCalendar extends StatelessWidget {
  final Plant plant;

  const _PlantYearCalendar({required this.plant});

  @override
  Widget build(BuildContext context) {
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    const monthsFull = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Légende
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _SmallLegend(
                color: GardenActivityType.sowingUnderCover.color,
                label: 'Semis abri',
              ),
              _SmallLegend(
                color: GardenActivityType.sowingOpenGround.color,
                label: 'Semis',
              ),
              _SmallLegend(
                color: GardenActivityType.planting.color,
                label: 'Plantation',
              ),
              _SmallLegend(
                color: GardenActivityType.harvest.color,
                label: 'Récolte',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grille des mois
          Row(
            children: List.generate(12, (index) {
              final monthName = monthsFull[index];
              final activities = _getMonthActivities(plant, monthName);

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      months[index],
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: activities.isEmpty
                            ? AppColors.border.withValues(alpha: 0.3)
                            : null,
                        gradient: activities.isNotEmpty
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: activities.length == 1
                                    ? [
                                        activities.first.color,
                                        activities.first.color,
                                      ]
                                    : activities.map((a) => a.color).toList(),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  List<GardenActivityType> _getMonthActivities(Plant plant, String monthName) {
    final activities = <GardenActivityType>[];

    final sowingData = _parseCalendar(plant.sowingCalendar);
    if (sowingData != null) {
      final value = sowingData[monthName];
      if (value != null && value.toString().startsWith('Oui')) {
        if (value.toString().contains('sous abri')) {
          activities.add(GardenActivityType.sowingUnderCover);
        } else {
          activities.add(GardenActivityType.sowingOpenGround);
        }
      }
    }

    final plantingData = _parseCalendar(plant.plantingCalendar);
    if (plantingData != null) {
      final value = plantingData[monthName];
      if (value != null && value.toString().startsWith('Oui')) {
        activities.add(GardenActivityType.planting);
      }
    }

    final harvestData = _parseCalendar(plant.harvestCalendar);
    if (harvestData != null) {
      final value = harvestData[monthName];
      if (value != null && value.toString().startsWith('Oui')) {
        activities.add(GardenActivityType.harvest);
      }
    }

    return activities;
  }

  Map<String, dynamic>? _parseCalendar(String? calendarJson) {
    if (calendarJson == null) return null;
    try {
      final data = json.decode(calendarJson) as Map<String, dynamic>;
      return data['monthly_period'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}

class _SmallLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _SmallLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _PeriodInfo extends StatelessWidget {
  final GardenActivityType type;
  final String value;

  const _PeriodInfo({required this.type, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: type.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(type.emoji, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: AppTypography.labelSmall.copyWith(color: type.color),
                ),
                Text(value, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
