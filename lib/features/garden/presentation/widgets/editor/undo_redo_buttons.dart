import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';

class UndoRedoButtons extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const UndoRedoButtons({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _UndoRedoButton(
          icon: PhosphorIcons.arrowUUpLeft(
            PhosphorIconsStyle.bold,
          ),
          enabled: canUndo,
          tooltip: canUndo ? 'Annuler' : 'Rien a annuler',
          onTap: onUndo,
        ),
        _UndoRedoButton(
          icon: PhosphorIcons.arrowUUpRight(
            PhosphorIconsStyle.bold,
          ),
          enabled: canRedo,
          tooltip:
              canRedo ? 'Retablir' : 'Rien a retablir',
          onTap: onRedo,
        ),
      ],
    );
  }
}

class _UndoRedoButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;

  const _UndoRedoButton({
    required this.icon,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
