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
    final priceLabel = productAsync.whenOrNull(
          data: (p) => p?.price,
        ) ??
        '...';

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
          'Sauvegarde cloud',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sauvegardez vos potagers, verger '
          'et historique dans le cloud.\n'
          'Restaurez-les à tout moment.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(
                      premiumNotifierProvider.notifier,
                    )
                    .purchaseWithSignIn();
              } catch (_) {
                // Erreur gérée par le notifier
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Débloquer pour $priceLabel',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
