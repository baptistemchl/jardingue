import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_info.dart';
import '../theme/app_typography.dart';

/// Bottom sheet "A propos" avec infos de version, copyright
/// et remerciements.
class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AboutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nom + version
                Text(
                  'Jardingue',
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Version ${AppInfo.version}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mon potager connecte',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                // Remerciements
                const _ThanksCard(),

                const SizedBox(height: 16),

                // Copyright
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIcons.code(PhosphorIconsStyle.bold),
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Concu avec amour pour les jardiniers',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\u00a9 ${DateTime.now().year} Jardingue. Tous droits reserves.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de remerciements avec confettis animes
class _ThanksCard extends StatefulWidget {
  const _ThanksCard();

  @override
  State<_ThanksCard> createState() => _ThanksCardState();
}

class _ThanksCardState extends State<_ThanksCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerConfetti() {
    setState(() => _showConfetti = true);
    _controller.forward(from: 0).then((_) {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerConfetti,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.secondary.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Stack(
          children: [
            // Confettis
            if (_showConfetti)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ConfettiPainter(
                        progress: _controller.value,
                      ),
                    );
                  },
                ),
              ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.heart(PhosphorIconsStyle.fill),
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remerciements',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Un immense merci a Ana & Charles\n'
                    'pour la motivation, les idees folles,\n'
                    'et les sessions de tests intensives !',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tapez pour celebrer !',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confettis animes
class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  static final _particles = List.generate(30, (i) {
    final rng = math.Random(i);
    return (
      x: rng.nextDouble(),
      speed: 0.3 + rng.nextDouble() * 0.7,
      drift: (rng.nextDouble() - 0.5) * 2,
      size: 4 + rng.nextDouble() * 4,
      rotation: rng.nextDouble() * math.pi * 2,
      color: [
        const Color(0xFFFF6B6B),
        const Color(0xFF4ECDC4),
        const Color(0xFFFFE66D),
        const Color(0xFF95E1D3),
        const Color(0xFFF38181),
        const Color(0xFFAA96DA),
        const Color(0xFFFCBF49),
        const Color(0xFF2EC4B6),
      ][i % 8],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fadeOut = progress > 0.7 ? (1.0 - progress) / 0.3 : 1.0;

    for (final p in _particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.8 * fadeOut)
        ..style = PaintingStyle.fill;

      final x = p.x * size.width + p.drift * progress * 40;
      final y = -10 + progress * p.speed * (size.height + 30);
      final angle = p.rotation + progress * 4;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

/// AnimatedBuilder local
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
