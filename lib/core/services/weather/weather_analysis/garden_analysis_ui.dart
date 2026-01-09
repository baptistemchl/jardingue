import 'package:Jardingue/core/services/weather/weather_analysis/garden_analysis.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

extension GardenSeverityUi on GardenSeverity {
  Color get color => switch (this) {
    GardenSeverity.critical => AppColors.error,
    GardenSeverity.hard => AppColors.warning,
    GardenSeverity.ok => AppColors.warning,
    GardenSeverity.good => AppColors.success,
    GardenSeverity.great => AppColors.success,
  };
}

extension GardenStatusUi on GardenStatus {
  Color get color => switch (this) {
    GardenStatus.good => AppColors.success,
    GardenStatus.warning => AppColors.warning,
    GardenStatus.bad => AppColors.error,
  };
}
