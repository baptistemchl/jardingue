import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_decoration.dart';
import '../../../../core/providers/weather_providers.dart';
import '../../../../core/services/weather/weather_models.dart';
import '../../../../router/app_router.dart';

/// Écran principal du potager
class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text('Mon Potager', style: AppTypography.displayMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Planifiez et organisez votre jardin',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // Carte météo rapide
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.horizontalPadding,
                child: const QuickWeatherCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

            // Zone du plan (placeholder)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.horizontalPadding,
                child: _GardenPlanPlaceholder(),
              ),
            ),

            // Espace pour la bottom nav
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

/// Carte météo rapide avec animations
class QuickWeatherCard extends ConsumerWidget {
  const QuickWeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherDataProvider);

    return weatherAsync.when(
      data: (weather) => _AnimatedWeatherCard(
        weather: weather,
        onTap: () => context.go(AppRoutes.weather),
      ),
      loading: () => const _WeatherCardLoading(),
      error: (_, __) => _WeatherCardError(
        onRetry: () => ref.invalidate(weatherDataProvider),
      ),
    );
  }
}

/// Carte météo animée
class _AnimatedWeatherCard extends StatelessWidget {
  final WeatherData weather;
  final VoidCallback onTap;

  const _AnimatedWeatherCard({
    required this.weather,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final condition = current.condition;
    final moon = weather.moon;
    final advice = weather.gardeningAdvice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusXxl,
          boxShadow: [
            BoxShadow(
              color: Color(condition.primaryColor).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppSpacing.borderRadiusXxl,
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(condition.primaryColor),
                      Color(condition.secondaryColor),
                    ],
                  ),
                ),
              ),

              // Animations météo
              _WeatherAnimationLayer(animation: condition.animation),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Gauche: Température et condition
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                current.temperatureDisplay,
                                style: AppTypography.displayMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w300,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                condition.icon,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            condition.label,
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              advice.mainAdvice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Droite: Stats rapides
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(moon.phaseEmoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Text(
                              '${moon.moonAdvice.score}/5',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _MiniStat(
                          icon: PhosphorIcons.drop(PhosphorIconsStyle.fill),
                          value: current.humidityDisplay,
                        ),
                        const SizedBox(height: 4),
                        _MiniStat(
                          icon: PhosphorIcons.wind(PhosphorIconsStyle.fill),
                          value: current.windSpeedDisplay,
                        ),
                        const Spacer(),
                        Icon(
                          PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _MiniStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

/// Layer d'animation selon le type de météo
class _WeatherAnimationLayer extends StatelessWidget {
  final String animation;

  const _WeatherAnimationLayer({required this.animation});

  @override
  Widget build(BuildContext context) {
    switch (animation) {
      case 'sunny':
        return const _SunnyAnimation();
      case 'rain':
      case 'drizzle':
        return const _RainAnimation(intensity: 0.5);
      case 'heavy_rain':
        return const _RainAnimation(intensity: 1.0);
      case 'cloudy':
      case 'partly_cloudy':
        return const _CloudsAnimation();
      case 'snow':
        return const _SnowAnimation();
      case 'clear_night':
        return const _NightAnimation();
      case 'thunderstorm':
        return const _ThunderstormAnimation();
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Animation soleil
class _SunnyAnimation extends StatefulWidget {
  const _SunnyAnimation();

  @override
  State<_SunnyAnimation> createState() => _SunnyAnimationState();
}

class _SunnyAnimationState extends State<_SunnyAnimation>
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
        return Positioned(
          right: -30,
          top: -30,
          child: Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _SunPainter(),
            ),
          ),
        );
      },
    );
  }
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow.withValues(alpha: 0.4),
          Colors.orange.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 60));
    canvas.drawCircle(center, 60, haloPaint);

    final rayPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * 25, center.dy + math.sin(angle) * 25),
        Offset(center.dx + math.cos(angle) * 45, center.dy + math.sin(angle) * 45),
        rayPaint,
      );
    }

    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF59D), Color(0xFFFFB74D)],
      ).createShader(Rect.fromCircle(center: center, radius: 20));
    canvas.drawCircle(center, 20, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animation nuages - défilement continu sans reset
class _CloudsAnimation extends StatefulWidget {
  const _CloudsAnimation();

  @override
  State<_CloudsAnimation> createState() => _CloudsAnimationState();
}

class _CloudsAnimationState extends State<_CloudsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 60), // Très lent pour éviter le reset visible
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
        return LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _CloudsPainter(
                progress: _controller.value,
                width: constraints.maxWidth,
              ),
            );
          },
        );
      },
    );
  }
}

