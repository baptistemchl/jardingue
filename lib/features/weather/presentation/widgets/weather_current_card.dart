import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../core/theme/app_typography.dart';
import 'weather_animations.dart' as anim;

class WeatherCurrentCard extends StatelessWidget {
  final WeatherData weather;

  const WeatherCurrentCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final condition = current.condition;
    final daily = weather.dailyForecast.isNotEmpty
        ? weather.dailyForecast[0]
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Fond animé
          Positioned.fill(
            child: _CardWeatherAnimation(condition: condition),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.cloudSun(PhosphorIconsStyle.fill),
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('Conditions actuelles',
                        style: AppTypography.titleMedium),
                  ],
                ),
                const SizedBox(height: 16),

                // Température + icone
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.temperatureDisplay,
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 56,
                              fontWeight: FontWeight.w200,
                              color: AppColors.textPrimary,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            condition.label,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Ressenti ${current.feelsLikeDisplay}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (daily != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.arrowUp(
                                      PhosphorIconsStyle.bold),
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                Text(
                                  ' ${daily.tempMaxDisplay}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  PhosphorIcons.arrowDown(
                                      PhosphorIconsStyle.bold),
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                Text(
                                  ' ${daily.tempMinDisplay}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(condition.icon, style: const TextStyle(fontSize: 56)),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _WeatherStat(
                      icon: PhosphorIcons.drop(PhosphorIconsStyle.fill),
                      value: current.humidityDisplay,
                      label: 'Humidite',
                    ),
                    _WeatherStat(
                      icon: PhosphorIcons.wind(PhosphorIconsStyle.fill),
                      value: current.windSpeedDisplay,
                      label: 'Vent ${current.windDirectionDisplay}',
                    ),
                    _WeatherStat(
                      icon: PhosphorIcons.sun(PhosphorIconsStyle.fill),
                      value: 'UV ${current.uvIndex.round()}',
                      label: _uvLabel(current.uvIndex),
                    ),
                    _WeatherStat(
                      icon: PhosphorIcons.cloudRain(PhosphorIconsStyle.fill),
                      value: '${current.precipitation.toStringAsFixed(1)}mm',
                      label: 'Precip.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _uvLabel(double uv) {
    if (uv <= 2) return 'Faible';
    if (uv <= 5) return 'Modere';
    if (uv <= 7) return 'Eleve';
    if (uv <= 10) return 'Tres eleve';
    return 'Extreme';
  }
}

// ============================================
// STATS
// ============================================

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WeatherStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ============================================
// ANIMATION DE FOND POUR LA CARD
// ============================================

class _CardWeatherAnimation extends StatefulWidget {
  final WeatherCondition condition;

  const _CardWeatherAnimation({required this.condition});

  @override
  State<_CardWeatherAnimation> createState() => _CardWeatherAnimationState();
}

class _CardWeatherAnimationState extends State<_CardWeatherAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _animationDuration,
      vsync: this,
    )..repeat();
  }

  Duration get _animationDuration {
    final anim = widget.condition.animation;
    if (anim == 'sunny' || anim == 'clear_night') {
      return const Duration(seconds: 8);
    }
    if (anim == 'snow') return const Duration(seconds: 4);
    if (anim == 'cloudy' || anim == 'partly_cloudy' || anim == 'fog') {
      return const Duration(seconds: 15);
    }
    return const Duration(seconds: 2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gradient subtil selon la météo
    final primary = Color(widget.condition.primaryColor);
    final secondary = Color(widget.condition.secondaryColor);

    return Stack(
      children: [
        // Gradient de fond léger
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                primary.withValues(alpha: 0.08),
                secondary.withValues(alpha: 0.04),
                AppColors.surface,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),

        // Animation custom painter
        anim.AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _getCardPainter(
                widget.condition.animation,
                _controller.value,
                primary,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }

  CustomPainter _getCardPainter(
      String animation, double progress, Color color) {
    return switch (animation) {
      'sunny' => _CardSunPainter(progress: progress),
      'clear_night' => _CardNightPainter(progress: progress),
      'rain' || 'drizzle' => _CardRainPainter(
          progress: progress, intensity: 0.5),
      'heavy_rain' || 'freezing_rain' => _CardRainPainter(
          progress: progress, intensity: 1.0),
      'snow' => _CardSnowPainter(progress: progress),
      'cloudy' || 'partly_cloudy' || 'fog' => _CardCloudPainter(
          progress: progress, color: color),
      'thunderstorm' => _CardThunderstormPainter(progress: progress),
      _ => _CardCloudPainter(progress: progress, color: color),
    };
  }
}

// ============================================
// PAINTERS
// ============================================

/// Soleil : halo doux + rayons qui tournent
class _CardSunPainter extends CustomPainter {
  final double progress;
  _CardSunPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.15);

    // Halo
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFA726).withValues(alpha: 0.15),
          const Color(0xFFFFA726).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 80));
    canvas.drawCircle(center, 80, haloPaint);

    // Rayons subtils
    final rayPaint = Paint()
      ..color = const Color(0xFFFFA726).withValues(alpha: 0.08)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 10; i++) {
      final angle = (i / 10) * 2 * math.pi + progress * 2 * math.pi;
      final inner = 30.0;
      final outer = 55 + math.sin(progress * 2 * math.pi + i) * 8;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * inner,
          center.dy + math.sin(angle) * inner,
        ),
        Offset(
          center.dx + math.cos(angle) * outer,
          center.dy + math.sin(angle) * outer,
        ),
        rayPaint,
      );
    }

    // Disque soleil
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF176).withValues(alpha: 0.2),
          const Color(0xFFFFB74D).withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 22));
    canvas.drawCircle(center, 22, sunPaint);
  }

  @override
  bool shouldRepaint(_CardSunPainter old) => true;
}

