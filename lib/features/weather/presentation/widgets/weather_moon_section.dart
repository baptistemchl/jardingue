import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/lunar/lunar_calendar.dart';
import '../../../../core/theme/app_typography.dart';
import 'lunar_sources_sheet.dart';

/// Hero du jour — l'identité biodynamique. Ce panneau pose le contexte
/// avant le verdict : type de jour Maria Thun, constellation, phase, et
/// si la lune coupe l'écliptique (nœud), une bannière de repos.
class WeatherLunarHeroSection extends StatelessWidget {
  final LunarDay lunar;

  const WeatherLunarHeroSection({super.key, required this.lunar});

  @override
  Widget build(BuildContext context) {
    final abstain = lunar.abstainEvent;
    final isNight = !DateTime.now().hour.isBetween(7, 19);

    return Stack(
      children: [
        // Panneau atmosphérique : dégradé sage profond → primaire clair.
        // Reste sur la palette Jardingue, mais se démarque des cartes
        // blanches standard pour signaler "contexte lunaire".
        Container(
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusXxl,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isNight
                  ? const [
                      Color(0xFF1F3D2C),
                      Color(0xFF2D5A3D),
                      Color(0xFF4A7C59),
                    ]
                  : const [
                      Color(0xFF2D5A3D),
                      Color(0xFF4A7C59),
                      Color(0xFF6B9B7A),
                    ],
            ),
          ),
          child: _Content(lunar: lunar, abstain: abstain),
        ),
        // Halo lumineux derrière la lune
        Positioned(
          top: -32,
          right: -32,
          child: IgnorePointer(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondaryLight.withValues(alpha: 0.18),
                    AppColors.secondaryLight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  final LunarDay lunar;
  final LunarAbstainEvent? abstain;

  const _Content({required this.lunar, required this.abstain});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1 — étiquette discrète + symbole zodiacal en filigrane
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AUJOURD\'HUI',
                style: AppTypography.captionStrong.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                lunar.constellation.symbol,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bloc principal : phase disc + nom du jour
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: _MoonPhasePainter(phaseFraction: lunar.phaseFraction),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lunar.dayType.label,
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lune en ${lunar.constellation.label}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Strip indicateurs lunaires (asc/desc + phase)
          _DimensionStrip(lunar: lunar),
          if (abstain != null) ...[
            const SizedBox(height: 14),
            _AbstainBanner(event: abstain!),
          ],
          const SizedBox(height: 14),
          const _SourcesLink(),
        ],
      ),
    );
  }
}

class _SourcesLink extends StatelessWidget {
  const _SourcesLink();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusFull,
        onTap: () => LunarSourcesSheet.show(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.info(PhosphorIconsStyle.regular),
                size: 14,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 6),
              Text(
                'Sources & méthode (Maria Thun, Meeus, Open-Meteo)',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DimensionStrip extends StatelessWidget {
  final LunarDay lunar;

  const _DimensionStrip({required this.lunar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DimensionItem(
              icon: lunar.isAscending
                  ? PhosphorIcons.arrowLineUp(PhosphorIconsStyle.regular)
                  : PhosphorIcons.arrowLineDown(PhosphorIconsStyle.regular),
              label: lunar.isAscending ? 'Montante' : 'Descendante',
              hint:
                  lunar.isAscending ? 'la sève monte' : 'la sève redescend',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          Expanded(
            child: _DimensionItem(
              icon: lunar.isWaxing
                  ? PhosphorIcons.plus(PhosphorIconsStyle.regular)
                  : PhosphorIcons.minus(PhosphorIconsStyle.regular),
              label: lunar.isWaxing ? 'Croissante' : 'Décroissante',
              hint: lunar.phase.label.toLowerCase(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;

  const _DimensionItem({
    required this.icon,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondaryLight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AbstainBanner extends StatelessWidget {
  final LunarAbstainEvent event;

  const _AbstainBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE07A5F).withValues(alpha: 0.25),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: const Color(0xFFE07A5F).withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIcons.handPalm(PhosphorIconsStyle.regular),
            size: 22,
            color: const Color(0xFFFFD7C2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.label.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFFFFD7C2),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.94),
                    height: 1.35,
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

/// Phase de lune — version polie (terminator ellipsoïdal Meeus-style).
/// Disque sombre derrière, partie illuminée en `secondary`.
class _MoonPhasePainter extends CustomPainter {
  final double phaseFraction;

  _MoonPhasePainter({required this.phaseFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    // Disque sombre de fond
    final darkPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF1F3D2C), Color(0xFF0E1F16)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, darkPaint);

    // Disque illuminé : on dessine d'abord la moitié claire, puis on
    // ajoute/retire une ellipse pour faire varier la courbe du terminator.
    final litPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        colors: const [Color(0xFFFFF1C1), Color(0xFFE9C46A)],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    // litRight = lune croissante (illuminée à droite dans l'hémisphère N).
    final litRight = phaseFraction < 0.5;
    final halfRect = Rect.fromCircle(center: center, radius: r);
    final startAngle = litRight ? -math.pi / 2 : math.pi / 2;

    canvas.save();
    canvas.clipPath(Path()..addOval(halfRect));
    // Demi-cercle illuminé
    canvas.drawArc(halfRect, startAngle, math.pi, true, litPaint);

    // Ellipse du terminator. cos(2π × phase) :
    //   phase 0   → 1   : ellipse complète sombre dans la partie lit → tout sombre
    //   phase 0.25→ 0   : pas d'ellipse → demi-disque illuminé (1er quartier)
    //   phase 0.5 → -1  : ellipse claire dans la partie sombre → pleine lune
    final factor = math.cos(2 * math.pi * phaseFraction);
    final ellipseW = r * factor.abs();
    if (ellipseW > 0.5) {
      final ellipseRect = Rect.fromCenter(
        center: center,
        width: ellipseW * 2,
        height: r * 2,
      );
      final terminatorPaint = factor > 0 ? darkPaint : litPaint;
      canvas.drawOval(ellipseRect, terminatorPaint);
    }
    canvas.restore();

    // Cercle de contour très subtil pour la matière
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.15);
    canvas.drawCircle(center, r - 0.4, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _MoonPhasePainter old) =>
      old.phaseFraction != phaseFraction;
}

extension on int {
  bool isBetween(int min, int max) => this >= min && this <= max;
}
