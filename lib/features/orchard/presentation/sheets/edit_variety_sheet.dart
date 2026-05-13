import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../widgets/variety_picker_field.dart';

/// Bottom sheet d'édition inline de la variété d'un arbre du verger.
///
/// Renvoie le nouveau texte au pop (ou `null` si annulé / vidé).
class EditVarietySheet extends StatefulWidget {
  final String? initialValue;
  final List<String> suggestions;

  const EditVarietySheet({
    super.key,
    required this.suggestions,
    this.initialValue,
  });

  /// Helper — renvoie `null` si l'utilisateur a annulé, ou la nouvelle valeur
  /// (peut être `null` si l'utilisateur a vidé le champ pour "non renseignée").
  static Future<({String? value})?> show(
    BuildContext context, {
    required List<String> suggestions,
    String? initialValue,
  }) {
    return AppBottomSheet.show<({String? value})>(
      context: context,
      child: EditVarietySheet(
        initialValue: initialValue,
        suggestions: suggestions,
      ),
    );
  }

  @override
  State<EditVarietySheet> createState() => _EditVarietySheetState();
}

class _EditVarietySheetState extends State<EditVarietySheet> {
  String? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    // Padding clavier : sans ça, le bouton "Enregistrer" passe sous le
    // clavier quand le TextField a le focus (AppBottomSheet n'absorbe
    // pas les viewInsets car isScrollControlled est à true).
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHandle(),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Variété',
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
              VarietyPickerField(
                initialValue: widget.initialValue,
                suggestions: widget.suggestions,
                onChanged: (v) => _value = v,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, (value: _value)),
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
