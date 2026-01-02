import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/garden_providers.dart';

/// Carte affichant un potager dans la liste
class GardenCard extends StatelessWidget {
  final Garden garden;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GardenCard({
    super.key,
    required this.garden,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusXl,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview
            Container(
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F0E6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: _MiniPreview(
                      widthMeters: garden.widthMeters,
                      heightMeters: garden.heightMeters,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onSelected: (v) {
                        if (v == 'edit') onEdit?.call();
                        if (v == 'delete') onDelete?.call();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.pencilSimple(
                                  PhosphorIconsStyle.regular,
                                ),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text('Modifier'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.trash(PhosphorIconsStyle.regular),
                                size: 18,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          garden.name,
                          style: AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Chip(
                        emoji: '📐',
                        label: '${garden.surfaceM2.toStringAsFixed(1)} m²',
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        emoji: '↔️',
                        label:
                            '${garden.widthMeters.toStringAsFixed(1)} × ${garden.heightMeters.toStringAsFixed(1)} m',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPreview extends StatelessWidget {
  final double widthMeters;
  final double heightMeters;

  const _MiniPreview({required this.widthMeters, required this.heightMeters});

  @override
  Widget build(BuildContext context) {
    const maxSize = 70.0;
    final aspectRatio = widthMeters / heightMeters;
    double w, h;
    if (aspectRatio > 1) {
      w = maxSize;
      h = maxSize / aspectRatio;
    } else {
      h = maxSize;
      w = maxSize * aspectRatio;
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFE8DFD0),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: CustomPaint(
        size: Size(w, h),
        painter: _MiniGridPainter(
          widthMeters: widthMeters,
          heightMeters: heightMeters,
        ),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  final double widthMeters;
  final double heightMeters;

  _MiniGridPainter({required this.widthMeters, required this.heightMeters});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    final cellsX = (widthMeters * 2).ceil();
    final cellsY = (heightMeters * 2).ceil();
    final cellW = size.width / cellsX;
    final cellH = size.height / cellsY;

    for (int i = 1; i < cellsX; i++) {
      canvas.drawLine(
        Offset(i * cellW, 0),
        Offset(i * cellW, size.height),
        paint,
      );
    }
    for (int i = 1; i < cellsY; i++) {
      canvas.drawLine(
        Offset(0, i * cellH),
        Offset(size.width, i * cellH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniGridPainter oldDelegate) => false;
}

class _Chip extends StatelessWidget {
  final String emoji;
  final String label;

  const _Chip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
