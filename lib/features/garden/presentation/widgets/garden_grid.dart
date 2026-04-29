import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/garden_providers.dart';
import '../../domain/editor_mode.dart';
import '../../domain/models/amendment_type.dart';
import '../../domain/models/watering_helpers.dart';

/// Pixels par mètre (échelle de la grille)
/// 200px/m = 2px/cm, donc 10cm = 20px, 50cm = 100px, 1m = 200px
const double kPixelsPerMeter = 200.0;

/// Grille interactive du potager
class GardenGrid extends StatelessWidget {
  final Garden garden;
  final List<GardenPlantWithDetails> elements;

  /// Éléments du potager précédent (calque historique), optionnel.
  /// Rendu en transparence, non interactif.
  final List<GardenPlantWithDetails> previousElements;

  /// Amendements du potager courant (rendus en widgets interactifs :
  /// drag + resize + tap).
  final List<GardenAmendment> amendments;

  /// Amendements hérités des potagers précédents (lineage). Rendus en
  /// painter statique, non interactifs.
  final List<GardenAmendment> historicAmendments;

  /// Date de dernier arrosage par gardenPlantId.
  /// Absent de la map = jamais arrosée.
  final Map<int, DateTime> lastWateringByGp;

  final EditorMode mode;
  final Function(GardenPlantWithDetails element)? onElementTap;
  final Function(
    GardenPlantWithDetails element,
    double xMeters,
    double yMeters,
  )?
  onElementMoved;
  final Function(
    GardenPlantWithDetails element,
    double widthMeters,
    double heightMeters,
  )? onElementResized;
  final Function(GardenAmendment amendment)? onAmendmentTap;
  final Function(
    GardenAmendment amendment,
    double xMeters,
    double yMeters,
  )? onAmendmentMoved;
  final Function(
    GardenAmendment amendment,
    double widthMeters,
    double heightMeters,
  )? onAmendmentResized;

  const GardenGrid({
    super.key,
    required this.garden,
    required this.elements,
    this.previousElements = const [],
    this.amendments = const [],
    this.historicAmendments = const [],
    this.lastWateringByGp = const {},
    this.mode = EditorMode.locked,
    this.onElementTap,
    this.onElementMoved,
    this.onElementResized,
    this.onAmendmentTap,
    this.onAmendmentMoved,
    this.onAmendmentResized,
  });

  /// Dimensions en mètres du jardin
  double get _widthM =>
      garden.widthCells * garden.cellSizeCm / 100.0;
  double get _heightM =>
      garden.heightCells * garden.cellSizeCm / 100.0;

  /// Décoration du conteneur principal
  BoxDecoration get _gardenDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFA5D6A7),
        Color(0xFF81C784),
      ],
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: const Color(0xFF8D6E63),
      width: 3,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  List<Widget> _buildStackChildren() {
    return [
      Positioned.fill(
        child: CustomPaint(
          painter: _GardenTexturePainter(
            _widthM, _heightM,
          ),
        ),
      ),
      Positioned.fill(
        child: CustomPaint(
          painter: _GridPainter(
            widthMeters: _widthM,
            heightMeters: _heightM,
          ),
        ),
      ),
      // Calque amendements hérités (potagers précédents) — painter,
      // non interactif, sous l'année précédente et sous les éléments.
      if (historicAmendments.isNotEmpty)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _AmendmentLayerPainter(
                amendments: historicAmendments,
                cellSizeCm: garden.cellSizeCm,
                now: DateTime.now(),
              ),
            ),
          ),
        ),
      if (previousElements.isNotEmpty)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _PreviousLayerPainter(
                elements: previousElements
                    .where((e) => !e.isPendingPlacement)
                    .toList(),
                cellSizeCm: garden.cellSizeCm,
              ),
            ),
          ),
        ),
      // Amendements du potager courant — widgets interactifs (drag +
      // resize + tap). Sous les plantes dans le Stack pour que les
      // plantes restent primaires à la sélection.
      ...amendments.map(
        (a) => _DraggableAmendment(
          key: ValueKey('amendment-${a.id}'),
          amendment: a,
          garden: garden,
          mode: mode,
          onTap: () => onAmendmentTap?.call(a),
          onMoved: (xM, yM) => onAmendmentMoved?.call(a, xM, yM),
          onResized: (wM, hM) => onAmendmentResized?.call(a, wM, hM),
        ),
      ),
      ...elements.where((e) => !e.isPendingPlacement).map(
        (e) => _DraggableElement(
          key: ValueKey(e.id),
          element: e,
          garden: garden,
          mode: mode,
          wateringStatus: _statusFor(e),
          onTap: () => onElementTap?.call(e),
          onMoved: (xM, yM) =>
              onElementMoved?.call(e, xM, yM),
          onResized: (wM, hM) => onElementResized?.call(e, wM, hM),
        ),
      ),
    ];
  }

  /// Calcule le statut d'arrosage pour une plante (null pour les zones).
  WateringStatus? _statusFor(GardenPlantWithDetails e) {
    if (e.isZone) return null;
    final freq = e.gardenPlant.wateringFrequencyDays ??
        defaultWateringFrequencyDays(e.plant?.watering);
    return computeWateringStatus(
      lastWatered: lastWateringByGp[e.id],
      frequencyDays: freq,
      now: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _widthM * kPixelsPerMeter,
      height: _heightM * kPixelsPerMeter,
      decoration: _gardenDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          clipBehavior: Clip.none,
          children: _buildStackChildren(),
        ),
      ),
    );
  }
}

