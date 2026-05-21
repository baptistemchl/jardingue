import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/services/preferences/user_guidance_preferences.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../../../core/providers/garden_event_providers.dart';
import '../../../../core/utils/plant_emoji_mapper.dart';
import '../../domain/action_history.dart';
import '../../domain/companion_guidance_service.dart';
import '../../domain/editor_mode.dart';
import '../../domain/models/amendment_type.dart';
import '../widgets/garden_grid.dart';
import '../widgets/editor/antagonist_warning_dialog.dart';
import '../widgets/editor/color_picker_sheet.dart';
import '../widgets/editor/companion_suggestions_sheet.dart';
import '../widgets/editor/undo_redo_buttons.dart';
import '../widgets/editor/editor_mode_selector.dart';
import '../widgets/editor/zoom_controls.dart';
import '../widgets/editor/editor_stats.dart';
import '../widgets/editor/editor_add_element_sheet.dart';
import '../widgets/editor/editor_edit_element_sheet.dart';
import '../widgets/editor/editor_elements_list_sheet.dart';
import '../widgets/editor/editor_plant_detail_sheet.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';

/// Indique si le calque "année précédente" est affiché dans l'éditeur.
final _showPreviousLayerProvider =
    NotifierProvider<_ShowPreviousLayerNotifier, bool>(
        _ShowPreviousLayerNotifier.new);

class _ShowPreviousLayerNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

/// Ensemble des types d'amendements visibles.
final _visibleAmendmentsProvider =
    NotifierProvider<_VisibleAmendmentsNotifier, Set<AmendmentType>>(
        _VisibleAmendmentsNotifier.new);

class _VisibleAmendmentsNotifier extends Notifier<Set<AmendmentType>> {
  @override
  Set<AmendmentType> build() => Set.of(AmendmentType.values);

