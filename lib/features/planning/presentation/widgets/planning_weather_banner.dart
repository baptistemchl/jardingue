import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/theme/app_typography.dart';

class PlanningWeatherBanner extends ConsumerWidget {
  const PlanningWeatherBanner({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final weather = ref.watch(
      weatherDataProvider.select(
        (v) => v.valueOrNull,
      ),
    );

    if (weather == null) {
      return _Banner(
        color: AppColors.warning,
        icon: '⚠️',
        title: 'Météo indisponible',
        subtitle: 'Certaines recommandations '
            'peuvent manquer',
      );
    }

    final condition = weather.current.condition;
    final color = condition.isGood
        ? AppColors.success
        : AppColors.warning;

    return _Banner(
      color: color,
      icon: condition.icon,
      title:
          '${weather.current.temperatureDisplay}'
          ' — ${condition.label}',
      subtitle:
          weather.gardeningAdvice.mainAdvice,
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