/// Nuit claire : petites etoiles scintillantes
class _CardNightPainter extends CustomPainter {
  final double progress;
  _CardNightPainter({required this.progress});

  static final _stars = List.generate(12, (i) {
    final rng = math.Random(i);
    return Offset(rng.nextDouble(), rng.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final twinkle =
          (math.sin(progress * 2 * math.pi * 3 + i * 1.7) + 1) / 2;
      paint.color = Colors.indigo.withValues(alpha: 0.05 + twinkle * 0.1);
      final r = 2 + twinkle * 2;
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CardNightPainter old) => true;
}

/// Pluie : gouttes qui tombent
class _CardRainPainter extends CustomPainter {
  final double progress;
  final double intensity;
  _CardRainPainter({required this.progress, required this.intensity});

  static final _drops = List.generate(25, (i) {
    final rng = math.Random(i);
    return (
      x: rng.nextDouble(),
      speed: 0.5 + rng.nextDouble() * 0.5,
      length: 8 + rng.nextDouble() * 14.0,
      startY: rng.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = (25 * intensity).round();
    final paint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.12 + intensity * 0.08)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < count; i++) {
      final d = _drops[i];
      final x = d.x * size.width;
      final totalTravel = size.height + d.length;
      final y = ((d.startY + progress * d.speed * 2) % 1.3) * totalTravel -
          d.length;
      canvas.drawLine(Offset(x, y), Offset(x - 1.5, y + d.length), paint);
    }
  }

  @override
  bool shouldRepaint(_CardRainPainter old) => true;
}

/// Neige : flocons flottants
class _CardSnowPainter extends CustomPainter {
  final double progress;
  _CardSnowPainter({required this.progress});

  static final _flakes = List.generate(18, (i) {
    final rng = math.Random(i);
    return (
      x: rng.nextDouble(),
      speed: 0.15 + rng.nextDouble() * 0.25,
      size: 2 + rng.nextDouble() * 3.5,
      startY: rng.nextDouble(),
      wobble: rng.nextDouble() * 2 * math.pi,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    for (final f in _flakes) {
      final wobble =
          math.sin(progress * 2 * math.pi + f.wobble) * 15;
      final x = f.x * size.width + wobble;
      final y = ((f.startY + progress * f.speed) % 1.15) * size.height;
      canvas.drawCircle(Offset(x, y), f.size, paint);
    }
  }

  @override
  bool shouldRepaint(_CardSnowPainter old) => true;
}

/// Nuages : bulles qui derivent
class _CardCloudPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CardCloudPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    void drawBlob(double phase, double yFrac, double radius, double alpha) {
      paint.color = color.withValues(alpha: alpha);
      final x = ((progress + phase) * 1.3 % 1.4) * (size.width + radius * 2) -
          radius;
      final y = size.height * yFrac;
      // Forme arrondie (3 cercles)
      canvas.drawCircle(Offset(x, y), radius, paint);
      canvas.drawCircle(Offset(x - radius * 0.5, y + 4), radius * 0.7, paint);
      canvas.drawCircle(Offset(x + radius * 0.5, y + 2), radius * 0.8, paint);
    }

    drawBlob(0.0, 0.12, 30, 0.06);
    drawBlob(0.4, 0.25, 22, 0.05);
    drawBlob(0.7, 0.08, 18, 0.04);
  }

  @override
  bool shouldRepaint(_CardCloudPainter old) => true;
}

/// Orage : pluie + eclairs
class _CardThunderstormPainter extends CustomPainter {
  final double progress;
  _CardThunderstormPainter({required this.progress});

  static final _drops = _CardRainPainter._drops;

  @override
  void paint(Canvas canvas, Size size) {
    // Pluie forte
    final rainPaint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.15)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 20; i++) {
      final d = _drops[i];
      final x = d.x * size.width;
      final totalTravel = size.height + d.length;
      final y =
          ((d.startY + progress * d.speed * 2) % 1.3) * totalTravel - d.length;
      canvas.drawLine(Offset(x, y), Offset(x - 1.5, y + d.length), rainPaint);
    }

    // Eclair subtil (flash periodique)
    final flashPhase = (progress * 7) % 1.0;
    if (flashPhase < 0.05) {
      final lightningPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: 0.08);
      canvas.drawRect(Offset.zero & size, lightningPaint);

      // Petite forme eclair
      final boltPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: 0.15)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final bx = size.width * 0.7;
      final by = size.height * 0.1;
      final path = Path()
        ..moveTo(bx, by)
        ..lineTo(bx - 8, by + 18)
        ..lineTo(bx + 4, by + 16)
        ..lineTo(bx - 4, by + 35);
      canvas.drawPath(path, boltPaint);
    }
  }

  @override
  bool shouldRepaint(_CardThunderstormPainter old) => true;
}