/// Texture de fond plus subtile
class _GardenTexturePainter extends CustomPainter {
  final double widthM;
  final double heightM;

  _GardenTexturePainter(this.widthM, this.heightM);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    final numPoints = (widthM * heightM * 2).clamp(30, 300).toInt();

    for (int i = 0; i < numPoints; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1 + random.nextDouble() * 1.5;
      paint.color = Colors.green.withValues(
        alpha: 0.05 + random.nextDouble() * 0.05,
      );
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  final double widthMeters;
  final double heightMeters;

  _GridPainter({required this.widthMeters, required this.heightMeters});

  /// Calcule l'intervalle optimal pour les marqueurs
  int _getMarkerInterval(double meters) {
    if (meters <= 5) return 1; // 1m, 2m, 3m...
    if (meters <= 12) return 2; // 2m, 4m, 6m...
    if (meters <= 25) return 5; // 5m, 10m, 15m...
    return 10; // 10m, 20m, 30m...
  }

  /// Crée les Paint pour les 3 niveaux de grille
  List<Paint> _gridPaints() => [
    Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5, // 10cm
    Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 1.0, // 50cm
    Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..strokeWidth = 2.0, // 1m
  ];

  /// Dessine les lignes de la grille (10cm, 50cm, 1m)
  void _drawGridLines(Canvas canvas, Size size) {
    final paints = _gridPaints();
    final cell10cm = kPixelsPerMeter * 0.1;
    final cell50cm = kPixelsPerMeter * 0.5;
    final cell1m = kPixelsPerMeter;

    Paint pick(double pos) {
      if ((pos % cell1m) < 1) return paints[2];
      if ((pos % cell50cm) < 1) return paints[1];
      return paints[0];
    }

    for (var x = 0.0; x <= size.width + 1; x += cell10cm) {
      canvas.drawLine(
        Offset(x, 0), Offset(x, size.height), pick(x),
      );
    }
    for (var y = 0.0; y <= size.height + 1; y += cell10cm) {
      canvas.drawLine(
        Offset(0, y), Offset(size.width, y), pick(y),
      );
    }
  }

  /// Style de texte pour les marqueurs
  TextStyle get _markerTextStyle => TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    shadows: [
      Shadow(
        color: Colors.black.withValues(alpha: 0.5),
        blurRadius: 2,
        offset: const Offset(1, 1),
      ),
    ],
  );

  /// Paint de fond pour les marqueurs texte
  Paint get _markerBgPaint => Paint()
    ..color = Colors.black.withValues(alpha: 0.35)
    ..style = PaintingStyle.fill;