  void toggle(AmendmentType t) {
    final next = Set<AmendmentType>.of(state);
    if (!next.add(t)) next.remove(t);
    state = next;
  }
}

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
  final _gardenGridKey = GlobalKey();

  double _currentScale = 1.0;
  double _displayScale = 1.0;
  EditorMode _mode = EditorMode.locked;
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

  // ========== Export PDF ==========

  Future<void> _exportGardenPlan(AsyncValue<Garden?> gardenAsync) async {
    final garden = gardenAsync.value;
    if (garden == null) return;

    final boundary = _gardenGridKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    // Afficher le loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Génération du PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Capturer le widget en image haute résolution
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final pngBytes = byteData.buffer.asUint8List();

    final gardenName = garden.name;
    final widthM = (garden.widthCells * garden.cellSizeCm / 100).toStringAsFixed(1);
    final heightM = (garden.heightCells * garden.cellSizeCm / 100).toStringAsFixed(1);

    // Générer le PDF pleine page
    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              gardenName,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '$widthM m \u{00D7} $heightM m',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Expanded(
              child: pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Jardingue \u{2022} ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();

    if (!mounted) return;

    // Fermer le loader
    Navigator.of(context).pop();

    // Ouvrir l'aperçu pleine page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PdfPreviewScreen(
          pdfBytes: pdfBytes,
          title: 'Plan - $gardenName',
        ),
      ),
    );
  }

  // ========== Mode d'edition ==========

  void _setMode(EditorMode m) {
    if (m == _mode) return;
    setState(() => _mode = m);
  }

  /// Toggle utilise par les sheets externes (liste des elements) :
  /// verrouille si on etait deverrouille, sinon repasse en mode "deplacer"
  /// (mode "doux" par defaut quand on deverrouille).
  void _toggleLockFromSheet() {
    HapticFeedback.mediumImpact();
    setState(() {
      _mode = _mode == EditorMode.locked
          ? EditorMode.move
          : EditorMode.locked;
    });
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
    if (!_mode.canDrag) return;

    // Avertissement d'antagonisme (opt-in, off par défaut).
    final prefs = ref.readGuidancePrefs();
    if (prefs.antagonistWarningsEnabled && !element.isZone) {
      final abort = await _checkAntagonistAndMaybeAbort(
        element: element,
        newXMeters: newX,
        newYMeters: newY,
        cellSizeCm: cellSizeCm,
      );
      if (abort) return;
    }

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

  /// Cherche les antagonistes voisins et affiche le dialog de confirmation
  /// si nécessaire. Retourne `true` si l'utilisateur annule le placement.
  Future<bool> _checkAntagonistAndMaybeAbort({
    required GardenPlantWithDetails element,
    required double newXMeters,
    required double newYMeters,
    required int cellSizeCm,
  }) async {
    final plant = element.plant;
    if (plant == null) return false;

    final antagonists = await ref.read(
      plantAntagonistsProvider(plant.id).future,
    );
    if (antagonists.isEmpty) return false;
    final antagonistIds = antagonists.map((p) => p.id).toSet();

    final existing = ref
            .read(gardenPlantsProvider(widget.gardenId))
            .value ??
        const <GardenPlantWithDetails>[];

    final newGridX = (newXMeters * 100 / cellSizeCm).round();
    final newGridY = (newYMeters * 100 / cellSizeCm).round();

    final conflicts = const CompanionGuidanceService().findConflictsAt(
      sourcePlant: plant,
      sourceGridX: newGridX,
      sourceGridY: newGridY,
      sourceWidthCells: element.widthCells,
      sourceHeightCells: element.heightCells,
      existingPlants: existing,
      antagonistsOfSource: antagonistIds,
      cellSizeCm: cellSizeCm,
      excludeGardenPlantId: element.id,
    );
    if (conflicts.isEmpty) return false;
    if (!mounted) return false;

    final confirmed = await AntagonistWarningDialog.show(
      context: context,
      sourcePlantName: plant.commonName,
      conflicts: conflicts,
    );
    return !confirmed;
  }

  /// Affiche la bottom sheet de suggestions de compagnons après l'ajout
  /// d'une plante (opt-in, off par défaut). Filtre les compagnons déjà
  /// présents dans le potager. Ajoute les compagnons cochés au panier
  /// (gridX = -1, en attente de placement).
  Future<void> _maybeSuggestCompanions(int sourcePlantId) async {
    final prefs = ref.readGuidancePrefs();
    if (!prefs.companionSuggestionsEnabled) return;

    final sourcePlant = await ref.read(
      plantByIdProvider(sourcePlantId).future,
    );
    if (sourcePlant == null) return;

    final companions = await ref.read(
      plantCompanionsProvider(sourcePlantId).future,
    );
    if (companions.isEmpty) return;

    final existing = ref
            .read(gardenPlantsProvider(widget.gardenId))
            .value ??
        const <GardenPlantWithDetails>[];
    final alreadyInGarden = existing
        .where((e) => !e.isZone)
        .map((e) => e.gardenPlant.plantId)
        .toSet();

    final suggestions = const CompanionGuidanceService().companionsToSuggest(
      companions: companions,
      alreadyInGardenPlantIds: alreadyInGarden,
    );
    if (suggestions.isEmpty) return;
    if (!mounted) return;

    final chosen = await CompanionSuggestionsSheet.show(
      context: context,
      sourcePlantName: sourcePlant.commonName,
      sourcePlantEmoji: PlantEmojiMapper.forPlant(sourcePlant),
      suggestions: suggestions,
    );
    if (chosen == null || chosen.isEmpty) return;

    final notifier = ref.read(gardenNotifierProvider.notifier);
    for (final plantId in chosen) {
      await notifier.addPlantPendingPlacement(
        gardenId: widget.gardenId,
        plantId: plantId,
      );
    }
  }

  Future<void> _deleteElement(
    GardenPlantWithDetails element,
    int cellSizeCm,
  ) async {
    final action = DeleteElementAction(
      elementId: element.id,
      gardenId: widget.gardenId,
      isZone: element.isZone,
      plantId: element.gardenPlant.plantId,
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

  /// Ouvre le color picker et applique le résultat sur l'élément.
  Future<void> _changeElementColor(GardenPlantWithDetails element) async {
    // Compte les pieds de la même espèce dans CE potager (zones exclues).
    // Sert au toggle « Appliquer à tous les X de ce potager » dans la
    // sheet : on ne l'affiche que s'il y a au moins 2 pieds à modifier.
    final allInGarden = ref
            .read(gardenPlantsProvider(widget.gardenId))
            .value ??
        const <GardenPlantWithDetails>[];
    final sameSpeciesCount = allInGarden
        .where((e) =>
            !e.isZone && e.gardenPlant.plantId == element.gardenPlant.plantId)
        .length;

    final result = await ColorPickerSheet.show(
      context: context,
      plantName: element.name,
      plantEmoji: element.emoji,
      currentColor: element.color,
      hasCustomColor: element.gardenPlant.customColor != null,
      sameSpeciesCount: sameSpeciesCount,
    );
    if (result == null) return;
    if (!mounted) return;
    final notifier = ref.read(gardenNotifierProvider.notifier);
    final newColor = result.isReset ? null : result.color;
    if (result.applyToAll) {
      await notifier.updateGardenPlantsColorBySpecies(
        gardenId: widget.gardenId,
        plantId: element.gardenPlant.plantId,
        color: newColor,
      );
    } else {
      await notifier.updateGardenPlantColor(
        gardenPlantId: element.id,
        color: newColor,
      );
    }
  }

  /// Duplique un élément (plante ou zone) en envoyant la copie au panier
  /// (gridX=-1). Affiche un snackbar de confirmation.
  Future<void> _duplicateElement(GardenPlantWithDetails element) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(gardenNotifierProvider.notifier).duplicateGardenPlant(
            gardenPlantId: element.id,
            gardenId: widget.gardenId,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${element.name} dupliquée — voir le panier'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Impossible de dupliquer'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
            {sowedAt,
            plantedAt,
            wateringFrequencyDays,
            previousCropPlantId}) async {
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
                previousCropPlantId: previousCropPlantId,
              );
          // Propose les compagnons (opt-in, off par défaut).
          await _maybeSuggestCompanions(plantId);
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
        onAmendmentAdded: (type, w, h, appliedAt) async {
          Navigator.of(ctx, rootNavigator: true).pop();
          await ref
              .read(gardenNotifierProvider.notifier)
              .addAmendment(
                gardenId: widget.gardenId,
                type: type.code,
                xMeters: 0.1,
                yMeters: 0.1,
                widthMeters: w,
                heightMeters: h,
                appliedAt: appliedAt,
              );
        },
      ),
    );
  }

  void _showAmendmentSheet(GardenAmendment a, int gardenId) {
    final type = AmendmentType.fromCode(a.type);
    if (type == null) return;
    AppBottomSheet.show<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: AppBottomSheetHandle()),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.label, style: AppTypography.titleMedium),
                      Text(
                        'Appliqué le '
                        '${a.appliedAt.day.toString().padLeft(2, '0')}/'
                        '${a.appliedAt.month.toString().padLeft(2, '0')}/'
                        '${a.appliedAt.year}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              type.description,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  await ref
                      .read(gardenNotifierProvider.notifier)
                      .deleteAmendment(a.id, gardenId);
                },
                icon: Icon(
                    PhosphorIcons.trash(PhosphorIconsStyle.regular)),
                label: const Text('Supprimer l\'amendement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
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
          onDuplicate: () async {
            Navigator.of(ctx, rootNavigator: true).pop();
            await _duplicateElement(element);
          },
          onChangeColor: () async {
            Navigator.of(ctx, rootNavigator: true).pop();
            await _changeElementColor(element);
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
    final garden = gardenAsync.value;
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
        isLocked: _mode == EditorMode.locked,
        onToggleLock: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          _toggleLockFromSheet();
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
        _buildLayersMenu(gardenAsync),
        IconButton(
          onPressed: _resetView,
          icon: Icon(
            PhosphorIcons.arrowsOut(
              PhosphorIconsStyle.regular,
            ),
          ),
          tooltip: AppLocalizations.of(context)!.resetView,
        ),
        IconButton(
          onPressed: () => _exportGardenPlan(gardenAsync),
          icon: Icon(
            PhosphorIcons.printer(
              PhosphorIconsStyle.regular,
            ),
          ),
          tooltip: 'Exporter le plan',
        ),
      ],
    );
  }

  Widget _buildLayersMenu(AsyncValue<Garden?> gardenAsync) {
    return gardenAsync.whenOrNull(
          data: (garden) {
            if (garden == null) return const SizedBox.shrink();
            final hasPrevious = garden.previousGardenId != null;
            final showPrevious = ref.watch(_showPreviousLayerProvider);
            final highlight = hasPrevious && showPrevious;
            return IconButton(
              tooltip: 'Calques',
              icon: Icon(
                highlight
                    ? PhosphorIcons.stackSimple(PhosphorIconsStyle.fill)
                    : PhosphorIcons.stackSimple(
                        PhosphorIconsStyle.regular),
                color:
                    highlight ? AppColors.primary : AppColors.textPrimary,
              ),
              onPressed: () => _openLayersSheet(hasPrevious),
            );
          },
        ) ??
        const SizedBox.shrink();
  }

  void _openLayersSheet(bool hasPrevious) {
    AppBottomSheet.show<void>(
      context: context,
      child: _LayersSheet(hasPrevious: hasPrevious),
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
    final bottomInset =
        MediaQuery.of(context).padding.bottom;

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
                    child: EditorModeSelector(
                      mode: _mode,
                      onChanged: _setMode,
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
              bottom: bottomInset + 200,
              child: ZoomControls(
                scale: _displayScale,
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
              ),
            ),
            // Bouton ajouter
            Positioned(
              right: 16,
              bottom: bottomInset + 80,
              child: _buildAddButton(gardenAsync),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset + 24,
              child: Center(
                child: _buildStats(
                  gardenAsync,
                  plantsAsync,
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: bottomInset + 80,
              child: const EditorLegend(),
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
          data: (elements) {
            final showPrevious = ref.watch(_showPreviousLayerProvider);
            final visibleAmendments =
                ref.watch(_visibleAmendmentsProvider);
            final previousAsync =
                (showPrevious && garden.previousGardenId != null)
                    ? ref.watch(
                        gardenPlantsProvider(garden.previousGardenId!))
                    : null;
            final previousElements =
                previousAsync?.asData?.value ?? const [];
            final allAmendments = ref
                    .watch(gardenAmendmentsLineageProvider(garden.id))
                    .asData
                    ?.value ??
                const [];
            final visibleFiltered = allAmendments.where((a) {
              final type = AmendmentType.fromCode(a.type);
              return type != null && visibleAmendments.contains(type);
            });
            // Courants = appartenant au potager actif → interactifs.
            // Historiques = hérités des potagers précédents → painter.
            final currentAmendments = visibleFiltered
                .where((a) => a.gardenId == garden.id)
                .toList();
            final historicAmendments = visibleFiltered
                .where((a) => a.gardenId != garden.id)
                .toList();
            // Derniers arrosages (1 requête bulk) → badge par plante.
            final lastWateringByGp =
                ref.watch(lastWateringDatesProvider).asData?.value ??
                    const <int, DateTime>{};
            return InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.001,
              maxScale: 100.0,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(5000),
              onInteractionUpdate: _onInteractionUpdate,
              onInteractionEnd: _onInteractionEnd,
              child: RepaintBoundary(
                key: _gardenGridKey,
                child: GardenGrid(
                  garden: garden,
                  elements: elements,
                  previousElements: previousElements,
                  amendments: currentAmendments,
                  historicAmendments: historicAmendments,
                  lastWateringByGp: lastWateringByGp,
                  mode: _mode,
                  onElementTap: (e) =>
                      _showEditSheet(e, garden),
                  onElementMoved: (e, xM, yM) =>
                      _onElementMoved(
                    e,
                    xM,
                    yM,
                    garden.cellSizeCm,
                  ),
                  onElementResized: (e, wM, hM) => ref
                      .read(gardenNotifierProvider.notifier)
                      .updateElementSize(e.id, wM, hM, garden.id),
                  onAmendmentTap: (a) =>
                      _showAmendmentSheet(a, garden.id),
                  onAmendmentMoved: (a, xM, yM) => ref
                      .read(gardenNotifierProvider.notifier)
                      .moveAmendment(
                          id: a.id,
                          gardenId: garden.id,
                          xMeters: xM,
                          yMeters: yM),
                  onAmendmentResized: (a, wM, hM) => ref
                      .read(gardenNotifierProvider.notifier)
                      .resizeAmendment(
                          id: a.id,
                          gardenId: garden.id,
                          widthMeters: wM,
                          heightMeters: hM),
                ),
              ),
            );
          },
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

  Widget _buildAddButton(
    AsyncValue<Garden?> gardenAsync,
  ) {
    return gardenAsync.whenOrNull(
          data: (garden) => garden != null
              ? GestureDetector(
                  onTap: () => _showAddSheet(garden),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.plus(
                            PhosphorIconsStyle.bold,
                          ),
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!
                              .add,
                          style: AppTypography
                              .labelMedium
                              .copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ) ??
        const SizedBox.shrink();
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
              separatorBuilder: (_, _) => const SizedBox(width: 6),
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

// ============================================
// PDF PREVIEW SCREEN
// ============================================

class _PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;

  const _PdfPreviewScreen({
    required this.pdfBytes,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTypography.titleMedium),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () => Printing.sharePdf(
              bytes: pdfBytes,
              filename: '$title.pdf',
            ),
            icon: Icon(PhosphorIcons.shareNetwork(PhosphorIconsStyle.regular)),
            tooltip: 'Partager',
          ),
          IconButton(
            onPressed: () => Printing.layoutPdf(
              onLayout: (_) async => pdfBytes,
              name: title,
            ),
            icon: Icon(PhosphorIcons.printer(PhosphorIconsStyle.regular)),
            tooltip: 'Imprimer',
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => pdfBytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        pdfFileName: '$title.pdf',
      ),
    );
  }
}


/// Bottom sheet des calques. Coche/décoche des types d'amendements et
/// l'année précédente via les StateProviders ; reste ouvert pendant la
/// sélection, sans déclencher de rebuild parasite de l'éditeur.
class _LayersSheet extends ConsumerWidget {
  final bool hasPrevious;
  const _LayersSheet({required this.hasPrevious});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showPrevious = ref.watch(_showPreviousLayerProvider);
    final visible = ref.watch(_visibleAmendmentsProvider);

    void togglePrevious() {
      ref.read(_showPreviousLayerProvider.notifier).toggle();
    }

    void toggleAmendment(AmendmentType t) {
      ref.read(_visibleAmendmentsProvider.notifier).toggle(t);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHandle(),
          const SizedBox(height: 4),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.stackSimple(PhosphorIconsStyle.fill),
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text('Calques', style: AppTypography.titleMedium),
              ],
            ),
          ),
          const Divider(height: 8),
          if (hasPrevious) ...[
            CheckboxListTile(
              value: showPrevious,
              onChanged: (_) => togglePrevious(),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: const Text('Année précédente'),
              subtitle: Text(
                'Plantes du potager précédent en hachures',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Divider(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Amendements',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          for (final t in AmendmentType.values)
            CheckboxListTile(
              value: visible.contains(t),
              onChanged: (_) => toggleAmendment(t),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: Row(
                children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(t.label),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
