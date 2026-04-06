import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class ZoomIndicator extends StatelessWidget {
  final double scale;
  const ZoomIndicator({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final percent = scale * 100;
    final text = switch (percent) {
      < 1 => '${percent.toStringAsFixed(2)}%',
      < 10 => '${percent.toStringAsFixed(1)}%',
      > 1000 => '${(percent / 1000).toStringAsFixed(1)}k%',
      _ => '${percent.round()}%',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          fontFeatures: const [
            FontFeature.tabularFigures(),
          ],
        ),
      ),
    );
  }
}

class ZoomControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const ZoomControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class ZoomControls extends StatelessWidget {
  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const ZoomControls({
    super.key,
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ZoomControlButton(
          icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
          onTap: onZoomIn,
          tooltip: 'Zoom +',
        ),
        const SizedBox(height: 8),
        ZoomIndicator(scale: scale),
        const SizedBox(height: 8),
        ZoomControlButton(
          icon: PhosphorIcons.minus(
            PhosphorIconsStyle.bold,
          ),
          onTap: onZoomOut,
          tooltip: 'Zoom -',
        ),
      ],
    );
  }
}
