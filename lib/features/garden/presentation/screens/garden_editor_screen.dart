import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../../../core/providers/database_providers.dart';
import '../widgets/garden_grid.dart';

// =============================================================================
// SYSTÈME D'HISTORIQUE POUR UNDO/REDO
// =============================================================================

/// Représente une action qui peut être annulée/refaite
abstract class GardenAction {
  Future<void> execute(GardenNotifier notifier);

  Future<void> undo(GardenNotifier notifier);

  String get description;
}

/// Action de déplacement d'un élément
class MoveElementAction extends GardenAction {
  final int elementId;
  final int gardenId;
  final double oldX, oldY;
  final double newX, newY;

  MoveElementAction({
    required this.elementId,
    required this.gardenId,
    required this.oldX,
    required this.oldY,
    required this.newX,
    required this.newY,
  });

  @override
  Future<void> execute(GardenNotifier notifier) async {
    await notifier.moveElement(elementId, newX, newY, gardenId);
  }

  @override
  Future<void> undo(GardenNotifier notifier) async {
    await notifier.moveElement(elementId, oldX, oldY, gardenId);
  }

  @override
  String get description => 'Déplacement';
}

/// Action de suppression d'un élément
class DeleteElementAction extends GardenAction {
  final int elementId;
  final int gardenId;

  final bool isZone;
  final int? plantId;
  final String zoneType;

  final double xMeters;
  final double yMeters;
  final double widthMeters;
  final double heightMeters;

  DeleteElementAction({
    required this.elementId,
    required this.gardenId,
    required this.isZone,
    required this.plantId,
    required this.zoneType,
    required this.xMeters,
    required this.yMeters,
    required this.widthMeters,
    required this.heightMeters,
  });

  @override
  Future<void> execute(GardenNotifier notifier) async {
    await notifier.removeElement(elementId, gardenId);
  }

  @override
  Future<void> undo(GardenNotifier notifier) async {
    if (isZone) {
      await notifier.addZoneToGarden(
        gardenId: gardenId,
        xMeters: xMeters,
        yMeters: yMeters,
        widthMeters: widthMeters,
        heightMeters: heightMeters,
        zoneType: zoneType,
      );
      return;
    }

    await notifier.addPlantToGarden(
      gardenId: gardenId,
      plantId: plantId!,
      xMeters: xMeters,
      yMeters: yMeters,
      widthMeters: widthMeters,
      heightMeters: heightMeters,
    );
  }

  @override
  String get description => 'Suppression';
}

/// Action de redimensionnement d'un élément
class ResizeElementAction extends GardenAction {
  final int elementId;
  final int gardenId;
  final double oldWidth, oldHeight;
  final double newWidth, newHeight;

  ResizeElementAction({
    required this.elementId,
    required this.gardenId,
    required this.oldWidth,
    required this.oldHeight,
    required this.newWidth,
    required this.newHeight,
  });

  @override
  Future<void> execute(GardenNotifier notifier) async {
    await notifier.updateElementSize(elementId, newWidth, newHeight, gardenId);
  }

  @override
  Future<void> undo(GardenNotifier notifier) async {
    await notifier.updateElementSize(elementId, oldWidth, oldHeight, gardenId);
  }

  @override
  String get description => 'Redimensionnement';
}

/// Gestionnaire d'historique pour les actions
class ActionHistory extends ChangeNotifier {
  final List<GardenAction> _undoStack = [];
  final List<GardenAction> _redoStack = [];
  static const int maxHistory = 50;

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;

  int get redoCount => _redoStack.length;

  void addAction(GardenAction action) {
    _undoStack.add(action);
    _redoStack.clear();
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    notifyListeners();
  }

  GardenAction? popUndo() {
    if (_undoStack.isEmpty) return null;
    final action = _undoStack.removeLast();
    _redoStack.add(action);
    notifyListeners();
    return action;
  }

  GardenAction? popRedo() {
    if (_redoStack.isEmpty) return null;
    final action = _redoStack.removeLast();
    _undoStack.add(action);
    notifyListeners();
    return action;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}

// =============================================================================
// ÉCRAN PRINCIPAL DE L'ÉDITEUR
// =============================================================================

class GardenEditorScreen extends ConsumerStatefulWidget {
  final int gardenId;

  const GardenEditorScreen({super.key, required this.gardenId});

  @override
  ConsumerState<GardenEditorScreen> createState() => _GardenEditorScreenState();
}

class _GardenEditorScreenState extends ConsumerState<GardenEditorScreen> {
  final TransformationController _transformController =
      TransformationController();
  final ActionHistory _actionHistory = ActionHistory();

