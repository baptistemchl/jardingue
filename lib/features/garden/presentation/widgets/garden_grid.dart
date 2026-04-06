import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/database/app_database.dart';
import '../../../../core/providers/garden_providers.dart';

/// Pixels par mètre (échelle de la grille)
/// 200px/m = 2px/cm, donc 10cm = 20px, 50cm = 100px, 1m = 200px
const double kPixelsPerMeter = 200.0;

/// Grille interactive du potager
class GardenGrid extends StatelessWidget {
  final Garden garden;
  final List<GardenPlantWithDetails> elements;
  final bool isLocked;
  final Function(GardenPlantWithDetails element)? onElementTap;
  final Function(
    GardenPlantWithDetails element,
    double xMeters,
    double yMeters,
  )?
  onElementMoved;

  const GardenGrid({
    super.key,
    required this.garden,
    required this.elements,
    this.isLocked = true,
    this.onElementTap,
    this.onElementMoved,
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

  /// Contenu empilé : texture + grille + éléments
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
      ...elements.where((e) => !e.isPendingPlacement).map(
        (e) => _DraggableElement(
          key: ValueKey(e.id),
          element: e,
          garden: garden,
          isLocked: isLocked,
          onTap: () => onElementTap?.call(e),
          onMoved: (xM, yM) =>
              onElementMoved?.call(e, xM, yM),
        ),
      ),
    ];
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
  final bool isLocked;
  final VoidCallback? onTap;
  final Function(double xMeters, double yMeters)? onMoved;

  const _DraggableElement({
    super.key,
    required this.element,
    required this.garden,
    this.isLocked = true,
    this.onTap,
    this.onMoved,
  });

  @override
  State<_DraggableElement> createState() => _DraggableElementState();
}

class _DraggableElementState extends State<_DraggableElement>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;

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
  void dispose() {
    _bumpController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (widget.isLocked) return;

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
    if (widget.isLocked || !_isDragging) return;
    setState(() => _dragOffset += details.delta);
  }

  /// Calcule la position clampée après un drag
  (double x, double y) _clampedPosition() {
    final xPx = e.xMeters(cellSizeCm) * kPixelsPerMeter
        + _dragOffset.dx;
    final yPx = e.yMeters(cellSizeCm) * kPixelsPerMeter
        + _dragOffset.dy;
    final maxX = widget.garden.widthCells
        * cellSizeCm / 100.0
        - e.widthMeters(cellSizeCm);
    final maxY = widget.garden.heightCells
        * cellSizeCm / 100.0
        - e.heightMeters(cellSizeCm);
    return (
      (xPx / kPixelsPerMeter).clamp(0, maxX),
      (yPx / kPixelsPerMeter).clamp(0, maxY),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.isLocked || !_isDragging) return;
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
            : (widget.isLocked
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.primary),
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

  /// Icône lock / move en haut à droite
  Widget _buildLockIndicator() {
    return Positioned(
      right: 2,
      top: 2,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: widget.isLocked
              ? Colors.white.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          widget.isLocked
              ? PhosphorIcons.lock(
                  PhosphorIconsStyle.fill,
                )
              : PhosphorIcons.arrowsOutCardinal(
                  PhosphorIconsStyle.fill,
                ),
          size: 12,
          color: widget.isLocked
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.white,
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
    final widthPx =
        e.widthMeters(cellSizeCm) * kPixelsPerMeter;
    final heightPx =
        e.heightMeters(cellSizeCm) * kPixelsPerMeter;
    final color = Color(e.color);
    final dw = math.max(widthPx, 30.0);
    final dh = math.max(heightPx, 30.0);
    final emojiSize =
        (math.min(dw, dh) * 0.5).clamp(16.0, 50.0);

    return Container(
      width: dw,
      height: dh,
      decoration: _buildDecoration(color),
      child: Stack(
        children: [
          _buildCenterContent(dw, dh, emojiSize),
          if (dw > 40) _buildLockIndicator(),
          if (!widget.isLocked &&
              dw > 60 &&
              !_isDragging)
            _buildDragHint(),
        ],
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
        onTap: widget.onTap,
        onPanStart:
            widget.isLocked ? null : _onDragStart,
        onPanUpdate:
            widget.isLocked ? null : _onDragUpdate,
        onPanEnd:
            widget.isLocked ? null : _onDragEnd,
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
