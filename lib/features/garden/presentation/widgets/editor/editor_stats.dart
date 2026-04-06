import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../domain/models/garden_plant_with_details.dart';

class EditorStats extends StatelessWidget {
  final Garden garden;
  final List<GardenPlantWithDetails> elements;

  const EditorStats({
    super.key,
    required this.garden,
    required this.elements,
  });

  @override
  Widget build(BuildContext context) {
    final plantCount =
        elements.where((e) => !e.isZone).length;
    final zoneCount =
        elements.where((e) => e.isZone).length;
    final widthM =
        garden.widthCells * garden.cellSizeCm / 100.0;
    final heightM =
        garden.heightCells * garden.cellSizeCm / 100.0;
    final surfaceM2 = widthM * heightM;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatItem(
            emoji: '\u{1F4D0}',
            value: '${surfaceM2.toStringAsFixed(1)} m\u{00B2}',
          ),
          const SizedBox(width: 12),
          _StatItem(
            emoji: '\u{1F331}',
            value: '$plantCount plantes',
          ),
          const SizedBox(width: 12),
          _StatItem(
            emoji: '\u{1F4E6}',
            value: '$zoneCount zones',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;
  const _StatItem({required this.emoji, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class EditorLegend extends StatelessWidget {
  const EditorLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Legende',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const _LegendItem(
            color: Color(0xFF4CAF50),
            label: 'Legumes',
          ),
          const _LegendItem(
            color: Color(0xFF009688),
            label: 'Aromates',
          ),
          const _LegendItem(
            color: Color(0xFFE91E63),
            label: 'Fruits',
          ),
          const _LegendItem(
            color: Color(0xFF607D8B),
            label: 'Zones',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
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
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
