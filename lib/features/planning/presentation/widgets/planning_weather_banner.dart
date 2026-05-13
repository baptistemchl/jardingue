import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis_ui.dart';
import '../../../../core/theme/app_typography.dart';

class PlanningWeatherBanner extends ConsumerWidget {
  const PlanningWeatherBanner({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final analysisAsync = ref.watch(gardenAnalysisProvider);
    final analysis = analysisAsync.value;

    if (analysis == null) {
      return _Banner(
        color: AppColors.warning,
        icon: '⚠️',
        title: 'Météo indisponible',
        subtitle: 'Certaines recommandations '
            'peuvent manquer',
      );
    }

    return _Banner(
      color: analysis.severity.color,
      icon: analysis.lunar.dayType.emoji,
      title: analysis.headline,
      subtitle: analysis.summary,
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final String icon;
  final String title;
  final String subtitle;

  const _Banner({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge
                      .copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption
                      .copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
