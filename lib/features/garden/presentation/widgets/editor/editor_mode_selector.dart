import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/editor_mode.dart';

/// Segmented control a 3 etats pour le mode d'edition de la grille :
/// verrouille, deplacer, redimensionner.
///
/// Le segment actif est rempli (primary), les autres sont muets et n'affichent
/// que leur icone. Tap sur un segment passe au mode correspondant. Sur
/// changement de mode l'indicateur glisse en douceur (250 ms) et un retour
/// haptique est emis.
class EditorModeSelector extends StatelessWidget {
  final EditorMode mode;
  final ValueChanged<EditorMode> onChanged;

  const EditorModeSelector({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  static const _segments = <_SegmentSpec>[
    _SegmentSpec(EditorMode.locked),
    _SegmentSpec(EditorMode.move),
    _SegmentSpec(EditorMode.resize),
  ];

  void _onTap(EditorMode target) {
    if (target == mode) return;
    HapticFeedback.selectionClick();
    onChanged(target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final spec in _segments)
              _Segment(
                spec: spec,
                active: spec.mode == mode,
                label: _labelFor(l10n, spec.mode),
                onTap: () => _onTap(spec.mode),
              ),
          ],
        ),
      ),
    );
  }

  static String _labelFor(AppLocalizations l10n, EditorMode m) {
    switch (m) {
      case EditorMode.locked:
        return l10n.locked;
      case EditorMode.move:
        return l10n.moveMode;
      case EditorMode.resize:
        return l10n.resizeMode;
    }
  }
}

class _SegmentSpec {
  final EditorMode mode;
  const _SegmentSpec(this.mode);

  IconData iconFor() {
    switch (mode) {
      case EditorMode.locked:
        return PhosphorIcons.lock(PhosphorIconsStyle.fill);
      case EditorMode.move:
        return PhosphorIcons.arrowsOutCardinal(PhosphorIconsStyle.fill);
      case EditorMode.resize:
        return PhosphorIcons.cornersOut(PhosphorIconsStyle.bold);
    }
  }
}

class _Segment extends StatelessWidget {
  final _SegmentSpec spec;
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _Segment({
    required this.spec,
    required this.active,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 14 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              spec.iconFor(),
              size: 18,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.centerLeft,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                widthFactor: active ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