class _CloudsPainter extends CustomPainter {
  final double progress;
  final double width;

  _CloudsPainter({required this.progress, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    _drawCloudGroup(canvas, size, progress, 0.0, 12, 0.4, 1.0);
    _drawCloudGroup(canvas, size, progress * 0.6, 0.4, 50, 0.25, 0.7);
    _drawCloudGroup(canvas, size, progress * 0.4, 0.7, 85, 0.2, 0.5);
  }

  void _drawCloudGroup(
      Canvas canvas,
      Size size,
      double prog,
      double startOffset,
      double y,
      double opacity,
      double scale,
      ) {
    // Position qui boucle proprement
    final totalTravel = size.width + 150 * scale;
    final x = ((prog + startOffset) % 1.0) * totalTravel - 80 * scale;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity);

    final baseRadius = 25 * scale;

    // Dessine un groupe de cercles pour former un nuage
    // Centre
    canvas.drawCircle(Offset(x, y), baseRadius, paint);
    // Gauche
    canvas.drawCircle(Offset(x - baseRadius * 0.9, y + baseRadius * 0.2), baseRadius * 0.7, paint);
    // Droite
    canvas.drawCircle(Offset(x + baseRadius * 1.0, y + baseRadius * 0.15), baseRadius * 0.85, paint);
    // Haut gauche
    canvas.drawCircle(Offset(x - baseRadius * 0.3, y - baseRadius * 0.5), baseRadius * 0.6, paint);
    // Haut droite
    canvas.drawCircle(Offset(x + baseRadius * 0.4, y - baseRadius * 0.4), baseRadius * 0.7, paint);
  }

  @override
  bool shouldRepaint(_CloudsPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Animation pluie
class _RainAnimation extends StatefulWidget {
  final double intensity;
  const _RainAnimation({this.intensity = 0.5});

  @override
  State<_RainAnimation> createState() => _RainAnimationState();
}

class _RainAnimationState extends State<_RainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Drop> _drops;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    final random = math.Random(42);
    final count = (20 * widget.intensity).round();
    _drops = List.generate(count, (_) => _Drop(
      x: random.nextDouble(),
      speed: 0.5 + random.nextDouble() * 0.5,
      length: 8 + random.nextDouble() * 12,
      offset: random.nextDouble(),
    ));
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
          size: Size.infinite,
          painter: _RainPainter(drops: _drops, progress: _controller.value),
        );
      },
    );
  }
}

class _Drop {
  final double x, speed, length, offset;
  _Drop({required this.x, required this.speed, required this.length, required this.offset});
}

class _RainPainter extends CustomPainter {
  final List<_Drop> drops;
  final double progress;

  _RainPainter({required this.drops, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final drop in drops) {
      final x = drop.x * size.width;
      final y = ((progress * drop.speed + drop.offset) % 1.0) * (size.height + drop.length * 2) - drop.length;
      canvas.drawLine(Offset(x, y), Offset(x - 1, y + drop.length), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter oldDelegate) => true;
}

/// Animation neige
class _SnowAnimation extends StatefulWidget {
  const _SnowAnimation();

  @override
  State<_SnowAnimation> createState() => _SnowAnimationState();
}

class _SnowAnimationState extends State<_SnowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Flake> _flakes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    final random = math.Random(42);
    _flakes = List.generate(15, (_) => _Flake(
      x: random.nextDouble(),
      speed: 0.2 + random.nextDouble() * 0.3,
      size: 2 + random.nextDouble() * 3,
      offset: random.nextDouble(),
      wobble: random.nextDouble() * 2 * math.pi,
    ));
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
          size: Size.infinite,
          painter: _SnowPainter(flakes: _flakes, progress: _controller.value),
        );
      },
    );
  }
}

