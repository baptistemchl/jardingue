import 'package:flutter/material.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../domain/models/garden_plant_with_details.dart';

/// Sheet affichant la liste de tous les elements
/// du potager avec actions rapides.
class EditorElementsListSheet extends StatelessWidget {
  final Garden garden;
  final List<GardenPlantWithDetails> elements;
  final bool isLocked;
  final VoidCallback onToggleLock;
  final void Function(GardenPlantWithDetails) onElementTap;
  final void Function(GardenPlantWithDetails) onElementDelete;

  const EditorElementsListSheet({
    super.key,
    required this.garden,
    required this.elements,
    required this.isLocked,
    required this.onToggleLock,
    required this.onElementTap,
    required this.onElementDelete,
  });

  @override
  Widget build(BuildContext context) {
    final plants =
        elements.where((e) => !e.isZone).toList();
    final zones =
        elements.where((e) => e.isZone).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(context),
          const Divider(),
          Expanded(
            child: elements.isEmpty
                ? _buildEmpty(context)
                : _buildList(context, plants, zones),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.gardenElements,
              style: AppTypography.titleLarge,
            ),
          ),
          _LockBadge(
            isLocked: isLocked,
            onTap: onToggleLock,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              PhosphorIcons.x(PhosphorIconsStyle.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.plant(
              PhosphorIconsStyle.duotone,
            ),
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noElement,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.addPlantsOrZones,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<GardenPlantWithDetails> plants,
    List<GardenPlantWithDetails> zones,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      children: [
        if (plants.isNotEmpty) ...[
          _SectionHeader(
            title: AppLocalizations.of(context)!.plantsSection,
            count: plants.length,
            emoji: '\u{1F331}',
          ),
          const SizedBox(height: 8),
          ...plants.map(
            (e) => _ElementItem(
              element: e,
              garden: garden,
              onTap: () => onElementTap(e),
              onDelete: () => onElementDelete(e),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (zones.isNotEmpty) ...[
          _SectionHeader(
            title: AppLocalizations.of(context)!.zonesSection,
            count: zones.length,
            emoji: '\u{1F4E6}',
          ),
          const SizedBox(height: 8),
          ...zones.map(
            (e) => _ElementItem(
              element: e,
              garden: garden,
              onTap: () => onElementTap(e),
              onDelete: () => onElementDelete(e),
            ),
          ),
        ],
      ],
    );
  }
}

class _LockBadge extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onTap;
  const _LockBadge({
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLocked
        ? AppColors.textSecondary
        : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocked
                  ? PhosphorIcons.lock(
                      PhosphorIconsStyle.fill,
                    )
                  : PhosphorIcons.lockOpen(
                      PhosphorIconsStyle.fill,
                    ),
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              isLocked ? AppLocalizations.of(context)!.locked : AppLocalizations.of(context)!.unlocked,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final String emoji;
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ElementItem extends StatelessWidget {
  final GardenPlantWithDetails element;
  final Garden garden;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ElementItem({
    required this.element,
    required this.garden,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(element.color);
    final cs = garden.cellSizeCm;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    element.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.name,
                      style:
                          AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${element.widthMeters(cs).toStringAsFixed(2)}m '
                      '\u{00D7} '
                      '${element.heightMeters(cs).toStringAsFixed(2)}m',
                      style:
                          AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _DeleteButton(
                name: element.name,
                onConfirmed: onDelete,
              ),
              Icon(
                PhosphorIcons.caretRight(
                  PhosphorIconsStyle.bold,
                ),
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final String name;
  final VoidCallback onConfirmed;
  const _DeleteButton({
    required this.name,
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.deleteConfirmTitle),
            content: Text(
              AppLocalizations.of(context)!.deleteConfirmMessage(name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onConfirmed();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
        );
      },
      icon: Icon(
        PhosphorIcons.trash(PhosphorIconsStyle.regular),
        size: 20,
        color: AppColors.error,
      ),
    );
  }
}
