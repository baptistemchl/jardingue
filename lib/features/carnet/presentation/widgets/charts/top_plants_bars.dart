import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../domain/models/carnet_stats.dart';

/// Top 5 plantes — barres horizontales animées avec emoji et badge
/// "n°1" doré sur la première position. La barre est dimensionnée
/// selon le `sortMode` (poids / count / pièces / bottes) ; la valeur
/// affichée à droite suit le même mode.
class TopPlantsBars extends StatefulWidget {
  final List<TopPlant> plants;
  final TopPlantsSortMode sortMode;
  const TopPlantsBars({
    super.key,
    required this.plants,
    required this.sortMode,
  });

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
    // Référence (max) selon le mode actif, pour proportionner les barres.
    double scoreOf(TopPlant p) => switch (widget.sortMode) {
          TopPlantsSortMode.count => p.harvestCount.toDouble(),
          TopPlantsSortMode.weight => p.totalKg,
          TopPlantsSortMode.pieces => p.totalPieces.toDouble(),
          TopPlantsSortMode.bunches => p.totalBunches.toDouble(),
        };
    final maxScore = widget.plants
        .map(scoreOf)
        .fold<double>(0, (m, s) => s > m ? s : m);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Column(
          children: List.generate(widget.plants.length, (i) {
            final p = widget.plants[i];
            final ratio = maxScore == 0 ? 0.0 : scoreOf(p) / maxScore;
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
                sortMode: widget.sortMode,
                ratio: ratio * eased,
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
  final TopPlantsSortMode sortMode;
  final double ratio; // 0..1
  final double opacity;

  const _TopPlantRow({
    required this.rank,
    required this.plant,
    required this.sortMode,
    required this.ratio,
    required this.opacity,
  });

  String _valueLabel() {
    switch (sortMode) {
      case TopPlantsSortMode.count:
        return '${plant.harvestCount}';
      case TopPlantsSortMode.weight:
        final kg = plant.totalKg;
        if (kg == kg.roundToDouble()) return '${kg.toStringAsFixed(0)} kg';
        return '${kg.toStringAsFixed(2).replaceAll('.', ',')} kg';
      case TopPlantsSortMode.pieces:
        return '${plant.totalPieces} u';
      case TopPlantsSortMode.bunches:
        return '${plant.totalBunches}';
    }
  }

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
            _valueLabel(),
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
