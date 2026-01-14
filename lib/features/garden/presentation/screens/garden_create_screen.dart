import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/garden_providers.dart';

/// Écran de création/édition d'un potager (dimensions en mètres)
class GardenCreateScreen extends ConsumerStatefulWidget {
  final Garden? garden;
  final VoidCallback? onSaved;

  const GardenCreateScreen({super.key, this.garden, this.onSaved});

  @override
  ConsumerState<GardenCreateScreen> createState() => _GardenCreateScreenState();
}

class _GardenCreateScreenState extends ConsumerState<GardenCreateScreen> {
  late TextEditingController _nameController;
  late double _widthMeters;
  late double _heightMeters;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isEditing => widget.garden != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.garden?.name ?? '');
    _widthMeters = widget.garden?.widthMeters ?? 3.0;
    _heightMeters = widget.garden?.heightMeters ?? 2.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    // Effacer l'erreur après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
  }

  void _closeSheet() {
    // Utiliser le rootNavigator pour fermer le ModalBottomSheet
    // car il a été ouvert avec useRootNavigator: true
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _save() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showError('Veuillez entrer un nom pour votre potager');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isEditing) {
        await ref
            .read(gardenNotifierProvider.notifier)
            .updateGarden(
          id: widget.garden!.id,
          name: _nameController.text.trim(),
          widthMeters: _widthMeters,
          heightMeters: _heightMeters,
        );
      } else {
        await ref
            .read(gardenNotifierProvider.notifier)
            .createGarden(
          name: _nameController.text.trim(),
          widthMeters: _widthMeters,
          heightMeters: _heightMeters,
        );
      }

      if (mounted) {
        // D'abord appeler le callback (qui invalide le provider)
        widget.onSaved?.call();
        // Puis fermer le bottom sheet avec un léger délai
        // pour éviter le conflit de navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _closeSheet();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Modifier le potager' : 'Nouveau potager',
                    style: AppTypography.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: _closeSheet,
                  icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                ),
              ],
            ),
          ),

          const Divider(),

          // Message d'erreur intégré
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.warning(PhosphorIconsStyle.fill),
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Contenu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Nom
                Text('Nom du potager', style: AppTypography.labelMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Potager principal',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    // Bordure d'erreur si le champ est vide et une erreur est affichée
                    enabledBorder: _errorMessage != null &&
                        _nameController.text.trim().isEmpty
                        ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                    )
                        : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) {
                    // Effacer l'erreur quand l'utilisateur tape
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Dimensions
                Text('Dimensions', style: AppTypography.labelMedium),
                const SizedBox(height: 4),
                Text(
                  'Définissez la taille de votre potager en mètres',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _DimensionSlider(
                        label: 'Largeur',
                        value: _widthMeters,
                        onChanged: (v) => setState(() => _widthMeters = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DimensionSlider(
                        label: 'Hauteur',
                        value: _heightMeters,
                        onChanged: (v) => setState(() => _heightMeters = v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Aperçu
                Text('Aperçu', style: AppTypography.labelMedium),
                const SizedBox(height: 12),
                _GardenPreview(
                  widthMeters: _widthMeters,
                  heightMeters: _heightMeters,
                ),

                const SizedBox(height: 16),

                // Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat(
                        emoji: '📐',
                        label: 'Surface',
                        value:
                        '${(_widthMeters * _heightMeters).toStringAsFixed(1)} m²',
                      ),
                      _Stat(
                        emoji: '↔️',
                        label: 'Largeur',
                        value: '${_widthMeters.toStringAsFixed(1)} m',
                      ),
                      _Stat(
                        emoji: '↕️',
                        label: 'Hauteur',
                        value: '${_heightMeters.toStringAsFixed(1)} m',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bouton
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(isEditing ? 'Enregistrer' : 'Créer le potager'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionSlider extends StatelessWidget {
  final String label;
  final double value;
  final Function(double) onChanged;

  const _DimensionSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} m',
              style: AppTypography.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: 0.5,
            max: 20.0,
            divisions: 39,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _GardenPreview extends StatelessWidget {
  final double widthMeters;
  final double heightMeters;

  const _GardenPreview({required this.widthMeters, required this.heightMeters});

  @override
  Widget build(BuildContext context) {
    const maxSize = 200.0;
    final aspectRatio = widthMeters / heightMeters;

    double width, height;
    if (aspectRatio > 1) {
      width = maxSize;
      height = maxSize / aspectRatio;
    } else {
      height = maxSize;
      width = maxSize * aspectRatio;
    }

    return Center(
      child: Column(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFE8DFD0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: CustomPaint(
              size: Size(width, height),
              painter: _GridPainter(
                widthMeters: widthMeters,
                heightMeters: heightMeters,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grille: 1 carreau = 50cm',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double widthMeters;
  final double heightMeters;

  _GridPainter({required this.widthMeters, required this.heightMeters});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    // Grille 50cm
    final cellsX = (widthMeters / 0.5).ceil();
    final cellsY = (heightMeters / 0.5).ceil();
    final cellW = size.width / cellsX;
    final cellH = size.height / cellsY;

    for (int i = 1; i < cellsX; i++) {
      canvas.drawLine(
        Offset(i * cellW, 0),
        Offset(i * cellW, size.height),
        paint,
      );
    }
    for (int i = 1; i < cellsY; i++) {
      canvas.drawLine(
        Offset(0, i * cellH),
        Offset(size.width, i * cellH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.widthMeters != widthMeters ||
          oldDelegate.heightMeters != heightMeters;
}

class _Stat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _Stat({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.titleSmall),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}