  double _currentScale = 1.0;
  double _displayScale = 1.0;
  bool _isLocked = true;
  bool _initialized = false;

  Timer? _scaleDebounceTimer;

  @override
  void initState() {
    super.initState();
    _actionHistory.addListener(_onHistoryChanged);
  }

  @override
  void dispose() {
    _transformController.dispose();
    _scaleDebounceTimer?.cancel();
    _actionHistory.removeListener(_onHistoryChanged);
    _actionHistory.dispose();
    super.dispose();
  }

  void _onHistoryChanged() {
    if (mounted) setState(() {});
  }

  void _initializeView(Garden garden, BoxConstraints constraints) {
    if (_initialized) return;
    _initialized = true;

    final gardenWidthPx = garden.widthCells * garden.cellSizeCm;
    final gardenHeightPx = garden.heightCells * garden.cellSizeCm;

    final availableWidth = constraints.maxWidth - 32;
    final availableHeight = constraints.maxHeight - 100;

    final scaleX = availableWidth / gardenWidthPx;
    final scaleY = availableHeight / gardenHeightPx;
    final fitScale = math.min(scaleX, scaleY);

    _currentScale = fitScale;
    _displayScale = _currentScale;

    final scaledWidth = gardenWidthPx * _currentScale;
    final scaledHeight = gardenHeightPx * _currentScale;
    final dx = (constraints.maxWidth - scaledWidth) / 2;
    final dy = (constraints.maxHeight - scaledHeight) / 2;

    _transformController.value = Matrix4.identity()
      ..translate(dx.clamp(0, double.infinity), dy.clamp(0, double.infinity))
      ..scale(_currentScale);

    setState(() {});
  }

  // ============================================
  // UNDO / REDO
  // ============================================

  Future<void> _undo() async {
    if (!_actionHistory.canUndo) return;

    final action = _actionHistory.popUndo();
    if (action != null) {
      await action.undo(ref.read(gardenNotifierProvider.notifier));
      _showActionFeedback('↩️ Annulé : ${action.description}');
    }
  }

  Future<void> _redo() async {
    if (!_actionHistory.canRedo) return;

    final action = _actionHistory.popRedo();
    if (action != null) {
      await action.execute(ref.read(gardenNotifierProvider.notifier));
      _showActionFeedback('↪️ Rétabli : ${action.description}');
    }
  }

  void _showActionFeedback(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textSecondary,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
  }

  // ============================================
  // GESTION DES ÉLÉMENTS AVEC HISTORIQUE
  // ============================================

  Future<void> _onElementMoved(
    GardenPlantWithDetails element,
    double newXMeters,
    double newYMeters,
    int cellSizeCm,
  ) async {
    if (_isLocked) return;

    final action = MoveElementAction(
      elementId: element.id,
      gardenId: widget.gardenId,
      oldX: element.xMeters(cellSizeCm),
      oldY: element.yMeters(cellSizeCm),
      newX: newXMeters,
      newY: newYMeters,
    );

    await action.execute(ref.read(gardenNotifierProvider.notifier));
    _actionHistory.addAction(action);
  }

  Future<void> _deleteElement(
    GardenPlantWithDetails element,
    int cellSizeCm,
  ) async {
    final action = DeleteElementAction(
      elementId: element.id,
      gardenId: widget.gardenId,
      isZone: element.isZone,
      plantId: element.id,
      zoneType: element.zoneType.toString(),
      xMeters: element.xMeters(cellSizeCm),
      yMeters: element.yMeters(cellSizeCm),
      widthMeters: element.widthMeters(cellSizeCm),
      heightMeters: element.heightMeters(cellSizeCm),
    );

    await action.execute(ref.read(gardenNotifierProvider.notifier));
    _actionHistory.addAction(action);
  }

  Future<void> _resizeElement(
    GardenPlantWithDetails element,
    double newWidth,
    double newHeight,
    int cellSizeCm,
  ) async {
    final action = ResizeElementAction(
      elementId: element.id,
      gardenId: widget.gardenId,
      oldWidth: element.widthMeters(cellSizeCm),
      oldHeight: element.heightMeters(cellSizeCm),
      newWidth: newWidth,
      newHeight: newHeight,
    );

    await action.execute(ref.read(gardenNotifierProvider.notifier));
    _actionHistory.addAction(action);
  }

  // ============================================
  // ZOOM - SANS LIMITES BLOQUANTES
  // ============================================

