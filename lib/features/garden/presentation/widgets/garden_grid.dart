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

  @override
  Widget build(BuildContext context) {
    // Calcul des dimensions en mètres
    final widthM = garden.widthCells * garden.cellSizeCm / 100.0;
    final heightM = garden.heightCells * garden.cellSizeCm / 100.0;

    final gridWidth = widthM * kPixelsPerMeter;
    final gridHeight = heightM * kPixelsPerMeter;

    return Container(
      width: gridWidth,
      height: gridHeight,
      decoration: BoxDecoration(
        // Vert plus doux et naturel
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFA5D6A7), // Vert pastel clair
            Color(0xFF81C784), // Vert pastel moyen
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8D6E63),
          width: 3,
        ), // Bordure bois plus claire
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Texture
            Positioned.fill(
              child: CustomPaint(
                painter: _GardenTexturePainter(widthM, heightM),
              ),
            ),

            // Grille
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                  widthMeters: widthM,
                  heightMeters: heightM,
                ),
              ),
            ),

            // Éléments
            ...elements.map(
              (e) => _DraggableElement(
                key: ValueKey('element-${e.id}'),
                element: e,
                garden: garden,
                isLocked: isLocked,
                onTap: () => onElementTap?.call(e),
                onMoved: (xM, yM) => onElementMoved?.call(e, xM, yM),
              ),
            ),
          ],
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

  @override
  void paint(Canvas canvas, Size size) {
    // Paints pour les différentes lignes
    final minorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    final majorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 1.0;

    final meterPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..strokeWidth = 2.0;

    // Taille des cellules en pixels (avec nouvelle échelle)
    final cell10cm = kPixelsPerMeter * 0.1; // 20px
    final cell50cm = kPixelsPerMeter * 0.5; // 100px
    final cell1m = kPixelsPerMeter; // 200px

    // === LIGNES VERTICALES ===
    double x = 0;
    while (x <= size.width + 1) {
      final isMeter = (x % cell1m) < 1;
      final isMajor = (x % cell50cm) < 1;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMeter ? meterPaint : (isMajor ? majorPaint : minorPaint),
      );
      x += cell10cm;
    }

    // === LIGNES HORIZONTALES ===
    double y = 0;
    while (y <= size.height + 1) {
      final isMeter = (y % cell1m) < 1;
      final isMajor = (y % cell50cm) < 1;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMeter ? meterPaint : (isMajor ? majorPaint : minorPaint),
      );
      y += cell10cm;
    }

    // === MARQUEURS MÈTRES (texte) ===
    final textStyle = TextStyle(
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

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Intervalle intelligent pour les marqueurs
    final xInterval = _getMarkerInterval(widthMeters);
    final yInterval = _getMarkerInterval(heightMeters);

    // Marqueurs horizontaux (en haut)
    for (int m = xInterval; m <= widthMeters.floor(); m += xInterval) {
      final xPos = m * kPixelsPerMeter;
      if (xPos < size.width - 20) {
        textPainter.text = TextSpan(text: '${m}m', style: textStyle);
        textPainter.layout();

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            xPos - textPainter.width / 2 - 4,
            4,
            textPainter.width + 8,
            textPainter.height + 4,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, bgPaint);
        textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, 6));
      }
    }

    // Marqueurs verticaux (à gauche)
    for (int m = yInterval; m <= heightMeters.floor(); m += yInterval) {
      final yPos = m * kPixelsPerMeter;
      if (yPos < size.height - 20) {
        textPainter.text = TextSpan(text: '${m}m', style: textStyle);
        textPainter.layout();

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            4,
            yPos - textPainter.height / 2 - 2,
            textPainter.width + 8,
            textPainter.height + 4,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, bgPaint);
        textPainter.paint(canvas, Offset(8, yPos - textPainter.height / 2));
      }
    }

    // Dimensions totales en bas à droite
    final dimsText =
        '${widthMeters.toStringAsFixed(1)} × ${heightMeters.toStringAsFixed(1)} m';
    textPainter.text = TextSpan(
      text: dimsText,
      style: textStyle.copyWith(fontSize: 11),
    );
    textPainter.layout();

    final dimsRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width - textPainter.width - 14,
        size.height - textPainter.height - 10,
        textPainter.width + 10,
        textPainter.height + 6,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(dimsRect, bgPaint);
    textPainter.paint(
      canvas,
      Offset(
        size.width - textPainter.width - 9,
        size.height - textPainter.height - 7,
      ),
    );
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

  @override
  void initState() {
    super.initState();
    _bumpController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    // Animation bump : 1.0 -> 1.08 -> 1.0 (rapide)
    _bumpAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_bumpController);
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

  void _onDragEnd(DragEndDetails details) {
    if (widget.isLocked || !_isDragging) return;

    final currentXPx = e.xMeters(cellSizeCm) * kPixelsPerMeter + _dragOffset.dx;
    final currentYPx = e.yMeters(cellSizeCm) * kPixelsPerMeter + _dragOffset.dy;

    double newXMeters = currentXPx / kPixelsPerMeter;
    double newYMeters = currentYPx / kPixelsPerMeter;

    final gardenWidthM = widget.garden.widthCells * cellSizeCm / 100.0;
    final gardenHeightM = widget.garden.heightCells * cellSizeCm / 100.0;

    final elemWidthM = e.widthMeters(cellSizeCm);
    final elemHeightM = e.heightMeters(cellSizeCm);

    newXMeters = newXMeters.clamp(0, gardenWidthM - elemWidthM);
    newYMeters = newYMeters.clamp(0, gardenHeightM - elemHeightM);

    setState(() {
      _isDragging = false;
      _dragOffset = Offset.zero;
    });

    final oldXMeters = e.xMeters(cellSizeCm);
    final oldYMeters = e.yMeters(cellSizeCm);
    if ((newXMeters - oldXMeters).abs() > 0.01 ||
        (newYMeters - oldYMeters).abs() > 0.01) {
      // Petit retour haptique à la fin si position changée
      HapticFeedback.lightImpact();
      widget.onMoved?.call(newXMeters, newYMeters);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Position et taille en pixels
    final xPx = e.xMeters(cellSizeCm) * kPixelsPerMeter;
    final yPx = e.yMeters(cellSizeCm) * kPixelsPerMeter;
    final widthPx = e.widthMeters(cellSizeCm) * kPixelsPerMeter;
    final heightPx = e.heightMeters(cellSizeCm) * kPixelsPerMeter;

    final left = xPx + (_isDragging ? _dragOffset.dx : 0);
    final top = yPx + (_isDragging ? _dragOffset.dy : 0);
    final color = Color(e.color);

    // Taille minimum visible
    final displayWidth = math.max(widthPx, 30.0);
    final displayHeight = math.max(heightPx, 30.0);

    // Taille emoji proportionnelle à la taille de l'élément
    final emojiSize = (math.min(displayWidth, displayHeight) * 0.5).clamp(
      16.0,
      50.0,
    );

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: widget.isLocked ? null : _onDragStart,
        onPanUpdate: widget.isLocked ? null : _onDragUpdate,
        onPanEnd: widget.isLocked ? null : _onDragEnd,
        child: AnimatedBuilder(
          animation: _bumpAnimation,
          builder: (context, child) =>
              Transform.scale(scale: _bumpAnimation.value, child: child),
          child: Container(
            width: displayWidth,
            height: displayHeight,
            decoration: BoxDecoration(
              color: color.withValues(alpha: _isDragging ? 0.95 : 0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isDragging
                    ? Colors.white
                    : (widget.isLocked
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.primary),
                width: _isDragging ? 3 : 2,
              ),
              boxShadow: _isDragging
                  ? [
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
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                // Emoji centré
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.emoji, style: TextStyle(fontSize: emojiSize)),
                      if (displayWidth > 70 && displayHeight > 70)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            e.name,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Indicateur lock amélioré
                if (displayWidth > 40)
                  Positioned(
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
                            ? PhosphorIcons.lock(PhosphorIconsStyle.fill)
                            : PhosphorIcons.arrowsOutCardinal(
                                PhosphorIconsStyle.fill,
                              ),
                        size: 12,
                        color: widget.isLocked
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.white,
                      ),
                    ),
                  ),
                // Indicateur de déplacement quand déverrouillé
                if (!widget.isLocked && displayWidth > 60 && !_isDragging)
                  Positioned(
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
                          color: AppColors.primary.withValues(alpha: 0.9),
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
                  ),
              ],
            ),
          ),
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
