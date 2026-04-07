import 'package:flutter/material.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class LockToggleButton extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onToggle;

  const LockToggleButton({
    super.key,
    required this.isLocked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isLocked
              ? AppColors.surface
              : AppColors.primary,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isLocked
                ? AppColors.border
                : AppColors.primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isLocked
                      ? Colors.black
                      : AppColors.primary)
                  .withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(width: 10),
            _buildLabel(context),
            const SizedBox(width: 8),
            _buildBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Icon(
        isLocked
            ? PhosphorIcons.lock(PhosphorIconsStyle.fill)
            : PhosphorIcons.pencilSimple(
                PhosphorIconsStyle.fill,
              ),
        key: ValueKey(isLocked),
        size: 18,
        color: isLocked
            ? AppColors.textSecondary
            : Colors.white,
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        isLocked ? AppLocalizations.of(context)!.locked : AppLocalizations.of(context)!.editMode,
        key: ValueKey(isLocked),
        style: AppTypography.labelMedium.copyWith(
          color: isLocked
              ? AppColors.textSecondary
              : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isLocked
            ? AppColors.textTertiary.withValues(
                alpha: 0.15,
              )
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isLocked
            ? AppLocalizations.of(context)!.tapToEdit
            : AppLocalizations.of(context)!.moveElements,
        style: AppTypography.caption.copyWith(
          fontSize: 10,
          color: isLocked
              ? AppColors.textTertiary
              : Colors.white.withValues(alpha: 0.95),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
