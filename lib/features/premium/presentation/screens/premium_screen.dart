import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/premium_providers.dart';
import '../widgets/premium_card.dart';
import '../widgets/backup_section.dart';
import '../widgets/restore_section.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumNotifierProvider);
    final user = ref.watch(firebaseUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            PhosphorIcons.arrowLeft(
              PhosphorIconsStyle.bold,
            ),
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Cloud & Premium',
          style: AppTypography.titleMedium,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (user != null) ...[
              _AccountCard(user: user),
              const SizedBox(height: 20),
            ],
            const PremiumCard(),
            if (premium.isPremium && user != null) ...[
              const SizedBox(height: 20),
              const BackupSection(),
              const SizedBox(height: 16),
              const RestoreSection(),
            ],
            const SizedBox(height: 32),
            _RestorePurchasesButton(),
          ],
        ),
      ),
    );
  }
}

// ── Mon compte ──

class _AccountCard extends ConsumerWidget {
  final User user;

  const _AccountCard({required this.user});

  String get _initials {
    final name = user.displayName ?? user.email ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar avec initiales
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: AppTypography.titleSmall
                        .copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon compte',
                      style: AppTypography.titleSmall
                          .copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? 'Connecté',
                      style:
                          AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.checkCircle(
                  PhosphorIconsStyle.fill,
                ),
                size: 20,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Changer de compte
          GestureDetector(
            onTap: () => _confirmSwitchAccount(
              context,
              ref,
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.arrowsLeftRight(
                    PhosphorIconsStyle.regular,
                  ),
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Changer de compte Google',
                    style:
                        AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  PhosphorIcons.caretRight(
                    PhosphorIconsStyle.bold,
                  ),
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              'Les sauvegardes cloud sont liées '
              'au compte Google connecté.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSwitchAccount(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer de compte ?'),
        content: const Text(
          'Vos sauvegardes cloud sont liées à '
          'votre compte Google. En changeant de '
          'compte, vous accéderez aux sauvegardes '
          'de l\'autre compte.\n\n'
          'Les achats Premium sont liés à votre '
          'compte Play Store, pas au compte Google.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(firebaseUserProvider.notifier)
                  .signOut();
              if (context.mounted) {
                await ref
                    .read(
                      firebaseUserProvider.notifier,
                    )
                    .signIn();
              }
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }
}

// ── Restaurer les achats ──

class _RestorePurchasesButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton(
        onPressed: () async {
          try {
            await ref
                .read(premiumNotifierProvider.notifier)
                .restorePurchases();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Achats restaurés avec succès.',
                  ),
                ),
              );
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Impossible de restaurer.',
                  ),
                ),
              );
            }
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Restaurer mes achats',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vous avez déjà acheté le premium ?\n'
              'Appuyez ici pour le réactiver après '
              'une réinstallation ou un changement '
              'd\'appareil.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
