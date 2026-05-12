import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/premium_providers.dart';

class PremiumCard extends ConsumerWidget {
  const PremiumCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: premium.isPremium
              ? [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ]
              : [
                  AppColors.surface,
                  AppColors.surface,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: premium.isPremium
            ? null
            : Border.all(color: AppColors.border),
      ),
      child: premium.isPremium
          ? _buildActive()
          : _buildLocked(ref),
    );
  }

  Widget _buildActive() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            PhosphorIcons.cloud(
              PhosphorIconsStyle.fill,
            ),
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium actif',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sauvegarde cloud disponible',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Icon(
          PhosphorIcons.checkCircle(
            PhosphorIconsStyle.fill,
          ),
          color: Colors.white,
          size: 28,
        ),
      ],
    );
  }

  Widget _buildLocked(WidgetRef ref) {
    final productAsync = ref.watch(premiumProductProvider);
    // 3 états : chargement / produit indispo (debug, store KO,
    // SKU non activé) / prix dispo.
    final isLoadingPrice = productAsync.isLoading;
    final price = productAsync.whenOrNull(data: (p) => p?.price);
    final hasPrice = price != null && price.isNotEmpty;
    final isUnavailable = !isLoadingPrice && !hasPrice;

    return Column(
      children: [
        Icon(
          PhosphorIcons.cloudArrowUp(
            PhosphorIconsStyle.duotone,
          ),
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Sauvegarde cloud Premium',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Prix mis en avant
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.tag(PhosphorIconsStyle.fill),
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              if (hasPrice)
                Text(
                  price,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else if (isLoadingPrice)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                Text(
                  'Bientôt disponible',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '· achat unique',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (isUnavailable) ...[
          const SizedBox(height: 8),
          Text(
            'La validation par Google Play est en cours. '
            'L\'achat sera disponible très prochainement, '
            'merci pour votre patience.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              height: 1.4,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Liste d'avantages
        const _Benefit(
          icon: 'cloudCheck',
          text: 'Sauvegarde cloud sécurisée de vos potagers, '
              'verger et historique',
        ),
        const SizedBox(height: 10),
        const _Benefit(
          icon: 'phones',
          text: 'Restaurez vos données sur n\'importe '
              'quel appareil',
        ),
        const SizedBox(height: 10),
        const _Benefit(
          icon: 'shield',
          text: 'Pas d\'abonnement : un seul paiement, '
              'à vie',
        ),
        const SizedBox(height: 16),

        // Mot du dev
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PhosphorIcons.heart(PhosphorIconsStyle.duotone),
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jardingue est développé bénévolement '
                  'par une auto-entreprise. Chaque achat '
                  'aide à maintenir et améliorer l\'app.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Bouton d'achat — actif uniquement quand le tarif est connu.
        // Tant que la validation côté Play Console (mode de paiement +
        // fiscalité) n'est pas terminée, queryProductDetails renvoie une
        // liste vide : on désactive le bouton avec un libellé clair
        // plutôt que de risquer un launchBillingFlow qui crashe en NPE
        // dans ProxyBillingActivity côté lib Google.
        Builder(
          builder: (buttonContext) {
            final canBuy = hasPrice;
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canBuy
                    ? () async {
                        try {
                          await ref
                              .read(
                                premiumNotifierProvider.notifier,
                              )
                              .purchaseWithSignIn();
                        } catch (e) {
                          if (!buttonContext.mounted) return;
                          ScaffoldMessenger.of(buttonContext)
                              .showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              behavior:
                                  SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  hasPrice
                      ? 'Débloquer pour $price'
                      : isLoadingPrice
                          ? 'Chargement du tarif...'
                          : 'Bientôt disponible',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  final String icon;
  final String text;

  const _Benefit({required this.icon, required this.text});

  IconData _resolveIcon() {
    switch (icon) {
      case 'cloudCheck':
        return PhosphorIcons.cloudCheck(PhosphorIconsStyle.duotone);
      case 'phones':
        return PhosphorIcons.devices(PhosphorIconsStyle.duotone);
      case 'shield':
        return PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone);
      default:
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_resolveIcon(), size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
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