class _Flake {
  final double x, speed, size, offset, wobble;
  _Flake({required this.x, required this.speed, required this.size, required this.offset, required this.wobble});
}

class _SnowPainter extends CustomPainter {
  final List<_Flake> flakes;
  final double progress;

  _SnowPainter({required this.flakes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.7);

    for (final flake in flakes) {
      final wobbleX = math.sin(progress * 4 * math.pi + flake.wobble) * 8;
      final x = flake.x * size.width + wobbleX;
      final y = ((progress * flake.speed + flake.offset) % 1.0) * (size.height + 20) - 10;
      canvas.drawCircle(Offset(x, y), flake.size, paint);
    }
  }

  @override
  bool shouldRepaint(_SnowPainter oldDelegate) => true;
}

/// Animation nuit
class _NightAnimation extends StatefulWidget {
  const _NightAnimation();

  @override
  State<_NightAnimation> createState() => _NightAnimationState();
}

class _NightAnimationState extends State<_NightAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
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
          size: Size.infinite,
          painter: _NightPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _NightPainter extends CustomPainter {
  final double progress;
  static final _stars = List.generate(12, (i) {
    final r = math.Random(i);
    return _StarData(r.nextDouble(), r.nextDouble() * 0.7, 1 + r.nextDouble() * 2, r.nextDouble() * math.pi * 2);
  });

  _NightPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final twinkle = 0.3 + 0.7 * ((math.sin(progress * math.pi + star.phase) + 1) / 2);
      final paint = Paint()..color = Colors.white.withValues(alpha: twinkle * 0.8);
      canvas.drawCircle(Offset(star.x * size.width, star.y * size.height), star.size, paint);
    }

    // Lune
    final moonCenter = Offset(size.width - 30, 25);
    canvas.drawCircle(moonCenter, 18, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawCircle(moonCenter, 28, Paint()
      ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.2), Colors.transparent])
          .createShader(Rect.fromCircle(center: moonCenter, radius: 28)));
  }

  @override
  bool shouldRepaint(_NightPainter oldDelegate) => oldDelegate.progress != progress;
}

class _StarData {
  final double x, y, size, phase;
  _StarData(this.x, this.y, this.size, this.phase);
}

/// Animation orage
class _ThunderstormAnimation extends StatefulWidget {
  const _ThunderstormAnimation();

  @override
  State<_ThunderstormAnimation> createState() => _ThunderstormAnimationState();
}

class _ThunderstormAnimationState extends State<_ThunderstormAnimation> {
  double _flash = 0;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _scheduleLightning();
  }

  void _scheduleLightning() {
    Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(4000)), () {
      if (mounted) {
        setState(() => _flash = 0.5);
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) setState(() => _flash = 0);
        });
        _scheduleLightning();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _RainAnimation(intensity: 1.0),
        const _CloudsAnimation(),
        Container(color: Colors.white.withValues(alpha: _flash)),
      ],
    );
  }
}

/// Chargement
class _WeatherCardLoading extends StatelessWidget {
  const _WeatherCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXxl,
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(height: 8),
            Text('Chargement météo...'),
          ],
        ),
      ),
    );
  }
}

/// Erreur
class _WeatherCardError extends StatelessWidget {
  final VoidCallback onRetry;
  const _WeatherCardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXxl,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: const Icon(Icons.cloud_off, color: AppColors.error),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Météo indisponible', style: AppTypography.titleSmall),
                Text('Vérifiez votre connexion', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

/// Placeholder jardin
class _GardenPlanPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXxl,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppSpacing.borderRadiusXl,
              ),
              child: Icon(PhosphorIcons.gridNine(PhosphorIconsStyle.duotone), size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Votre potager est vide', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Commencez par ajouter des plantes', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
              label: const Text('Créer mon potager'),
            ),
          ],
        ),
      ),
    );
  }
}

/// AnimatedBuilder
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