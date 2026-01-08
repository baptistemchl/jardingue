import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/garden_providers.dart'; // Contient ZoneType et GardenPlantWithDetails
import '../widgets/garden_grid.dart';

/// Écran d'édition du potager
class GardenEditorScreen extends ConsumerStatefulWidget {
  final int gardenId;

  const GardenEditorScreen({super.key, required this.gardenId});

  @override
  ConsumerState<GardenEditorScreen> createState() => _GardenEditorScreenState();
}

class _GardenEditorScreenState extends ConsumerState<GardenEditorScreen> {
  final TransformationController _transformController =
      TransformationController();
  double _currentScale = 1.0;
  double _displayScale = 1.0; // Scale affiché (mis à jour de façon fluide)
  bool _isLocked = true;
  bool _initialized = false;

  // Timer pour le debounce du scale
  Timer? _scaleDebounceTimer;

  @override
  void dispose() {
    _transformController.dispose();
    _scaleDebounceTimer?.cancel();
    super.dispose();
  }

  void _initializeView(Garden garden, BoxConstraints constraints) {
    if (_initialized) return;
    _initialized = true;

    // Calcul des dimensions du jardin en pixels (kPixelsPerMeter = 100)
    final gardenWidthPx =
        garden.widthCells * garden.cellSizeCm; // en pixels directement
    final gardenHeightPx = garden.heightCells * garden.cellSizeCm;

    // Espace disponible (avec marges)
    final availableWidth = constraints.maxWidth - 32;
    final availableHeight = constraints.maxHeight - 100;

    // Calcul du scale pour que le jardin tienne dans l'écran
    final scaleX = availableWidth / gardenWidthPx;
    final scaleY = availableHeight / gardenHeightPx;
    final fitScale = math.min(scaleX, scaleY);

    // On démarre avec un scale qui montre tout le jardin
    _currentScale = fitScale.clamp(0.05, 2.0);
    _displayScale = _currentScale;

    // Centrer la vue
    final scaledWidth = gardenWidthPx * _currentScale;
    final scaledHeight = gardenHeightPx * _currentScale;
    final dx = (constraints.maxWidth - scaledWidth) / 2;
    final dy = (constraints.maxHeight - scaledHeight) / 2;

    _transformController.value = Matrix4.identity()
      ..translate(dx.clamp(0, double.infinity), dy.clamp(0, double.infinity))
      ..scale(_currentScale);

    setState(() {});
  }

