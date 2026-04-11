import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../domain/action_history.dart';
import '../widgets/garden_grid.dart';
import '../widgets/editor/undo_redo_buttons.dart';
import '../widgets/editor/lock_toggle_button.dart';
import '../widgets/editor/zoom_controls.dart';
import '../widgets/editor/editor_stats.dart';
import '../widgets/editor/editor_add_element_sheet.dart';
import '../widgets/editor/editor_edit_element_sheet.dart';
import '../widgets/editor/editor_elements_list_sheet.dart';
import '../widgets/editor/editor_plant_detail_sheet.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

class GardenEditorScreen extends ConsumerStatefulWidget {
  final int gardenId;

  const GardenEditorScreen({
    super.key,
    required this.gardenId,
  });

  @override
  ConsumerState<GardenEditorScreen> createState() =>
      _GardenEditorScreenState();
}

class _GardenEditorScreenState
    extends ConsumerState<GardenEditorScreen> {
  final _transformController =
      TransformationController();
  final _actionHistory = ActionHistory();

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
    _actionHistory
      ..removeListener(_onHistoryChanged)
      ..dispose();
    super.dispose();
  }

  void _onHistoryChanged() {
    if (mounted) setState(() {});
  }

  // ========== Vue / Zoom ==========

  void _initializeView(
    Garden garden,
    BoxConstraints constraints,
  ) {
    if (_initialized) return;
    _initialized = true;

    final gardenW =
        garden.widthCells * garden.cellSizeCm;
    final gardenH =
        garden.heightCells * garden.cellSizeCm;

    final availW = constraints.maxWidth - 32;
    final availH = constraints.maxHeight - 100;

    final fitScale = math.min(
      availW / gardenW,
      availH / gardenH,
    );

    _currentScale = fitScale;
    _displayScale = fitScale;

    final scaledW = gardenW * fitScale;
    final scaledH = gardenH * fitScale;
    final dx = (constraints.maxWidth - scaledW) / 2;
    final dy = (constraints.maxHeight - scaledH) / 2;

    _transformController.value = Matrix4.identity()
      ..translateByDouble(
        dx.clamp(0, double.infinity),
        dy.clamp(0, double.infinity),
        0.0,
        1.0,
      )
      ..scaleByDouble(fitScale, fitScale, fitScale, 1.0);
    setState(() {});
  }

  void _zoomIn() => _applyScale(_currentScale * 1.5);
  void _zoomOut() => _applyScale(_currentScale / 1.5);

  void _applyScale(double newScale) {
    final clamped = newScale.clamp(0.001, 100.0);
    final matrix = _transformController.value.clone();
    final current = matrix.getMaxScaleOnAxis();
    if (current <= 0) return;

    final factor = clamped / current;
    matrix.scaleByDouble(factor, factor, factor, 1.0);
    _transformController.value = matrix;
    setState(() {
      _currentScale = clamped;
      _displayScale = clamped;
    });
  }

  void _onInteractionUpdate(ScaleUpdateDetails _) {
    final newScale =
        _transformController.value.getMaxScaleOnAxis();
    _scaleDebounceTimer?.cancel();
    _scaleDebounceTimer = Timer(
      const Duration(milliseconds: 16),
      () {
        if (mounted &&
            (_displayScale - newScale).abs() > 0.001) {
          setState(() => _displayScale = newScale);
        }
      },
    );
  }

  void _onInteractionEnd(ScaleEndDetails _) {
    _scaleDebounceTimer?.cancel();
    final s =
        _transformController.value.getMaxScaleOnAxis();
    setState(() {
      _currentScale = s;
      _displayScale = s;
    });
  }

  void _resetView() {
    _initialized = false;
    setState(() {});
  }

  // ========== Lock ==========

  void _toggleLock() {
    setState(() => _isLocked = !_isLocked);
    HapticFeedback.mediumImpact();
  }

  // ========== Undo / Redo ==========

  Future<void> _undo() async {
    final action = _actionHistory.popUndo();
    if (action == null) return;
    await action.undo(
      ref.read(gardenNotifierProvider.notifier),
    );
    if (!mounted) return;
    _showFeedback(
      AppLocalizations.of(context)!.undoAction(action.description),
    );
  }

  Future<void> _redo() async {
    final action = _actionHistory.popRedo();
    if (action == null) return;
    await action.execute(
      ref.read(gardenNotifierProvider.notifier),
    );
    if (!mounted) return;
    _showFeedback(
      AppLocalizations.of(context)!.redoAction(action.description),
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textSecondary,
          margin: const EdgeInsets.only(
            bottom: 100,
            left: 16,
            right: 16,
          ),
        ),
      );
  }

  // ========== Element actions ==========

  Future<void> _onElementMoved(
    GardenPlantWithDetails element,
    double newX,
    double newY,
    int cellSizeCm,
  ) async {
    if (_isLocked) return;
    final action = MoveElementAction(
      elementId: element.id,
      gardenId: widget.gardenId,
      oldX: element.xMeters(cellSizeCm),
      oldY: element.yMeters(cellSizeCm),
      newX: newX,
      newY: newY,
    );
    await action.execute(
      ref.read(gardenNotifierProvider.notifier),
    );
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
    await action.execute(
      ref.read(gardenNotifierProvider.notifier),
    );
    _actionHistory.addAction(action);
  }

  Future<void> _resizeElement(
    GardenPlantWithDetails element,
    double newW,
    double newH,
    int cellSizeCm,
  ) async {
    final action = ResizeElementAction(
      elementId: element.id,
      gardenId: widget.gardenId,
      oldWidth: element.widthMeters(cellSizeCm),
      oldHeight: element.heightMeters(cellSizeCm),
      newWidth: newW,
      newHeight: newH,
    );
    await action.execute(
      ref.read(gardenNotifierProvider.notifier),
    );
    _actionHistory.addAction(action);
  }

  // ========== Bottom sheets ==========

  void _showAddSheet(Garden garden) {
    final maxW =
        garden.widthCells * garden.cellSizeCm / 100.0;
    final maxH =
        garden.heightCells * garden.cellSizeCm / 100.0;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditorAddElementSheet(
        garden: garden,
        maxWidthM: maxW,
        maxHeightM: maxH,
        onPlantAdded: (plantId, w, h,
            {sowedAt, plantedAt, wateringFrequencyDays}) async {
          Navigator.of(ctx, rootNavigator: true).pop();
          await ref
              .read(gardenNotifierProvider.notifier)
              .addPlantToGarden(
                gardenId: widget.gardenId,
                plantId: plantId,
                xMeters: 0.1,
                yMeters: 0.1,
                widthMeters: w,
                heightMeters: h,
                sowedAt: sowedAt,
                plantedAt: plantedAt,
                wateringFrequencyDays: wateringFrequencyDays,
              );
        },
        onZoneAdded: (zoneType, w, h) async {
          Navigator.of(ctx, rootNavigator: true).pop();
          await ref
              .read(gardenNotifierProvider.notifier)
              .addZoneToGarden(
                gardenId: widget.gardenId,
                xMeters: 0.1,
                yMeters: 0.1,
                widthMeters: w,
                heightMeters: h,
                zoneType: zoneType.name,
              );
        },
      ),
    );
  }

  void _showEditSheet(
    GardenPlantWithDetails element,
    Garden garden,
  ) {
    final maxW =
        garden.widthCells * garden.cellSizeCm / 100.0;
    final maxH =
        garden.heightCells * garden.cellSizeCm / 100.0;
    final cellSize = garden.cellSizeCm;

    if (!element.isZone && element.plant != null) {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => EditorPlantDetailSheet(
          element: element,
          garden: garden,
          maxWidthM: maxW,
          maxHeightM: maxH,
          onUpdate: (w, h) async {
            Navigator.of(ctx, rootNavigator: true).pop();
            await _resizeElement(element, w, h, cellSize);
          },
          onDelete: () async {
            Navigator.of(ctx, rootNavigator: true).pop();
            await _deleteElement(element, cellSize);
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => EditorEditElementSheet(
          element: element,
          garden: garden,
          maxWidthM: maxW,
          maxHeightM: maxH,
          onUpdate: (w, h) async {
            Navigator.of(ctx, rootNavigator: true).pop();
            await _resizeElement(element, w, h, cellSize);
          },
          onDelete: () async {
            Navigator.of(ctx, rootNavigator: true).pop();
            await _deleteElement(element, cellSize);
          },
        ),
      );
    }
  }

  Future<void> _placePendingElement(
    GardenPlantWithDetails element,
    AsyncValue<Garden?> gardenAsync,
  ) async {
    final garden = gardenAsync.valueOrNull;
    if (garden == null) return;

    // Placer au centre du potager en position (0,0)
    await ref.read(gardenNotifierProvider.notifier).moveElement(
          element.gardenPlant.id,
          0.1,
          0.1,
          garden.id,
        );
  }

  void _showElementsList(
    Garden garden,
    List<GardenPlantWithDetails> elements,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditorElementsListSheet(
        garden: garden,
        elements: elements,
        isLocked: _isLocked,
        onToggleLock: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          _toggleLock();
        },
        onElementTap: (e) {
          Navigator.of(ctx, rootNavigator: true).pop();
          _showEditSheet(e, garden);
        },
        onElementDelete: (e) async {
          await _deleteElement(e, garden.cellSizeCm);
        },
      ),
    );
  }

  // ========== Build ==========

  @override
  Widget build(BuildContext context) {
    final gardenAsync = ref.watch(
      gardenByIdProvider(widget.gardenId),
    );
    final plantsAsync = ref.watch(
      gardenPlantsProvider(widget.gardenId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: _buildAppBar(gardenAsync, plantsAsync),
      body: _buildBody(gardenAsync, plantsAsync),
      floatingActionButton: _buildFab(gardenAsync),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AsyncValue<Garden?> gardenAsync,
    AsyncValue<List<GardenPlantWithDetails>> plantsAsync,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Center(
          child: AppBackButton.light(),
        ),
      ),
      title: gardenAsync.whenOrNull(
        data: (garden) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              garden?.name ?? AppLocalizations.of(context)!.gardenDefault,
              style: AppTypography.titleMedium,
            ),
            if (garden != null)
              Text(
                '${(garden.widthCells * garden.cellSizeCm / 100).toStringAsFixed(1)}m '
                '\u{00D7} '
                '${(garden.heightCells * garden.cellSizeCm / 100).toStringAsFixed(1)}m',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
      actions: [
        UndoRedoButtons(
          canUndo: _actionHistory.canUndo,
          canRedo: _actionHistory.canRedo,
          onUndo: _undo,
          onRedo: _redo,
        ),
        Container(
          width: 1,
          height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          color: AppColors.border,
        ),
        _buildElementsListButton(gardenAsync, plantsAsync),
        IconButton(
          onPressed: _resetView,
          icon: Icon(
            PhosphorIcons.arrowsOut(
              PhosphorIconsStyle.regular,
            ),
          ),
          tooltip: AppLocalizations.of(context)!.resetView,
        ),
      ],
    );
  }

  Widget _buildElementsListButton(
    AsyncValue<Garden?> gardenAsync,
    AsyncValue<List<GardenPlantWithDetails>> plantsAsync,
  ) {
    return gardenAsync.whenOrNull(
          data: (garden) {
            if (garden == null) return null;
            return plantsAsync.whenOrNull(
              data: (elements) => IconButton(
                onPressed: () =>
                    _showElementsList(garden, elements),
                icon: Stack(
                  children: [
                    Icon(
                      PhosphorIcons.list(
                        PhosphorIconsStyle.bold,
                      ),
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
                            borderRadius:
                                BorderRadius.circular(6),
                          ),
                          constraints:
                              const BoxConstraints(
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
                tooltip: AppLocalizations.of(context)!.elementsList,
              ),
            );
          },
        ) ??
        const SizedBox.shrink();
  }

  Widget _buildBody(
    AsyncValue<Garden?> gardenAsync,
    AsyncValue<List<GardenPlantWithDetails>> plantsAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            _buildGridArea(
              gardenAsync,
              plantsAsync,
              constraints,
            ),
            // Bandeau plantes en attente de placement
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Center(
                    child: LockToggleButton(
                      isLocked: _isLocked,
                      onToggle: _toggleLock,
                    ),
                  ),
                  plantsAsync.whenOrNull(
                        data: (elements) {
                          final pending = elements
                              .where((e) => e.isPendingPlacement)
                              .toList();
                          if (pending.isEmpty) return null;
                          return _PendingPlacementBanner(
                            pending: pending,
                            onPlace: (element) =>
                                _placePendingElement(
                                    element, gardenAsync),
                          );
                        },
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 200,
              child: ZoomControls(
                scale: _displayScale,
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: _buildStats(
                  gardenAsync,
                  plantsAsync,
                ),
              ),
            ),
            const Positioned(
              left: 16,
              bottom: 80,
              child: EditorLegend(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGridArea(
    AsyncValue<Garden?> gardenAsync,
    AsyncValue<List<GardenPlantWithDetails>> plantsAsync,
    BoxConstraints constraints,
  ) {
    return gardenAsync.when(
      data: (garden) {
        if (garden == null) {
          return Center(
            child: Text(AppLocalizations.of(context)!.gardenNotFound),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeView(garden, constraints);
        });
        return plantsAsync.when(
          data: (elements) => InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.001,
            maxScale: 100.0,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(5000),
            onInteractionUpdate: _onInteractionUpdate,
            onInteractionEnd: _onInteractionEnd,
            child: GardenGrid(
              garden: garden,
              elements: elements,
              isLocked: _isLocked,
              onElementTap: (e) =>
                  _showEditSheet(e, garden),
              onElementMoved: (e, xM, yM) =>
                  _onElementMoved(
                e,
                xM,
                yM,
                garden.cellSizeCm,
              ),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (e, _) =>
              Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
    );
  }

  Widget _buildStats(
    AsyncValue<Garden?> gardenAsync,
    AsyncValue<List<GardenPlantWithDetails>> plantsAsync,
  ) {
    return gardenAsync.whenOrNull(
          data: (garden) {
            if (garden == null) return null;
            return plantsAsync.whenOrNull(
              data: (elements) => EditorStats(
                garden: garden,
                elements: elements,
              ),
            );
          },
        ) ??
        const SizedBox.shrink();
  }

  Widget? _buildFab(AsyncValue<Garden?> gardenAsync) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: gardenAsync.whenOrNull(
        data: (garden) => garden != null
            ? FloatingActionButton.extended(
                onPressed: () => _showAddSheet(garden),
                backgroundColor: AppColors.primary,
                icon: Icon(
                  PhosphorIcons.plus(
                    PhosphorIconsStyle.bold,
                  ),
                ),
                label: Text(AppLocalizations.of(context)!.add),
              )
            : null,
      ),
    );
  }
}

// ============================================
// BANDEAU PLANTES EN ATTENTE DE PLACEMENT
// ============================================

class _PendingPlacementBanner extends StatelessWidget {
  final List<GardenPlantWithDetails> pending;
  final void Function(GardenPlantWithDetails) onPlace;

  const _PendingPlacementBanner({
    required this.pending,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.clock(PhosphorIconsStyle.fill),
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.pendingPlacementCount(pending.length),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final e = pending[i];
                return GestureDetector(
                  onTap: () => onPlace(e),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          e.name,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(PhosphorIcons.arrowDown(PhosphorIconsStyle.bold),
                            size: 12, color: AppColors.warning),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
