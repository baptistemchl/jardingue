import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/providers/database_providers.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/plant_emoji_mapper.dart';
import '../../../domain/models/rotation_family.dart';

/// Sélecteur "culture précédente" pour la rotation des cultures.
/// Utilisé à l'ajout comme à l'édition. Affiche un bandeau d'alerte
/// si la famille sélectionnée == famille de la plante courante.
///
/// Maintient un `_localValue` pour l'optimistic UI : le rendu se met à
/// jour dès le tap, sans attendre le round-trip DB → invalidate →
/// re-read déclenché par le notifier côté détail.
class PreviousCropPicker extends ConsumerStatefulWidget {
  final int? value;
  final Plant currentPlant;
  final ValueChanged<int?> onChanged;

  /// Optionnel : plante résolue automatiquement (depuis le potager
  /// précédent à la même position). Si renseignée et pas d'override
  /// manuel, on l'affiche en libellé secondaire.
  final Plant? autoResolved;

  const PreviousCropPicker({
    super.key,
    required this.value,
    required this.currentPlant,
    required this.onChanged,
    this.autoResolved,
  });

  @override
  ConsumerState<PreviousCropPicker> createState() =>
      _PreviousCropPickerState();
}

class _PreviousCropPickerState extends ConsumerState<PreviousCropPicker> {
  int? _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant PreviousCropPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le parent refournit une valeur explicitement (changement de
    // plante courante, ou réouverture du sheet), on la prend en compte.
    if (oldWidget.value != widget.value) {
      _localValue = widget.value;
    }
  }

  void _applyChange(int? newValue) {
    setState(() => _localValue = newValue);
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(allPlantsSortedProvider);
    final currentFamily =
        RotationFamily.fromLatinName(widget.currentPlant.latinName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Culture précédente', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          'Ce qui poussait à cette place l\'année passée.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        plantsAsync.when(
          data: (plants) {
            final effective = _localValue != null
                ? plants.firstWhere(
                    (p) => p.id == _localValue,
                    orElse: () => plants.first,
                  )
                : widget.autoResolved;
            final conflict =
                _computeConflict(effective, widget.currentPlant);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PickerButton(
                  effective: effective,
                  overridden: _localValue != null,
                  autoFromPrevious:
                      _localValue == null && widget.autoResolved != null,
                  onTap: () => _showPlantPicker(context, plants),
                  onClear:
                      _localValue != null ? () => _applyChange(null) : null,
                ),
                if (conflict) ...[
                  const SizedBox(height: 8),
                  _ConflictBanner(
                    previousFamily: RotationFamily.fromLatinName(
                      effective!.latinName,
                    ),
                    currentFamily: currentFamily,
                  ),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => Text(
            'Impossible de charger les plantes.',
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  bool _computeConflict(Plant? previous, Plant current) {
    if (previous == null) return false;
    final prev = RotationFamily.fromLatinName(previous.latinName);
    final curr = RotationFamily.fromLatinName(current.latinName);
    return isRotationConflict(prev, curr);
  }

  void _showPlantPicker(BuildContext context, List<Plant> plants) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlantPickerSheet(
        plants: plants,
        onPlantSelected: (id) => _applyChange(id),
      ),
    );
  }
}

class _PlantPickerSheet extends StatefulWidget {
  final List<Plant> plants;
  final ValueChanged<int> onPlantSelected;

  const _PlantPickerSheet({
    required this.plants,
    required this.onPlantSelected,
  });

  @override
  State<_PlantPickerSheet> createState() => _PlantPickerSheetState();
}

class _PlantPickerSheetState extends State<_PlantPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plants = widget.plants;
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? plants
        : plants
            .where((p) =>
                p.commonName.toLowerCase().contains(query) ||
                (p.latinName?.toLowerCase().contains(query) ?? false))
            .toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choisir la culture précédente',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher une plante…',
              prefixIcon: Icon(
                PhosphorIcons.magnifyingGlass(
                  PhosphorIconsStyle.regular,
                ),
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final p = filtered[i];
                final family = RotationFamily.fromLatinName(p.latinName);
                return ListTile(
                  dense: true,
                  leading: Text(
                    PlantEmojiMapper.fromName(
                      p.commonName,
                      categoryCode: p.categoryCode,
                    ),
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Text(p.commonName, style: AppTypography.bodySmall),
                  subtitle:
                      family != null && family != RotationFamily.other
                          ? Text(
                              family.label,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            )
                          : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onPlantSelected(p.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final Plant? effective;
  final bool overridden;
  final bool autoFromPrevious;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PickerButton({
    required this.effective,
    required this.overridden,
    required this.autoFromPrevious,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.clockCounterClockwise(
                PhosphorIconsStyle.regular,
              ),
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: effective == null
                  ? Text(
                      'Inconnu',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          PlantEmojiMapper.fromName(
                            effective!.commonName,
                            categoryCode: effective!.categoryCode,
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            effective!.commonName,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (autoFromPrevious) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'auto',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    PhosphorIcons.x(PhosphorIconsStyle.bold),
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  final RotationFamily? previousFamily;
  final RotationFamily? currentFamily;

  const _ConflictBanner({
    required this.previousFamily,
    required this.currentFamily,
  });

  @override
  Widget build(BuildContext context) {
    final label = previousFamily?.label ?? '';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.warning(PhosphorIconsStyle.fill),
            size: 18,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rotation déconseillée : même famille ($label). '
              'Préférez changer d\'emplacement.',
              style: AppTypography.caption.copyWith(
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
