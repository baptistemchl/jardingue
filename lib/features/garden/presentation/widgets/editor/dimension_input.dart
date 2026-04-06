import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Widget combinant Slider et TextField pour saisir
/// une dimension (largeur, longueur) en metres.
class DimensionInput extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const DimensionInput({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<DimensionInput> createState() => _DimensionInputState();
}

class _DimensionInputState extends State<DimensionInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.toStringAsFixed(2),
    );
    _focusNode = FocusNode()
      ..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(DimensionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.value != oldWidget.value) {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isEditing = _focusNode.hasFocus);
    if (!_focusNode.hasFocus) _validateAndApply();
  }

  void _validateAndApply() {
    final text = _controller.text.replaceAll(',', '.');
    final parsed = double.tryParse(text);

    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      _controller.text = clamped.toStringAsFixed(2);
    } else {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelAndField(),
        const SizedBox(height: 8),
        _buildSlider(),
      ],
    );
  }

  Widget _buildLabelAndField() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[\d.,]'),
              ),
            ],
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              suffixText: widget.unit,
              suffixStyle: AppTypography.caption,
            ),
            onSubmitted: (_) => _validateAndApply(),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return Row(
      children: [
        Text(
          '${widget.min.toStringAsFixed(1)}'
          '${widget.unit}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary
                  .withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: widget.value.clamp(
                widget.min,
                widget.max,
              ),
              min: widget.min,
              max: widget.max,
              divisions:
                  ((widget.max - widget.min) * 20).round(),
              onChanged: (value) {
                widget.onChanged(value);
                if (!_isEditing) {
                  _controller.text =
                      value.toStringAsFixed(2);
                }
              },
            ),
          ),
        ),
        Text(
          '${widget.max.toStringAsFixed(1)}'
          '${widget.unit}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
