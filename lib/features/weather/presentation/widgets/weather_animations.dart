import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/services/weather/weather_models.dart';

/// Background animé selon la météo
class WeatherBackground extends StatelessWidget {
  final WeatherCondition condition;

  const WeatherBackground({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient de fond
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(condition.primaryColor).withValues(alpha: 0.3),
                Color(condition.secondaryColor).withValues(alpha: 0.1),
                const Color(0xFFF5F7F2),
              ],
              stops: const [0.0, 0.3, 0.7],
            ),
          ),
        ),

        // Animations selon la condition
        if (condition.animation == 'rain' || condition.animation == 'drizzle')
          const RainAnimation(intensity: 0.5),
        if (condition.animation == 'heavy_rain')
          const RainAnimation(intensity: 1.0),
        if (condition.animation == 'snow') const SnowAnimation(),
        if (condition.animation == 'sunny') const SunAnimation(),
        if (condition.animation == 'partly_cloudy' ||
            condition.animation == 'cloudy')
          const CloudsAnimation(),
        if (condition.animation == 'thunderstorm')
          const ThunderstormAnimation(),
      ],
    );
  }
}

/// Animation de pluie
class RainAnimation extends StatefulWidget {
  final double intensity; // 0.0 - 1.0

  const RainAnimation({super.key, this.intensity = 0.5});

  @override
  State<RainAnimation> createState() => _RainAnimationState();
}

class _RainAnimationState extends State<RainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<RainDrop> _drops;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    final dropCount = (50 * widget.intensity).round();
    _drops = List.generate(dropCount, (_) => RainDrop.random());
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
      builder: (context, child) {
        return CustomPaint(
          painter: RainPainter(
            drops: _drops,
            progress: _controller.value,
            intensity: widget.intensity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class RainDrop {
  final double x; // 0-1
  final double speed; // vitesse relative
  final double length;
  final double startY;

  RainDrop({
    required this.x,
    required this.speed,
    required this.length,
    required this.startY,
  });

  factory RainDrop.random() {
    final random = math.Random();
    return RainDrop(
      x: random.nextDouble(),
      speed: 0.5 + random.nextDouble() * 0.5,
      length: 10 + random.nextDouble() * 20,
      startY: random.nextDouble(),
    );
  }
}

class RainPainter extends CustomPainter {
  final List<RainDrop> drops;
  final double progress;
  final double intensity;

  RainPainter({
    required this.drops,
    required this.progress,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.3 + intensity * 0.3)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final drop in drops) {
      final x = drop.x * size.width;
      final totalTravel = size.height + drop.length;
      final y =
          ((drop.startY + progress * drop.speed * 2) % 1.2) * totalTravel -
          drop.length;

      canvas.drawLine(Offset(x, y), Offset(x - 2, y + drop.length), paint);
    }
  }

  @override
  bool shouldRepaint(RainPainter oldDelegate) => true;
}

/// Animation de neige
class SnowAnimation extends StatefulWidget {
  const SnowAnimation({super.key});

  @override
  State<SnowAnimation> createState() => _SnowAnimationState();
}

class _SnowAnimationState extends State<SnowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Snowflake> _flakes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _flakes = List.generate(40, (_) => Snowflake.random());
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
      builder: (context, child) {
        return CustomPaint(
          painter: SnowPainter(flakes: _flakes, progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class Snowflake {
  final double x;
  final double speed;
  final double size;
  final double startY;
  final double wobble;

  Snowflake({
    required this.x,
    required this.speed,
    required this.size,
    required this.startY,
    required this.wobble,
  });

  factory Snowflake.random() {
    final random = math.Random();
    return Snowflake(
      x: random.nextDouble(),
      speed: 0.2 + random.nextDouble() * 0.3,
      size: 3 + random.nextDouble() * 5,
      startY: random.nextDouble(),
      wobble: random.nextDouble() * 2 * math.pi,
    );
  }
}

class SnowPainter extends CustomPainter {
  final List<Snowflake> flakes;
  final double progress;

  SnowPainter({required this.flakes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (final flake in flakes) {
      final wobbleOffset = math.sin(progress * 2 * math.pi + flake.wobble) * 20;
      final x = flake.x * size.width + wobbleOffset;
      final y = ((flake.startY + progress * flake.speed) % 1.1) * size.height;

      canvas.drawCircle(Offset(x, y), flake.size, paint);
    }
  }

  @override
  bool shouldRepaint(SnowPainter oldDelegate) => true;
}

/// Animation de soleil
class SunAnimation extends StatefulWidget {
  const SunAnimation({super.key});

  @override
  State<SunAnimation> createState() => _SunAnimationState();
}

class _SunAnimationState extends State<SunAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
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
      builder: (context, child) {
        return CustomPaint(
          painter: SunPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class SunPainter extends CustomPainter {
  final double progress;

  SunPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.8, size.height * 0.15);

    // Rayons
    final rayPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.2)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi + progress * 2 * math.pi;
      final innerRadius = 40.0;
      final outerRadius = 70 + math.sin(progress * 2 * math.pi + i) * 10;

      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * innerRadius,
          center.dy + math.sin(angle) * innerRadius,
        ),
        Offset(
          center.dx + math.cos(angle) * outerRadius,
          center.dy + math.sin(angle) * outerRadius,
        ),
        rayPaint,
      );
    }

    // Halo
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.orange.withValues(alpha: 0.3),
          Colors.orange.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 80));
    canvas.drawCircle(center, 80, haloPaint);

    // Soleil
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF176), Color(0xFFFFB74D)],
      ).createShader(Rect.fromCircle(center: center, radius: 35));
    canvas.drawCircle(center, 35, sunPaint);
  }

  @override
  bool shouldRepaint(SunPainter oldDelegate) => true;
}

