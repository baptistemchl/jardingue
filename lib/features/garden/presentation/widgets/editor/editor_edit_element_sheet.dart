import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/services/database/app_database.dart';
import '../../../domain/models/garden_plant_with_details.dart';
import 'dimension_input.dart';

/// Sheet pour editer les dimensions d'un element
/// (zone ou plante sans detail) dans l'editeur.
class EditorEditElementSheet extends StatefulWidget {
  final GardenPlantWithDetails element;
  final Garden garden;
  final double maxWidthM;
  final double maxHeightM;
  final Function(double w, double h) onUpdate;
  final VoidCallback onDelete;

  const EditorEditElementSheet({
    super.key,
    required this.element,
    required this.garden,
    required this.maxWidthM,
    required this.maxHeightM,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<EditorEditElementSheet> createState() =>
      _State();
}

class _State extends State<EditorEditElementSheet> {
  late double _width;
  late double _height;

  @override
  void initState() {
    super.initState();
    final cs = widget.garden.cellSizeCm;
    _width = widget.element.widthMeters(cs);
    _height = widget.element.heightMeters(cs);
  }

  @override
  Widget build(BuildContext context) {
    final isZone = widget.element.isZone;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _handle(),
            const SizedBox(height: 16),
            Text(
              isZone
                  ? 'Modifier la zone'
                  : 'Modifier la plante',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.element.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.element.name,
                  style: AppTypography.bodyMedium
                      .copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DimensionInput(
              label: 'Largeur',
              value: _width,
              min: 0.1,
              max: widget.maxWidthM,
              unit: 'm',
              onChanged: (v) =>
                  setState(() => _width = v),
            ),
            const SizedBox(height: 16),
            DimensionInput(
              label: 'Longueur',
              value: _height,
              min: 0.1,
              max: widget.maxHeightM,
              unit: 'm',
              onChanged: (v) =>
                  setState(() => _height = v),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _deleteButton(context, isZone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        widget.onUpdate(_width, _height),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Enregistrer',
                      style: AppTypography.bodyMedium
                          .copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _handle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _deleteButton(BuildContext context, bool isZone) {
    return OutlinedButton.icon(
      onPressed: () => _confirmDelete(context, isZone),
      icon: Icon(
        PhosphorIcons.trash(PhosphorIconsStyle.fill),
        size: 18,
      ),
      label: const Text('Supprimer'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding:
            const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    bool isZone,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer '
          '${isZone ? "cette zone" : "cette plante"} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
