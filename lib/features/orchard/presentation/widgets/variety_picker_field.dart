import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Champ de saisie de variété pour un arbre fruitier.
///
/// Affiche les variétés populaires sous forme de chips tappables AU-DESSUS
/// d'un [TextField] libre. L'utilisateur peut tapper sur une chip pour
/// pré-remplir le champ, ou taper directement sa propre variété. Aucun
/// overlay : le clavier ne masque jamais les suggestions (contrairement à
/// un [Autocomplete] qui les rendrait via [Overlay] sous le champ).
class VarietyPickerField extends StatefulWidget {
  final List<String> suggestions;
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const VarietyPickerField({
    super.key,
    required this.suggestions,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<VarietyPickerField> createState() => _VarietyPickerFieldState();
}

class _VarietyPickerFieldState extends State<VarietyPickerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickSuggestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
    widget.onChanged(value);
    setState(() {}); // refresh chip selection visuel
  }

  @override
  Widget build(BuildContext context) {
    final currentText = _controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.suggestions.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.suggestions.map((v) {
              final isSelected = v == currentText;
              return ChoiceChip(
                label: Text(v),
                selected: isSelected,
                onSelected: (_) => _pickSuggestion(v),
                backgroundColor: AppColors.background,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primary : AppColors.border,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _controller,
          onChanged: (s) {
            final trimmed = s.trim();
            widget.onChanged(trimmed.isEmpty ? null : trimmed);
            setState(() {}); // refresh chip selection au fil de la saisie
          },
          decoration: InputDecoration(
            hintText: 'Ex: Bergeron, ou la vôtre',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