/// Animation de nuages
class CloudsAnimation extends StatefulWidget {
  const CloudsAnimation({super.key});

  @override
  State<CloudsAnimation> createState() => _CloudsAnimationState();
}

class _CloudsAnimationState extends State<CloudsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
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
      builder: (context, child) {
        return CustomPaint(
          painter: CloudsPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class CloudsPainter extends CustomPainter {
  final double progress;

  CloudsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Nuage 1
    _drawCloud(
      canvas,
      Offset(
        (progress * size.width * 1.5) % (size.width + 200) - 100,
        size.height * 0.1,
      ),
      80,
      paint,
    );

    // Nuage 2
    _drawCloud(
      canvas,
      Offset(
        ((progress + 0.3) * size.width * 1.2) % (size.width + 200) - 100,
        size.height * 0.2,
      ),
      60,
      paint..color = Colors.white.withValues(alpha: 0.4),
    );

    // Nuage 3
    _drawCloud(
      canvas,
      Offset(
        ((progress + 0.6) * size.width * 1.3) % (size.width + 200) - 100,
        size.height * 0.05,
      ),
      50,
      paint..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  void _drawCloud(Canvas canvas, Offset center, double scale, Paint paint) {
    final path = Path();

    // Forme de nuage avec plusieurs cercles
    path.addOval(
      Rect.fromCenter(center: center, width: scale, height: scale * 0.6),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(center.dx - scale * 0.3, center.dy),
        width: scale * 0.7,
        height: scale * 0.5,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(center.dx + scale * 0.3, center.dy),
        width: scale * 0.8,
        height: scale * 0.55,
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - scale * 0.15),
        width: scale * 0.6,
        height: scale * 0.5,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CloudsPainter oldDelegate) => true;
}

/// Animation d'orage
class ThunderstormAnimation extends StatefulWidget {
  const ThunderstormAnimation({super.key});

  @override
  State<ThunderstormAnimation> createState() => _ThunderstormAnimationState();
}

class _ThunderstormAnimationState extends State<ThunderstormAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _lightningOpacity = 0;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _controller.addListener(_checkLightning);
  }

  void _checkLightning() {
    if (_random.nextDouble() < 0.01) {
      setState(() => _lightningOpacity = 0.8);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _lightningOpacity = 0);
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkLightning);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const RainAnimation(intensity: 1.0),
        const CloudsAnimation(),
        // Flash d'éclair
        AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          color: Colors.white.withValues(alpha: _lightningOpacity),
        ),
      ],
    );
  }
}

/// AnimatedBuilder personnalisé
class AnimatedBuilder extends AnimatedWidget {
  final TransitionBuilder builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
