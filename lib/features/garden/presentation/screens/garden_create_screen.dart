import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/patch.dart';
import '../../../../core/services/crash_reporting/crash_reporting_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../domain/garden_template_service.dart';
import '../../domain/models/garden_template.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

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
  late int _cellSizeCm;
  int? _year;
  int? _previousGardenId;
  bool _isLoading = false;
  String? _errorMessage;

  /// Template sélectionné (mode création uniquement). Quand non null,
  /// l'enregistrement passe par createGardenFromTemplate au lieu de
  /// createGarden — toutes les plantes du modèle sont placées d'un coup.
  /// La taille de cellule du template écrase `_cellSizeCm` à la sélection.
  GardenTemplate? _selectedTemplate;

  bool get isEditing => widget.garden != null;

  void _selectTemplate(GardenTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _cellSizeCm = template.cellSizeCm;
      _nameController.text = template.name;
      _widthMeters = template.widthMeters;
      _heightMeters = template.heightMeters;
      _errorMessage = null;
    });
  }

  void _clearTemplate() {
    setState(() {
      _selectedTemplate = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.garden?.name ?? '');
    _widthMeters = widget.garden?.widthMeters ?? 3.0;
    _heightMeters = widget.garden?.heightMeters ?? 2.0;
    // En édition, on reprend la taille existante (changer la taille de
    // cellule sur un potager existant invaliderait les coords gridX/Y
    // des plantes déjà posées → on cache le sélecteur dans ce cas).
    // En création, défaut à 30 cm (lisibilité standard) — l'utilisateur
    // peut descendre à 5/10/15 pour plus de précision dans les warnings
    // d'antagonisme.
    _cellSizeCm = widget.garden?.cellSizeCm ?? 30;
    _year = widget.garden?.year;
    _previousGardenId = widget.garden?.previousGardenId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    // Le SnackBar gère sa propre durée d'affichage
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _closeSheet() {
    // Utiliser le rootNavigator pour fermer le ModalBottomSheet
    // car il a été ouvert avec useRootNavigator: true
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _save() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showError(AppLocalizations.of(context)!.gardenNameRequired);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Capture les providers avant tout await : le bottom sheet peut être
    // fermé pendant le chargement, ce qui dispose `ref` et fait crasher
    // tout `ref.read` ultérieur (assertNotDisposed).
    final notifier = ref.read(gardenNotifierProvider.notifier);

    try {
      if (isEditing) {
        // Vérifie que les éléments existants tiennent
        // dans les nouvelles dimensions.
        final cellSize = widget.garden!.cellSizeCm;
        final newWidthCells =
            (_widthMeters * 100 / cellSize).ceil();
        final newHeightCells =
            (_heightMeters * 100 / cellSize).ceil();
        final elements = await ref.read(
          gardenPlantsProvider(widget.garden!.id).future,
        );
        final overflow = elements
            .where((e) =>
                !e.isPendingPlacement &&
                (e.gridX + e.widthCells > newWidthCells ||
                    e.gridY + e.heightCells > newHeightCells))
            .length;
        if (overflow > 0) {
          if (mounted) {
            _showError(
              AppLocalizations.of(context)!
                  .gardenResizeOverflow(overflow),
            );
            setState(() => _isLoading = false);
          }
          return;
        }

        await notifier.updateGarden(
          id: widget.garden!.id,
          name: _nameController.text.trim(),
          widthMeters: _widthMeters,
          heightMeters: _heightMeters,
          year: Patch(_year),
          previousGardenId: Patch(_previousGardenId),
        );
      } else if (_selectedTemplate != null) {
        // Création à partir d'un template : on délègue tout au notifier
        // qui crée le potager ET pose toutes les plantes pré-définies.
        await notifier.createGardenFromTemplate(
          name: _nameController.text.trim(),
          widthMeters: _widthMeters,
          heightMeters: _heightMeters,
          cellSizeCm: _cellSizeCm,
          plants: _selectedTemplate!.plants
              .map((p) => (
                    plantName: p.plantName,
                    xCells: p.xCells,
                    yCells: p.yCells,
                    wCells: p.wCells,
                    hCells: p.hCells,
                  ))
              .toList(),
          year: _year,
          previousGardenId: _previousGardenId,
        );
      } else {
        await notifier.createGarden(
          name: _nameController.text.trim(),
          widthMeters: _widthMeters,
          heightMeters: _heightMeters,
          cellSizeCm: _cellSizeCm,
          year: _year,
          previousGardenId: _previousGardenId,
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
    } catch (e, st) {
      CrashReportingService.recordError(e, st,
        reason: 'GardenCreateScreen._save',
      );
      if (mounted) {
        _showError(AppLocalizations.of(context)!.errorWithMessage(e.toString()));
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
                    isEditing ? AppLocalizations.of(context)!.editGarden : AppLocalizations.of(context)!.newGarden,
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
                // Templates de potagers (mode création uniquement)
                if (!isEditing) ...[
                  _TemplatesSection(
                    selectedTemplate: _selectedTemplate,
                    onTemplateSelected: _selectTemplate,
                    onCustomSelected: _clearTemplate,
                  ),
                  const SizedBox(height: 24),
                ],

                // Nom
                Text(AppLocalizations.of(context)!.gardenName, style: AppTypography.labelMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.gardenNameHint,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    // Bordure d'erreur si le champ est vide et une erreur est affichée
                    enabledBorder:
                        _errorMessage != null &&
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
                Text(AppLocalizations.of(context)!.dimensions, style: AppTypography.labelMedium),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.dimensionsHint,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _DimensionSlider(
                        label: AppLocalizations.of(context)!.width,
                        value: _widthMeters,
                        onChanged: (v) => setState(() => _widthMeters = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DimensionSlider(
                        label: AppLocalizations.of(context)!.length,
                        value: _heightMeters,
                        onChanged: (v) => setState(() => _heightMeters = v),
                      ),
                    ),
                  ],
                ),

                // Précision de la grille (création uniquement — modifier
                // après coup invaliderait les coords des plantes posées).
                if (!isEditing) ...[
                  const SizedBox(height: 24),
                  _CellSizeSelector(
                    value: _cellSizeCm,
                    onChanged: (v) => setState(() => _cellSizeCm = v),
                  ),
                ],

                const SizedBox(height: 24),

                // Année et potager précédent (rotation)
                _RotationSection(
                  year: _year,
                  previousGardenId: _previousGardenId,
                  currentGardenId: widget.garden?.id,
                  onYearChanged: (v) => setState(() => _year = v),
                  onPreviousGardenChanged: (v) =>
                      setState(() => _previousGardenId = v),
                ),

                const SizedBox(height: 32),

                // Aperçu
                Text(AppLocalizations.of(context)!.preview, style: AppTypography.labelMedium),
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
                        label: AppLocalizations.of(context)!.surface,
                        value:
                            '${(_widthMeters * _heightMeters).toStringAsFixed(1)} m²',
                      ),
                      _Stat(
                        emoji: '↔️',
                        label: AppLocalizations.of(context)!.width,
                        value: '${_widthMeters.toStringAsFixed(1)} m',
                      ),
                      _Stat(
                        emoji: '↕️',
                        label: AppLocalizations.of(context)!.length,
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
                    : Text(isEditing ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.createGarden),
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
            AppLocalizations.of(context)!.gridInfo,
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

/// Section "Rotation" : année du potager + potager précédent.
class _RotationSection extends ConsumerWidget {
  final int? year;
  final int? previousGardenId;
  final int? currentGardenId;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<int?> onPreviousGardenChanged;

  const _RotationSection({
    required this.year,
    required this.previousGardenId,
    required this.currentGardenId,
    required this.onYearChanged,
    required this.onPreviousGardenChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardensAsync = ref.watch(gardensListProvider);
    final currentYear = DateTime.now().year;
    // 4 années antérieures (au-delà la rotation n'a plus d'impact)
    // et 1 année future (potager planifié pour l'an prochain).
    final years = [
      for (var y = currentYear - 4; y <= currentYear + 1; y++) y,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Année du potager', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          'Permet de dater vos cultures et d\'activer la rotation.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _YearChips(
          value: year,
          years: years,
          onChanged: onYearChanged,
        ),
        const SizedBox(height: 20),
        Text('Potager précédent', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          'Pour reprendre l\'historique d\'un ancien potager.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        gardensAsync.when(
          data: (list) {
            final candidates =
                list.where((g) => g.id != currentGardenId).toList();
            return _PreviousGardenDropdown(
              value: previousGardenId,
              candidates: candidates,
              onChanged: onPreviousGardenChanged,
            );
          },
          loading: () => const SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => Text(
            'Impossible de charger les potagers.',
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

class _YearChips extends StatelessWidget {
  final int? value;
  final List<int> years;
  final ValueChanged<int?> onChanged;

  const _YearChips({
    required this.value,
    required this.years,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'Non définie',
          selected: value == null,
          onTap: () => onChanged(null),
        ),
        for (final y in years)
          _Chip(
            label: '$y',
            selected: value == y,
            onTap: () => onChanged(y),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PreviousGardenDropdown extends StatelessWidget {
  final int? value;
  final List<Garden> candidates;
  final ValueChanged<int?> onChanged;

  const _PreviousGardenDropdown({
    required this.value,
    required this.candidates,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Aucun autre potager disponible.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<int?>(
        value: value,
        hint: Text(
          'Aucun',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem<int?>(
            value: null,
            child: Text(
              'Aucun',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          for (final g in candidates)
            DropdownMenuItem<int?>(
              value: g.id,
              child: Text(
                g.year != null ? '${g.name} (${g.year})' : g.name,
                style: AppTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
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

/// Section "Démarrer avec un modèle" en haut du formulaire de création.
/// Affiche un carrousel horizontal de templates pré-faits + une carte
/// "Personnalisé" qui efface la sélection courante.
class _TemplatesSection extends ConsumerWidget {
  final GardenTemplate? selectedTemplate;
  final ValueChanged<GardenTemplate> onTemplateSelected;
  final VoidCallback onCustomSelected;

  const _TemplatesSection({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.onCustomSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(gardenTemplatesProvider);
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              loc.templatesSectionTitle,
              style: AppTypography.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          loc.templatesSectionSubtitle,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 154,
          child: templatesAsync.when(
            loading: () => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (templates) => ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CustomTemplateCard(
                    selected: selectedTemplate == null,
                    onTap: onCustomSelected,
                  );
                }
                final template = templates[index - 1];
                return _TemplateCard(
                  template: template,
                  selected: selectedTemplate?.id == template.id,
                  onTap: () => onTemplateSelected(template),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final GardenTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 168,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(template.emoji,
                      style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.templateCardDimensions(
                  template.widthMeters.toStringAsFixed(1),
                  template.heightMeters.toStringAsFixed(1),
                  template.plants.length,
                ),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  template.level,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomTemplateCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CustomTemplateCard({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 124,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                size: 32,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.templateCustomTitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.templateCustomSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sélecteur de taille de cellule (précision de la grille). Chips
/// horizontales avec 5 valeurs prédéfinies, du plus précis au plus
/// lisible. Plus la cellule est petite, plus l'utilisateur peut placer
/// finement les plantes (et plus les avertissements d'antagonisme se
/// déclenchent au bon endroit).
///
/// Quand un template est sélectionné, le _State force la valeur sur
/// celle du template — la cellule reste cohérente avec les coords
/// pré-définies de ses plantes.
class _CellSizeSelector extends StatelessWidget {
  static const _values = <int>[5, 10, 15, 30, 50];

  final int value;
  final ValueChanged<int> onChanged;

  const _CellSizeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.gardenCellSizeTitle, style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          loc.gardenCellSizeSubtitle,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final v in _values) ...[
              Expanded(
                child: _CellSizeChip(
                  value: v,
                  selected: v == value,
                  onTap: () => onChanged(v),
                ),
              ),
              if (v != _values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.gardenCellSizeHintFine,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
            Text(
              loc.gardenCellSizeHintCoarse,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CellSizeChip extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _CellSizeChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              loc.gardenCellSizeValue(value),
              style: AppTypography.labelMedium.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

