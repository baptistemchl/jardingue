import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/weather/weather_analysis/garden_analysis.dart';
import '../../../../core/theme/app_typography.dart';

class WeatherAnalysisRow extends StatelessWidget {
  final String label;
  final String value;
  final String ideal;
  final GardenStatus status;

  const WeatherAnalysisRow({
    super.key,
    required this.label,
    required this.value,
    required this.ideal,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case GardenStatus.good:
        statusColor = AppColors.success;
        statusIcon = PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
        break;
      case GardenStatus.warning:
        statusColor = AppColors.warning;
        statusIcon = PhosphorIcons.warning(PhosphorIconsStyle.fill);
        break;
      case GardenStatus.bad:
        statusColor = AppColors.error;
        statusIcon = PhosphorIcons.xCircle(PhosphorIconsStyle.fill);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTypography.bodySmall)),
          Text(value, style: AppTypography.labelMedium),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              ideal,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
