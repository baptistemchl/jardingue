import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/premium/presentation/providers/premium_providers.dart';
import '../../../router/app_router.dart';
import '../../constants/app_colors.dart';
import '../../theme/app_typography.dart';

const _kNeverAskAgain = 'premium_reminder_never_ask_again';
const _kRemindAfter = 'premium_reminder_remind_after';
const _kAppOpenCount = 'premium_reminder_app_open_count';

/// Nombre minimum d'ouvertures avant la première proposition.
const _kMinOpensBeforeAsk = 8;

/// Délai par défaut quand l'utilisateur clique "Plus tard".
const _kRemindLaterDuration = Duration(days: 14);

/// Vérifie si la bottom sheet de rappel premium doit être affichée
/// et l'affiche si les conditions sont remplies.
///
/// - Pas affichée si l'utilisateur est déjà Premium.
/// - Pas affichée si l'utilisateur a coché "ne plus rappeler".
/// - Pas affichée si on est encore dans la fenêtre "plus tard".
Future<void> maybeShowPremiumReminder(WidgetRef ref) async {
  // Déjà Premium : rien à proposer.
  final premium = ref.read(premiumNotifierProvider);
  if (premium.isPremium) return;

  final prefs = await SharedPreferences.getInstance();

  if (prefs.getBool(_kNeverAskAgain) ?? false) return;

  final openCount = (prefs.getInt(_kAppOpenCount) ?? 0) + 1;
  await prefs.setInt(_kAppOpenCount, openCount);

  if (openCount < _kMinOpensBeforeAsk) return;

  final remindAfterMs = prefs.getInt(_kRemindAfter);
  if (remindAfterMs != null) {
    final remindAfter =
        DateTime.fromMillisecondsSinceEpoch(remindAfterMs);
    if (DateTime.now().isBefore(remindAfter)) return;
  }

  // Laisse l'app finir son init avant d'afficher la sheet.
  await Future.delayed(const Duration(seconds: 3));

  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return;

  // Re-vérifier après le délai (l'utilisateur peut être devenu premium).
  if (ref.read(premiumNotifierProvider).isPremium) return;

  showModalBottomSheet(
    // ignore: use_build_context_synchronously
    context: navigator.context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _PremiumReminderSheet(),
  );
}

class _PremiumReminderSheet extends ConsumerWidget {
  const _PremiumReminderSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final productAsync = ref.watch(premiumProductProvider);
    final priceLabel = productAsync.whenOrNull(
          data: (p) => p?.price,
        ) ??
        '';

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
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                bottomPadding + 16,
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.cloudArrowUp(
                        PhosphorIconsStyle.duotone,
                      ),
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Soutenez Jardingue',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Jardingue est développé bénévolement par '
                    'une auto-entreprise. Pour aller plus loin, '
                    'vous pouvez débloquer le Premium :',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Liste des avantages
                  _BenefitRow(
                    icon: PhosphorIcons.cloudCheck(
                      PhosphorIconsStyle.duotone,
                    ),
                    text: 'Sauvegardez vos potagers et verger '
                        'dans le cloud',
                  ),
                  const SizedBox(height: 8),
                  _BenefitRow(
                    icon: PhosphorIcons.arrowsClockwise(
                      PhosphorIconsStyle.duotone,
                    ),
                    text: 'Restaurez vos données sur n\'importe '
                        'quel appareil',
                  ),
                  const SizedBox(height: 8),
                  _BenefitRow(
                    icon: PhosphorIcons.heart(
                      PhosphorIconsStyle.duotone,
                    ),
                    text: 'Soutenez le développement '
                        'de l\'application',
                  ),
                  const SizedBox(height: 20),
                  // Encart prix
                  if (priceLabel.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.tag(
                              PhosphorIconsStyle.fill,
                            ),
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Achat unique · $priceLabel',
                            style:
                                AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Bouton principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openPremium(context),
                      icon: Icon(
                        PhosphorIcons.cloudArrowUp(
                          PhosphorIconsStyle.bold,
                        ),
                        size: 20,
                      ),
                      label: Text(
                        priceLabel.isEmpty
                            ? 'Découvrir Premium'
                            : 'Débloquer pour $priceLabel',
                        style:
                            AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Plus tard
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _remindLater(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                          color: AppColors.border,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Me le rappeler plus tard',
                        style:
                            AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Ne plus rappeler
                  TextButton(
                    onPressed: () => _neverAskAgain(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textTertiary,
                    ),
                    child: Text(
                      'Ne plus me le rappeler',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
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

  Future<void> _openPremium(BuildContext context) async {
    // Capturer la référence au navigator racine avant tout await.
    final navigator = rootNavigatorKey.currentState;

    // L'utilisateur a montré de l'intérêt : on n'insiste plus.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNeverAskAgain, true);

    if (context.mounted) Navigator.pop(context);
    // Push après pop pour éviter d'empiler la sheet sur la nav.
    if (navigator != null && navigator.mounted) {
      navigator.context.push(AppRoutes.premium);
    }
  }

  Future<void> _remindLater(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final next = DateTime.now().add(_kRemindLaterDuration);
    await prefs.setInt(_kRemindAfter, next.millisecondsSinceEpoch);

    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _neverAskAgain(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNeverAskAgain, true);

    if (context.mounted) Navigator.pop(context);
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