  void _showAddElementSheet(Garden garden) {
    // Calcul des dimensions max du jardin en mètres
    final maxWidthM = garden.widthCells * garden.cellSizeCm / 100.0;
    final maxHeightM = garden.heightCells * garden.cellSizeCm / 100.0;

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EnhancedAddElementSheet(
        garden: garden,
        maxWidthM: maxWidthM,
        maxHeightM: maxHeightM,
        onPlantAdded: (plantId, widthM, heightM) async {
          Navigator.pop(context);
          await ref
              .read(gardenNotifierProvider.notifier)
              .addPlantToGarden(
                gardenId: widget.gardenId,
                plantId: plantId,
                xMeters: 0.1,
                yMeters: 0.1,
                widthMeters: widthM,
                heightMeters: heightM,
              );
        },
        onZoneAdded: (zoneType, widthM, heightM) async {
          Navigator.pop(context);
          await ref
              .read(gardenNotifierProvider.notifier)
              .addZoneToGarden(
                gardenId: widget.gardenId,
                xMeters: 0.1,
                yMeters: 0.1,
                widthMeters: widthM,
                heightMeters: heightM,
                zoneType: zoneType.name,
              );
        },
      ),
    );
  }

  void _showEditElementSheet(GardenPlantWithDetails element, Garden garden) {
    // Calcul des dimensions max du jardin en mètres
    final maxWidthM = garden.widthCells * garden.cellSizeCm / 100.0;
    final maxHeightM = garden.heightCells * garden.cellSizeCm / 100.0;

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EnhancedEditElementSheet(
        element: element,
        garden: garden,
        maxWidthM: maxWidthM,
        maxHeightM: maxHeightM,
        onUpdate: (widthM, heightM) async {
          Navigator.pop(context);
          await ref
              .read(gardenNotifierProvider.notifier)
              .updateElementSize(element.id, widthM, heightM, widget.gardenId);
        },
        onDelete: () async {
          Navigator.pop(context);
          await ref
              .read(gardenNotifierProvider.notifier)
              .removeElement(element.id, widget.gardenId);
        },
      ),
    );
  }

  void _onElementMoved(
    GardenPlantWithDetails element,
    double xMeters,
    double yMeters,
  ) async {
    if (_isLocked) return;
    await ref
        .read(gardenNotifierProvider.notifier)
        .moveElement(element.id, xMeters, yMeters, widget.gardenId);
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.5).clamp(0.05, 5.0);
    _applyScale(newScale);
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.5).clamp(0.05, 5.0);
    _applyScale(newScale);
  }

  void _applyScale(double newScale) {
    final matrix = _transformController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final scaleFactor = newScale / currentScale;
    matrix.scale(scaleFactor);
    _transformController.value = matrix;
    setState(() {
      _currentScale = newScale;
      _displayScale = newScale;
    });
  }

  /// Mise à jour fluide du scale pendant l'interaction
  /// Utilise un debounce pour éviter les rebuilds trop fréquents
  void _onInteractionUpdate(ScaleUpdateDetails details) {
    final newScale = _transformController.value.getMaxScaleOnAxis();

    // Annule le timer précédent
    _scaleDebounceTimer?.cancel();

    // Met à jour le scale affiché avec un léger debounce (16ms ≈ 60fps)
    _scaleDebounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (mounted && (_displayScale - newScale).abs() > 0.001) {
        setState(() {
          _displayScale = newScale;
        });
      }
    });
  }

  /// Mise à jour finale du scale quand l'interaction est terminée
  void _onInteractionEnd(ScaleEndDetails details) {
    _scaleDebounceTimer?.cancel();
    final newScale = _transformController.value.getMaxScaleOnAxis();
    setState(() {
      _currentScale = newScale;
      _displayScale = newScale;
    });
  }

  void _resetView() {
    _initialized = false;
    setState(() {});
  }

  void _toggleLock() {
    setState(() => _isLocked = !_isLocked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isLocked
                  ? PhosphorIcons.lock(PhosphorIconsStyle.fill)
                  : PhosphorIcons.lockOpen(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _isLocked
                  ? 'Éléments verrouillés'
                  : 'Mode édition - Glissez pour déplacer',
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isLocked
            ? AppColors.textSecondary
            : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gardenAsync = ref.watch(gardenByIdProvider(widget.gardenId));
    final plantsAsync = ref.watch(gardenPlantsProvider(widget.gardenId));

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: gardenAsync.whenOrNull(
          data: (garden) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(garden?.name ?? 'Potager', style: AppTypography.titleMedium),
              if (garden != null)
                Text(
                  '${(garden.widthCells * garden.cellSizeCm / 100).toStringAsFixed(1)}m × ${(garden.heightCells * garden.cellSizeCm / 100).toStringAsFixed(1)}m',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleLock,
            icon: Icon(
              _isLocked
                  ? PhosphorIcons.lock(PhosphorIconsStyle.fill)
                  : PhosphorIcons.lockOpen(PhosphorIconsStyle.fill),
              color: _isLocked ? AppColors.textSecondary : AppColors.primary,
            ),
            tooltip: _isLocked ? 'Déverrouiller' : 'Verrouiller',
          ),
          IconButton(
            onPressed: _resetView,
            icon: Icon(PhosphorIcons.arrowsOut(PhosphorIconsStyle.regular)),
            tooltip: 'Réinitialiser vue',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Grille interactive
              gardenAsync.when(
                data: (garden) {
                  if (garden == null) {
                    return const Center(child: Text('Potager introuvable'));
                  }

                  // Initialiser la vue au premier rendu
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _initializeView(garden, constraints);
                  });

                  return plantsAsync.when(
                    data: (elements) => InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.02,
                      maxScale: 10.0,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(1000),
                      // Utilisation de onInteractionUpdate avec debounce
                      onInteractionUpdate: _onInteractionUpdate,
                      // Mise à jour finale à la fin de l'interaction
                      onInteractionEnd: _onInteractionEnd,
                      child: GardenGrid(
                        garden: garden,
                        elements: elements,
                        isLocked: _isLocked,
                        onElementTap: (e) => _showEditElementSheet(e, garden),
                        onElementMoved: _onElementMoved,
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),

              // Indicateur mode édition
              if (!_isLocked)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.pencilSimple(PhosphorIconsStyle.fill),
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Mode édition actif',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Contrôles zoom avec pourcentage fluide
              Positioned(
                right: 16,
                bottom: 200,
                child: Column(
                  children: [
                    _ControlButton(
                      icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                      onTap: _zoomIn,
                    ),
                    const SizedBox(height: 8),
                    // Affichage fluide du pourcentage
                    _ZoomIndicator(scale: _displayScale),
                    const SizedBox(height: 8),
                    _ControlButton(
                      icon: PhosphorIcons.minus(PhosphorIconsStyle.bold),
                      onTap: _zoomOut,
                    ),
                  ],
                ),
              ),

              // Stats
              Positioned(
                left: 16,
                right: 80,
                bottom: 100,
                child:
                    gardenAsync.whenOrNull(
                      data: (garden) {
                        if (garden == null) return null;
                        return plantsAsync.whenOrNull(
                          data: (elements) =>
                              _Stats(garden: garden, elements: elements),
                        );
                      },
                    ) ??
                    const SizedBox.shrink(),
              ),

              // Légende
              Positioned(left: 16, bottom: 160, child: _Legend()),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: gardenAsync.whenOrNull(
          data: (garden) => garden != null
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddElementSheet(garden),
                  backgroundColor: AppColors.primary,
                  icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
                  label: const Text('Ajouter'),
                )
              : null,
        ),
      ),
    );
  }
}

/// Widget pour afficher le pourcentage de zoom de façon fluide
class _ZoomIndicator extends StatelessWidget {
  final double scale;

  const _ZoomIndicator({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text('${(scale * 100).round()}%', style: AppTypography.caption),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final Garden garden;
  final List<GardenPlantWithDetails> elements;

  const _Stats({required this.garden, required this.elements});

  @override
  Widget build(BuildContext context) {
    final plantCount = elements.where((e) => !e.isZone).length;
    final zoneCount = elements.where((e) => e.isZone).length;
    final widthM = garden.widthCells * garden.cellSizeCm / 100.0;
    final heightM = garden.heightCells * garden.cellSizeCm / 100.0;
    final surfaceM2 = widthM * heightM;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatItem(emoji: '📐', value: '${surfaceM2.toStringAsFixed(1)} m²'),
          const SizedBox(width: 12),
          _StatItem(emoji: '🌱', value: '$plantCount plantes'),
          const SizedBox(width: 12),
          _StatItem(emoji: '📦', value: '$zoneCount zones'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;

  const _StatItem({required this.emoji, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Légende',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          _LegendItem(color: const Color(0xFF4CAF50), label: 'Légumes'),
          _LegendItem(color: const Color(0xFF009688), label: 'Aromates'),
          _LegendItem(color: const Color(0xFFE91E63), label: 'Fruits'),
          _LegendItem(color: const Color(0xFF607D8B), label: 'Zones'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// =============================================================================
// WIDGET AMÉLIORÉ POUR LA SAISIE DES DIMENSIONS
// =============================================================================

/// Widget combinant Slider et TextField pour la saisie des dimensions
class _DimensionInput extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _DimensionInput({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_DimensionInput> createState() => _DimensionInputState();
}

class _DimensionInputState extends State<_DimensionInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_DimensionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Met à jour le texte si la valeur change depuis l'extérieur (slider)
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

    if (!_focusNode.hasFocus) {
      // Validation à la perte du focus
      _validateAndApply();
    }
  }

  void _validateAndApply() {
    final text = _controller.text.replaceAll(',', '.');
    final parsed = double.tryParse(text);

    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      _controller.text = clamped.toStringAsFixed(2);
    } else {
      // Remet la valeur précédente si invalide
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label et champ de saisie
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Champ de saisie numérique
            SizedBox(
              width: 80,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
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
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  suffixText: widget.unit,
                  suffixStyle: AppTypography.caption,
                ),
                onSubmitted: (_) => _validateAndApply(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Slider
        Row(
          children: [
            Text(
              '${widget.min.toStringAsFixed(1)}${widget.unit}',
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
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: widget.value.clamp(widget.min, widget.max),
                  min: widget.min,
                  max: widget.max,
                  divisions: ((widget.max - widget.min) * 20).round(),
                  onChanged: (value) {
                    widget.onChanged(value);
                    if (!_isEditing) {
                      _controller.text = value.toStringAsFixed(2);
                    }
                  },
                ),
              ),
            ),
            Text(
              '${widget.max.toStringAsFixed(1)}${widget.unit}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// BOTTOM SHEET AMÉLIORÉE POUR L'AJOUT D'ÉLÉMENTS
// =============================================================================

/// Bottom sheet améliorée pour ajouter des éléments avec limitation aux dimensions du jardin
class _EnhancedAddElementSheet extends StatefulWidget {
  final Garden garden;
  final double maxWidthM;
  final double maxHeightM;
  final Function(int plantId, double widthM, double heightM) onPlantAdded;
  final Function(ZoneType zoneType, double widthM, double heightM) onZoneAdded;

  const _EnhancedAddElementSheet({
    required this.garden,
    required this.maxWidthM,
    required this.maxHeightM,
    required this.onPlantAdded,
    required this.onZoneAdded,
  });

  @override
  State<_EnhancedAddElementSheet> createState() =>
      _EnhancedAddElementSheetState();
}

class _EnhancedAddElementSheetState extends State<_EnhancedAddElementSheet> {
  bool _isAddingZone = false;
  ZoneType _selectedZoneType = ZoneType.greenhouse;
  late double _width;
  late double _height;

  @override
  void initState() {
    super.initState();
    // Valeurs par défaut (1m ou max si le jardin est plus petit)
    _width = math.min(1.0, widget.maxWidthM);
    _height = math.min(1.0, widget.maxHeightM);
  }

  String _getZoneTypeLabel(ZoneType type) {
    return type.label;
  }

  IconData _getZoneTypeIcon(ZoneType type) {
    switch (type) {
      case ZoneType.greenhouse:
        return PhosphorIcons.house(PhosphorIconsStyle.fill);
      case ZoneType.path:
        return PhosphorIcons.path(PhosphorIconsStyle.fill);
      case ZoneType.water:
        return PhosphorIcons.drop(PhosphorIconsStyle.fill);
      case ZoneType.compost:
        return PhosphorIcons.recycle(PhosphorIconsStyle.fill);
      case ZoneType.storage:
        return PhosphorIcons.package(PhosphorIconsStyle.fill);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poignée
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            Text(
              'Ajouter un élément',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Info sur les dimensions max
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.info(PhosphorIconsStyle.fill),
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dimensions max : ${widget.maxWidthM.toStringAsFixed(1)}m × ${widget.maxHeightM.toStringAsFixed(1)}m',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Toggle Plante / Zone
            Row(
              children: [
                Expanded(
                  child: _ToggleButton(
                    label: 'Plante',
                    icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
                    isSelected: !_isAddingZone,
                    onTap: () => setState(() => _isAddingZone = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ToggleButton(
                    label: 'Zone',
                    icon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                    isSelected: _isAddingZone,
                    onTap: () => setState(() => _isAddingZone = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contenu selon le mode
            if (_isAddingZone) ...[
              // Sélection du type de zone
              Text(
                'Type de zone',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ZoneType.values.map((type) {
                  final isSelected = _selectedZoneType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedZoneType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getZoneTypeIcon(type),
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getZoneTypeLabel(type),
                            style: AppTypography.bodySmall.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Dimensions avec TextField
            _DimensionInput(
              label: 'Largeur',
              value: _width,
              min: 0.1,
              max: widget.maxWidthM,
              unit: 'm',
              onChanged: (value) => setState(() => _width = value),
            ),
            const SizedBox(height: 16),
            _DimensionInput(
              label: 'Hauteur',
              value: _height,
              min: 0.1,
              max: widget.maxHeightM,
              unit: 'm',
              onChanged: (value) => setState(() => _height = value),
            ),
            const SizedBox(height: 24),

            // Bouton de validation
            ElevatedButton(
              onPressed: () {
                if (_isAddingZone) {
                  widget.onZoneAdded(_selectedZoneType, _width, _height);
                } else {
                  // TODO: Ajouter la sélection de plante
                  // Pour l'instant, on utilise un ID fictif
                  widget.onPlantAdded(1, _width, _height);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isAddingZone ? 'Ajouter la zone' : 'Ajouter la plante',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton toggle pour la sélection plante/zone
class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BOTTOM SHEET AMÉLIORÉE POUR L'ÉDITION D'ÉLÉMENTS
// =============================================================================

/// Bottom sheet améliorée pour éditer des éléments avec limitation aux dimensions du jardin
class _EnhancedEditElementSheet extends StatefulWidget {
  final GardenPlantWithDetails element;
  final Garden garden;
  final double maxWidthM;
  final double maxHeightM;
  final Function(double widthM, double heightM) onUpdate;
  final VoidCallback onDelete;

  const _EnhancedEditElementSheet({
    required this.element,
    required this.garden,
    required this.maxWidthM,
    required this.maxHeightM,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_EnhancedEditElementSheet> createState() =>
      _EnhancedEditElementSheetState();
}

class _EnhancedEditElementSheetState extends State<_EnhancedEditElementSheet> {
  late double _width;
  late double _height;

  @override
  void initState() {
    super.initState();
    // Récupérer les dimensions actuelles de l'élément via les méthodes
    final cellSizeCm = widget.garden.cellSizeCm;
    _width = widget.element.widthMeters(cellSizeCm);
    _height = widget.element.heightMeters(cellSizeCm);
  }

  @override
  Widget build(BuildContext context) {
    final isZone = widget.element.isZone;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poignée
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            Text(
              isZone ? 'Modifier la zone' : 'Modifier la plante',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Nom de l'élément
            Text(
              widget.element.name,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Info sur les dimensions max
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.info(PhosphorIconsStyle.fill),
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dimensions max : ${widget.maxWidthM.toStringAsFixed(1)}m × ${widget.maxHeightM.toStringAsFixed(1)}m',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dimensions avec TextField
            _DimensionInput(
              label: 'Largeur',
              value: _width,
              min: 0.1,
              max: widget.maxWidthM,
              unit: 'm',
              onChanged: (value) => setState(() => _width = value),
            ),
            const SizedBox(height: 16),
            _DimensionInput(
              label: 'Hauteur',
              value: _height,
              min: 0.1,
              max: widget.maxHeightM,
              unit: 'm',
              onChanged: (value) => setState(() => _height = value),
            ),
            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                // Bouton supprimer
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Confirmation avant suppression
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmer la suppression'),
                          content: Text(
                            'Voulez-vous vraiment supprimer ${isZone ? "cette zone" : "cette plante"} ?',
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
                    },
                    icon: Icon(
                      PhosphorIcons.trash(PhosphorIconsStyle.fill),
                      size: 18,
                    ),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton enregistrer
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onUpdate(_width, _height),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Enregistrer',
                      style: AppTypography.bodyMedium.copyWith(
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
}
