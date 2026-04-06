import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Fond decoratif avec ronds epars utilise sur
/// tous les ecrans principaux de l'application.
class DecorativeBackground extends StatelessWidget {
  const DecorativeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: CustomPaint(
        size: size,
        painter: _BlobsPainter(
          primary: AppColors.primary,
          light: AppColors.primaryContainer,
        ),
      ),
    );
  }
}

class _BlobsPainter extends CustomPainter {
  final Color primary;
  final Color light;

  _BlobsPainter({
    required this.primary,
    required this.light,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..style = PaintingStyle.fill;
    final pale = Paint()..style = PaintingStyle.fill;

    _drawTopRight(canvas, size, dark, pale);
    _drawTopLeft(canvas, size, dark, pale);
    _drawMiddle(canvas, size, dark, pale);
    _drawBottom(canvas, size, dark, pale);
    _drawScattered(canvas, size, dark, pale);
  }

  void _drawTopRight(
    Canvas c, Size s, Paint dark, Paint pale,
  ) {
    pale.color = light.withValues(alpha: 0.5);
    c.drawCircle(Offset(s.width + 20, -30), 120, pale);

    dark.color = primary.withValues(alpha: 0.15);
    c.drawCircle(Offset(s.width - 40, 60), 45, dark);

    pale.color = light.withValues(alpha: 0.4);
    c.drawCircle(Offset(s.width - 20, 130), 25, pale);
  }

  void _drawTopLeft(
    Canvas c, Size s, Paint dark, Paint pale,
  ) {
    pale.color = light.withValues(alpha: 0.35);
    c.drawCircle(const Offset(-30, 80), 55, pale);

    dark.color = primary.withValues(alpha: 0.12);
    c.drawCircle(const Offset(40, 50), 20, dark);
  }

  void _drawMiddle(
    Canvas c, Size s, Paint dark, Paint pale,
  ) {
    pale.color = light.withValues(alpha: 0.3);
    c.drawCircle(
      Offset(-60, s.height * 0.4), 90, pale,
    );

    dark.color = primary.withValues(alpha: 0.1);
    c.drawCircle(
      Offset(25, s.height * 0.35), 18, dark,
    );

    pale.color = light.withValues(alpha: 0.25);
    c.drawCircle(
      Offset(s.width + 30, s.height * 0.5), 70, pale,
    );

    dark.color = primary.withValues(alpha: 0.08);
    c.drawCircle(
      Offset(s.width - 35, s.height * 0.45), 15, dark,
    );
  }

  void _drawBottom(
    Canvas c, Size s, Paint dark, Paint pale,
  ) {
    pale.color = light.withValues(alpha: 0.4);
    c.drawCircle(
      Offset(-50, s.height * 0.75), 100, pale,
    );

    dark.color = primary.withValues(alpha: 0.12);
    c.drawCircle(
      Offset(50, s.height * 0.8), 35, dark,
    );

    pale.color = light.withValues(alpha: 0.3);
    c.drawCircle(
      Offset(20, s.height * 0.7), 22, pale,
    );

    pale.color = light.withValues(alpha: 0.35);
    c.drawCircle(
      Offset(s.width + 40, s.height * 0.85), 80, pale,
    );

    dark.color = primary.withValues(alpha: 0.1);
    c.drawCircle(
      Offset(s.width - 50, s.height * 0.9), 25, dark,
    );
  }

  void _drawScattered(
    Canvas c, Size s, Paint dark, Paint pale,
  ) {
    dark.color = primary.withValues(alpha: 0.06);
    c.drawCircle(
      Offset(s.width * 0.2, s.height * 0.15), 12, dark,
    );
    c.drawCircle(
      Offset(s.width * 0.85, s.height * 0.3), 10, dark,
    );
    c.drawCircle(
      Offset(s.width * 0.15, s.height * 0.55), 8, dark,
    );
    c.drawCircle(
      Offset(s.width * 0.9, s.height * 0.65), 14, dark,
    );

    pale.color = light.withValues(alpha: 0.2);
    c.drawCircle(
      Offset(s.width * 0.75, s.height * 0.2), 16, pale,
    );
    c.drawCircle(
      Offset(s.width * 0.1, s.height * 0.6), 12, pale,
    );
    c.drawCircle(
      Offset(s.width * 0.8, s.height * 0.75), 10, pale,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
