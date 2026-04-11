import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_back_button.dart';
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
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(
                top: 60,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              children: [
                // Titre
                Text(
                  'Cloud & Premium',
                  style: AppTypography.headlineLarge
                      .copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
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

            // Bouton retour
            Positioned(
              top: 8,
              left: 12,
              child: const AppBackButton.light(),
            ),
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

// ── Restaurer les achats / Connexion ──

class _RestorePurchasesButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RestorePurchasesButton> createState() =>
      _RestorePurchasesButtonState();
}

class _RestorePurchasesButtonState
    extends ConsumerState<_RestorePurchasesButton> {
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseUserProvider);

    // Utilisateur connecté : bouton classique "Restaurer mes achats"
    if (user != null) {
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
          child: Text(
            'Restaurer mes achats',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    // Non connecté : invitation à se connecter
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.cloudCheck(PhosphorIconsStyle.duotone),
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Déjà un compte Cloud ?',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connectez-vous avec le compte Google '
            'lié à votre Play Store pour retrouver '
            'vos achats et sauvegardes.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSigningIn
                  ? null
                  : () async {
                      setState(() => _isSigningIn = true);
                      try {
                        await ref
                            .read(firebaseUserProvider.notifier)
                            .signIn();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Connexion impossible.',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => _isSigningIn = false);
                        }
                      }
                    },
              icon: _isSigningIn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      PhosphorIcons.googleLogo(
                        PhosphorIconsStyle.bold,
                      ),
                      size: 16,
                    ),
              label: Text(
                _isSigningIn
                    ? 'Connexion...'
                    : 'Se connecter avec Google',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