  void _zoomIn() {
    final newScale = _currentScale * 1.5;
    _applyScale(newScale);
  }

  void _zoomOut() {
    // Pas de limite basse restrictive
    final newScale = _currentScale / 1.5;
    _applyScale(newScale);
  }

  void _applyScale(double newScale) {
    // Seule limite : éviter les valeurs négatives ou trop petites pour le rendu
    if (newScale < 0.001) newScale = 0.001;
    if (newScale > 100) newScale = 100; // Limite haute raisonnable

    final matrix = _transformController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    if (currentScale <= 0) return;

    final scaleFactor = newScale / currentScale;
    matrix.scale(scaleFactor);
    _transformController.value = matrix;

    setState(() {
      _currentScale = newScale;
      _displayScale = newScale;
    });
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    final newScale = _transformController.value.getMaxScaleOnAxis();

    _scaleDebounceTimer?.cancel();
    _scaleDebounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (mounted && (_displayScale - newScale).abs() > 0.001) {
        setState(() => _displayScale = newScale);
      }
    });
  }

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

  // ============================================
  // VERROUILLAGE - PLUS INTUITIF
  // ============================================

  void _toggleLock() {
    setState(() => _isLocked = !_isLocked);
    HapticFeedback.mediumImpact();
  }

  // ============================================
  // BOTTOM SHEETS
  // ============================================

  void _showAddElementSheet(Garden garden) {
    final maxWidthM = garden.widthCells * garden.cellSizeCm / 100.0;
    final maxHeightM = garden.heightCells * garden.cellSizeCm / 100.0;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EnhancedAddElementSheet(
        garden: garden,
        maxWidthM: maxWidthM,
        maxHeightM: maxHeightM,
        onPlantAdded: (plantId, widthM, heightM) async {
          Navigator.of(sheetContext, rootNavigator: true).pop();
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
          Navigator.of(sheetContext, rootNavigator: true).pop();
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
    final maxWidthM = garden.widthCells * garden.cellSizeCm / 100.0;
    final maxHeightM = garden.heightCells * garden.cellSizeCm / 100.0;

    if (!element.isZone && element.plant != null) {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _PlantDetailSheet(
          element: element,
          garden: garden,
          maxWidthM: maxWidthM,
          maxHeightM: maxHeightM,
          onUpdate: (widthM, heightM) async {
            Navigator.of(sheetContext, rootNavigator: true).pop();
            await _resizeElement(element, widthM, heightM, garden.cellSizeCm);
          },
          onDelete: () async {
            Navigator.of(sheetContext, rootNavigator: true).pop();
            await _deleteElement(element, garden.cellSizeCm);
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _EnhancedEditElementSheet(
          element: element,
          garden: garden,
          maxWidthM: maxWidthM,
          maxHeightM: maxHeightM,
          onUpdate: (widthM, heightM) async {
            Navigator.of(sheetContext, rootNavigator: true).pop();
            await _resizeElement(element, widthM, heightM, garden.cellSizeCm);
          },
          onDelete: () async {
            Navigator.of(sheetContext, rootNavigator: true).pop();
            await _deleteElement(element, garden.cellSizeCm);
          },
        ),
      );
    }
  }

  void _showElementsListSheet(
    Garden garden,
    List<GardenPlantWithDetails> elements,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ElementsListSheet(
        garden: garden,
        elements: elements,
        isLocked: _isLocked,
        onToggleLock: () {
          Navigator.of(sheetContext, rootNavigator: true).pop();
          _toggleLock();
        },
        onElementTap: (element) {
          Navigator.of(sheetContext, rootNavigator: true).pop();
          _showEditElementSheet(element, garden);
        },
        onElementDelete: (element) async {
          await _deleteElement(element, garden.cellSizeCm);
        },
      ),
    );
  }

  // ============================================
  // BUILD
  // ============================================

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
          // Boutons Undo/Redo
          _UndoRedoButtons(
            canUndo: _actionHistory.canUndo,
            canRedo: _actionHistory.canRedo,
            onUndo: _undo,
            onRedo: _redo,
          ),
          // Séparateur
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: AppColors.border,
          ),
          // Bouton liste des éléments
          gardenAsync.whenOrNull(
                data: (garden) => garden != null
                    ? plantsAsync.whenOrNull(
                        data: (elements) => IconButton(
                          onPressed: () =>
                              _showElementsListSheet(garden, elements),
                          icon: Stack(
                            children: [
                              Icon(
                                PhosphorIcons.list(PhosphorIconsStyle.bold),
                                color: AppColors.textPrimary,
                              ),
                              if (elements.isNotEmpty)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 14,
                                      minHeight: 14,
                                    ),
                                    child: Text(
                                      '${elements.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          tooltip: 'Liste des éléments',
                        ),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
          // Bouton réinitialiser vue
          IconButton(
            onPressed: _resetView,
            icon: Icon(PhosphorIcons.arrowsOut(PhosphorIconsStyle.regular)),
            tooltip: 'Réinitialiser la vue',
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

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _initializeView(garden, constraints);
                  });

                  return plantsAsync.when(
                    data: (elements) => InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.001,
                      // Zoom quasi illimité
                      maxScale: 100.0,
                      // Zoom max très élevé
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(5000),
                      onInteractionUpdate: _onInteractionUpdate,
                      onInteractionEnd: _onInteractionEnd,
                      child: GardenGrid(
                        garden: garden,
                        elements: elements,
                        isLocked: _isLocked,
                        onElementTap: (e) => _showEditElementSheet(e, garden),
                        onElementMoved: (e, xM, yM) =>
                            _onElementMoved(e, xM, yM, garden.cellSizeCm),
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

              // Bouton de verrouillage amélioré (en haut, centré)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: Center(
                  child: _LockToggleButton(
                    isLocked: _isLocked,
                    onToggle: _toggleLock,
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
                      tooltip: 'Zoom +',
                    ),
                    const SizedBox(height: 8),
                    _ZoomIndicator(scale: _displayScale),
                    const SizedBox(height: 8),
                    _ControlButton(
                      icon: PhosphorIcons.minus(PhosphorIconsStyle.bold),
                      onTap: _zoomOut,
                      tooltip: 'Zoom -',
                    ),
                  ],
                ),
              ),

              // Stats - centrées en bas
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
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
              ),

              // Légende
              Positioned(left: 16, bottom: 80, child: _Legend()),
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

// =============================================================================
// BOUTONS UNDO/REDO
// =============================================================================

class _UndoRedoButtons extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const _UndoRedoButtons({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton Annuler
        Tooltip(
          message: canUndo ? 'Annuler' : 'Rien à annuler',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canUndo ? onUndo : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.arrowUUpLeft(PhosphorIconsStyle.bold),
                      size: 20,
                      color: canUndo
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Bouton Rétablir
        Tooltip(
          message: canRedo ? 'Rétablir' : 'Rien à rétablir',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canRedo ? onRedo : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.arrowUUpRight(PhosphorIconsStyle.bold),
                      size: 20,
                      color: canRedo
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// BOUTON DE VERROUILLAGE AMÉLIORÉ
// =============================================================================

class _LockToggleButton extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onToggle;

  const _LockToggleButton({required this.isLocked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isLocked ? AppColors.surface : AppColors.primary,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isLocked ? AppColors.border : AppColors.primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isLocked ? Colors.black : AppColors.primary).withValues(
                alpha: 0.15,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône animée
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isLocked
                    ? PhosphorIcons.lock(PhosphorIconsStyle.fill)
                    : PhosphorIcons.pencilSimple(PhosphorIconsStyle.fill),
                key: ValueKey(isLocked),
                size: 18,
                color: isLocked ? AppColors.textSecondary : Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            // Texte principal
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isLocked ? 'Verrouillé' : 'Mode édition',
                key: ValueKey(isLocked),
                style: AppTypography.labelMedium.copyWith(
                  color: isLocked ? AppColors.textSecondary : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Badge d'indication
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isLocked
                    ? AppColors.textTertiary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isLocked ? 'Appuyer pour éditer' : 'Déplacez les éléments',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: isLocked
                      ? AppColors.textTertiary
                      : Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGETS ZOOM ET CONTRÔLES
// =============================================================================

class _ZoomIndicator extends StatelessWidget {
  final double scale;

  const _ZoomIndicator({required this.scale});

  @override
  Widget build(BuildContext context) {
    // Formatage intelligent du pourcentage
    String percentText;
    final percent = scale * 100;
    if (percent < 1) {
      percentText = '${percent.toStringAsFixed(2)}%';
    } else if (percent < 10) {
      percentText = '${percent.toStringAsFixed(1)}%';
    } else if (percent > 1000) {
      percentText = '${(percent / 1000).toStringAsFixed(1)}k%';
    } else {
      percentText = '${percent.round()}%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        percentText,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _ControlButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
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

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

// =============================================================================
// STATISTIQUES
// =============================================================================

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

// =============================================================================
// LÉGENDE
// =============================================================================

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
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
class _EnhancedAddElementSheet extends ConsumerStatefulWidget {
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
  ConsumerState<_EnhancedAddElementSheet> createState() =>
      _EnhancedAddElementSheetState();
}

class _EnhancedAddElementSheetState
    extends ConsumerState<_EnhancedAddElementSheet> {
  // 0 = choix type, 1 = sélection plante, 2 = config dimensions
  int _step = 0;
  bool _isAddingZone = false;
  ZoneType _selectedZoneType = ZoneType.greenhouse;
  Plant? _selectedPlant;
  late double _width;
  late double _height;

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Valeurs par défaut (1m ou max si le jardin est plus petit)
    _width = math.min(1.0, widget.maxWidthM);
    _height = math.min(1.0, widget.maxHeightM);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(plantsFilterProvider.notifier).setSearchQuery(value);
    });
  }

  void _selectPlant(Plant plant) {
    setState(() {
      _selectedPlant = plant;
      // Adapter les dimensions selon l'espacement recommandé
      if (plant.spacingBetweenPlants != null &&
          plant.spacingBetweenPlants! > 0) {
        final spacingM = plant.spacingBetweenPlants! / 100.0;
        _width = spacingM.clamp(0.1, widget.maxWidthM);
        _height = spacingM.clamp(0.1, widget.maxHeightM);
      } else {
        _width = math.min(0.3, widget.maxWidthM);
        _height = math.min(0.3, widget.maxHeightM);
      }
      _step = 2; // Passer aux dimensions
    });
  }

  void _selectZone(ZoneType type) {
    setState(() {
      _selectedZoneType = type;
      _isAddingZone = true;
      _width = math.min(1.0, widget.maxWidthM);
      _height = math.min(1.0, widget.maxHeightM);
      _step = 2; // Passer aux dimensions
    });
  }

  String _getZoneTypeLabel(ZoneType type) {
    return type.label;
  }

  String _getPlantEmoji(Plant plant) {
    final name = plant.commonName.toLowerCase();
    const map = {
      'tomate': '🍅',
      'carotte': '🥕',
      'salade': '🥬',
      'laitue': '🥬',
      'poivron': '🫑',
      'aubergine': '🍆',
      'courgette': '🥒',
      'concombre': '🥒',
      'haricot': '🫘',
      'petit pois': '🫛',
      'pois': '🫛',
      'radis': '🔴',
      'betterave': '🔴',
      'oignon': '🧅',
      'ail': '🧄',
      'pomme de terre': '🥔',
      'patate': '🥔',
      'chou': '🥬',
      'brocoli': '🥦',
      'épinard': '🥬',
      'fraise': '🍓',
      'framboise': '🫐',
      'myrtille': '🫐',
      'basilic': '🌿',
      'persil': '🌿',
      'menthe': '🌿',
      'thym': '🌿',
      'romarin': '🌿',
      'ciboulette': '🌿',
      'maïs': '🌽',
      'tournesol': '🌻',
      'citrouille': '🎃',
      'potiron': '🎃',
      'melon': '🍈',
      'pastèque': '🉐',
    };
    for (final entry in map.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _step == 1 ? MediaQuery.of(context).size.height * 0.85 : null,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: _step == 1 ? 20 : MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: _step == 1 ? _buildPlantSelection() : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
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

          // Header avec retour si step > 0
          Row(
            children: [
              if (_step > 0)
                IconButton(
                  onPressed: () => setState(() => _step = 0),
                  icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (_step > 0) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _step == 0
                      ? 'Ajouter un élément'
                      : (_isAddingZone
                            ? 'Configurer la zone'
                            : 'Configurer la plante'),
                  style: AppTypography.titleMedium,
                  textAlign: _step == 0 ? TextAlign.center : TextAlign.left,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_step == 0) ...[
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

            // Bouton Ajouter une plante
            _SelectionCard(
              icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
              title: 'Ajouter une plante',
              subtitle: 'Choisir parmi 200+ variétés',
              color: AppColors.primary,
              onTap: () => setState(() {
                _isAddingZone = false;
                _step = 1;
              }),
            ),
            const SizedBox(height: 12),

            // Section Zones
            Text(
              'Ou ajouter une zone',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ZoneType.values.map((type) {
                return GestureDetector(
                  onTap: () => _selectZone(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Color(type.color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(type.color).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          _getZoneTypeLabel(type),
                          style: AppTypography.bodySmall.copyWith(
                            color: Color(type.color),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (_step == 2) ...[
            // Afficher l'élément sélectionné
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isAddingZone
                          ? Color(
                              _selectedZoneType.color,
                            ).withValues(alpha: 0.2)
                          : AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _isAddingZone
                            ? _selectedZoneType.emoji
                            : (_selectedPlant != null
                                  ? _getPlantEmoji(_selectedPlant!)
                                  : '🌱'),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAddingZone
                              ? _getZoneTypeLabel(_selectedZoneType)
                              : (_selectedPlant?.commonName ?? 'Plante'),
                          style: AppTypography.titleSmall,
                        ),
                        if (!_isAddingZone && _selectedPlant?.latinName != null)
                          Text(
                            _selectedPlant!.latinName!,
                            style: AppTypography.caption.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _step = _isAddingZone ? 0 : 1),
                    child: const Text('Changer'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dimensions
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
              label: 'Longueur',
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
                } else if (_selectedPlant != null) {
                  widget.onPlantAdded(_selectedPlant!.id, _width, _height);
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
        ],
      ),
    );
  }

  Widget _buildPlantSelection() {
    final plantsAsync = ref.watch(filteredPlantsProvider);

    return Column(
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

        // Header
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _step = 0),
              icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Choisir une plante',
                style: AppTypography.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Barre de recherche
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Rechercher une plante...',
            prefixIcon: Icon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Liste des plantes
        Expanded(
          child: plantsAsync.when(
            data: (plants) {
              if (plants.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.plant(PhosphorIconsStyle.duotone),
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune plante trouvée',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: plants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  return _PlantListItem(
                    plant: plant,
                    emoji: _getPlantEmoji(plant),
                    onTap: () => _selectPlant(plant),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
          ),
        ),
      ],
    );
  }
}

/// Carte de sélection pour le choix initial
class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(color: color),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Item de plante dans la liste
class _PlantListItem extends StatelessWidget {
  final Plant plant;
  final String emoji;
  final VoidCallback onTap;

  const _PlantListItem({
    required this.plant,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.commonName,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (plant.latinName != null)
                    Text(
                      plant.latinName!,
                      style: AppTypography.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (plant.categoryLabel != null)
                        _MiniChip(label: plant.categoryLabel!),
                      if (plant.spacingBetweenPlants != null) ...[
                        const SizedBox(width: 6),
                        _MiniChip(label: '${plant.spacingBetweenPlants}cm'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.plus(PhosphorIconsStyle.bold),
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 10,
          color: AppColors.textSecondary,
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

            // Nom de l'élément avec emoji
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
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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
              label: 'Longueur',
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

// =============================================================================
// BOTTOM SHEET POUR LA LISTE DES ÉLÉMENTS
// =============================================================================

/// Bottom sheet affichant la liste de tous les éléments du jardin
class _ElementsListSheet extends StatelessWidget {
  final Garden garden;
  final List<GardenPlantWithDetails> elements;
  final bool isLocked;
  final VoidCallback onToggleLock;
  final Function(GardenPlantWithDetails) onElementTap;
  final Function(GardenPlantWithDetails) onElementDelete;

  const _ElementsListSheet({
    required this.garden,
    required this.elements,
    required this.isLocked,
    required this.onToggleLock,
    required this.onElementTap,
    required this.onElementDelete,
  });

  @override
  Widget build(BuildContext context) {
    final plants = elements.where((e) => !e.isZone).toList();
    final zones = elements.where((e) => e.isZone).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Poignée
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

          // Header avec bouton lock
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Éléments du potager',
                    style: AppTypography.titleLarge,
                  ),
                ),
                // Bouton lock/unlock
                GestureDetector(
                  onTap: onToggleLock,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? AppColors.textSecondary.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLocked
                            ? AppColors.textSecondary.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLocked
                              ? PhosphorIcons.lock(PhosphorIconsStyle.fill)
                              : PhosphorIcons.lockOpen(PhosphorIconsStyle.fill),
                          size: 16,
                          color: isLocked
                              ? AppColors.textSecondary
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isLocked ? 'Verrouillé' : 'Déverrouillé',
                          style: AppTypography.caption.copyWith(
                            color: isLocked
                                ? AppColors.textSecondary
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                ),
              ],
            ),
          ),

          const Divider(),

          // Contenu
          Expanded(
            child: elements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.plant(PhosphorIconsStyle.duotone),
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun élément',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ajoutez des plantes ou des zones',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Section Plantes
                      if (plants.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Plantes',
                          count: plants.length,
                          emoji: '🌱',
                        ),
                        const SizedBox(height: 8),
                        ...plants.map(
                          (e) => _ElementListItem(
                            element: e,
                            garden: garden,
                            onTap: () => onElementTap(e),
                            onDelete: () => onElementDelete(e),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section Zones
                      if (zones.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Zones',
                          count: zones.length,
                          emoji: '📦',
                        ),
                        const SizedBox(height: 8),
                        ...zones.map(
                          (e) => _ElementListItem(
                            element: e,
                            garden: garden,
                            onTap: () => onElementTap(e),
                            onDelete: () => onElementDelete(e),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final String emoji;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ElementListItem extends StatelessWidget {
  final GardenPlantWithDetails element;
  final Garden garden;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ElementListItem({
    required this.element,
    required this.garden,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(element.color);
    final cellSize = garden.cellSizeCm;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Emoji
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    element.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${element.widthMeters(cellSize).toStringAsFixed(2)}m × ${element.heightMeters(cellSize).toStringAsFixed(2)}m',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Bouton supprimer
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer ?'),
                      content: Text(
                        'Voulez-vous supprimer "${element.name}" ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDelete();
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
                  PhosphorIcons.trash(PhosphorIconsStyle.regular),
                  size: 20,
                  color: AppColors.error,
                ),
              ),

              // Flèche
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// BOTTOM SHEET DÉTAILLÉE POUR LES PLANTES
// =============================================================================

/// Bottom sheet affichant les détails complets d'une plante avec options d'édition
class _PlantDetailSheet extends ConsumerStatefulWidget {
  final GardenPlantWithDetails element;
  final Garden garden;
  final double maxWidthM;
  final double maxHeightM;
  final Function(double widthM, double heightM) onUpdate;
  final VoidCallback onDelete;

  const _PlantDetailSheet({
    required this.element,
    required this.garden,
    required this.maxWidthM,
    required this.maxHeightM,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  ConsumerState<_PlantDetailSheet> createState() => _PlantDetailSheetState();
}

class _PlantDetailSheetState extends ConsumerState<_PlantDetailSheet> {
  late double _width;
  late double _height;
  bool _showSizeEditor = false;

  @override
  void initState() {
    super.initState();
    final cellSizeCm = widget.garden.cellSizeCm;
    _width = widget.element.widthMeters(cellSizeCm);
    _height = widget.element.heightMeters(cellSizeCm);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.element.plant!;
    final companionsAsync = ref.watch(plantCompanionsProvider(plant.id));
    final antagonistsAsync = ref.watch(plantAntagonistsProvider(plant.id));
    final cellSize = widget.garden.cellSizeCm;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
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

              // Contenu scrollable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header plante
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Color(
                              widget.element.color,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              widget.element.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plant.commonName,
                                style: AppTypography.titleLarge,
                              ),
                              if (plant.latinName != null)
                                Text(
                                  plant.latinName!,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (plant.categoryLabel != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    plant.categoryLabel!,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Position et dimensions dans le potager
                    _DetailInfoCard(
                      title: 'Dans le potager',
                      icon: PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                      trailing: IconButton(
                        onPressed: () =>
                            setState(() => _showSizeEditor = !_showSizeEditor),
                        icon: Icon(
                          _showSizeEditor
                              ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold)
                              : PhosphorIcons.pencilSimple(
                                  PhosphorIconsStyle.regular,
                                ),
                          size: 18,
                          color: AppColors.primary,
                        ),
                        tooltip: 'Modifier les dimensions',
                      ),
                      children: [
                        _DetailInfoRow(
                          label: 'Position',
                          value:
                              '${widget.element.xMeters(cellSize).toStringAsFixed(2)}m × ${widget.element.yMeters(cellSize).toStringAsFixed(2)}m',
                        ),
                        _DetailInfoRow(
                          label: 'Dimensions',
                          value:
                              '${_width.toStringAsFixed(2)}m × ${_height.toStringAsFixed(2)}m',
                        ),
                        if (widget.element.plantedAt != null)
                          _DetailInfoRow(
                            label: 'Planté le',
                            value: _formatDate(widget.element.plantedAt!),
                          ),
                        // Éditeur de taille
                        if (_showSizeEditor) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          _DimensionInput(
                            label: 'Largeur',
                            value: _width,
                            min: 0.1,
                            max: widget.maxWidthM,
                            unit: 'm',
                            onChanged: (value) =>
                                setState(() => _width = value),
                          ),
                          const SizedBox(height: 12),
                          _DimensionInput(
                            label: 'Longueur',
                            value: _height,
                            min: 0.1,
                            max: widget.maxHeightM,
                            unit: 'm',
                            onChanged: (value) =>
                                setState(() => _height = value),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => widget.onUpdate(_width, _height),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Enregistrer les dimensions'),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Culture
                    _DetailInfoCard(
                      title: 'Culture',
                      icon: PhosphorIcons.plant(PhosphorIconsStyle.fill),
                      children: [
                        if (plant.spacingBetweenPlants != null)
                          _DetailInfoRow(
                            label: 'Espacement recommandé',
                            value: '${plant.spacingBetweenPlants} cm',
                          ),
                        if (plant.plantingDepthCm != null)
                          _DetailInfoRow(
                            label: 'Profondeur de plantation',
                            value: '${plant.plantingDepthCm} cm',
                          ),
                        if (plant.sunExposure != null)
                          _DetailInfoRow(
                            label: 'Exposition',
                            value: plant.sunExposure!,
                          ),
                        if (plant.watering != null)
                          _DetailInfoRow(
                            label: 'Arrosage',
                            value: plant.watering!,
                          ),
                        if (plant.soilType != null)
                          _DetailInfoRow(
                            label: 'Type de sol',
                            value: plant.soilType!,
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Périodes
                    if (plant.sowingRecommendation != null ||
                        plant.harvestPeriod != null)
                      _DetailInfoCard(
                        title: 'Calendrier',
                        icon: PhosphorIcons.calendar(PhosphorIconsStyle.fill),
                        children: [
                          if (plant.sowingRecommendation != null)
                            _DetailInfoRow(
                              label: 'Semis',
                              value: plant.sowingRecommendation!,
                            ),
                          if (plant.harvestPeriod != null)
                            _DetailInfoRow(
                              label: 'Récolte',
                              value: plant.harvestPeriod!,
                            ),
                        ],
                      ),

                    if (plant.sowingRecommendation != null ||
                        plant.harvestPeriod != null)
                      const SizedBox(height: 16),

                    // Compagnons
                    companionsAsync.when(
                      data: (companions) {
                        if (companions.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.handshake(
                                    PhosphorIconsStyle.fill,
                                  ),
                                  size: 18,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bonnes associations',
                                  style: AppTypography.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: companions
                                  .map(
                                    (c) =>
                                        _CompanionChip(plant: c, isGood: true),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Antagonistes
                    antagonistsAsync.when(
                      data: (antagonists) {
                        if (antagonists.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.prohibit(
                                    PhosphorIconsStyle.fill,
                                  ),
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'À éviter à proximité',
                                  style: AppTypography.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: antagonists
                                  .map(
                                    (a) =>
                                        _CompanionChip(plant: a, isGood: false),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Notes
                    if (widget.element.notes != null &&
                        widget.element.notes!.isNotEmpty)
                      _DetailInfoCard(
                        title: 'Notes',
                        icon: PhosphorIcons.notepad(PhosphorIconsStyle.fill),
                        children: [
                          Text(
                            widget.element.notes!,
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Bouton supprimer
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: Icon(
                        PhosphorIcons.trash(PhosphorIconsStyle.regular),
                      ),
                      label: const Text('Retirer du potager'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer cette plante ?'),
        content: Text(
          'Voulez-vous vraiment retirer "${widget.element.name}" du potager ?',
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }
}

// Widgets utilitaires pour le détail des plantes

class _DetailInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const _DetailInfoCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppTypography.titleSmall)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailInfoRow({required this.label, required this.value});

  static const double _minGap = 12;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _minGap),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionChip extends StatelessWidget {
  final Plant plant;
  final bool isGood;

  const _CompanionChip({required this.plant, required this.isGood});

  String get _emoji {
    final name = plant.commonName.toLowerCase();
    const map = {
      'tomate': '🍅',
      'carotte': '🥕',
      'salade': '🥬',
      'laitue': '🥬',
      'poivron': '🫑',
      'aubergine': '🍆',
      'courgette': '🥒',
      'concombre': '🥒',
      'haricot': '🫘',
      'petit pois': '🫛',
      'pois': '🫛',
      'radis': '🔴',
      'betterave': '🔴',
      'oignon': '🧅',
      'ail': '🧄',
      'pomme de terre': '🥔',
      'chou': '🥬',
      'brocoli': '🥦',
      'épinard': '🥬',
      'fraise': '🍓',
      'basilic': '🌿',
      'persil': '🌿',
      'menthe': '🌿',
      'thym': '🌿',
      'romarin': '🌿',
      'maïs': '🌽',
    };
    for (final entry in map.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    final color = isGood ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            plant.commonName,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
