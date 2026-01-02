import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/garden_providers.dart';
import '../widgets/garden_grid.dart';
import '../widgets/add_element_sheet.dart';
import '../widgets/edit_element_sheet.dart';

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
  bool _isLocked = true;
  bool _initialized = false;

  @override
  void dispose() {
    _transformController.dispose();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddElementSheet(
        garden: garden,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditElementSheet(
        element: element,
        garden: garden,
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
    setState(() => _currentScale = newScale);
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
                      constrained:
                          false, // IMPORTANT: permet à la grille d'être plus grande que l'écran
                      boundaryMargin: const EdgeInsets.all(1000),
                      onInteractionUpdate: (details) {
                        setState(
                          () => _currentScale = _transformController.value
                              .getMaxScaleOnAxis(),
                        );
                      },
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

              // Contrôles zoom
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '${(_currentScale * 100).round()}%',
                        style: AppTypography.caption,
                      ),
                    ),
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
