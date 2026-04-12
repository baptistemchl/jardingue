import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../router/app_router.dart';
import '../../constants/app_colors.dart';
import '../../theme/app_typography.dart';

const _kNeverAskAgain = 'rate_never_ask_again';
const _kRemindAfter = 'rate_remind_after';
const _kAppOpenCount = 'rate_app_open_count';

/// Nombre minimum d'ouvertures avant de demander un avis.
const _kMinOpensBeforeAsk = 5;

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.agenceixp.jardingue';

/// Vérifie si le bottom sheet de notation doit être affiché
/// et l'affiche si les conditions sont remplies.
///
/// Appeler dans le [initState] du widget principal.
Future<void> maybeShowRateSheet() async {
  final prefs = await SharedPreferences.getInstance();

  // L'utilisateur a dit "ne plus me le demander"
  if (prefs.getBool(_kNeverAskAgain) ?? false) return;

  // Incrémenter le compteur d'ouvertures
  final openCount = (prefs.getInt(_kAppOpenCount) ?? 0) + 1;
  await prefs.setInt(_kAppOpenCount, openCount);

  // Pas assez d'ouvertures
  if (openCount < _kMinOpensBeforeAsk) return;

  // "Me le rappeler plus tard" : vérifier la date
  final remindAfterMs = prefs.getInt(_kRemindAfter);
  if (remindAfterMs != null) {
    final remindAfter = DateTime.fromMillisecondsSinceEpoch(remindAfterMs);
    if (DateTime.now().isBefore(remindAfter)) return;
  }

  // Attendre que l'app soit bien chargée
  await Future.delayed(const Duration(seconds: 3));

  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return;

  showModalBottomSheet(
    // ignore: use_build_context_synchronously
    context: navigator.context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RateAppSheet(),
  );
}

class _RateAppSheet extends StatelessWidget {
  const _RateAppSheet();

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 8,
              ),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                bottomPadding + 16,
              ),
              child: Column(
                children: [
                  // Icône
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors
                          .secondaryLight
                          .withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.star(
                        PhosphorIconsStyle.fill,
                      ),
                      size: 32,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Vous aimez Jardingue ?',
                    style: AppTypography
                        .headlineMedium
                        .copyWith(
                      color:
                          AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Votre avis compte '
                    'énormément ! '
                    'Un petit commentaire sur le '
                    'Play Store nous aide à '
                    'améliorer l\'application.',
                    style: AppTypography.bodySmall
                        .copyWith(
                      color:
                          AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Bouton principal : noter
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _rateNow(context),
                      icon: Icon(
                        PhosphorIcons
                            .googlePlayLogo(
                          PhosphorIconsStyle.fill,
                        ),
                        size: 20,
                      ),
                      label: Text(
                        'Donner mon avis',
                        style: AppTypography
                            .labelLarge
                            .copyWith(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton
                          .styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets
                            .symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rappeler plus tard
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          _remindLater(context),
                      style: OutlinedButton
                          .styleFrom(
                        foregroundColor:
                            AppColors
                                .textSecondary,
                        side: const BorderSide(
                          color: AppColors.border,
                        ),
                        padding: const EdgeInsets
                            .symmetric(
                          vertical: 12,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(14),
                        ),
                      ),
                      child: Text(
                        'Me le rappeler plus tard',
                        style: AppTypography
                            .labelMedium
                            .copyWith(
                          color: AppColors
                              .textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Ne plus demander
                  TextButton(
                    onPressed: () =>
                        _neverAskAgain(context),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          AppColors.textTertiary,
                    ),
                    child: Text(
                      'Ne plus me le demander',
                      style: AppTypography.caption
                          .copyWith(
                        color: AppColors
                            .textTertiary,
                      ),
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

  Future<void> _rateNow(BuildContext context) async {
    // Marquer comme "ne plus demander" (l'utilisateur a cliqué)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNeverAskAgain, true);

    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _remindLater(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final inOneWeek = DateTime.now().add(const Duration(days: 7));
    await prefs.setInt(_kRemindAfter, inOneWeek.millisecondsSinceEpoch);

    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _neverAskAgain(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNeverAskAgain, true);

    if (context.mounted) Navigator.pop(context);
  }
}