  /// Marqueurs horizontaux (en haut)
  void _drawHorizontalMarkers(Canvas canvas, Size size) {
    final bg = _markerBgPaint;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final style = _markerTextStyle;
    final interval = _getMarkerInterval(widthMeters);
    for (int m = interval;
        m <= widthMeters.floor();
        m += interval) {
      final xPos = m * kPixelsPerMeter;
      if (xPos >= size.width - 20) continue;
      tp.text = TextSpan(text: '${m}m', style: style);
      tp.layout();
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(xPos - tp.width / 2 - 4, 4,
            tp.width + 8, tp.height + 4),
        const Radius.circular(4),
      );
      canvas.drawRRect(r, bg);
      tp.paint(canvas, Offset(xPos - tp.width / 2, 6));
    }
  }

  /// Marqueurs verticaux (à gauche)
  void _drawVerticalMarkers(Canvas canvas, Size size) {
    final bg = _markerBgPaint;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final style = _markerTextStyle;
    final interval = _getMarkerInterval(heightMeters);
    for (int m = interval;
        m <= heightMeters.floor();
        m += interval) {
      final yPos = m * kPixelsPerMeter;
      if (yPos >= size.height - 20) continue;
      tp.text = TextSpan(text: '${m}m', style: style);
      tp.layout();
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(4, yPos - tp.height / 2 - 2,
            tp.width + 8, tp.height + 4),
        const Radius.circular(4),
      );
      canvas.drawRRect(r, bg);
      tp.paint(canvas, Offset(8, yPos - tp.height / 2));
    }
  }

  /// Dessine les dimensions totales en bas à droite
  void _drawDimensions(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final dimsText = '${widthMeters.toStringAsFixed(1)}'
        ' × ${heightMeters.toStringAsFixed(1)} m';
    tp.text = TextSpan(
      text: dimsText,
      style: _markerTextStyle.copyWith(fontSize: 11),
    );
    tp.layout();
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width - tp.width - 14,
        size.height - tp.height - 10,
        tp.width + 10, tp.height + 6,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, bgPaint);
    tp.paint(
      canvas,
      Offset(
        size.width - tp.width - 9,
        size.height - tp.height - 7,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGridLines(canvas, size);
    _drawHorizontalMarkers(canvas, size);
    _drawVerticalMarkers(canvas, size);
    _drawDimensions(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.widthMeters != widthMeters ||
      oldDelegate.heightMeters != heightMeters;
}

/// Élément déplaçable (plante ou zone)
class _DraggableElement extends StatefulWidget {
  final GardenPlantWithDetails element;
  final Garden garden;
  final EditorMode mode;
  final WateringStatus? wateringStatus;
  final VoidCallback? onTap;
  final Function(double xMeters, double yMeters)? onMoved;
  final Function(double widthMeters, double heightMeters)? onResized;

  const _DraggableElement({
    super.key,
    required this.element,
    required this.garden,
    this.mode = EditorMode.locked,
    this.wateringStatus,
    this.onTap,
    this.onMoved,
    this.onResized,
  });

  @override
  State<_DraggableElement> createState() => _DraggableElementState();
}

class _DraggableElementState extends State<_DraggableElement>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;
  bool _isResizing = false;
  Offset _resizeDelta = Offset.zero;

  // Override visuel applique apres relachement de la poignee resize. On
  // garde la nouvelle taille a l'ecran le temps que la mise a jour DB
  // remonte via gardenPlantsProvider. Sans cela, on a un flash : la taille
  // revient a `e.widthMeters` (ancienne valeur DB) puis re-saute a la
  // nouvelle quand le widget rebuild avec le nouvel element.
  double? _pendingWidthMeters;
  double? _pendingHeightMeters;

  // Animation "bump" au lieu du grossissement permanent
  late AnimationController _bumpController;
  late Animation<double> _bumpAnimation;

  GardenPlantWithDetails get e => widget.element;

  int get cellSizeCm => widget.garden.cellSizeCm;

  /// Animation bump : 1.0 -> 1.08 -> 1.0
  Animation<double> _createBumpAnimation() {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(
                curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_bumpController);
  }

  @override
  void initState() {
    super.initState();
    _bumpController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bumpAnimation = _createBumpAnimation();
  }

  @override
  void didUpdateWidget(covariant _DraggableElement old) {
    super.didUpdateWidget(old);
    // Quand la nouvelle taille DB matche le pending, on lache l'override.
    if (_pendingWidthMeters != null) {
      final actualW = widget.element.widthMeters(cellSizeCm);
      final actualH = widget.element.heightMeters(cellSizeCm);
      if ((actualW - _pendingWidthMeters!).abs() < 0.01 &&
          (actualH - _pendingHeightMeters!).abs() < 0.01) {
        _pendingWidthMeters = null;
        _pendingHeightMeters = null;
      }
    }
  }

  @override
  void dispose() {
    _bumpController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.mode.canDrag) return;

    // Retour haptique au début du drag
    HapticFeedback.mediumImpact();

    setState(() {
      _isDragging = true;
      _dragOffset = Offset.zero;
    });

    // Lancer l'animation bump (rapide rebond)
    _bumpController.forward(from: 0);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.mode.canDrag || !_isDragging) return;
    setState(() => _dragOffset += details.delta);
  }

  /// Calcule la position clampée après un drag
  (double x, double y) _clampedPosition() {
    final xPx = e.xMeters(cellSizeCm) * kPixelsPerMeter
        + _dragOffset.dx;
    final yPx = e.yMeters(cellSizeCm) * kPixelsPerMeter
        + _dragOffset.dy;
    // Si l'élément est plus grand que le jardin, maxX/maxY
    // peut être négatif : on force à 0 pour éviter un crash
    // de clamp(lowerLimit > upperLimit).
    final maxX = math.max(
      0.0,
      widget.garden.widthCells * cellSizeCm / 100.0
          - e.widthMeters(cellSizeCm),
    );
    final maxY = math.max(
      0.0,
      widget.garden.heightCells * cellSizeCm / 100.0
          - e.heightMeters(cellSizeCm),
    );
    return (
      (xPx / kPixelsPerMeter).clamp(0.0, maxX),
      (yPx / kPixelsPerMeter).clamp(0.0, maxY),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.mode.canDrag || !_isDragging) return;
    final (newX, newY) = _clampedPosition();

    setState(() {
      _isDragging = false;
      _dragOffset = Offset.zero;
    });

    final oldX = e.xMeters(cellSizeCm);
    final oldY = e.yMeters(cellSizeCm);
    if ((newX - oldX).abs() > 0.01 ||
        (newY - oldY).abs() > 0.01) {
      HapticFeedback.lightImpact();
      widget.onMoved?.call(newX, newY);
    }
  }

  /// Ombres selon l'état drag
  List<BoxShadow> _buildShadows(Color color) {
    if (_isDragging) {
      return [
        BoxShadow(
          color: color.withValues(alpha: 0.5),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Décoration du conteneur selon l'état drag
  BoxDecoration _buildDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(
        alpha: _isDragging ? 0.95 : 0.85,
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: _isDragging
            ? Colors.white
            : (widget.mode.isUnlocked
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.7)),
        width: _isDragging ? 3 : 2,
      ),
      boxShadow: _buildShadows(color),
    );
  }

  /// Label du nom sous l'emoji
  Widget _buildNameLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        e.name,
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withValues(
                alpha: 0.4,
              ),
              blurRadius: 2,
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Emoji + nom de la plante au centre
  Widget _buildCenterContent(
    double displayWidth,
    double displayHeight,
    double emojiSize,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            e.emoji,
            style: TextStyle(fontSize: emojiSize),
          ),
          if (displayWidth > 70 && displayHeight > 70)
            _buildNameLabel(),
        ],
      ),
    );
  }

  /// Icône lock / move / resize en haut à droite, selon le mode courant.
  Widget _buildLockIndicator() {
    final unlocked = widget.mode.isUnlocked;
    final IconData icon;
    switch (widget.mode) {
      case EditorMode.locked:
        icon = PhosphorIcons.lock(PhosphorIconsStyle.fill);
      case EditorMode.move:
        icon = PhosphorIcons.arrowsOutCardinal(PhosphorIconsStyle.fill);
      case EditorMode.resize:
        icon = PhosphorIcons.cornersOut(PhosphorIconsStyle.bold);
    }
    return Positioned(
      right: 2,
      top: 2,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.primary.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 12,
          color: unlocked
              ? Colors.white
              : Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  /// Indicateur "Glisser" en bas
  Widget _buildDragHint() {
    return Positioned(
      bottom: 2,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.9,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Glisser',
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Conteneur principal de l'élément
  Widget _buildContainer() {
    // Si une mise a jour de taille est en attente cote DB, on affiche cette
    // taille au lieu de e.widthMeters/e.heightMeters pour eviter le flash
    // entre le relachement de la poignee et le retour de la DB.
    final effectiveW = _pendingWidthMeters ?? e.widthMeters(cellSizeCm);
    final effectiveH = _pendingHeightMeters ?? e.heightMeters(cellSizeCm);
    final baseW = effectiveW * kPixelsPerMeter;
    final baseH = effectiveH * kPixelsPerMeter;
    final widthPx = _isResizing
        ? (baseW + _resizeDelta.dx).clamp(30.0, double.infinity)
        : baseW;
    final heightPx = _isResizing
        ? (baseH + _resizeDelta.dy).clamp(30.0, double.infinity)
        : baseH;
    final color = Color(e.color);
    final dw = math.max(widthPx, 30.0);
    final dh = math.max(heightPx, 30.0);
    final emojiSize =
        (math.min(dw, dh) * 0.5).clamp(16.0, 50.0);

    final showResizeHandle = widget.mode.canResize;
    return SizedBox(
      // On élargit pour loger la poignée (hit area 44) qui dépasse du coin —
      // uniquement quand la poignée est visible (mode resize).
      width: dw + (showResizeHandle ? 24 : 0),
      height: dh + (showResizeHandle ? 24 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: dw,
            height: dh,
            decoration: _buildDecoration(color),
            child: Stack(
              children: [
                _buildCenterContent(dw, dh, emojiSize),
                if (dw > 40) _buildLockIndicator(),
                if (widget.wateringStatus != null && dw > 30)
                  _buildWateringBadge(),
                if (widget.mode.canDrag &&
                    dw > 60 &&
                    !_isDragging &&
                    !_isResizing)
                  _buildDragHint(),
              ],
            ),
          ),
          if (showResizeHandle)
            Positioned(
              right: 0,
              bottom: 0,
              child: _ResizeHandle(
                isActive: _isResizing,
                onPanStart: (_) {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _isResizing = true;
                    _resizeDelta = Offset.zero;
                  });
                },
                onPanUpdate: (d) {
                  setState(() => _resizeDelta += d.delta);
                },
                onPanEnd: (_) {
                  final maxW = widget.garden.widthCells *
                          cellSizeCm /
                          100.0 -
                      e.xMeters(cellSizeCm);
                  final maxH = widget.garden.heightCells *
                          cellSizeCm /
                          100.0 -
                      e.yMeters(cellSizeCm);
                  final newW =
                      ((baseW + _resizeDelta.dx) / kPixelsPerMeter)
                          .clamp(0.1, math.max(0.1, maxW))
                          .toDouble();
                  final newH =
                      ((baseH + _resizeDelta.dy) / kPixelsPerMeter)
                          .clamp(0.1, math.max(0.1, maxH))
                          .toDouble();
                  final prevW = e.widthMeters(cellSizeCm);
                  final prevH = e.heightMeters(cellSizeCm);
                  final changed = (newW - prevW).abs() > 0.01 ||
                      (newH - prevH).abs() > 0.01;
                  setState(() {
                    _isResizing = false;
                    _resizeDelta = Offset.zero;
                    // On garde la nouvelle taille a l'ecran jusqu'a ce que
                    // le widget recoive le nouvel element via didUpdateWidget.
                    if (changed) {
                      _pendingWidthMeters = newW;
                      _pendingHeightMeters = newH;
                    }
                  });
                  if (changed) {
                    HapticFeedback.lightImpact();
                    widget.onResized?.call(newW, newH);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Badge d'arrosage dans le coin bas-droit : couleur selon le statut,
  /// icône goutte ou croix.
  Widget _buildWateringBadge() {
    final status = widget.wateringStatus!;
    final (bgColor, icon, tooltip) = switch (status) {
      WateringStatus.never => (
          const Color(0xFF9E9E9E),
          PhosphorIcons.drop(PhosphorIconsStyle.regular),
          'Jamais arrosée',
        ),
      WateringStatus.upToDate => (
          const Color(0xFF03A9F4),
          PhosphorIcons.drop(PhosphorIconsStyle.fill),
          'Arrosée récemment',
        ),
      WateringStatus.dueSoon => (
          const Color(0xFFFF9800),
          PhosphorIcons.drop(PhosphorIconsStyle.fill),
          'À arroser bientôt',
        ),
      WateringStatus.overdue => (
          const Color(0xFFE53935),
          PhosphorIcons.dropHalfBottom(PhosphorIconsStyle.fill),
          'Arrosage en retard',
        ),
    };
    return Positioned(
      right: 2,
      bottom: 2,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xPx =
        e.xMeters(cellSizeCm) * kPixelsPerMeter;
    final yPx =
        e.yMeters(cellSizeCm) * kPixelsPerMeter;
    final left =
        xPx + (_isDragging ? _dragOffset.dx : 0);
    final top =
        yPx + (_isDragging ? _dragOffset.dy : 0);

    return AnimatedPositioned(
      duration: _isDragging
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      child: GestureDetector(
        // opaque pour s'assurer que le tap est toujours capture, meme si la
        // tuile est dans un parent avec d'autres recognizers (InteractiveViewer).
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanStart:
            widget.mode.canDrag ? _onDragStart : null,
        onPanUpdate:
            widget.mode.canDrag ? _onDragUpdate : null,
        onPanEnd:
            widget.mode.canDrag ? _onDragEnd : null,
        child: AnimatedBuilder(
          animation: _bumpAnimation,
          builder: (context, child) =>
              Transform.scale(
            scale: _bumpAnimation.value,
            child: child,
          ),
          child: _buildContainer(),
        ),
      ),
    );
  }
}

/// Poignée de redimensionnement au coin bas-droit. Visible uniquement
/// quand le parent est en mode resize. Capture ses propres gestures pan
/// pour ne pas entrer en concurrence avec le drag de l'élément.
///
/// Hit area de 48×48 (recommandation Material) avec un visuel de 36×36
/// bien lisible. Le hit area deborde du coin (positionnement parent en
/// `right: -kHandleOverflow, bottom: -kHandleOverflow`) pour ne pas voler
/// le tap du body de la tuile.
class _ResizeHandle extends StatelessWidget {
  final bool isActive;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  static const double hitSize = 48;
  static const double visualSize = 36;

  const _ResizeHandle({
    required this.isActive,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: isActive ? visualSize + 4 : visualSize,
            height: isActive ? visualSize + 4 : visualSize,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              PhosphorIcons.arrowsOutCardinal(PhosphorIconsStyle.bold),
              size: 20,
              color: isActive ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Amendement déplaçable + redimensionnable + tap pour éditer.
/// Pendant du `_DraggableElement` pour les amendements du potager courant.
class _DraggableAmendment extends StatefulWidget {
  final GardenAmendment amendment;
  final Garden garden;
  final EditorMode mode;
  final VoidCallback? onTap;
  final Function(double xMeters, double yMeters)? onMoved;
  final Function(double widthMeters, double heightMeters)? onResized;

  const _DraggableAmendment({
    super.key,
    required this.amendment,
    required this.garden,
    this.mode = EditorMode.locked,
    this.onTap,
    this.onMoved,
    this.onResized,
  });

  @override
  State<_DraggableAmendment> createState() => _DraggableAmendmentState();
}

class _DraggableAmendmentState extends State<_DraggableAmendment> {
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;
  bool _isResizing = false;
  Offset _resizeDelta = Offset.zero;
  // Voir _DraggableElementState : evite le flash entre relachement et update DB.
  double? _pendingWidthMeters;
  double? _pendingHeightMeters;

  @override
  void didUpdateWidget(covariant _DraggableAmendment old) {
    super.didUpdateWidget(old);
    if (_pendingWidthMeters != null) {
      if ((_wM - _pendingWidthMeters!).abs() < 0.01 &&
          (_hM - _pendingHeightMeters!).abs() < 0.01) {
        _pendingWidthMeters = null;
        _pendingHeightMeters = null;
      }
    }
  }

  GardenAmendment get a => widget.amendment;
  int get cellSizeCm => widget.garden.cellSizeCm;

  double get _xM => a.gridX * cellSizeCm / 100.0;
  double get _yM => a.gridY * cellSizeCm / 100.0;
  double get _wM => a.widthCells * cellSizeCm / 100.0;
  double get _hM => a.heightCells * cellSizeCm / 100.0;

  void _onDragStart(DragStartDetails _) {
    if (!widget.mode.canDrag) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isDragging = true;
      _dragOffset = Offset.zero;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!widget.mode.canDrag || !_isDragging) return;
    setState(() => _dragOffset += d.delta);
  }

  void _onDragEnd(DragEndDetails _) {
    if (!widget.mode.canDrag || !_isDragging) return;
    final xPx = _xM * kPixelsPerMeter + _dragOffset.dx;
    final yPx = _yM * kPixelsPerMeter + _dragOffset.dy;
    final maxX = math.max(
        0.0,
        widget.garden.widthCells * cellSizeCm / 100.0 - _wM);
    final maxY = math.max(
        0.0,
        widget.garden.heightCells * cellSizeCm / 100.0 - _hM);
    final newX = (xPx / kPixelsPerMeter).clamp(0.0, maxX);
    final newY = (yPx / kPixelsPerMeter).clamp(0.0, maxY);
    setState(() {
      _isDragging = false;
      _dragOffset = Offset.zero;
    });
    if ((newX - _xM).abs() > 0.01 || (newY - _yM).abs() > 0.01) {
      HapticFeedback.lightImpact();
      widget.onMoved?.call(newX, newY);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = AmendmentType.fromCode(a.type);
    if (type == null) return const SizedBox.shrink();

    final xPx = _xM * kPixelsPerMeter +
        (_isDragging ? _dragOffset.dx : 0);
    final yPx = _yM * kPixelsPerMeter +
        (_isDragging ? _dragOffset.dy : 0);

    final effectiveWM = _pendingWidthMeters ?? _wM;
    final effectiveHM = _pendingHeightMeters ?? _hM;
    final baseW = effectiveWM * kPixelsPerMeter;
    final baseH = effectiveHM * kPixelsPerMeter;
    final w = _isResizing
        ? (baseW + _resizeDelta.dx).clamp(30.0, double.infinity)
        : baseW;
    final h = _isResizing
        ? (baseH + _resizeDelta.dy).clamp(30.0, double.infinity)
        : baseH;

    final opacity = amendmentOpacity(a.appliedAt, DateTime.now());
    final color = Color(type.color);
    final ageYears =
        DateTime.now().difference(a.appliedAt).inDays ~/ 365;
    final label = ageYears == 0
        ? '${type.emoji} cette année'
        : '${type.emoji} -${ageYears}a';

    return AnimatedPositioned(
      duration: _isDragging
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: xPx,
      top: yPx,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanStart: widget.mode.canDrag ? _onDragStart : null,
        onPanUpdate: widget.mode.canDrag ? _onDragUpdate : null,
        onPanEnd: widget.mode.canDrag ? _onDragEnd : null,
        child: SizedBox(
          width: w + (widget.mode.canResize ? 24 : 0),
          height: h + (widget.mode.canResize ? 24 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: color.withValues(
                      alpha: _isDragging ? opacity + 0.15 : opacity),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.mode.isUnlocked
                        ? AppColors.primary
                        : color.withValues(
                            alpha: (opacity + 0.2).clamp(0, 1)),
                    width: _isDragging ? 3 : 1.5,
                  ),
                ),
                child: w >= 36 && h >= 36
                    ? Padding(
                        padding: const EdgeInsets.all(4),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              label,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              if (widget.mode.canResize)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _ResizeHandle(
                    isActive: _isResizing,
                    onPanStart: (_) {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _isResizing = true;
                        _resizeDelta = Offset.zero;
                      });
                    },
                    onPanUpdate: (d) {
                      setState(() => _resizeDelta += d.delta);
                    },
                    onPanEnd: (_) {
                      final maxW = widget.garden.widthCells *
                              cellSizeCm /
                              100.0 -
                          _xM;
                      final maxH = widget.garden.heightCells *
                              cellSizeCm /
                              100.0 -
                          _yM;
                      final newW = ((baseW + _resizeDelta.dx) /
                              kPixelsPerMeter)
                          .clamp(0.1, math.max(0.1, maxW))
                          .toDouble();
                      final newH = ((baseH + _resizeDelta.dy) /
                              kPixelsPerMeter)
                          .clamp(0.1, math.max(0.1, maxH))
                          .toDouble();
                      final changed = (newW - _wM).abs() > 0.01 ||
                          (newH - _hM).abs() > 0.01;
                      setState(() {
                        _isResizing = false;
                        _resizeDelta = Offset.zero;
                        if (changed) {
                          _pendingWidthMeters = newW;
                          _pendingHeightMeters = newH;
                        }
                      });
                      if (changed) {
                        HapticFeedback.lightImpact();
                        widget.onResized?.call(newW, newH);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calque du potager précédent : dessine chaque plante en hachures
/// transparentes avec son emoji au centre. Destiné à la visualisation
/// de la rotation — non interactif.
class _PreviousLayerPainter extends CustomPainter {
  final List<GardenPlantWithDetails> elements;
  final int cellSizeCm;

  // Paints réutilisables.
  final Paint _hashPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.35)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  final Paint _fillPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.25)
    ..style = PaintingStyle.fill;
  final Paint _borderPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.4)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  final TextPainter _tp = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  _PreviousLayerPainter({
    required this.elements,
    required this.cellSizeCm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in elements) {
      final x = e.xMeters(cellSizeCm) * kPixelsPerMeter;
      final y = e.yMeters(cellSizeCm) * kPixelsPerMeter;
      final w = e.widthMeters(cellSizeCm) * kPixelsPerMeter;
      final h = e.heightMeters(cellSizeCm) * kPixelsPerMeter;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(6),
      );

      canvas.drawRRect(rect, _fillPaint);
      canvas.drawRRect(rect, _borderPaint);

      // Hachures diagonales pour marquer "historique".
      canvas.save();
      canvas.clipRRect(rect);
      const spacing = 8.0;
      final diag = w + h;
      for (var d = -diag; d <= diag; d += spacing) {
        canvas.drawLine(
          Offset(x + d, y),
          Offset(x + d + h, y + h),
          _hashPaint,
        );
      }
      canvas.restore();

      final minSide = math.min(w, h);
      if (minSide > 28) {
        _tp.text = TextSpan(
          text: e.emoji,
          style: TextStyle(
            fontSize: (minSide * 0.4).clamp(14.0, 36.0),
            color: Colors.black.withValues(alpha: 0.55),
          ),
        );
        _tp.layout();
        _tp.paint(
          canvas,
          Offset(x + (w - _tp.width) / 2, y + (h - _tp.height) / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PreviousLayerPainter oldDelegate) =>
      oldDelegate.elements != elements ||
      oldDelegate.cellSizeCm != cellSizeCm;
}

/// Calque des amendements : rectangle teinté de la couleur du type,
/// avec un emoji dans le coin et une opacité qui décroît avec l'âge.
class _AmendmentLayerPainter extends CustomPainter {
  final List<GardenAmendment> amendments;
  final int cellSizeCm;
  final DateTime now;

  // Paints réutilisables — mutés par amendement pour éviter les allocs.
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _borderPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  final Paint _badgeBgPaint = Paint()..style = PaintingStyle.fill;
  final TextPainter _tp =
      TextPainter(textDirection: TextDirection.ltr);

  _AmendmentLayerPainter({
    required this.amendments,
    required this.cellSizeCm,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final a in amendments) {
      final type = AmendmentType.fromCode(a.type);
      if (type == null) continue;

      final x = a.gridX * cellSizeCm * kPixelsPerMeter / 100.0;
      final y = a.gridY * cellSizeCm * kPixelsPerMeter / 100.0;
      final w = a.widthCells * cellSizeCm * kPixelsPerMeter / 100.0;
      final h = a.heightCells * cellSizeCm * kPixelsPerMeter / 100.0;

      final opacity = amendmentOpacity(a.appliedAt, now);
      final baseColor = Color(type.color);

      _fillPaint.color = baseColor.withValues(alpha: opacity);
      _borderPaint.color =
          baseColor.withValues(alpha: (opacity + 0.2).clamp(0.0, 1.0));

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, _fillPaint);
      canvas.drawRRect(rect, _borderPaint);

      if (w < 36 || h < 36) continue;

      final ageYears = now.difference(a.appliedAt).inDays ~/ 365;
      final badgeText = ageYears == 0
          ? '${type.emoji} cette année'
          : '${type.emoji} -${ageYears}a';
      _tp.text = TextSpan(
        text: badgeText,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 2,
            ),
          ],
        ),
      );
      _tp.layout(maxWidth: w - 8);
      _badgeBgPaint.color = baseColor.withValues(alpha: 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + 4,
            y + 4,
            _tp.width + 8,
            _tp.height + 4,
          ),
          const Radius.circular(4),
        ),
        _badgeBgPaint,
      );
      _tp.paint(canvas, Offset(x + 8, y + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _AmendmentLayerPainter oldDelegate) =>
      oldDelegate.amendments != amendments ||
      oldDelegate.cellSizeCm != cellSizeCm ||
      oldDelegate.now != now;
}

class AnimatedBuilder extends AnimatedWidget {
  final TransitionBuilder builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Listenable animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
