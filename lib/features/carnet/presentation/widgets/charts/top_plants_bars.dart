import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../domain/models/carnet_stats.dart';

/// Top 5 plantes — barres horizontales animées avec emoji et badge
/// "n°1" doré sur la première position.
class TopPlantsBars extends StatefulWidget {
  final List<TopPlant> plants;
  const TopPlantsBars({super.key, required this.plants});

  @override
  State<TopPlantsBars> createState() => _TopPlantsBarsState();
}

class _TopPlantsBarsState extends State<TopPlantsBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant TopPlantsBars old) {
    super.didUpdateWidget(old);
    if (old.plants != widget.plants) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plants.isEmpty) return const SizedBox.shrink();
    final maxCount = widget.plants
        .map((p) => p.harvestCount)
        .fold<int>(0, (m, c) => c > m ? c : m);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Column(
          children: List.generate(widget.plants.length, (i) {
            final p = widget.plants[i];
            final ratio = maxCount == 0 ? 0.0 : p.harvestCount / maxCount;
            final localStart = i * 0.08;
            final localT =
                ((_controller.value - localStart) / (1 - localStart))
                    .clamp(0.0, 1.0);
            final eased = 1 - _pow3(1 - localT);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _TopPlantRow(
                rank: i + 1,
                plant: p,
                ratio: ratio * eased,
                rawCount: p.harvestCount,
                opacity: eased,
              ),
            );
          }),
        );
      },
    );
  }

  double _pow3(double x) => x * x * x;
}

class _TopPlantRow extends StatelessWidget {
  final int rank;
  final TopPlant plant;
  final double ratio; // 0..1
  final int rawCount;
  final double opacity;

  const _TopPlantRow({
    required this.rank,
    required this.plant,
    required this.ratio,
    required this.rawCount,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = PlantEmojiMapper.fromName(
      plant.plantName,
      categoryCode: plant.plantCategoryCode,
    );
    final isFirst = rank == 1;
    return Opacity(
      opacity: opacity,
      child: Row(
        children: [
          // Rang dans un cercle.
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isFirst
                  ? AppColors.secondary
                  : AppColors.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: isFirst
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTypography.caption.copyWith(
                  color:
                      isFirst ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.plantName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                LayoutBuilder(
                  builder: (_, c) => Container(
                    width: double.infinity,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: ratio.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isFirst
                                    ? [
                                        AppColors.secondary,
                                        AppColors.warning,
                                      ]
                                    : [
                                        AppColors.primary,
                                        AppColors.primaryLight,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$rawCount',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
