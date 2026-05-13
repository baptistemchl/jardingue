import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/models/planting_type.dart';
import '../widgets/planting_type_selector.dart';

/// Bottom sheet d'édition inline du type de plantation d'un arbre du verger.
class EditPlantingTypeSheet extends StatefulWidget {
  final PlantingType initialValue;
  final bool containerSuitable;
  final double? heightAdultM;

  const EditPlantingTypeSheet({
    super.key,
    required this.initialValue,
    this.containerSuitable = true,
    this.heightAdultM,
  });

  static Future<PlantingType?> show(
    BuildContext context, {
    required PlantingType initialValue,
    bool containerSuitable = true,
    double? heightAdultM,
  }) {
    return AppBottomSheet.show<PlantingType>(
      context: context,
      child: EditPlantingTypeSheet(
        initialValue: initialValue,
        containerSuitable: containerSuitable,
        heightAdultM: heightAdultM,
      ),
    );
  }

  @override
  State<EditPlantingTypeSheet> createState() =>
      _EditPlantingTypeSheetState();
}

class _EditPlantingTypeSheetState extends State<EditPlantingTypeSheet> {
  late PlantingType _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Type de plantation',
                      style: AppTypography.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PlantingTypeSelector(
                selected: _selected,
                onChanged: (t) => setState(() => _selected = t),
                containerSuitable: widget.containerSuitable,
                heightAdultM: widget.heightAdultM,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
