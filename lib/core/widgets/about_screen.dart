import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jardingue/l10n/generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_info.dart';
import '../theme/app_typography.dart';
import '../widgets/decorative_background.dart';

/// Page "A propos" plein ecran avec scroll.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const DecorativeBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Bouton retour
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      top: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () =>
                            context.pop(),
                        icon: Icon(
                          PhosphorIcons.arrowLeft(
                            PhosphorIconsStyle.bold,
                          ),
                          color:
                              AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenu
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors
                                .primaryContainer,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors
                                    .primary
                                    .withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 16,
                                offset:
                                    const Offset(
                                  0,
                                  6,
                                ),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius
                                    .circular(20),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nom + version
                        Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .appName,
                          style: AppTypography
                              .displayMedium
                              .copyWith(
                            color:
                                AppColors.primary,
                            fontWeight:
                                FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets
                              .symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors
                                .primaryContainer
                                .withValues(
                              alpha: 0.5,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(8),
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .aboutVersion(
                              AppInfo.version,
                            ),
                            style: AppTypography
                                .caption
                                .copyWith(
                              color:
                                  AppColors.primary,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .aboutSubtitle,
                          style: AppTypography
                              .bodySmall
                              .copyWith(
                            color: AppColors
                                .textSecondary,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Remerciements
                        const _ThanksCard(),

                        const SizedBox(height: 16),

                        // Famille
                        const _FamilyCard(),

                        const SizedBox(height: 16),

                        // Sources
                        _buildSection(
                          context,
                          icon: PhosphorIcons
                              .bookOpen(
                            PhosphorIconsStyle.fill,
                          ),
                          iconColor:
                              AppColors.primary,
                          title:
                              AppLocalizations.of(
                            context,
                          )!
                                  .aboutSourcesTitle,
                          body:
                              AppLocalizations.of(
                            context,
                          )!
                                  .aboutSourcesBody,
                        ),

                        const SizedBox(height: 16),

                        // Copyright & contact
                        _buildCopyright(context),

                        SizedBox(
                          height:
                              bottomPadding + 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelSmall
                      .copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style:
                AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyright(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.code(
                  PhosphorIconsStyle.bold,
                ),
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!
                      .aboutMadeWithLove,
                  style: AppTypography.caption
                      .copyWith(
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(
                'mailto:${AppLocalizations.of(context)!.aboutContact}',
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.envelope(
                    PhosphorIconsStyle.regular,
                  ),
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!
                        .aboutContact,
                    style: AppTypography.caption
                        .copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration
                          .underline,
                      decorationColor:
                          AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!
                .aboutCopyright(
              DateTime.now().year.toString(),
            ),
            style:
                AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
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
  State<_ThanksCard> createState() =>
      _ThanksCardState();
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
      if (mounted) {
        setState(() => _showConfetti = false);
      }
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
              AppColors.primary
                  .withValues(alpha: 0.08),
              AppColors.secondary
                  .withValues(alpha: 0.06),
            ],
          ),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary
                .withValues(alpha: 0.15),
          ),
        ),
        child: Stack(
          children: [
            if (_showConfetti)
              Positioned.fill(
                child: _AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ConfettiPainter(
                        progress:
                            _controller.value,
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.heart(
                          PhosphorIconsStyle.fill,
                        ),
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .aboutThanks,
                          style: AppTypography
                              .titleSmall
                              .copyWith(
                            color:
                                AppColors.primary,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!
                        .aboutThanksMessage,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall
                        .copyWith(
                      color:
                          AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!
                        .aboutTapToCelebrate,
                    style: AppTypography.caption
                        .copyWith(
                      color:
                          AppColors.textTertiary,
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

/// Card dedicace famille
class _FamilyCard extends StatelessWidget {
  const _FamilyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary
                .withValues(alpha: 0.08),
            AppColors.tertiary
                .withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary
              .withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.house(
                  PhosphorIconsStyle.fill,
                ),
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!
                      .aboutFamilyTitle,
                  style: AppTypography.titleSmall
                      .copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!
                .aboutFamilyMessage,
            textAlign: TextAlign.center,
            style:
                AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Confettis animes
class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  static final _particles =
      List.generate(30, (i) {
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
    final fadeOut = progress > 0.7
        ? (1.0 - progress) / 0.3
        : 1.0;

    for (final p in _particles) {
      final paint = Paint()
        ..color = p.color
            .withValues(alpha: 0.8 * fadeOut)
        ..style = PaintingStyle.fill;

      final x =
          p.x * size.width +
          p.drift * progress * 40;
      final y =
          -10 +
          progress *
              p.speed *
              (size.height + 30);
      final angle =
          p.rotation + progress * 4;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      true;
}

class _AnimatedBuilder extends AnimatedWidget {
  final TransitionBuilder builder;

  const _AnimatedBuilder({
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) =>
      builder(context, null);
}
