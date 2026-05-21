import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Bar chart mensuel — 12 barres animées avec dégradé primary→secondary.
///
/// Le mois courant est légèrement plus opaque pour le mettre en avant.
/// Animation : staggered entrance (chaque barre arrive en cascade avec
/// un easeOutCubic). Le mois "best" (max) est highlighted en jaune.
class MonthlyBarChart extends StatefulWidget {
  final List<int> values; // 12 ints
  final int? bestMonth; // 1-12 ou null
  final int currentMonth; // 1-12

  const MonthlyBarChart({
    super.key,
    required this.values,
    required this.bestMonth,
    required this.currentMonth,
  });

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant MonthlyBarChart old) {
    super.didUpdateWidget(old);
    if (old.values != widget.values) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => CustomPaint(
        painter: _MonthlyBarPainter(
          values: widget.values,
          bestMonth: widget.bestMonth,
          currentMonth: widget.currentMonth,
          progress: _controller.value,
          labelStyle: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
        size: const Size(double.infinity, 140),
      ),
    );
  }
}

class _MonthlyBarPainter extends CustomPainter {
  final List<int> values;
  final int? bestMonth;
  final int currentMonth;
  final double progress;
  final TextStyle labelStyle;

  static const _months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

  _MonthlyBarPainter({
    required this.values,
    required this.bestMonth,
    required this.currentMonth,
    required this.progress,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.fold<int>(0, (m, v) => v > m ? v : m);
    if (maxVal == 0) {
      // État vide : juste les labels et une baseline subtile.
      _drawLabels(canvas, size);
      _drawBaseline(canvas, size);
      return;
    }
    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final barAreaWidth = size.width;
    final barCount = 12;
    final spacing = 4.0;
    final barWidth = (barAreaWidth - spacing * (barCount - 1)) / barCount;

    for (var i = 0; i < 12; i++) {
      final ratio = values[i] / maxVal;
      // Stagger : chaque barre démarre à i * 0.04 du progress global.
      final localStart = i * 0.04;
      final localT = ((progress - localStart) / (1 - localStart)).clamp(0.0, 1.0);
      // Curve easeOutCubic
      final eased = 1 - _pow3(1 - localT);
      final animatedRatio = ratio * eased;
      final barHeight = chartHeight * animatedRatio;
      final x = i * (barWidth + spacing);
      final y = chartHeight - barHeight;
      final isBest = bestMonth == i + 1;
      final isCurrent = currentMonth == i + 1;

      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: isBest
              ? [AppColors.secondary, AppColors.warning]
              : [
                  AppColors.primary.withValues(
                    alpha: isCurrent ? 1.0 : 0.85,
                  ),
                  AppColors.primaryLight.withValues(
                    alpha: isCurrent ? 1.0 : 0.7,
                  ),
                ],
        ).createShader(rect);
      canvas.drawRRect(rrect, paint);
    }

    _drawLabels(canvas, size);
  }

  void _drawBaseline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final y = size.height - 18;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  void _drawLabels(Canvas canvas, Size size) {
    final barAreaWidth = size.width;
    final spacing = 4.0;
    final barWidth = (barAreaWidth - spacing * 11) / 12;
    for (var i = 0; i < 12; i++) {
      final isBest = bestMonth == i + 1;
      final isCurrent = currentMonth == i + 1;
      final color = isBest
          ? AppColors.warning
          : isCurrent
              ? AppColors.primary
              : AppColors.textTertiary;
      final tp = TextPainter(
        text: TextSpan(
          text: _months[i],
          style: labelStyle.copyWith(
            color: color,
            fontWeight:
                isBest || isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = i * (barWidth + spacing) + (barWidth - tp.width) / 2;
      tp.paint(canvas, Offset(x, size.height - tp.height));
    }
  }

  double _pow3(double x) => x * x * x;

  @override
  bool shouldRepaint(_MonthlyBarPainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.bestMonth != bestMonth;
}
