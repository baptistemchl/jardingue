import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Champ de saisie de variété pour un arbre fruitier.
///
/// Combine un [Autocomplete] qui propose [suggestions] (variétés populaires
/// issues du catalogue) tout en acceptant n'importe quel texte libre. La
/// valeur courante est exposée via [onChanged] ; un texte vide est mappé sur
/// `null` côté caller (variété "non renseignée").
class VarietyAutocompleteField extends StatefulWidget {
  final List<String> suggestions;
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const VarietyAutocompleteField({
    super.key,
    required this.suggestions,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<VarietyAutocompleteField> createState() =>
      _VarietyAutocompleteFieldState();
}

class _VarietyAutocompleteFieldState extends State<VarietyAutocompleteField> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.initialValue ?? ''),
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return widget.suggestions;
        final lower = value.text.toLowerCase();
        return widget.suggestions
            .where((v) => v.toLowerCase().contains(lower));
      },
      onSelected: (s) => widget.onChanged(s.isEmpty ? null : s),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (s) =>
              widget.onChanged(s.trim().isEmpty ? null : s.trim()),
          decoration: InputDecoration(
            hintText: 'Ex: Bergeron, ou la vôtre',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final opt = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(opt),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(opt, style: AppTypography.bodyMedium),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
